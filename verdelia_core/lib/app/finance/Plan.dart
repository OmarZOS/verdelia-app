// lib/business/finance/Plan.dart

import 'package:verdelia_core/business/NamingContribution.dart';

/// Which audience the plan is sold to. Mirrors the DB enum on
/// `plan.plan_type`.
enum PlanType {
  individual,
  organization;

  static PlanType fromWire(dynamic raw) {
    if (raw is! String) return PlanType.individual;
    switch (raw.toLowerCase().trim()) {
      case 'organization':
        return PlanType.organization;
      case 'individual':
      default:
        return PlanType.individual;
    }
  }

  String get wireValue => name;
}

/// How often the plan is billed. Mirrors the DB enum on
/// `plan.billing_cycle`.
enum BillingCycle {
  monthly,
  semestrial,
  yearly,
  lifetime;

  static BillingCycle fromWire(dynamic raw) {
    if (raw is! String) return BillingCycle.monthly;
    switch (raw.toLowerCase().trim()) {
      case 'monthly':
        return BillingCycle.monthly;
      case 'semestrial':
        return BillingCycle.semestrial;
      case 'yearly':
        return BillingCycle.yearly;
      case 'lifetime':
        return BillingCycle.lifetime;
      default:
        return BillingCycle.monthly;
    }
  }

  String get wireValue => name;

  bool get isLifetime => this == BillingCycle.lifetime;

  /// Months covered per billing cycle. Used to compute the
  /// monthly-equivalent price shown on yearly/semestrial cards.
  /// Lifetime returns null — there is no meaningful divisor.
  int? get months {
    switch (this) {
      case BillingCycle.monthly:
        return 1;
      case BillingCycle.semestrial:
        return 6;
      case BillingCycle.yearly:
        return 12;
      case BillingCycle.lifetime:
        return null;
    }
  }
}

// ══════════════════════════════════════════════════════════════════
// PlanLimit
// ══════════════════════════════════════════════════════════════════

/// A quantitative ceiling attached to a plan.
///
/// [resourceCode] is a stable identifier the backend and the app agree
/// on — `provider_owned`, `team_members`, `storage_bytes`, etc. The
/// display label is derived from the code on the app side; it is not
/// part of this row.
///
/// `limitValue` uses four distinct encodings:
///
///   * `> 0`  — a hard numeric ceiling.
///   * `0`    — the resource is not available on this plan.
///   * `-1`   — unlimited by design. Used internally; never sold as a
///              flat-price plan.
///   * `-2`   — negotiated per contract. Used by Enterprise. The real
///              ceiling is defined outside the plan row (in the
///              subscription or the signed contract).
///
/// `-1` and `-2` are *not* interchangeable. Code that treats any
/// negative value as "unlimited" will mis-handle Enterprise. Use
/// [isUnlimited] and [isNegotiated] explicitly.
class PlanLimit {
  final int? id;
  final int planId;
  final String resourceCode;
  final int limitValue;

  const PlanLimit({
    this.id,
    required this.planId,
    required this.resourceCode,
    required this.limitValue,
  });

  factory PlanLimit.fromJson(Map<String, dynamic> json) {
    return PlanLimit(
      id: _asInt(json['id_plan_limit']),
      planId: _asInt(json['plan_id']) ?? 0,
      resourceCode: (json['resource_code'] ?? '').toString(),
      limitValue: _asInt(json['limit_value']) ?? 0,
    );
  }

  static List<PlanLimit> listFromJson(dynamic json) {
    if (json is! List) return const [];
    return json
        .whereType<Map>()
        .map((e) => PlanLimit.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  // ── Sentinels ──────────────────────────────────────────────

  /// True when the limit is `-1` — unlimited by design.
  bool get isUnlimited => limitValue == -1;

  /// True when the limit is `-2` — negotiated per contract. The
  /// actual ceiling is defined outside the plan row.
  bool get isNegotiated => limitValue == -2;

  /// True when the limit is any negative sentinel (`-1` or `-2`).
  /// Use this when you want "not a hard number" without caring which
  /// kind — e.g. to skip arithmetic or bounds-checking.
  bool get isSentinel => limitValue < 0;

  /// True when the limit is exactly `0` (feature disabled).
  bool get isDisabled => limitValue == 0;

  /// True when the limit is a positive number.
  bool get isFinitePositive => limitValue > 0;

  Map<String, dynamic> toJson() => {
        if (id != null) 'id_plan_limit': id,
        'plan_id': planId,
        'resource_code': resourceCode,
        'limit_value': limitValue,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanLimit &&
          runtimeType == other.runtimeType &&
          planId == other.planId &&
          resourceCode == other.resourceCode;

  @override
  int get hashCode => Object.hash(planId, resourceCode);

  @override
  String toString() {
    final kind = switch (limitValue) {
      -1 => 'unlimited',
      -2 => 'negotiated',
      0 => 'disabled',
      _ => limitValue.toString(),
    };
    return 'PlanLimit(plan: $planId, code: $resourceCode, value: $kind)';
  }
}

// ══════════════════════════════════════════════════════════════════
// PlanFeature
// ══════════════════════════════════════════════════════════════════

/// A qualitative capability attached to a plan.
///
/// [featureCode] is a stable identifier (`api_access`, `custom_branding`,
/// `sso_saml`, …). The display name and description are resolved from
/// the naming contributions the backend sends alongside the row:
/// `feature_naming` for the name and `feature_description_naming` for
/// the description. Both are kept as parsed objects so callers can pick
/// the locale at render time.
class PlanFeature {
  final int? id;
  final int planId;
  final String featureCode;
  final String? featureValue;
  final int displayOrder;
  final bool isVisible;

  /// Localized display name. Null when the backend didn't include a
  /// naming block (older endpoints, or a row without one).
  final NamingContribution? naming;

  /// Localized description. Null when the feature has no description
  /// — pure boolean features like "Barcode scanning" typically don't.
  final NamingContribution? descriptionNaming;

  const PlanFeature({
    this.id,
    required this.planId,
    required this.featureCode,
    this.featureValue,
    this.displayOrder = 0,
    this.isVisible = true,
    this.naming,
    this.descriptionNaming,
  });

  factory PlanFeature.fromJson(Map<String, dynamic> json) {
    return PlanFeature(
      id: _asInt(json['id_plan_feature']),
      planId: _asInt(json['plan_id']) ?? 0,
      featureCode: (json['feature_code'] ?? '').toString(),
      featureValue: _asStringOrNull(json['feature_value']),
      displayOrder: _asInt(json['display_order']) ?? 0,
      isVisible: _asBool(json['is_visible']) ?? true,
      naming: _resolveNaming(json['feature_naming']),
      descriptionNaming: _resolveNaming(json['feature_description_naming']),
    );
  }

  static List<PlanFeature> listFromJson(dynamic json) {
    if (json is! List) return const [];
    return json
        .whereType<Map>()
        .map((e) => PlanFeature.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  // ── Localized accessors ───────────────────────────────────

  /// The feature's display name in [lang]. Prefers the naming
  /// contribution's translation, falls back to its English, then to
  /// the feature code so a missing block is visible rather than blank.
  String nameFor(String lang) {
    final resolved = naming?.nameFor(lang) ?? '';
    if (resolved.isNotEmpty) return resolved;
    return featureCode;
  }

  /// The feature's description in [lang], or null when the row has
  /// no description.
  String? descriptionFor(String lang) {
    if (descriptionNaming == null) return null;
    final resolved = descriptionNaming!.nameFor(lang);
    return resolved.isEmpty ? null : resolved;
  }

  /// English name. Kept for callers that don't have a locale in scope
  /// — tests, log lines, debug output.
  String get featureName => naming?.en ?? featureCode;

  /// English description. Same rationale as [featureName].
  String? get featureDescription {
    final en = descriptionNaming?.en ?? '';
    return en.isEmpty ? null : en;
  }

  /// Whether this feature carries a value (`"4h"`, `"SSD"`), as opposed
  /// to being a pure boolean capability.
  bool get hasValue => featureValue != null && featureValue!.isNotEmpty;

  Map<String, dynamic> toJson() => {
        if (id != null) 'id_plan_feature': id,
        'plan_id': planId,
        'feature_code': featureCode,
        'feature_value': featureValue,
        'display_order': displayOrder,
        'is_visible': isVisible ? 1 : 0,
        if (naming != null) 'feature_naming': naming!.toJson(),
        if (descriptionNaming != null)
          'feature_description_naming': descriptionNaming!.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanFeature &&
          runtimeType == other.runtimeType &&
          planId == other.planId &&
          featureCode == other.featureCode;

  @override
  int get hashCode => Object.hash(planId, featureCode);

  @override
  String toString() =>
      'PlanFeature(plan: $planId, code: $featureCode, name: $featureName)';
}

// ══════════════════════════════════════════════════════════════════
// PlanValueAxis
// ══════════════════════════════════════════════════════════════════

/// The *kind* of upgrade a plan represents. Answers "why is this tier
/// more expensive?" without relying on raw quotas.
///
///   capability     — unlocks a new kind of action
///   capacity       — unlocks more of an existing action
///   governance     — unlocks control over other people / audit
///   infrastructure — unlocks operational dependency / isolation
///
/// Not currently sent by the backend. Screens may infer it from the
/// plan name; this enum gives that inference a typed home.
enum PlanValueAxis {
  capability,
  capacity,
  governance,
  infrastructure;

  static PlanValueAxis? fromWire(dynamic raw) {
    if (raw is! String) return null;
    switch (raw.toLowerCase().trim()) {
      case 'capability':
        return PlanValueAxis.capability;
      case 'capacity':
        return PlanValueAxis.capacity;
      case 'governance':
        return PlanValueAxis.governance;
      case 'infrastructure':
        return PlanValueAxis.infrastructure;
      default:
        return null;
    }
  }

  String get wireValue => name;
}

// ══════════════════════════════════════════════════════════════════
// Plan
// ══════════════════════════════════════════════════════════════════

/// A plan as returned by `GET /plans`.
///
/// The backend sends the plan's display name as a nested
/// `NamingContribution` under `plan_naming`, and the plan's features
/// and limits as arrays under `plan_feature` and `plan_limit`. All
/// three are parsed here; screens read them directly rather than
/// re-parsing the raw JSON.
class Plan {
  final int? idPlan;
  final String planName;
  final double planPrice;
  final BillingCycle billingCycle;
  final PlanType planType;

  /// Localized display name. Falls back to [planName] when the
  /// backend didn't include a naming contribution.
  final NamingContribution? naming;

  final List<PlanFeature> features;
  final List<PlanLimit> limits;

  const Plan({
    this.idPlan,
    required this.planName,
    required this.planPrice,
    required this.billingCycle,
    required this.planType,
    this.naming,
    this.features = const [],
    this.limits = const [],
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      idPlan: _asInt(json['id_plan']),
      planName: (json['plan_name'] ?? '').toString(),
      planPrice: _asDouble(json['plan_price']) ?? 0.0,
      billingCycle: BillingCycle.fromWire(json['billing_cycle']),
      planType: PlanType.fromWire(json['plan_type']),
      naming: _resolveNaming(json['plan_naming']),
      features: PlanFeature.listFromJson(json['plan_feature']),
      limits: PlanLimit.listFromJson(json['plan_limit']),
    );
  }

  static List<Plan> listFromJson(dynamic json) {
    if (json is! List) return const [];
    return json
        .whereType<Map>()
        .map((e) => Plan.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  Map<String, dynamic> toJson() => {
        if (idPlan != null) 'id_plan': idPlan,
        'plan_name': planName,
        'plan_price': planPrice,
        'billing_cycle': billingCycle.wireValue,
        'plan_type': planType.wireValue,
        if (naming != null) 'plan_naming': naming!.toJson(),
        'plan_feature': features.map((f) => f.toJson()).toList(),
        'plan_limit': limits.map((l) => l.toJson()).toList(),
      };

  // ── Convenience ────────────────────────────────────────────

  bool get isFree => planPrice <= 0;
  bool get isPaid => !isFree;

  /// The plan's display name in [lang], resolved through the naming
  /// contribution. Falls back to the flat [planName].
  String nameFor(String lang) {
    final resolved = naming?.nameFor(lang) ?? '';
    if (resolved.isNotEmpty) return resolved;
    return planName;
  }

  /// Features visible on the pricing card, sorted by display order.
  /// Features the backend marks as hidden are filtered out.
  List<PlanFeature> get visibleFeatures {
    final list = features.where((f) => f.isVisible).toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return list;
  }

  /// Look up a feature by code. Returns null when the plan doesn't
  /// include it.
  PlanFeature? feature(String code) {
    for (final f in features) {
      if (f.featureCode == code) return f;
    }
    return null;
  }

  /// True when the plan grants [code].
  bool hasFeature(String code) => feature(code) != null;

  /// Look up a limit by resource code. Returns null when the plan
  /// doesn't define one.
  PlanLimit? limit(String resourceCode) {
    for (final l in limits) {
      if (l.resourceCode == resourceCode) return l;
    }
    return null;
  }

  /// The numeric value of a limit, or null when undefined. Use
  /// [limit] when you need sentinel semantics (`-1` unlimited,
  /// `-2` negotiated); this getter returns the raw number.
  int? limitValue(String resourceCode) => limit(resourceCode)?.limitValue;

  /// Whether [resourceCode] is unlimited on this plan (`-1`).
  bool isUnlimited(String resourceCode) =>
      limit(resourceCode)?.isUnlimited ?? false;

  /// Whether [resourceCode] is negotiated on this plan (`-2`).
  bool isNegotiated(String resourceCode) =>
      limit(resourceCode)?.isNegotiated ?? false;

  /// Whether [resourceCode] is available on this plan. True when the
  /// code is defined and its value is not `0`. Negotiated (`-2`) and
  /// unlimited (`-1`) both count as available.
  bool hasResource(String resourceCode) {
    final l = limit(resourceCode);
    if (l == null) return false;
    return l.limitValue != 0;
  }

  // ── Ads ────────────────────────────────────────────────────

  /// Whether this plan displays ads. Encoded in the API as the
  /// `ads_enabled` limit (`1` = ads on, `0` = ads off).
  ///
  /// Defaults to `false` when the code is absent — absence means the
  /// backend didn't advertise an ad policy, and the safe default for
  /// a paid plan is "no ads".
  bool get adsEnabled {
    final l = limit('ads_enabled');
    if (l == null) return false;
    return l.limitValue != 0;
  }

  /// Convenience inverse, used by the pricing card to render the
  /// "No ads" row.
  bool get isAdFree => !adsEnabled;

  // ── Pricing helpers ────────────────────────────────────────

  /// The monthly-equivalent price, or null when the cycle has no
  /// meaningful divisor (lifetime). Used by the pricing card to show
  /// "≈ X DA / monthly" on yearly plans.
  double? get monthlyEquivalent {
    final months = billingCycle.months;
    if (months == null || months == 1) return null;
    return planPrice / months;
  }

  /// The number of free months implied by the cycle, assuming the
  /// "annual = 10 months" rule. Returns null when the cycle has no
  /// implied saving.
  int? get savingsMonths {
    if (billingCycle == BillingCycle.yearly) return 2;
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Plan &&
          runtimeType == other.runtimeType &&
          idPlan == other.idPlan;

  @override
  int get hashCode => idPlan.hashCode;

  @override
  String toString() => 'Plan(id: $idPlan, name: $planName, price: $planPrice, '
      'cycle: ${billingCycle.name}, type: ${planType.name}, '
      'features: ${features.length}, limits: ${limits.length})';
}

// ══════════════════════════════════════════════════════════════════
// JSON helpers
// ══════════════════════════════════════════════════════════════════

NamingContribution? _resolveNaming(dynamic raw) {
  if (raw == null) return null;
  if (raw is Map) {
    return NamingContribution.fromJson(Map<String, dynamic>.from(raw));
  }
  if (raw is String && raw.isNotEmpty) {
    // Flat form: the backend sent the English name directly.
    return NamingContribution(id: null, en: raw);
  }
  return null;
}

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

String? _asStringOrNull(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

bool? _asBool(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final lower = v.toLowerCase();
    if (lower == '1' || lower == 'true') return true;
    if (lower == '0' || lower == 'false') return false;
  }
  return null;
}
