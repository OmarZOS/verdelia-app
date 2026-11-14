import 'dart:typed_data';

import 'package:verdelia_core/app/TraceableService.dart';
import 'package:verdelia_core/business/finance/OrderedItem.dart';

import '../finance/Order.dart';

// OrderService.dart
abstract class OrderService extends TraceableService {
  Future<List<Order>> getAllOrders(int offset, int limit,
      {int idUser = 0, String? callerKey}) async {
    throw UnimplementedError();
  }

  Future<Order?> getOrder(String idOrder, {String? callerKey}) async {
    return null;
  }

  Future<Order?> addOrder(dynamic order, {String? callerKey}) async {
    return null;
  }

  Future<Order?> updateOrder(Order updatedOrder, {String? callerKey}) async {
    return null;
  }

  Future<int?> deleteOrder(String productId, {String? callerKey}) async {
    return null;
  }

  Future<List<OrderedItem>> getOrderDetails(int idOrder,
      {String? callerKey}) async {
    return [];
  }
}
