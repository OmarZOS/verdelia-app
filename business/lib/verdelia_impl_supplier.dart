// business/lib/supplier_service_impl.dart

library business;

import 'dart:developer' as developer;
import 'package:app_constants/app_constants.dart';
import 'package:verdelia_core/business/Organisation.dart';
import 'package:verdelia_core/business/Supplier.dart';
import 'package:verdelia_core/business/services/SupplierService.dart';
import 'package:verdelia_core/mediation/StorageService.dart';
import 'package:locator/locator.dart';

class SupplierServiceImpl extends SupplierService {
  List<SupplierCategory> _categories = [];

  // Helper method to generate caller key
  String _getCallerKey(String method, {String? id, String? suffix}) {
    final parts = [method];
    if (id != null) parts.add(id);
    if (suffix != null) parts.add(suffix);
    if (parts.length == 1)
      parts.add(DateTime.now().millisecondsSinceEpoch.toString());
    return parts.join('_');
  }

  @override
  Future<SupplierCategory?> getCategoryById(int categoryId,
      {String? callerKey}) async {
    final key = callerKey ??
        _getCallerKey('getCategoryById', id: categoryId.toString());

    try {
      if (_categories.isEmpty) {
        await getCategories();
      }

      if (categoryId <= 0 || categoryId > _categories.length) {
        developer.log('Invalid category ID: $categoryId',
            name: 'SupplierServiceImpl');
        setFailureResponse(key, null,
            statusCode: 400, responseCode: 'INVALID_CATEGORY_ID');
        return null;
      }

      final category = _categories[categoryId - 1];
      setSuccessResponse(key, category,
          statusCode: 200, responseCode: 'SUCCESS');
      return category;
    } catch (e, stacktrace) {
      developer.log('Error getting category by ID: $e',
          name: 'SupplierServiceImpl');
      developer.log('Stacktrace: $stacktrace', name: 'SupplierServiceImpl');
      setFailureResponse(key, e.toString(),
          statusCode: 500, responseCode: 'ERROR_GETTING_CATEGORY');
      return null;
    }
  }

  @override
  Future<List<SupplierCategory>> getCategories({String? callerKey}) async {
    final key = callerKey ?? _getCallerKey('getCategories');

    if (_categories.isNotEmpty) {
      developer.log('Returning cached categories: ${_categories.length}',
          name: 'SupplierServiceImpl');
      setSuccessResponse(key, _categories,
          statusCode: 200, responseCode: 'CACHED');
      return _categories;
    }

    try {
      final storageService = AppLocator.get<StorageService>();

      const url =
          '${AppConstants.apiBaseUrl}${AppConstants.getSupplierCategoriesEndpoint}';
      developer.log('Fetching supplier categories from: $url',
          name: 'SupplierServiceImpl');

      final responseData = await storageService.getAll(url, callerKey: key);

      // Get status info from storage service
      final statusCode = storageService.getStatusCode(key);
      final responseCode = storageService.getResponseCode(key);

      if (responseData == null) {
        developer.log('No categories found', name: 'SupplierServiceImpl');
        setFailureResponse(key, null,
            statusCode: statusCode ?? 404, responseCode: 'NO_CATEGORIES');
        return [];
      }

      List<SupplierCategory> categories = [];

      if (responseData is List) {
        categories = responseData
            .map((data) =>
                SupplierCategory.fromJson(data as Map<String, dynamic>))
            .toList();
      } else if (responseData is Map && responseData.containsKey('data')) {
        final dataList = responseData['data'];
        if (dataList is List) {
          categories = dataList
              .map((data) =>
                  SupplierCategory.fromJson(data as Map<String, dynamic>))
              .toList();
        }
      }

      _categories = categories;
      developer.log('Found ${_categories.length} categories',
          name: 'SupplierServiceImpl');

      setSuccessResponse(key, _categories,
          statusCode: statusCode ?? 200, responseCode: 'SUCCESS');
      return _categories;
    } catch (e, stacktrace) {
      developer.log('Error getting categories: $e',
          name: 'SupplierServiceImpl');
      developer.log('Stacktrace: $stacktrace', name: 'SupplierServiceImpl');
      setFailureResponse(key, e.toString(),
          statusCode: 500, responseCode: 'ERROR_GETTING_CATEGORIES');
      return [];
    }
  }

  @override
  Future<Supplier?> addSupplier(Supplier supplier,
      {String? callerKey, String? token}) async {
    final key = callerKey ??
        _getCallerKey('addSupplier', suffix: supplier.providerName);

    try {
      final storageService = AppLocator.get<StorageService>();

      developer.log('Adding supplier: ${supplier.toJson()}',
          name: 'SupplierServiceImpl');

      final result = await storageService.insert(
          '${AppConstants.apiBaseUrl}${AppConstants.addSupplierEndpoint}',
          supplier.toJson(),
          callerKey: key,
          token: token);

      final statusCode = storageService.getStatusCode(key);
      final responseCode = storageService.getResponseCode(key);

      developer.log('Add supplier result: $result',
          name: 'SupplierServiceImpl');

      if (result == null) {
        developer.log('Failed to add supplier: null response',
            name: 'SupplierServiceImpl');
        setFailureResponse(key, null,
            statusCode: statusCode ?? 500, responseCode: 'ADD_FAILED');
        return null;
      }

      final createdSupplier = Supplier.fromJson(result as Map<String, dynamic>);
      setSuccessResponse(key, createdSupplier,
          statusCode: statusCode ?? 200, responseCode: 'SUCCESS');
      return createdSupplier;
    } catch (e, stacktrace) {
      developer.log('Error adding supplier: $e', name: 'SupplierServiceImpl');
      developer.log('Stacktrace: $stacktrace', name: 'SupplierServiceImpl');
      setFailureResponse(key, e.toString(),
          statusCode: 500, responseCode: 'ERROR_ADDING_SUPPLIER');
      return null;
    }
  }

  @override
  Future<int?> deleteSupplier(String supplierId,
      {String? callerKey, String? token}) async {
    final key = callerKey ?? _getCallerKey('deleteSupplier', id: supplierId);

    try {
      final storageService = AppLocator.get<StorageService>();

      developer.log('Deleting supplier: $supplierId',
          name: 'SupplierServiceImpl');

      final result = await storageService.delete(
          '${AppConstants.apiBaseUrl}${AppConstants.deleteSupplierEndpoint}',
          supplierId,
          callerKey: key,
          token: token);

      final statusCode = storageService.getStatusCode(key);
      final responseCode = storageService.getResponseCode(key);

      developer.log('Delete result: $result', name: 'SupplierServiceImpl');

      if (result == 200 || result == 204) {
        setSuccessResponse(key, true,
            statusCode: result, responseCode: 'SUCCESS');
      } else {
        setFailureResponse(key, false,
            statusCode: result, responseCode: 'DELETE_FAILED');
      }

      return result;
    } catch (e, stacktrace) {
      developer.log('Error deleting supplier: $e', name: 'SupplierServiceImpl');
      developer.log('Stacktrace: $stacktrace', name: 'SupplierServiceImpl');
      setFailureResponse(key, e.toString(),
          statusCode: 500, responseCode: 'ERROR_DELETING_SUPPLIER');
      return null;
    }
  }

  @override
  Future<Supplier?> updateSupplier(Supplier updatedSupplier,
      {String? callerKey, String? token}) async {
    final key = callerKey ??
        _getCallerKey('updateSupplier',
            id: updatedSupplier.idProductProvider.toString());

    try {
      final storageService = AppLocator.get<StorageService>();

      const url =
          '${AppConstants.apiBaseUrl}${AppConstants.updateSupplierEndpoint}';

      developer.log('Updating supplier at: $url', name: 'SupplierServiceImpl');
      developer.log('Supplier data: ${updatedSupplier.toJson()}',
          name: 'SupplierServiceImpl');

      final result = await storageService.update(
          url,
          updatedSupplier.idProductProvider.toString(),
          {"supplier_id": updatedSupplier.idProductProvider.toString()},
          updatedSupplier.toJson(),
          callerKey: key,
          token: token);

      final statusCode = storageService.getStatusCode(key);
      final responseCode = storageService.getResponseCode(key);

      developer.log('Update result: $result', name: 'SupplierServiceImpl');

      if (result == null) {
        developer.log('Failed to update supplier: null response',
            name: 'SupplierServiceImpl');
        setFailureResponse(key, null,
            statusCode: statusCode ?? 500, responseCode: 'UPDATE_FAILED');
        return null;
      }

      final updated = Supplier.fromJson(result as Map<String, dynamic>);
      setSuccessResponse(key, updated,
          statusCode: statusCode ?? 200, responseCode: 'SUCCESS');
      return updated;
    } catch (e, stacktrace) {
      developer.log('Error updating supplier: $e', name: 'SupplierServiceImpl');
      developer.log('Stacktrace: $stacktrace', name: 'SupplierServiceImpl');
      setFailureResponse(key, e.toString(),
          statusCode: 500, responseCode: 'ERROR_UPDATING_SUPPLIER');
      return null;
    }
  }

  @override
  Future<List<Supplier>?> getSuppliersByIds(List<int> ids) async {
    if (ids.isEmpty) {
      developer.log('No supplier IDs provided', name: 'SupplierServiceImpl');
      return Future.value([]);
    }

    final key = _getCallerKey('getSuppliersByIds', suffix: ids.join('_'));

    try {
      final storageService = AppLocator.get<StorageService>();

      final url =
          '${AppConstants.apiBaseUrl}${AppConstants.getSuppliersByIdsEndpoint}';
      developer.log('Fetching suppliers by IDs from: $url',
          name: 'SupplierServiceImpl');

      final responseData = await storageService.insert(
        url,
        {'provider_ids': ids},
        callerKey: key,
      );

      final statusCode = storageService.getStatusCode(key);
      final responseCode = storageService.getResponseCode(key);

      if (responseData == null) {
        developer.log('No suppliers found for provided IDs',
            name: 'SupplierServiceImpl');
        setFailureResponse(key, null,
            statusCode: statusCode ?? 404, responseCode: 'NO_SUPPLIERS_FOUND');
        return [];
      }

      List<Supplier> suppliers = [];

      if (responseData is List) {
        suppliers = responseData
            .map((data) => Supplier.fromJson(data as Map<String, dynamic>))
            .toList();
      } else if (responseData is Map && responseData.containsKey('data')) {
        final dataList = responseData['data'];
        if (dataList is List) {
          suppliers = dataList
              .map((data) => Supplier.fromJson(data as Map<String, dynamic>))
              .toList();
        }
      }

      developer.log('Found ${suppliers.length} suppliers for provided IDs',
          name: 'SupplierServiceImpl');
      setSuccessResponse(key, suppliers,
          statusCode: statusCode ?? 200, responseCode: 'SUCCESS');
      return suppliers;
    } catch (e, stacktrace) {
      developer.log('Error fetching suppliers by IDs: $e',
          name: 'SupplierServiceImpl');
      developer.log('Stacktrace: $stacktrace', name: 'SupplierServiceImpl');
      setFailureResponse(key, e.toString(),
          statusCode: 500, responseCode: 'ERROR_FETCHING_SUPPLIERS_BY_IDS');
      return null;
    }
  }

  @override
  Future<Supplier?> getSupplier(String id, {String? callerKey}) async {
    final key = callerKey ?? _getCallerKey('getSupplier', id: id);

    try {
      final storageService = AppLocator.get<StorageService>();

      final url =
          '${AppConstants.apiBaseUrl}${AppConstants.supplierEndpoint}/$id';
      developer.log('Getting supplier from: $url', name: 'SupplierServiceImpl');

      final responseData = await storageService.get(
        '${AppConstants.apiBaseUrl}${AppConstants.supplierEndpoint}',
        id,
        callerKey: key,
      );

      final statusCode = storageService.getStatusCode(key);
      final responseCode = storageService.getResponseCode(key);

      if (responseData == null) {
        developer.log('Supplier not found: $id', name: 'SupplierServiceImpl');
        setFailureResponse(key, null,
            statusCode: statusCode ?? 404, responseCode: 'NOT_FOUND');
        return null;
      }

      Supplier? supplier;

      // Handle different response formats
      if (responseData is List && responseData.isNotEmpty) {
        supplier = Supplier.fromJson(responseData[0] as Map<String, dynamic>);
      } else if (responseData is Map) {
        supplier = Supplier.fromJson(responseData as Map<String, dynamic>);
      }

      if (supplier != null) {
        setSuccessResponse(key, supplier,
            statusCode: statusCode ?? 200, responseCode: 'SUCCESS');
      } else {
        setFailureResponse(key, responseData,
            statusCode: statusCode ?? 500, responseCode: 'INVALID_FORMAT');
      }

      return supplier;
    } catch (e, stacktrace) {
      developer.log('Error getting supplier: $e', name: 'SupplierServiceImpl');
      developer.log('Stacktrace: $stacktrace', name: 'SupplierServiceImpl');
      setFailureResponse(key, e.toString(),
          statusCode: 500, responseCode: 'ERROR_GETTING_SUPPLIER');
      return null;
    }
  }

  @override
  Future<List<Supplier>> searchSuppliersByToken(
    String token,
    int offset,
    int itemsPerPage, {
    String? callerKey,
  }) async {
    final key =
        callerKey ?? _getCallerKey('searchSuppliersByToken', suffix: token);

    try {
      final storageService = AppLocator.get<StorageService>();

      final url =
          '${AppConstants.apiBaseUrl}${AppConstants.getSupplierSearchByTokenEndpoint}/$token/$offset/$itemsPerPage';
      developer.log('Searching suppliers with token: $token',
          name: 'SupplierServiceImpl');

      final responseData = await storageService.getAll(url, callerKey: key);

      final statusCode = storageService.getStatusCode(key);
      final responseCode = storageService.getResponseCode(key);

      if (responseData == null) {
        developer.log('No suppliers found for search',
            name: 'SupplierServiceImpl');
        setFailureResponse(key, null,
            statusCode: statusCode ?? 404, responseCode: 'NO_RESULTS');
        return [];
      }

      List<Supplier> suppliers = [];

      if (responseData is List) {
        suppliers = responseData
            .map(
                (data) => Supplier.fromSearchJson(data as Map<String, dynamic>))
            .toList();
      } else if (responseData is Map && responseData.containsKey('data')) {
        final dataList = responseData['data'];
        if (dataList is List) {
          suppliers = dataList
              .map((data) =>
                  Supplier.fromSearchJson(data as Map<String, dynamic>))
              .toList();
        }
      }

      developer.log('Found ${suppliers.length} suppliers',
          name: 'SupplierServiceImpl');
      setSuccessResponse(key, suppliers,
          statusCode: statusCode ?? 200, responseCode: 'SUCCESS');
      return suppliers;
    } catch (e, stacktrace) {
      developer.log('Error searching suppliers by token: $e',
          name: 'SupplierServiceImpl');
      developer.log('Stacktrace: $stacktrace', name: 'SupplierServiceImpl');
      setFailureResponse(key, e.toString(),
          statusCode: 500, responseCode: 'ERROR_SEARCHING_SUPPLIERS');
      return [];
    }
  }

  @override
  Future<List<Supplier>> searchSuppliersByGeo(
    double longitude,
    double latitude,
    int offset,
    int itemsPerPage,
    double distance, {
    String? callerKey,
  }) async {
    // Include every parameter that affects the result. `distance`,
    // `offset`, and `itemsPerPage` change the response, so they must
    // change the cache key — otherwise switching the distance slider
    // would return stale results.
    final key = callerKey ??
        _getCallerKey(
          'searchSuppliersByGeo',
          suffix:
              '${longitude}_${latitude}_${distance}_${offset}_$itemsPerPage',
        );

    try {
      final storageService = AppLocator.get<StorageService>();

      // Query-parameter endpoint. The path portion is only
      // `/search/position/supplier`; all values travel as query params.
      final uri = Uri.parse(
        '${AppConstants.apiBaseUrl}${AppConstants.getSupplierSearchByGeoEndpoint}',
      ).replace(
        queryParameters: {
          'longitude': longitude.toString(),
          'latitude': latitude.toString(),
          'distance_km': distance.toString(),
          'offset': offset.toString(),
          'limit': itemsPerPage.toString(),
        },
      );
      final url = uri.toString();

      developer.log(
        'Searching suppliers near: ($longitude, $latitude) '
        'within ${distance}km, offset=$offset, limit=$itemsPerPage',
        name: 'SupplierServiceImpl',
      );

      final responseData = await storageService.getAll(url, callerKey: key);

      final statusCode = storageService.getStatusCode(key);
      final responseCode = storageService.getResponseCode(key);

      if (responseData == null) {
        developer.log('No suppliers found for location',
            name: 'SupplierServiceImpl');
        setFailureResponse(key, null,
            statusCode: statusCode ?? 404, responseCode: 'NO_RESULTS');
        return [];
      }

      List<Supplier> suppliers = [];

      if (responseData is List) {
        suppliers = responseData
            .whereType<Map<String, dynamic>>()
            .map(Supplier.fromSearchJson)
            .toList();
      } else if (responseData is Map && responseData.containsKey('data')) {
        final dataList = responseData['data'];
        if (dataList is List) {
          suppliers = dataList
              .whereType<Map<String, dynamic>>()
              .map(Supplier.fromSearchJson)
              .toList();
        }
      }

      developer.log('Found ${suppliers.length} suppliers near location',
          name: 'SupplierServiceImpl');
      setSuccessResponse(key, suppliers,
          statusCode: statusCode ?? 200, responseCode: 'SUCCESS');
      return suppliers;
    } catch (e, stacktrace) {
      developer.log('Error searching suppliers by geo: $e',
          name: 'SupplierServiceImpl');
      developer.log('Stacktrace: $stacktrace', name: 'SupplierServiceImpl');
      setFailureResponse(key, e.toString(),
          statusCode: 500, responseCode: 'ERROR_SEARCHING_BY_GEO');
      return [];
    }
  }

  @override
  Future<List<Supplier>> getAllSuppliers(
    int ownerId,
    int orgId,
    int offset,
    int itemsPerPage, {
    String? callerKey,
  }) async {
    final key = callerKey ??
        _getCallerKey('getAllSuppliers',
            suffix: '${ownerId}_${orgId}_${offset}_$itemsPerPage');

    try {
      final storageService = AppLocator.get<StorageService>();
      // Build URL with query parameters
      final url =
          '${AppConstants.apiBaseUrl}${AppConstants.getAllSuppliersEndpoint}'
          '?owner_id=$ownerId&org_id=$orgId&offset=$offset&limit=$itemsPerPage';

      developer.log('Getting all suppliers from: $url',
          name: 'SupplierServiceImpl');

      final responseData = await storageService.getAll(url, callerKey: key);

      final statusCode = storageService.getStatusCode(key);
      final responseCode = storageService.getResponseCode(key);

      if (responseData == null) {
        developer.log('No suppliers found', name: 'SupplierServiceImpl');
        setFailureResponse(key, null,
            statusCode: statusCode ?? 404, responseCode: 'NO_SUPPLIERS');
        return [];
      }

      List<Supplier> suppliers = [];

      if (responseData is List) {
        suppliers = responseData
            .map((data) => Supplier.fromJson(data as Map<String, dynamic>))
            .toList();
      } else if (responseData is Map && responseData.containsKey('data')) {
        final dataList = responseData['data'];
        if (dataList is List) {
          suppliers = dataList
              .map((data) => Supplier.fromJson(data as Map<String, dynamic>))
              .toList();
        }
      }

      developer.log('Found ${suppliers.length} suppliers',
          name: 'SupplierServiceImpl');
      setSuccessResponse(key, suppliers,
          statusCode: statusCode ?? 200, responseCode: 'SUCCESS');
      return suppliers;
    } catch (e, stacktrace) {
      developer.log('Error getting all suppliers: $e',
          name: 'SupplierServiceImpl');
      developer.log('Stacktrace: $stacktrace', name: 'SupplierServiceImpl');
      setFailureResponse(key, e.toString(),
          statusCode: 500, responseCode: 'ERROR_GETTING_ALL_SUPPLIERS');
      return [];
    }
  }

  @override
  Future<List<Organisation>> getAllOrganisations(
    int ownerId,
    int orgId,
    int offset,
    int itemsPerPage, {
    String? callerKey,
  }) async {
    final key = callerKey ??
        _getCallerKey('getAllOrganisations',
            suffix: '${ownerId}_${orgId}_${offset}_$itemsPerPage');

    try {
      final storageService = AppLocator.get<StorageService>();

      // Build URL with query parameters
      final url =
          '${AppConstants.apiBaseUrl}${AppConstants.getOrganisationsEndpoint}'
          '?offset=$offset&limit=$itemsPerPage';

      if (ownerId > 0) {
        // Add owner filter if needed
      }

      developer.log('Getting organisations from: $url',
          name: 'SupplierServiceImpl');

      final responseData = await storageService.getAll(url, callerKey: key);

      final statusCode = storageService.getStatusCode(key);
      final responseCode = storageService.getResponseCode(key);

      if (responseData == null) {
        developer.log('No organisations found', name: 'SupplierServiceImpl');
        setFailureResponse(key, null,
            statusCode: statusCode ?? 404, responseCode: 'NO_ORGANISATIONS');
        return [];
      }

      List<Organisation> organisations = [];

      if (responseData is List) {
        organisations = responseData
            .map((data) => Organisation.fromJson(data as Map<String, dynamic>))
            .toList();
      } else if (responseData is Map && responseData.containsKey('data')) {
        final dataList = responseData['data'];
        if (dataList is List) {
          organisations = dataList
              .map(
                  (data) => Organisation.fromJson(data as Map<String, dynamic>))
              .toList();
        }
      }

      developer.log('Found ${organisations.length} organisations',
          name: 'SupplierServiceImpl');
      setSuccessResponse(key, organisations,
          statusCode: statusCode ?? 200, responseCode: 'SUCCESS');
      return organisations;
    } catch (e, stacktrace) {
      developer.log('Error getting organisations: $e',
          name: 'SupplierServiceImpl');
      developer.log('Stacktrace: $stacktrace', name: 'SupplierServiceImpl');
      setFailureResponse(key, e.toString(),
          statusCode: 500, responseCode: 'ERROR_GETTING_ORGANISATIONS');
      return [];
    }
  }

  // Helper method to clear cache
  void clearCache() {
    _categories.clear();
    developer.log('Supplier service cache cleared',
        name: 'SupplierServiceImpl');
  }

  // Helper method to refresh categories
  Future<List<SupplierCategory>> refreshCategories({String? callerKey}) async {
    _categories.clear();
    return await getCategories(callerKey: callerKey);
  }

  @override
  Future<Organisation?> getOrganisation(String id, {String? callerKey}) async {
    final key = callerKey ?? _getCallerKey('getOrganisation', id: id);

    try {
      final storageService = AppLocator.get<StorageService>();

      final url =
          '${AppConstants.apiBaseUrl}${AppConstants.getOrganisationsEndpoint}/$id';
      developer.log('Getting organisation from: $url',
          name: 'SupplierServiceImpl');

      final responseData = await storageService.get(
        '${AppConstants.apiBaseUrl}${AppConstants.getOrganisationsEndpoint}',
        id,
        callerKey: key,
      );

      final statusCode = storageService.getStatusCode(key);

      if (responseData == null) {
        developer.log('Organisation not found: $id',
            name: 'SupplierServiceImpl');
        setFailureResponse(key, null,
            statusCode: statusCode ?? 404,
            responseCode: 'ORGANISATION_NOT_FOUND');
        return null;
      }

      Organisation? organisation;

      // Handle different response formats
      if (responseData is List && responseData.isNotEmpty) {
        organisation =
            Organisation.fromJson(responseData[0] as Map<String, dynamic>);
      } else if (responseData is Map) {
        organisation =
            Organisation.fromJson(responseData as Map<String, dynamic>);
      }

      if (organisation != null) {
        setSuccessResponse(key, organisation,
            statusCode: statusCode ?? 200, responseCode: 'SUCCESS');
      } else {
        setFailureResponse(key, responseData,
            statusCode: statusCode ?? 500, responseCode: 'INVALID_FORMAT');
      }

      return organisation;
    } catch (e, stacktrace) {
      developer.log('Error getting organisation: $e',
          name: 'SupplierServiceImpl');
      developer.log('Stacktrace: $stacktrace', name: 'SupplierServiceImpl');
      setFailureResponse(key, e.toString(),
          statusCode: 500, responseCode: 'ERROR_GETTING_ORGANISATION');
      return null;
    }
  }

  @override
  Future<Organisation?> addOrganisation(Organisation organisation,
      {String? callerKey, String? token}) async {
    final key = callerKey ??
        _getCallerKey('addOrganisation',
            suffix: organisation.provider_organisation_name);

    try {
      final storageService = AppLocator.get<StorageService>();

      developer.log('Adding organisation: ${organisation.toJson()}',
          name: 'SupplierServiceImpl');

      final result = await storageService.insert(
          '${AppConstants.apiBaseUrl}${AppConstants.createOrganisationEndpoint}',
          organisation.toJson(),
          callerKey: key,
          token: token);

      final statusCode = storageService.getStatusCode(key);

      developer.log('Add organisation result: $result',
          name: 'SupplierServiceImpl');

      if (result == null) {
        developer.log('Failed to add organisation: null response',
            name: 'SupplierServiceImpl');
        setFailureResponse(key, null,
            statusCode: statusCode ?? 500,
            responseCode: 'ADD_ORGANISATION_FAILED');
        return null;
      }

      final createdOrganisation =
          Organisation.fromJson(result as Map<String, dynamic>);
      setSuccessResponse(key, createdOrganisation,
          statusCode: statusCode ?? 200, responseCode: 'SUCCESS');
      return createdOrganisation;
    } catch (e, stacktrace) {
      developer.log('Error adding organisation: $e',
          name: 'SupplierServiceImpl');
      developer.log('Stacktrace: $stacktrace', name: 'SupplierServiceImpl');
      setFailureResponse(key, e.toString(),
          statusCode: 500, responseCode: 'ERROR_ADDING_ORGANISATION');
      return null;
    }
  }

  @override
  Future<Organisation?> updateOrganisation(Organisation updatedOrganisation,
      {String? callerKey, String? token}) async {
    final key = callerKey ??
        _getCallerKey('updateOrganisation',
            id: updatedOrganisation.id_provider_organisation.toString());

    try {
      final storageService = AppLocator.get<StorageService>();

      const url =
          '${AppConstants.apiBaseUrl}${AppConstants.updateOrganisationEndpoint}';

      developer.log('Updating organisation at: $url',
          name: 'SupplierServiceImpl');
      developer.log('Organisation data: ${updatedOrganisation.toJson()}',
          name: 'SupplierServiceImpl');

      final result = await storageService.update(
          url,
          updatedOrganisation.id_provider_organisation.toString(),
          {
            "organisation_id":
                updatedOrganisation.id_provider_organisation.toString()
          },
          updatedOrganisation.toJson(),
          callerKey: key,
          token: token);

      final statusCode = storageService.getStatusCode(key);

      developer.log('Update organisation result: $result',
          name: 'SupplierServiceImpl');

      if (result == null) {
        developer.log('Failed to update organisation: null response',
            name: 'SupplierServiceImpl');
        setFailureResponse(key, null,
            statusCode: statusCode ?? 500,
            responseCode: 'UPDATE_ORGANISATION_FAILED');
        return null;
      }

      final updated = Organisation.fromJson(result as Map<String, dynamic>);
      setSuccessResponse(key, updated,
          statusCode: statusCode ?? 200, responseCode: 'SUCCESS');
      return updated;
    } catch (e, stacktrace) {
      developer.log('Error updating organisation: $e',
          name: 'SupplierServiceImpl');
      developer.log('Stacktrace: $stacktrace', name: 'SupplierServiceImpl');
      setFailureResponse(key, e.toString(),
          statusCode: 500, responseCode: 'ERROR_UPDATING_ORGANISATION');
      return null;
    }
  }

  @override
  Future<int?> deleteOrganisation(String id,
      {String? callerKey, String? token}) async {
    final key = callerKey ?? _getCallerKey('deleteOrganisation', id: id);

    try {
      final storageService = AppLocator.get<StorageService>();

      developer.log('Deleting organisation: $id', name: 'SupplierServiceImpl');

      final result = await storageService.delete(
          '${AppConstants.apiBaseUrl}${AppConstants.deleteOrganisationEndpoint}',
          id,
          callerKey: key,
          token: token);

      final statusCode = storageService.getStatusCode(key);

      developer.log('Delete organisation result: $result',
          name: 'SupplierServiceImpl');

      if (result == 200 || result == 204) {
        setSuccessResponse(key, true,
            statusCode: result, responseCode: 'SUCCESS');
      } else {
        setFailureResponse(key, false,
            statusCode: result, responseCode: 'DELETE_ORGANISATION_FAILED');
      }

      return result;
    } catch (e, stacktrace) {
      developer.log('Error deleting organisation: $e',
          name: 'SupplierServiceImpl');
      developer.log('Stacktrace: $stacktrace', name: 'SupplierServiceImpl');
      setFailureResponse(key, e.toString(),
          statusCode: 500, responseCode: 'ERROR_DELETING_ORGANISATION');
      return null;
    }
  }
}
