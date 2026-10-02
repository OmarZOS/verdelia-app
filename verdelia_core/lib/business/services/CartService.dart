import 'dart:typed_data';

// import 'package:verdelia_core/business/finance/Order.dart';

import '../../app/TraceableService.dart';
import '../finance/Cart.dart';
import '../finance/Order.dart';

// CartService.dart
abstract class CartService extends TraceableService {
  Future<List<Cart>> getAllCarts(int offset, int limit,
      {int providerId = 0,
      int sellerId = 0,
      int cartId = 0,
      int clientId = 0,
      int personId = 0,
      String? callerKey}) async {
    throw UnimplementedError();
  }

  Future<Cart?> getCart(int idCart, {String? callerKey}) async {
    return null;
  }

  Future<Cart?> addCart(dynamic Cart, {params, String? callerKey}) async {
    return null;
  }

  Future<Cart?> updateCart(Cart updatedCart, {String? callerKey}) async {
    return null;
  }

  Future<int?> deleteCart(String productId, {String? callerKey}) async {
    return null;
  }

  Future<List<OrderedItem>> getCartDetails(int idCart,
      {String? callerKey}) async {
    return [];
  }
}
