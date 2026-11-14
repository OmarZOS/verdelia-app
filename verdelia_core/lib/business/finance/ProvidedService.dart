// lib/business/finance/ProvidedService.dart

import 'dart:convert';

import 'package:decimal/decimal.dart';

import '../NamingContribution.dart';

// ==================================================================
// Decimal helpers
// ==================================================================

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

// ==================================================================
// ProvidedServiceCategory
// ==================================================================

/// Category for a provided service.
///
/// Read shape (from `provided_service_category` in the standalone
/// categories endpoint, or an inline `category` / `provided_service_category`
/// snapshot on a service):
///
/// ```json
/// {
///   "id_provided_service_category": 3,
///   "provided_service_category_name": "food.dining.catering",
///   "provided_service_category_description": "...",
///   "provided_service_category_icon_url": null,
///   "provided_service_category_naming_ref": 12,
///   "provided_service_category_avg_duration": 60,
///   "naming_contribution": { ... }
/// }
/// ```
///
/// The `fromJson` accepts the flat forms (`id`, `name`, `category_id`)
/// as fallbacks because inline echoes on the operations payload use the
/// short names.
class ProvidedServiceCategory {
  final int id;
  final String name;
  final String description;
  final String? iconUrl;
  final int? namingRef;
  final int? avgDuration;
  final NamingContribution? naming;

  const ProvidedServiceCategory({
    required this.id,
    required this.name,
    this.description = '',
    this.iconUrl,
    this.namingRef,
    this.avgDuration,
    this.naming,
  });

  factory ProvidedServiceCategory.empty() => const ProvidedServiceCategory(
        id: 0,
        name: '',
      );

  factory ProvidedServiceCategory.fromJson(Map<String, dynamic> json) {
    NamingContribution? naming;
    final namingJson = json['naming_contribution'];
    if (namingJson is Map) {
      naming = NamingContribution.fromJson(
        Map<String, dynamic>.from(namingJson),
      );
    }

    return ProvidedServiceCategory(
      // Accept both wire shapes — the standalone category endpoint uses
      // `provided_service_category_id`; inline echoes use `id` or
      // `category_id`.
      id: _asInt(
        json['provided_service_category_id'] ??
            json['id_provided_service_category'] ??
            json['id'] ??
            json['category_id'],
      ),
      name: _asString(
        json['provided_service_category_name'] ??
            json['name'] ??
            json['category_name'],
      ),
      description: _asString(
        json['provided_service_category_description'] ?? json['description'],
      ),
      iconUrl: _asStringOrNull(
        json['provided_service_category_icon_url'] ?? json['icon_url'],
      ),
      namingRef: _asIntOrNull(
        json['provided_service_category_naming_ref'] ?? json['naming_ref'],
      ),
      avgDuration: _asIntOrNull(
        json['provided_service_category_avg_duration'] ?? json['avg_duration'],
      ),
      naming: naming,
    );
  }

  static List<ProvidedServiceCategory> listFromJson(dynamic json) {
    if (json is! List) return const [];
    return json
        .whereType<Map>()
        .map((e) =>
            ProvidedServiceCategory.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  /// Serialises the category for **local persistence** and for
  /// use as a nested snapshot. Round-trips with [fromJson].
  ///
  /// Not an API body — there is no dedicated write endpoint for
  /// categories in the current contract.
  Map<String, dynamic> toJson() => {
        'provided_service_category_id': id,
        'provided_service_category_name': name,
        'provided_service_category_description': description,
        if (iconUrl != null) 'provided_service_category_icon_url': iconUrl,
        if (namingRef != null)
          'provided_service_category_naming_ref': namingRef,
        if (avgDuration != null)
          'provided_service_category_avg_duration': avgDuration,
        if (naming != null) 'naming_contribution': naming!.toJson(),
      };

  String nameFor(String lang) {
    final resolved = naming?.nameFor(lang) ?? '';
    if (resolved.isNotEmpty) return resolved;
    return humanizeCanonicalKey(name);
  }

  String? get resolvedIconUrl {
    final fromNaming = naming?.iconUrl;
    if (fromNaming != null && fromNaming.isNotEmpty) return fromNaming;
    return iconUrl;
  }

  ProvidedServiceCategory withNaming(NamingContribution? value) {
    return ProvidedServiceCategory(
      id: id,
      name: name,
      description: description,
      iconUrl: iconUrl,
      namingRef: namingRef,
      avgDuration: avgDuration,
      naming: value ?? naming,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProvidedServiceCategory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id;

  @override
  String toString() => 'ProvidedServiceCategory(id: $id, name: $name, '
      'naming: ${naming != null})';
}

String humanizeCanonicalKey(String key) {
  if (key.isEmpty) return '';
  final leaf = key.split('.').last;
  return leaf
      .split(RegExp(r'[_\s]+'))
      .where((s) => s.isNotEmpty)
      .map((s) => s[0].toUpperCase() + s.substring(1))
      .join(' ');
}

// ==================================================================
// StaffRole
// ==================================================================

/// One staff role that a service can require.
///
/// Wire shape (from the standalone `staff_role` endpoint):
///
/// ```json
/// {
///   "id_staff_role": 1,
///   "staff_role_service_category_ref": 3,
///   "staff_role_name": "Senior cleaner",
///   "staff_role_icon_url": null,
///   "staff_role_description": "...",
///   "staff_role_naming_ref": 5,
///   "naming_contribution": { ... }
/// }
/// ```
class StaffRole {
  final int id;
  final int categoryId;
  final String name;
  final String? iconUrl;
  final String? description;
  final int? namingRef;
  final NamingContribution? naming;

  const StaffRole({
    required this.id,
    required this.categoryId,
    required this.name,
    this.iconUrl,
    this.description,
    this.namingRef,
    this.naming,
  });

  factory StaffRole.empty() => const StaffRole(
        id: 0,
        categoryId: 0,
        name: '',
      );

  factory StaffRole.fromJson(Map<String, dynamic> json) {
    NamingContribution? naming;
    final namingJson = json['naming_contribution'];
    if (namingJson is Map) {
      naming = NamingContribution.fromJson(
        Map<String, dynamic>.from(namingJson),
      );
    }

    return StaffRole(
      id: _asInt(json['id_staff_role']),
      categoryId: _asInt(json['staff_role_service_category_ref']),
      name: _asString(json['staff_role_name']),
      iconUrl: _asStringOrNull(json['staff_role_icon_url']),
      description: _asStringOrNull(json['staff_role_description']),
      namingRef: _asIntOrNull(json['staff_role_naming_ref']),
      naming: naming,
    );
  }

  /// Serialises the role for **local persistence**. Round-trips with
  /// [fromJson]. Not an API body — there is no dedicated write
  /// endpoint for staff roles in the current contract.
  Map<String, dynamic> toJson() => {
        'id_staff_role': id,
        'staff_role_service_category_ref': categoryId,
        'staff_role_name': name,
        if (iconUrl != null) 'staff_role_icon_url': iconUrl,
        if (description != null) 'staff_role_description': description,
        if (namingRef != null) 'staff_role_naming_ref': namingRef,
        if (naming != null) 'naming_contribution': naming!.toJson(),
      };

  String nameFor(String lang) {
    final resolved = naming?.nameFor(lang) ?? '';
    if (resolved.isNotEmpty) return resolved;
    return name;
  }

  String? get resolvedIconUrl {
    final fromNaming = naming?.iconUrl;
    if (fromNaming != null && fromNaming.isNotEmpty) return fromNaming;
    return iconUrl;
  }

  StaffRole withNaming(NamingContribution? value) {
    return StaffRole(
      id: id,
      categoryId: categoryId,
      name: name,
      iconUrl: iconUrl,
      description: description,
      namingRef: namingRef,
      naming: value ?? naming,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaffRole && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id;

  @override
  String toString() =>
      'StaffRole(id: $id, name: $name, naming: ${naming != null})';
}

// ==================================================================
// ProvidedService
// ==================================================================

/// A single service offered by a provider.
///
/// ## Read shape
///
/// Two shapes arrive from the API:
///
/// 1. **Operations response** (from `ordered_service.service` and any
///    inline echo): flat field names —
///    `idprovided_service`, `unit_price`, `base_price`,
///    `category_id`, `provider_id`, `service_resource_requirement[]`,
///    `created_at`, `updated_at`, `deleted_at`.
///
/// 2. **Standalone `/business/services` response**: prefixed names —
///    `provided_service_id`, `provided_service_base_price`,
///    `provided_service_final_price`,
///    `provided_service_category_id`, `provided_service_product_provider_id`,
///    `requirements[]`, `staff_requirements[]`.
///
/// `fromJson` accepts both. Callers don't have to know which endpoint
/// produced the payload.
///
/// ## Write shape
///
/// `ProvidedService_API` — see [toServiceApiJson]. Every field name is
/// prefixed `provided_service_*`; there is no `vat_rate`, no timestamps,
/// no `idprovided_service` on the write model (those are server-owned).
///
/// ## Money
///
/// [basePrice], [finalPrice], [vatRate], [totalResourceCost],
/// [totalStaffCost], [totalCost], [discountPercentage] and
/// [profitMargin] are [Decimal]. The `double` conversion happens only
/// inside [toServiceApiJson] / [toJson], at the JSON boundary.
class ProvidedService {
  final int id;
  final String name;
  final String description;
  final int categoryId;
  final int productProviderId;

  /// Base (catalog) price, in [Decimal].
  final Decimal basePrice;

  /// Final (sell) price, in [Decimal].
  final Decimal finalPrice;

  final int actualDuration;

  /// VAT rate as a percentage (0–100), in [Decimal]. Present on the DB
  /// row and the read payload; **not** on `ProvidedService_API`, so
  /// it's read-only on the write path.
  final Decimal vatRate;

  final ProvidedServicePricingConfig pricingConfig;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final List<ServiceResourceRequirement> resourceRequirements;
  final List<ServiceStaffRequirement> staffRequirements;
  final ProvidedServiceCategory? category;

  ProvidedService({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.productProviderId,
    required this.basePrice,
    required this.finalPrice,
    required this.actualDuration,
    Decimal? vatRate,
    required this.pricingConfig,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.resourceRequirements = const [],
    this.staffRequirements = const [],
    this.category,
  }) : vatRate = vatRate ?? Decimal.zero;

  // ==================== Computed getters ====================

  /// Percentage discount from base to final, in [Decimal]. Returns
  /// `Decimal.zero` when [basePrice] is zero.
  Decimal get discountPercentage {
    if (basePrice == Decimal.zero) return Decimal.zero;
    return ((basePrice - finalPrice) / basePrice)
            .toDecimal(scaleOnInfinitePrecision: 2) *
        _hundred;
  }

  String get durationFormatted {
    final hours = actualDuration ~/ 60;
    final minutes = actualDuration % 60;
    if (hours == 0) return '${minutes}min';
    return '${hours}h ${minutes}min';
  }

  /// Sum of all resource-requirement line costs, in [Decimal].
  Decimal get totalResourceCost {
    return resourceRequirements.fold(
      Decimal.zero,
      (total, requirement) => total + requirement.totalCost,
    );
  }

  /// Sum of all staff-requirement line costs, in [Decimal].
  ///
  /// Uses the average head count (`(min + max) / 2`), matching what
  /// [ServiceStaffRequirement.averageCost] exposes. If you need the
  /// worst-case cost, sum [ServiceStaffRequirement.maxCost] instead.
  Decimal get totalStaffCost {
    return staffRequirements.fold(
      Decimal.zero,
      (total, requirement) => total + requirement.averageCost,
    );
  }

  Decimal get totalCost => totalResourceCost + totalStaffCost;

  /// Margin as a percentage, in [Decimal]. Returns `Decimal.zero` when
  /// [finalPrice] is zero.
  Decimal get profitMargin {
    if (finalPrice == Decimal.zero) return Decimal.zero;
    return ((finalPrice - totalCost) / finalPrice)
            .toDecimal(scaleOnInfinitePrecision: 2) *
        _hundred;
  }

  String categoryNameFor(String lang) => category?.nameFor(lang) ?? '';
  String get categoryKey => category?.name ?? '';
  String? get categoryIconUrl => category?.resolvedIconUrl;

  // ==================== Factories ====================

  factory ProvidedService.empty() {
    return ProvidedService(
      id: 0,
      name: '',
      description: '',
      categoryId: 1,
      productProviderId: 1,
      basePrice: Decimal.zero,
      finalPrice: Decimal.zero,
      actualDuration: 0,
      pricingConfig: ProvidedServicePricingConfig(),
      isActive: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Parse a service from **either** the operations-response shape
  /// (flat `unit_price`, `base_price`, `idprovided_service`,
  /// `category_id`, `provider_id`, `service_resource_requirement`)
  /// or the standalone `GET /business/services` shape (prefixed
  /// `provided_service_*` names). Missing fields fall back to the
  /// other shape.
  factory ProvidedService.fromJson(Map<String, dynamic> json) {
    final int id = _asInt(
      json['idprovided_service'] ?? json['provided_service_id'],
    );
    final String name = _asString(
      json['provided_service_name'] ?? json['name'],
    );
    final String description = _asString(
      json['provided_service_description'] ?? json['description'],
    );
    final int categoryId = _asInt(
      json['category_id'] ?? json['provided_service_category_id'],
    );
    final int productProviderId = _asInt(
      json['provider_id'] ?? json['provided_service_product_provider_id'],
    );

    // The operations shape carries `base_price` / `unit_price`; the
    // standalone endpoint carries `provided_service_base_price` /
    // `provided_service_final_price`.
    final Decimal basePrice = _readDecimalOrZero(
      json['base_price'] ?? json['provided_service_base_price'],
    );
    final Decimal finalPrice = _readDecimalOrZero(
      json['unit_price'] ?? json['provided_service_final_price'],
    );
    final Decimal vatRate = _readDecimalOrZero(json['vat_rate']);

    final int actualDuration = _asInt(
      json['provided_service_actual_duration'] ?? json['actual_duration'],
    );

    // `provided_service_is_active` can be bool or 1/0.
    final isActiveRaw = json['provided_service_is_active'] ?? json['is_active'];
    final bool isActive;
    if (isActiveRaw is bool) {
      isActive = isActiveRaw;
    } else if (isActiveRaw is num) {
      isActive = isActiveRaw == 1;
    } else {
      isActive = false;
    }

    // Pricing config: empty string (operations shape) → default;
    // JSON string → decode; map → parse.
    final pricingConfigValue =
        json['provided_service_pricing_config'] ?? json['pricing_config'];
    ProvidedServicePricingConfig pricingConfig;
    if (pricingConfigValue is String && pricingConfigValue.trim().isEmpty) {
      pricingConfig = ProvidedServicePricingConfig();
    } else if (pricingConfigValue is String) {
      try {
        final parsed = jsonDecode(pricingConfigValue);
        pricingConfig = parsed is Map<String, dynamic>
            ? ProvidedServicePricingConfig.fromJson(parsed)
            : ProvidedServicePricingConfig();
      } catch (_) {
        pricingConfig = ProvidedServicePricingConfig();
      }
    } else if (pricingConfigValue is Map) {
      pricingConfig = ProvidedServicePricingConfig.fromJson(
        Map<String, dynamic>.from(pricingConfigValue),
      );
    } else {
      pricingConfig = ProvidedServicePricingConfig();
    }

    // Timestamps: operations shape uses `created_at`, standalone uses
    // `provided_service_created_at`.
    final DateTime createdAt = _parseDate(
      json['created_at'] ?? json['provided_service_created_at'],
    );
    final DateTime updatedAt = _parseDate(
      json['updated_at'] ?? json['provided_service_updated_at'],
    );
    final DateTime? deletedAt = _parseDateOrNull(
      json['deleted_at'] ?? json['provided_service_deleted_at'],
    );

    // Resource requirements: both keys are present in the ecosystem
    // (`service_resource_requirement` in the operations payload,
    // `requirements` in some endpoints, and `service_resource_requirement`
    // in the standalone endpoint).
    final resourceRequirements = <ServiceResourceRequirement>[];
    for (final key in const [
      'service_resource_requirement',
      'requirements',
    ]) {
      final raw = json[key];
      if (raw is List) {
        resourceRequirements.addAll(
          raw.whereType<Map>().map(
                (e) => ServiceResourceRequirement.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              ),
        );
      }
    }

    // Staff requirements — same story.
    final staffRequirements = <ServiceStaffRequirement>[];
    for (final key in const [
      'service_staff_requirement',
      'staff_requirements',
    ]) {
      final raw = json[key];
      if (raw is List) {
        staffRequirements.addAll(
          raw.whereType<Map>().map(
                (e) => ServiceStaffRequirement.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              ),
        );
      }
    }

    // Nested category if the payload inlined it.
    final categoryRaw = json['provided_service_category'] ?? json['category'];
    final ProvidedServiceCategory? category = categoryRaw is Map
        ? ProvidedServiceCategory.fromJson(
            Map<String, dynamic>.from(categoryRaw),
          )
        : null;

    return ProvidedService(
      id: id,
      name: name,
      description: description,
      categoryId: categoryId,
      productProviderId: productProviderId,
      basePrice: basePrice,
      finalPrice: finalPrice,
      actualDuration: actualDuration,
      vatRate: vatRate,
      pricingConfig: pricingConfig,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
      resourceRequirements: resourceRequirements,
      staffRequirements: staffRequirements,
      category: category,
    );
  }

  // ==================== Serialisation ====================

  /// The ten fields of `ProvidedService_API`.
  ///
  /// Every key here exists on the Pydantic `ProvidedService_API` model.
  /// The flat `idprovided_service` / `vat_rate` / `created_at` /
  /// `updated_at` / `deleted_at` fields the class carries are ORM
  /// columns — server-owned on create, read-only otherwise. Sending
  /// them is silently dropped.
  ///
  /// `provided_service_pricing_config` is a `str` on the API
  /// (`Optional[str] = ""`). [ProvidedServicePricingConfig.toJsonString]
  /// serialises the config to a JSON string the server parses back into
  /// the JSON column.
  ///
  /// Monetary values are emitted via [_decimalToWire] so the JSON
  /// number is the shortest round-trip form of the [Decimal].
  Map<String, dynamic> toServiceApiJson() {
    return {
      'provided_service_product_provider_id': productProviderId,
      'provided_service_name': name,
      'provided_service_description': description,
      'category_id': categoryId,
      'provided_service_base_price': _decimalToWire(basePrice),
      'provided_service_final_price': _decimalToWire(finalPrice),
      'provided_service_actual_duration': actualDuration,
      'provided_service_is_active': isActive,
      'provided_service_pricing_config': pricingConfig.toJsonString(),
    };
  }

  /// Body for `POST /business/services` and `PUT /business/services/{id}`.
  ///
  /// Shape (`Body_create_service_api_v1_business_services_post`):
  ///
  /// ```json
  /// {
  ///   "service":            { ...ProvidedService_API... },
  ///   "requirements":       [ ...ServiceResourceRequirement_API... ],
  ///   "staff_requirements": [ ...ServiceStaffRequirement_API... ]
  /// }
  /// ```
  ///
  /// The resource-requirement fields are prefixed `resource_requirement_*`
  /// — **not** `service_resource_requirement_*`. The current server model
  /// rejects the latter prefix with 422 (or silently drops it if the
  /// Pydantic model has `extra='ignore'`). See
  /// [ServiceResourceRequirement.toRequirementApiJson].
  ///
  /// The staff-requirement fields are prefixed `service_staff_requirement_*`
  /// — the same prefix the ORM and payload use. The server validates
  /// `service_staff_requirement_role > 0`; a role of 0 is rejected with
  /// 422. See [ServiceStaffRequirement.toStaffApiJson].
  Map<String, dynamic> toCreateJson() {
    return {
      'service': toServiceApiJson(),
      'requirements':
          resourceRequirements.map((r) => r.toRequirementApiJson()).toList(),
      'staff_requirements':
          staffRequirements.map((s) => s.toStaffApiJson()).toList(),
    };
  }

  /// The full snapshot for **local persistence**.
  ///
  /// Round-trips with [ProvidedService.fromJson]. Do **not** send this
  /// to the API — the write contract is [toServiceApiJson] /
  /// [toCreateJson].
  ///
  /// Field names here intentionally use the read-payload names (flat
  /// `idprovided_service`, `unit_price`, `base_price`, ...) so that
  /// `fromJson(toJson())` reproduces the same object.
  Map<String, dynamic> toJson() {
    return {
      'idprovided_service': id,
      'provided_service_name': name,
      'provided_service_description': description,
      'category_id': categoryId,
      'provider_id': productProviderId,
      'base_price': _decimalToWire(basePrice),
      'unit_price': _decimalToWire(finalPrice),
      'vat_rate': _decimalToWire(vatRate),
      'provided_service_actual_duration': actualDuration,
      'provided_service_pricing_config': pricingConfig.toJsonString(),
      'provided_service_is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
      'service_resource_requirement':
          resourceRequirements.map((r) => r.toJson()).toList(),
      'service_staff_requirement':
          staffRequirements.map((s) => s.toJson()).toList(),
      if (category != null) 'provided_service_category': category!.toJson(),
    };
  }

  ProvidedService copyWith({
    int? id,
    String? name,
    String? description,
    int? categoryId,
    int? productProviderId,
    Decimal? basePrice,
    Decimal? finalPrice,
    int? actualDuration,
    Decimal? vatRate,
    ProvidedServicePricingConfig? pricingConfig,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    List<ServiceResourceRequirement>? resourceRequirements,
    List<ServiceStaffRequirement>? staffRequirements,
    ProvidedServiceCategory? category,
  }) {
    return ProvidedService(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      productProviderId: productProviderId ?? this.productProviderId,
      basePrice: basePrice ?? this.basePrice,
      finalPrice: finalPrice ?? this.finalPrice,
      actualDuration: actualDuration ?? this.actualDuration,
      vatRate: vatRate ?? this.vatRate,
      pricingConfig: pricingConfig ?? this.pricingConfig,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      resourceRequirements: resourceRequirements ?? this.resourceRequirements,
      staffRequirements: staffRequirements ?? this.staffRequirements,
      category: category ?? this.category,
    );
  }

  ProvidedService withCategory(ProvidedServiceCategory? value) =>
      copyWith(category: value ?? category);

  @override
  String toString() {
    return 'ProvidedService(id: $id, name: $name, category: $categoryId, '
        'price: DZD$finalPrice, resources: ${resourceRequirements.length}, '
        'staff: ${staffRequirements.length})';
  }
}

// ==================================================================
// ServiceResourceRequirement
// ==================================================================

/// One resource requirement on a service.
///
/// ## Read shape (from `service_resource_requirement[]` on the operations
/// payload):
///
/// ```json
/// {
///   "service_id": 1,
///   "service_resource_requirement_name": "Cleaning supplies",
///   "service_resource_requirement_quantity": 10,
///   "service_resource_requirement_notes": "...",
///   "unit_price": 132.4,
///   "product_id": 1,
///   "id_service_resource_requirement": 1,
///   "service_resource_requirement_type": "tool",
///   "service_resource_requirement_is_consumable": 1,
///   "created_at": "...",
///   "updated_at": "..."
/// }
/// ```
///
/// ## Write shape (`ServiceResourceRequirement_API`):
///
/// ```json
/// {
///   "resource_requirement_id":            0,
///   "resource_requirement_service_id":    1,
///   "resource_requirement_name":          "...",
///   "resource_requirement_type":          "tool",
///   "resource_requirement_quantity":      10,
///   "resource_requirement_cost_per_unit": 132.4,
///   "resource_requirement_is_consumable": true,
///   "resource_requirement_notes":         "...",
///   "resource_requirement_product_ref":   1
/// }
/// ```
///
/// The write prefix is `resource_requirement_*` — **not**
/// `service_resource_requirement_*`. Sending the read names on write
/// silently drops every field on the server.
///
/// ## Money
///
/// [quantity] and [costPerUnit] are [Decimal]; [totalCost] is
/// `quantity × costPerUnit` in [Decimal].
class ServiceResourceRequirement {
  final int id;
  final String name;
  final String type;

  /// Quantity of the resource consumed. [Decimal] because it multiplies
  /// [costPerUnit] and the result must be exact.
  final Decimal quantity;

  final bool isConsumable;
  final int? productRef;
  final int serviceId;

  /// Cost per unit, in [Decimal].
  final Decimal costPerUnit;

  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceResourceRequirement({
    required this.id,
    required this.name,
    required this.type,
    required this.quantity,
    required this.isConsumable,
    this.productRef,
    required this.serviceId,
    required this.costPerUnit,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Decimal get totalCost => costPerUnit * quantity;

  factory ServiceResourceRequirement.fromJson(Map<String, dynamic> json) {
    return ServiceResourceRequirement(
      id: _asInt(
        json['id_service_resource_requirement'] ??
            json['service_resource_requirement_id'],
      ),
      name: _asString(json['service_resource_requirement_name']),
      type: _asString(json['service_resource_requirement_type']),
      quantity: _readDecimalOrZero(
        json['service_resource_requirement_quantity'],
      ),
      isConsumable:
          _asBoolInt(json['service_resource_requirement_is_consumable']),
      productRef: _asIntOrNull(
        json['product_id'] ?? json['service_resource_requirement_product_ref'],
      ),
      serviceId: _asInt(
        json['service_id'] ?? json['service_resource_requirement_service_id'],
      ),
      costPerUnit: _readDecimalOrZero(
        json['unit_price'] ??
            json['service_resource_requirement_cost_per_unit'],
      ),
      notes: _asStringOrNull(json['service_resource_requirement_notes']),
      createdAt: _parseDate(
        json['created_at'] ?? json['service_resource_requirement_created_at'],
      ),
      updatedAt: _parseDate(
        json['updated_at'] ?? json['service_resource_requirement_updated_at'],
      ),
    );
  }

  /// The nine fields of `ServiceResourceRequirement_API`.
  ///
  /// Every key here is prefixed `resource_requirement_*` (not
  /// `service_resource_requirement_*` — that's the ORM column name
  /// and the read-payload key). The prefix change is what makes the
  /// server actually persist the requirement; without it, every field
  /// is silently dropped.
  Map<String, dynamic> toRequirementApiJson() {
    return {
      'resource_requirement_id': id,
      'resource_requirement_service_id': serviceId,
      'resource_requirement_name': name,
      'resource_requirement_type': type,
      'resource_requirement_quantity': _decimalToWire(quantity),
      'resource_requirement_cost_per_unit': _decimalToWire(costPerUnit),
      'resource_requirement_is_consumable': isConsumable,
      'resource_requirement_notes': notes ?? '',
      'resource_requirement_product_ref': productRef ?? 0,
    };
  }

  /// The full snapshot for **local persistence**. Round-trips with
  /// [fromJson]. Uses the read-payload field names (the
  /// `service_resource_requirement_*` prefix).
  Map<String, dynamic> toJson() {
    return {
      'id_service_resource_requirement': id,
      'service_resource_requirement_name': name,
      'service_resource_requirement_type': type,
      'service_resource_requirement_quantity': _decimalToWire(quantity),
      'service_resource_requirement_is_consumable': isConsumable ? 1 : 0,
      'product_id': productRef,
      'service_id': serviceId,
      'unit_price': _decimalToWire(costPerUnit),
      'service_resource_requirement_notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

// ==================================================================
// ServiceStaffRequirement
// ==================================================================

/// One staff requirement on a service.
///
/// ## Read shape
///
/// Both the prefixed write shape (`service_staff_requirement_*`)
/// and a possible short-form read shape (`min_count`, `role`, ...)
/// are accepted. `staff_role` may be inlined.
///
/// ## Write shape (`ServiceStaffRequirement_API`):
///
/// ```json
/// {
///   "service_staff_requirement_id":              0,
///   "service_staff_requirement_service_id":      1,
///   "service_staff_requirement_role":            3,
///   "service_staff_requirement_notes":           "",
///   "service_staff_requirement_min_count":       1,
///   "service_staff_requirement_max_count":       3,
///   "service_staff_requirement_hourly_rate":     45.0,
///   "service_staff_requirement_allocated_hours": 4.0
/// }
/// ```
///
/// The API rejects `service_staff_requirement_role <= 0` with 422.
/// Callers must ensure the role is set before sending the create
/// payload.
///
/// ## Counts vs money
///
/// [minCount] and [maxCount] are head counts — `int`, not `Decimal`.
/// Everything that participates in money arithmetic ([hourlyRate],
/// [allocatedHours], [minCost], [maxCost], [averageCost]) is [Decimal].
class ServiceStaffRequirement {
  final int id;
  final int serviceId;

  /// Minimum head count — an integer, not money.
  final int minCount;

  /// Maximum head count — an integer, not money.
  final int maxCount;

  final int role;

  /// Hours allocated to this requirement. [Decimal] because it multiplies
  /// [hourlyRate].
  final Decimal allocatedHours;

  /// Hourly rate, in [Decimal].
  final Decimal hourlyRate;

  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final StaffRole? staffRole;

  ServiceStaffRequirement({
    required this.id,
    required this.serviceId,
    required this.minCount,
    required this.maxCount,
    required this.role,
    required this.allocatedHours,
    required this.hourlyRate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.staffRole,
  });

  Decimal get minCost =>
      hourlyRate * allocatedHours * Decimal.fromInt(minCount);

  Decimal get maxCost =>
      hourlyRate * allocatedHours * Decimal.fromInt(maxCount);

  /// Average head count, in [Decimal] — `(min + max) / 2`. Uses the
  /// average because head count is an integer range, and using either
  /// bound alone biases the cost estimate.
  Decimal get averageCost {
    final avg = ((Decimal.fromInt(minCount) + Decimal.fromInt(maxCount)) /
            Decimal.fromInt(2))
        .toDecimal(scaleOnInfinitePrecision: 2);
    return hourlyRate * allocatedHours * avg;
  }

  String roleNameFor(String lang) => staffRole?.nameFor(lang) ?? '';
  String? get roleIconUrl => staffRole?.resolvedIconUrl;

  ServiceStaffRequirement withRole(StaffRole? value) {
    return ServiceStaffRequirement(
      id: id,
      serviceId: serviceId,
      minCount: minCount,
      maxCount: maxCount,
      role: role,
      allocatedHours: allocatedHours,
      hourlyRate: hourlyRate,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      staffRole: value ?? staffRole,
    );
  }

  factory ServiceStaffRequirement.fromJson(Map<String, dynamic> json) {
    final roleRaw = json['staff_role'];
    final StaffRole? staffRole = roleRaw is Map
        ? StaffRole.fromJson(Map<String, dynamic>.from(roleRaw))
        : null;

    return ServiceStaffRequirement(
      id: _asInt(
        json['service_staff_requirement_id'] ??
            json['id_service_staff_requirement'],
      ),
      serviceId: _asInt(
        json['service_staff_requirement_service_id'] ?? json['service_id'],
      ),
      minCount: _asInt(
        json['service_staff_requirement_min_count'] ?? json['min_count'],
      ),
      maxCount: _asInt(
        json['service_staff_requirement_max_count'] ?? json['max_count'],
      ),
      role: _asInt(
        json['service_staff_requirement_role'] ?? json['role'],
      ),
      allocatedHours: _readDecimalOrZero(
        json['service_staff_requirement_allocated_hours'] ??
            json['allocated_hours'],
      ),
      hourlyRate: _readDecimalOrZero(
        json['service_staff_requirement_hourly_rate'] ?? json['hourly_rate'],
      ),
      notes: _asStringOrNull(
        json['service_staff_requirement_notes'] ?? json['notes'],
      ),
      createdAt: _parseDate(
        json['created_at'] ?? json['service_staff_requirement_created_at'],
      ),
      updatedAt: _parseDate(
        json['updated_at'] ?? json['service_staff_requirement_updated_at'],
      ),
      staffRole: staffRole,
    );
  }

  /// The eight fields of `ServiceStaffRequirement_API`.
  ///
  /// The timestamps and the nested `staff_role` are **not** on the
  /// API model and are dropped here. The `role` value must be > 0
  /// for the server to accept the row — the API validator rejects 0
  /// with a 422.
  Map<String, dynamic> toStaffApiJson() {
    return {
      'service_staff_requirement_id': id,
      'service_staff_requirement_service_id': serviceId,
      'service_staff_requirement_role': role,
      'service_staff_requirement_notes': notes ?? '',
      'service_staff_requirement_min_count': minCount,
      'service_staff_requirement_max_count': maxCount,
      'service_staff_requirement_hourly_rate': _decimalToWire(hourlyRate),
      'service_staff_requirement_allocated_hours':
          _decimalToWire(allocatedHours),
    };
  }

  /// The full snapshot for **local persistence**. Round-trips with
  /// [fromJson]. Includes the timestamps and the nested `staff_role`
  /// so a subsequent read after persistence reproduces the same
  /// object.
  Map<String, dynamic> toJson() {
    return {
      'service_staff_requirement_id': id,
      'service_staff_requirement_service_id': serviceId,
      'service_staff_requirement_min_count': minCount,
      'service_staff_requirement_max_count': maxCount,
      'service_staff_requirement_role': role,
      'service_staff_requirement_allocated_hours':
          _decimalToWire(allocatedHours),
      'service_staff_requirement_hourly_rate': _decimalToWire(hourlyRate),
      'service_staff_requirement_notes': notes,
      'service_staff_requirement_created_at': createdAt.toIso8601String(),
      'service_staff_requirement_updated_at': updatedAt.toIso8601String(),
      if (staffRole != null) 'staff_role': staffRole!.toJson(),
    };
  }
}

// ==================================================================
// ProvidedServicePricingConfig
// ==================================================================

/// Free-form pricing config carried on `provided_service_pricing_config`.
///
/// Stored as a JSON column on the DB; exposed as a `str` on the API.
/// [toJsonString] produces the string the server expects.
class ProvidedServicePricingConfig {
  final String? recommendedAge;
  final String? recommendedFrequency;
  final String? ageGroup;
  final String? sampleType;
  final bool? specialistConsultation;
  final bool? governmentFunded;
  final bool? consultationIncluded;
  final bool? digitalImaging;
  final List<String>? materialOptions;
  final List<String>? includes;
  final Map<String, dynamic>? additionalConfig;

  ProvidedServicePricingConfig({
    this.recommendedAge,
    this.recommendedFrequency,
    this.ageGroup,
    this.sampleType,
    this.specialistConsultation,
    this.governmentFunded,
    this.consultationIncluded,
    this.digitalImaging,
    this.materialOptions,
    this.includes,
    this.additionalConfig,
  });

  factory ProvidedServicePricingConfig.fromJson(Map<String, dynamic> json) {
    return ProvidedServicePricingConfig(
      recommendedAge: json['recommended_age'] as String?,
      recommendedFrequency: json['recommended_frequency'] as String?,
      ageGroup: json['age_group'] as String?,
      sampleType: json['sample_type'] as String?,
      specialistConsultation: json['specialist_consultation'] as bool?,
      governmentFunded: json['government_funded'] as bool?,
      consultationIncluded: json['consultation_included'] as bool?,
      digitalImaging: json['digital_imaging'] as bool?,
      materialOptions: json['material_options'] != null
          ? List<String>.from(json['material_options'] as List)
          : null,
      includes: json['includes'] != null
          ? List<String>.from(json['includes'] as List)
          : null,
      additionalConfig: json.cast<String, dynamic>(),
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (recommendedAge != null) json['recommended_age'] = recommendedAge;
    if (recommendedFrequency != null)
      json['recommended_frequency'] = recommendedFrequency;
    if (ageGroup != null) json['age_group'] = ageGroup;
    if (sampleType != null) json['sample_type'] = sampleType;
    if (specialistConsultation != null)
      json['specialist_consultation'] = specialistConsultation;
    if (governmentFunded != null) json['government_funded'] = governmentFunded;
    if (consultationIncluded != null)
      json['consultation_included'] = consultationIncluded;
    if (digitalImaging != null) json['digital_imaging'] = digitalImaging;
    if (materialOptions != null) json['material_options'] = materialOptions;
    if (includes != null) json['includes'] = includes;
    if (additionalConfig != null) json.addAll(additionalConfig!);
    return json;
  }

  String toJsonString() => jsonEncode(toJson());

  @override
  String toString() => 'PricingConfig(${toJson().toString()})';
}

// ==================================================================
// Shared parse helpers
// ==================================================================

/// `100` as a `Decimal`. Used to convert between fraction and percent.
final Decimal _hundred = Decimal.fromInt(100);

int _asInt(dynamic v) => _asIntOrNull(v) ?? 0;

int? _asIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

String _asString(dynamic v) {
  if (v == null) return '';
  if (v is String) return v.trim();
  return v.toString().trim();
}

String? _asStringOrNull(dynamic v) {
  final s = _asString(v);
  return s.isEmpty ? null : s;
}

bool _asBoolInt(dynamic v) {
  if (v is bool) return v;
  if (v is num) return v == 1;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return false;
}

DateTime _parseDate(dynamic v) => _parseDateOrNull(v) ?? DateTime.now();

DateTime? _parseDateOrNull(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
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
