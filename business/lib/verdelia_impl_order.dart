library business;

import 'dart:developer';
import 'dart:typed_data';

import 'package:app_constants/app_constants.dart';
import 'package:verdelia_core/business/finance/Order.dart';
import 'package:verdelia_core/business/services/OrderService.dart';
import 'package:verdelia_core/app/VerdeliaException.dart';
import 'package:verdelia_core/mediation/StorageService.dart';
import 'package:locator/locator.dart';

class OrderServiceImpl extends OrderService {
  final StorageService _storageService = AppLocator.get<StorageService>();

  String _getCallerKey(String method, {String? id, String? suffix}) {
    final parts = [method];
    if (id != null) parts.add(id);
    if (suffix != null) parts.add(suffix);
    if (parts.length == 1)
      parts.add(DateTime.now().millisecondsSinceEpoch.toString());
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

  @override
  Future<Order?> addOrder(dynamic orderData, {String? callerKey}) async {
    final key = callerKey ?? _getCallerKey('addOrder');
    try {
      final result = await _storageService.insert(
        '${AppConstants.apiBaseUrl}${AppConstants.addOrderEndpoint}',
        orderData,
        callerKey: key,
      );

      if (result == null) {
        _storeFailure(key, null, code: 500, errorCode: 'ADD_FAILED');
        return null;
      }

      final order = Order.fromJson(result as Map<String, dynamic>);
      _storeSuccess(key, order);
      return order;
    } catch (e) {
      _storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      return null;
    }
  }

  @override
  Future<int?> deleteOrder(String orderId, {String? callerKey}) async {
    final key = callerKey ?? _getCallerKey('deleteOrder', id: orderId);
    try {
      // Fixed: Previously threw UnimplementedError, now properly implemented
      final result = await _storageService.delete(
        '${AppConstants.apiBaseUrl}${AppConstants.deleteOrderEndpoint}/$orderId',
        orderId,
        callerKey: key,
      );

      if (result == 200 || result == 204) {
        _storeSuccess(key, true);
      } else {
        _storeFailure(key, false, code: result);
      }
      return result as int?;
    } catch (e) {
      _storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      return null;
    }
  }

  @override
  Future<Order?> updateOrder(Order updatedOrder, {String? callerKey}) async {
    final key = callerKey ??
        _getCallerKey('updateOrder',
            id: updatedOrder.idPlacedOrder?.toString() ?? 'unknown');
    try {
      // Fixed: Using correct endpoint for order update
      final result = await _storageService.update(
        '${AppConstants.apiBaseUrl}${AppConstants.updateOrderEndpoint ?? AppConstants.orderEndpoint}/${updatedOrder.idPlacedOrder}',
        updatedOrder.idPlacedOrder?.toString() ?? '',
        {},
        updatedOrder.toJson(),
        callerKey: key,
      );

      if (result == null) {
        _storeFailure(key, null, code: 500, errorCode: 'UPDATE_FAILED');
        return null;
      }

      final order = Order.fromJson(result as Map<String, dynamic>);
      _storeSuccess(key, order);
      return order;
    } catch (e) {
      _storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      return null;
    }
  }

  @override
  Future<Order?> getOrder(String id, {String? callerKey}) async {
    final key = callerKey ?? _getCallerKey('getOrder', id: id);
    try {
      final data = await _storageService.get(
        '${AppConstants.apiBaseUrl}${AppConstants.orderEndpoint}',
        id,
        callerKey: key,
      );

      if (data == null) {
        _storeFailure(key, null, code: 404, errorCode: 'NOT_FOUND');
        return null;
      }

      final order = Order.fromJson(data as Map<String, dynamic>);
      _storeSuccess(key, order);
      return order;
    } catch (e) {
      _storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      return null;
    }
  }

  @override
  Future<List<Order>> getAllOrders(int offset, int limit,
      {int idUser = 0, String? callerKey}) async {
    final key = callerKey ??
        _getCallerKey('getAllOrders',
            suffix: 'offset_$offset-limit_$limit-user_$idUser');
    try {
      final responseData = await _storageService.getAll(
        "${AppConstants.apiBaseUrl}${AppConstants.getAllOrdersEndpoint}/$idUser/$offset/$limit",
        callerKey: key,
      );

      if (responseData == null || responseData.isEmpty) {
        _storeSuccess(key, [], responseCode: 'EMPTY');
        return [];
      }

      final List<Order> orders = (responseData as List)
          .map((data) => Order.fromJson(data as Map<String, dynamic>))
          .toList();

      _storeSuccess(key, orders);
      return orders;
    } catch (e) {
      _storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      return [];
    }
  }

  @override
  Future<List<OrderedItem>> getOrderDetails(int idOrder,
      {String? callerKey}) async {
    final key =
        callerKey ?? _getCallerKey('getOrderDetails', id: idOrder.toString());
    try {
      final responseData = await _storageService.getAll(
        "${AppConstants.apiBaseUrl}${AppConstants.getOrderDetailsEndpoint}/$idOrder",
        callerKey: key,
      );

      if (responseData == null || responseData.isEmpty) {
        _storeSuccess(key, [], responseCode: 'EMPTY');
        return [];
      }

      final List<OrderedItem> orderedItems = (responseData as List)
          .map((data) => OrderedItem.fromJson(data as Map<String, dynamic>))
          .toList();

      _storeSuccess(key, orderedItems);
      return orderedItems;
    } catch (e) {
      _storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      return [];
    }
  }

  // Additional useful methods with traceability

  Future<List<Order>> getOrdersByStatus(String status,
      {String? callerKey}) async {
    final key = callerKey ??
        _getCallerKey('getOrdersByStatus', suffix: 'status_$status');
    try {
      final responseData = await _storageService.getAll(
        '${AppConstants.apiBaseUrl}${AppConstants.orderEndpoint}/status/$status',
        callerKey: key,
      );

      if (responseData == null || responseData.isEmpty) {
        _storeSuccess(key, [], responseCode: 'EMPTY');
        return [];
      }

      final List<Order> orders = (responseData as List)
          .map((data) => Order.fromJson(data as Map<String, dynamic>))
          .toList();

      _storeSuccess(key, orders);
      return orders;
    } catch (e) {
      _storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      return [];
    }
  }

  Future<Order?> updateOrderStatus(String orderId, String newStatus,
      {String? callerKey}) async {
    final key = callerKey ??
        _getCallerKey('updateOrderStatus',
            id: orderId, suffix: 'status_$newStatus');
    try {
      final result = await _storageService.update(
        '${AppConstants.apiBaseUrl}${AppConstants.orderEndpoint}/status/$orderId',
        orderId,
        {},
        {'status': newStatus},
        callerKey: key,
      );

      if (result == null) {
        _storeFailure(key, null, code: 500, errorCode: 'UPDATE_FAILED');
        return null;
      }

      final order = Order.fromJson(result as Map<String, dynamic>);
      _storeSuccess(key, order);
      return order;
    } catch (e) {
      _storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      return null;
    }
  }

  Future<List<Order>> getOrdersByUser(int userId, {String? callerKey}) async {
    final key =
        callerKey ?? _getCallerKey('getOrdersByUser', id: userId.toString());
    try {
      final responseData = await _storageService.getAll(
        '${AppConstants.apiBaseUrl}${AppConstants.orderEndpoint}/user/$userId',
        callerKey: key,
      );

      if (responseData == null || responseData.isEmpty) {
        _storeSuccess(key, [], responseCode: 'EMPTY');
        return [];
      }

      final List<Order> orders = (responseData as List)
          .map((data) => Order.fromJson(data as Map<String, dynamic>))
          .toList();

      _storeSuccess(key, orders);
      return orders;
    } catch (e) {
      _storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      return [];
    }
  }

  // Helper method to clear any cache if needed
  void clearCache() {
    // If there's any caching mechanism in the future
    log('Order service cache cleared', name: 'OrderServiceImpl');
  }
}
