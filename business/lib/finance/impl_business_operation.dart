library business;

import 'dart:developer' as developer;

import 'package:app_constants/app_constants.dart';
import 'package:verdelia_core/business/finance/BusinessOperation.dart';
import 'package:verdelia_core/business/services/BusinessOperationService.dart';
import 'package:verdelia_core/mediation/StorageService.dart';
import 'package:locator/locator.dart';

class BusinessOperationServiceImpl implements BusinessOperationService {
  @override
  Future<BusinessOperationsResponse?> getAllBusinessOperations(
    int page,
    int limit, {
    int supplierId = 0,
    int clientId = 0,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool includeStats = true,
  }) async {
    try {
      final StorageService storageService = AppLocator.get<StorageService>();

      // Build query parameters, omitting the ones the caller didn't set.
      // supplierId/clientId are treated as filters: only included when > 0.
      final queryParams = <String, String>{
        'offset': '${page * limit}',
        'limit': '$limit',
        if (supplierId > 0) 'supplier_id': '$supplierId',
        if (clientId > 0) 'client_id': '$clientId',
        if (dateFrom != null) 'date_from': _formatDate(dateFrom),
        if (dateTo != null) 'date_to': _formatDate(dateTo),
        'include_stats': includeStats ? 'true' : 'false',
      };

      final queryString = queryParams.entries
          .map((e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
          .join('&');

      // getBusinessOperationsEndpoint is expected to be the full path
      // (e.g. "/api/v1/business/operations"), WITHOUT a trailing slash.
      // Do not add "/" before the query string or the backend will 404.
      final route =
          "${AppConstants.apiBaseUrl}${AppConstants.getBusinessOperationsEndpoint}?$queryString";

      developer.log('BusinessOperations: GET $route');

      final dynamic raw = await storageService.getAll(route);

      if (raw is! Map<String, dynamic>) {
        developer.log(
          'BusinessOperations: expected envelope map, got ${raw.runtimeType}',
        );
        return null;
      }

      return BusinessOperationsResponse.fromJson(raw);
    } catch (e, stacktrace) {
      developer.log(e.toString());
      developer.log(stacktrace.toString());
      return null;
    }
  }

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  @override
  Future<BusinessOperation?> getBusinessOperation(String idBusinessOperation) {
    // TODO: implement getBusinessOperation
    throw UnimplementedError();
  }
}
