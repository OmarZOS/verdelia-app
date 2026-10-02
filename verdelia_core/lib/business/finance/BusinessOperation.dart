// lib/models/business_operation.dart

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
    return BusinessOperationsResponse(
      operations: _parseOperations(json['operations']),
      stats: _parseStatsOrNull(json['stats']),
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
}

// ---------------------------------------------------------------------------
// One operation
// ---------------------------------------------------------------------------

class BusinessOperation {
  // Identity
  final String sourceType; // "cart" | "delivery"
  final int sourceId;
  final int? supplierId;
  final int? clientId;

  // Status
  final String? status;
  final DateTime? createdAt;

  // Raw payloads
  final Map<String, dynamic>? invoice;
  final Map<String, dynamic>? cart;
  final Map<String, dynamic>? delivery;
  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>> services;

  // Commercial
  final double productSubtotal;
  final double serviceSubtotal;
  final double grossSubtotal;
  final double discountAmount;
  final double itemDiscountAmount;
  final double orderDiscountAmount;
  final double taxAmount;
  final double deliveryRevenue;
  final double grandTotal;

  // Settlement
  final double invoiceTotal;
  final double paidAmount;
  final double dueAmount;
  final String? invoiceStatus;

  // Cost
  final double productCost;
  final double consumableServiceCost;
  final double nonConsumableServiceCost;
  final double laborCost;
  final double deliveryCost;
  final double totalCost;

  // Profitability
  final double marginAmount;
  final double? roi;

  // Counts
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

  factory BusinessOperation.fromJson(Map<String, dynamic> json) {
    return BusinessOperation(
      sourceType: _asString(json['source_type']) ?? 'unknown',
      sourceId: _asInt(json['source_id']) ?? 0,
      supplierId: _asIntOrNull(json['supplier_id']),
      clientId: _asIntOrNull(json['client_id']),
      status: _asString(json['status']),
      createdAt: _parseDate(json['created_at']),
      invoice: _asMapOrNull(json['invoice']),
      cart: _asMapOrNull(json['cart']),
      delivery: _asMapOrNull(json['delivery']),
      items: _asMapList(json['items']),
      services: _asMapList(json['services']),
      productSubtotal: _asDouble(json['product_subtotal']),
      serviceSubtotal: _asDouble(json['service_subtotal']),
      grossSubtotal: _asDouble(json['gross_subtotal']),
      discountAmount: _asDouble(json['discount_amount']),
      itemDiscountAmount: _asDouble(json['item_discount_amount']),
      orderDiscountAmount: _asDouble(json['order_discount_amount']),
      taxAmount: _asDouble(json['tax_amount']),
      deliveryRevenue: _asDouble(json['delivery_revenue']),
      grandTotal: _asDouble(json['grand_total']),
      invoiceTotal: _asDouble(json['invoice_total']),
      paidAmount: _asDouble(json['paid_amount']),
      dueAmount: _asDouble(json['due_amount']),
      invoiceStatus: _asString(json['invoice_status']),
      productCost: _asDouble(json['product_cost']),
      consumableServiceCost: _asDouble(json['consumable_service_cost']),
      nonConsumableServiceCost: _asDouble(json['non_consumable_service_cost']),
      laborCost: _asDouble(json['labor_cost']),
      deliveryCost: _asDouble(json['delivery_cost']),
      totalCost: _asDouble(json['total_cost']),
      marginAmount: _asDouble(json['margin_amount']),
      roi: _asDoubleOrNull(json['roi']),
      itemCount: _asInt(json['item_count']) ?? 0,
      serviceCount: _asInt(json['service_count']) ?? 0,
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
        'items': items,
        'services': services,
        'product_subtotal': productSubtotal,
        'service_subtotal': serviceSubtotal,
        'gross_subtotal': grossSubtotal,
        'discount_amount': discountAmount,
        'item_discount_amount': itemDiscountAmount,
        'order_discount_amount': orderDiscountAmount,
        'tax_amount': taxAmount,
        'delivery_revenue': deliveryRevenue,
        'grand_total': grandTotal,
        'invoice_total': invoiceTotal,
        'paid_amount': paidAmount,
        'due_amount': dueAmount,
        'invoice_status': invoiceStatus,
        'product_cost': productCost,
        'consumable_service_cost': consumableServiceCost,
        'non_consumable_service_cost': nonConsumableServiceCost,
        'labor_cost': laborCost,
        'delivery_cost': deliveryCost,
        'total_cost': totalCost,
        'margin_amount': marginAmount,
        'roi': roi,
        'item_count': itemCount,
        'service_count': serviceCount,
      };

  // Convenience
  bool get isCart => sourceType == 'cart';
  bool get isDelivery => sourceType == 'delivery';
  bool get isPaid => invoiceStatus?.toLowerCase() == 'paid';
  bool get isUnpaid => invoiceStatus?.toLowerCase() == 'unpaid';
  bool get isFullySettled => dueAmount <= 0.001;
  bool get isProfitable => marginAmount > 0;

  /// True when the payment records fall short of the invoice's stated total.
  /// Computed on the client from the values the backend already sends; the
  /// backend no longer ships an explicit `payment_status_consistent` flag.
  bool get paymentShortfall => paidAmount + 0.01 < invoiceTotal;

  String get title {
    if (isCart) return 'Cart #$sourceId';
    if (isDelivery) return 'Order #$sourceId';
    return '$sourceType #$sourceId';
  }
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
}

class BusinessOperationsTotals {
  final double productSubtotal;
  final double serviceSubtotal;
  final double grossSubtotal;
  final double discountAmount;
  final double taxAmount;
  final double deliveryRevenue;
  final double grandTotal;
  final double invoiceTotal;
  final double paidAmount;
  final double dueAmount;
  final double productCost;
  final double consumableServiceCost;
  final double nonConsumableServiceCost;
  final double laborCost;
  final double deliveryCost;
  final double totalCost;
  final double marginAmount;
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
        productSubtotal: _asDouble(j['product_subtotal']),
        serviceSubtotal: _asDouble(j['service_subtotal']),
        grossSubtotal: _asDouble(j['gross_subtotal']),
        discountAmount: _asDouble(j['discount_amount']),
        taxAmount: _asDouble(j['tax_amount']),
        deliveryRevenue: _asDouble(j['delivery_revenue']),
        grandTotal: _asDouble(j['grand_total']),
        invoiceTotal: _asDouble(j['invoice_total']),
        paidAmount: _asDouble(j['paid_amount']),
        dueAmount: _asDouble(j['due_amount']),
        productCost: _asDouble(j['product_cost']),
        consumableServiceCost: _asDouble(j['consumable_service_cost']),
        nonConsumableServiceCost: _asDouble(j['non_consumable_service_cost']),
        laborCost: _asDouble(j['labor_cost']),
        deliveryCost: _asDouble(j['delivery_cost']),
        totalCost: _asDouble(j['total_cost']),
        marginAmount: _asDouble(j['margin_amount']),
        itemCount: _asInt(j['item_count']) ?? 0,
        serviceCount: _asInt(j['service_count']) ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'product_subtotal': productSubtotal,
        'service_subtotal': serviceSubtotal,
        'gross_subtotal': grossSubtotal,
        'discount_amount': discountAmount,
        'tax_amount': taxAmount,
        'delivery_revenue': deliveryRevenue,
        'grand_total': grandTotal,
        'invoice_total': invoiceTotal,
        'paid_amount': paidAmount,
        'due_amount': dueAmount,
        'product_cost': productCost,
        'consumable_service_cost': consumableServiceCost,
        'non_consumable_service_cost': nonConsumableServiceCost,
        'labor_cost': laborCost,
        'delivery_cost': deliveryCost,
        'total_cost': totalCost,
        'margin_amount': marginAmount,
        'item_count': itemCount,
        'service_count': serviceCount,
      };
}

class BusinessOperationsRatios {
  final double? overallRoi;
  final double averageTicket;
  final double? collectionRate;
  final double? discountRate;

  const BusinessOperationsRatios({
    required this.overallRoi,
    required this.averageTicket,
    required this.collectionRate,
    required this.discountRate,
  });

  factory BusinessOperationsRatios.fromJson(Map<String, dynamic> j) =>
      BusinessOperationsRatios(
        overallRoi: _asDoubleOrNull(j['overall_roi']),
        averageTicket: _asDouble(j['average_ticket']),
        collectionRate: _asDoubleOrNull(j['collection_rate']),
        discountRate: _asDoubleOrNull(j['discount_rate']),
      );

  Map<String, dynamic> toJson() => {
        'overall_roi': overallRoi,
        'average_ticket': averageTicket,
        'collection_rate': collectionRate,
        'discount_rate': discountRate,
      };
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
}

// A per-bucket aggregate. Keys vary by bucket type (status name, supplier id,
// day string), but the numeric fields are consistent.
class BusinessOperationsBucket {
  final int count;
  final double? grandTotal;
  final double? totalAmount; // some buckets only carry total_amount
  final double? dueAmount;

  const BusinessOperationsBucket({
    required this.count,
    this.grandTotal,
    this.totalAmount,
    this.dueAmount,
  });

  factory BusinessOperationsBucket.fromJson(Map<String, dynamic> j) =>
      BusinessOperationsBucket(
        count: _asInt(j['count']) ?? 0,
        grandTotal: _asDoubleOrNull(j['grand_total']),
        totalAmount: _asDoubleOrNull(j['total_amount']),
        dueAmount: _asDoubleOrNull(j['due_amount']),
      );

  Map<String, dynamic> toJson() => {
        'count': count,
        if (grandTotal != null) 'grand_total': grandTotal,
        if (totalAmount != null) 'total_amount': totalAmount,
        if (dueAmount != null) 'due_amount': dueAmount,
      };
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
        limit: _asInt(j['limit']) ?? 100,
        returned: _asInt(j['returned']) ?? 0,
        totalInWindow: _asInt(j['total_in_window']) ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'offset': offset,
        'limit': limit,
        'returned': returned,
        'total_in_window': totalInWindow,
      };
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
}

// ---------------------------------------------------------------------------
// Safe numeric / string / bool coercion
// ---------------------------------------------------------------------------

/// Coerce any value to a double. Accepts int, double, String, null.
double _asDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

/// Coerce any value to a double, returning null when the source is null
/// or unparseable.
double? _asDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

/// Coerce any value to an int. Accepts int, double (truncated), String.
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

/// Coerce any value to a String. Booleans and numbers become their
/// string form.
String? _asString(dynamic v) {
  if (v == null) return null;
  if (v is String) return v;
  return v.toString();
}

/// Coerce any value to a bool. Accepts bool, "true"/"false", 1/0.
bool? _asBool(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final s = v.toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
  }
  return null;
}

/// Coerce any value to a Map<String, dynamic>. Returns an empty map when
/// the source isn't a map, so callers never have to null-check the result
/// of `_asMap(...)`.
Map<String, dynamic> _asMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  return const {};
}

/// Coerce any value to a Map<String, dynamic>, or null when the source
/// isn't a map. Use this for optional nested payloads (invoice, cart,
/// delivery).
Map<String, dynamic>? _asMapOrNull(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  return null;
}

/// Coerce any value to a List<Map<String, dynamic>>. Non-map entries are
/// dropped silently.
List<Map<String, dynamic>> _asMapList(dynamic v) {
  if (v is! List) return const [];
  final out = <Map<String, dynamic>>[];
  for (final e in v) {
    if (e is Map<String, dynamic>) {
      out.add(e);
    } else if (e is Map) {
      out.add(Map<String, dynamic>.from(e));
    }
  }
  return out;
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
