// lib/business/finance/OrderedService.dart

import 'package:decimal/decimal.dart';

import 'package:verdelia_core/business/finance/ProvidedService.dart';

/// One ordered service line.
///
/// ## Wire shape (read)
///
/// ```json
/// {
///   "ordered_service_id": 2,
///   "cart_id": 4,
///   "service_id": 1,
///   "ordered_service_quantity": 1,
///   "unit_price": 391.59,
///   "subtotal": 391.59,
///   "vat_rate": 0,
///   "discount_amount": null,
///   "ordered_service_delivery_fee": 0,
///   "ordered_service_delivery_status": "pending",
///   "ordered_service_notes": "Service line 20374d",
///   "scheduled_at": null,
///   "created_at": "2026-10-23T20:41:32",
///   "updated_at": "2026-10-23T20:41:32",
///   "service": { ...provided-service snapshot... }
/// }
/// ```
///
/// Notice the **hybrid** naming: some fields carry the
/// `ordered_service_` prefix (`id`, `quantity`, `notes`,
/// `delivery_*`), some are flat (`cart_id`, `service_id`,
/// `unit_price`, `subtotal`, `vat_rate`, `scheduled_at`,
/// `created_at`, `updated_at`), and the provided-service snapshot
/// is nested under `service`.
///
/// ## Wire shape (write)
///
/// `OrderedService_API` from `api_models.py` expects a **different**
/// shape on write:
///
/// ```json
/// {
///   "ordered_service_service_id":    1,
///   "ordered_service_quantity":      1,
///   "ordered_service_unit_price":    391.59,
///   "ordered_service_total_price":   391.59,
///   "ordered_service_scheduled_at":  null,
///   "ordered_service_notes":         "...",
///   "resource_requirement_id":       0
/// }
/// ```
///
/// Note the server-side names: `ordered_service_unit_price` (write)
/// vs `unit_price` (read); `ordered_service_total_price` (write) vs
/// `subtotal` (read); `ordered_service_scheduled_at` (write) vs
/// `scheduled_at` (read). `fromJson` reads the read-side names;
/// [toOrderedServiceApiJson] emits the write-side names.
///
/// ## Money
///
/// [unitPrice], [totalPrice], [vatRate], [discountAmount] and
/// [deliveryFee] are [Decimal]. The `double` conversion happens only
/// inside [toOrderedServiceApiJson] / [toJson], at the JSON boundary.
class OrderedService {
  final int id;
  final int cartId;
  final int serviceId;
  final int quantity;

  /// Unit price, in [Decimal].
  final Decimal unitPrice;

  /// Line total (after discount, before or after VAT — server decides),
  /// in [Decimal]. Mirrors the server's `subtotal` / `ordered_service_total_price`.
  final Decimal totalPrice;

  /// VAT rate as a percentage (0–100), in [Decimal].
  final Decimal vatRate;

  /// Absolute discount on this line, in [Decimal]. Null when the
  /// payload carried no discount.
  final Decimal? discountAmount;

  /// Delivery fee for this line, in [Decimal].
  final Decimal deliveryFee;

  final String? deliveryStatus;
  final String? notes;
  final DateTime? scheduledAt;
  final int? resourceRequirementId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Nested `provided_service` snapshot, when the payload inlines it.
  ///
  /// Carries the service's name, description, category, and
  /// resource requirements. Null when the payload only carried the
  /// `service_id` FK.
  final ProvidedService? service;

  OrderedService({
    required this.id,
    required this.cartId,
    required this.serviceId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    Decimal? vatRate,
    this.discountAmount,
    Decimal? deliveryFee,
    this.deliveryStatus,
    this.notes,
    this.scheduledAt,
    this.resourceRequirementId,
    this.createdAt,
    this.updatedAt,
    this.service,
  })  : vatRate = vatRate ?? Decimal.zero,
        deliveryFee = deliveryFee ?? Decimal.zero;

  // ── Derived ──────────────────────────────────────────────────

  bool get hasNotes => notes != null && notes!.isNotEmpty;

  /// True when a scheduled time is recorded.
  bool get hasSchedule => scheduledAt != null;

  /// True when the service line has been delivered.
  bool get isDelivered => (deliveryStatus ?? '').toLowerCase() == 'delivered';

  /// True when the line carries a `provided_service` snapshot.
  bool get hasServiceSnapshot => service != null;

  // ── Read parse ───────────────────────────────────────────────

  /// Parse a service line from the read response.
  ///
  /// Accepts both the flat read shape (see the class docstring) and
  /// the prefixed write shape (for round-trips through local
  /// persistence). Every field is null-coerced — a missing field
  /// becomes a default, never a crash.
  factory OrderedService.fromJson(Map<String, dynamic> json) {
    // Provided-service snapshot, when present.
    ProvidedService? service;
    final serviceRaw = json['service'];
    if (serviceRaw is Map) {
      try {
        service = ProvidedService.fromJson(
          Map<String, dynamic>.from(serviceRaw),
        );
      } catch (_) {
        service = null;
      }
    }

    // Read-side fields first, prefixed write-side names second.
    // The two shapes use `unit_price` vs `ordered_service_unit_price`,
    // `subtotal` vs `ordered_service_total_price`, etc.
    return OrderedService(
      id: (json['ordered_service_id'] as num?)?.toInt() ?? 0,
      cartId: (json['cart_id'] ?? json['ordered_service_cart_id'] as num?)
              ?.toInt() ??
          0,
      serviceId:
          (json['service_id'] ?? json['ordered_service_service_id'] as num?)
                  ?.toInt() ??
              0,
      quantity: (json['ordered_service_quantity'] as num?)?.toInt() ?? 0,
      unitPrice: _readDecimalOrZero(
        json['unit_price'] ?? json['ordered_service_unit_price'],
      ),
      totalPrice: _readDecimalOrZero(
        json['subtotal'] ?? json['ordered_service_total_price'],
      ),
      vatRate: _readDecimalOrZero(json['vat_rate']),
      discountAmount: _readDecimal(json['discount_amount']),
      deliveryFee: _readDecimalOrZero(
        json['ordered_service_delivery_fee'],
      ),
      deliveryStatus: (json['ordered_service_delivery_status'] as String?),
      notes: json['ordered_service_notes'] as String?,
      scheduledAt: _parseDate(
        json['scheduled_at'] ?? json['ordered_service_scheduled_at'],
      ),
      resourceRequirementId: (json['resource_requirement_id'] as num?)?.toInt(),
      createdAt: _parseDate(
        json['created_at'] ?? json['ordered_service_created_at'],
      ),
      updatedAt: _parseDate(
        json['updated_at'] ?? json['ordered_service_updated_at'],
      ),
      service: service,
    );
  }

  // ── Write body ───────────────────────────────────────────────

  /// Body for `OrderedService_API` — the shape the cart create
  /// endpoint expects inside `ordered_services[]`.
  ///
  /// Seven fields, all prefixed `ordered_service_*`:
  ///
  ///   * `ordered_service_service_id`
  ///   * `ordered_service_quantity`
  ///   * `ordered_service_unit_price`
  ///   * `ordered_service_total_price`
  ///   * `ordered_service_scheduled_at` (nullable)
  ///   * `ordered_service_notes`       (nullable)
  ///   * `resource_requirement_id`     (nullable)
  ///
  /// The id, cart id, and timestamps are **not** included — they're
  /// server-owned and silently dropped if sent.
  ///
  /// Monetary values are emitted via [_decimalToWire] so the JSON
  /// number is the shortest round-trip form of the [Decimal].
  Map<String, dynamic> toOrderedServiceApiJson() {
    return {
      'ordered_service_service_id': serviceId,
      'ordered_service_quantity': quantity,
      'ordered_service_unit_price': _decimalToWire(unitPrice),
      'ordered_service_total_price': _decimalToWire(totalPrice),
      if (scheduledAt != null)
        'ordered_service_scheduled_at': scheduledAt!.toIso8601String(),
      'ordered_service_notes': notes ?? '',
      if (resourceRequirementId != null)
        'resource_requirement_id': resourceRequirementId,
    };
  }

  // ── Local persistence ────────────────────────────────────────

  /// Serialises the full ordered-service snapshot for **local
  /// persistence**. Round-trips with [OrderedService.fromJson] because
  /// both sides use the read-side field names. Do **not** send this to
  /// the API — the write contract is
  /// [toOrderedServiceApiJson].
  Map<String, dynamic> toJson() {
    return {
      'ordered_service_id': id,
      'cart_id': cartId,
      'service_id': serviceId,
      'ordered_service_quantity': quantity,
      'unit_price': _decimalToWire(unitPrice),
      'subtotal': _decimalToWire(totalPrice),
      'vat_rate': _decimalToWire(vatRate),
      if (discountAmount != null)
        'discount_amount': _decimalToWire(discountAmount!),
      'ordered_service_delivery_fee': _decimalToWire(deliveryFee),
      if (deliveryStatus != null)
        'ordered_service_delivery_status': deliveryStatus,
      'ordered_service_notes': notes,
      if (scheduledAt != null) 'scheduled_at': scheduledAt!.toIso8601String(),
      if (resourceRequirementId != null)
        'resource_requirement_id': resourceRequirementId,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (service != null) 'service': service!.toJson(),
    };
  }

  // ── copyWith ─────────────────────────────────────────────────

  OrderedService copyWith({
    int? id,
    int? cartId,
    int? serviceId,
    int? quantity,
    Decimal? unitPrice,
    Decimal? totalPrice,
    Decimal? vatRate,
    Decimal? discountAmount,
    Decimal? deliveryFee,
    String? deliveryStatus,
    String? notes,
    DateTime? scheduledAt,
    int? resourceRequirementId,
    DateTime? createdAt,
    DateTime? updatedAt,
    ProvidedService? service,
  }) {
    return OrderedService(
      id: id ?? this.id,
      cartId: cartId ?? this.cartId,
      serviceId: serviceId ?? this.serviceId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      vatRate: vatRate ?? this.vatRate,
      discountAmount: discountAmount ?? this.discountAmount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      notes: notes ?? this.notes,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      resourceRequirementId:
          resourceRequirementId ?? this.resourceRequirementId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      service: service ?? this.service,
    );
  }

  @override
  String toString() {
    return 'OrderedService(id: $id, serviceId: $serviceId, '
        'qty: $quantity, total: DZD$totalPrice)';
  }
}

// ============================================================================
// ServiceUtils
// ============================================================================

class ServiceUtils {
  static List<ProvidedService> parseProvidedServices(List<dynamic> jsonList) {
    return jsonList
        .whereType<Map>()
        .map(
            (json) => ProvidedService.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  static List<OrderedService> parseOrderedServices(List<dynamic> jsonList) {
    return jsonList
        .whereType<Map>()
        .map((json) => OrderedService.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  static Map<int, List<ProvidedService>> groupByCategory(
    List<ProvidedService> services,
  ) {
    final Map<int, List<ProvidedService>> grouped = {};
    for (final service in services) {
      grouped.putIfAbsent(service.categoryId, () => []).add(service);
    }
    return grouped;
  }

  /// Sum of every line's [OrderedService.totalPrice], in [Decimal].
  /// Exact.
  static Decimal calculateCartTotal(List<OrderedService> orderedServices) {
    return orderedServices.fold(
      Decimal.zero,
      (total, service) => total + service.totalPrice,
    );
  }
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

// ============================================================================
// Parse helpers
// ============================================================================

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
