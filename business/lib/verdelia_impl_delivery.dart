library business;

import 'dart:developer' as developer;

import 'package:app_constants/app_constants.dart';
import 'package:verdelia_core/business/Delivery.dart';
import 'package:verdelia_core/business/services/DeliveryService.dart';
import 'package:verdelia_core/app/VerdeliaException.dart';
import 'package:verdelia_core/mediation/StorageService.dart';
import 'package:locator/locator.dart';

class DeliveryServiceImpl extends DeliveryService {
  final StorageService _storageService = AppLocator.get<StorageService>();

  void _log(String message) {
    developer.log(message, name: 'DeliveryServiceImpl');
  }

  String _getCallerKey(String method, {String? id, String? suffix}) {
    final parts = [method];
    if (id != null) parts.add(id);
    if (suffix != null) parts.add(suffix);
    if (parts.length == 1) {
      parts.add(DateTime.now().millisecondsSinceEpoch.toString());
    }
    return parts.join('_');
  }

  void _storeSuccess(String key, dynamic data,
      {int? code, String? responseCode}) {
    _storageService.setSuccessResponse(key, data,
        statusCode: code ?? 200, responseCode: responseCode ?? 'SUCCESS');
  }

  void _storeFailure(String key, dynamic data,
      {int? code, String? errorCode, String? message}) {
    _storageService.setFailureResponse(key,
        data: data,
        statusCode: code ?? 500,
        errorCode: errorCode,
        message: message);
  }

  // ==================== READ ====================

  /// GET /api/v1/business/delivery
  ///
  /// The router requires at least one filter (provider / source / status).
  /// We forward `provider_id` when > 0, `status` when non-empty, and
  /// derive `source_id` when `orderId > 0`.
  @override
  Future<List<Delivery>> getAllDeliveries(
    int offset,
    int limit, {
    int providerId = 0,
    int orderId = 0,
    int brokerId = 0,
    String? callerKey,
  }) async {
    final key = callerKey ??
        _getCallerKey('getAllDeliveries',
            suffix: 'offset_$offset-limit_$limit');
    try {
      final Map<String, String> queryParams = {
        'offset': offset.toString(),
        'limit': limit.toString(),
      };
      if (providerId > 0) queryParams['provider_id'] = providerId.toString();
      if (orderId > 0) {
        queryParams['source_type'] = 'placed_order';
        queryParams['source_id'] = orderId.toString();
      }
      if (brokerId > 0) queryParams['broker_id'] = brokerId.toString();

      final queryString = Uri(queryParameters: queryParams).query;
      final url = '${AppConstants.apiBaseUrl}'
          '${AppConstants.getAllDeliveriesEndpoint}?$queryString';

      _log('Fetching deliveries from: $url');
      final responseData = await _storageService.getAll(url, callerKey: key);

      if (responseData == null ||
          (responseData is Iterable && responseData.isEmpty) ||
          (responseData is Map && responseData.isEmpty)) {
        _log('No deliveries found');
        _storeSuccess(key, [], responseCode: 'EMPTY');
        return [];
      }

      final List<dynamic> dataList = _extractList(responseData);
      final List<Delivery> deliveries = dataList
          .map((data) => Delivery.fromJson(data as Map<String, dynamic>))
          .toList();

      _log('Found ${deliveries.length} deliveries');
      _storeSuccess(key, deliveries);
      return deliveries;
    } catch (e, stackTrace) {
      _log('Error getting all deliveries: $e');
      _log('Stacktrace: $stackTrace');
      _storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      return [];
    }
  }

  /// GET /api/v1/business/delivery/{delivery_id}
  @override
  Future<Delivery?> getDelivery(String id, {String? callerKey}) async {
    final key = callerKey ?? _getCallerKey('getDelivery', id: id);
    try {
      const url = '${AppConstants.apiBaseUrl}'
          '${AppConstants.getDeliveryDetailsEndpoint}';
      _log('Fetching delivery $id from: $url');

      final data = await _storageService.get(url, id, callerKey: key);
      if (data == null) {
        _log('Delivery not found: $id');
        _storeFailure(key, null, code: 404, errorCode: 'NOT_FOUND');
        return null;
      }

      final delivery = Delivery.fromJson(data as Map<String, dynamic>);
      _storeSuccess(key, delivery);
      return delivery;
    } catch (e) {
      _log('Error getting delivery $id: $e');
      _storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      return null;
    }
  }

  // ==================== CREATE ====================

  /// POST /api/v1/business/delivery
  ///
  /// `deliveryData` must be a JSON-encodable map matching Delivery_API.
  @override
  Future<Delivery?> addDelivery(dynamic deliveryData,
      {String? callerKey}) async {
    final key = callerKey ?? _getCallerKey('addDelivery');
    try {
      final url = '${AppConstants.apiBaseUrl}'
          '${AppConstants.addDeliveryEndpoint}';
      _log('Adding delivery: $url');

      final result = await _storageService.insert(
        url,
        deliveryData,
        callerKey: key,
      );
      if (result == null) {
        _log('Failed to add delivery: null response');
        _storeFailure(key, null, code: 500, errorCode: 'ADD_FAILED');
        return null;
      }

      final delivery = Delivery.fromJson(result as Map<String, dynamic>);
      _storeSuccess(key, delivery);
      return delivery;
    } catch (e) {
      _log('Error adding delivery: $e');
      _storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      return null;
    }
  }

  // ==================== BUSINESS OPS ====================
  //
  // Each op is a POST to /delivery/{id}/<action>. Optional `body`
  // carries a Delivery_API-shaped payload: real fields patch the
  // delivery, signal fields (delivery_confirmed, proof_captured, ...)
  // flow into the policy.

  @override
  Future<Delivery?> acceptDelivery(
    int deliveryId, {
    Map<String, dynamic>? body,
    String? callerKey,
  }) =>
      _runAction(deliveryId, 'accept', body: body, callerKey: callerKey);

  @override
  Future<Delivery?> confirmDelivery(
    int deliveryId, {
    Map<String, dynamic>? body,
    String? callerKey,
  }) =>
      _runAction(deliveryId, 'confirm', body: body, callerKey: callerKey);

  @override
  Future<Delivery?> shipDelivery(
    int deliveryId, {
    Map<String, dynamic>? body,
    String? callerKey,
  }) =>
      _runAction(deliveryId, 'ship', body: body, callerKey: callerKey);

  @override
  Future<Delivery?> markInTransit(
    int deliveryId, {
    Map<String, dynamic>? body,
    String? callerKey,
  }) =>
      _runAction(deliveryId, 'in-transit', body: body, callerKey: callerKey);

  @override
  Future<Delivery?> markOutForDelivery(
    int deliveryId, {
    Map<String, dynamic>? body,
    String? callerKey,
  }) =>
      _runAction(deliveryId, 'out-for-delivery',
          body: body, callerKey: callerKey);

  @override
  Future<Delivery?> deliverDelivery(
    int deliveryId, {
    bool? proofCaptured,
    Map<String, dynamic>? body,
    String? callerKey,
  }) {
    final merged = _mergeSignal(
      body,
      'proof_captured',
      proofCaptured,
    );
    return _runAction(deliveryId, 'deliver',
        body: merged, callerKey: callerKey);
  }

  @override
  Future<Delivery?> cancelDelivery(
    int deliveryId, {
    String? reason,
    Map<String, dynamic>? body,
    String? callerKey,
  }) async {
    final query = <String, String>{
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    };
    return _runAction(deliveryId, 'cancel',
        body: body, query: query, callerKey: callerKey);
  }

  @override
  Future<Delivery?> failDelivery(
    int deliveryId, {
    bool? failureReported,
    String? reason,
    Map<String, dynamic>? body,
    String? callerKey,
  }) {
    final merged = _mergeSignal(
      body,
      'failure_reported',
      failureReported,
    );
    final query = <String, String>{
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    };
    return _runAction(deliveryId, 'fail',
        body: merged, query: query, callerKey: callerKey);
  }

  @override
  Future<Delivery?> returnDelivery(
    int deliveryId, {
    bool? returnConfirmed,
    Map<String, dynamic>? body,
    String? callerKey,
  }) {
    final merged = _mergeSignal(
      body,
      'return_confirmed',
      returnConfirmed,
    );
    return _runAction(deliveryId, 'return', body: merged, callerKey: callerKey);
  }

  @override
  Future<Delivery?> refundDelivery(
    int deliveryId, {
    bool? refundCompleted,
    Map<String, dynamic>? body,
    String? callerKey,
  }) {
    final merged = _mergeSignal(
      body,
      'refund_completed',
      refundCompleted,
    );
    return _runAction(deliveryId, 'refund', body: merged, callerKey: callerKey);
  }

  @override
  Future<Delivery?> archiveDelivery(
    int deliveryId, {
    String? callerKey,
  }) =>
      _runAction(deliveryId, 'archive', callerKey: callerKey);

  // ── Non-state ops ──────────────────────────────────────────────

  /// POST /delivery/{id}/tracking-pings?current_address_id=N
  @override
  Future<Delivery?> recordTrackingPing(
    int deliveryId,
    int currentAddressId, {
    String? callerKey,
  }) async {
    final key = callerKey ??
        _getCallerKey('recordTrackingPing',
            id: deliveryId.toString(), suffix: 'addr_$currentAddressId');
    try {
      final url = '${AppConstants.apiBaseUrl}'
          '${AppConstants.updateDeliveryTrackingEndpoint}'
          '/$deliveryId/tracking-pings'
          '?current_address_id=$currentAddressId';
      _log('Recording tracking ping: $url');

      final result = await _storageService.insert(url, {}, callerKey: key);
      if (result == null) {
        _storeFailure(key, null, code: 500, errorCode: 'TRACKING_FAILED');
        return null;
      }
      final delivery = Delivery.fromJson(result as Map<String, dynamic>);
      _storeSuccess(key, delivery);
      return delivery;
    } catch (e) {
      _log('Error recording tracking ping $deliveryId: $e');
      _storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      return null;
    }
  }

  @override
  Future<Delivery?> updateDetails(
    int deliveryId, {
    Map<String, dynamic>? body,
    String? callerKey,
  }) async {
    final key =
        callerKey ?? _getCallerKey('updateDetails', id: deliveryId.toString());
    try {
      final url = '${AppConstants.apiBaseUrl}'
          '${AppConstants.updateDeliveryEndpoint}'
          '/$deliveryId/details';
      _log('Updating delivery details: $url  body=${body ?? '{}'}');

      final result = await _storageService.insert(
        url,
        body ?? const <String, dynamic>{},
        callerKey: key,
      );

      if (result == null) {
        _log('Update details returned null for $deliveryId');
        _storeFailure(key, null, code: 500, errorCode: 'UPDATE_FAILED');
        return null;
      }

      final delivery = Delivery.fromJson(result as Map<String, dynamic>);
      _storeSuccess(key, delivery);
      return delivery;
    } catch (e) {
      _log('Error updating delivery details $deliveryId: $e');
      _storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      return null;
    }
  }

  /// POST /delivery/{id}/reroute?address_id=N
  @override
  Future<Delivery?> rerouteDelivery(
    int deliveryId,
    int addressId, {
    String? callerKey,
  }) async {
    final key = callerKey ??
        _getCallerKey('rerouteDelivery',
            id: deliveryId.toString(), suffix: 'addr_$addressId');
    try {
      final url = '${AppConstants.apiBaseUrl}'
          '${AppConstants.updateDeliveryAddressEndpoint}'
          '/$deliveryId/reroute?address_id=$addressId';
      _log('Rerouting delivery: $url');

      final result = await _storageService.insert(url, {}, callerKey: key);
      if (result == null) {
        _storeFailure(key, null, code: 500, errorCode: 'REROUTE_FAILED');
        return null;
      }
      final delivery = Delivery.fromJson(result as Map<String, dynamic>);
      _storeSuccess(key, delivery);
      return delivery;
    } catch (e) {
      _log('Error rerouting delivery $deliveryId: $e');
      _storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      return null;
    }
  }

  // ==================== NEXT-STATES ====================

  /// GET /delivery/{id}/next-states
  ///
  /// Returns the list of states the delivery can legally move to.
  @override
  Future<List<String>?> nextStates(int deliveryId, {String? callerKey}) async {
    final key =
        callerKey ?? _getCallerKey('nextStates', id: deliveryId.toString());
    try {
      final url = '${AppConstants.apiBaseUrl}'
          '${AppConstants.getDeliveryDetailsEndpoint}'
          '/$deliveryId/next-states';
      _log('Fetching next states: $url');

      final data = await _storageService.get(
        url,
        deliveryId.toString(),
        callerKey: key,
      );
      if (data == null || data is! Map) {
        _storeFailure(key, null, code: 404, errorCode: 'NOT_FOUND');
        return null;
      }

      final states =
          (data['next_states'] as List?)?.map((s) => s.toString()).toList() ??
              <String>[];
      _storeSuccess(key, states);
      return states;
    } catch (e) {
      _log('Error fetching next states $deliveryId: $e');
      _storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      return null;
    }
  }

  // ==================== INTERNAL: ACTION RUNNER ====================

  Future<Delivery?> _runAction(
    int deliveryId,
    String action, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    String? callerKey,
  }) async {
    final key =
        callerKey ?? _getCallerKey('action_$action', id: deliveryId.toString());
    try {
      final queryString = (query != null && query.isNotEmpty)
          ? '?${Uri(queryParameters: query).query}'
          : '';
      final url = '${AppConstants.apiBaseUrl}'
          '${AppConstants.updateDeliveryEndpoint}'
          '/$deliveryId/$action$queryString';
      _log('Delivery action [$action]: $url  body=${body ?? '{}'}');

      final result = await _storageService.insert(
        url,
        body ?? const <String, dynamic>{},
        callerKey: key,
      );

      if (result == null) {
        _log('Action [$action] returned null for $deliveryId');
        _storeFailure(key, null, code: 500, errorCode: 'ACTION_FAILED');
        return null;
      }

      final delivery = Delivery.fromJson(result as Map<String, dynamic>);
      _storeSuccess(key, delivery);
      return delivery;
    } catch (e) {
      _log('Error in action [$action] on $deliveryId: $e');
      _storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      return null;
    }
  }

  // ==================== INTERNAL: HELPERS ====================

  /// Extract a list from the various response shapes the backend
  /// produces (bare list, `{data: [...]}`, etc.).
  List<dynamic> _extractList(dynamic response) {
    if (response is List) return response;
    if (response is Map) {
      final data = response['data'];
      if (data is List) return data;
      final items = response['items'];
      if (items is List) return items;
    }
    return const [];
  }

  /// Merge a single signal into an existing body, without mutating it.
  /// If the signal is null, returns the original body unchanged.
  Map<String, dynamic>? _mergeSignal(
    Map<String, dynamic>? body,
    String key,
    bool? value,
  ) {
    if (value == null) return body;
    final merged = <String, dynamic>{...?body};
    merged[key] = value;
    return merged;
  }

  // ==================== CACHE ====================

  @override
  void clearCache() {
    _log('Delivery service cache cleared');
  }
}
