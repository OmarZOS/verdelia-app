// lib/event/components/user/plan_cache.dart

import 'package:verdelia_core/app/finance/Plan.dart';

/// In-memory cache for the plan catalogue.
///
/// The catalogue is small (a dozen entries), changes rarely, and is
/// fetched by every screen that shows pricing. A simple map keyed by
/// the filter tuple avoids refetching on every navigation.
///
/// Not persisted to disk: on cold start the app refetches once, which
/// is cheap and guarantees freshness against a backend that may have
/// adjusted prices.
class PlanCache {
  /// Cache of `list` results keyed by `"type|cycle"`. The empty filter
  /// is stored under `"|"`.
  final Map<String, List<Plan>> _listCache = {};

  /// Cache of individual plans keyed by id. Populated both by
  /// [getPlan] and by successful list fetches.
  final Map<int, Plan> _byId = {};

  bool _enabled = true;

  bool get isEnabled => _enabled;

  void enable(bool value) {
    _enabled = value;
    if (!value) clear();
  }

  /// Compose the key used for a filtered list fetch.
  static String listKey({String? planType, String? billingCycle}) {
    return '${planType ?? ''}|${billingCycle ?? ''}';
  }

  List<Plan>? getList({String? planType, String? billingCycle}) {
    if (!_enabled) return null;
    return _listCache[listKey(planType: planType, billingCycle: billingCycle)];
  }

  void cacheList(
    List<Plan> plans, {
    String? planType,
    String? billingCycle,
  }) {
    if (!_enabled) return;
    _listCache[listKey(planType: planType, billingCycle: billingCycle)] =
        List.unmodifiable(plans);
    // Also index each plan by id so getPlan can short-circuit.
    for (final plan in plans) {
      if (plan.idPlan != null && plan.idPlan! > 0) {
        _byId[plan.idPlan!] = plan;
      }
    }
  }

  Plan? getPlan(int planId) {
    if (!_enabled) return null;
    return _byId[planId];
  }

  void cachePlan(Plan plan) {
    if (!_enabled) return;
    if (plan.idPlan != null && plan.idPlan! > 0) {
      _byId[plan.idPlan!] = plan;
    }
  }

  int get listCacheSize => _listCache.length;
  int get planCacheSize => _byId.length;

  void clear() {
    _listCache.clear();
    _byId.clear();
  }

  void invalidateList({String? planType, String? billingCycle}) {
    _listCache.remove(
      listKey(planType: planType, billingCycle: billingCycle),
    );
  }
}
