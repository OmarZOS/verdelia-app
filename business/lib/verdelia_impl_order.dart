library business;

import 'dart:developer';

import 'package:app_constants/app_constants.dart';
import 'package:verdelia_core/app/VerdeliaException.dart';
import 'package:verdelia_core/business/finance/Order.dart';
import 'package:verdelia_core/business/finance/OrderedItem.dart';
import 'package:verdelia_core/business/services/OrderService.dart';
import 'package:verdelia_core/mediation/StorageService.dart';
import 'package:locator/locator.dart';

/// Concrete [OrderService] implementation against the Verdelia
/// order router.
///
/// Every URL, verb, and body shape below is verified against
/// `routers/business_routers/order_router.py`:
///
///     POST   /orders                          → create_order
///     POST   /orders/{id}/pay?payment_method= → process_order_payment
///     POST   /orders/{id}/confirm-inventory   → confirm_order_inventory
///     POST   /orders/{id}/finalize?payment_method= → finalize_order
///     GET    /orders/user/{user_id}?offset=&limit= → get_user_orders
///     GET    /orders/{id}?include_items=      → get_order
///     GET    /orders/{id}/items               → get_order_items
///     PUT    /orders/{id}                     → update_order
///     DELETE /orders/{id}?force_delete=       → delete_order
///     PATCH  /orders/{id}/status?status=      → update_order_status
///     GET    /orders/{id}/inventory-status    → get_order_inventory_status
///
/// The base path (`/api/v1/business/orders`) is what the running
/// server exposes — confirmed from live request logs. `AppConstants.
/// apiBaseUrl` supplies the `http://host:port` part only.
class OrderServiceImpl extends OrderService {
  final StorageService _storageService = AppLocator.get<StorageService>();

  // ── URL building ────────────────────────────────────────────────
  //
  // One base, one helper. Every call appends a suffix to this. If
  // the router ever moves, one line changes.

  static const String _ordersBase = '/business/orders';

  String _url(String suffix) => '${AppConstants.apiBaseUrl}$_ordersBase$suffix';

  String _urlWithQuery(String suffix, Map<String, String>? query) {
    final base = _url(suffix);
    if (query == null || query.isEmpty) return base;
    return Uri.parse(base).replace(queryParameters: query).toString();
  }

  // ── Caller keys ─────────────────────────────────────────────────

  String _getCallerKey(String method, {String? id, String? suffix}) {
    final parts = <String>[method];
    if (id != null) parts.add(id);
    if (suffix != null) parts.add(suffix);
    if (parts.length == 1) {
      parts.add(DateTime.now().microsecondsSinceEpoch.toString());
    }
    return parts.join('_');
  }

  void _storeSuccess(
    String key,
    dynamic data, {
    int? code,
    String? responseCode,
  }) {
    _storageService.setSuccessResponse(
      key,
      data,
      statusCode: code ?? 200,
      responseCode: responseCode ?? 'SUCCESS',
    );
  }

  void _storeFailure(
    String key,
    dynamic data, {
    int? code,
    String? errorCode,
    String? message,
  }) {
    _storageService.setFailureResponse(
      key,
      data: data,
      statusCode: code ?? 500,
      errorCode: errorCode,
      message: message,
    );
  }

  // ── Response unwrapping ────────────────────────────────────────
  //
  // The router wraps most bodies in `{"order": ...}` or
  // `{"order_id": ..., "items": [...]}`. This helper extracts the
  // `Order` payload from either shape, so callers don't have to know
  // which endpoint returned which.

  static Map<String, dynamic>? _extractOrderMap(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);

    // `{"order": {...}}` — most endpoints return this.
    final nested = map['order'];
    if (nested is Map) {
      return Map<String, dynamic>.from(nested);
    }

    // `{"data": {"order": {...}}}` — wrapped variants.
    final data = map['data'];
    if (data is Map) {
      final inner = data['order'];
      if (inner is Map) {
        return Map<String, dynamic>.from(inner);
      }
      // Bare `{"data": {...}}`
      return Map<String, dynamic>.from(data);
    }

    // Already the order itself.
    if (map.containsKey('id_placed_order')) {
      return map;
    }

    return null;
  }

  static List<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      for (final key in const ['data', 'items', 'orders', 'results']) {
        final v = raw[key];
        if (v is List) return v;
      }
    }
    return const [];
  }

  // ════════════════════════════════════════════════════════════════
  // CREATE
  // ════════════════════════════════════════════════════════════════

  /// Create a new order.
  ///
  /// The router's signature is:
  ///
  ///     async def create_order(
  ///         ordered_items: List[OrderedItem_API],   ← body param 1
  ///         submitted_order: PlacedOrder_API,       ← body param 2
  ///         payment_method: str = Query("cash"),
  ///         delivery_info: Delivery_Info_API = None,← body param 3
  ///         user_id: int = Depends(get_current_user_id),
  ///         workflow: OrderWorkflow = Depends(...),
  ///     )
  ///
  /// FastAPI requires the body to be a **single object** with keys
  /// matching the parameter names: `{ordered_items, submitted_order,
  /// delivery_info}`. Sending just a `PlacedOrder_API` to the body
  /// will 422.
  ///
  /// `payment_method` goes in the query string, not the body.
  ///
  /// Returns the created `Order` and stores the full response
  /// envelope (`{order, payment_id, invoice_id, ...}`) in the
  /// success record so the UI can read the invoice id if it needs to.
  @override
  Future<Order?> addOrder(
    dynamic orderData, {
    String? callerKey,
    String? paymentMethod,
  }) async {
    final key =
        callerKey ?? _getCallerKey('addOrder', suffix: paymentMethod ?? 'cash');

    // `orderData` is the full body. It must already be shaped like
    // `{ordered_items: [...], submitted_order: {...}, delivery_info: {...}}`.
    // If the caller passed a PlacedOrder_API directly, wrap it.
    final body = _coerceCreateBody(orderData);
    if (body == null) {
      _storeFailure(key, orderData,
          code: 400,
          errorCode: 'BAD_PAYLOAD',
          message: 'create-order body must be a map');
      return null;
    }

    try {
      final url = _urlWithQuery(
        '',
        {'payment_method': paymentMethod ?? 'cash'},
      );

      final result = await _storageService.insert(
        url,
        body,
        callerKey: key,
      );

      if (result == null) {
        _storeFailure(key, null,
            code: 500,
            errorCode: 'ADD_FAILED',
            message: 'Server returned no body');
        return null;
      }

      final orderMap = _extractOrderMap(result);
      if (orderMap == null) {
        _storeFailure(key, result,
            code: 500,
            errorCode: 'ADD_MALFORMED',
            message: 'Response did not contain an order');
        return null;
      }

      final order = Order.fromJson(orderMap);
      _storeSuccess(key, order);
      return order;
    } catch (e) {
      _storeFailure(
        key,
        e.toString(),
        errorCode: e is VerdeliaException ? e.message : 'ERROR',
        message: e.toString(),
      );
      return null;
    }
  }

  /// Ensure the body sent to `POST /orders` matches what the router's
  /// FastAPI signature expects.
  static Map<String, dynamic>? _coerceCreateBody(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      // Already shaped with the three keys.
      if (raw.containsKey('submitted_order') ||
          raw.containsKey('ordered_items')) {
        return raw;
      }
      // A `PlacedOrder_API` was passed bare — wrap it as the
      // submitted_order part of the body. The caller is expected to
      // supply `ordered_items` separately on a second call, or use
      // the richer overload. This is a safety net, not the primary
      // path.
      return <String, dynamic>{
        'submitted_order': raw,
        'ordered_items': <Map<String, dynamic>>[],
      };
    }
    return null;
  }

  // ════════════════════════════════════════════════════════════════
  // READ
  // ════════════════════════════════════════════════════════════════

  /// Fetch one order. Uses `GET /orders/{id}`.
  ///
  /// `include_items` is a query param on the router — pass it as an
  /// optional argument here.
  @override
  Future<Order?> getOrder(
    String id, {
    String? callerKey,
    bool includeItems = true,
  }) async {
    final key = callerKey ?? _getCallerKey('getOrder', id: id);
    try {
      final url = _urlWithQuery(
        '/$id',
        {'include_items': includeItems.toString()},
      );

      final data = await _storageService.get(url, id, callerKey: key);

      if (data == null) {
        _storeFailure(key, null,
            code: 404, errorCode: 'NOT_FOUND', message: 'Order $id not found');
        return null;
      }

      final orderMap = _extractOrderMap(data);
      if (orderMap == null) {
        _storeFailure(key, data, code: 500, errorCode: 'GET_MALFORMED');
        return null;
      }

      final order = Order.fromJson(orderMap);
      _storeSuccess(key, order);
      return order;
    } catch (e) {
      _storeFailure(
        key,
        e.toString(),
        errorCode: e is VerdeliaException ? e.message : 'ERROR',
      );
      return null;
    }
  }

  /// Fetch ordered items for an order. Uses `GET /orders/{id}/items`.
  ///
  /// The router returns `{order_id, items: [...], total_items}`. The
  /// items are enriched with `product_name`, `product_brand`,
  /// `product_category` when the product lookup succeeds server-side.
  @override
  Future<List<OrderedItem>> getOrderDetails(
    int idOrder, {
    String? callerKey,
  }) async {
    final key =
        callerKey ?? _getCallerKey('getOrderDetails', id: idOrder.toString());
    try {
      final responseData = await _storageService.getAll(
        _url('/$idOrder/items'),
        callerKey: key,
      );

      if (responseData == null) {
        _storeSuccess(key, <OrderedItem>[], responseCode: 'EMPTY');
        return <OrderedItem>[];
      }

      // `GET /orders/{id}/items` returns `{"items": [...]}`, not
      // a bare array. `_extractList` walks that.
      final list = _extractList(responseData);
      final items = list
          .whereType<Map>()
          .map((m) => OrderedItem.fromJson(Map<String, dynamic>.from(m)))
          .toList(growable: false);

      _storeSuccess(key, items);
      return items;
    } catch (e) {
      _storeFailure(
        key,
        e.toString(),
        errorCode: e is VerdeliaException ? e.message : 'ERROR',
      );
      return <OrderedItem>[];
    }
  }

  /// Fetch a page of orders for a user.
  ///
  /// `GET /orders/user/{user_id}?offset=&limit=` — the router's
  /// `get_user_orders` handler. The user_id is a path parameter,
  /// not a query filter. There is no status filter on this endpoint;
  /// use `updateOrderStatus` to change status, and filter client-side
  /// if you need to.
  @override
  Future<List<Order>> getAllOrders(
    int offset,
    int limit, {
    int idUser = 0,
    String? callerKey,
  }) async {
    if (idUser <= 0) {
      // The endpoint requires a user id in the path. A `0` here is
      // a caller bug, not a server call.
      final key = callerKey ?? _getCallerKey('getAllOrders');
      _storeFailure(key, null,
          code: 400,
          errorCode: 'MISSING_USER',
          message: 'getAllOrders requires idUser > 0');
      return <Order>[];
    }

    final key = callerKey ??
        _getCallerKey(
          'getAllOrders',
          suffix: 'user_$idUser-offset_$offset-limit_$limit',
        );

    try {
      final url = _urlWithQuery(
        '/user/$idUser',
        {
          'offset': offset.toString(),
          'limit': limit.toString(),
        },
      );

      final responseData = await _storageService.getAll(url, callerKey: key);

      if (responseData == null) {
        _storeSuccess(key, <Order>[], responseCode: 'EMPTY');
        return <Order>[];
      }

      final list = _extractList(responseData);
      final orders = list
          .whereType<Map>()
          .map((m) => Order.fromJson(Map<String, dynamic>.from(m)))
          .toList(growable: false);

      _storeSuccess(key, orders);
      return orders;
    } catch (e) {
      _storeFailure(
        key,
        e.toString(),
        errorCode: e is VerdeliaException ? e.message : 'ERROR',
      );
      return <Order>[];
    }
  }

  // ════════════════════════════════════════════════════════════════
  // UPDATE
  // ════════════════════════════════════════════════════════════════

  /// Update an order's metadata and items. Uses `PUT /orders/{id}`.
  ///
  /// The router expects `{updated_items: [...], updated_order: {...}}`
  /// as the body (the two FastAPI params). `Order` on the client side
  /// doesn't carry items, so this method accepts them explicitly:
  /// pass `updatedOrder` for the metadata and `updatedItems` for the
  /// item list. If `updatedItems` is null, an empty list is sent —
  /// which tells the server "replace items with nothing" (typically
  /// not what you want; pass the existing items to keep them).
  @override
  Future<Order?> updateOrder(
    Order updatedOrder, {
    String? callerKey,
    List<OrderedItem>? updatedItems,
  }) async {
    final orderId = updatedOrder.idPlacedOrder;
    if (orderId == null) {
      log('updateOrder called with an Order that has no id',
          name: 'OrderServiceImpl');
      return null;
    }

    final key =
        callerKey ?? _getCallerKey('updateOrder', id: orderId.toString());
    try {
      final body = <String, dynamic>{
        'updated_order': updatedOrder.toJson(),
        'updated_items': (updatedItems ?? const <OrderedItem>[])
            .map((i) => i.toJson())
            .toList(),
      };

      final result = await _storageService.update(
        _url('/$orderId'),
        orderId.toString(),
        const <String, dynamic>{}, // no query params
        body,
        callerKey: key,
      );

      if (result == null) {
        _storeFailure(key, null, code: 500, errorCode: 'UPDATE_FAILED');
        return null;
      }

      final orderMap = _extractOrderMap(result);
      if (orderMap == null) {
        _storeFailure(key, result, code: 500, errorCode: 'UPDATE_MALFORMED');
        return null;
      }

      final order = Order.fromJson(orderMap);
      _storeSuccess(key, order);
      return order;
    } catch (e) {
      _storeFailure(
        key,
        e.toString(),
        errorCode: e is VerdeliaException ? e.message : 'ERROR',
      );
      return null;
    }
  }

  /// Update only an order's status. Uses `PATCH /orders/{id}/status?status=`.
  ///
  /// The router validates the transition against
  /// `STATUS_TRANSITIONS`. Legal moves:
  ///
  ///     PENDING    → PROCESSING, CANCELLED
  ///     PROCESSING → SHIPPED, CANCELLED
  ///     SHIPPED    → DELIVERED, CANCELLED, REFUNDED
  ///     DELIVERED  → REFUNDED
  ///     CANCELLED  → (terminal)
  ///     REFUNDED   → (terminal)
  ///
  /// An illegal transition returns 400 with a JSON body naming the
  /// allowed targets. This method stores the raw body so the caller
  /// can present that.
  Future<Order?> updateOrderStatus(
    String orderId,
    String newStatus, {
    String? callerKey,
  }) async {
    final key = callerKey ??
        _getCallerKey(
          'updateOrderStatus',
          id: orderId,
          suffix: 'status_$newStatus',
        );
    try {
      final url = _urlWithQuery(
        '/$orderId/status',
        {'status': newStatus},
      );

      final result = await _storageService.update(
        url,
        orderId,
        const <String, dynamic>{}, // no body params
        {}, // PATCH with query param only
        callerKey: key,
      );

      if (result == null) {
        _storeFailure(key, null, code: 500, errorCode: 'STATUS_UPDATE_FAILED');
        return null;
      }

      // The router returns `{order_id, previous_status, new_status,
      // updated_at}` — not a full Order. Re-fetch the order so the
      // caller gets a real object.
      final order = await getOrder(
        orderId,
        callerKey: '${key}_refetch',
      );
      _storeSuccess(key, order);
      return order;
    } catch (e) {
      _storeFailure(
        key,
        e.toString(),
        errorCode: e is VerdeliaException ? e.message : 'ERROR',
      );
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════════
  // DELETE
  // ════════════════════════════════════════════════════════════════

  /// Delete an order. Uses `DELETE /orders/{id}?force_delete=`.
  ///
  /// The router returns 204 on success, 400 if the order has items
  /// and `force_delete=false`, 404 if the order is missing, 500 on
  /// server error. Returns the status code, or `null` on a client-side
  /// failure (network / serialization).
  @override
  Future<int?> deleteOrder(
    String orderId, {
    String? callerKey,
    bool forceDelete = false,
  }) async {
    final key = callerKey ?? _getCallerKey('deleteOrder', id: orderId);
    try {
      final url = _urlWithQuery(
        '/$orderId',
        {'force_delete': forceDelete.toString()},
      );

      final result = await _storageService.delete(
        url,
        orderId,
        callerKey: key,
      );

      if (result == 204 || result == 200) {
        _storeSuccess(key, true, code: result);
      } else if (result == 404) {
        _storeFailure(key, false,
            code: 404,
            errorCode: 'NOT_FOUND',
            message: 'Order $orderId not found');
      } else if (result == 400) {
        _storeFailure(key, false,
            code: 400,
            errorCode: 'HAS_ITEMS',
            message: 'Order has items; pass forceDelete=true to delete anyway');
      } else if (result == 0) {
        _storeFailure(key, false,
            code: 0,
            errorCode: 'NETWORK_ERROR',
            message: 'Delete request never reached the server');
      } else {
        _storeFailure(key, false, code: result);
      }
      return result;
    } catch (e) {
      _storeFailure(
        key,
        e.toString(),
        errorCode: e is VerdeliaException ? e.message : 'ERROR',
      );
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════════
  // PAYMENT / INVENTORY — phases 2 and 3
  // ════════════════════════════════════════════════════════════════

  /// Pay an order. Uses `POST /orders/{id}/pay?payment_method=`.
  ///
  /// Idempotent on already-paid invoices. Returns the router's raw
  /// body (`{cart_id?..., payment_id, payment_status, ...}`); callers
  /// that only care about the outcome can look at `payment_status`.
  Future<Map<String, dynamic>?> payOrder(
    int orderId, {
    String paymentMethod = 'card',
    String? callerKey,
  }) async {
    final key = callerKey ??
        _getCallerKey(
          'payOrder',
          id: orderId.toString(),
          suffix: paymentMethod,
        );
    try {
      final url = _urlWithQuery(
        '/$orderId/pay',
        {'payment_method': paymentMethod},
      );

      final result = await _storageService.insert(
        url,
        const <String, dynamic>{},
        callerKey: key,
      );

      if (result is! Map) {
        _storeFailure(key, result, code: 500, errorCode: 'PAY_MALFORMED');
        return null;
      }
      final body = Map<String, dynamic>.from(result);
      _storeSuccess(key, body);
      return body;
    } catch (e) {
      _storeFailure(
        key,
        e.toString(),
        errorCode: e is VerdeliaException ? e.message : 'ERROR',
      );
      return null;
    }
  }

  /// Confirm inventory for an order. Uses
  /// `POST /orders/{id}/confirm-inventory`.
  ///
  /// Runs after `payOrder`. Idempotent on already-confirmed items.
  Future<Map<String, dynamic>?> confirmInventory(
    int orderId, {
    String? callerKey,
  }) async {
    final key =
        callerKey ?? _getCallerKey('confirmInventory', id: orderId.toString());
    try {
      final result = await _storageService.insert(
        _url('/$orderId/confirm-inventory'),
        const <String, dynamic>{},
        callerKey: key,
      );

      if (result is! Map) {
        _storeFailure(key, result, code: 500, errorCode: 'CONFIRM_MALFORMED');
        return null;
      }
      final body = Map<String, dynamic>.from(result);
      _storeSuccess(key, body);
      return body;
    } catch (e) {
      _storeFailure(
        key,
        e.toString(),
        errorCode: e is VerdeliaException ? e.message : 'ERROR',
      );
      return null;
    }
  }

  /// Convenience: pay + confirm-inventory in one call. Uses
  /// `POST /orders/{id}/finalize?payment_method=`.
  Future<Map<String, dynamic>?> finalizeOrder(
    int orderId, {
    String paymentMethod = 'card',
    String? callerKey,
  }) async {
    final key = callerKey ??
        _getCallerKey(
          'finalizeOrder',
          id: orderId.toString(),
          suffix: paymentMethod,
        );
    try {
      final url = _urlWithQuery(
        '/$orderId/finalize',
        {'payment_method': paymentMethod},
      );

      final result = await _storageService.insert(
        url,
        const <String, dynamic>{},
        callerKey: key,
      );

      if (result is! Map) {
        _storeFailure(key, result, code: 500, errorCode: 'FINALIZE_MALFORMED');
        return null;
      }
      final body = Map<String, dynamic>.from(result);
      _storeSuccess(key, body);
      return body;
    } catch (e) {
      _storeFailure(
        key,
        e.toString(),
        errorCode: e is VerdeliaException ? e.message : 'ERROR',
      );
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════════
  // INVENTORY READ
  // ════════════════════════════════════════════════════════════════

  /// Read live inventory status for the order's items. Uses
  /// `GET /orders/{id}/inventory-status`.
  ///
  /// Returns per-item availability. This is a *read* — it does not
  /// reserve or deduct.
  Future<Map<String, dynamic>?> getInventoryStatus(
    int orderId, {
    String? callerKey,
  }) async {
    final key = callerKey ??
        _getCallerKey('getInventoryStatus', id: orderId.toString());
    try {
      final result = await _storageService.get(
        _url('/$orderId/inventory-status'),
        orderId.toString(),
        callerKey: key,
      );

      if (result is! Map) {
        _storeFailure(key, result, code: 500, errorCode: 'INVENTORY_MALFORMED');
        return null;
      }
      final body = Map<String, dynamic>.from(result);
      _storeSuccess(key, body);
      return body;
    } catch (e) {
      _storeFailure(
        key,
        e.toString(),
        errorCode: e is VerdeliaException ? e.message : 'ERROR',
      );
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════════
  // CONVENIENCE
  // ════════════════════════════════════════════════════════════════

  /// Orders for a user, paginated. Thin wrapper around
  /// `getAllOrders` with the id passed positionally, matching the
  /// ergonomics of the original API.
  Future<List<Order>> getOrdersByUser(
    int userId, {
    int offset = 0,
    int limit = 100,
    String? callerKey,
  }) {
    return getAllOrders(
      offset,
      limit,
      idUser: userId,
      callerKey:
          callerKey ?? _getCallerKey('getOrdersByUser', id: userId.toString()),
    );
  }

  /// No-op today; kept because some callers reference it. Wire a
  /// cache here later without breaking them.
  void clearCache() {
    log('Order service cache cleared', name: 'OrderServiceImpl');
  }
}
