// lib/models/business_operation.dart

import 'package:decimal/decimal.dart';

import 'package:verdelia_core/business/finance/OrderedItem.dart';

// ---------------------------------------------------------------------------
// Envelope: what the API returns
// ---------------------------------------------------------------------------

class BusinessOperationsResponse {
  final List<BusinessOperation> operations;
  final BusinessOperationsStatsData? stats;
  final BusinessOperationsPagination pagination;
  final BusinessOperationsWindow window;

  const BusinessOperationsResponse({
    required this.operations,
    required this.stats,
    required this.pagination,
    required this.window,
  });

  factory BusinessOperationsResponse.fromJson(Map<String, dynamic> json) {
    final operations = _parseOperations(json['operations']);
    final rawStats = _parseStatsOrNull(json['stats']);
    final stats = _maybeRecomputeStats(rawStats, operations);

    return BusinessOperationsResponse(
      operations: operations,
      stats: stats,
      pagination:
          BusinessOperationsPagination.fromJson(_asMap(json['pagination'])),
      window: BusinessOperationsWindow.fromJson(_asMap(json['window'])),
    );
  }

  Map<String, dynamic> toJson() => {
        'operations': operations.map((e) => e.toJson()).toList(),
        if (stats != null) 'stats': stats!.toJson(),
        'pagination': pagination.toJson(),
        'window': window.toJson(),
      };

  bool get isEmpty => operations.isEmpty;
  bool get isNotEmpty => operations.isNotEmpty;

  @override
  String toString() => 'BusinessOperationsResponse(ops: ${operations.length}, '
      'stats: ${stats != null}, '
      'page: ${pagination.offset}/${pagination.totalInWindow})';
}

BusinessOperationsStatsData? _maybeRecomputeStats(
  BusinessOperationsStatsData? stats,
  List<BusinessOperation> operations,
) {
  if (stats == null) return null;
  if (operations.isEmpty) return stats;

  final t = stats.totals;
  final backendZeroed = t.productSubtotal == Decimal.zero &&
      t.serviceSubtotal == Decimal.zero &&
      t.grossSubtotal == Decimal.zero &&
      t.grandTotal == Decimal.zero &&
      t.taxAmount == Decimal.zero;

  if (!backendZeroed) return stats;
  final anyLines = operations.any((o) => o.hasLines);
  if (!anyLines) return stats;

  final recomputed = _recomputeTotals(operations);
  final invoice = recomputed.invoiceTotal;
  final paid = recomputed.paidAmount;

  // `.toDecimal(scaleOnInfinitePrecision: 2)` on every division: `Decimal / Decimal` returns a
  // `Rational`, which can't be assigned to a `Decimal`. Each ratio is
  // clamped to `[0, 1]` with a manual three-branch because `Decimal`
  // has no `.clamp`.
  Decimal? collectionRate = stats.ratios.collectionRate;
  if (invoice > Decimal.zero) {
    final raw = (paid / invoice).toDecimal(scaleOnInfinitePrecision: 2);
    if (raw < Decimal.zero) {
      collectionRate = Decimal.zero;
    } else if (raw > Decimal.one) {
      collectionRate = Decimal.one;
    } else {
      collectionRate = raw;
    }
  }

  Decimal? discountRate = stats.ratios.discountRate;
  if (recomputed.grossSubtotal > Decimal.zero) {
    discountRate = (recomputed.discountAmount / recomputed.grossSubtotal)
        .toDecimal(scaleOnInfinitePrecision: 2);
  }

  final averageTicket =
      (recomputed.invoiceTotal / Decimal.fromInt(operations.length))
          .toDecimal(scaleOnInfinitePrecision: 2);

  Decimal? roi = stats.ratios.overallRoi;
  if (recomputed.totalCost > Decimal.zero) {
    roi = (recomputed.marginAmount / recomputed.totalCost)
        .toDecimal(scaleOnInfinitePrecision: 2);
  }

  return BusinessOperationsStatsData(
    totals: recomputed,
    ratios: BusinessOperationsRatios(
      overallRoi: roi,
      averageTicket: averageTicket,
      collectionRate: collectionRate,
      discountRate: discountRate,
    ),
    counts: stats.counts,
    byStatus: stats.byStatus,
    bySource: stats.bySource,
    bySupplier: stats.bySupplier,
    byClient: stats.byClient,
    byDay: stats.byDay,
  );
}

BusinessOperationsTotals _recomputeTotals(List<BusinessOperation> ops) {
  Decimal productSubtotal = Decimal.zero;
  Decimal serviceSubtotal = Decimal.zero;
  Decimal grossSubtotal = Decimal.zero;
  Decimal discount = Decimal.zero;
  Decimal tax = Decimal.zero;
  Decimal delivery = Decimal.zero;
  Decimal grandTotal = Decimal.zero;
  Decimal invoiceTotal = Decimal.zero;
  Decimal paid = Decimal.zero;
  Decimal due = Decimal.zero;
  Decimal productCost = Decimal.zero;
  Decimal consumable = Decimal.zero;
  Decimal nonConsumable = Decimal.zero;
  Decimal labor = Decimal.zero;
  Decimal deliveryCost = Decimal.zero;
  Decimal totalCost = Decimal.zero;
  Decimal margin = Decimal.zero;
  int itemCount = 0;
  int serviceCount = 0;

  for (final o in ops) {
    productSubtotal += o.productSubtotal;
    serviceSubtotal += o.serviceSubtotal;
    grossSubtotal += o.grossSubtotal;
    discount += o.discountAmount;
    tax += o.taxAmount;
    delivery += o.deliveryRevenue;
    grandTotal += o.grandTotal;
    invoiceTotal += o.invoiceTotal;
    paid += o.paidAmount;
    due += o.dueAmount;
    productCost += o.productCost;
    consumable += o.consumableServiceCost;
    nonConsumable += o.nonConsumableServiceCost;
    labor += o.laborCost;
    deliveryCost += o.deliveryCost;
    totalCost += o.totalCost;
    margin += o.marginAmount;
    itemCount += o.items.length;
    serviceCount += o.services.length;
  }

  return BusinessOperationsTotals(
    productSubtotal: productSubtotal,
    serviceSubtotal: serviceSubtotal,
    grossSubtotal: grossSubtotal,
    discountAmount: discount,
    taxAmount: tax,
    deliveryRevenue: delivery,
    grandTotal: grandTotal,
    invoiceTotal: invoiceTotal,
    paidAmount: paid,
    dueAmount: due,
    productCost: productCost,
    consumableServiceCost: consumable,
    nonConsumableServiceCost: nonConsumable,
    laborCost: labor,
    deliveryCost: deliveryCost,
    totalCost: totalCost,
    marginAmount: margin,
    itemCount: itemCount,
    serviceCount: serviceCount,
  );
}

// ---------------------------------------------------------------------------
// One line item
// ---------------------------------------------------------------------------

/// One product line on an operation.
///
/// The nested `product` snapshot is parsed into the shared
/// [OrderedProduct] type so the UI binds to typed fields instead of a
/// raw map.
///
/// ## Money
///
/// [unitPrice], [appliedVat], [discountAmount], [deliveryFee] and every
/// derived getter ([lineSubtotal], [lineNet], [lineVat], [lineTotal])
/// are [Decimal]. The `double` conversion happens only inside [toJson],
/// at the JSON boundary.
class BusinessOperationItem {
  final int idOrderedItem;
  final int? orderedProductId;
  final int orderedQuantity;
  final Decimal discountAmount;

  /// Unit price, in [Decimal].
  final Decimal unitPrice;

  /// VAT as a **percent** (19 = 19%), in [Decimal].
  final Decimal appliedVat;

  /// Absolute discount for this line, in currency units, in [Decimal].

  final int reservedQuantity;

  /// Delivery fee for this line, in [Decimal].
  final Decimal deliveryFee;

  final String? deliveryStatus;
  final DateTime? placedOrderCreation;
  final DateTime? lastModified;
  final int? cartRef;
  final int? orderRef;

  /// Typed nested product snapshot. Null when the wire only carried
  /// `product_id`. See [OrderedProduct].
  final OrderedProduct? product;

  BusinessOperationItem({
    required this.idOrderedItem,
    required this.orderedProductId,
    required this.orderedQuantity,
    required this.unitPrice,
    required this.appliedVat,
    Decimal? discountAmount,
    required this.reservedQuantity,
    required this.deliveryFee,
    this.deliveryStatus,
    this.placedOrderCreation,
    this.lastModified,
    this.cartRef,
    this.orderRef,
    this.product,
  }) : discountAmount = discountAmount ?? Decimal.zero;

  factory BusinessOperationItem.fromJson(Map<String, dynamic> json) {
    final rawProduct = _asMapOrNull(json['product'] ?? json['ordered_product']);
    OrderedProduct? parsedProduct;
    if (rawProduct != null) {
      try {
        parsedProduct = OrderedProduct.fromJson(rawProduct);
      } catch (_) {
        parsedProduct = null;
      }
    }

    return BusinessOperationItem(
      idOrderedItem: _asInt(json['id_ordered_item']) ?? 0,
      orderedProductId: _asIntOrNull(
        json['product_id'] ?? json['ordered_product_id'],
      ),
      orderedQuantity: _asInt(json['ordered_quantity']) ?? 0,
      unitPrice: _readDecimalOrZero(json['unit_price']),
      appliedVat: _readDecimalOrZero(json['vat_rate'] ?? json['applied_vat']),
      discountAmount: _readDecimalOrZero(json['discount_amount']),
      reservedQuantity: _asInt(json['reserved_quantity']) ?? 0,
      deliveryFee: _readDecimalOrZero(
        json['delivery_fee'] ?? json['ordered_item_delivery_fee'],
      ),
      deliveryStatus: _asString(
        json['delivery_status'] ?? json['ordered_item_delivery_status'],
      ),
      placedOrderCreation: _parseDate(
        json['created_at'] ?? json['placed_order_creation'],
      ),
      lastModified: _parseDate(
        json['updated_at'] ?? json['ordered_item_last_mod'],
      ),
      cartRef: _asIntOrNull(
        json['cart_id'] ?? json['ordered_item_cart_ref'],
      ),
      orderRef: _asIntOrNull(json['order_id'] ?? json['order_ref']),
      product: parsedProduct,
    );
  }

  Map<String, dynamic> toJson() => {
        'id_ordered_item': idOrderedItem,
        'product_id': orderedProductId,
        'ordered_quantity': orderedQuantity,
        'unit_price': _decimalToWire(unitPrice),
        'vat_rate': _decimalToWire(appliedVat),
        'discount_amount': _decimalToWire(discountAmount),
        'reserved_quantity': reservedQuantity,
        'delivery_fee': _decimalToWire(deliveryFee),
        'delivery_status': deliveryStatus,
        'created_at': placedOrderCreation?.toIso8601String(),
        'updated_at': lastModified?.toIso8601String(),
        'cart_id': cartRef,
        'order_id': orderRef,
        if (product != null) 'product': product!.toJson(),
      };

  /// Gross line total before discount: `unitPrice × quantity`.
  Decimal get lineSubtotal => unitPrice * Decimal.fromInt(orderedQuantity);

  /// Discount applied to this line, in currency units.
  Decimal get lineDiscount => discountAmount;

  /// Net line total after discount, before VAT.
  Decimal get lineNet => lineSubtotal - lineDiscount;

  /// `.toDecimal(scaleOnInfinitePrecision: 2)` on the division — `Decimal / Decimal` returns a
  /// `Rational`.
  Decimal get lineVat =>
      lineNet *
      (appliedVat / Decimal.fromInt(100))
          .toDecimal(scaleOnInfinitePrecision: 2);

  /// Net line total after discount and VAT.
  Decimal get lineTotal => lineNet + lineVat;

  bool get isDelivered => (deliveryStatus ?? '').toLowerCase() == 'delivered';

  /// Product display name from the typed snapshot, or null when the
  /// payload only carried `product_id`.
  String? get productName => product?.productName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessOperationItem &&
          runtimeType == other.runtimeType &&
          idOrderedItem == other.idOrderedItem;

  @override
  int get hashCode => idOrderedItem;

  @override
  String toString() =>
      'BusinessOperationItem(id: $idOrderedItem, product: $orderedProductId, '
      'qty: $orderedQuantity, unit: $unitPrice, vat: $appliedVat)';
}

// ---------------------------------------------------------------------------
// One service line
// ---------------------------------------------------------------------------

/// ## Money
///
/// [unitPrice], [totalPrice], [appliedVat], [deliveryFee] and every
/// derived getter ([lineNet], [lineVat], [lineTotal]) are [Decimal].
class BusinessOperationServiceLine {
  final int idOrderedService;
  final int? orderedServiceServiceId;
  final int orderedServiceQuantity;

  /// Unit price, in [Decimal].
  final Decimal unitPrice;

  /// Line subtotal as shipped by the server, in [Decimal]. When zero,
  /// [lineNet] falls back to `unitPrice × quantity`.
  final Decimal totalPrice;

  /// VAT as a percent (0–100), in [Decimal].
  final Decimal appliedVat;

  /// Delivery fee for this line, in [Decimal].
  final Decimal deliveryFee;

  final String? deliveryStatus;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? scheduledAt;

  /// Raw nested `service` map. Kept because there is no shared typed
  /// `ProvidedService` model in this codebase yet.
  final Map<String, dynamic>? providedServiceRaw;

  const BusinessOperationServiceLine({
    required this.idOrderedService,
    required this.orderedServiceServiceId,
    required this.orderedServiceQuantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.appliedVat,
    required this.deliveryFee,
    this.deliveryStatus,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.scheduledAt,
    this.providedServiceRaw,
  });

  factory BusinessOperationServiceLine.fromJson(Map<String, dynamic> json) {
    return BusinessOperationServiceLine(
      idOrderedService: _asInt(json['ordered_service_id']) ?? 0,
      orderedServiceServiceId: _asIntOrNull(
        json['service_id'] ?? json['ordered_service_service_id'],
      ),
      orderedServiceQuantity: _asInt(json['ordered_service_quantity']) ?? 0,
      unitPrice: _readDecimalOrZero(
        json['unit_price'] ?? json['ordered_service_unit_price'],
      ),
      totalPrice: _readDecimalOrZero(
        json['subtotal'] ?? json['ordered_service_total_price'],
      ),
      appliedVat: _readDecimalOrZero(json['vat_rate'] ?? json['applied_vat']),
      deliveryFee: _readDecimalOrZero(json['ordered_service_delivery_fee']),
      deliveryStatus: _asString(json['ordered_service_delivery_status']),
      notes: _asString(json['ordered_service_notes']),
      createdAt: _parseDate(
        json['created_at'] ?? json['ordered_service_created_at'],
      ),
      updatedAt: _parseDate(
        json['updated_at'] ?? json['ordered_service_updated_at'],
      ),
      scheduledAt: _parseDate(
        json['scheduled_at'] ?? json['ordered_service_scheduled_at'],
      ),
      providedServiceRaw: _asMapOrNull(
        json['service'] ?? json['ordered_service_service'],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'ordered_service_id': idOrderedService,
        'service_id': orderedServiceServiceId,
        'ordered_service_quantity': orderedServiceQuantity,
        'unit_price': _decimalToWire(unitPrice),
        'subtotal': _decimalToWire(totalPrice),
        'vat_rate': _decimalToWire(appliedVat),
        'ordered_service_delivery_fee': _decimalToWire(deliveryFee),
        'ordered_service_delivery_status': deliveryStatus,
        'ordered_service_notes': notes,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'scheduled_at': scheduledAt?.toIso8601String(),
        if (providedServiceRaw != null) 'service': providedServiceRaw,
      };

  Decimal get lineNet {
    if (totalPrice != Decimal.zero) return totalPrice;
    return unitPrice * Decimal.fromInt(orderedServiceQuantity);
  }

  /// `.toDecimal(scaleOnInfinitePrecision: 2)` on the division, same reason as [BusinessOperationItem.lineVat].
  Decimal get lineVat =>
      lineNet *
      (appliedVat / Decimal.fromInt(100))
          .toDecimal(scaleOnInfinitePrecision: 2);

  Decimal get lineTotal => lineNet + lineVat;

  bool get isDelivered => (deliveryStatus ?? '').toLowerCase() == 'delivered';

  String? get providedServiceName =>
      _asString(providedServiceRaw?['provided_service_name']);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessOperationServiceLine &&
          runtimeType == other.runtimeType &&
          idOrderedService == other.idOrderedService;

  @override
  int get hashCode => idOrderedService;

  @override
  String toString() => 'BusinessOperationServiceLine(id: $idOrderedService, '
      'service: $orderedServiceServiceId, qty: $orderedServiceQuantity, '
      'total: $totalPrice)';
}

// ---------------------------------------------------------------------------
// One operation
// ---------------------------------------------------------------------------

/// ## Money
///
/// Every monetary field is [Decimal]: subtotals, tax, delivery revenue,
/// grand total, invoice total, paid, due, costs, margin, and ROI. The
/// `double` conversion happens only inside [toJson], at the JSON
/// boundary. Derived getters ([billingDelta], [effectiveGrandTotal],
/// [amountCharged], [amountPerLines]) are also [Decimal].
class BusinessOperation {
  final String sourceType;
  final int sourceId;
  final int? supplierId;
  final int? clientId;

  final String? status;
  final DateTime? createdAt;

  final Map<String, dynamic>? invoice;
  final Map<String, dynamic>? cart;
  final Map<String, dynamic>? delivery;

  final List<BusinessOperationItem> items;
  final List<BusinessOperationServiceLine> services;

  final Decimal productSubtotal;
  final Decimal serviceSubtotal;
  final Decimal grossSubtotal;
  final Decimal discountAmount;
  final Decimal itemDiscountAmount;
  final Decimal orderDiscountAmount;
  final Decimal taxAmount;
  final Decimal deliveryRevenue;
  final Decimal grandTotal;

  final Decimal invoiceTotal;
  final Decimal paidAmount;
  final Decimal dueAmount;
  final String? invoiceStatus;

  final Decimal productCost;
  final Decimal consumableServiceCost;
  final Decimal nonConsumableServiceCost;
  final Decimal laborCost;
  final Decimal deliveryCost;
  final Decimal totalCost;

  final Decimal marginAmount;
  final Decimal? roi;

  final int itemCount;
  final int serviceCount;

  const BusinessOperation({
    required this.sourceType,
    required this.sourceId,
    this.supplierId,
    this.clientId,
    this.status,
    this.createdAt,
    this.invoice,
    this.cart,
    this.delivery,
    required this.items,
    required this.services,
    required this.productSubtotal,
    required this.serviceSubtotal,
    required this.grossSubtotal,
    required this.discountAmount,
    required this.itemDiscountAmount,
    required this.orderDiscountAmount,
    required this.taxAmount,
    required this.deliveryRevenue,
    required this.grandTotal,
    required this.invoiceTotal,
    required this.paidAmount,
    required this.dueAmount,
    this.invoiceStatus,
    required this.productCost,
    required this.consumableServiceCost,
    required this.nonConsumableServiceCost,
    required this.laborCost,
    required this.deliveryCost,
    required this.totalCost,
    required this.marginAmount,
    this.roi,
    required this.itemCount,
    required this.serviceCount,
  });

  factory BusinessOperation.empty() {
    return BusinessOperation(
      sourceType: 'unknown',
      sourceId: 0,
      items: const [],
      services: const [],
      productSubtotal: Decimal.zero,
      serviceSubtotal: Decimal.zero,
      grossSubtotal: Decimal.zero,
      discountAmount: Decimal.zero,
      itemDiscountAmount: Decimal.zero,
      orderDiscountAmount: Decimal.zero,
      taxAmount: Decimal.zero,
      deliveryRevenue: Decimal.zero,
      grandTotal: Decimal.zero,
      invoiceTotal: Decimal.zero,
      paidAmount: Decimal.zero,
      dueAmount: Decimal.zero,
      productCost: Decimal.zero,
      consumableServiceCost: Decimal.zero,
      nonConsumableServiceCost: Decimal.zero,
      laborCost: Decimal.zero,
      deliveryCost: Decimal.zero,
      totalCost: Decimal.zero,
      marginAmount: Decimal.zero,
      itemCount: 0,
      serviceCount: 0,
    );
  }

  factory BusinessOperation.fromJson(Map<String, dynamic> json) {
    final cart = _asMapOrNull(json['cart']);

    var items = _parseOperationItems(json['items']);
    if (items.isEmpty && cart != null) {
      items = _parseOperationItems(cart['ordered_item']);
    }

    var services = _parseOperationServices(json['services']);
    if (services.isEmpty && cart != null) {
      services = _parseOperationServices(cart['ordered_service']);
    }

    final rawProductSubtotal = _readDecimalOrZero(json['product_subtotal']);
    final rawServiceSubtotal = _readDecimalOrZero(json['service_subtotal']);
    final rawGrossSubtotal = _readDecimalOrZero(json['gross_subtotal']);
    final rawTaxAmount = _readDecimalOrZero(json['tax_amount']);
    final rawGrandTotal = _readDecimalOrZero(json['grand_total']);
    final rawItemDiscount = _readDecimalOrZero(json['item_discount_amount']);
    final rawOrderDiscount = _readDecimalOrZero(json['order_discount_amount']);

    final hasLines = items.isNotEmpty || services.isNotEmpty;
    final backendZeroedFinancials = hasLines &&
        rawProductSubtotal == Decimal.zero &&
        rawServiceSubtotal == Decimal.zero &&
        rawGrossSubtotal == Decimal.zero &&
        rawGrandTotal == Decimal.zero &&
        rawTaxAmount == Decimal.zero;

    Decimal productSubtotal = rawProductSubtotal;
    Decimal serviceSubtotal = rawServiceSubtotal;
    Decimal grossSubtotal = rawGrossSubtotal;
    Decimal taxAmount = rawTaxAmount;
    Decimal grandTotal = rawGrandTotal;
    Decimal itemDiscountAmount = rawItemDiscount;

    if (backendZeroedFinancials) {
      productSubtotal = Decimal.zero;
      Decimal derivedItemDiscount = Decimal.zero;
      Decimal derivedTax = Decimal.zero;
      for (final it in items) {
        productSubtotal += it.lineSubtotal;
        derivedItemDiscount += it.lineDiscount;
        derivedTax += it.lineVat;
      }

      serviceSubtotal = Decimal.zero;
      for (final sv in services) {
        serviceSubtotal += sv.lineNet;
        derivedTax += sv.lineVat;
      }

      itemDiscountAmount = derivedItemDiscount;
      grossSubtotal = productSubtotal + serviceSubtotal;
      taxAmount = derivedTax;
      grandTotal =
          grossSubtotal - itemDiscountAmount - rawOrderDiscount + taxAmount;
    }

    final itemCountRaw = _asInt(json['item_count']) ?? 0;
    final serviceCountRaw = _asInt(json['service_count']) ?? 0;
    final itemCount = itemCountRaw > 0 ? itemCountRaw : items.length;
    final serviceCount =
        serviceCountRaw > 0 ? serviceCountRaw : services.length;

    return BusinessOperation(
      sourceType: _asString(json['source_type']) ?? 'unknown',
      sourceId: _asInt(json['source_id']) ?? 0,
      supplierId: _asIntOrNull(json['supplier_id']),
      clientId: _asIntOrNull(json['client_id']),
      status: _asString(json['status']),
      createdAt: _parseDate(json['created_at']),
      invoice: _asMapOrNull(json['invoice']),
      cart: cart,
      delivery: _asMapOrNull(json['delivery']),
      items: items,
      services: services,
      productSubtotal: productSubtotal,
      serviceSubtotal: serviceSubtotal,
      grossSubtotal: grossSubtotal,
      discountAmount: _readDecimalOrZero(json['discount_amount']),
      itemDiscountAmount: itemDiscountAmount,
      orderDiscountAmount: rawOrderDiscount,
      taxAmount: taxAmount,
      deliveryRevenue: _readDecimalOrZero(json['delivery_revenue']),
      grandTotal: grandTotal,
      invoiceTotal: _readDecimalOrZero(json['invoice_total']),
      paidAmount: _readDecimalOrZero(json['paid_amount']),
      dueAmount: _readDecimalOrZero(json['due_amount']),
      invoiceStatus: _asString(json['invoice_status']),
      productCost: _readDecimalOrZero(json['product_cost']),
      consumableServiceCost:
          _readDecimalOrZero(json['consumable_service_cost']),
      nonConsumableServiceCost:
          _readDecimalOrZero(json['non_consumable_service_cost']),
      laborCost: _readDecimalOrZero(json['labor_cost']),
      deliveryCost: _readDecimalOrZero(json['delivery_cost']),
      totalCost: _readDecimalOrZero(json['total_cost']),
      marginAmount: _readDecimalOrZero(json['margin_amount']),
      roi: _readDecimal(json['roi']),
      itemCount: itemCount,
      serviceCount: serviceCount,
    );
  }

  BusinessOperation copyWith({
    String? sourceType,
    int? sourceId,
    int? supplierId,
    int? clientId,
    String? status,
    DateTime? createdAt,
    Map<String, dynamic>? invoice,
    Map<String, dynamic>? cart,
    Map<String, dynamic>? delivery,
    List<BusinessOperationItem>? items,
    List<BusinessOperationServiceLine>? services,
    Decimal? productSubtotal,
    Decimal? serviceSubtotal,
    Decimal? grossSubtotal,
    Decimal? discountAmount,
    Decimal? itemDiscountAmount,
    Decimal? orderDiscountAmount,
    Decimal? taxAmount,
    Decimal? deliveryRevenue,
    Decimal? grandTotal,
    Decimal? invoiceTotal,
    Decimal? paidAmount,
    Decimal? dueAmount,
    String? invoiceStatus,
    Decimal? productCost,
    Decimal? consumableServiceCost,
    Decimal? nonConsumableServiceCost,
    Decimal? laborCost,
    Decimal? deliveryCost,
    Decimal? totalCost,
    Decimal? marginAmount,
    Decimal? roi,
    int? itemCount,
    int? serviceCount,
  }) {
    return BusinessOperation(
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      supplierId: supplierId ?? this.supplierId,
      clientId: clientId ?? this.clientId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      invoice: invoice ?? this.invoice,
      cart: cart ?? this.cart,
      delivery: delivery ?? this.delivery,
      items: items ?? this.items,
      services: services ?? this.services,
      productSubtotal: productSubtotal ?? this.productSubtotal,
      serviceSubtotal: serviceSubtotal ?? this.serviceSubtotal,
      grossSubtotal: grossSubtotal ?? this.grossSubtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      itemDiscountAmount: itemDiscountAmount ?? this.itemDiscountAmount,
      orderDiscountAmount: orderDiscountAmount ?? this.orderDiscountAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      deliveryRevenue: deliveryRevenue ?? this.deliveryRevenue,
      grandTotal: grandTotal ?? this.grandTotal,
      invoiceTotal: invoiceTotal ?? this.invoiceTotal,
      paidAmount: paidAmount ?? this.paidAmount,
      dueAmount: dueAmount ?? this.dueAmount,
      invoiceStatus: invoiceStatus ?? this.invoiceStatus,
      productCost: productCost ?? this.productCost,
      consumableServiceCost:
          consumableServiceCost ?? this.consumableServiceCost,
      nonConsumableServiceCost:
          nonConsumableServiceCost ?? this.nonConsumableServiceCost,
      laborCost: laborCost ?? this.laborCost,
      deliveryCost: deliveryCost ?? this.deliveryCost,
      totalCost: totalCost ?? this.totalCost,
      marginAmount: marginAmount ?? this.marginAmount,
      roi: roi ?? this.roi,
      itemCount: itemCount ?? this.itemCount,
      serviceCount: serviceCount ?? this.serviceCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'source_type': sourceType,
        'source_id': sourceId,
        'supplier_id': supplierId,
        'client_id': clientId,
        'status': status,
        'created_at': createdAt?.toIso8601String(),
        'invoice': invoice,
        'cart': cart,
        'delivery': delivery,
        'items': items.map((e) => e.toJson()).toList(),
        'services': services.map((e) => e.toJson()).toList(),
        'product_subtotal': _decimalToWire(productSubtotal),
        'service_subtotal': _decimalToWire(serviceSubtotal),
        'gross_subtotal': _decimalToWire(grossSubtotal),
        'discount_amount': _decimalToWire(discountAmount),
        'item_discount_amount': _decimalToWire(itemDiscountAmount),
        'order_discount_amount': _decimalToWire(orderDiscountAmount),
        'tax_amount': _decimalToWire(taxAmount),
        'delivery_revenue': _decimalToWire(deliveryRevenue),
        'grand_total': _decimalToWire(grandTotal),
        'invoice_total': _decimalToWire(invoiceTotal),
        'paid_amount': _decimalToWire(paidAmount),
        'due_amount': _decimalToWire(dueAmount),
        'invoice_status': invoiceStatus,
        'product_cost': _decimalToWire(productCost),
        'consumable_service_cost': _decimalToWire(consumableServiceCost),
        'non_consumable_service_cost': _decimalToWire(nonConsumableServiceCost),
        'labor_cost': _decimalToWire(laborCost),
        'delivery_cost': _decimalToWire(deliveryCost),
        'total_cost': _decimalToWire(totalCost),
        'margin_amount': _decimalToWire(marginAmount),
        'roi': _decimalToWireOrNull(roi),
        'item_count': itemCount,
        'service_count': serviceCount,
      };

  // ---------------------------------------------------------------------
  // Convenience
  // ---------------------------------------------------------------------

  bool get isCart => sourceType == 'cart';
  bool get isDelivery => sourceType == 'delivery';
  bool get isPaid => invoiceStatus?.toLowerCase() == 'paid';
  bool get isUnpaid => invoiceStatus?.toLowerCase() == 'unpaid';
  bool get isFullySettled => dueAmount <= Decimal.parse('0.001');
  bool get isProfitable => marginAmount > Decimal.zero;

  /// True when paid falls short of the invoice total by more than a
  /// cent. Uses `Decimal.parse('0.01')` as the tolerance.
  bool get paymentShortfall =>
      paidAmount + Decimal.parse('0.01') < invoiceTotal;

  /// True when grand total exceeds invoice total by more than a cent.
  bool get billingShortfall =>
      grandTotal > invoiceTotal + Decimal.parse('0.01');

  /// Signed difference between grand total and invoiced total.
  Decimal get billingDelta => grandTotal - invoiceTotal;

  /// Prefers the line-derived [grandTotal]; falls back to
  /// [invoiceTotal] when the operation is fully zero (e.g. an empty
  /// stub).
  Decimal get effectiveGrandTotal {
    if (grandTotal > Decimal.zero) return grandTotal;
    if (invoiceTotal > Decimal.zero) return invoiceTotal;
    return Decimal.zero;
  }

  /// What the customer was billed (invoice first, then grand total).
  Decimal get amountCharged =>
      invoiceTotal > Decimal.zero ? invoiceTotal : grandTotal;

  /// What the line items say the operation is worth.
  Decimal get amountPerLines => grandTotal;

  int get lineCount => items.length + services.length;
  bool get hasLines => items.isNotEmpty || services.isNotEmpty;

  String get title {
    if (isCart) return 'Cart #$sourceId';
    if (isDelivery) return 'Order #$sourceId';
    return '$sourceType #$sourceId';
  }

  String get key => '$sourceType:$sourceId';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessOperation &&
          runtimeType == other.runtimeType &&
          sourceType == other.sourceType &&
          sourceId == other.sourceId;

  @override
  int get hashCode => Object.hash(sourceType, sourceId);

  @override
  String toString() =>
      'BusinessOperation($sourceType #$sourceId, status: $status, '
      'grandTotal: $grandTotal, paid: $paidAmount, due: $dueAmount)';
}

// ---------------------------------------------------------------------------
// Aggregate statistics
// ---------------------------------------------------------------------------

class BusinessOperationsStatsData {
  final BusinessOperationsTotals totals;
  final BusinessOperationsRatios ratios;
  final BusinessOperationsCounts counts;
  final Map<String, BusinessOperationsBucket> byStatus;
  final Map<String, BusinessOperationsBucket> bySource;
  final Map<String, BusinessOperationsBucket> bySupplier;
  final Map<String, BusinessOperationsBucket> byClient;
  final Map<String, BusinessOperationsBucket> byDay;

  const BusinessOperationsStatsData({
    required this.totals,
    required this.ratios,
    required this.counts,
    required this.byStatus,
    required this.bySource,
    required this.bySupplier,
    required this.byClient,
    required this.byDay,
  });

  factory BusinessOperationsStatsData.fromJson(Map<String, dynamic> json) {
    return BusinessOperationsStatsData(
      totals: BusinessOperationsTotals.fromJson(_asMap(json['totals'])),
      ratios: BusinessOperationsRatios.fromJson(_asMap(json['ratios'])),
      counts: BusinessOperationsCounts.fromJson(_asMap(json['counts'])),
      byStatus: _parseBuckets(json['by_status']),
      bySource: _parseBuckets(json['by_source']),
      bySupplier: _parseBuckets(json['by_supplier']),
      byClient: _parseBuckets(json['by_client']),
      byDay: _parseBuckets(json['by_day']),
    );
  }

  Map<String, dynamic> toJson() => {
        'totals': totals.toJson(),
        'ratios': ratios.toJson(),
        'counts': counts.toJson(),
        'by_status': byStatus.map((k, v) => MapEntry(k, v.toJson())),
        'by_source': bySource.map((k, v) => MapEntry(k, v.toJson())),
        'by_supplier': bySupplier.map((k, v) => MapEntry(k, v.toJson())),
        'by_client': byClient.map((k, v) => MapEntry(k, v.toJson())),
        'by_day': byDay.map((k, v) => MapEntry(k, v.toJson())),
      };

  @override
  String toString() => 'BusinessOperationsStatsData(totals: $totals, '
      'counts: $counts)';
}

class BusinessOperationsTotals {
  final Decimal productSubtotal;
  final Decimal serviceSubtotal;
  final Decimal grossSubtotal;
  final Decimal discountAmount;
  final Decimal taxAmount;
  final Decimal deliveryRevenue;
  final Decimal grandTotal;
  final Decimal invoiceTotal;
  final Decimal paidAmount;
  final Decimal dueAmount;
  final Decimal productCost;
  final Decimal consumableServiceCost;
  final Decimal nonConsumableServiceCost;
  final Decimal laborCost;
  final Decimal deliveryCost;
  final Decimal totalCost;
  final Decimal marginAmount;
  final int itemCount;
  final int serviceCount;

  const BusinessOperationsTotals({
    required this.productSubtotal,
    required this.serviceSubtotal,
    required this.grossSubtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.deliveryRevenue,
    required this.grandTotal,
    required this.invoiceTotal,
    required this.paidAmount,
    required this.dueAmount,
    required this.productCost,
    required this.consumableServiceCost,
    required this.nonConsumableServiceCost,
    required this.laborCost,
    required this.deliveryCost,
    required this.totalCost,
    required this.marginAmount,
    required this.itemCount,
    required this.serviceCount,
  });

  factory BusinessOperationsTotals.fromJson(Map<String, dynamic> j) =>
      BusinessOperationsTotals(
        productSubtotal: _readDecimalOrZero(j['product_subtotal']),
        serviceSubtotal: _readDecimalOrZero(j['service_subtotal']),
        grossSubtotal: _readDecimalOrZero(j['gross_subtotal']),
        discountAmount: _readDecimalOrZero(j['discount_amount']),
        taxAmount: _readDecimalOrZero(j['tax_amount']),
        deliveryRevenue: _readDecimalOrZero(j['delivery_revenue']),
        grandTotal: _readDecimalOrZero(j['grand_total']),
        invoiceTotal: _readDecimalOrZero(j['invoice_total']),
        paidAmount: _readDecimalOrZero(j['paid_amount']),
        dueAmount: _readDecimalOrZero(j['due_amount']),
        productCost: _readDecimalOrZero(j['product_cost']),
        consumableServiceCost: _readDecimalOrZero(j['consumable_service_cost']),
        nonConsumableServiceCost:
            _readDecimalOrZero(j['non_consumable_service_cost']),
        laborCost: _readDecimalOrZero(j['labor_cost']),
        deliveryCost: _readDecimalOrZero(j['delivery_cost']),
        totalCost: _readDecimalOrZero(j['total_cost']),
        marginAmount: _readDecimalOrZero(j['margin_amount']),
        itemCount: _asInt(j['item_count']) ?? 0,
        serviceCount: _asInt(j['service_count']) ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'product_subtotal': _decimalToWire(productSubtotal),
        'service_subtotal': _decimalToWire(serviceSubtotal),
        'gross_subtotal': _decimalToWire(grossSubtotal),
        'discount_amount': _decimalToWire(discountAmount),
        'tax_amount': _decimalToWire(taxAmount),
        'delivery_revenue': _decimalToWire(deliveryRevenue),
        'grand_total': _decimalToWire(grandTotal),
        'invoice_total': _decimalToWire(invoiceTotal),
        'paid_amount': _decimalToWire(paidAmount),
        'due_amount': _decimalToWire(dueAmount),
        'product_cost': _decimalToWire(productCost),
        'consumable_service_cost': _decimalToWire(consumableServiceCost),
        'non_consumable_service_cost': _decimalToWire(nonConsumableServiceCost),
        'labor_cost': _decimalToWire(laborCost),
        'delivery_cost': _decimalToWire(deliveryCost),
        'total_cost': _decimalToWire(totalCost),
        'margin_amount': _decimalToWire(marginAmount),
        'item_count': itemCount,
        'service_count': serviceCount,
      };

  @override
  String toString() => 'BusinessOperationsTotals(grandTotal: $grandTotal, '
      'paid: $paidAmount, due: $dueAmount, margin: $marginAmount)';
}

class BusinessOperationsRatios {
  final Decimal? overallRoi;
  final Decimal averageTicket;
  final Decimal? collectionRate;
  final Decimal? discountRate;

  const BusinessOperationsRatios({
    required this.overallRoi,
    required this.averageTicket,
    required this.collectionRate,
    required this.discountRate,
  });

  factory BusinessOperationsRatios.fromJson(Map<String, dynamic> j) =>
      BusinessOperationsRatios(
        overallRoi: _readDecimal(j['overall_roi']),
        averageTicket: _readDecimalOrZero(j['average_ticket']),
        collectionRate: _readDecimal(j['collection_rate']),
        discountRate: _readDecimal(j['discount_rate']),
      );

  Map<String, dynamic> toJson() => {
        'overall_roi': _decimalToWireOrNull(overallRoi),
        'average_ticket': _decimalToWire(averageTicket),
        'collection_rate': _decimalToWireOrNull(collectionRate),
        'discount_rate': _decimalToWireOrNull(discountRate),
      };

  @override
  String toString() => 'BusinessOperationsRatios(roi: $overallRoi, '
      'avgTicket: $averageTicket, collection: $collectionRate)';
}

class BusinessOperationsCounts {
  final int operations;
  final int carts;
  final int deliveries;

  const BusinessOperationsCounts({
    required this.operations,
    required this.carts,
    required this.deliveries,
  });

  factory BusinessOperationsCounts.fromJson(Map<String, dynamic> j) =>
      BusinessOperationsCounts(
        operations: _asInt(j['operations']) ?? 0,
        carts: _asInt(j['carts']) ?? 0,
        deliveries: _asInt(j['deliveries']) ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'operations': operations,
        'carts': carts,
        'deliveries': deliveries,
      };

  @override
  String toString() =>
      'BusinessOperationsCounts(ops: $operations, carts: $carts, '
      'deliveries: $deliveries)';
}

class BusinessOperationsBucket {
  final int count;
  final Decimal? grandTotal;
  final Decimal? totalAmount;
  final Decimal? dueAmount;

  const BusinessOperationsBucket({
    required this.count,
    this.grandTotal,
    this.totalAmount,
    this.dueAmount,
  });

  factory BusinessOperationsBucket.fromJson(Map<String, dynamic> j) =>
      BusinessOperationsBucket(
        count: _asInt(j['count']) ?? 0,
        grandTotal: _readDecimal(j['grand_total']),
        totalAmount: _readDecimal(j['total_amount']),
        dueAmount: _readDecimal(j['due_amount']),
      );

  Map<String, dynamic> toJson() => {
        'count': count,
        if (grandTotal != null) 'grand_total': _decimalToWire(grandTotal!),
        if (totalAmount != null) 'total_amount': _decimalToWire(totalAmount!),
        if (dueAmount != null) 'due_amount': _decimalToWire(dueAmount!),
      };

  Decimal? get amount => grandTotal ?? totalAmount;

  @override
  String toString() =>
      'BusinessOperationsBucket(count: $count, amount: $amount, '
      'due: $dueAmount)';
}

// ---------------------------------------------------------------------------
// Envelope metadata
// ---------------------------------------------------------------------------

class BusinessOperationsPagination {
  final int offset;
  final int limit;
  final int returned;
  final int totalInWindow;

  const BusinessOperationsPagination({
    required this.offset,
    required this.limit,
    required this.returned,
    required this.totalInWindow,
  });

  factory BusinessOperationsPagination.fromJson(Map<String, dynamic> j) =>
      BusinessOperationsPagination(
        offset: _asInt(j['offset']) ?? 0,
        limit: _asInt(j['limit']) ?? 0,
        returned: _asInt(j['returned']) ?? 0,
        totalInWindow: _asInt(j['total_in_window']) ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'offset': offset,
        'limit': limit,
        'returned': returned,
        'total_in_window': totalInWindow,
      };

  bool get isEmpty => returned == 0;

  @override
  String toString() =>
      'BusinessOperationsPagination(offset: $offset, limit: $limit, '
      'returned: $returned, totalInWindow: $totalInWindow)';
}

class BusinessOperationsWindow {
  final DateTime? dateFrom;
  final DateTime? dateTo;

  const BusinessOperationsWindow({this.dateFrom, this.dateTo});

  factory BusinessOperationsWindow.fromJson(Map<String, dynamic> j) =>
      BusinessOperationsWindow(
        dateFrom: _parseDate(j['date_from']),
        dateTo: _parseDate(j['date_to']),
      );

  Map<String, dynamic> toJson() => {
        'date_from': dateFrom?.toIso8601String(),
        'date_to': dateTo?.toIso8601String(),
      };

  bool get hasRange => dateFrom != null || dateTo != null;
  bool get isOpenStart => dateFrom == null && dateTo != null;
  bool get isOpenEnd => dateFrom != null && dateTo == null;
  bool get isBounded => dateFrom != null && dateTo != null;

  @override
  String toString() => 'BusinessOperationsWindow(from: $dateFrom, to: $dateTo)';
}

// ---------------------------------------------------------------------------
// Decimal helpers
// ---------------------------------------------------------------------------

/// Coerces any JSON value to [Decimal].
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

// ---------------------------------------------------------------------------
// Safe coercion (non-money)
// ---------------------------------------------------------------------------

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is num) return v.toInt();
  if (v is String) {
    final asInt = int.tryParse(v);
    if (asInt != null) return asInt;
    final asDouble = double.tryParse(v);
    return asDouble?.toInt();
  }
  return null;
}

int? _asIntOrNull(dynamic v) => _asInt(v);

String? _asString(dynamic v) {
  if (v == null) return null;
  if (v is String) return v;
  return v.toString();
}

Map<String, dynamic> _asMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  return const {};
}

Map<String, dynamic>? _asMapOrNull(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  return null;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is int) {
    final ms = v > 1000000000000 ? v : v * 1000;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }
  if (v is String) {
    if (v.isEmpty) return null;
    try {
      return DateTime.parse(v);
    } catch (_) {
      return null;
    }
  }
  return null;
}

// ---------------------------------------------------------------------------
// Collection helpers
// ---------------------------------------------------------------------------

List<BusinessOperation> _parseOperations(dynamic raw) {
  if (raw is! List) return const [];
  final out = <BusinessOperation>[];
  for (final e in raw) {
    if (e is Map<String, dynamic>) {
      out.add(BusinessOperation.fromJson(e));
    } else if (e is Map) {
      out.add(BusinessOperation.fromJson(Map<String, dynamic>.from(e)));
    }
  }
  return out;
}

List<BusinessOperationItem> _parseOperationItems(dynamic raw) {
  if (raw is! List) return const [];
  final out = <BusinessOperationItem>[];
  for (final e in raw) {
    if (e is Map<String, dynamic>) {
      out.add(BusinessOperationItem.fromJson(e));
    } else if (e is Map) {
      out.add(
        BusinessOperationItem.fromJson(Map<String, dynamic>.from(e)),
      );
    }
  }
  return out;
}

List<BusinessOperationServiceLine> _parseOperationServices(dynamic raw) {
  if (raw is! List) return const [];
  final out = <BusinessOperationServiceLine>[];
  for (final e in raw) {
    if (e is Map<String, dynamic>) {
      out.add(BusinessOperationServiceLine.fromJson(e));
    } else if (e is Map) {
      out.add(
        BusinessOperationServiceLine.fromJson(
          Map<String, dynamic>.from(e),
        ),
      );
    }
  }
  return out;
}

BusinessOperationsStatsData? _parseStatsOrNull(dynamic raw) {
  final map = _asMapOrNull(raw);
  if (map == null) return null;
  return BusinessOperationsStatsData.fromJson(map);
}

Map<String, BusinessOperationsBucket> _parseBuckets(dynamic raw) {
  if (raw is! Map) return const {};
  final out = <String, BusinessOperationsBucket>{};
  raw.forEach((k, v) {
    if (v is Map<String, dynamic>) {
      out[k.toString()] = BusinessOperationsBucket.fromJson(v);
    } else if (v is Map) {
      out[k.toString()] =
          BusinessOperationsBucket.fromJson(Map<String, dynamic>.from(v));
    }
  });
  return out;
}
