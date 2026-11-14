import 'package:decimal/decimal.dart';
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

  /// Server-side status for a completed order is `delivered`, not
  /// `completed`. `completed` only exists as a *payment* status.
  List<Order> get completedOrders {
    return _orders.values
        .where((order) => order.status.toLowerCase() == 'delivered')
        .toList();
  }

  List<Order> get pendingOrders {
    return _orders.values
        .where((order) => order.status.toLowerCase() == 'pending')
        .toList();
  }

  List<Order> get cancelledOrders {
    return _orders.values
        .where((order) => order.status.toLowerCase() == 'cancelled')
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
      // `getOrderDetails(orderId)` returns the line items for that
      // *one* order, so store them under the order id, not under any
      // line-item id. The original code keyed by `idOrderedItem`,
      // which always missed.
      final order = _orders[orderId];
      if (order != null) {
        order.items = orderDetails;
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
        .where(
          (order) => order.status.toLowerCase() == status.toLowerCase(),
        )
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
                  .toLowerCase()
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
        _orders[data.idPlacedOrder] = data;
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

  /// Updates the **order state** (pending / processing / shipped /
  /// delivered / cancelled / refunded). Note: the original code wrote
  /// `newStatus` into `paymentStatus`, which is a different axis —
  /// payment is `pending | paid | failed | refunded | completed`.
  Future<OrderResult> updateOrderStatus(int orderId, String newStatus) async {
    _setLoading(true);
    _clearError();

    try {
      final order = _orders[orderId];
      if (order == null) {
        return OrderResult.failure('Order not found');
      }

      final updatedOrder = order.copyWith(
        placedOrderStateRaw: newStatus,
        placedOrderStateRef: _stateRefFor(newStatus),
      );
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

  /// `delivered` is the terminal state the server accepts for a
  /// completed order. `completed` is a *payment* status, not an order
  /// status — sending it as `placed_order_state` gets a 422.
  Future<OrderResult> completeOrder(int orderId) async {
    return await updateOrderStatus(orderId, 'delivered');
  }

  Future<OrderResult> deleteOrder(int orderId) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _orderService.deleteOrder(orderId.toString());
      // NOTE: the original inverted this check — removing the order on
      // `success == 0`. Assuming `success` is the count of deleted
      // rows (as the name and the `== 0` comparison suggest), the
      // success branch should be `success > 0`.
      if ((success ?? 0) > 0) {
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

  /// Sum of every order's [Order.totalPrice], in [Decimal]. Exact.
  ///
  /// Falls back to [Decimal.zero] for orders whose `totalPrice` is
  /// null, so a single half-loaded order doesn't blow up the whole
  /// stats header.
  Decimal get totalOrderValue {
    return _orders.values.fold(
      Decimal.zero,
      (sum, order) => sum + (order.totalPrice ?? Decimal.zero),
    );
  }

  /// [totalOrderValue] divided by the order count, in [Decimal].
  ///
  /// `.toDecimal(scaleOnInfinitePrecision: 2)` on the division: `Decimal / Decimal` returns a
  /// `Rational`, which can't be assigned to a `Decimal`.
  Decimal get averageOrderValue {
    if (_orders.isEmpty) return Decimal.zero;
    return (totalOrderValue / Decimal.fromInt(_orders.length))
        .toDecimal(scaleOnInfinitePrecision: 2);
  }

  Map<String, int> get ordersByStatusCount {
    final result = <String, int>{};

    for (final order in _orders.values) {
      final status = order.status;
      result[status] = (result[status] ?? 0) + 1;
    }

    return result;
  }

  /// Revenue grouped by the month of [Order.placedOrderCreation].
  ///
  /// Keyed by month number (`'1'` .. `'12'`). Callers that want a
  /// year-aware key should group by `(year, month)` themselves.
  Map<String, Decimal> get revenueByMonth {
    final result = <String, Decimal>{};

    for (final order in _orders.values) {
      final date = order.placedOrderCreation;
      final month = date.month.toString();
      result[month] =
          (result[month] ?? Decimal.zero) + (order.totalPrice ?? Decimal.zero);
    }

    return result;
  }

  // ============ ORDER FILTERING ============

  List<Order> filterOrders({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    Decimal? minAmount,
    Decimal? maxAmount,
  }) {
    return _orders.values.where((order) {
      if (status != null &&
          order.status.toLowerCase() != status.toLowerCase()) {
        return false;
      }

      if (startDate != null) {
        if (order.placedOrderCreation.isBefore(startDate)) {
          return false;
        }
      }

      if (endDate != null) {
        if (order.placedOrderCreation.isAfter(endDate)) {
          return false;
        }
      }

      final price = order.totalPrice ?? Decimal.zero;

      if (minAmount != null && price < minAmount) {
        return false;
      }

      if (maxAmount != null && price > maxAmount) {
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
        _orders[order.idPlacedOrder] = order;
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

  // ============ PRIVATE HELPERS ============

  /// Maps a lowercase status string back to the numeric ref the
  /// `placed_order` row stores. Mirrors the private helper on
  /// `Order._stateToRef`, kept here so the notifier can set both
  /// fields in one `copyWith`.
  int _stateRefFor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 1;
      case 'processing':
        return 2;
      case 'shipped':
        return 3;
      case 'delivered':
        return 4;
      case 'cancelled':
      case 'canceled':
        return 5;
      case 'refunded':
        return 6;
      default:
        return 1;
    }
  }
}
