// lib/business/DeliveryBroker.dart

import 'dart:convert';

/// A delivery broker as returned by the delivery service.
///
/// Brokers are the shipping companies a delivery can be dispatched
/// through. A delivery's `delivery_broker_id` points at one of these.
///
/// The wire format flattens the broker's wallet to a foreign key
/// (`delivery_broker_wallet_id`), and carries the pricing rules as a
/// **JSON string** rather than a nested object. Both are parsed here
/// so callers get typed access without re-parsing at every call site.
class DeliveryBroker {
  /// Primary key. Referenced by `Delivery.delivery_broker_id`.
  final int id;

  /// Display name for the UI. Short, human-readable.
  /// e.g. "Yalidine Express".
  final String? label;

  /// Legal or full name. May be longer than [label].
  /// e.g. "Sarl Speed Delivery".
  final String? name;

  /// Full-bleed image, typically a 16:9 or 4:3 photograph.
  final String? imageUrl;

  /// Logo, typically square and transparent.
  final String? logoUrl;

  /// Foreign key into the wallet table. The broker's earnings
  /// account. Null when the broker was created without a wallet,
  /// which shouldn't happen for brokers created through the service
  /// but is tolerated here for robustness.
  final int? walletId;

  /// 0 or 1 in the payload; exposed as a bool.
  /// Unverified brokers are hidden from the shipping picker in the
  /// delivery UI until an admin flips this.
  final bool verified;

  /// Home delivery price. Null when the broker doesn't offer home
  /// delivery, or when the price is negotiated separately.
  final double? homeDeliveryPrice;

  /// Parsed pricing matrix. Null when the field is absent or
  /// malformed — the raw string is preserved in [priceMatrixRaw]
  /// so the caller can decide whether to log or ignore.
  final BrokerPriceMatrix? priceMatrix;

  /// The exact string the server sent, unparsed. Kept for debugging
  /// and for the rare case where a caller needs the raw form.
  final String? priceMatrixRaw;

  const DeliveryBroker({
    required this.id,
    this.label,
    this.name,
    this.imageUrl,
    this.logoUrl,
    this.walletId,
    this.verified = false,
    this.homeDeliveryPrice,
    this.priceMatrix,
    this.priceMatrixRaw,
  });

  // ==================== Prefer the parsed view ====================

  /// The name to show in a list. Prefers [label], falls back to
  /// [name], then to a placeholder that includes the id so the row
  /// isn't blank if the server sent neither.
  String get displayName => (label?.trim().isNotEmpty == true)
      ? label!.trim()
      : (name?.trim().isNotEmpty == true)
          ? name!.trim()
          : 'Broker #$id';

  /// Every price in the matrix, in a stable order, for callers that
  /// want to display the range. Empty when there is no matrix.
  List<double> get basePrices => <double>[
        if (priceMatrix?.homeBase != null) priceMatrix!.homeBase!,
        if (priceMatrix?.stopDeskBase != null) priceMatrix!.stopDeskBase!,
      ];

  // ==================== Parsing ====================

  factory DeliveryBroker.fromJson(dynamic json) {
    if (json is! Map) return DeliveryBroker.empty();

    final map = Map<String, dynamic>.from(json);

    // Price matrix: parse the JSON string once. If it fails, keep
    // the raw string so the failure is visible in logs, but don't
    // blow up the whole broker.
    final rawMatrix = _asString(map['delivery_broker_price_matrix']);
    BrokerPriceMatrix? parsedMatrix;
    if (rawMatrix != null && rawMatrix.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawMatrix);
        if (decoded is Map<String, dynamic>) {
          parsedMatrix = BrokerPriceMatrix.fromJson(decoded);
        }
      } catch (_) {
        // Malformed; leave `parsedMatrix` null and keep the raw
        // string. The caller can log it or surface it in an
        // admin view.
      }
    }

    return DeliveryBroker(
      id: _asIntOrNull(map['id_delivery_broker']) ?? 0,
      label: _asString(map['delivery_broker_label']),
      name: _asString(map['delivery_broker_name']),
      imageUrl: _asString(map['delivery_broker_image_url']),
      logoUrl: _asString(map['delivery_broker_logo_url']),
      walletId: _asIntOrNull(map['delivery_broker_wallet_id']),
      verified: _asBoolFlag(map['verified_delivery_broker']),
      homeDeliveryPrice:
          _asDoubleOrNull(map['delivery_broker_home_delivery_price']),
      priceMatrix: parsedMatrix,
      priceMatrixRaw: rawMatrix,
    );
  }

  /// A blank broker. Useful as a placeholder where a `DeliveryBroker`
  /// is required but unknown.
  factory DeliveryBroker.empty() => const DeliveryBroker(
        id: 0,
        verified: false,
      );

  // ==================== Serialisation ====================

  /// Emit the shape the server accepts on write.
  ///
  /// The server stores the price matrix as a JSON string, so the
  /// nested [priceMatrix] object is re-encoded into the same string
  /// form on the way out. If [priceMatrix] is null, the raw string
  /// (if any) is sent unchanged.
  Map<String, dynamic> toJson() {
    final matrixString = priceMatrix != null
        ? jsonEncode(priceMatrix!.toJson())
        : priceMatrixRaw;

    return <String, dynamic>{
      'id_delivery_broker': id,
      if (label != null) 'delivery_broker_label': label,
      if (name != null) 'delivery_broker_name': name,
      if (imageUrl != null) 'delivery_broker_image_url': imageUrl,
      if (logoUrl != null) 'delivery_broker_logo_url': logoUrl,
      if (walletId != null) 'delivery_broker_wallet_id': walletId,
      'verified_delivery_broker': verified ? 1 : 0,
      if (homeDeliveryPrice != null)
        'delivery_broker_home_delivery_price': homeDeliveryPrice,
      if (matrixString != null) 'delivery_broker_price_matrix': matrixString,
    };
  }

  // ==================== Equality ====================

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DeliveryBroker && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'DeliveryBroker(id: $id, name: $displayName, verified: $verified)';
}

// ==================== Price matrix ====================

/// Parsed form of the JSON string in
/// `delivery_broker.delivery_broker_price_matrix`.
///
/// The wire shape is:
///
/// ```json
/// {
///   "home":     { "base": 400, "per_kg_over_5": 50 },
///   "stopdesk": { "base": 250, "per_kg_over_5": 30 },
///   "regions": {
///     "north_center": 1.00,
///     "north_east":   1.10,
///     "north_west":   1.15,
///     "highlands":    1.25,
///     "south":        1.60
///   }
/// }
/// ```
///
/// `home` and `stopdesk` are the two service tiers the broker
/// offers. `regions` are multipliers applied on top of the base
/// price depending on the destination region.
class BrokerPriceMatrix {
  /// Home delivery base price.
  final double? homeBase;

  /// Home delivery surcharge per kilogram over 5 kg. Null when the
  /// broker doesn't bill weight, or when the field is absent.
  final double? homePerKgOver5;

  /// Stopdesk delivery base price.
  final double? stopDeskBase;

  /// Stopdesk surcharge per kilogram over 5 kg.
  final double? stopDeskPerKgOver5;

  /// Region multipliers, keyed by region name. Empty when the
  /// broker doesn't vary pricing by region.
  final Map<String, double> regionMultipliers;

  const BrokerPriceMatrix({
    this.homeBase,
    this.homePerKgOver5,
    this.stopDeskBase,
    this.stopDeskPerKgOver5,
    this.regionMultipliers = const {},
  });

  factory BrokerPriceMatrix.fromJson(Map<String, dynamic> json) {
    final home = _asMapOrNull(json['home']);
    final stopdesk = _asMapOrNull(json['stopdesk']);
    final regions = _asMapOrNull(json['regions']);

    final multipliers = <String, double>{};
    if (regions != null) {
      for (final entry in regions.entries) {
        final value = _asDoubleOrNull(entry.value);
        if (value != null) multipliers[entry.key] = value;
      }
    }

    return BrokerPriceMatrix(
      homeBase: _asDoubleOrNull(home?['base']),
      homePerKgOver5: _asDoubleOrNull(home?['per_kg_over_5']),
      stopDeskBase: _asDoubleOrNull(stopdesk?['base']),
      stopDeskPerKgOver5: _asDoubleOrNull(stopdesk?['per_kg_over_5']),
      regionMultipliers: multipliers,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (homeBase != null || homePerKgOver5 != null)
          'home': {
            if (homeBase != null) 'base': homeBase,
            if (homePerKgOver5 != null) 'per_kg_over_5': homePerKgOver5,
          },
        if (stopDeskBase != null || stopDeskPerKgOver5 != null)
          'stopdesk': {
            if (stopDeskBase != null) 'base': stopDeskBase,
            if (stopDeskPerKgOver5 != null) 'per_kg_over_5': stopDeskPerKgOver5,
          },
        if (regionMultipliers.isNotEmpty) 'regions': regionMultipliers,
      };

  /// Effective home delivery price for a given weight and region.
  ///
  /// Returns null when the broker has no home base price, or when
  /// [region] is supplied but not present in the multiplier map.
  double? homePriceFor({
    required double weightKg,
    String? region,
  }) {
    final base = homeBase;
    if (base == null) return null;

    final overage = weightKg > 5 ? weightKg - 5 : 0.0;
    final weightCharge = overage * (homePerKgOver5 ?? 0);

    double multiplier = 1.0;
    if (region != null) {
      final m = regionMultipliers[region];
      if (m == null) return null;
      multiplier = m;
    }

    return (base + weightCharge) * multiplier;
  }

  /// Effective stopdesk delivery price for a given weight and region.
  double? stopDeskPriceFor({
    required double weightKg,
    String? region,
  }) {
    final base = stopDeskBase;
    if (base == null) return null;

    final overage = weightKg > 5 ? weightKg - 5 : 0.0;
    final weightCharge = overage * (stopDeskPerKgOver5 ?? 0);

    double multiplier = 1.0;
    if (region != null) {
      final m = regionMultipliers[region];
      if (m == null) return null;
      multiplier = m;
    }

    return (base + weightCharge) * multiplier;
  }

  @override
  String toString() =>
      'BrokerPriceMatrix(home: $homeBase, stopdesk: $stopDeskBase, '
      'regions: ${regionMultipliers.length})';
}

// ==================== Parse helpers ====================

int? _asIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is num) return v.toInt();
  if (v is String) {
    final asInt = int.tryParse(v);
    if (asInt != null) return asInt;
    return double.tryParse(v)?.toInt();
  }
  return null;
}

double? _asDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

String? _asString(dynamic v) {
  if (v == null) return null;
  if (v is String) return v.isEmpty ? null : v;
  return v.toString();
}

Map<String, dynamic>? _asMapOrNull(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  return null;
}

bool _asBoolFlag(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is num) return v != 0;
  if (v is String) {
    final lower = v.toLowerCase();
    return lower == 'true' || lower == '1';
  }
  return false;
}
