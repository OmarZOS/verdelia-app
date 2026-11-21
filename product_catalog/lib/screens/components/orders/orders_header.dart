import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:verdelia_core/business/finance/Order.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

class OrdersHeader extends StatelessWidget {
  final List<Order> orders;
  final int outstandingCount;
  final Decimal outstandingAmount;

  const OrdersHeader({
    super.key,
    required this.orders,
    required this.outstandingCount,
    required this.outstandingAmount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    final totalSpent =
        orders.fold(Decimal.zero, (sum, o) => sum + o.totalPrice);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withOpacity(0.5),
            theme.colorScheme.primaryContainer.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loc.yourOrderStats,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                loc.price(totalSpent.toStringAsFixed(2)),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatPill(
                value: orders.length.toString(),
                label: loc.ordersText,
                icon: Icons.inventory_2_outlined,
              ),
              const SizedBox(width: 10),
              _StatPill(
                value: orders
                    .where((o) => o.isPending || o.isProcessing || o.isShipped)
                    .length
                    .toString(),
                label: loc.inProgressTxt,
                icon: Icons.pending_actions_outlined,
              ),
              const SizedBox(width: 10),
              _StatPill(
                value: orders.where((o) => o.isCompleted).length.toString(),
                label: loc.completedTxt,
                icon: Icons.check_circle_outline,
              ),
            ],
          ),
          if (outstandingCount > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    loc.outstandingSummaryTxt(
                      outstandingCount,
                      loc.price(outstandingAmount.toStringAsFixed(2)),
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatPill({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
