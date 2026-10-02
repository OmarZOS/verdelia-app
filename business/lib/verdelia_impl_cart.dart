library verdelia_impl_cart;

import 'dart:convert';
import 'dart:developer';

import 'package:app_constants/app_constants.dart';
import 'package:verdelia_core/business/finance/Cart.dart';
import 'package:verdelia_core/business/finance/Order.dart';
import 'package:verdelia_core/business/services/CartService.dart';
import 'package:verdelia_core/app/VerdeliaException.dart';
import 'package:verdelia_core/mediation/StorageService.dart';
import 'package:locator/locator.dart';

class CartServiceImpl extends CartService {
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
  Future<List<Cart>> getAllCarts(int offset, int limit,
      {int providerId = 0,
      int sellerId = 0,
      int cartId = 0,
      int clientId = 0,
      int personId = 0,
      String? callerKey}) async {
    final key = callerKey ??
        _getCallerKey('getAllCarts', suffix: 'offset_$offset-limit_$limit');
    try {
      final responseData = await _storageService.getAll(
          '${AppConstants.apiBaseUrl}${AppConstants.getCartsEndpoint}/$providerId/$sellerId/$cartId/$clientId/$personId/$offset/$limit',
          callerKey: key);

      if (responseData == null || responseData.isEmpty) {
        _storeSuccess(key, [], responseCode: 'EMPTY');
        return [];
      }

      final List<Cart> carts = (responseData as List)
          .map((item) => Cart.fromJson(item as Map<String, dynamic>))
          .toList();

      _storeSuccess(key, carts);
      return carts;
    } catch (e) {
      _storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      return [];
    }
  }

  @override
  Future<Cart?> getCart(int idCart, {String? callerKey}) async {
    final key = callerKey ?? _getCallerKey('getCart', id: idCart.toString());
    try {
      final data = await getAllCarts(0, 1, cartId: idCart, callerKey: key);

      if (data.isEmpty) {
        _storeFailure(key, null, code: 404, errorCode: 'NOT_FOUND');
        return null;
      }

      final cart = data[0];
      _storeSuccess(key, cart);
      return cart;
    } catch (e) {
      _storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      return null;
    }
  }

  @override
  Future<Cart?> addCart(dynamic cartData,
      {dynamic params, String? callerKey}) async {
    final key = callerKey ?? _getCallerKey('addCart');
    try {
      final url = '${AppConstants.apiBaseUrl}${AppConstants.postCartEndpoint}';

      final result = await _storageService.insert(
        url,
        cartData,
        params: params,
        callerKey: key,
      );

      if (result == null) {
        _storeFailure(key, null, code: 500, errorCode: 'ADD_FAILED');
        return null;
      }

      try {
        final cart = Cart.fromResponseJson(result);
        _storeSuccess(key, cart);
        return cart;
      } catch (e, stack) {
        log(
          'Cart parse failed',
          name: 'CartServiceImpl',
          error: e,
          stackTrace: stack,
        );
        log('Raw response: $result', name: 'CartServiceImpl');
        _storeFailure(key, result,
            code: 500,
            errorCode: 'PARSE_FAILED',
            message: 'Failed to parse cart: $e');
        return null;
      }
    } catch (e) {
      _storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      return null;
    }
  }

  @override
  Future<Cart?> updateCart(Cart updatedCart, {String? callerKey}) async {
    final key = callerKey ??
        _getCallerKey('updateCart',
            id: updatedCart.cartId?.toString() ?? 'unknown');
    try {
      final result = await _storageService.update(
        '${AppConstants.apiBaseUrl}${AppConstants.cartEndpoint}',
        updatedCart.cartId?.toString() ?? '',
        {},
        updatedCart.toJson(),
        callerKey: key,
      );

      if (result == null) {
        _storeFailure(key, null, code: 500, errorCode: 'UPDATE_FAILED');
        return null;
      }

      final cart = Cart.fromJson(result);
      _storeSuccess(key, cart);
      return cart;
    } catch (e) {
      _storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      return null;
    }
  }

  @override
  Future<int?> deleteCart(String cartId, {String? callerKey}) async {
    final key = callerKey ?? _getCallerKey('deleteCart', id: cartId);
    try {
      final result = await _storageService.delete(
        '${AppConstants.apiBaseUrl}${AppConstants.deleteCartEndpoint ?? AppConstants.cartEndpoint}/$cartId',
        cartId,
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
  Future<List<OrderedItem>> getCartDetails(int idCart,
      {String? callerKey}) async {
    final key =
        callerKey ?? _getCallerKey('getCartDetails', id: idCart.toString());
    try {
      final responseData = await _storageService.getAll(
        '${AppConstants.apiBaseUrl}${AppConstants.getCartDetailsEndpoint}/$idCart',
        callerKey: key,
      );

      if (responseData == null || responseData.isEmpty) {
        _storeSuccess(key, [], responseCode: 'EMPTY');
        return [];
      }

      final List<OrderedItem> items = (responseData as List)
          .map((item) => OrderedItem.fromJson(item as Map<String, dynamic>))
          .toList();

      _storeSuccess(key, items);
      return items;
    } catch (e) {
      _storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      return [];
    }
  }

  // Additional useful methods with traceability

  Future<List<Cart>> getCartsByStatus(int userId, String status,
      {String? callerKey}) async {
    final key = callerKey ??
        _getCallerKey('getCartsByStatus',
            suffix: 'user_$userId-status_$status');
    try {
      final responseData = await _storageService.getAll(
        '${AppConstants.apiBaseUrl}${AppConstants.cartEndpoint}/status/$userId/$status',
        callerKey: key,
      );

      if (responseData == null || responseData.isEmpty) {
        _storeSuccess(key, [], responseCode: 'EMPTY');
        return [];
      }

      final List<Cart> carts = (responseData as List)
          .map((item) => Cart.fromJson(item as Map<String, dynamic>))
          .toList();

      _storeSuccess(key, carts);
      return carts;
    } catch (e) {
      _storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      return [];
    }
  }

  Future<List<Cart>> getCartsByProvider(int userId, int providerId,
      {String? callerKey}) async {
    final key = callerKey ??
        _getCallerKey('getCartsByProvider',
            suffix: 'user_$userId-provider_$providerId');
    try {
      final responseData = await _storageService.getAll(
        '${AppConstants.apiBaseUrl}${AppConstants.cartEndpoint}/provider/$userId/$providerId',
        callerKey: key,
      );

      if (responseData == null || responseData.isEmpty) {
        _storeSuccess(key, [], responseCode: 'EMPTY');
        return [];
      }

      final List<Cart> carts = (responseData as List)
          .map((item) => Cart.fromJson(item as Map<String, dynamic>))
          .toList();

      _storeSuccess(key, carts);
      return carts;
    } catch (e) {
      _storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      return [];
    }
  }

  Future<Cart?> updateCartStatus(String cartId, String newStatus,
      {String? callerKey}) async {
    final key = callerKey ??
        _getCallerKey('updateCartStatus',
            id: cartId, suffix: 'status_$newStatus');
    try {
      final result = await _storageService.update(
        '${AppConstants.apiBaseUrl}${AppConstants.cartEndpoint}/status/$cartId',
        cartId,
        {},
        {'status': newStatus},
        callerKey: key,
      );

      if (result == null) {
        _storeFailure(key, null, code: 500, errorCode: 'UPDATE_FAILED');
        return null;
      }

      final cart = Cart.fromJson(result);
      _storeSuccess(key, cart);
      return cart;
    } catch (e) {
      _storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      return null;
    }
  }

  // Helper method to clear any cache if needed
  void clearCache() {
    // If there's any caching mechanism in the future
    log('Cart service cache cleared', name: 'CartServiceImpl');
  }
}
