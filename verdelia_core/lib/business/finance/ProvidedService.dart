// lib/business/finance/ProvidedService.dart

import 'dart:convert';

import '../NamingContribution.dart';

// ==================================================================
// ProvidedServiceCategory
// ==================================================================

class ProvidedServiceCategory {
  /// FK to `provided_service_category.id`.
  final int id;

  /// Canonical dotted key, e.g. `health.diagnostics.diagnostic_imaging`.
  /// Kept as `name` for backward compatibility with the existing model.
  final String name;

  /// Free-form category description.
  final String description;

  /// Icon URL from `provided_service_category_icon_url`, nullable.
  final String? iconUrl;

  /// FK to the trilingual naming contribution row.
  final int? namingRef;

  /// Average duration in minutes, when the payload carries it.
  final int? avgDuration;

  /// Trilingual naming block (fr / ar / en + status + icon).
  /// Null when the payload only carried the flat shape or the
  /// contribution hasn't been hydrated yet.
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
      id: _asInt(json['provided_service_category_id']),
      name: _asString(json['provided_service_category_name']),
      description: _asString(json['provided_service_category_description']),
      iconUrl: _asStringOrNull(json['provided_service_category_icon_url']),
      namingRef: _asIntOrNull(json['provided_service_category_naming_ref']),
      avgDuration: _asIntOrNull(json['provided_service_category_avg_duration']),
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

  // ==================== Naming accessors ====================

  /// Return the category name in [lang]. Prefers the trilingual
  /// naming contribution; falls back to humanizing the canonical
  /// dotted key, then to the raw [name].
  String nameFor(String lang) {
    final resolved = naming?.nameFor(lang) ?? '';
    if (resolved.isNotEmpty) return resolved;
    return humanizeCanonicalKey(name);
  }

  /// Icon URL preferring the naming block, falling back to the flat
  /// top-level icon.
  String? get resolvedIconUrl {
    final fromNaming = naming?.iconUrl;
    if (fromNaming != null && fromNaming.isNotEmpty) return fromNaming;
    return iconUrl;
  }

  /// Attach a naming contribution after parse. Used to hydrate a
  /// category that arrived with only a `naming_ref`.
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

/// Turn `health.diagnostics.diagnostic_imaging` into
/// `Diagnostic Imaging`. Last-resort fallback when no naming
/// contribution is available.
String humanizeCanonicalKey(String key) {
  if (key.isEmpty) return '';
  final leaf = key.split('.').last;
  return leaf
      .split(RegExp(r'[_\s]+'))
      .where((s) => s.isNotEmpty)
      .map((s) => s[0].toUpperCase() + s.substring(1))
      .join(' ');
}

// ==================== Parse helpers ====================

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

// ==================================================================
// StaffRole
// ==================================================================

class StaffRole {
  /// FK to `id_staff_role`.
  final int id;

  /// FK to the service category this role belongs to.
  final int categoryId;

  /// Flat English label from `staff_role_name`.
  /// Kept for backward compatibility — prefer [nameFor] or [naming].
  final String name;

  /// Icon URL from `staff_role_icon_url`.
  final String? iconUrl;

  /// Free-form description, when present.
  final String? description;

  /// FK to the trilingual naming contribution row.
  final int? namingRef;

  /// Trilingual naming block (fr / ar / en + status + icon).
  /// Null when the payload only carried the flat shape.
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

  Map<String, dynamic> toJson() => {
        'id_staff_role': id,
        'staff_role_service_category_ref': categoryId,
        'staff_role_name': name,
        if (iconUrl != null) 'staff_role_icon_url': iconUrl,
        if (description != null) 'staff_role_description': description,
        if (namingRef != null) 'staff_role_naming_ref': namingRef,
        if (naming != null) 'naming_contribution': naming!.toJson(),
      };

  // ==================== Naming accessors ====================

  /// Resolve the display name for [lang].
  ///
  /// Falls back through: naming contribution → flat [name] → empty.
  /// Mirrors [ProvidedServiceCategory.nameFor] so call sites behave the
  /// same regardless of which entity they're reading.
  String nameFor(String lang) {
    final resolved = naming?.nameFor(lang) ?? '';
    if (resolved.isNotEmpty) return resolved;
    return name;
  }

  /// Icon URL preferring the naming block, falling back to the flat
  /// top-level icon.
  String? get resolvedIconUrl {
    final fromNaming = naming?.iconUrl;
    if (fromNaming != null && fromNaming.isNotEmpty) return fromNaming;
    return iconUrl;
  }

  /// Attach a naming contribution after parse.
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

class ProvidedService {
  final int id;
  final String name;
  final String description;
  final int categoryId;
  final int productProviderId;
  final double basePrice;
  final double finalPrice;
  final int actualDuration; // in minutes
  final ProvidedServicePricingConfig pricingConfig;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final List<ServiceResourceRequirement> resourceRequirements;
  final List<ServiceStaffRequirement> staffRequirements;

  /// Nested category snapshot, when the payload inlines it.
  ///
  /// The canonical source of truth for the *resolved* display name is
  /// still [ServiceNotifier.categoryName], which holds the hydrated
  /// list. This field exists so a service rendered outside the
  /// notifier scope (previews, tests, export) can still show a label.
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
    required this.pricingConfig,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.resourceRequirements = const [],
    this.staffRequirements = const [],
    this.category,
  });

  // ==================== Computed getters ====================

  double get discountPercentage {
    if (basePrice == 0) return 0;
    return ((basePrice - finalPrice) / basePrice * 100);
  }

  String get durationFormatted {
    final hours = actualDuration ~/ 60;
    final minutes = actualDuration % 60;
    if (hours == 0) return '${minutes}min';
    return '${hours}h ${minutes}min';
  }

  double get totalResourceCost {
    return resourceRequirements.fold(
      0.0,
      (total, requirement) =>
          total + (requirement.costPerUnit * requirement.quantity),
    );
  }

  double get totalStaffCost {
    return staffRequirements.fold(
      0.0,
      (total, requirement) =>
          total + (requirement.hourlyRate * requirement.allocatedHours),
    );
  }

  double get totalCost => totalResourceCost + totalStaffCost;

  double get profitMargin {
    if (finalPrice == 0) return 0;
    return ((finalPrice - totalCost) / finalPrice * 100);
  }

  // ==================== Category accessors ====================

  /// Resolved name for the nested category in [lang].
  ///
  /// Falls back through the category's own naming chain. Returns empty
  /// when the payload didn't carry the category inline — callers that
  /// need a label in that case should resolve it via the notifier's
  /// `categoryName(service.categoryId)` instead.
  String categoryNameFor(String lang) => category?.nameFor(lang) ?? '';

  /// Canonical dotted key of the nested category, or empty.
  String get categoryKey => category?.name ?? '';

  /// Resolved icon URL for the nested category, or null.
  String? get categoryIconUrl => category?.resolvedIconUrl;

  // ==================== Factories ====================

  factory ProvidedService.empty() {
    return ProvidedService(
      id: 0,
      name: '',
      description: '',
      categoryId: 1,
      productProviderId: 1,
      basePrice: 0.0,
      finalPrice: 0.0,
      actualDuration: 0,
      pricingConfig: ProvidedServicePricingConfig(),
      isActive: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory ProvidedService.fromJson(Map<String, dynamic> json) {
    final int id = (json['provided_service_id'] as num).toInt();
    final String name = json['provided_service_name'] as String;
    final String description = json['provided_service_description'] as String;
    final int categoryId =
        (json['provided_service_category_id'] as num).toInt();
    final int productProviderId =
        (json['provided_service_product_provider_id'] as num).toInt();
    final double basePrice =
        (json['provided_service_base_price'] as num).toDouble();
    final double finalPrice =
        (json['provided_service_final_price'] as num).toDouble();

    // Handle actualDuration (could be int or double)
    final int actualDuration;
    final actualDurationValue = json['provided_service_actual_duration'];
    if (actualDurationValue is num) {
      actualDuration = actualDurationValue.toInt();
    } else {
      actualDuration = 0;
    }

    // Handle isActive (could be 1/0 or true/false)
    final bool isActive;
    final isActiveValue = json['provided_service_is_active'];
    if (isActiveValue is bool) {
      isActive = isActiveValue;
    } else if (isActiveValue is num) {
      isActive = isActiveValue == 1;
    } else {
      isActive = false;
    }

    // Handle pricing config (JSON string or Map)
    final pricingConfigValue = json['provided_service_pricing_config'];
    ProvidedServicePricingConfig pricingConfig;

    if (pricingConfigValue is String) {
      try {
        final parsed = jsonDecode(pricingConfigValue) as Map<String, dynamic>;
        pricingConfig = ProvidedServicePricingConfig.fromJson(parsed);
      } catch (e) {
        pricingConfig = ProvidedServicePricingConfig();
      }
    } else if (pricingConfigValue is Map<String, dynamic>) {
      pricingConfig = ProvidedServicePricingConfig.fromJson(pricingConfigValue);
    } else {
      pricingConfig = ProvidedServicePricingConfig();
    }

    // Handle dates
    DateTime createdAt;
    try {
      createdAt = DateTime.parse(json['provided_service_created_at'] as String);
    } catch (e) {
      createdAt = DateTime.now();
    }

    DateTime updatedAt;
    try {
      updatedAt = DateTime.parse(json['provided_service_updated_at'] as String);
    } catch (e) {
      updatedAt = DateTime.now();
    }

    DateTime? deletedAt;
    if (json['provided_service_deleted_at'] != null &&
        json['provided_service_deleted_at'] is String) {
      try {
        deletedAt =
            DateTime.parse(json['provided_service_deleted_at'] as String);
      } catch (e) {
        deletedAt = null;
      }
    } else {
      deletedAt = null;
    }

    // Parse resource requirements if they exist (nested)
    final List<ServiceResourceRequirement> resourceRequirements = [];
    if (json['requirements'] != null) {
      final resourcesJson = json['requirements'] as List;
      resourceRequirements.addAll(
        resourcesJson.map(
          (resourceJson) => ServiceResourceRequirement.fromJson(resourceJson),
        ),
      );
    }
    if (json['service_resource_requirement'] != null) {
      final resourcesJson = json['service_resource_requirement'] as List;
      resourceRequirements.addAll(
        resourcesJson.map(
          (resourceJson) => ServiceResourceRequirement.fromJson(resourceJson),
        ),
      );
    }

    // Parse staff requirements if they exist (nested)
    final List<ServiceStaffRequirement> staffRequirements = [];
    if (json['staff_requirements'] != null) {
      final staffJson = json['staff_requirements'] as List;
      staffRequirements.addAll(
        staffJson.map(
          (staffJson) => ServiceStaffRequirement.fromJson(staffJson),
        ),
      );
    }
    if (json['service_staff_requirement'] != null) {
      final staffJson = json['service_staff_requirement'] as List;
      staffRequirements.addAll(
        staffJson.map(
          (staffJson) => ServiceStaffRequirement.fromJson(staffJson),
        ),
      );
    }

    // Parse nested category when inlined in the payload.
    final categoryRaw = json['provided_service_category'];
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

  Map<String, dynamic> toJson() {
    return {
      'provided_service_product_provider_id': productProviderId,
      'service': {
        'provided_service_id': id,
        'provided_service_name': name,
        'provided_service_description': description,
        'provided_service_category_id': categoryId,
        'provided_service_product_provider_id': productProviderId,
        'provided_service_base_price': basePrice,
        'provided_service_final_price': finalPrice,
        'provided_service_actual_duration': actualDuration,
        'provided_service_pricing_config': pricingConfig.toJsonString(),
        'provided_service_is_active': isActive ? 1 : 0,
        'provided_service_created_at': createdAt.toIso8601String(),
        'provided_service_updated_at': updatedAt.toIso8601String(),
        'provided_service_deleted_at': deletedAt?.toIso8601String(),
      },
      'requirements': resourceRequirements.map((r) => r.toJson()).toList(),
      'staff_requirements': staffRequirements.map((s) => s.toJson()).toList(),
    };
  }

  // ==================== copyWith ====================

  ProvidedService copyWith({
    int? id,
    String? name,
    String? description,
    int? categoryId,
    int? productProviderId,
    double? basePrice,
    double? finalPrice,
    int? actualDuration,
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

  /// Attach a category after parse. Used to hydrate a service whose
  /// payload only carried the id and whose category details live in
  /// the notifier.
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

class ServiceResourceRequirement {
  final int id;
  final String name;
  final String type;
  final double quantity;
  final bool isConsumable;
  final int? productRef;
  final int serviceId;
  final double costPerUnit;
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

  double get totalCost => costPerUnit * quantity;

  factory ServiceResourceRequirement.fromJson(Map<String, dynamic> json) {
    return ServiceResourceRequirement(
      id: json['service_resource_requirement_id'] as int,
      name: json['service_resource_requirement_name'] as String,
      type: json['service_resource_requirement_type'] as String,
      quantity:
          (json['service_resource_requirement_quantity'] as num).toDouble(),
      isConsumable: json['service_resource_requirement_is_consumable'] == 1,
      productRef: json['service_resource_requirement_product_ref'] as int?,
      serviceId: json['service_resource_requirement_service_id'] as int,
      costPerUnit: (json['service_resource_requirement_cost_per_unit'] as num)
          .toDouble(),
      notes: json['service_resource_requirement_notes'] as String?,
      createdAt:
          DateTime.parse(json['service_resource_requirement_created_at']),
      updatedAt:
          DateTime.parse(json['service_resource_requirement_updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'service_resource_requirement_id': id,
      'service_resource_requirement_name': name,
      'service_resource_requirement_type': type,
      'service_resource_requirement_quantity': quantity,
      'service_resource_requirement_is_consumable': isConsumable ? 1 : 0,
      'service_resource_requirement_product_ref': productRef,
      'service_resource_requirement_service_id': serviceId,
      'service_resource_requirement_cost_per_unit': costPerUnit,
      'service_resource_requirement_notes': notes,
      'service_resource_requirement_created_at': createdAt.toIso8601String(),
      'service_resource_requirement_updated_at': updatedAt.toIso8601String(),
    };
  }
}

// ==================================================================
// ServiceStaffRequirement
// ==================================================================

class ServiceStaffRequirement {
  final int id;
  final int serviceId;
  final int minCount;
  final int maxCount;
  final int role;
  final double allocatedHours;
  final double hourlyRate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Nested staff role snapshot, when the payload inlines it.
  ///
  /// Carries the trilingual naming contribution. Use [roleNameFor] to
  /// get a resolved label; fall back to the notifier's role list when
  /// the payload only sent the `role` id.
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

  // ==================== Cost getters ====================

  double get minCost => hourlyRate * allocatedHours * minCount;
  double get maxCost => hourlyRate * allocatedHours * maxCount;

  double get averageCost {
    final avgCount = (minCount + maxCount) / 2;
    return hourlyRate * allocatedHours * avgCount;
  }

  // ==================== Role accessors ====================

  /// Resolved role name for [lang], or empty when the payload didn't
  /// inline the role.
  ///
  /// Prefers the nested role's naming contribution, falling back to
  /// the flat `staff_role_name`. Callers that need a label when this
  /// returns empty should resolve it via the notifier's role cache by
  /// [role] id.
  String roleNameFor(String lang) => staffRole?.nameFor(lang) ?? '';

  /// Resolved icon URL for the role, or null.
  String? get roleIconUrl => staffRole?.resolvedIconUrl;

  /// Attach a role after parse. Used to hydrate a requirement whose
  /// payload only carried the `role` id and whose role details live in
  /// the notifier.
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

  // ==================== Factories ====================

  factory ServiceStaffRequirement.fromJson(Map<String, dynamic> json) {
    final roleRaw = json['staff_role'];
    final StaffRole? staffRole = roleRaw is Map
        ? StaffRole.fromJson(Map<String, dynamic>.from(roleRaw))
        : null;

    return ServiceStaffRequirement(
      id: _asInt(json['service_staff_requirement_id']),
      serviceId: _asInt(json['service_staff_requirement_service_id']),
      minCount: _asInt(json['service_staff_requirement_min_count']),
      maxCount: _asInt(json['service_staff_requirement_max_count']),
      role: _asInt(json['service_staff_requirement_role']),
      allocatedHours: _asDouble(
        json['service_staff_requirement_allocated_hours'],
      ),
      hourlyRate: _asDouble(
        json['service_staff_requirement_hourly_rate'],
      ),
      notes: _asStringOrNull(json['service_staff_requirement_notes']),
      createdAt: _parseDate(
        json['service_staff_requirement_created_at'],
      ),
      updatedAt: _parseDate(
        json['service_staff_requirement_updated_at'],
      ),
      staffRole: staffRole,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'service_staff_requirement_id': id,
      'service_staff_requirement_service_id': serviceId,
      'service_staff_requirement_min_count': minCount,
      'service_staff_requirement_max_count': maxCount,
      'service_staff_requirement_role': role,
      'service_staff_requirement_allocated_hours': allocatedHours,
      'service_staff_requirement_hourly_rate': hourlyRate,
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

    if (additionalConfig != null) {
      json.addAll(additionalConfig!);
    }

    return json;
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  @override
  String toString() {
    return 'PricingConfig(${toJson().toString()})';
  }
}

double _asDouble(dynamic v) => _asDoubleOrNull(v) ?? 0;

double? _asDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

DateTime _parseDate(dynamic v) {
  if (v == null) return DateTime.now();
  if (v is DateTime) return v;
  if (v is String) {
    try {
      return DateTime.parse(v);
    } catch (_) {
      return DateTime.now();
    }
  }
  return DateTime.now();
}
