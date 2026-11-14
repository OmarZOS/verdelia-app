// lib/business/finance/Order.dart

import 'dart:convert';
import 'dart:developer';

import 'package:decimal/decimal.dart';

import 'package:verdelia_core/app/AppUser.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:verdelia_core/business/finance/Cart.dart';
import 'package:verdelia_core/business/finance/OrderedItem.dart';

class Order {
  final int idPlacedOrder;

  /// Order-level discount, in [Decimal]. Null when the payload carried
  /// no discount.
  final Decimal? orderDiscount;

  /// Order subtotal (before [orderDiscount]), in [Decimal].
  final Decimal totalPrice;

  final int? orderingUserId;
  final int? placedOrderLocationRef;
  final int? placedOrderStateRef;
  final String? placedOrderStateRaw;
  final DateTime placedOrderLastMod;
  final int? placedOrderInvoiceRef;
  final int? placedOrderReceiptRef;
  final DateTime placedOrderCreation;
  List<OrderedItem>? items;
  AppUser? orderingUser;
  String? paymentStatus;
  String? paymentMethod;
  String? paymentRef;
  String? customerName;

  Order({
    required this.idPlacedOrder,
    this.orderDiscount,
    required this.totalPrice,
    this.orderingUserId,
    this.placedOrderLocationRef,
    this.placedOrderStateRef,
    this.placedOrderStateRaw,
    required this.placedOrderLastMod,
    this.placedOrderInvoiceRef,
    this.placedOrderReceiptRef,
    required this.placedOrderCreation,
    this.items,
    this.orderingUser,
    this.paymentStatus,
    this.paymentMethod,
    this.paymentRef,
    this.customerName,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final rawItems = json['ordered_item'] ?? json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((e) => OrderedItem.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : null;

    final stateRef = (json['placed_order_state_ref'] as num?)?.toInt();
    final stateStr =
        (json['order_state'] ?? json['placed_order_state']) as String?;

    AppUser? orderingUser;
    final rawUser = json['ordering_user'] ?? json['app_user'];
    if (rawUser is Map) {
      try {
        orderingUser = AppUser.fromJson(Map<String, dynamic>.from(rawUser));
      } catch (e) {
        log('Order.fromJson: failed to parse ordering_user: $e');
      }
    }

    final explicitName = json['customer_name'] as String?;
    final derivedName = orderingUser?.displayName;

    // Parenthesise the whole `??` before `as`, not just one operand.
    // `a ?? b as num?` parses as `a ?? (b as num?)` and the fallback
    // silently loses its type. The `?.toX()` then relies on whatever
    // happened to survive at runtime.
    return Order(
      idPlacedOrder: (json['id_placed_order'] as num?)?.toInt() ?? 0,
      orderDiscount: _readDecimal(
        json['discount_amount'] ?? json['order_discount'],
      ),
      totalPrice: _readDecimalOrZero(
        json['subtotal'] ?? json['total_price'],
      ),
      orderingUserId: (json['ordering_user_id'] as num?)?.toInt(),
      placedOrderLocationRef: ((json['order_location_id'] ??
              json['placed_order_location_ref']) as num?)
          ?.toInt(),
      placedOrderStateRef: stateRef,
      placedOrderStateRaw: stateStr,
      placedOrderLastMod: _parseDateTime(
        json['updated_at'] ?? json['placed_order_last_mod'],
      ),
      placedOrderInvoiceRef:
          ((json['invoice_id'] ?? json['placed_order_invoice_ref']) as num?)
              ?.toInt(),
      placedOrderReceiptRef:
          (json['placed_order_receipt_ref'] as num?)?.toInt(),
      placedOrderCreation: _parseDateTime(
        json['created_at'] ?? json['placed_order_creation'],
      ),
      items: items,
      orderingUser: orderingUser,
      paymentStatus: json['payment_status'] as String?,
      paymentMethod: json['payment_method'] as String?,
      paymentRef: json['payment_ref'] as String?,
      customerName: (explicitName != null && explicitName.isNotEmpty)
          ? explicitName
          : derivedName,
    );
  }

  static DateTime _parseDateTime(dynamic dateString) {
    if (dateString == null) return DateTime.now();
    try {
      return DateTime.parse(dateString.toString()).toLocal();
    } catch (e) {
      return DateTime.now();
    }
  }

  String get status {
    if (placedOrderStateRaw != null && placedOrderStateRaw!.isNotEmpty) {
      return placedOrderStateRaw!.toLowerCase();
    }
    return _statusFromRef(placedOrderStateRef);
  }

  String get statusRaw =>
      (placedOrderStateRaw ?? _statusFromRef(placedOrderStateRef))
          .toUpperCase();

  static String _statusFromRef(int? stateRef) {
    switch (stateRef) {
      case 1:
        return 'pending';
      case 2:
        return 'processing';
      case 3:
        return 'shipped';
      case 4:
        return 'delivered';
      case 5:
        return 'cancelled';
      case 6:
        return 'refunded';
      default:
        return 'unknown';
    }
  }

  static int _stateToRef(String state) {
    switch (state.toLowerCase()) {
      case 'pending':
        return 1;
      case 'processing':
        return 2;
      case 'shipped':
        return 3;
      case 'delivered':
        return 4;
      case 'cancelled':
        return 5;
      case 'refunded':
        return 6;
      default:
        return 1;
    }
  }

  String get orderingUserName {
    if (orderingUser != null) return orderingUser!.displayName;
    if (customerName != null && customerName!.isNotEmpty) return customerName!;
    if (orderingUserId != null) return 'User #$orderingUserId';
    return 'Unknown';
  }

  String? get orderingUserImageUrl => orderingUser?.appUserImageUrl;

  String get orderingUserInitials {
    if (orderingUser != null) return orderingUser!.shortName;
    if (customerName != null && customerName!.isNotEmpty) {
      final parts = customerName!.split(' ');
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      }
      return customerName!.substring(0, 1).toUpperCase();
    }
    return '?';
  }

  bool get hasOrderingUser =>
      orderingUser != null || (customerName?.isNotEmpty ?? false);

  Map<String, dynamic> toSummaryJson() {
    return {
      'id_placed_order': idPlacedOrder,
      'order_discount': _decimalToWireOrNull(orderDiscount),
      'total_price': _decimalToWire(totalPrice),
      'ordering_user_id': orderingUserId,
      'placed_order_location_ref': placedOrderLocationRef,
      'placed_order_state_ref': placedOrderStateRef,
      'placed_order_state': statusRaw,
      'placed_order_last_mod': placedOrderLastMod.toIso8601String(),
      'placed_order_invoice_ref': placedOrderInvoiceRef,
      'placed_order_receipt_ref': placedOrderReceiptRef,
      'placed_order_creation': placedOrderCreation.toIso8601String(),
      'status': status,
      'payment_status': paymentStatus,
      'payment_method': paymentMethod,
      'payment_ref': paymentRef,
      'customer_name': customerName,
      if (orderingUser != null) 'ordering_user': orderingUser!.toJson(),
    };
  }

  Map<String, dynamic> toSubmissionJson() {
    return {
      "ordered_items": items?.map((item) => item.toJson()).toList() ?? [],
      "order_discount": _decimalToWireOrNull(orderDiscount),
      "total_price": _decimalToWire(totalPrice),
      "ordering_user_id": orderingUserId,
      "placed_order_location_ref": placedOrderLocationRef,
      "placed_order_state_ref": placedOrderStateRef ?? 1,
    };
  }

  Map<String, dynamic> toJson({Map<String, dynamic>? deliveryInfo}) {
    return {
      'ordered_items':
          items?.map((item) => item.toOrderedItemApiJson()).toList() ?? [],
      'submitted_order': {
        'id_placed_order': idPlacedOrder,
        'ordered_timestamp': placedOrderCreation.toIso8601String(),
        'order_discount': _decimalToWire(orderDiscount ?? Decimal.zero),
        'placed_order_last_mod': placedOrderLastMod.toIso8601String(),
        'payment_status': paymentStatus?.toLowerCase() ?? 'pending',
        'payment_ref': paymentRef ?? '',
        'placed_order_state': statusRaw,
        'payment_method': paymentMethod ?? 'cash',
        'ordering_user_id': orderingUserId,
      },
      if (deliveryInfo != null) 'delivery_info': deliveryInfo,
    };
  }

  Map<String, dynamic> toJsonForService() {
    return {
      'id_order': idPlacedOrder,
      'total_amount': _decimalToWire(totalPrice),
      'order_discount': _decimalToWireOrNull(orderDiscount),
      'order_date': placedOrderCreation.toIso8601String(),
      'last_modified': placedOrderLastMod.toIso8601String(),
      'status': statusRaw,
      'payment_status': paymentStatus,
      'payment_method': paymentMethod,
      'payment_reference': paymentRef,
      'customer_name': customerName,
      if (orderingUserId != null) 'user_id': orderingUserId,
      if (placedOrderLocationRef != null) 'location_id': placedOrderLocationRef,
      if (placedOrderInvoiceRef != null) 'invoice_id': placedOrderInvoiceRef,
      if (placedOrderReceiptRef != null) 'receipt_id': placedOrderReceiptRef,
      if (items != null)
        'items': items!.map((item) => item.toJsonForService()).toList(),
      if (orderingUser != null) 'user': orderingUser!.toApiJson(),
    };
  }

  Order copyWith({
    int? idPlacedOrder,
    Decimal? orderDiscount,
    Decimal? totalPrice,
    int? orderingUserId,
    int? placedOrderLocationRef,
    int? placedOrderStateRef,
    String? placedOrderStateRaw,
    DateTime? placedOrderLastMod,
    int? placedOrderInvoiceRef,
    int? placedOrderReceiptRef,
    DateTime? placedOrderCreation,
    List<OrderedItem>? items,
    AppUser? orderingUser,
    String? paymentStatus,
    String? paymentMethod,
    String? paymentRef,
    String? customerName,
  }) {
    return Order(
      idPlacedOrder: idPlacedOrder ?? this.idPlacedOrder,
      orderDiscount: orderDiscount ?? this.orderDiscount,
      totalPrice: totalPrice ?? this.totalPrice,
      orderingUserId: orderingUserId ?? this.orderingUserId,
      placedOrderLocationRef:
          placedOrderLocationRef ?? this.placedOrderLocationRef,
      placedOrderStateRef: placedOrderStateRef ?? this.placedOrderStateRef,
      placedOrderStateRaw: placedOrderStateRaw ?? this.placedOrderStateRaw,
      placedOrderLastMod: placedOrderLastMod ?? this.placedOrderLastMod,
      placedOrderInvoiceRef:
          placedOrderInvoiceRef ?? this.placedOrderInvoiceRef,
      placedOrderReceiptRef:
          placedOrderReceiptRef ?? this.placedOrderReceiptRef,
      placedOrderCreation: placedOrderCreation ?? this.placedOrderCreation,
      items: items ?? this.items,
      orderingUser: orderingUser ?? this.orderingUser,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentRef: paymentRef ?? this.paymentRef,
      customerName: customerName ?? this.customerName,
    );
  }

  bool get isCompleted => status == 'delivered';
  bool get isPending => status == 'pending';
  bool get isProcessing => status == 'processing';
  bool get isShipped => status == 'shipped';
  bool get isCancelled => status == 'cancelled';
  bool get isRefunded => status == 'refunded';

  bool get hasInvoice => placedOrderInvoiceRef != null;
  bool get hasReceipt => placedOrderReceiptRef != null;
  bool get hasLocation => placedOrderLocationRef != null;

  bool get isPaid => paymentStatus?.toLowerCase() == 'paid';

  /// [totalPrice] minus [orderDiscount], in [Decimal].
  Decimal get netPrice => totalPrice - (orderDiscount ?? Decimal.zero);

  bool hasItems() => items != null && items!.isNotEmpty;

  int get itemCount =>
      items?.fold(0, (sum, item) => (sum ?? 0) + item.orderedQuantity) ?? 0;

  int get totalQuantity =>
      items?.fold(0, (total, item) => (total ?? 0) + item.orderedQuantity) ?? 0;

  /// Same as [netPrice], kept as a separate getter for API compatibility.
  Decimal get finalTotal => totalPrice - (orderDiscount ?? Decimal.zero);

  static Map<String, dynamic> buildSingleOrderData({
    required Product product,
    required int quantity,
    required int orderingUserId,
    Decimal? discount,
    Decimal? taxRate,
    int? locationRef,
    String? paymentStatus,
    String? paymentMethod,
    String? paymentRef,
    String? orderState,
  }) {
    if (quantity <= 0) throw ArgumentError('Quantity must be positive');
    if (product.id_product == null) {
      throw ArgumentError('Product ID cannot be null');
    }

    final d = discount ?? Decimal.zero;
    final t = taxRate ?? Decimal.zero;

    final unitPrice = _readDecimalOrZero(product.unit_price);
    final totalPrice = unitPrice * Decimal.fromInt(quantity);

    // `product_discount` on the wire is a percentage per
    // `OrderedItem_API`. The static builder accepts a monetary
    // `discount`, so convert: percent = (discount / lineBase) * 100.
    final discountPercent = totalPrice > Decimal.zero
        ? (d / totalPrice).toDecimal(scaleOnInfinitePrecision: 2) *
            Decimal.fromInt(100)
        : Decimal.zero;

    return {
      "ordered_items": [
        {
          "id_ordered_item": 0,
          "product_id": product.id_product!,
          "order_ref": 0,
          "product_discount": _decimalToWire(discountPercent),
          "ordered_quantity": quantity,
          "unit_price": _decimalToWire(unitPrice),
          "vat_rate": _decimalToWire(t),
        },
      ],
      "submitted_order": {
        "id_placed_order": 0,
        "ordered_timestamp": DateTime.now().toIso8601String(),
        "order_discount": _decimalToWire(
          d < totalPrice ? d : totalPrice,
        ),
        "placed_order_last_mod": DateTime.now().toIso8601String(),
        "payment_status": paymentStatus ?? 'pending',
        "payment_ref": paymentRef ?? '',
        "placed_order_state": orderState ?? 'PENDING',
        "payment_method": paymentMethod ?? 'cash',
        "ordering_user_id": orderingUserId,
      },
    };
  }

  static Map<String, dynamic> buildOrderData(
    List<CartItem> cartItems,
    int orderingUserId, {
    Decimal? orderDiscount,
    int? locationRef,
    String? paymentStatus,
    String? paymentMethod,
    String? paymentRef,
    String? orderState,
  }) {
    if (cartItems.isEmpty) {
      throw StateError('Cannot build order with empty cart');
    }

    final orderedItems = <Map<String, dynamic>>[];
    Decimal totalPrice = Decimal.zero;

    for (final item in cartItems) {
      final product = item.product;
      if (product?.id_product == null) {
        throw ArgumentError('Product ID cannot be null for order item');
      }

      final catalogPrice = item.catalogUnitPrice ?? Decimal.zero;
      final effectivePrice = item.unitPrice ?? catalogPrice;
      totalPrice += effectivePrice * Decimal.fromInt(item.quantity);

      orderedItems.add({
        "id_ordered_item": 0,
        "product_id": product!.id_product!,
        "order_ref": 0,
        "ordered_quantity": item.quantity,
        "unit_price": _decimalToWire(catalogPrice),
        "product_discount": _decimalToWire(item.discountPercent),
        "vat_rate": _decimalToWire(item.appliedVatPercent),
      });
    }

    final d = orderDiscount ?? Decimal.zero;
    final finalDiscount = d < totalPrice ? d : totalPrice;

    return {
      "ordered_items": orderedItems,
      "submitted_order": {
        "id_placed_order": 0,
        "ordered_timestamp": DateTime.now().toIso8601String(),
        "order_discount": _decimalToWire(finalDiscount),
        "placed_order_last_mod": DateTime.now().toIso8601String(),
        "payment_status": paymentStatus ?? 'pending',
        "payment_ref": paymentRef ?? '',
        "placed_order_state": orderState ?? 'PENDING',
        "payment_method": paymentMethod ?? 'cash',
        "ordering_user_id": orderingUserId,
      },
    };
  }

  static Map<String, dynamic> buildOrderDataFromOrder(Order order) {
    return {
      "ordered_items":
          order.items?.map((item) => item.toOrderedItemApiJson()).toList() ??
              [],
      "submitted_order": {
        "id_placed_order": order.idPlacedOrder,
        "ordered_timestamp": order.placedOrderCreation.toIso8601String(),
        "order_discount": _decimalToWire(order.orderDiscount ?? Decimal.zero),
        "placed_order_last_mod": order.placedOrderLastMod.toIso8601String(),
        "payment_status": order.paymentStatus?.toLowerCase() ?? 'pending',
        "payment_ref": order.paymentRef ?? '',
        "placed_order_state": order.statusRaw,
        "payment_method": order.paymentMethod ?? 'cash',
        "ordering_user_id": order.orderingUserId,
      },
    };
  }

  static Map<String, dynamic> buildOrderUpdateData({
    required int orderId,
    String? orderState,
    Decimal? orderDiscount,
    String? paymentStatus,
    String? paymentMethod,
    String? paymentRef,
    int? locationRef,
  }) {
    return {
      "ordered_items": [],
      "submitted_order": {
        "id_placed_order": orderId,
        "placed_order_state": orderState,
        "order_discount": _decimalToWireOrNull(orderDiscount),
        "payment_status": paymentStatus,
        "payment_method": paymentMethod,
        "payment_ref": paymentRef,
        "placed_order_last_mod": DateTime.now().toIso8601String(),
      },
    };
  }

  @override
  String toString() {
    return 'Order(id: $idPlacedOrder, total: DZD$totalPrice, '
        'status: $status, items: ${items?.length ?? 0}, '
        'user: $orderingUserName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Order && idPlacedOrder == other.idPlacedOrder;
  }

  @override
  int get hashCode => idPlacedOrder.hashCode;
}

List<OrderedItem> parseOrderedItems(List<dynamic> jsonList) {
  return jsonList
      .whereType<Map>()
      .map((item) => OrderedItem.fromJson(Map<String, dynamic>.from(item)))
      .toList();
}

List<Map<String, dynamic>> orderedItemsToJson(List<OrderedItem> items) {
  return items.map((item) => item.toJson()).toList();
}

Order createOrderFromCart({
  required int userId,
  required List<CartItem> cartItems,
  Decimal? orderDiscount,
  int? locationId,
  int? invoiceRef,
  int? receiptRef,
  String? paymentStatus,
  String? paymentMethod,
  String? paymentRef,
}) {
  Decimal totalPrice = Decimal.zero;
  for (final item in cartItems) {
    totalPrice += item.totalPrice;
  }

  final orderedItems = cartItems.map((cartItem) {
    final product = cartItem.product;
    return OrderedItem(
      idOrderedItem: 0,
      orderedProductId: product?.id_product,
      orderedQuantity: cartItem.quantity,
      appliedVat: cartItem.appliedVatPercent,
      orderRef: 0,
      unitPrice: cartItem.unitPrice ?? Decimal.zero,
      productDiscount: cartItem.discountPercent,
      orderedItemCartRef: 0,
      reservedQuantity: 0,
      orderedProduct: product != null
          ? OrderedProduct(
              productName: product.product_name ?? "",
              productProviderId: product.product_provider_id ?? 0,
              productQuantifier: product.product_quantifier,
              productOwner: product.product_owner_id ?? 0,
              productBrand: product.product_brand ?? '',
              productCategoryId: product.product_category_id ?? 0,
              idProduct: product.id_product ?? 0,
              lastUpdated: DateTime.now(),
              productBarcode: product.product_barcode ?? '',
              created: DateTime.now(),
              productDescription: product.product_description ?? '',
              productPrice: _readDecimalOrZero(product.product_price),
              productQuantity: product.product_quantity ?? 0,
            )
          : null,
    );
  }).toList();

  return Order(
    idPlacedOrder: 0,
    orderDiscount: orderDiscount,
    totalPrice: totalPrice,
    orderingUserId: userId,
    placedOrderLocationRef: locationId,
    placedOrderStateRef: 1,
    placedOrderLastMod: DateTime.now(),
    placedOrderInvoiceRef: invoiceRef,
    placedOrderReceiptRef: receiptRef,
    placedOrderCreation: DateTime.now(),
    items: orderedItems,
    paymentStatus: paymentStatus,
    paymentMethod: paymentMethod,
    paymentRef: paymentRef,
  );
}

// ============================================================================
// Decimal helpers
// ============================================================================

/// Coerces any JSON value to [Decimal].
///
/// * [Decimal] → passthrough
/// * `int`     → `Decimal.fromInt`
/// * `double`  → `Decimal.tryParse(v.toString())` (shortest round-trip,
///                NOT the binary expansion)
/// * `String`  → `Decimal.tryParse`
/// * anything else, or a non-finite `double` → `null`
Decimal? _readDecimal(dynamic v) {
  if (v == null) return null;
  if (v is Decimal) return v;
  if (v is int) return Decimal.fromInt(v);
  if (v is double) {
    if (v.isNaN || v.isInfinite) return null;
    return Decimal.tryParse(v.toString());
  }
  if (v is String) return Decimal.tryParse(v);
  return null;
}

/// Coerces any JSON value to a [Decimal], defaulting to zero.
Decimal _readDecimalOrZero(dynamic v) => _readDecimal(v) ?? Decimal.zero;

/// Converts a [Decimal] to the shortest `double` that round-trips.
/// For the JSON wire boundary only — never use this for arithmetic.
double _decimalToDouble(Decimal v) => double.parse(v.toString());

/// Serialises a [Decimal] for JSON. Emits a `num` so `jsonEncode`
/// writes it as a JSON number, not a string.
num _decimalToWire(Decimal v) => _decimalToDouble(v);

/// [decimalToWire] with a `null` passthrough, for optional money fields.
num? _decimalToWireOrNull(Decimal? v) => v == null ? null : _decimalToWire(v);
