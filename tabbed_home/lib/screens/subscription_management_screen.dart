import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:verdelia_core/app/finance/Plan.dart';
import 'package:verdelia_core/app/finance/Subscription.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

import 'package:app_constants/app_routes.dart';
import 'package:event/preferenceChangeNotifier.dart';
import 'package:event/user_change_notifier.dart';

/// Manage the current subscription: view status, plan details,
/// renewal date, and take action (cancel, upgrade).
///
/// Reads everything from [AppUserNotifier]. All writes go through the
/// same notifier, so the profile screen and any other screen showing
/// subscription state rebuilds immediately on success.
class SubscriptionManagementScreen extends StatefulWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  State<SubscriptionManagementScreen> createState() =>
      _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState
    extends State<SubscriptionManagementScreen> {
  /// Set while a mutating action (cancel) is in flight. Blocks the
  /// action button and shows a spinner.
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    // Fire-and-forget. The screen renders whatever the notifier
    // already has and updates when the fetch resolves.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = context.read<AppUserNotifier>();
      notifier.fetchSubscription(forceRefresh: true);
      // Also make sure the plan catalogue is loaded so we can show
      // the plan name and price.
      notifier.ensurePlansLoaded().catchError((_) => <Plan>[]);
    });
  }

  // ══════════════════════════════════════════════════════════════════
  // Actions
  // ══════════════════════════════════════════════════════════════════

  Future<void> _refresh() async {
    final notifier = context.read<AppUserNotifier>();
    await Future.wait([
      notifier.fetchSubscription(forceRefresh: true),
      notifier
          .ensurePlansLoaded(forceRefresh: true)
          .catchError((_) => <Plan>[]),
    ]);
  }

  Future<void> _openPlans() async {
    HapticFeedback.selectionClick();
    final changed = await Navigator.pushNamed(context, AppRoutes.plans);
    if (changed == true && mounted) {
      // The plans screen updated the notifier's subscription state,
      // but a fresh fetch guarantees we're in sync with the backend.
      await context.read<AppUserNotifier>().fetchSubscription(
            forceRefresh: true,
          );
    }
  }

  Future<void> _cancelSubscription() async {
    if (_isCancelling) return;

    final confirmed = await _confirmCancel();
    if (confirmed != true || !mounted) return;

    final notifier = context.read<AppUserNotifier>();
    final loc = AppLocalizations.of(context)!;

    setState(() => _isCancelling = true);
    final result = await notifier.cancelSubscription();
    if (!mounted) return;
    setState(() => _isCancelling = false);

    if (result != null) {
      _showSuccess(loc.subscriptionCancelled);
    } else {
      _showError(loc.subscriptionCancelFailed);
    }
  }

  Future<bool?> _confirmCancel() {
    final loc = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final cs = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          icon: Icon(
            Icons.warning_amber_rounded,
            color: cs.error,
            size: 40,
          ),
          title: Text(loc.cancelSubscriptionTitle),
          content: Text(
            loc.cancelSubscriptionConfirmation,
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(loc.keepSubscription),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: cs.error,
                foregroundColor: cs.onError,
              ),
              child: Text(loc.confirmCancel),
            ),
          ],
        );
      },
    );
  }

  void _showSuccess(String message) {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: cs.onPrimaryContainer,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: cs.primaryContainer,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(12),
        ),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.manageSubscriptionTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: loc.refresh,
            onPressed: _refresh,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: Consumer<AppUserNotifier>(
            builder: (context, notifier, _) {
              final subscription = notifier.subscription;
              final isFetching = notifier.isFetchingSubscription;

              // First-load spinner: no subscription yet AND the
              // fetch hasn't resolved. On a user with no
              // subscription, the fetch returns null and we fall
              // through to the empty state below.
              if (isFetching && subscription == null) {
                return const Center(child: CircularProgressIndicator());
              }

              if (subscription == null) {
                return _NoSubscriptionState(onBrowsePlans: _openPlans);
              }

              final plan = notifier.planById(subscription.subscriptionPlanId);

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  _StatusCard(subscription: subscription, loc: loc),
                  const SizedBox(height: 16),
                  _PlanDetailsCard(
                    subscription: subscription,
                    plan: plan,
                    loc: loc,
                  ),
                  const SizedBox(height: 16),
                  _BillingCard(subscription: subscription, loc: loc),
                  const SizedBox(height: 24),
                  _ActionsSection(
                    subscription: subscription,
                    isCancelling: _isCancelling,
                    onUpgrade: _openPlans,
                    onCancel:
                        subscription.isActive ? _cancelSubscription : null,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Status card — the hero
// ══════════════════════════════════════════════════════════════════

class _StatusCard extends StatelessWidget {
  final Subscription subscription;
  final AppLocalizations loc;

  const _StatusCard({required this.subscription, required this.loc});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isActive = subscription.isActive;

    // Two visual treatments: active (primary-tinted) and inactive
    // (neutral-tinted). The gradient on active mirrors the profile
    // hero so the screens feel related.
    final accent = isActive ? cs.primary : cs.onSurfaceVariant;
    final bgTop = isActive
        ? cs.primary.withOpacity(0.10)
        : cs.surfaceContainerHighest.withOpacity(0.4);
    final bgBottom = isActive
        ? cs.tertiary.withOpacity(0.06)
        : cs.surfaceContainerHighest.withOpacity(0.25);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bgTop, bgBottom],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(0.22), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isActive
                      ? Icons.workspace_premium_rounded
                      : Icons.workspace_premium_outlined,
                  color: accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isActive
                          ? loc.subscriptionStatusActive
                          : loc.subscriptionStatusInactive,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: accent,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isActive
                          ? loc.subscriptionStatusActiveHint
                          : loc.subscriptionStatusInactiveHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isActive && subscription.subscriptionExpiry != null) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.event_available_rounded,
                  size: 16,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc.subscriptionRenewsOn(
                      _formatDate(context, subscription.subscriptionExpiry!),
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final locale =
        context.read<LocaleProvider>().locale?.toLanguageTag() ?? 'en';
    return DateFormat.yMMMd(locale).format(date.toLocal());
  }
}

// ══════════════════════════════════════════════════════════════════
// Plan details card
// ══════════════════════════════════════════════════════════════════

class _PlanDetailsCard extends StatelessWidget {
  final Subscription subscription;
  final Plan? plan;
  final AppLocalizations loc;

  const _PlanDetailsCard({
    required this.subscription,
    required this.plan,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <_DetailRow>[
      if (plan != null)
        _DetailRow(
          icon: Icons.card_membership_outlined,
          label: loc.subscriptionPlanText,
          value: plan!.planName,
        ),
      if (plan != null)
        _DetailRow(
          icon: Icons.payments_outlined,
          label: loc.subscriptionPriceText,
          value: '${plan!.planPrice.toStringAsFixed(2)} ${loc.currencySymbol}',
        ),
      if (plan != null)
        _DetailRow(
          icon: Icons.repeat_outlined,
          label: loc.billingCycleText,
          value: _billingCycleLabel(loc, plan!.billingCycle),
        ),
      _DetailRow(
        icon: Icons.speed_outlined,
        label: loc.subscriptionQuotaText,
        value: subscription.subscriptionQuota?.toString() ?? '—',
      ),
    ];

    return _Section(
      icon: Icons.info_outline_rounded,
      title: loc.subscriptionDetailsSection,
      children: rows,
    );
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

// ══════════════════════════════════════════════════════════════════
// Billing card — dates and id
// ══════════════════════════════════════════════════════════════════

class _BillingCard extends StatelessWidget {
  final Subscription subscription;
  final AppLocalizations loc;

  const _BillingCard({required this.subscription, required this.loc});

  @override
  Widget build(BuildContext context) {
    final rows = <_DetailRow>[
      if (subscription.subscriptionCreatedAt != null)
        _DetailRow(
          icon: Icons.event_available_outlined,
          label: loc.subscriptionCreatedText,
          value: _formatDateTime(context, subscription.subscriptionCreatedAt!),
        ),
      _DetailRow(
        icon: Icons.event_outlined,
        label: loc.subscriptionExpiryText,
        value: subscription.subscriptionExpiry == null
            ? loc.subscriptionNeverExpiresLabel
            : _formatDateTime(context, subscription.subscriptionExpiry!),
      ),
      if (subscription.idSubscription != null)
        _DetailRow(
          icon: Icons.tag_rounded,
          label: loc.subscriptionIdLabel,
          value: '#${subscription.idSubscription}',
          copyable: true,
        ),
    ];

    return _Section(
      icon: Icons.receipt_long_outlined,
      title: loc.subscriptionBillingSection,
      children: rows,
    );
  }

  String _formatDateTime(BuildContext context, DateTime date) {
    final locale =
        context.read<LocaleProvider>().locale?.toLanguageTag() ?? 'en';
    return DateFormat.yMMMd(locale).add_Hm().format(date.toLocal());
  }
}

// ══════════════════════════════════════════════════════════════════
// Actions
// ══════════════════════════════════════════════════════════════════

class _ActionsSection extends StatelessWidget {
  final Subscription subscription;
  final bool isCancelling;
  final VoidCallback onUpgrade;
  final VoidCallback? onCancel;

  const _ActionsSection({
    required this.subscription,
    required this.isCancelling,
    required this.onUpgrade,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;

    final canCancel = onCancel != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: onUpgrade,
            icon: const Icon(Icons.upgrade_rounded, size: 20),
            label: Text(
              loc.subscriptionChangePlan,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        if (canCancel) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: isCancelling ? null : onCancel,
              icon: isCancelling
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : Icon(
                      Icons.cancel_outlined,
                      size: 20,
                      color: cs.error,
                    ),
              label: Text(
                loc.subscriptionCancel,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: isCancelling ? cs.onSurfaceVariant : cs.error,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isCancelling
                      ? cs.outlineVariant
                      : cs.error.withOpacity(0.4),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Empty state
// ══════════════════════════════════════════════════════════════════

class _NoSubscriptionState extends StatelessWidget {
  final VoidCallback onBrowsePlans;

  const _NoSubscriptionState({required this.onBrowsePlans});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.workspace_premium_outlined,
                size: 48,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              loc.noActiveSubscriptionTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              loc.noActiveSubscriptionMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: onBrowsePlans,
                icon: const Icon(Icons.rocket_launch_rounded, size: 20),
                label: Text(
                  loc.browsePlans,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Shared pieces
// ══════════════════════════════════════════════════════════════════

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<_DetailRow> children;

  const _Section({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(icon, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 50,
                endIndent: 16,
                color: cs.outlineVariant.withOpacity(0.4),
              ),
          ],
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool copyable;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.copyable = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: cs.onSurfaceVariant.withOpacity(0.7)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (copyable)
            Icon(
              Icons.content_copy_rounded,
              size: 14,
              color: cs.onSurfaceVariant.withOpacity(0.4),
            ),
        ],
      ),
    );

    if (!copyable) return content;

    return InkWell(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: value));
        if (!context.mounted) return;
        final loc = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(loc.copiedToClipboard(label)),
              duration: const Duration(milliseconds: 1200),
              behavior: SnackBarBehavior.floating,
              width: 260,
            ),
          );
      },
      child: content,
    );
  }
}
