import 'package:event/components/supplier/supplier_cache.dart';
import 'package:event/components/supplier/supplier_crud.dart';
import 'package:event/components/supplier/supplier_filter.dart';
import 'package:event/components/supplier/supplier_location.dart';
import 'package:event/components/supplier/supplier_organisation.dart';
import 'package:event/components/supplier/supplier_persistence.dart';
import 'package:event/components/supplier/supplier_search.dart';
import 'package:event/components/supplier/supplier_state.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locator/locator.dart';
import 'package:verdelia_core/business/Organisation.dart';
import 'package:verdelia_core/business/Supplier.dart';
import 'package:verdelia_core/business/services/SupplierService.dart';
import 'package:verdelia_core/mediation/StorageService.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SupplierChangeNotifier extends ChangeNotifier {
  // Currently selected supplier id (nullable). Other widgets can listen
  // to changes via this notifier and react (e.g., dashboards).
  int? _selectedSupplierId;

  /// Get or null if no supplier selected
  int? get selectedSupplierId => _selectedSupplierId;

  /// Select a supplier (or null to clear selection)
  void selectSupplier(int? supplierId) {
    if (_selectedSupplierId == supplierId) return;
    _selectedSupplierId = supplierId;
    notifyListeners();
  }

  // Dependencies
  final SupplierService _service = AppLocator.get<SupplierService>();
  final StorageService _storage = AppLocator.get<StorageService>();

  // Components (initialized in constructor)
  late final SupplierCache _cache;
  late final SupplierState _state;
  late final SupplierPersistence _persistence;
  late final SupplierCrud _crud;
  late final SupplierSearch _search;
  late final SupplierLocation _location;
  late final SupplierOrganisation _organisation;

  // Track pending individual fetches
  final Map<int, Future<Supplier?>> _pendingFetches = {};
  Future<List<SupplierCategory>>? _pendingCategoryFetch;

  SupplierChangeNotifier() {
    _initComponents();
    _loadPersistedData();
  }

  void _initComponents() {
    _state = SupplierState();
    _cache = SupplierCache();
    _persistence = SupplierPersistence();
    _crud = SupplierCrud(
      service: _service,
      storage: _storage,
      cache: _cache,
      state: _state,
      persistence: _persistence,
    );
    _search = SupplierSearch(
      service: _service,
      storage: _storage,
      cache: _cache,
      state: _state,
    );
    _location = SupplierLocation(
      storage: _storage,
      state: _state,
    );
    _organisation = SupplierOrganisation(
      service: _service,
      storage: _storage,
      state: _state,
      persistence: _persistence,
      cache: _cache,
    );
  }

  Future<void> _loadPersistedData() async {
    await _persistence.load();
  }

  // ============ PUBLIC GETTERS (DELEGATED) ============

  List<Supplier> get suppliers => _state.suppliers;
  List<SupplierCategory> get supplierCategories => _state.categories;
  List<Supplier> get filteredSuppliers => _state.filteredSuppliers;
  List<Organisation> get organisations => _state.organisations.values.toList();
  Position? get currentLocation => _state.currentLocation;
  SupplierFilter get filter => _state.filter;
  bool get isLoading => _state.isLoading;
  bool get hasMoreSuppliers => _state.hasMoreSuppliers;
  bool get hasMoreOrganisations => _state.hasMoreOrganisations;
  bool get isCacheEnabled => _cache.isEnabled;

  Future<List<SupplierCategory>> fetchSupplierCategories({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = _cache.getCategories();
      if (cached != null) {
        _state.categories = List.of(cached);
        notifyListeners();
        return _state.categories;
      }

      final pending = _pendingCategoryFetch;
      if (pending != null) return pending;
    }

    final request = _loadSupplierCategories();
    _pendingCategoryFetch = request;
    try {
      return await request;
    } finally {
      if (identical(_pendingCategoryFetch, request)) {
        _pendingCategoryFetch = null;
      }
    }
  }

  Future<List<SupplierCategory>> _loadSupplierCategories() async {
    try {
      final fetched = await _service.getCategories();
      _cache.cacheCategories(fetched);
      _state.categories = List.of(fetched);
      return _state.categories;
    } catch (e) {
      debugPrint('Failed to fetch supplier categories: $e');
      return _state.categories;
    } finally {
      notifyListeners();
    }
  }

  String categoryName(int? categoryId, {String languageCode = 'en'}) {
    if (categoryId == null) return '';
    for (final category in _state.categories) {
      if (category.productProviderTypeId == categoryId) {
        return category.nameFor(languageCode);
      }
    }
    return '';
  }

  // Persistence getters
  List<int> get ownedSupplierIds =>
      _persistence.getOwnedSuppliers(_persistence.currentUserId);
  List<int> get ownedOrganisationIds =>
      _persistence.getOwnedOrganisations(_persistence.currentUserId);

  // ============ USER CONTEXT ============

  void setCurrentUserId(int userId) {
    _persistence.setCurrentUser(userId);
  }

  // ============ SUPPLIER OPERATIONS ============

  Future<void> fetchSuppliers({
    bool reset = false,
    int? ownerId,
    int? organisationId,
    bool forceRefresh = false,
  }) async {
    if (_state.isLoading || (!reset && !_state.hasMoreSuppliers)) return;

    if (reset) {
      _state.suppliers.clear();
      _state.suppliersPage = 0;
      _state.hasMoreSuppliers = true;
    }

    final cacheKey =
        'suppliers_${ownerId ?? 0}_${organisationId ?? 0}_${_state.suppliersPage}';

    if (!forceRefresh) {
      final cached = _cache.getList(cacheKey);

      if (cached != null) {
        _addSuppliers(cached);
        _state.hasMoreSuppliers = cached.length >= SupplierState.itemsPerPage;
        return;
      }
    }

    _state.isLoading = true;

    try {
      // IMPORTANT: Make the API call with the actual ownerId
      final results = await _service.getAllSuppliers(
        ownerId ?? 0,
        organisationId ?? 0,
        _state.suppliersPage * SupplierState.itemsPerPage,
        SupplierState.itemsPerPage,
      );

      debugPrint(
          '📡 API returned ${results.length} suppliers for ownerId: $ownerId');

      if (!reset) {
        _cache.cacheList(cacheKey, results);
      }

      _addSuppliers(results);
      _state.hasMoreSuppliers = results.length >= SupplierState.itemsPerPage;
      if (_state.hasMoreSuppliers) _state.suppliersPage++;

      debugPrint('📦 Fetched ${results.length} suppliers (ownerId: $ownerId)');
    } catch (e) {
      debugPrint('❌ Error fetching suppliers: $e');
    } finally {
      _state.isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch suppliers owned by a specific user
  Future<List<Supplier>> fetchOwnedSuppliers(
    int userId, {
    bool forceRefresh = false,
  }) async {
    debugPrint('👑 [DEBUG] fetchOwnedSuppliers called for user: $userId');
    debugPrint('👑 [DEBUG] forceRefresh: $forceRefresh');

    final ownedCacheKey = 'owned_suppliers_$userId';

    if (!forceRefresh) {
      final cached = _cache.getList(ownedCacheKey);
      if (cached != null && cached.isNotEmpty) {
        debugPrint('📦 [DEBUG] Using cached owned suppliers: ${cached.length}');
        for (final supplier in cached) {
          _upsertSupplier(supplier); // ✅ This adds to _state.suppliers
        }
        return cached;
      }
    }

    try {
      debugPrint(
          '🌐 [DEBUG] Calling API for owned suppliers (userId: $userId)');
      final results = await _service.getAllSuppliers(
        userId, // owner_id
        0, // org_id
        0, // offset
        100, // limit
      );

      debugPrint('📡 [DEBUG] API returned ${results.length} owned suppliers');

      for (final s in results) {
        debugPrint(
            '   - ${s.idProductProvider}: ${s.providerName} (owner: ${s.productProviderOwnerId})');
      }

      _cache.cacheList(ownedCacheKey, results);

      // ✅ CRITICAL: Add to main suppliers list
      for (final supplier in results) {
        _upsertSupplier(supplier); // ✅ This is already happening!
      }

      debugPrint(
          '📦 [DEBUG] Suppliers after upsert: ${_state.suppliers.length}');
      return results;
    } catch (e) {
      debugPrint('❌ [DEBUG] Error fetching owned suppliers: $e');
      return [];
    }
  }

  /// Get owned suppliers with guaranteed fresh data
  Future<List<Supplier>> getOwnedSuppliersFresh(int userId) async {
    debugPrint('🔍 [DEBUG] getOwnedSuppliersFresh called for user: $userId');

    // Fetch fresh data
    final results = await fetchOwnedSuppliers(userId, forceRefresh: true);
    debugPrint(
        '🔍 [DEBUG] fetchOwnedSuppliers returned ${results.length} suppliers');

    // Return the results
    return results;
  }

  /// Get owned suppliers from current state (may be stale)
  List<Supplier> getOwnedSuppliersFromState(int userId) {
    final owned = _state.suppliers
        .where((s) => s.productProviderOwnerId == userId)
        .toList();
    debugPrint(
        '🔍 [DEBUG] getOwnedSuppliersFromState: ${owned.length} suppliers');
    return owned;
  }

  /// Upsert a supplier (add if not exists, update if exists)
  void _upsertSupplier(Supplier supplier) {
    final index = _state.suppliers
        .indexWhere((s) => s.idProductProvider == supplier.idProductProvider);

    if (index >= 0) {
      _state.suppliers[index] = supplier;
    } else {
      _state.suppliers.add(supplier);
    }

    _cache.cacheSupplier(supplier);
  }

  /// Get a supplier by ID - tries cache first, then fetches individually
  Future<Supplier?> getSupplierById(int id, {bool forceRefresh = false}) async {
    // Check cache first
    if (!forceRefresh) {
      final cached = _cache.getSupplier(id);
      if (cached != null && cached.idProductProvider != 0) {
        debugPrint('📦 Supplier $id found in cache');
        return cached;
      }
    }

    // Check if there's already a pending fetch for this ID
    if (_pendingFetches.containsKey(id)) {
      debugPrint('⏳ Supplier $id fetch already in progress, waiting...');
      return _pendingFetches[id];
    }

    // Start fetching
    debugPrint('🔄 Fetching supplier $id individually...');
    final future = _fetchSupplierById(id);
    _pendingFetches[id] = future;

    try {
      final supplier = await future;
      return supplier;
    } finally {
      _pendingFetches.remove(id);
    }
  }

  /// Internal method to fetch a single supplier by ID
  Future<Supplier?> _fetchSupplierById(int id) async {
    try {
      final supplier = await _service.getSupplier(id.toString());

      if (supplier == null || supplier.idProductProvider == 0) {
        return null;
      }

      _upsertSupplier(supplier);
      return supplier;
    } catch (e) {
      debugPrint('Failed to fetch supplier $id: $e');
      return null;
    }
  }

  List<Supplier> getSuppliersOwnedByUser(int userId) {
    return _state.suppliers
        .where((s) => s.productProviderOwnerId == userId)
        .toList();
  }

  /// Get multiple suppliers by IDs - batch fetch
  Future<List<Supplier>> getSuppliersByIds(List<int> ids) async {
    if (ids.isEmpty) return [];

    final uniqueIds = ids.toSet().toList();
    final results = <Supplier>[];
    final missingIds = <int>[];

    // Check cache first
    for (final id in uniqueIds) {
      final cached = _cache.getSupplier(id);
      if (cached != null && cached.idProductProvider != 0) {
        results.add(cached);
      } else {
        missingIds.add(id);
      }
    }

    // Fetch missing in batch (if API supports batch)
    if (missingIds.isNotEmpty) {
      try {
        // Option 1: If API supports batch
        final fetched = await _service.getSuppliersByIds(missingIds);
        for (final supplier in fetched ?? []) {
          _upsertSupplier(supplier);
          results.add(supplier);
        }
      } catch (e) {
        // Option 2: Fallback to individual fetches (but limited)
        debugPrint('Batch fetch failed, falling back to individual fetches');
        for (final id in missingIds.take(20)) {
          // Limit to 20
          final supplier = await getSupplierById(id);
          if (supplier != null) {
            results.add(supplier);
          }
        }
      }
    }

    return results;
  }

  /// Get suppliers owned by a specific user (filtered locally)
  /// Get suppliers owned by a specific user - ensures fresh data
  Future<List<Supplier>> getSuppliersOwnedBy(
    int userId, {
    bool forceRefresh = false,
  }) async {
    // Always fetch fresh to ensure accuracy
    await fetchSuppliers(
      ownerId: userId,
      reset: true,
      forceRefresh: forceRefresh,
    );

    return List.unmodifiable(
      _state.suppliers.where(
        (s) => s.productProviderOwnerId == userId,
      ),
    );
  }

  /// Get suppliers for a specific organisation (filtered locally)
  List<Supplier> getSuppliersForOrganisation(int organisationId) {
    return _state.suppliers
        .where((s) => s.idProviderOrganisation == organisationId)
        .toList();
  }

  Future<Supplier> createOrUpdateSupplier(Supplier supplier, String token) =>
      _crud.createOrUpdate(supplier, token).then((result) {
        notifyListeners();
        return result;
      });

  Future<bool> deleteSupplier(int id, String token) =>
      _crud.delete(id, token).then((result) {
        notifyListeners();
        return result;
      });

  // ============ SEARCH OPERATIONS ============

  Future<void> searchSuppliers(String query) =>
      _search.search(query).then((_) => notifyListeners());

  Future<void> searchSuppliersByGeo({
    required double longitude,
    required double latitude,
    required double radiusKm,
    bool reset = false,
  }) =>
      _search
          .searchByGeo(
              longitude: longitude,
              latitude: latitude,
              radiusKm: radiusKm,
              reset: reset)
          .then((_) => notifyListeners());

  void clearSearch() {
    _state.filter = const SupplierFilter();
    notifyListeners();
  }

  // ============ LOCATION OPERATIONS ============

  Future<Position?> getCurrentLocation() =>
      _location.getCurrentLocation().then((pos) {
        notifyListeners();
        return pos;
      });

  // ============ ORGANISATION OPERATIONS ============

  Future<void> fetchOrganisations({bool reset = false}) =>
      _organisation.fetch(reset: reset).then((_) => notifyListeners());

  Future<Organisation?> getOrganisationById(int id) =>
      _organisation.getById(id).then((org) {
        notifyListeners();
        return org;
      });

  Future<Organisation?> createOrganisation(Organisation org, String token) =>
      _organisation.create(org, token).then((result) {
        notifyListeners();
        return result;
      });

  Future<Organisation?> updateOrganisation(Organisation org, String token) =>
      _organisation.update(org, token).then((result) {
        notifyListeners();
        return result;
      });

  Future<bool> deleteOrganisation(int id, String token) =>
      _organisation.delete(id, token).then((result) {
        notifyListeners();
        return result;
      });

  // ============ CACHE MANAGEMENT ============

  void enableCaching(bool enable) {
    _cache.enable(enable);
    notifyListeners();
  }

  void invalidateCache({int? supplierId, String? listKey}) {
    _cache.invalidate(supplierId: supplierId, listKey: listKey);
    // Clear pending fetches for invalidated supplier
    if (supplierId != null) {
      _pendingFetches.remove(supplierId);
    }
  }

  void refreshAllCaches() {
    _cache.clearAll();
    _pendingFetches.clear();
    _state.categories.clear();
    notifyListeners();
  }

  // ============ PERSISTENCE OPERATIONS ============

  Future<void> clearPersistedData() =>
      _persistence.clearAll().then((_) => notifyListeners());

  Future<void> addOwnedSupplier(int userId, int supplierId) => _persistence
      .addSupplier(userId, supplierId)
      .then((_) => notifyListeners());

  Future<void> removeOwnedSupplier(int userId, int supplierId) => _persistence
      .removeSupplier(userId, supplierId)
      .then((_) => notifyListeners());

  Future<void> addOwnedOrganisation(int userId, int orgId) => _persistence
      .addOrganisation(userId, orgId)
      .then((_) => notifyListeners());

  Future<void> removeOwnedOrganisation(int userId, int orgId) => _persistence
      .removeOrganisation(userId, orgId)
      .then((_) => notifyListeners());

  // ============ HELPERS ============

  void _addSuppliers(List<Supplier> newSuppliers) {
    if (newSuppliers.isEmpty) {
      debugPrint('⚠️ _addSuppliers called with empty list');
      return;
    }

    debugPrint('📦 _addSuppliers called with ${newSuppliers.length} suppliers');

    for (final supplier in newSuppliers) {
      if (supplier.idProductProvider == 0) {
        debugPrint('⚠️ Skipping supplier with ID 0: ${supplier.providerName}');
        continue;
      }
      _upsertSupplier(supplier);
    }

    debugPrint('📦 Total suppliers: ${_state.suppliers.length}');
  }

  // ============ STATE RESET ============

  void reset() {
    _state.reset();
    _cache.clearAll();
    _pendingFetches.clear();
    _pendingCategoryFetch = null;
    notifyListeners();
  }

  // ============ CACHE STATS ============

  CacheStats getCacheStats() {
    return CacheStats(
      detailedCacheSize: _cache.detailedCacheSize,
      lruCacheSize: _cache.lruCacheSize,
      listCacheSize: _cache.listCacheSize,
      suppliersCount: _state.suppliers.length,
      organisationsCount: _state.organisations.length,
      cacheEnabled: _cache.isEnabled,
      cacheTTLSeconds: 300,
      hits: _cache.hits,
      misses: _cache.misses,
    );
  }

  // ============ RESPONSE RETRIEVAL ============

  CallerResponse? getResponse(String callerKey) {
    return _storage.getResponse(callerKey);
  }
}

// ============ CACHE STATS ============

class CacheStats {
  final int detailedCacheSize;
  final int lruCacheSize;
  final int listCacheSize;
  final int suppliersCount;
  final int organisationsCount;
  final bool cacheEnabled;
  final int cacheTTLSeconds;
  final int hits;
  final int misses;

  CacheStats({
    required this.detailedCacheSize,
    required this.lruCacheSize,
    required this.listCacheSize,
    required this.suppliersCount,
    required this.organisationsCount,
    required this.cacheEnabled,
    required this.cacheTTLSeconds,
    required this.hits,
    required this.misses,
  });

  double get hitRate => hits + misses > 0 ? hits / (hits + misses) : 0.0;
}
