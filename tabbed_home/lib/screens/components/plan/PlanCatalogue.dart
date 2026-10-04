// lib/business/plan/PlanCatalogue.dart

import 'PlanModel.dart';

/// A flat list of plans with grouping helpers on top.
///
/// The backend returns a flat array from `GET /plans`; the UI usually
/// wants it grouped by type and, within a type, ordered by cycle. This
/// wrapper does that grouping once so the widget tree stays a plain
/// list iteration.
class PlanCatalogue {
  final List<Plan> all;

  const PlanCatalogue(this.all);

  factory PlanCatalogue.fromJson(dynamic json) =>
      PlanCatalogue(Plan.listFromJson(json));

  const PlanCatalogue.empty() : all = const [];

  bool get isEmpty => all.isEmpty;
  bool get isNotEmpty => all.isNotEmpty;

  /// Every plan of a given type, sorted by cycle in ascending
  /// duration order: monthly, semestrial, yearly, lifetime.
  List<Plan> forType(PlanType type) {
    final filtered = all.where((p) => p.planType == type).toList();
    filtered.sort((a, b) =>
        _cycleOrder(a.billingCycle).compareTo(_cycleOrder(b.billingCycle)));
    return filtered;
  }

  /// Just the free plan, if one exists.
  Plan? get freePlan => all.where((p) => p.isFree).firstOrNull;

  /// All paid plans, sorted by type then cycle then price.
  List<Plan> get paidPlans {
    final filtered = all.where((p) => p.isPaid).toList();
    filtered.sort((a, b) {
      final typeCmp = a.planType.index.compareTo(b.planType.index);
      if (typeCmp != 0) return typeCmp;
      final cycleCmp =
          _cycleOrder(a.billingCycle).compareTo(_cycleOrder(b.billingCycle));
      if (cycleCmp != 0) return cycleCmp;
      return a.planPrice.compareTo(b.planPrice);
    });
    return filtered;
  }

  Plan? byId(int? id) {
    if (id == null) return null;
    for (final p in all) {
      if (p.idPlan == id) return p;
    }
    return null;
  }

  static int _cycleOrder(BillingCycle cycle) {
    switch (cycle) {
      case BillingCycle.monthly:
        return 0;
      case BillingCycle.semestrial:
        return 1;
      case BillingCycle.yearly:
        return 2;
      case BillingCycle.lifetime:
        return 3;
    }
  }
}
