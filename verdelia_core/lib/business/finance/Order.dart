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
  /// no discount. (`discount_amount` on the `placed_order` row.)
  final Decimal? orderDiscount;

  /// FK to the `discount` row applied to this order. Null when no
  /// discount was applied. The applied *amount* lives in
  /// [orderDiscount]; this is the discount entity's id.
  final int? discountId;

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

  /// Nested invoice payload, when the order response expands it.
  /// Null when the endpoint only carries `invoice_id` (list views
  /// without `?expand=invoice`, for example).
  InvoiceSummary? invoice;

  String? paymentStatus;
  String? paymentMethod;
  String? paymentRef;
  String? customerName;

  Order({
    required this.idPlacedOrder,
    this.orderDiscount,
    this.discountId,
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
    this.invoice,
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

    InvoiceSummary? invoice;
    final rawInvoice = json['invoice'];
    if (rawInvoice is Map) {
      try {
        invoice = InvoiceSummary.fromJson(
          Map<String, dynamic>.from(rawInvoice),
        );
      } catch (e) {
        log('Order.fromJson: failed to parse invoice: $e');
      }
    }

    final explicitName = json['customer_name'] as String?;
    final derivedName = orderingUser?.displayName;

    return Order(
      idPlacedOrder: (json['id_placed_order'] as num?)?.toInt() ?? 0,
      orderDiscount: _readDecimal(
        json['discount_amount'] ?? json['order_discount'],
      ),
      discountId: (json['discount_id'] as num?)?.toInt(),
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
      invoice: invoice,
      // `payment_status` etc. are not present on the placed_order row
      // in the current schema; they live on the invoice. Kept here so
      // callers that receive a flat order payload (e.g. from a search
      // index) can populate them.
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
      case 'canceled':
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

  /// Non-null view of [items] for call sites that just want to iterate.
  List<OrderedItem> get orderedItems => items ?? const [];

  // ── Invoice shortcuts ──────────────────────────────────────────────

  /// True when the order carries an invoice reference (FK) or an
  /// expanded invoice object. Use [hasExpandedInvoice] to distinguish.
  bool get hasInvoice => placedOrderInvoiceRef != null || invoice != null;

  /// True when the invoice payload is expanded (not just the FK).
  bool get hasExpandedInvoice => invoice != null;

  /// Invoice status as a lowercase string: paid, unpaid,
  /// partially_paid, overdue, refunded, canceled. Falls back to the
  /// order-level [paymentStatus] when the invoice isn't expanded.
  String? get invoiceStatus {
    final fromInvoice = invoice?.status;
    if (fromInvoice != null && fromInvoice.isNotEmpty) return fromInvoice;
    return paymentStatus?.toLowerCase();
  }

  bool get isInvoicePaid => invoiceStatus == 'paid';
  bool get isInvoiceUnpaid => invoiceStatus == 'unpaid';
  bool get isInvoiceOverdue => invoiceStatus == 'overdue';
  bool get isInvoicePartiallyPaid => invoiceStatus == 'partially_paid';
  bool get isInvoiceRefunded => invoiceStatus == 'refunded';
  bool get isInvoiceCanceled => invoiceStatus == 'canceled';

  /// True when the invoice has an outstanding balance the customer
  /// still owes. Only meaningful when [hasExpandedInvoice].
  bool get isInvoiceOutstanding => invoice?.isOutstanding ?? false;

  /// The invoice's grand total when expanded, otherwise the order's
  /// own [totalPrice]. Both are [Decimal].
  Decimal get effectiveTotal => invoice?.grandTotal ?? totalPrice;

  Map<String, dynamic> toSummaryJson() {
    return {
      'id_placed_order': idPlacedOrder,
      'order_discount': _decimalToWireOrNull(orderDiscount),
      'discount_id': discountId,
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
      if (invoice != null) 'invoice': invoice!.toJson(),
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
        'discount_id': discountId,
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
      'discount_id': discountId,
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
      if (invoice != null) 'invoice': invoice!.toJson(),
    };
  }

  Order copyWith({
    int? idPlacedOrder,
    Decimal? orderDiscount,
    int? discountId,
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
    InvoiceSummary? invoice,
    String? paymentStatus,
    String? paymentMethod,
    String? paymentRef,
    String? customerName,
  }) {
    return Order(
      idPlacedOrder: idPlacedOrder ?? this.idPlacedOrder,
      orderDiscount: orderDiscount ?? this.orderDiscount,
      discountId: discountId ?? this.discountId,
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
      invoice: invoice ?? this.invoice,
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

  bool get hasReceipt => placedOrderReceiptRef != null;
  bool get hasLocation => placedOrderLocationRef != null;

  bool get isPaid => paymentStatus?.toLowerCase() == 'paid';

  /// [totalPrice] minus [orderDiscount], in [Decimal].
  Decimal get netPrice => totalPrice - (orderDiscount ?? Decimal.zero);

  bool hasItems() => orderedItems.isNotEmpty;

  int get itemCount =>
      orderedItems.fold(0, (sum, item) => sum + item.orderedQuantity);

  int get totalQuantity =>
      orderedItems.fold(0, (total, item) => total + item.orderedQuantity);

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

      // NOTE: `unit_price` on the wire is the *catalog* price. Any
      // override (discount) is carried separately via
      // `product_discount`. `totalPrice` uses the effective price
      // (override applied), so the two can differ.
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
        "discount_id": order.discountId,
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
    int? discountId,
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
        "discount_id": discountId,
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
        'user: $orderingUserName, '
        'invoice: ${invoice?.reference ?? "-"})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Order && idPlacedOrder == other.idPlacedOrder;
  }

  @override
  int get hashCode => idPlacedOrder.hashCode;
}

/// ------------------------------------------------------------------
/// InvoiceSummary — the nested `invoice` object on an order payload
/// ------------------------------------------------------------------
///
/// Mirrors the invoice shape the orders endpoint returns:
///
/// ```json
/// "invoice": {
///   "invoice_status": "unpaid",
///   "grand_total": 558.38,
///   "invoice_issue_date": "2026-11-16",
///   "discount_amount": null,
///   "invoice_reference": "INV-44-20261116",
///   "invoice_due_date": "2026-12-16",
///   "additional_amount": null,
///   "invoice_id": 74,
///   "invoice_notes": "Order #44",
///   "subtotal_amount": null,
///   "created_at": "2026-11-16T18:44:39",
///   "updated_at": "2026-11-16T18:44:39",
///   "invoice_type": "invoice",
///   "tax_amount": 0
/// }
/// ```
///
/// Only the fields the UI uses are modelled. Extra fields on the wire
/// are ignored.
class InvoiceSummary {
  final int invoiceId;

  /// Lowercase status: paid | unpaid | partially_paid | overdue |
  /// refunded | canceled.
  final String status;

  /// Human reference (e.g. `INV-44-20261116`). Null when the server
  /// didn't set one.
  final String? reference;

  /// Lowercase type: invoice | receipt | proforma.
  final String type;

  final DateTime? issueDate;
  final DateTime? dueDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? notes;

  final Decimal grandTotal;
  final Decimal? subtotalAmount;
  final Decimal taxAmount;
  final Decimal? discountAmount;
  final Decimal? additionalAmount;

  InvoiceSummary({
    required this.invoiceId,
    required this.status,
    this.reference,
    required this.type,
    this.issueDate,
    this.dueDate,
    this.createdAt,
    this.updatedAt,
    this.notes,
    required this.grandTotal,
    this.subtotalAmount,
    required this.taxAmount,
    this.discountAmount,
    this.additionalAmount,
  });

  factory InvoiceSummary.fromJson(Map<String, dynamic> json) {
    return InvoiceSummary(
      invoiceId: (json['invoice_id'] as num?)?.toInt() ?? 0,
      status: ((json['invoice_status'] as String?) ?? 'unpaid').toLowerCase(),
      reference: json['invoice_reference'] as String?,
      type: ((json['invoice_type'] as String?) ?? 'invoice').toLowerCase(),
      issueDate: _parseDateOnly(json['invoice_issue_date']),
      dueDate: _parseDateOnly(json['invoice_due_date']),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      notes: json['invoice_notes'] as String?,
      grandTotal: _readDecimalOrZero(json['grand_total']),
      subtotalAmount: _readDecimal(json['subtotal_amount']),
      taxAmount: _readDecimalOrZero(json['tax_amount']),
      discountAmount: _readDecimal(json['discount_amount']),
      additionalAmount: _readDecimal(json['additional_amount']),
    );
  }

  bool get isPaid => status == 'paid';
  bool get isUnpaid => status == 'unpaid';
  bool get isOverdue => status == 'overdue';
  bool get isPartiallyPaid => status == 'partially_paid';
  bool get isRefunded => status == 'refunded';
  bool get isCanceled => status == 'canceled';

  /// True when there's still money owed on this invoice.
  bool get isOutstanding => isUnpaid || isPartiallyPaid || isOverdue;

  /// Days until [dueDate]. Negative when the invoice is already overdue.
  /// Null when [dueDate] is unknown.
  ///
  /// Compares calendar days (Y/M/D), not instants, so a due date of
  /// "today" yields `0` regardless of the time of day.
  int? get daysUntilDue {
    if (dueDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return due.difference(today).inDays;
  }

  Map<String, dynamic> toJson() {
    return {
      'invoice_id': invoiceId,
      'invoice_status': status,
      'invoice_reference': reference,
      'invoice_type': type,
      'invoice_issue_date': issueDate?.toIso8601String().split('T').first,
      'invoice_due_date': dueDate?.toIso8601String().split('T').first,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'invoice_notes': notes,
      'grand_total': _decimalToWire(grandTotal),
      'subtotal_amount': _decimalToWireOrNull(subtotalAmount),
      'tax_amount': _decimalToWire(taxAmount),
      'discount_amount': _decimalToWireOrNull(discountAmount),
      'additional_amount': _decimalToWireOrNull(additionalAmount),
    };
  }

  @override
  String toString() {
    return 'InvoiceSummary(id: $invoiceId, status: $status, '
        'total: DZD$grandTotal, '
        'due: ${dueDate?.toIso8601String().split("T").first ?? "-"})';
  }
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
  int? discountId,
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
    discountId: discountId,
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

/// Parses a date-only string (`YYYY-MM-DD`) without timezone shifting.
///
/// Date-only strings represent a calendar date, not a moment in time.
/// Calling `.toLocal()` on them shifts by the local timezone offset and
/// can roll the date back a day for users east of UTC. Kept as-parsed
/// so `"2026-12-16"` stays December 16 everywhere.
DateTime? _parseDateOnly(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  try {
    return DateTime.parse(v.toString());
  } catch (_) {
    return null;
  }
}

/// Parses a full ISO-8601 timestamp into local time. Null on failure.
DateTime? _parseDateTime(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  try {
    return DateTime.parse(v.toString()).toLocal();
  } catch (_) {
    return null;
  }
}
