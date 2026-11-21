import 'package:flutter/material.dart';
import 'package:verdelia_core/business/finance/OrderedItem.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

class FulfilmentRollup {
  final int total;
  final int delivered;
  final int inTransit;
  final int pending;
  final int partial;
  final int cancelled;

  const FulfilmentRollup({
    required this.total,
    required this.delivered,
    required this.inTransit,
    required this.pending,
    required this.partial,
    required this.cancelled,
  });

  static const empty = FulfilmentRollup(
    total: 0,
    delivered: 0,
    inTransit: 0,
    pending: 0,
    partial: 0,
    cancelled: 0,
  );

  bool get allDelivered => total > 0 && delivered == total;

  factory FulfilmentRollup.fromItems(List<OrderedItem> items) {
    if (items.isEmpty) return empty;
    var delivered = 0;
    var inTransit = 0;
    var pending = 0;
    var partial = 0;
    var cancelled = 0;
    for (final item in items) {
      switch ((item.orderedItemDeliveryStatus ?? '').toLowerCase().trim()) {
        case 'delivered':
          delivered++;
          break;
        case 'shipped':
        case 'in_transit':
        case 'out_for_delivery':
          inTransit++;
          break;
        case 'partial':
          partial++;
          break;
        case 'cancelled':
        case 'canceled':
        case 'returned':
        case 'refunded':
          cancelled++;
          break;
        default:
          pending++;
      }
    }
    return FulfilmentRollup(
      total: items.length,
      delivered: delivered,
      inTransit: inTransit,
      pending: pending,
      partial: partial,
      cancelled: cancelled,
    );
  }
}

class FulfilmentStrip extends StatelessWidget {
  final FulfilmentRollup rollup;

  const FulfilmentStrip({super.key, required this.rollup});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 5,
            child: Row(
              children: [
                if (rollup.delivered > 0)
                  Expanded(
                    flex: rollup.delivered,
                    child: ColoredBox(color: Colors.green.shade600),
                  ),
                if (rollup.inTransit > 0)
                  Expanded(
                    flex: rollup.inTransit,
                    child: ColoredBox(color: Colors.blue.shade500),
                  ),
                if (rollup.partial > 0)
                  Expanded(
                    flex: rollup.partial,
                    child: ColoredBox(color: Colors.amber.shade600),
                  ),
                if (rollup.pending > 0)
                  Expanded(
                    flex: rollup.pending,
                    child: ColoredBox(
                      color:
                          theme.colorScheme.onSurfaceVariant.withOpacity(0.35),
                    ),
                  ),
                if (rollup.cancelled > 0)
                  Expanded(
                    flex: rollup.cancelled,
                    child: ColoredBox(
                      color: theme.colorScheme.error.withOpacity(0.6),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _label(rollup, loc),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  String _label(FulfilmentRollup r, AppLocalizations loc) {
    if (r.total == 0) return '';
    if (r.allDelivered) return loc.allItemsDeliveredTxt;
    final parts = <String>[];
    if (r.delivered > 0) {
      parts.add('${r.delivered} ${loc.deliveredTxt.toLowerCase()}');
    }
    if (r.inTransit > 0) {
      parts.add('${r.inTransit} ${loc.inTransitTxt.toLowerCase()}');
    }
    if (r.partial > 0) {
      parts.add('${r.partial} ${loc.partial.toLowerCase()}');
    }
    if (r.pending > 0) {
      parts.add('${r.pending} ${loc.pendingTxt.toLowerCase()}');
    }
    if (r.cancelled > 0) {
      parts.add('${r.cancelled} ${loc.cancelledTxt.toLowerCase()}');
    }
    return parts.join(' · ');
  }
}

class FulfilmentSummaryCard extends StatelessWidget {
  final FulfilmentRollup rollup;

  const FulfilmentSummaryCard({super.key, required this.rollup});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final total = rollup.total;
    final ratio = total == 0 ? 0.0 : rollup.delivered / total;

    Widget countPill(String label, int n, Color color) {
      if (n == 0) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$n $label',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                ratio >= 1.0
                    ? Icons.check_circle
                    : ratio > 0
                        ? Icons.local_shipping_outlined
                        : Icons.schedule,
                size: 18,
                color: ratio >= 1.0
                    ? Colors.green.shade600
                    : ratio > 0
                        ? Colors.blue.shade500
                        : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                loc.fulfilmentLabel,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '${rollup.delivered}/$total',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  if (rollup.delivered > 0)
                    Expanded(
                      flex: rollup.delivered,
                      child: ColoredBox(color: Colors.green.shade600),
                    ),
                  if (rollup.inTransit > 0)
                    Expanded(
                      flex: rollup.inTransit,
                      child: ColoredBox(color: Colors.blue.shade500),
                    ),
                  if (rollup.partial > 0)
                    Expanded(
                      flex: rollup.partial,
                      child: ColoredBox(color: Colors.amber.shade600),
                    ),
                  if (rollup.pending > 0)
                    Expanded(
                      flex: rollup.pending,
                      child: ColoredBox(
                        color: theme.colorScheme.onSurfaceVariant
                            .withOpacity(0.35),
                      ),
                    ),
                  if (rollup.cancelled > 0)
                    Expanded(
                      flex: rollup.cancelled,
                      child: ColoredBox(
                        color: theme.colorScheme.error.withOpacity(0.6),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            children: [
              countPill(
                  loc.deliveredTxt, rollup.delivered, Colors.green.shade700),
              countPill(
                  loc.inTransitTxt, rollup.inTransit, Colors.blue.shade700),
              countPill(loc.partial, rollup.partial, Colors.amber.shade800),
              countPill(loc.pendingTxt, rollup.pending,
                  theme.colorScheme.onSurfaceVariant),
              countPill(
                  loc.cancelledTxt, rollup.cancelled, theme.colorScheme.error),
            ],
          ),
        ],
      ),
    );
  }
}
