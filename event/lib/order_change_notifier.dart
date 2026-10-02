import 'package:flutter/material.dart';
import 'package:verdelia_core/business/finance/Order.dart';
import 'package:verdelia_core/business/services/OrderService.dart';
import 'package:locator/locator.dart';

class OrderResult {
  final bool isSuccess;
  final String message;

  const OrderResult._(this.isSuccess, this.message);

  factory OrderResult.success(String message) => OrderResult._(true, message);
  factory OrderResult.failure(String message) => OrderResult._(false, message);
}

class OrderChangeNotifier with ChangeNotifier {
  final OrderService _orderService = AppLocator.get<OrderService>();

  // State
  final Map<int, Order> _orders = {};
  bool _isLoading = false;
  String? _lastError;

  // ============ PUBLIC GETTERS ============
  List<Order> get orders => List.unmodifiable(_orders.values);
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  int get orderCount => _orders.length;

  // Get completed orders
  List<Order> get completedOrders {
    return _orders.values
        .where((order) => order.status?.toLowerCase() == 'completed')
        .toList();
  }

  // Get pending orders
  List<Order> get pendingOrders {
    return _orders.values
        .where((order) => order.status?.toLowerCase() == 'pending')
        .toList();
  }

  // Get cancelled orders
  List<Order> get cancelledOrders {
    return _orders.values
        .where((order) => order.status?.toLowerCase() == 'cancelled')
        .toList();
  }

  // ============ STATE MANAGEMENT HELPERS ============
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _lastError = error;
    notifyListeners();
  }

  void _clearError() {
    _lastError = null;
    notifyListeners();
  }

  // ============ ORDER FETCHING METHODS ============
  Future<void> fetchOrders({bool reset = false, required int appUserId}) async {
    if (_isLoading) return;
    _setLoading(true);
    _clearError();

    try {
      if (reset) _orders.clear();
      final fetchedOrders =
          await _orderService.getAllOrders(0, 30, idUser: appUserId);

      for (final order in fetchedOrders) {
        final existingOrder = _orders[order.idPlacedOrder];
        _orders[order.idPlacedOrder] =
            existingOrder != null && existingOrder.hasItems()
                ? order.copyWith(items: existingOrder.items)
                : order;
      }
    } catch (e, stackTrace) {
      _setError('Failed to fetch orders: ${e.toString()}');
      debugPrint('Error fetching orders: $e\n$stackTrace');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchOrderDetails({required int orderId}) async {
    if (_isLoading) return;
    _setLoading(true);
    _clearError();

    try {
      final orderDetails = await _orderService.getOrderDetails(orderId);
      for (final detailedOrder in orderDetails) {
        _orders[detailedOrder.idOrderedItem]?.items = [detailedOrder];
      }
    } catch (e, stackTrace) {
      _setError('Failed to fetch order details: ${e.toString()}');
      debugPrint('Error fetching order details: $e\n$stackTrace');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshOrderDetails(int orderId) async {
    await fetchOrderDetails(orderId: orderId);
  }

  // ============ ORDER QUERY METHODS ============
  Order? getOrder(int orderId) {
    return _orders[orderId];
  }

  List<Order> getOrdersByStatus(String status) {
    return _orders.values
        .where((order) => order.status?.toLowerCase() == status.toLowerCase())
        .toList();
  }

  Order? getOrderWithDetails(int orderId) {
    final order = _orders[orderId];
    return order != null && order.items != null ? order : null;
  }

  List<Order> searchOrders(String query) {
    final searchQuery = query.toLowerCase();
    return _orders.values.where((order) {
      return order.idPlacedOrder
                  .toString()
                  ?.toLowerCase()
                  .contains(searchQuery) ==
              true ||
          order.customerName?.toLowerCase().contains(searchQuery) == true ||
          order.idPlacedOrder.toString().contains(searchQuery);
    }).toList();
  }

  // ============ ORDER CRUD OPERATIONS ============
  Future<OrderResult> submitOrder(Map<String, dynamic> orderData) async {
    _setLoading(true);
    _clearError();

    try {
      final data = await _orderService.addOrder(orderData);
      if (data != null) {
        _orders[data.idPlacedOrder ?? 0] = data;
        notifyListeners();
        return OrderResult.success('Order placed successfully');
      }
      return OrderResult.failure('Failed to place order');
    } catch (e, stackTrace) {
      debugPrint('Order submission error: $e\n$stackTrace');
      return OrderResult.failure('Order failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<OrderResult> updateOrderStatus(int orderId, String newStatus) async {
    _setLoading(true);
    _clearError();

    try {
      final order = _orders[orderId];
      if (order == null) {
        return OrderResult.failure('Order not found');
      }

      final updatedOrder = order.copyWith(paymentStatus: newStatus);
      final result = await _orderService.updateOrder(updatedOrder);

      if (result != null) {
        _orders[orderId] = result;
        notifyListeners();
        return OrderResult.success('Order status updated successfully');
      }
      return OrderResult.failure('Failed to update order status');
    } catch (e, stackTrace) {
      debugPrint('Update order status error: $e\n$stackTrace');
      return OrderResult.failure('Update failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<OrderResult> cancelOrder(int orderId) async {
    return await updateOrderStatus(orderId, 'cancelled');
  }

  Future<OrderResult> completeOrder(int orderId) async {
    return await updateOrderStatus(orderId, 'completed');
  }

  Future<OrderResult> deleteOrder(int orderId) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _orderService.deleteOrder(orderId.toString());
      if (success == 0) {
        _orders.remove(orderId);
        notifyListeners();
        return OrderResult.success('Order deleted successfully');
      }
      return OrderResult.failure('Failed to delete order');
    } catch (e, stackTrace) {
      debugPrint('Delete order error: $e\n$stackTrace');
      return OrderResult.failure('Delete failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // ============ ORDER STATISTICS ============
  double get totalOrderValue {
    return _orders.values
        .fold(0.0, (sum, order) => sum + (order.totalPrice ?? 0));
  }

  double get averageOrderValue {
    if (_orders.isEmpty) return 0.0;
    return totalOrderValue / _orders.length;
  }

  Map<String, int> get ordersByStatusCount {
    final result = <String, int>{};

    for (final order in _orders.values) {
      final status = order.status ?? 'unknown';
      result[status] = (result[status] ?? 0) + 1;
    }

    return result;
  }

  Map<String, double> get revenueByMonth {
    final result = <String, double>{};

    for (final order in _orders.values) {
      final date = order.placedOrderCreation;
      if (date != null) {
        final month = date.month.toString();
        result[month] = (result[month] ?? 0) + (order.totalPrice ?? 0);
      }
    }

    return result;
  }

  // ============ ORDER VALIDATION ============
  // bool validateOrderData(Map<String, dynamic> orderData) {
  //   // Required fields validation
  //   final requiredFields = [
  //     'customer_id',
  //     'total_amount',
  //     'items',
  //   ];

  //   for (final field in requiredFields) {
  //     if (!orderData.containsKey(field) || orderData[field] == null) {
  //       _setError('Missing required field: $field');
  //       return false;
  //     }
  //   }

  //   // Items validation
  //   final items = orderData['items'];
  //   if (items is! List || items.isEmpty) {
  //     _setError('Order must contain at least one item');
  //     return false;
  //   }

  //   // Amount validation
  //   final totalPrice = orderData['total_amount'];
  //   if (totalPrice is! num || totalPrice <= 0) {
  //     _setError('Total amount must be a positive number');
  //     return false;
  //   }

  //   _clearError();
  //   return true;
  // }

  // ============ ORDER FILTERING ============
  List<Order> filterOrders({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
  }) {
    return _orders.values.where((order) {
      if (status != null &&
          order.status?.toLowerCase() != status.toLowerCase()) {
        return false;
      }

      if (startDate != null) {
        final orderDate = order.placedOrderCreation;
        if (orderDate == null || orderDate.isBefore(startDate)) {
          return false;
        }
      }

      if (endDate != null) {
        final orderDate = order.placedOrderCreation;
        if (orderDate == null || orderDate.isAfter(endDate)) {
          return false;
        }
      }

      if (minAmount != null && (order.totalPrice ?? 0) < minAmount) {
        return false;
      }

      if (maxAmount != null && (order.totalPrice ?? 0) > maxAmount) {
        return false;
      }

      return true;
    }).toList();
  }

  // ============ ORDER EXPORT/IMPORT ============
  List<Map<String, dynamic>> exportOrders() {
    return _orders.values.map((order) => order.toJson()).toList();
  }

  Future<void> importOrders(List<Map<String, dynamic>> ordersData) async {
    _setLoading(true);
    _clearError();

    try {
      for (final orderData in ordersData) {
        final order = Order.fromJson(orderData);
        _orders[order.idPlacedOrder ?? 0] = order;
      }
      notifyListeners();
    } catch (e, stackTrace) {
      _setError('Failed to import orders: ${e.toString()}');
      debugPrint('Import orders error: $e\n$stackTrace');
    } finally {
      _setLoading(false);
    }
  }

  // ============ UTILITY METHODS ============
  void clearOrders() {
    _orders.clear();
    notifyListeners();
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  void refreshOrder(int orderId) async {
    await fetchOrderDetails(orderId: orderId);
  }
}
