import 'dart:convert';
import 'dart:developer';

import 'package:verdelia_core/app/AppUser.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:verdelia_core/business/finance/Cart.dart';

class Order {
  final int idPlacedOrder;
  final double? orderDiscount;
  final double totalPrice;
  final int? orderingUserId;
  final int? placedOrderLocationRef;
  final int? placedOrderStateRef;

  /// Raw state string from the API (`"PENDING"`, `"PROCESSING"`, ...).
  /// The database only stores the ref, but the payload sends both.
  final String? placedOrderStateRaw;

  final DateTime placedOrderLastMod;
  final int? placedOrderInvoiceRef;
  final int? placedOrderReceiptRef;
  final DateTime placedOrderCreation;
  List<OrderedItem>? items;

  /// Fully-parsed ordering user (when the payload embeds it).
  AppUser? orderingUser;

  // Computed properties (not from database)
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

  // ============================================================
  // FACTORY
  // ============================================================

  factory Order.fromJson(Map<String, dynamic> json) {
    // ── Items: payload uses `ordered_item`, list endpoints use `items`.
    final rawItems = json['ordered_item'] ?? json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map<String, dynamic>>()
            .map(OrderedItem.fromJson)
            .toList()
        : null;

    // ── State: prefer the string form, fall back to ref.
    final stateRef = json['placed_order_state_ref'] as int?;
    final stateStr = json['placed_order_state'] as String?;

    // ── Ordering user: parse the embedded AppUser if present.
    AppUser? orderingUser;
    final rawUser = json['ordering_user'] ?? json['app_user'];
    if (rawUser is Map<String, dynamic>) {
      try {
        orderingUser = AppUser.fromJson(rawUser);
      } catch (e) {
        log('Order.fromJson: failed to parse ordering_user: $e');
      }
    }

    // ── Customer name: prefer the explicit field, else the user.
    final explicitName = json['customer_name'] as String?;
    final derivedName = orderingUser?.displayName;

    return Order(
      idPlacedOrder: json['id_placed_order'] as int? ?? 0,
      orderDiscount: (json['order_discount'] as num?)?.toDouble(),
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      orderingUserId: json['ordering_user_id'] as int?,
      placedOrderLocationRef: json['placed_order_location_ref'] as int?,
      placedOrderStateRef: stateRef,
      placedOrderStateRaw: stateStr,
      placedOrderLastMod: _parseDateTime(json['placed_order_last_mod']),
      placedOrderInvoiceRef: json['placed_order_invoice'] as int? ??
          json['placed_order_invoice_ref'] as int?,
      placedOrderReceiptRef: json['placed_order_receipt_ref'] as int?,
      placedOrderCreation: _parseDateTime(json['placed_order_creation']),
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

  // ============================================================
  // STATUS
  // ============================================================

  /// Normalized status string — always lowercase, always one of:
  /// pending | processing | shipped | delivered | cancelled | refunded |
  /// unknown
  String get status {
    // Prefer the string the API sent — it's authoritative.
    if (placedOrderStateRaw != null && placedOrderStateRaw!.isNotEmpty) {
      return placedOrderStateRaw!.toLowerCase();
    }
    // Fall back to the ref if the string is missing (older endpoints).
    return _statusFromRef(placedOrderStateRef);
  }

  /// The raw string (uppercase as sent by the API). Useful for matches.
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

  // ============================================================
  // ORDERING USER HELPERS
  // ============================================================

  /// The display name for whoever placed this order.
  String get orderingUserName {
    if (orderingUser != null) return orderingUser!.displayName;
    if (customerName != null && customerName!.isNotEmpty) return customerName!;
    if (orderingUserId != null) return 'User #$orderingUserId';
    return 'Unknown';
  }

  /// Avatar URL for the ordering user, if available.
  String? get orderingUserImageUrl => orderingUser?.appUserImageUrl;

  /// Two-letter initials for the ordering user.
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

  /// Whether we have enough to render an avatar.
  bool get hasOrderingUser =>
      orderingUser != null || (customerName?.isNotEmpty ?? false);

  // ============================================================
  // JSON SERIALIZATION
  // ============================================================

  Map<String, dynamic> toSummaryJson() {
    return {
      'id_placed_order': idPlacedOrder,
      'order_discount': orderDiscount,
      'total_price': totalPrice,
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
      "order_discount": orderDiscount,
      "total_price": totalPrice,
      "ordering_user_id": orderingUserId,
      "placed_order_location_ref": placedOrderLocationRef,
      "placed_order_state_ref": placedOrderStateRef ?? 1,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'ordered_items': items?.map((item) => item.toJson()).toList() ?? [],
      'submitted_order': {
        'id_placed_order': idPlacedOrder,
        'ordered_timestamp': placedOrderCreation.toIso8601String(),
        'order_discount': orderDiscount,
        'placed_order_last_mod': placedOrderLastMod.toIso8601String(),
        'payment_status': paymentStatus,
        'payment_ref': paymentRef,
        'placed_order_state': statusRaw,
        'payment_method': paymentMethod,
        'ordering_user_id': orderingUserId,
        'total_price': totalPrice,
        'placed_order_location_ref': placedOrderLocationRef,
        'placed_order_state_ref': placedOrderStateRef,
        'placed_order_invoice_ref': placedOrderInvoiceRef,
        'placed_order_receipt_ref': placedOrderReceiptRef,
        'customer_name': customerName,
      },
    };
  }

  Map<String, dynamic> toJsonForService() {
    return {
      'id_order': idPlacedOrder,
      'total_amount': totalPrice,
      'order_discount': orderDiscount,
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

  // ============================================================
  // COPY WITH
  // ============================================================

  Order copyWith({
    int? idPlacedOrder,
    double? orderDiscount,
    double? totalPrice,
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

  // ============================================================
  // BOOLEAN HELPERS
  // ============================================================

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

  double get netPrice => totalPrice - (orderDiscount ?? 0.0);

  bool hasItems() => items != null && items!.isNotEmpty;

  int get itemCount =>
      items?.fold(0, (sum, item) => sum ?? 0 + item.orderedQuantity) ?? 0;

  int get totalQuantity =>
      items?.fold(0, (total, item) => total ?? 0 + item!.orderedQuantity) ?? 0;

  double get finalTotal => totalPrice - (orderDiscount ?? 0.0);

  // ============================================================
  // STATIC BUILDERS
  // ============================================================

  static Map<String, dynamic> buildSingleOrderData({
    required Product product,
    required int quantity,
    required int orderingUserId,
    double discount = 0.0,
    double taxRate = 0.0,
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

    final unitPrice = product.product_price ?? 0.0;
    final totalPrice = unitPrice * quantity;

    return {
      "ordered_items": [
        {
          "id_ordered_item": 0,
          "ordered_product_id": product.id_product!,
          "order_ref": 0,
          "product_discount": discount.clamp(0.0, unitPrice * quantity),
          "ordered_quantity": quantity,
          "unit_price": unitPrice,
          "applied_vat": taxRate.clamp(0.0, 1.0),
          "ordered_item_cart_ref": null,
          "ordered_item_delivery_status": null,
          "ordered_item_delivery_fee": null,
        },
      ],
      "submitted_order": {
        "id_placed_order": 0,
        "ordered_timestamp": DateTime.now().toIso8601String(),
        "order_discount": discount.clamp(0.0, totalPrice),
        "total_price": totalPrice,
        "ordering_user_id": orderingUserId,
        "placed_order_location_ref": locationRef,
        "placed_order_state_ref":
            orderState != null ? _stateToRef(orderState) : 1,
        "placed_order_state": orderState ?? 'PENDING',
        "placed_order_last_mod": DateTime.now().toIso8601String(),
        "payment_status": paymentStatus ?? 'pending',
        "payment_method": paymentMethod ?? 'cash',
        "payment_ref": paymentRef ?? '',
        "placed_order_invoice_ref": null,
        "placed_order_receipt_ref": null,
      },
    };
  }

  static Map<String, dynamic> buildOrderData(
    List<CartItem> cartItems,
    int orderingUserId, {
    double? orderDiscount,
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
    double totalPrice = 0.0;

    for (final item in cartItems) {
      final product = item.product;
      if (product?.id_product == null) {
        throw ArgumentError('Product ID cannot be null for order item');
      }

      final catalogPrice = item.catalogUnitPrice ?? 0.0;
      final effectivePrice = item.unitPrice ?? catalogPrice;
      totalPrice += effectivePrice * item.quantity;

      orderedItems.add({
        "id_ordered_item": 0,
        "ordered_product_id": product!.id_product!,
        "order_ref": 0,
        "ordered_quantity": item.quantity,
        "unit_price": catalogPrice,
        "product_discount": item.lineDiscount,
      });
    }

    final finalDiscount = orderDiscount?.clamp(0.0, totalPrice) ?? 0.0;

    return {
      "ordered_items": orderedItems,
      "submitted_order": {
        "id_placed_order": 0,
        "ordered_timestamp": DateTime.now().toIso8601String(),
        "order_discount": finalDiscount,
        "total_price": totalPrice,
        "ordering_user_id": orderingUserId,
        "placed_order_location_ref": locationRef,
        "placed_order_state_ref":
            orderState != null ? _stateToRef(orderState) : 1,
        "placed_order_state": orderState ?? 'PENDING',
        "placed_order_last_mod": DateTime.now().toIso8601String(),
        "payment_status": paymentStatus ?? 'PENDING',
        "payment_method": paymentMethod ?? 'cash',
        "payment_ref": paymentRef ?? '',
        "placed_order_invoice_ref": null,
        "placed_order_receipt_ref": null,
      },
    };
  }

  static Map<String, dynamic> buildOrderDataFromOrder(Order order) {
    return {
      "ordered_items": order.items?.map((item) => item.toJson()).toList() ?? [],
      "submitted_order": {
        "id_placed_order": order.idPlacedOrder,
        "ordered_timestamp": order.placedOrderCreation.toIso8601String(),
        "order_discount": order.orderDiscount ?? 0.0,
        "total_price": order.totalPrice,
        "ordering_user_id": order.orderingUserId,
        "placed_order_location_ref": order.placedOrderLocationRef,
        "placed_order_state_ref": order.placedOrderStateRef,
        "placed_order_state": order.statusRaw,
        "placed_order_last_mod": order.placedOrderLastMod.toIso8601String(),
        "payment_status": order.paymentStatus,
        "payment_method": order.paymentMethod,
        "payment_ref": order.paymentRef,
        "placed_order_invoice_ref": order.placedOrderInvoiceRef,
        "placed_order_receipt_ref": order.placedOrderReceiptRef,
        "customer_name": order.customerName,
      },
    };
  }

  static Map<String, dynamic> buildOrderUpdateData({
    required int orderId,
    String? orderState,
    double? orderDiscount,
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
        "placed_order_state_ref":
            orderState != null ? _stateToRef(orderState) : null,
        "order_discount": orderDiscount,
        "payment_status": paymentStatus,
        "payment_method": paymentMethod,
        "payment_ref": paymentRef,
        "placed_order_location_ref": locationRef,
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

class OrderedItem {
  final int idOrderedItem;
  final int? orderedProductId;
  final int orderedQuantity;
  final double appliedVat;
  final int orderRef;
  final double unitPrice;
  final double? productDiscount;
  final int? orderedItemCartRef;
  final String? orderedItemDeliveryStatus;
  final double? orderedItemDeliveryFee;
  final OrderedProduct? orderedProduct;

  OrderedItem({
    required this.idOrderedItem,
    this.orderedProductId,
    required this.orderedQuantity,
    required this.appliedVat,
    required this.orderRef,
    required this.unitPrice,
    this.productDiscount,
    this.orderedItemCartRef,
    this.orderedItemDeliveryStatus,
    this.orderedItemDeliveryFee,
    required this.orderedProduct,
  });

  // Factory constructor to create OrderedItem from JSON
  factory OrderedItem.fromJson(Map<String, dynamic> json) {
    OrderedProduct? attachedProduct;
    if (json['ordered_product'] != null) {
      attachedProduct = OrderedProduct.fromJson(
          json['ordered_product'] as Map<String, dynamic>);
    }

    return OrderedItem(
      idOrderedItem: json['id_ordered_item'] as int? ?? 0,
      orderedProductId: json['ordered_product_id'] as int?,
      orderedQuantity: json['ordered_quantity'] as int? ?? 0,
      appliedVat: (json['applied_vat'] as num?)?.toDouble() ?? 0.0,
      orderRef: json['order_ref'] as int? ?? 0,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      productDiscount: (json['product_discount'] as num?)?.toDouble(),
      orderedItemCartRef: json['ordered_item_cart_ref'] as int?,
      orderedItemDeliveryStatus:
          json['ordered_item_delivery_status'] as String?,
      orderedItemDeliveryFee:
          (json['ordered_item_delivery_fee'] as num?)?.toDouble(),
      orderedProduct: attachedProduct,
    );
  }

  // Convert OrderedItem to JSON matching database schema
  Map<String, dynamic> toJson() {
    return {
      'id_ordered_item': idOrderedItem,
      'ordered_product_id': orderedProductId,
      'ordered_quantity': orderedQuantity,
      'applied_vat': appliedVat,
      'order_ref': orderRef,
      'unit_price': unitPrice,
      'product_discount': productDiscount,
      'ordered_item_cart_ref': orderedItemCartRef,
      'ordered_item_delivery_status': orderedItemDeliveryStatus,
      'ordered_item_delivery_fee': orderedItemDeliveryFee,
      if (orderedProduct != null) 'ordered_product': orderedProduct!.toJson(),
    };
  }

  // For service calls
  Map<String, dynamic> toJsonForService() {
    return {
      'id': idOrderedItem,
      'product_id': orderedProductId,
      'quantity': orderedQuantity,
      'vat_rate': appliedVat,
      'order_id': orderRef,
      'unit_price': unitPrice,
      'discount': productDiscount,
      'delivery_status': orderedItemDeliveryStatus,
      'delivery_fee': orderedItemDeliveryFee,
      if (orderedProduct != null) 'product': orderedProduct!.toJsonForService(),
    };
  }

  // Helper method to calculate total price for this item
  double get totalPrice {
    final basePrice = unitPrice * orderedQuantity;
    final discount = productDiscount ?? 0.0;
    final priceAfterDiscount = basePrice - discount;
    final vatAmount =
        priceAfterDiscount * (appliedVat / 100); // Assuming VAT is percentage
    return priceAfterDiscount + vatAmount;
  }

  // Helper method to calculate VAT amount for this item
  double get vatAmount {
    final basePrice = unitPrice * orderedQuantity;
    final discount = productDiscount ?? 0.0;
    final priceAfterDiscount = basePrice - discount;
    return priceAfterDiscount * (appliedVat / 100);
  }

  // Helper method to calculate price before VAT
  double get priceBeforeVat {
    final basePrice = unitPrice * orderedQuantity;
    final discount = productDiscount ?? 0.0;
    return basePrice - discount;
  }

  // Delivery status helpers
  bool get isDelivered =>
      orderedItemDeliveryStatus?.toLowerCase() == 'delivered';
  bool get isInTransit =>
      orderedItemDeliveryStatus?.toLowerCase() == 'in_transit';
  bool get isPendingDelivery =>
      orderedItemDeliveryStatus?.toLowerCase() == 'pending';

  // Check if item has delivery fee
  bool get hasDeliveryFee => (orderedItemDeliveryFee ?? 0) > 0;

  // Copy with method for immutability
  OrderedItem copyWith({
    int? idOrderedItem,
    int? orderedProductId,
    int? orderedQuantity,
    double? appliedVat,
    int? orderRef,
    double? unitPrice,
    double? productDiscount,
    int? orderedItemCartRef,
    String? orderedItemDeliveryStatus,
    double? orderedItemDeliveryFee,
    OrderedProduct? orderedProduct,
  }) {
    return OrderedItem(
      idOrderedItem: idOrderedItem ?? this.idOrderedItem,
      orderedProductId: orderedProductId ?? this.orderedProductId,
      orderedQuantity: orderedQuantity ?? this.orderedQuantity,
      appliedVat: appliedVat ?? this.appliedVat,
      orderRef: orderRef ?? this.orderRef,
      unitPrice: unitPrice ?? this.unitPrice,
      productDiscount: productDiscount ?? this.productDiscount,
      orderedItemCartRef: orderedItemCartRef ?? this.orderedItemCartRef,
      orderedItemDeliveryStatus:
          orderedItemDeliveryStatus ?? this.orderedItemDeliveryStatus,
      orderedItemDeliveryFee:
          orderedItemDeliveryFee ?? this.orderedItemDeliveryFee,
      orderedProduct: orderedProduct ?? this.orderedProduct,
    );
  }

  @override
  String toString() {
    return 'OrderedItem(id: $idOrderedItem, product: ${orderedProduct?.productName}, quantity: $orderedQuantity, total: DZD${totalPrice.toStringAsFixed(2)})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderedItem && other.idOrderedItem == idOrderedItem;
  }

  @override
  int get hashCode => idOrderedItem.hashCode;
}

class OrderedProduct {
  final String productName;
  final int productProviderId;
  final String? productQuantifier;
  final int productOwner;
  final String productBrand;
  final int productCategoryId;
  final int idProduct;
  final DateTime lastUpdated;
  final String productBarcode;
  final DateTime created;
  final String productDescription;
  final double productPrice;
  final int productQuantity;

  OrderedProduct({
    required this.productName,
    required this.productProviderId,
    this.productQuantifier,
    required this.productOwner,
    required this.productBrand,
    required this.productCategoryId,
    required this.idProduct,
    required this.lastUpdated,
    required this.productBarcode,
    required this.created,
    required this.productDescription,
    required this.productPrice,
    required this.productQuantity,
  });

  // Factory constructor to create OrderedProduct from JSON
  factory OrderedProduct.fromJson(Map<String, dynamic> json) {
    return OrderedProduct(
      productName: json['product_name'] as String? ?? '',
      productProviderId: json['product_provider_id'] as int? ?? 0,
      productQuantifier: json['product_quantifier'] as String?,
      productOwner: json['product_owner'] as int? ?? 0,
      productBrand: json['product_brand'] as String? ?? '',
      productCategoryId: json['product_category_id'] as int? ?? 0,
      idProduct: json['id_product'] as int? ?? 0,
      lastUpdated: _parseDateTime(json['last_updated']),
      productBarcode: json['product_barcode'] as String? ?? '',
      created: _parseDateTime(json['created']),
      productDescription: json['product_description'] as String? ?? '',
      productPrice: (json['product_price'] as num?)?.toDouble() ?? 0.0,
      productQuantity: json['product_quantity'] as int? ?? 0,
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

  // Convert OrderedProduct to JSON
  Map<String, dynamic> toJson() {
    return {
      'product_name': productName,
      'product_provider_id': productProviderId,
      'product_quantifier': productQuantifier,
      'product_owner': productOwner,
      'product_brand': productBrand,
      'product_category_id': productCategoryId,
      'id_product': idProduct,
      'last_updated': lastUpdated.toIso8601String(),
      'product_barcode': productBarcode,
      'created': created.toIso8601String(),
      'product_description': productDescription,
      'product_price': productPrice,
      'product_quantity': productQuantity,
    };
  }

  // For service calls
  Map<String, dynamic> toJsonForService() {
    return {
      'id': idProduct,
      'name': productName,
      'brand': productBrand,
      'price': productPrice,
      'quantity_available': productQuantity,
      'description': productDescription,
      'barcode': productBarcode,
      'category_id': productCategoryId,
      'provider_id': productProviderId,
    };
  }

  // Copy with method for immutability
  OrderedProduct copyWith({
    String? productName,
    int? productProviderId,
    String? productQuantifier,
    int? productOwner,
    String? productBrand,
    int? productCategoryId,
    int? idProduct,
    DateTime? lastUpdated,
    String? productBarcode,
    DateTime? created,
    String? productDescription,
    double? productPrice,
    int? productQuantity,
  }) {
    return OrderedProduct(
      productName: productName ?? this.productName,
      productProviderId: productProviderId ?? this.productProviderId,
      productQuantifier: productQuantifier ?? this.productQuantifier,
      productOwner: productOwner ?? this.productOwner,
      productBrand: productBrand ?? this.productBrand,
      productCategoryId: productCategoryId ?? this.productCategoryId,
      idProduct: idProduct ?? this.idProduct,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      productBarcode: productBarcode ?? this.productBarcode,
      created: created ?? this.created,
      productDescription: productDescription ?? this.productDescription,
      productPrice: productPrice ?? this.productPrice,
      productQuantity: productQuantity ?? this.productQuantity,
    );
  }

  // Helper methods
  bool get isInStock => productQuantity > 0;
  bool get isOutOfStock => productQuantity <= 0;

  String get displayPrice => 'DZD ${productPrice.toStringAsFixed(2)}';

  @override
  String toString() {
    return 'OrderedProduct(id: $idProduct, name: $productName, price: DZD$productPrice)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderedProduct && other.idProduct == idProduct;
  }

  @override
  int get hashCode => idProduct.hashCode;
}

// Helper function to parse a list of OrderedItems from JSON
List<OrderedItem> parseOrderedItems(List<dynamic> jsonList) {
  return jsonList
      .map((item) => OrderedItem.fromJson(item as Map<String, dynamic>))
      .toList();
}

// Helper function to convert a list of OrderedItems to JSON
List<Map<String, dynamic>> orderedItemsToJson(List<OrderedItem> items) {
  return items.map((item) => item.toJson()).toList();
}

// Helper function to create a new order from cart items
Order createOrderFromCart({
  required int userId,
  required List<CartItem> cartItems,
  double? orderDiscount,
  int? locationId,
  int? invoiceRef,
  int? receiptRef,
  String? paymentStatus,
  String? paymentMethod,
  String? paymentRef,
}) {
  final totalPrice =
      cartItems.fold(0.0, (sum, item) => sum + (item.totalPrice ?? 0));

  final orderedItems = cartItems.map((cartItem) {
    return OrderedItem(
      idOrderedItem: 0, // Will be assigned by database
      orderedProductId: cartItem.product?.id_product,
      orderedQuantity: cartItem.quantity,
      appliedVat: 0.0,
      orderRef: 0, // Will be updated after order creation
      unitPrice: cartItem.unitPrice ?? 0.0,
      productDiscount: 0.0,
      orderedItemCartRef: 0,
      orderedItemDeliveryStatus: null,
      orderedItemDeliveryFee: null,
      orderedProduct: cartItem.product != null
          ? OrderedProduct(
              productName: cartItem.product!.product_name ?? "",
              productProviderId: cartItem.product!.product_provider_id ?? 0,
              productQuantifier: cartItem.product!.product_quantifier,
              productOwner: cartItem.product!.product_owner_id ?? 0,
              productBrand: cartItem.product!.product_brand ?? '',
              productCategoryId: cartItem.product!.product_category_id ?? 0,
              idProduct: cartItem.product!.id_product ?? 0,
              lastUpdated: DateTime.now(),
              productBarcode: cartItem.product!.product_barcode ?? '',
              created: DateTime.now(),
              productDescription: cartItem.product!.product_description ?? '',
              productPrice: cartItem.product!.product_price ?? 0.0,
              productQuantity: cartItem.product!.product_quantity ?? 0,
            )
          : null,
    );
  }).toList();

  return Order(
    idPlacedOrder: 0, // Will be assigned by database
    orderDiscount: orderDiscount,
    totalPrice: totalPrice,
    orderingUserId: userId,
    placedOrderLocationRef: locationId,
    placedOrderStateRef: 1, // Default to pending
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
