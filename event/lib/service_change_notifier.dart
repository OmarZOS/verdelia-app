import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:verdelia_core/business/finance/ProvidedService.dart';
import 'package:event/TraceableNotifier.dart';
import 'package:verdelia_core/app/VerdeliaException.dart';
import 'package:locator/locator.dart';
import 'package:verdelia_core/business/services/ProvidedServiceManagementService.dart';

class ServiceNotifier extends TraceableNotifier {
  final ProvidedServiceManagementService _serviceManager =
      AppLocator.get<ProvidedServiceManagementService>();

  final List<ProvidedService> _services = [];
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

  // GETTERS
  List<ProvidedService> get services => List.unmodifiable(_services);

  final Map<int, ProvidedService> _cachedServices = {};

  // Add a method to get cached service
  ProvidedService? getCachedService(int serviceId) {
    return _cachedServices[serviceId];
  }

  List<ProvidedService> get filteredServices {
    if (_searchQuery.isEmpty) return services;

    // Actually filter based on search query
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

  Future<List<ProvidedServiceCategory>> fetchServiceCategories(
      {String? callerKey}) async {
    final key = callerKey ?? getCallerKey('fetchServiceCategories');
    try {
      final categories =
          await _serviceManager.getServiceCategories(callerKey: key);
      storeSuccess(key, categories);
      return categories;
    } catch (e) {
      storeFailure(key, e.toString(), errorCode: 'CATEGORY_LOAD_FAILED');
      return [];
    }
  }

  Future<List<StaffRole>> fetchStaffRolesByCategory(int categoryId,
      {String? callerKey}) async {
    final key = callerKey ??
        getCallerKey('fetchStaffRolesByCategory', id: categoryId.toString());
    try {
      final roles = await _serviceManager.getStaffRolesByCategory(categoryId,
          callerKey: key);
      storeSuccess(key, roles);
      return roles;
    } catch (e) {
      storeFailure(key, e.toString(), errorCode: 'ROLE_LOAD_FAILED');
      return [];
    }
  }

  // INTERNAL HELPERS
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

  // ------------------------------------------------------------
  // 🔵 MAIN FETCH — paginated AND supports supplier switching
  // ------------------------------------------------------------
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

    if (_isLoading) {
      debugPrint(
        '[SERVICES] fetchServices SKIPPED: already loading '
        'currentProviderId=$_currentProviderId',
      );
      developer.log(
          'fetchServices skipped because a request is already loading',
          name: 'ServiceNotifier');
      return;
    }

    // Handle supplier switching
    if (providerId != 0 && providerId != _currentProviderId) {
      _currentProviderId = providerId;
      reset = true;
      // Clear search when switching suppliers
      _searchQuery = '';
    }

    // If we're searching with a new query, reset
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
        // stale request
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

  Future<ProvidedService?> fetchServiceDetails(int serviceId,
      {String? callerKey}) async {
    final key = callerKey ??
        getCallerKey('fetchServiceDetails', id: serviceId.toString());

    _isFetchingDetails = true;
    notifyListeners();
    try {
      final ProvidedService? service = await _serviceManager
          .getProvidedService(serviceId.toString(), callerKey: key);

      if (service != null) {
        // Update the service in the list if it exists
        final index = _services.indexWhere((s) => s.id == serviceId);
        if (index != -1) {
          _services[index] = service;
          notifyListeners();
        }
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

  // Add clear cache method if needed
  void clearCache() {
    _cachedServices.clear();
    logInfo('Service cache cleared');
  }

  Future<ProvidedService?> getServiceById(int serviceId,
      {String? callerKey}) async {
    final key =
        callerKey ?? getCallerKey('getServiceById', id: serviceId.toString());

    // First check if we already have this service in our list
    try {
      final existingService = _services.firstWhere(
        (service) => service.id == serviceId,
      );
      storeSuccess(key, existingService, responseCode: 'CACHED');
      return existingService;
    } catch (e) {
      // Service not found in list
    }

    // If not in list, fetch from API
    return await fetchServiceDetails(serviceId, callerKey: key);
  }

  // ------------------------------------------------------------
  // 🔎 DEBOUNCED SEARCH (300 ms)
  // ------------------------------------------------------------
  Future<void> searchServices(String query, {String? callerKey}) async {
    final key = callerKey ??
        getCallerKey('searchServices', suffix: query.isEmpty ? 'empty' : query);

    _searchQuery = query.trim();
    _debounce?.cancel();

    if (query.isEmpty) {
      // Clear search and reload
      _searchQuery = '';
      await fetchServices(reset: true, callerKey: key);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      await fetchServices(reset: true, callerKey: key);
    });
  }

  // ------------------------------------------------------------
  // ⬇️ INFINITE SCROLL
  // ------------------------------------------------------------
  Future<void> loadMore({String? callerKey}) async {
    final key = callerKey ?? getCallerKey('loadMore');
    if (_isLoading || !_hasMore || _searchQuery.isNotEmpty) return;
    await fetchServices(reset: false, callerKey: key);
  }

  // ------------------------------------------------------------
  // 🔄 REFRESH
  // ------------------------------------------------------------
  Future<void> refresh({String? callerKey}) async {
    final key = callerKey ?? getCallerKey('refresh');
    await fetchServices(reset: true, callerKey: key);
  }

  // ------------------------------------------------------------
  // 🟢 ADD SERVICE
  // ------------------------------------------------------------
  Future<ProvidedService?> addService(ProvidedService service,
      {String? callerKey, String? token}) async {
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

  // ------------------------------------------------------------
  // 🟡 UPDATE SERVICE
  // ------------------------------------------------------------
  Future<ProvidedService?> updateService(ProvidedService service,
      {String? callerKey, String? token}) async {
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

  // ------------------------------------------------------------
  // 🔴 DELETE SERVICE
  // ------------------------------------------------------------
  Future<int?> deleteService(int id, {String? callerKey, String? token}) async {
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

  // ------------------------------------------------------------
  // CLEAR SEARCH
  // ------------------------------------------------------------
  void clearSearch({String? callerKey}) {
    final key = callerKey ?? getCallerKey('clearSearch');
    if (_searchQuery.isNotEmpty) {
      _searchQuery = '';
      storeSuccess(key, true);
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // CLEAR SELECTED SERVICE
  // ------------------------------------------------------------
  // void clearSelectedService() {
  //   _selectedService = null;
  // }

  // ------------------------------------------------------------
  // CLEAR ALL (for logout or cleanup)
  // ------------------------------------------------------------
  void clearAll({String? callerKey}) {
    final key = callerKey ?? getCallerKey('clearAll');
    _services.clear();
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
