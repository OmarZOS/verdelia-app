// lib/event/service/service_notifier.dart

import 'dart:async';
import 'dart:developer' as developer;

import 'package:event/TraceableNotifier.dart';
import 'package:event/service/service_category_persistence.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:locator/locator.dart';
import 'package:verdelia_core/app/VerdeliaException.dart';
import 'package:verdelia_core/business/CategoryHierarchyIndex.dart';
import 'package:verdelia_core/business/finance/ProvidedService.dart';
import 'package:verdelia_core/business/services/ProvidedServiceManagementService.dart';

class ServiceNotifier extends TraceableNotifier {
  final ProvidedServiceManagementService _serviceManager =
      AppLocator.get<ProvidedServiceManagementService>();
  final ServiceCategoryPersistence _categoryPersistence =
      ServiceCategoryPersistence();

  final List<ProvidedService> _services = [];

  List<ProvidedServiceCategory> _serviceCategories = [];
  CategoryHierarchyIndex<ProvidedServiceCategory> _categoryHierarchy =
      CategoryHierarchyIndex.fromItems(
    <ProvidedServiceCategory>[],
    (category) => category.name,
  );

  /// Staff roles keyed by id, populated after a successful
  /// [fetchStaffRolesByCategory]. Used by requirement cards to resolve
  /// a role id into a name when the service payload didn't inline the
  /// nested `staff_role` block.
  final Map<int, StaffRole> _staffRolesById = {};

  bool _serviceCategoriesLoaded = false;
  Future<List<ProvidedServiceCategory>>? _pendingServiceCategoryFetch;
  late final Future<void> _categoryBootstrap;

  bool _isLoading = false;
  bool _notificationScheduled = false;
  bool _hasMore = true;

  bool _isFetchingDetails = false;
  bool get isFetchingDetails => _isFetchingDetails;

  String _searchQuery = '';
  int? _currentProviderId;
  int _page = 0;
  final int _pageSize = 100;

  Timer? _debounce;
  int _requestToken = 0;

  final Map<int, ProvidedService> _cachedServices = {};

  ServiceNotifier() {
    // Bootstrap: restore persisted categories, then fetch if still empty.
    _categoryBootstrap = _bootstrapCategories();
  }

  // ============ GETTERS ============

  List<ProvidedService> get services => List.unmodifiable(_services);

  ProvidedService? getCachedService(int serviceId) {
    return _cachedServices[serviceId];
  }

  List<ProvidedService> get filteredServices {
    if (_searchQuery.isEmpty) return services;

    return services.where((service) {
      final name = service.name.toLowerCase();
      final description = service.description.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || description.contains(query);
    }).toList();
  }

  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String get searchQuery => _searchQuery;
  int? get currentProviderId => _currentProviderId;

  /// Categories, always non-empty after bootstrap when the backend
  /// has any. Reading this getter kicks off a fetch if the list is
  /// still empty and no request is in flight.
  List<ProvidedServiceCategory> get serviceCategories {
    if (_serviceCategories.isEmpty && _pendingServiceCategoryFetch == null) {
      unawaited(fetchServiceCategories());
    }
    return List.unmodifiable(_serviceCategories);
  }

  CategoryHierarchyIndex<ProvidedServiceCategory> get categoryHierarchy =>
      _categoryHierarchy;

  // ============ CATEGORY LOOKUPS ============

  /// Resolved display name for [categoryId] in [languageCode], or empty
  /// when the id is null / zero / unknown.
  ///
  /// Prefers the trilingual naming contribution carried by the
  /// category, falling back to the humanized canonical key
  /// (`health.diagnostics.diagnostic_imaging` → `Diagnostic Imaging`).
  String categoryName(
    int? categoryId, {
    String languageCode = 'en',
  }) {
    final category = categoryById(categoryId);
    if (category == null) return '';
    return category.nameFor(languageCode);
  }

  /// Look up the full category by id, or null when unknown.
  ///
  /// Prefer this over reaching into [serviceCategories] directly so the
  /// null / zero guards live in one place.
  ProvidedServiceCategory? categoryById(int? categoryId) {
    if (categoryId == null || categoryId <= 0) return null;
    for (final category in _serviceCategories) {
      if (category.id == categoryId) return category;
    }
    return null;
  }

  // ============ STAFF ROLE LOOKUPS ============

  /// Resolved display name for [roleId] in [languageCode], or empty
  /// when the role isn't cached.
  ///
  /// Prefers the trilingual naming contribution carried by the role,
  /// falling back to the flat `staff_role_name`.
  String staffRoleName(
    int? roleId, {
    String languageCode = 'en',
  }) {
    final role = staffRoleById(roleId);
    if (role == null) return '';
    return role.nameFor(languageCode);
  }

  /// Look up a cached staff role by id, or null when unknown.
  StaffRole? staffRoleById(int? roleId) {
    if (roleId == null || roleId <= 0) return null;
    return _staffRolesById[roleId];
  }

  /// Register roles after a fetch, keyed by id.
  ///
  /// Called automatically by [fetchStaffRolesByCategory] on success,
  /// but exposed for callers that already have a `List<StaffRole>` in
  /// hand (e.g. hydrated from a service payload).
  void registerStaffRoles(Iterable<StaffRole> roles) {
    var changed = false;
    for (final role in roles) {
      if (role.id <= 0) continue;
      _staffRolesById[role.id] = role;
      changed = true;
    }
    if (changed) _notifySafely();
  }

  // ============ CATEGORY BOOTSTRAP ============

  Future<void> _bootstrapCategories() async {
    await _restorePersistedCategories();

    if (_serviceCategories.isEmpty) {
      try {
        await fetchServiceCategories();
      } catch (error, stackTrace) {
        debugPrint(
          '[ServiceNotifier] Category bootstrap fetch failed: '
          '$error\n$stackTrace',
        );
      }
    }
  }

  Future<void> _restorePersistedCategories() async {
    try {
      final persisted = await _categoryPersistence.load();
      if (persisted == null || persisted.isEmpty) {
        _serviceCategories = const [];
        return;
      }
      _applyCategories(persisted);
    } catch (error, stackTrace) {
      debugPrint(
        '[ServiceNotifier] Failed to restore service categories: '
        '$error\n$stackTrace',
      );
    }
  }

  // ============ CATEGORIES ============

  Future<List<ProvidedServiceCategory>> fetchServiceCategories({
    String? callerKey,
    bool forceRefresh = false,
  }) async {
    await _categoryBootstrap;

    if (!forceRefresh &&
        _serviceCategoriesLoaded &&
        _serviceCategories.isNotEmpty) {
      return serviceCategories;
    }

    final pending = _pendingServiceCategoryFetch;
    if (pending != null) {
      if (!forceRefresh) return pending;
      try {
        await pending;
      } catch (_) {
        // Forced refresh still gets a chance after a failed request.
      }
    }

    final key = callerKey ?? getCallerKey('fetchServiceCategories');
    final request = _loadServiceCategories(key, forceRefresh: forceRefresh);
    _pendingServiceCategoryFetch = request;
    try {
      return await request;
    } finally {
      if (identical(_pendingServiceCategoryFetch, request)) {
        _pendingServiceCategoryFetch = null;
      }
    }
  }

  Future<List<ProvidedServiceCategory>> _loadServiceCategories(
    String key, {
    required bool forceRefresh,
  }) async {
    try {
      final categories = await _serviceManager.getServiceCategories(
        callerKey: key,
      );

      // A successful-but-empty response should not be cached or treated
      // as authoritative — leave state empty so the next call retries.
      if (categories.isEmpty) {
        debugPrint(
          '[ServiceNotifier] getServiceCategories returned an empty list '
          '(forceRefresh=$forceRefresh, callerKey=$key)',
        );
        storeSuccess(key, const [], responseCode: 'EMPTY');
        return serviceCategories;
      }

      _applyCategories(categories);
      storeSuccess(key, categories);

      try {
        await _categoryPersistence.save(categories);
      } catch (error, stackTrace) {
        debugPrint(
          '[ServiceNotifier] Failed to persist service categories: '
          '$error\n$stackTrace',
        );
      }

      _notifySafely();
      return serviceCategories;
    } catch (e) {
      storeFailure(key, e.toString(), errorCode: 'CATEGORY_LOAD_FAILED');
      return serviceCategories;
    }
  }

  void _applyCategories(List<ProvidedServiceCategory> categories) {
    _serviceCategories = List.unmodifiable(categories);
    _categoryHierarchy = CategoryHierarchyIndex.fromItems(
      categories,
      (category) => category.name,
    );
    _serviceCategoriesLoaded = true;
  }

  // ============ STAFF ROLES ============

  /// Fetch the staff roles for [categoryId] and cache them by id.
  ///
  /// The cache is what lets requirement cards resolve a role id into a
  /// localized label when the service payload only sent the id.
  Future<List<StaffRole>> fetchStaffRolesByCategory(
    int categoryId, {
    String? callerKey,
    bool forceRefresh = false,
  }) async {
    final key = callerKey ??
        getCallerKey('fetchStaffRolesByCategory', id: categoryId.toString());

    try {
      final roles = await _serviceManager.getStaffRolesByCategory(
        categoryId,
        callerKey: key,
      );
      registerStaffRoles(roles);
      storeSuccess(key, roles);
      return roles;
    } catch (e) {
      storeFailure(key, e.toString(), errorCode: 'ROLE_LOAD_FAILED');
      return [];
    }
  }

  // ============ INTERNAL HELPERS ============

  void _setLoading(bool value) {
    _isLoading = value;
    _notifySafely();
  }

  void _notifySafely() {
    if (!hasListeners || _notificationScheduled) return;
    _notificationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationScheduled = false;
      if (hasListeners) notifyListeners();
    });
  }

  void _resetPagination() {
    _services.clear();
    _page = 0;
    _hasMore = true;
  }

  // ============ MAIN FETCH ============

  Future<void> fetchServices({
    int serviceId = 0,
    int categoryId = 0,
    int providerId = 0,
    int userId = 0,
    String query = "",
    bool reset = false,
    String? callerKey,
  }) async {
    debugPrint(
      '[SERVICES] fetchServices ENTER '
      'providerId=$providerId currentProviderId=$_currentProviderId '
      'reset=$reset page=$_page query="$query"',
    );

    final key = callerKey ??
        getCallerKey('fetchServices',
            suffix: 'provider_${providerId}_page_$_page');

    developer.log(
      'fetchServices requested: providerId=$providerId '
      'currentProviderId=$_currentProviderId reset=$reset '
      'page=$_page query="$query"',
      name: 'ServiceNotifier',
    );

    final switchingProvider =
        providerId != 0 && providerId != _currentProviderId;
    final startingNewSearch = query.isNotEmpty && query != _searchQuery;
    if (_isLoading && !reset && !switchingProvider && !startingNewSearch) {
      debugPrint(
        '[SERVICES] fetchServices SKIPPED: already loading '
        'currentProviderId=$_currentProviderId',
      );
      developer.log(
        'fetchServices skipped because a request is already loading',
        name: 'ServiceNotifier',
      );
      return;
    }

    if (switchingProvider) {
      _currentProviderId = providerId;
      reset = true;
      _searchQuery = '';
    }

    if (query.isNotEmpty && query != _searchQuery) {
      _searchQuery = query;
      reset = true;
    }

    if (reset) {
      _resetPagination();
    }

    final effectiveProviderId =
        (providerId != 0 ? providerId : _currentProviderId) ?? 0;
    debugPrint(
      '[SERVICES] fetchServices BEFORE_API '
      'providerId=$effectiveProviderId offset=${_page * _pageSize} '
      'limit=$_pageSize reset=$reset',
    );
    developer.log(
      'fetchServices starting: providerId=$effectiveProviderId '
      'offset=${_page * _pageSize} limit=$_pageSize reset=$reset',
      name: 'ServiceNotifier',
    );

    _setLoading(true);

    final int token = ++_requestToken;
    try {
      final offset = _page * _pageSize;

      debugPrint(
        '[SERVICES] CALLING_API providerId=$effectiveProviderId '
        'offset=$offset limit=$_pageSize',
      );
      final list = await _serviceManager.getAllProvidedServices(
        offset,
        _pageSize,
        serviceId: serviceId,
        categoryId: categoryId,
        providerId: effectiveProviderId,
        userId: userId,
        query: _searchQuery.isNotEmpty ? _searchQuery : "",
        callerKey: key,
      );

      if (token != _requestToken) {
        storeFailure(key, 'Stale request cancelled',
            errorCode: 'STALE_REQUEST');
        return;
      }

      if (reset) {
        _services.clear();
      }

      if (list != null) {
        _services.addAll(list);
        storeSuccess(key, list);

        // Opportunistically harvest any inline staff roles from the
        // freshly-loaded services so requirement cards can resolve
        // labels even before fetchStaffRolesByCategory runs.
        _harvestStaffRoles(list);
      } else {
        storeSuccess(key, [], responseCode: 'EMPTY');
      }

      developer.log(
        'fetchServices completed: providerId=$effectiveProviderId '
        'received=${list?.length ?? 0} total=${_services.length} '
        'hasMore=$_hasMore',
        name: 'ServiceNotifier',
      );
      debugPrint(
        '[SERVICES] API_RESULT providerId=$effectiveProviderId '
        'received=${list?.length ?? 0} total=${_services.length}',
      );

      if ((list?.length ?? 0) < _pageSize) {
        _hasMore = false;
      } else {
        _page++;
      }

      notifyListeners();
    } catch (e) {
      debugPrint(
        '[SERVICES] API_ERROR providerId=$effectiveProviderId error=$e',
      );
      developer.log(
        'fetchServices failed: providerId=$effectiveProviderId error=$e',
        name: 'ServiceNotifier',
        error: e,
      );
      storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      logError('Error fetching services', error: e);
      rethrow;
    } finally {
      if (token == _requestToken) {
        _setLoading(false);
      }
      debugPrint(
        '[SERVICES] fetchServices EXIT '
        'providerId=$effectiveProviderId isLoading=$_isLoading '
        'total=${_services.length}',
      );
    }
  }

  /// Walk a batch of services and register any inline staff roles
  /// they carry, so the id-based lookup works without a separate
  /// fetch. Silent — no notification if nothing new arrived.
  void _harvestStaffRoles(List<ProvidedService> services) {
    var changed = false;
    for (final service in services) {
      for (final requirement in service.staffRequirements) {
        final role = requirement.staffRole;
        if (role != null && role.id > 0) {
          _staffRolesById[role.id] = role;
          changed = true;
        }
      }
    }
    if (changed) _notifySafely();
  }

  Future<ProvidedService?> fetchServiceDetails(
    int serviceId, {
    String? callerKey,
  }) async {
    final key = callerKey ??
        getCallerKey('fetchServiceDetails', id: serviceId.toString());

    _isFetchingDetails = true;
    notifyListeners();
    try {
      final ProvidedService? service = await _serviceManager
          .getProvidedService(serviceId.toString(), callerKey: key);

      if (service != null) {
        final index = _services.indexWhere((s) => s.id == serviceId);
        if (index != -1) {
          _services[index] = service;
          notifyListeners();
        }
        _harvestStaffRoles([service]);
        storeSuccess(key, service);
      } else {
        storeFailure(key, null, code: 404, errorCode: 'NOT_FOUND');
      }

      return service;
    } catch (e) {
      storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      logError('Error fetching service details', error: e);
      return null;
    } finally {
      _isFetchingDetails = false;
      notifyListeners();
    }
  }

  void clearCache() {
    _cachedServices.clear();
    logInfo('Service cache cleared');
  }

  Future<ProvidedService?> getServiceById(
    int serviceId, {
    String? callerKey,
  }) async {
    final key =
        callerKey ?? getCallerKey('getServiceById', id: serviceId.toString());

    try {
      final existingService = _services.firstWhere(
        (service) => service.id == serviceId,
      );
      storeSuccess(key, existingService, responseCode: 'CACHED');
      return existingService;
    } catch (e) {
      // Service not found in list — fall through to API.
    }

    return await fetchServiceDetails(serviceId, callerKey: key);
  }

  // ============ SEARCH ============

  Future<void> searchServices(String query, {String? callerKey}) async {
    final key = callerKey ??
        getCallerKey('searchServices', suffix: query.isEmpty ? 'empty' : query);

    _searchQuery = query.trim();
    _debounce?.cancel();

    if (query.isEmpty) {
      _searchQuery = '';
      await fetchServices(reset: true, callerKey: key);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      await fetchServices(reset: true, callerKey: key);
    });
  }

  // ============ INFINITE SCROLL ============

  Future<void> loadMore({String? callerKey}) async {
    final key = callerKey ?? getCallerKey('loadMore');
    if (_isLoading || !_hasMore || _searchQuery.isNotEmpty) return;
    await fetchServices(reset: false, callerKey: key);
  }

  // ============ REFRESH ============

  Future<void> refresh({String? callerKey}) async {
    final key = callerKey ?? getCallerKey('refresh');
    await fetchServices(reset: true, callerKey: key);
  }

  // ============ ADD ============

  Future<ProvidedService?> addService(
    ProvidedService service, {
    String? callerKey,
    String? token,
  }) async {
    final key = callerKey ?? getCallerKey('addService', suffix: service.name);

    _setLoading(true);

    try {
      final created = await _serviceManager.addProvidedService(
        service,
        callerKey: key,
        token: token,
      );

      if (created != null) {
        _services.insert(0, created);
        _harvestStaffRoles([created]);
        storeSuccess(key, created);
        notifyListeners();
      } else {
        storeFailure(key, null, code: 500, errorCode: 'ADD_FAILED');
      }
      return created;
    } catch (e) {
      storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      logError('Error adding service', error: e);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ============ UPDATE ============

  Future<ProvidedService?> updateService(
    ProvidedService service, {
    String? callerKey,
    String? token,
  }) async {
    final key =
        callerKey ?? getCallerKey('updateService', id: service.id.toString());

    _setLoading(true);

    try {
      final updated = await _serviceManager.updateProvidedService(
        service,
        callerKey: key,
        token: token,
      );

      if (updated != null) {
        final index = _services.indexWhere((s) => s.id == service.id);
        if (index != -1) {
          _services[index] = updated;
        }
        _harvestStaffRoles([updated]);
        storeSuccess(key, updated);
        notifyListeners();
      } else {
        storeFailure(key, null, code: 500, errorCode: 'UPDATE_FAILED');
      }
      return updated;
    } catch (e) {
      storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      logError('Error updating service', error: e);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ============ DELETE ============

  Future<int?> deleteService(
    int id, {
    String? callerKey,
    String? token,
  }) async {
    final key = callerKey ?? getCallerKey('deleteService', id: id.toString());

    _setLoading(true);

    try {
      final result = await _serviceManager.deleteProvidedService(
        id.toString(),
        callerKey: key,
        token: token,
      );

      if (result != null && (result == 200 || result == 204)) {
        _services.removeWhere((s) => s.id == id);
        storeSuccess(key, true);
        notifyListeners();
      } else {
        storeFailure(key, false, code: result);
      }

      return result;
    } catch (e) {
      storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      logError('Error deleting service', error: e);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ============ CLEAR SEARCH ============

  void clearSearch({String? callerKey}) {
    final key = callerKey ?? getCallerKey('clearSearch');
    if (_searchQuery.isNotEmpty) {
      _searchQuery = '';
      storeSuccess(key, true);
      notifyListeners();
    }
  }

  // ============ CLEAR ALL ============

  void clearAll({String? callerKey}) {
    final key = callerKey ?? getCallerKey('clearAll');
    _services.clear();
    _staffRolesById.clear();
    _searchQuery = '';
    _currentProviderId = null;
    _page = 0;
    _hasMore = true;
    _debounce?.cancel();
    _debounce = null;
    storeSuccess(key, true);
    logInfo('All service data cleared');
    notifyListeners();
  }
}
