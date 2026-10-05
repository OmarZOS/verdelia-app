import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:verdelia_core/app/finance/Plan.dart';
import 'package:verdelia_core/app/finance/Subscription.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

import 'package:event/user_change_notifier.dart';

/// Plan catalogue and purchase screen.
class PlansScreen extends StatefulWidget {
  final bool showCurrentSubscription;

  const PlansScreen({
    super.key,
    this.showCurrentSubscription = true,
  });

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

enum _PlanTab {
  individual,
  organization,
  all;

  String label(AppLocalizations loc) {
    switch (this) {
      case _PlanTab.individual:
        return loc.plansTabIndividual;
      case _PlanTab.organization:
        return loc.plansTabOrganization;
      case _PlanTab.all:
        return loc.plansTabAll;
    }
  }

  List<Plan> filter(List<Plan> plans) {
    switch (this) {
      case _PlanTab.individual:
        return plans.where((p) => p.planType == PlanType.individual).toList();
      case _PlanTab.organization:
        return plans.where((p) => p.planType == PlanType.organization).toList();
      case _PlanTab.all:
        return plans;
    }
  }
}

/// Limits that are already implied by a visible feature. Showing both
/// would say the same thing twice.
const _featureImpliedBy = <String, String>{
  'team_members': 'team_management',
  'ai_credits_monthly': 'ai_assistant',
  'api_calls_monthly': 'api_access',
};

class _PlansScreenState extends State<PlansScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final Map<_PlanTab, int?> _selectedPlanByTab = {
    _PlanTab.individual: null,
    _PlanTab.organization: null,
    _PlanTab.all: null,
  };

  int? _purchasingPlanId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _PlanTab.values.length, vsync: this);
    _tabController.addListener(_onTabChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppUserNotifier>().fetchPlans();
    });
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  _PlanTab get _currentTab => _PlanTab.values[_tabController.index];

  // ══════════════════════════════════════════════════════════════════
  // Actions
  // ══════════════════════════════════════════════════════════════════

  Future<void> _refresh() async {
    await context.read<AppUserNotifier>().fetchPlans(forceRefresh: true);
    if (mounted) {
      setState(() {
        for (final tab in _PlanTab.values) {
          _selectedPlanByTab[tab] = null;
        }
        _purchasingPlanId = null;
      });
    }
  }

  void _selectPlan(Plan plan) {
    if (_purchasingPlanId != null) return;
    setState(() => _selectedPlanByTab[_currentTab] = plan.idPlan);
  }

  Future<void> _subscribe(Plan plan) async {
    if (_purchasingPlanId != null) return;

    final notifier = context.read<AppUserNotifier>();
    final loc = AppLocalizations.of(context)!;

    if (plan.isFree) {
      setState(() => _purchasingPlanId = plan.idPlan);
      final result = await notifier.linkFreePlan(planId: plan.idPlan ?? 1);
      if (!mounted) return;
      setState(() => _purchasingPlanId = null);

      if (result != null) {
        await _showSuccessDialog(plan);
        if (mounted) Navigator.pop(context, true);
      } else {
        _showError(loc.planPurchaseFailed);
      }
      return;
    }

    final method = await _promptPaymentMethod();
    if (method == null || !mounted) return;

    setState(() => _purchasingPlanId = plan.idPlan);
    final result = await notifier.initiateSubscription(
      planId: plan.idPlan,
      paymentMethod: method,
    );
    if (!mounted) return;
    setState(() => _purchasingPlanId = null);

    if (result != null) {
      await _showSuccessDialog(plan);
      if (mounted) Navigator.pop(context, true);
    } else {
      _showError(loc.planPurchaseFailed);
    }
  }

  Future<String?> _promptPaymentMethod() {
    final loc = AppLocalizations.of(context)!;
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaymentMethodSheet(loc: loc),
    );
  }

  Future<void> _showSuccessDialog(Plan plan) {
    final loc = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final displayName = plan.nameFor(lang);

    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final cs = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          icon: Icon(Icons.check_circle_rounded, color: cs.primary, size: 48),
          title: Text(loc.planActivated),
          content: Text(
            loc.planActivatedMessage(displayName),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(loc.gotIt),
            ),
          ],
        );
      },
    );
  }

  void _showError(String message) {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: cs.errorContainer,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(12),
        ),
      );
  }

  // ══════════════════════════════════════════════════════════════════
  // Build
  // ══════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.choosePlanTitle),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _PlanTabBar(controller: _tabController, loc: loc, cs: cs),
        ),
      ),
      body: SafeArea(
        child: Consumer<AppUserNotifier>(
          builder: (context, notifier, _) {
            final allPlans = notifier.plans;
            final isLoading = notifier.isFetchingPlans;

            if (isLoading && allPlans.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (allPlans.isEmpty) {
              return _EmptyState(onRefresh: _refresh);
            }

            final currentPlanId = notifier.subscription?.subscriptionPlanId;
            final isOnFree = _isOnFreePlan(notifier, allPlans);

            return TabBarView(
              controller: _tabController,
              children: [
                for (final tab in _PlanTab.values)
                  _PlanTabBody(
                    tab: tab,
                    plans: tab.filter(allPlans),
                    currentPlanId: currentPlanId,
                    selectedPlanId: _selectedPlanByTab[tab],
                    purchasingPlanId: _purchasingPlanId,
                    isOnFree: isOnFree,
                    onSelect: _selectPlan,
                    onSubscribe: _subscribe,
                    onRefresh: _refresh,
                    loc: loc,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// True when the user has an active subscription whose plan is the
  /// zero-price plan. Used by the UI to switch from "choose a plan" to
  /// "here is what you have, here is what else exists".
  bool _isOnFreePlan(AppUserNotifier notifier, List<Plan> plans) {
    final sub = notifier.subscription;
    if (sub == null) return false;

    final currentId = sub.subscriptionPlanId;
    if (currentId == null) return false;

    for (final p in plans) {
      if (p.idPlan == currentId) return p.isFree;
    }
    return false;
  }
}

// ══════════════════════════════════════════════════════════════════
// Tab bar
// ══════════════════════════════════════════════════════════════════

class _PlanTabBar extends StatelessWidget {
  final TabController controller;
  final AppLocalizations loc;
  final ColorScheme cs;

  const _PlanTabBar({
    required this.controller,
    required this.loc,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: cs.surface,
      child: TabBar(
        controller: controller,
        labelColor: cs.primary,
        unselectedLabelColor: cs.onSurfaceVariant,
        indicatorColor: cs.primary,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        dividerColor: cs.outlineVariant.withOpacity(0.5),
        tabs: [
          for (final tab in _PlanTab.values) Tab(text: tab.label(loc)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Tab body
// ══════════════════════════════════════════════════════════════════

class _PlanTabBody extends StatelessWidget {
  final _PlanTab tab;
  final List<Plan> plans;
  final int? currentPlanId;
  final int? selectedPlanId;
  final int? purchasingPlanId;
  final bool isOnFree;
  final ValueChanged<Plan> onSelect;
  final Future<void> Function(Plan plan) onSubscribe;
  final Future<void> Function() onRefresh;
  final AppLocalizations loc;

  const _PlanTabBody({
    required this.tab,
    required this.plans,
    required this.currentPlanId,
    required this.selectedPlanId,
    required this.purchasingPlanId,
    required this.isOnFree,
    required this.onSelect,
    required this.onSubscribe,
    required this.onRefresh,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    if (plans.isEmpty) {
      return _TabEmptyState(tab: tab, loc: loc, onRefresh: onRefresh);
    }

    final selected = _planById(plans, selectedPlanId);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 140),
      children: [
        _Header(loc: loc, tab: tab, isOnFree: isOnFree),
        const SizedBox(height: 20),
        for (final plan in plans) ...[
          _PlanCard(
            plan: plan,
            isSelected: selectedPlanId == plan.idPlan,
            isCurrent: currentPlanId == plan.idPlan,
            isPurchasing: purchasingPlanId == plan.idPlan,
            anyPurchasing: purchasingPlanId != null,
            isOnFree: isOnFree,
            onTap: () => onSelect(plan),
          ),
          const SizedBox(height: 14),
        ],
        const SizedBox(height: 4),
        _SubscribeBar(
          selectedPlan: selected,
          currentPlanId: currentPlanId,
          isPurchasing: purchasingPlanId != null,
          isOnFree: isOnFree,
          onSubscribe: onSubscribe,
        ),
      ],
    );
  }

  Plan? _planById(List<Plan> plans, int? id) {
    if (id == null) return null;
    for (final p in plans) {
      if (p.idPlan == id) return p;
    }
    return null;
  }
}

// ══════════════════════════════════════════════════════════════════
// Header
// ══════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  final AppLocalizations loc;
  final _PlanTab tab;
  final bool isOnFree;

  const _Header({
    required this.loc,
    required this.tab,
    required this.isOnFree,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tab.label(loc),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _subtitle(loc, tab),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  String _subtitle(AppLocalizations loc, _PlanTab tab) {
    switch (tab) {
      case _PlanTab.individual:
        return isOnFree
            ? loc.plansIndividualSubtitleFree
            : loc.plansIndividualSubtitle;
      case _PlanTab.organization:
        return isOnFree
            ? loc.plansOrganizationSubtitleFree
            : loc.plansOrganizationSubtitle;
      case _PlanTab.all:
        return isOnFree ? loc.plansAllSubtitleFree : loc.plansAllSubtitle;
    }
  }
}

// ══════════════════════════════════════════════════════════════════
// Plan card
// ══════════════════════════════════════════════════════════════════

class _PlanCard extends StatelessWidget {
  final Plan plan;
  final bool isSelected;
  final bool isCurrent;
  final bool isOnFree;

  final bool isPurchasing;
  final bool anyPurchasing;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.isSelected,
    required this.isCurrent,
    required this.isOnFree,
    required this.isPurchasing,
    required this.anyPurchasing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;

    final displayName = plan.nameFor(lang);
    final features = plan.visibleFeatures;
    final limits = _visibleLimitsFor(plan, features);
    final showAdsBadge = plan.adsEnabled == false;

    // Selection ring: current plan gets tertiary, selected gets primary.
    final ringColor = isCurrent
        ? cs.tertiary
        : isSelected
            ? cs.primary
            : cs.outlineVariant.withOpacity(0.5);
    final ringWidth = (isCurrent || isSelected) ? 2.0 : 1.0;
    final background = isSelected
        ? cs.primary.withOpacity(0.05)
        : cs.surfaceContainerHighest.withOpacity(0.35);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ringColor, width: ringWidth),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: cs.primary.withOpacity(0.14),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: anyPurchasing ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardHeader(
                  displayName: displayName,
                  isCurrent: isCurrent,
                  plan: plan,
                  loc: loc,
                  theme: theme,
                  cs: cs,
                ),
                if (showAdsBadge ||
                    features.isNotEmpty ||
                    limits.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Divider(
                    height: 1,
                    color: cs.outlineVariant.withOpacity(0.35),
                  ),
                  const SizedBox(height: 14),
                ],
                for (final feature in features) ...[
                  _FeatureRow(feature: feature, cs: cs, theme: theme),
                  const SizedBox(height: 8),
                ],
                if (limits.isNotEmpty) ...[
                  if (features.isNotEmpty || showAdsBadge)
                    const SizedBox(height: 2),
                  for (final limit in limits) ...[
                    _LimitRow(limit: limit, cs: cs, theme: theme),
                    const SizedBox(height: 6),
                  ],
                ],
                const SizedBox(height: 14),
                _CardFooter(
                  isSelected: isSelected,
                  isCurrent: isCurrent,
                  isPurchasing: isPurchasing,
                  isFree: plan.isFree,
                  loc: loc,
                  theme: theme,
                  cs: cs,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Limits to render on the card. A limit is included when:
  ///   * its value is not disabled (value != 0), and
  ///   * it is not already implied by a visible feature on the plan.
  List<PlanLimit> _visibleLimitsFor(Plan plan, List<PlanFeature> features) {
    final visibleCodes = features.map((f) => f.featureCode).toSet();

    final ordered = <PlanLimit>[];
    for (final limit in plan.limits) {
      if (limit.isDisabled) continue;

      final impliedBy = _featureImpliedBy[limit.resourceCode];
      if (impliedBy != null && visibleCodes.contains(impliedBy)) {
        continue;
      }

      ordered.add(limit);
    }
    return ordered;
  }
}

// ══════════════════════════════════════════════════════════════════
// Card header
// ══════════════════════════════════════════════════════════════════

class _CardHeader extends StatelessWidget {
  final String displayName;
  final bool isCurrent;
  final Plan plan;
  final AppLocalizations loc;
  final ThemeData theme;
  final ColorScheme cs;

  const _CardHeader({
    required this.displayName,
    required this.isCurrent,
    required this.plan,
    required this.loc,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      displayName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: cs.onSurface,
                        height: 1.15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isCurrent) ...[
                    const SizedBox(width: 8),
                    _CurrentBadge(loc: loc, cs: cs),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              _ValueAxisTag(plan: plan, cs: cs, theme: theme),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _PriceTag(plan: plan, loc: loc, cs: cs, theme: theme),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Value-axis tag
// ══════════════════════════════════════════════════════════════════

/// Small label that tells the user *what kind of upgrade* this plan is.
/// Derived from the plan name when the backend doesn't send one, so
/// this widget works with the current API and gets richer for free
/// once `value_axis` is exposed.
class _ValueAxisTag extends StatelessWidget {
  final Plan plan;
  final ColorScheme cs;
  final ThemeData theme;

  const _ValueAxisTag({
    required this.plan,
    required this.cs,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final axis = _axisFor(plan);
    if (axis == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        axis.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          fontSize: 9.5,
        ),
        maxLines: 1,
        softWrap: false,
      ),
    );
  }

  String? _axisFor(Plan plan) {
    // Prefer backend-provided value_axis when present.
    // Fallback: infer from plan type + name so the UI still works.
    final name = plan.planName?.toLowerCase() ?? '';
    if (name.contains('enterprise')) return 'Infrastructure';
    if (name.contains('business')) return 'Governance';
    if (name.contains('pro')) return 'Capability';
    if (name.contains('starter')) return 'Capability';
    if (plan.isFree) return 'Consumer';
    return null;
  }
}

// ══════════════════════════════════════════════════════════════════
// Ad-free row
// ══════════════════════════════════════════════════════════════════

// ══════════════════════════════════════════════════════════════════
// Card footer
// ══════════════════════════════════════════════════════════════════

class _CardFooter extends StatelessWidget {
  final bool isSelected;
  final bool isCurrent;
  final bool isPurchasing;
  final bool isFree;
  final AppLocalizations loc;
  final ThemeData theme;
  final ColorScheme cs;

  const _CardFooter({
    required this.isSelected,
    required this.isCurrent,
    required this.isPurchasing,
    required this.isFree,
    required this.loc,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final label = isPurchasing
        ? loc.planPurchasing
        : isCurrent
            ? loc.planCurrent
            : isSelected
                ? loc.planSelected
                : isFree
                    ? loc.planTapToActivate
                    : loc.planTapToSelect;

    final active = isSelected || isCurrent;

    return Row(
      children: [
        if (isPurchasing)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: cs.primary,
            ),
          )
        else
          _SelectionIndicator(selected: isSelected, cs: cs),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: active ? cs.primary : cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Feature row
// ══════════════════════════════════════════════════════════════════

class _FeatureRow extends StatelessWidget {
  final PlanFeature feature;
  final ColorScheme cs;
  final ThemeData theme;

  const _FeatureRow({
    required this.feature,
    required this.cs,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final name = feature.nameFor(lang);
    final description = feature.descriptionFor(lang);
    final value = feature.featureValue;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(Icons.check_rounded, size: 16, color: cs.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (value != null && value.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _FeatureValueChip(value: value, cs: cs, theme: theme),
                  ],
                ],
              ),
              if (description != null && description.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FeatureValueChip extends StatelessWidget {
  final String value;
  final ColorScheme cs;
  final ThemeData theme;

  const _FeatureValueChip({
    required this.value,
    required this.cs,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value,
        style: theme.textTheme.labelSmall?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        maxLines: 1,
        softWrap: false,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Limit row
// ══════════════════════════════════════════════════════════════════

String _limitLabel(AppLocalizations loc, String code) {
  switch (code) {
    case 'organization_owned':
      return loc.planLimitOrganizations;
    case 'provider_owned':
      return loc.planLimitProviders;
    case 'products_per_provider':
      return loc.planLimitProducts;
    case 'services_per_provider':
      return loc.planLimitServices;
    case 'locations_per_provider':
      return loc.planLimitLocations;
    case 'product_categories':
      return loc.planLimitCategories;
    case 'team_members':
      return loc.team;
    case 'ads_enabled':
      return loc.planAdsLabel;
    case 'customers':
      return loc.planLimitCustomers;
    case 'orders_monthly':
      return loc.planLimitOrders;
    case 'storage_bytes':
      return loc.planLimitStorage;
    default:
      return code;
  }
}

/// Format a limit value for display.
///   * `-1` → "∞"
///   * `-2` → "Custom" (negotiated enterprise limits)
///   * anything else → the number, with unit suffix for known byte codes
String _limitValue(AppLocalizations loc, PlanLimit limit) {
  if (limit.resourceCode == "ads_enabled") {
    return (limit.limitValue == 1)
        ? loc.planAdsValueEnabled
        : loc.planAdsValueDisabled;
  }

  if (limit.limitValue == -2) return 'Custom';
  if (limit.isUnlimited) return '∞';
  if (limit.resourceCode == 'storage_bytes') {
    const mb = 1024 * 1024;
    const gb = 1024 * mb;
    final v = limit.limitValue;
    if (v >= gb) return '${(v / gb).toStringAsFixed(0)} GB';
    return '${(v / mb).toStringAsFixed(0)} MB';
  }

  return '${limit.limitValue}';
}

class _LimitRow extends StatelessWidget {
  final PlanLimit limit;
  final ColorScheme cs;
  final ThemeData theme;

  const _LimitRow({
    required this.limit,
    required this.cs,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final label = _limitLabel(loc, limit.resourceCode);
    final value = _limitValue(loc, limit);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.w700,
            height: 1.2,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          maxLines: 1,
          softWrap: false,
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Bits
// ══════════════════════════════════════════════════════════════════

class _CurrentBadge extends StatelessWidget {
  final AppLocalizations loc;
  final ColorScheme cs;

  const _CurrentBadge({required this.loc, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.tertiary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.tertiary.withOpacity(0.4)),
      ),
      child: Text(
        loc.planCurrentBadge,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: cs.tertiary,
          letterSpacing: 0.3,
        ),
        maxLines: 1,
        softWrap: false,
      ),
    );
  }
}

class _PriceTag extends StatelessWidget {
  final Plan plan;
  final AppLocalizations loc;
  final ColorScheme cs;
  final ThemeData theme;

  const _PriceTag({
    required this.plan,
    required this.loc,
    required this.cs,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (plan.isFree) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          loc.planFree,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: cs.primary,
            letterSpacing: 0.3,
          ),
          maxLines: 1,
          softWrap: false,
        ),
      );
    }

    final cycle = plan.billingCycle;
    final monthlyEquivalent = _monthlyEquivalent(plan, cycle);
    final showMonthlyHint =
        monthlyEquivalent != null && cycle != BillingCycle.monthly;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${plan.planPrice.toStringAsFixed(0)} ${loc.currencySymbol}',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: cs.primary,
            letterSpacing: -0.3,
            height: 1.1,
          ),
          maxLines: 1,
          softWrap: false,
        ),
        const SizedBox(height: 2),
        if (showMonthlyHint)
          Text(
            '≈ ${monthlyEquivalent.toStringAsFixed(0)} ${loc.currencySymbol} / ${loc.billingCycleMonthly.toLowerCase()}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            softWrap: false,
          )
        else
          Text(
            _billingCycleLabel(loc, cycle),
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            maxLines: 1,
            softWrap: false,
          ),
        if (_savingsMonths(plan, cycle) != null) ...[
          const SizedBox(height: 4),
          _SavingsBadge(
            months: _savingsMonths(plan, cycle)!,
            loc: loc,
            cs: cs,
            theme: theme,
          ),
        ],
      ],
    );
  }

  /// Monthly-equivalent price for non-monthly cycles, so the user can
  /// compare tiers without doing arithmetic.
  double? _monthlyEquivalent(Plan plan, BillingCycle cycle) {
    switch (cycle) {
      case BillingCycle.semestrial:
        return plan.planPrice / 6;
      case BillingCycle.yearly:
        return plan.planPrice / 12;
      case BillingCycle.monthly:
      case BillingCycle.lifetime:
        return null;
    }
  }

  /// Number of free months implied by the cycle, using the "annual =
  /// 10 months" rule. Returns null when the cycle has no implied saving.
  int? _savingsMonths(Plan plan, BillingCycle cycle) {
    switch (cycle) {
      case BillingCycle.yearly:
        return 2;
      case BillingCycle.semestrial:
        return null;
      case BillingCycle.monthly:
      case BillingCycle.lifetime:
        return null;
    }
  }

  String _billingCycleLabel(AppLocalizations loc, BillingCycle cycle) {
    switch (cycle) {
      case BillingCycle.monthly:
        return loc.billingCycleMonthly;
      case BillingCycle.semestrial:
        return loc.billingCycleSemestrial;
      case BillingCycle.yearly:
        return loc.billingCycleYearly;
      case BillingCycle.lifetime:
        return loc.billingCycleLifetime;
    }
  }
}

class _SavingsBadge extends StatelessWidget {
  final int months;
  final AppLocalizations loc;
  final ColorScheme cs;
  final ThemeData theme;

  const _SavingsBadge({
    required this.months,
    required this.loc,
    required this.cs,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: cs.tertiary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cs.tertiary.withOpacity(0.35)),
      ),
      child: Text(
        '+$months ${loc.savingsMonthsLabel}',
        style: theme.textTheme.labelSmall?.copyWith(
          color: cs.tertiary,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
        maxLines: 1,
        softWrap: false,
      ),
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  final bool selected;
  final ColorScheme cs;

  const _SelectionIndicator({required this.selected, required this.cs});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? cs.primary : Colors.transparent,
        border: Border.all(
          color: selected ? cs.primary : cs.onSurfaceVariant.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: selected
          ? Icon(Icons.check_rounded, size: 14, color: cs.onPrimary)
          : null,
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Subscribe bar
// ══════════════════════════════════════════════════════════════════

class _SubscribeBar extends StatelessWidget {
  final Plan? selectedPlan;
  final int? currentPlanId;
  final bool isPurchasing;
  final bool isOnFree;
  final Future<void> Function(Plan plan) onSubscribe;

  const _SubscribeBar({
    required this.selectedPlan,
    required this.currentPlanId,
    required this.isPurchasing,
    required this.isOnFree,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;

    final plan = selectedPlan;

    // When the user is on Free and Free is selected (or nothing is
    // selected), there is nothing to do here. Hide the bar entirely
    // rather than show a disabled "Subscribe" button.
    if (plan == null && isOnFree) {
      return const SizedBox.shrink();
    }

    final isCurrent = plan != null && plan.idPlan == currentPlanId;
    final isFree = plan != null && plan.isFree;

    final enabled = plan != null && !isCurrent && !isPurchasing;

    final label = plan == null
        ? loc.planSelectPrompt
        : isCurrent
            ? loc.planAlreadyActive
            : isFree
                ? loc.planActivate
                : loc.planSubscribeNow;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (plan != null) ...[
          _SelectionSummary(plan: plan, loc: loc, theme: theme, cs: cs),
          const SizedBox(height: 12),
        ],
        SizedBox(
          height: 56,
          child: FilledButton.icon(
            onPressed: enabled ? () => onSubscribe(plan) : null,
            icon: isPurchasing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    isFree
                        ? Icons.check_circle_rounded
                        : Icons.shopping_cart_checkout_rounded,
                    size: 20,
                  ),
            label: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: 0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: FilledButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              disabledBackgroundColor: cs.onSurface.withOpacity(0.12),
              disabledForegroundColor: cs.onSurface.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectionSummary extends StatelessWidget {
  final Plan plan;
  final AppLocalizations loc;
  final ThemeData theme;
  final ColorScheme cs;

  const _SelectionSummary({
    required this.plan,
    required this.loc,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final isFree = plan.isFree;
    final lang = Localizations.localeOf(context).languageCode;
    final displayName = plan.nameFor(lang);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.planSelectedLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            isFree
                ? loc.planFree
                : '${plan.planPrice.toStringAsFixed(0)} ${loc.currencySymbol}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.primary,
            ),
            maxLines: 1,
            softWrap: false,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Payment method sheet
// ══════════════════════════════════════════════════════════════════

class _PaymentMethodSheet extends StatelessWidget {
  final AppLocalizations loc;

  const _PaymentMethodSheet({required this.loc});

  static const _methods = <_PaymentMethod>[
    _PaymentMethod('cash', Icons.payments_rounded),
    _PaymentMethod('card', Icons.credit_card_rounded),
    _PaymentMethod('bank', Icons.account_balance_rounded),
    _PaymentMethod('mobile', Icons.smartphone_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: cs.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              loc.choosePaymentMethod,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            for (final m in _methods)
              _PaymentMethodTile(
                method: m,
                loc: loc,
                onTap: () => Navigator.of(context).pop(m.id),
              ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethod {
  final String id;
  final IconData icon;

  const _PaymentMethod(this.id, this.icon);
}

class _PaymentMethodTile extends StatelessWidget {
  final _PaymentMethod method;
  final AppLocalizations loc;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    required this.method,
    required this.loc,
    required this.onTap,
  });

  String _label() {
    switch (method.id) {
      case 'cash':
        return loc.cash;
      case 'card':
        return loc.card;
      case 'bank':
        return loc.bankTransfer;
      case 'mobile':
        return loc.mobileMoney;
      default:
        return method.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: cs.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(method.icon, size: 22, color: cs.primary),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    _label(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Empty states
// ══════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 80),
        Icon(
          Icons.workspace_premium_outlined,
          size: 64,
          color: cs.onSurfaceVariant.withOpacity(0.4),
        ),
        const SizedBox(height: 16),
        Text(
          loc.noPlansAvailable,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          loc.noPlansAvailableMessage,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Center(
          child: OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(loc.retryButton),
          ),
        ),
      ],
    );
  }
}

class _TabEmptyState extends StatelessWidget {
  final _PlanTab tab;
  final AppLocalizations loc;
  final Future<void> Function() onRefresh;

  const _TabEmptyState({
    required this.tab,
    required this.loc,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 80),
        Icon(
          _iconFor(tab),
          size: 56,
          color: cs.onSurfaceVariant.withOpacity(0.4),
        ),
        const SizedBox(height: 16),
        Text(
          _title(loc, tab),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _message(loc, tab),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Center(
          child: OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(loc.retryButton),
          ),
        ),
      ],
    );
  }

  IconData _iconFor(_PlanTab tab) {
    switch (tab) {
      case _PlanTab.individual:
        return Icons.person_outline_rounded;
      case _PlanTab.organization:
        return Icons.business_outlined;
      case _PlanTab.all:
        return Icons.workspace_premium_outlined;
    }
  }

  String _title(AppLocalizations loc, _PlanTab tab) {
    switch (tab) {
      case _PlanTab.individual:
        return loc.plansIndividualEmptyTitle;
      case _PlanTab.organization:
        return loc.plansOrganizationEmptyTitle;
      case _PlanTab.all:
        return loc.noPlansAvailable;
    }
  }

  String _message(AppLocalizations loc, _PlanTab tab) {
    switch (tab) {
      case _PlanTab.individual:
        return loc.plansIndividualEmptyMessage;
      case _PlanTab.organization:
        return loc.plansOrganizationEmptyMessage;
      case _PlanTab.all:
        return loc.noPlansAvailableMessage;
    }
  }
}
