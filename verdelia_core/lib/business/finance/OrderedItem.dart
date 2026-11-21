// lib/business/finance/OrderedItem.dart

import 'package:decimal/decimal.dart';
import 'package:verdelia_core/business/Delivery.dart';

class OrderedItem {
  final int idOrderedItem;
  final int? orderedProductId;
  final int orderedQuantity;

  /// VAT rate as a percentage (0–100), in [Decimal].
  final Decimal appliedVat;

  final int orderRef;

  /// Unit price, in [Decimal].
  final Decimal unitPrice;

  /// Discount percentage (0–100), in [Decimal]. Null when the line
  /// carried no discount.
  final Decimal? productDiscount;

  final int? orderedItemCartRef;
  final String? orderedItemDeliveryStatus;

  /// Delivery fee for this line, in [Decimal]. Null when the payload
  /// didn't carry one.
  final Decimal? orderedItemDeliveryFee;

  final int reservedQuantity;

  /// Server-provided line subtotal, in [Decimal]. When present, this is
  /// the authoritative total for the line; otherwise [totalPrice] is
  /// derived from [unitPrice] / [productDiscount] / [appliedVat].
  final Decimal? serverSubtotal;

  final OrderedProduct? orderedProduct;

  /// Nested delivery record attached to this line. Null when the line
  /// has no delivery (`ordered_item.delivery` was `null` in the
  /// payload). See [OrderItemDelivery].
  final OrderItemDelivery? delivery;

  Decimal get lineTotal => unitPrice * Decimal.fromInt(orderedQuantity);

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
    this.reservedQuantity = 0,
    this.serverSubtotal,
    this.orderedProduct,
    this.delivery,
  });

  factory OrderedItem.fromJson(Map<String, dynamic> json) {
    OrderedProduct? attachedProduct;
    final rawProduct = json['ordered_product'] ?? json['product'];
    if (rawProduct is Map) {
      try {
        attachedProduct = OrderedProduct.fromJson(
          Map<String, dynamic>.from(rawProduct),
        );
      } catch (_) {
        attachedProduct = null;
      }
    }

    OrderItemDelivery? attachedDelivery;
    final rawDelivery = json['delivery'];
    if (rawDelivery is Map) {
      try {
        attachedDelivery = OrderItemDelivery.fromJson(
          Map<String, dynamic>.from(rawDelivery),
        );
      } catch (e, st) {
        // ignore: avoid_print
        print('OrderedItem.fromJson: failed to parse delivery: $e\n$st');
        attachedDelivery = null;
      }
    }

    final readUnitPrice = _readDecimalOrZero(json['unit_price']);
    final readQuantity = (json['ordered_quantity'] as num?)?.toInt() ?? 0;
    final lineBase = readUnitPrice * Decimal.fromInt(readQuantity);

    // Two shapes:
    //   * `product_discount` — a percentage (write shape, and business-ops
    //     payload).
    //   * `discount_amount`  — an absolute currency amount (business-ops
    //     only). Convert it to a percentage so the rest of the model can
    //     use one convention.
    Decimal? productDiscountPercent;
    final rawProductDiscount = _readDecimal(json['product_discount']);
    if (rawProductDiscount != null) {
      productDiscountPercent = rawProductDiscount;
    } else {
      final discountAmount = _readDecimal(json['discount_amount']);
      if (discountAmount != null && lineBase > Decimal.zero) {
        productDiscountPercent =
            (discountAmount / lineBase).toDecimal(scaleOnInfinitePrecision: 2) *
                Decimal.fromInt(100);
      }
    }

    return OrderedItem(
      idOrderedItem: (json['id_ordered_item'] as num?)?.toInt() ?? 0,
      orderedProductId:
          (json['product_id'] ?? json['ordered_product_id'] as num?)?.toInt(),
      orderedQuantity: readQuantity,
      appliedVat: _readDecimalOrZero(json['vat_rate'] ?? json['applied_vat']),
      // `order_ref` is the wire name; `order_id` is what some older
      // payloads (and the previous version of this model) used.
      orderRef: (json['order_ref'] ?? json['order_id'] as num?)?.toInt() ?? 0,
      unitPrice: readUnitPrice,
      productDiscount: productDiscountPercent,
      orderedItemCartRef:
          (json['cart_id'] ?? json['ordered_item_cart_ref'] as num?)?.toInt(),
      orderedItemDeliveryStatus: (json['delivery_status'] ??
          json['ordered_item_delivery_status']) as String?,
      orderedItemDeliveryFee: _readDecimal(
        json['delivery_fee'] ?? json['ordered_item_delivery_fee'],
      ),
      reservedQuantity: (json['reserved_quantity'] as num?)?.toInt() ?? 0,
      serverSubtotal: _readDecimal(json['subtotal']),
      orderedProduct: attachedProduct,
      delivery: attachedDelivery,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_ordered_item': idOrderedItem,
      'product_id': orderedProductId,
      'ordered_quantity': orderedQuantity,
      'vat_rate': _decimalToWire(appliedVat),
      'order_ref': orderRef,
      'unit_price': _decimalToWire(unitPrice),
      'product_discount': _decimalToWireOrNull(productDiscount),
      'cart_id': orderedItemCartRef,
      'delivery_status': orderedItemDeliveryStatus,
      'delivery_fee': _decimalToWireOrNull(orderedItemDeliveryFee),
      'reserved_quantity': reservedQuantity,
      if (serverSubtotal != null) 'subtotal': _decimalToWire(serverSubtotal!),
      if (orderedProduct != null) 'ordered_product': orderedProduct!.toJson(),
      if (delivery != null) 'delivery': delivery!.toJson(),
    };
  }

  /// Body for `OrderedItem_API` — the shape the cart / order create
  /// endpoints expect inside `ordered_items[]`.
  ///
  /// Wire names per the OpenAPI schema:
  ///   * `id_ordered_item`
  ///   * `product_id`
  ///   * `order_ref`
  ///   * `product_discount` (percentage)
  ///   * `ordered_quantity`
  ///   * `unit_price`
  ///   * `vat_rate`
  ///
  /// `cart_id`, `delivery_status`, `delivery_fee`, `reserved_quantity`,
  /// the nested `product`, and the nested `delivery` are **not** on the
  /// write model — they're server-owned or derived, and the server
  /// silently drops them.
  Map<String, dynamic> toOrderedItemApiJson() {
    return {
      'id_ordered_item': idOrderedItem,
      'product_id': orderedProductId,
      'order_ref': orderRef,
      'product_discount': _decimalToWire(productDiscount ?? Decimal.zero),
      'ordered_quantity': orderedQuantity,
      'unit_price': _decimalToWire(unitPrice),
      'vat_rate': _decimalToWire(appliedVat),
    };
  }

  Map<String, dynamic> toJsonForService() {
    return {
      'id': idOrderedItem,
      'product_id': orderedProductId,
      'quantity': orderedQuantity,
      'vat_rate': _decimalToWire(appliedVat),
      'order_ref': orderRef,
      'unit_price': _decimalToWire(unitPrice),
      'discount': _decimalToWireOrNull(productDiscount),
      'delivery_status': orderedItemDeliveryStatus,
      'delivery_fee': _decimalToWireOrNull(orderedItemDeliveryFee),
      if (orderedProduct != null) 'product': orderedProduct!.toJsonForService(),
      if (delivery != null) 'delivery': delivery!.toJsonForService(),
    };
  }

  /// Gross line total before discount: `unitPrice × quantity`.
  Decimal get basePrice => unitPrice * Decimal.fromInt(orderedQuantity);

  /// Discount applied to this line, in currency units.
  Decimal get discountAmount {
    final percent = productDiscount ?? Decimal.zero;
    if (percent <= Decimal.zero) return Decimal.zero;
    return basePrice *
        (percent / Decimal.fromInt(100)).toDecimal(scaleOnInfinitePrecision: 2);
  }

  /// Net line total after discount, before VAT.
  Decimal get priceBeforeVat => basePrice - discountAmount;

  /// VAT amount derived from the net line total.
  Decimal get vatAmount =>
      priceBeforeVat *
      (appliedVat / Decimal.fromInt(100))
          .toDecimal(scaleOnInfinitePrecision: 2);

  /// Net line total after discount and VAT.
  ///
  /// When the server shipped a `subtotal`, that's authoritative (it
  /// already applied whatever discount / rounding the server decided).
  /// Otherwise derive it from the fields we have.
  Decimal get totalPrice {
    if (serverSubtotal != null) return serverSubtotal!;
    return priceBeforeVat + vatAmount;
  }

  bool get isDelivered =>
      orderedItemDeliveryStatus?.toLowerCase() == 'delivered';
  bool get isInTransit =>
      orderedItemDeliveryStatus?.toLowerCase() == 'in_transit';
  bool get isPendingDelivery =>
      orderedItemDeliveryStatus?.toLowerCase() == 'pending';

  bool get hasDeliveryFee =>
      (orderedItemDeliveryFee ?? Decimal.zero) > Decimal.zero;

  /// True when the payload carried a nested `delivery` record for this
  /// line. Prefer checking this over [isDelivered] when you need to
  /// render delivery metadata (provider, address, weight, …): the line
  /// can be `delivered` with a `null` delivery record (see order 32 in
  /// the sample payload), and vice versa.
  bool get hasDelivery => delivery != null;

  OrderedItem copyWith({
    int? idOrderedItem,
    int? orderedProductId,
    int? orderedQuantity,
    Decimal? appliedVat,
    int? orderRef,
    Decimal? unitPrice,
    Decimal? productDiscount,
    int? orderedItemCartRef,
    String? orderedItemDeliveryStatus,
    Decimal? orderedItemDeliveryFee,
    int? reservedQuantity,
    Decimal? serverSubtotal,
    OrderedProduct? orderedProduct,
    OrderItemDelivery? delivery,
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
      reservedQuantity: reservedQuantity ?? this.reservedQuantity,
      serverSubtotal: serverSubtotal ?? this.serverSubtotal,
      orderedProduct: orderedProduct ?? this.orderedProduct,
      delivery: delivery ?? this.delivery,
    );
  }

  @override
  String toString() {
    return 'OrderedItem(id: $idOrderedItem, product: ${orderedProduct?.productName}, quantity: $orderedQuantity, total: DZD$totalPrice, delivery: ${delivery?.idDelivery})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderedItem && other.idOrderedItem == idOrderedItem;
  }

  @override
  int get hashCode => idOrderedItem.hashCode;
}

// ============================================================================
// ORDER ITEM DELIVERY
// ============================================================================

/// Nested delivery record attached to a single [OrderedItem].
///
/// In the payload this is `ordered_item.delivery`. It can be `null`
/// (see order 32 / 30 in the sample), in which case
/// [OrderedItem.delivery] is `null` too.
///
/// ## Money
///
/// [deliveryFee] is [Decimal]. The `double` conversion happens only
/// inside [toJson], at the JSON boundary. All other fields are
/// identifiers / strings / nullable `num`s (weight, package count),
/// kept as-is.
class OrderItemDelivery {
  final int idDelivery;

  final int? deliverySourceId;
  final String? deliverySourceType;

  final int? deliveryBrokerId;
  final int? deliveryProviderId;
  final int? recipientPersonId;
  final int? recipientProviderId;
  final int? carryingUserId;

  final String? deliveryShippingMethod;

  /// Delivery fee, in [Decimal]. Zero when the payload carried `0`.
  final Decimal deliveryFee;

  /// Optional package count. Null when the server didn't send one.
  final int? deliveryPackageCount;

  /// Optional total weight. Kept as `double` — it's a measurement,
  /// not money, and the model has no arithmetic on it.
  final double? deliveryTotalWeight;

  final String? deliveryCargoDimensions;
  final String? deliveryGoodsDescription;
  final String? specialInstructions;

  /// Optional `hs_code` (customs harmonised-system code). String on the
  /// wire; kept verbatim.
  final String? hsCode;

  final String? deliveryStatus;

  final int? deliveryInvoiceRef;

  /// Address identifiers. Either can be null — the payload uses both
  /// `address_id` and `current_address_id`, and they can disagree.
  final int? addressId;
  final int? currentAddressId;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Full nested address record when the payload includes it. Null
  /// otherwise. See `DeliveryAddress`.
  final DeliveryAddress? address;

  OrderItemDelivery({
    required this.idDelivery,
    this.deliverySourceId,
    this.deliverySourceType,
    this.deliveryBrokerId,
    this.deliveryProviderId,
    this.recipientPersonId,
    this.recipientProviderId,
    this.carryingUserId,
    this.deliveryShippingMethod,
    Decimal? deliveryFee,
    this.deliveryPackageCount,
    this.deliveryTotalWeight,
    this.deliveryCargoDimensions,
    this.deliveryGoodsDescription,
    this.specialInstructions,
    this.hsCode,
    this.deliveryStatus,
    this.deliveryInvoiceRef,
    this.addressId,
    this.currentAddressId,
    this.createdAt,
    this.updatedAt,
    this.address,
  }) : deliveryFee = deliveryFee ?? Decimal.zero;

  factory OrderItemDelivery.fromJson(Map<String, dynamic> json) {
    DeliveryAddress? parsedAddress;
    final rawAddress = json['address'];
    if (rawAddress is Map) {
      try {
        parsedAddress = DeliveryAddress.fromJson(
          Map<String, dynamic>.from(rawAddress),
        );
      } catch (_) {
        parsedAddress = null;
      }
    }

    return OrderItemDelivery(
      idDelivery: (json['id_delivery'] as num?)?.toInt() ?? 0,
      deliverySourceId: (json['delivery_source_id'] as num?)?.toInt(),
      deliverySourceType: json['delivery_source_type'] as String?,
      deliveryBrokerId: (json['delivery_broker_id'] as num?)?.toInt(),
      deliveryProviderId: (json['delivery_provider_id'] as num?)?.toInt(),
      recipientPersonId: (json['recipient_person_id'] as num?)?.toInt(),
      recipientProviderId: (json['recipient_provider_id'] as num?)?.toInt(),
      carryingUserId: (json['carrying_user_id'] as num?)?.toInt(),
      deliveryShippingMethod: json['delivery_shipping_method'] as String?,
      deliveryFee: _readDecimalOrZero(json['delivery_fee']),
      deliveryPackageCount: (json['delivery_package_count'] as num?)?.toInt(),
      deliveryTotalWeight: (json['delivery_total_weight'] as num?)?.toDouble(),
      deliveryCargoDimensions: json['delivery_cargo_dimensions'] as String?,
      deliveryGoodsDescription: json['delivery_goods_description'] as String?,
      specialInstructions: json['special_instructions'] as String?,
      hsCode: json['hs_code'] as String?,
      deliveryStatus: json['delivery_status'] as String?,
      deliveryInvoiceRef: (json['delivery_invoice_ref'] as num?)?.toInt(),
      addressId: (json['address_id'] as num?)?.toInt(),
      currentAddressId: (json['current_address_id'] as num?)?.toInt(),
      createdAt: _parseNullableDateTime(json['created_at']),
      updatedAt: _parseNullableDateTime(json['updated_at']),
      address: parsedAddress,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_delivery': idDelivery,
      'delivery_source_id': deliverySourceId,
      'delivery_source_type': deliverySourceType,
      'delivery_broker_id': deliveryBrokerId,
      'delivery_provider_id': deliveryProviderId,
      'recipient_person_id': recipientPersonId,
      'recipient_provider_id': recipientProviderId,
      'carrying_user_id': carryingUserId,
      'delivery_shipping_method': deliveryShippingMethod,
      'delivery_fee': _decimalToWire(deliveryFee),
      'delivery_package_count': deliveryPackageCount,
      'delivery_total_weight': deliveryTotalWeight,
      'delivery_cargo_dimensions': deliveryCargoDimensions,
      'delivery_goods_description': deliveryGoodsDescription,
      'special_instructions': specialInstructions,
      'hs_code': hsCode,
      'delivery_status': deliveryStatus,
      'delivery_invoice_ref': deliveryInvoiceRef,
      'address_id': addressId,
      'current_address_id': currentAddressId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      if (address != null) 'address': address!.toJson(),
    };
  }

  Map<String, dynamic> toJsonForService() {
    return {
      'id': idDelivery,
      'source_id': deliverySourceId,
      'source_type': deliverySourceType,
      'broker_id': deliveryBrokerId,
      'provider_id': deliveryProviderId,
      'shipping_method': deliveryShippingMethod,
      'fee': _decimalToWire(deliveryFee),
      'package_count': deliveryPackageCount,
      'total_weight': deliveryTotalWeight,
      'cargo_dimensions': deliveryCargoDimensions,
      'goods_description': deliveryGoodsDescription,
      'special_instructions': specialInstructions,
      'hs_code': hsCode,
      'status': deliveryStatus,
      'invoice_ref': deliveryInvoiceRef,
      'address_id': addressId,
      'current_address_id': currentAddressId,
      if (address != null) 'address': address!.toJson(),
    };
  }

  bool get isConfirmed => deliveryStatus?.toLowerCase() == 'confirmed';
  bool get isPending => deliveryStatus?.toLowerCase() == 'pending';
  bool get isInTransit => deliveryStatus?.toLowerCase() == 'in_transit';
  bool get isDelivered => deliveryStatus?.toLowerCase() == 'delivered';

  bool get hasFee => deliveryFee > Decimal.zero;
  bool get hasWeight => deliveryTotalWeight != null && deliveryTotalWeight! > 0;
  bool get hasAddress => address != null || addressId != null;

  @override
  String toString() =>
      'OrderItemDelivery(id: $idDelivery, source: $deliverySourceType#$deliverySourceId, '
      'provider: $deliveryProviderId, status: $deliveryStatus, '
      'fee: $deliveryFee)';
}

// ============================================================================
// ORDERED PRODUCT
// ============================================================================

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

  /// Unit price, in [Decimal].
  final Decimal productPrice;

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

  factory OrderedProduct.fromJson(Map<String, dynamic> json) {
    return OrderedProduct(
      productName:
          (json['generic_name'] ?? json['product_name']) as String? ?? '',
      productProviderId:
          (json['provider_id'] ?? json['product_provider_id'] as num?)
                  ?.toInt() ??
              0,
      productQuantifier:
          (json['quantifier'] ?? json['product_quantifier']) as String?,
      productOwner:
          (json['user_id'] ?? json['product_owner'] as num?)?.toInt() ?? 0,
      productBrand: (json['brand'] ?? json['product_brand']) as String? ?? '',
      productCategoryId:
          (json['category_id'] ?? json['product_category_id'] as num?)
                  ?.toInt() ??
              0,
      idProduct: (json['id_product'] as num?)?.toInt() ?? 0,
      lastUpdated: _parseDateTime(json['last_updated']),
      productBarcode:
          (json['barcode'] ?? json['product_barcode']) as String? ?? '',
      created: _parseDateTime(json['created']),
      productDescription: json['product_description'] as String? ?? '',
      productPrice: _readDecimalOrZero(
        json['unit_price'] ?? json['product_price'],
      ),
      productQuantity:
          (json['available_quantity'] ?? json['product_quantity'] as num?)
                  ?.toInt() ??
              0,
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

  Map<String, dynamic> toJson() {
    return {
      'generic_name': productName,
      'provider_id': productProviderId,
      'quantifier': productQuantifier,
      'user_id': productOwner,
      'brand': productBrand,
      'category_id': productCategoryId,
      'id_product': idProduct,
      'last_updated': lastUpdated.toIso8601String(),
      'barcode': productBarcode,
      'created': created.toIso8601String(),
      'product_description': productDescription,
      'unit_price': _decimalToWire(productPrice),
      'available_quantity': productQuantity,
    };
  }

  Map<String, dynamic> toJsonForService() {
    return {
      'id': idProduct,
      'name': productName,
      'brand': productBrand,
      'price': _decimalToWire(productPrice),
      'quantity_available': productQuantity,
      'description': productDescription,
      'barcode': productBarcode,
      'category_id': productCategoryId,
      'provider_id': productProviderId,
    };
  }

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
    Decimal? productPrice,
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
/// * anything else → `null`
///
/// Rejects non-finite `double`s so a malformed payload can't poison
/// downstream arithmetic.
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

/// Parses a nullable ISO-8601 string into a local [DateTime].
/// Returns `null` for null / empty / unparseable input — unlike
/// [OrderedProduct._parseDateTime], which falls back to `DateTime.now()`.
DateTime? _parseNullableDateTime(dynamic raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  final str = raw.toString();
  if (str.isEmpty) return null;
  try {
    return DateTime.parse(str).toLocal();
  } catch (_) {
    return null;
  }
}
