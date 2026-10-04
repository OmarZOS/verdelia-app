// lib/business/finance/Plan.dart

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
}

/// A single plan as returned by `GET /plans`.
class Plan {
  final int? idPlan;
  final String planName;
  final double planPrice;
  final BillingCycle billingCycle;
  final PlanType planType;

  const Plan({
    this.idPlan,
    required this.planName,
    required this.planPrice,
    required this.billingCycle,
    required this.planType,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      idPlan: _asInt(json['id_plan']),
      planName: (json['plan_name'] ?? '').toString(),
      planPrice: _asDouble(json['plan_price']) ?? 0.0,
      billingCycle: BillingCycle.fromWire(json['billing_cycle']),
      planType: PlanType.fromWire(json['plan_type']),
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
      };

  bool get isFree => planPrice <= 0;
  bool get isPaid => !isFree;

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
      'cycle: ${billingCycle.name}, type: ${planType.name})';
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
