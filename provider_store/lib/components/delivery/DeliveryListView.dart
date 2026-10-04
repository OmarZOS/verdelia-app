import 'package:flutter/material.dart';
import 'package:event/delivery_change_notifier.dart';
import 'package:verdelia_core/business/Delivery.dart';
import 'package:provider_store/components/delivery/DeliveryCard.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

/// DeliveryListView — displays deliveries filtered by one or more
/// lifecycle statuses. The status set comes from the caller (the
/// tabbed view builds it from the current phase and the active chip);
/// this widget just renders the slice.
class DeliveryListView extends StatelessWidget {
  /// Statuses to include. A single status narrows to that state; a
  /// list shows the union of the states. An empty list means
  /// "everything".
  final List<DeliveryStatus> statuses;

  final DeliveryChangeNotifier notifier;

  /// Optional empty-state overrides. When null, the widget derives
  /// localized copy from the status set it was asked to show.
  final String? emptyTitle;
  final String? emptyMessage;

  const DeliveryListView({
    super.key,
    required this.statuses,
    required this.notifier,
    this.emptyTitle,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    final deliveries = _filteredDeliveries(notifier);
    final isLoading = notifier.isLoading;

    // Show loading only if we're loading AND have no data.
    if (isLoading && deliveries.isEmpty) {
      return const _LoadingShimmer();
    }

    if (deliveries.isEmpty) {
      return _EmptyState(
        statuses: statuses,
        titleOverride: emptyTitle,
        messageOverride: emptyMessage,
      );
    }

    return RefreshIndicator.adaptive(
      onRefresh: notifier.refreshDeliveries,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: deliveries.length,
        itemBuilder: (context, index) {
          final delivery = deliveries[index];
          return DeliveryCard(
            delivery: delivery,
            notifier: notifier,
          );
        },
      ),
    );
  }

  /// Filter the notifier's current list by the requested status set.
  /// When `statuses` is empty, everything passes.
  List<Delivery> _filteredDeliveries(DeliveryChangeNotifier n) {
    final all = n.searchQuery.isNotEmpty ? n.searchResults : n.deliveries;
    if (statuses.isEmpty) return all;
    final wanted = statuses.toSet();
    return all.where((d) => wanted.contains(d.delivery_status)).toList();
  }
}

// ============================================================================
// LOADING
// ============================================================================

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: CircularProgressIndicator.adaptive(),
          ),
        );
      },
    );
  }
}

// ============================================================================
// EMPTY STATE
// ============================================================================

class _EmptyState extends StatelessWidget {
  final List<DeliveryStatus> statuses;
  final String? titleOverride;
  final String? messageOverride;

  const _EmptyState({
    required this.statuses,
    this.titleOverride,
    this.messageOverride,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final cfg = _configFor(statuses, l10n);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cfg.color.withOpacity(0.10),
              ),
              child: Icon(cfg.icon, size: 48, color: cfg.color),
            ),
            const SizedBox(height: 24),
            Text(
              titleOverride ?? cfg.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              messageOverride ?? cfg.message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Pick a representative icon, color, and localized copy for the
  /// status set being shown. A single status gives a specific message;
  /// a set (a phase, or everything) gives a phase-level message.
  static _EmptyConfig _configFor(
    List<DeliveryStatus> statuses,
    AppLocalizations l10n,
  ) {
    if (statuses.isEmpty) {
      return _EmptyConfig(
        icon: Icons.local_shipping_outlined,
        title: l10n.deliveriesEmptyGenericTitle,
        message: l10n.deliveriesEmptyGenericMessage,
        color: Colors.grey,
      );
    }

    if (statuses.length == 1) {
      return _configForSingle(statuses.single, l10n);
    }

    return _configForPhase(statuses, l10n);
  }

  static _EmptyConfig _configForSingle(
    DeliveryStatus status,
    AppLocalizations l10n,
  ) {
    switch (status) {
      case DeliveryStatus.pending:
        return _EmptyConfig(
          icon: Icons.schedule_outlined,
          title: l10n.deliveriesEmptyPendingTitle,
          message: l10n.deliveriesEmptyPendingMessage,
          color: const Color(0xFFF59E0B),
        );
      case DeliveryStatus.processing:
        return _EmptyConfig(
          icon: Icons.hourglass_top_outlined,
          title: l10n.deliveriesEmptyProcessingTitle,
          message: l10n.deliveriesEmptyProcessingMessage,
          color: const Color(0xFF3B82F6),
        );
      case DeliveryStatus.confirmed:
        return _EmptyConfig(
          icon: Icons.verified_outlined,
          title: l10n.deliveriesEmptyConfirmedTitle,
          message: l10n.deliveriesEmptyConfirmedMessage,
          color: const Color(0xFF0EA5E9),
        );
      case DeliveryStatus.shipped:
        return _EmptyConfig(
          icon: Icons.inventory_2_outlined,
          title: l10n.deliveriesEmptyShippedTitle,
          message: l10n.deliveriesEmptyShippedMessage,
          color: const Color(0xFF8B5CF6),
        );
      case DeliveryStatus.inTransit:
        return _EmptyConfig(
          icon: Icons.route_outlined,
          title: l10n.deliveriesEmptyInTransitTitle,
          message: l10n.deliveriesEmptyInTransitMessage,
          color: const Color(0xFF8B5CF6),
        );
      case DeliveryStatus.outForDelivery:
        return _EmptyConfig(
          icon: Icons.delivery_dining_outlined,
          title: l10n.deliveriesEmptyOutForDeliveryTitle,
          message: l10n.deliveriesEmptyOutForDeliveryMessage,
          color: const Color(0xFFF97316),
        );
      case DeliveryStatus.delivered:
        return _EmptyConfig(
          icon: Icons.check_circle_outline_rounded,
          title: l10n.deliveriesEmptyDeliveredTitle,
          message: l10n.deliveriesEmptyDeliveredMessage,
          color: const Color(0xFF10B981),
        );
      case DeliveryStatus.failed:
        return _EmptyConfig(
          icon: Icons.error_outline_rounded,
          title: l10n.deliveriesEmptyFailedTitle,
          message: l10n.deliveriesEmptyFailedMessage,
          color: const Color(0xFFEF4444),
        );
      case DeliveryStatus.cancelled:
        return _EmptyConfig(
          icon: Icons.cancel_outlined,
          title: l10n.deliveriesEmptyCancelledTitle,
          message: l10n.deliveriesEmptyCancelledMessage,
          color: const Color(0xFF6B7280),
        );
      case DeliveryStatus.returned:
        return _EmptyConfig(
          icon: Icons.assignment_return_outlined,
          title: l10n.deliveriesEmptyReturnedTitle,
          message: l10n.deliveriesEmptyReturnedMessage,
          color: const Color(0xFFF59E0B),
        );
      case DeliveryStatus.refunded:
        return _EmptyConfig(
          icon: Icons.replay_rounded,
          title: l10n.deliveriesEmptyRefundedTitle,
          message: l10n.deliveriesEmptyRefundedMessage,
          color: const Color(0xFF06B6D4),
        );
    }
  }

  /// Config for a phase: pick an icon and copy that reflects the
  /// aggregate, not any single status.
  static _EmptyConfig _configForPhase(
    List<DeliveryStatus> statuses,
    AppLocalizations l10n,
  ) {
    final s = statuses.toSet();

    final active = {
      DeliveryStatus.pending,
      DeliveryStatus.processing,
      DeliveryStatus.confirmed,
    };
    final inFlight = {
      DeliveryStatus.shipped,
      DeliveryStatus.inTransit,
      DeliveryStatus.outForDelivery,
    };
    final closed = {
      DeliveryStatus.delivered,
      DeliveryStatus.failed,
      DeliveryStatus.cancelled,
      DeliveryStatus.returned,
      DeliveryStatus.refunded,
    };

    if (s.containsAll(active) && s.length == active.length) {
      return _EmptyConfig(
        icon: Icons.schedule_outlined,
        title: l10n.deliveriesEmptyActiveTitle,
        message: l10n.deliveriesEmptyActiveMessage,
        color: const Color(0xFF3B82F6),
      );
    }

    if (s.containsAll(inFlight) && s.length == inFlight.length) {
      return _EmptyConfig(
        icon: Icons.local_shipping_outlined,
        title: l10n.deliveriesEmptyInFlightTitle,
        message: l10n.deliveriesEmptyInFlightMessage,
        color: const Color(0xFF8B5CF6),
      );
    }

    if (s.containsAll(closed) && s.length == closed.length) {
      return _EmptyConfig(
        icon: Icons.inventory_2_outlined,
        title: l10n.deliveriesEmptyClosedTitle,
        message: l10n.deliveriesEmptyClosedMessage,
        color: const Color(0xFF6B7280),
      );
    }

    return _EmptyConfig(
      icon: Icons.filter_list_off_rounded,
      title: l10n.deliveriesEmptyFilteredTitle,
      message: l10n.deliveriesEmptyFilteredMessage,
      color: Colors.grey,
    );
  }
}

class _EmptyConfig {
  final IconData icon;
  final String title;
  final String message;
  final Color color;

  const _EmptyConfig({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });
}
