import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

enum OrderTab { all, inProgress, completed, cancelled }

class OrderTabBarDelegate extends SliverPersistentHeaderDelegate {
  final OrderTab tab;
  final ValueChanged<OrderTab> onChanged;
  final Map<OrderTab, int> counts;
  final bool hidden;

  OrderTabBarDelegate({
    required this.tab,
    required this.onChanged,
    required this.counts,
    this.hidden = false,
  });

  @override
  double get minExtent => 56;

  @override
  double get maxExtent => 56;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return SizedBox(
      height: 56,
      child: hidden
          ? const SizedBox.shrink()
          : Container(
              color: theme.colorScheme.surface,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _TabChip(
                      tab: tab,
                      target: OrderTab.all,
                      label: loc.ordersText,
                      count: counts[OrderTab.all] ?? 0,
                      onChanged: onChanged,
                    ),
                    const SizedBox(width: 8),
                    _TabChip(
                      tab: tab,
                      target: OrderTab.inProgress,
                      label: loc.inProgressTxt,
                      count: counts[OrderTab.inProgress] ?? 0,
                      onChanged: onChanged,
                    ),
                    const SizedBox(width: 8),
                    _TabChip(
                      tab: tab,
                      target: OrderTab.completed,
                      label: loc.completedTxt,
                      count: counts[OrderTab.completed] ?? 0,
                      onChanged: onChanged,
                    ),
                    const SizedBox(width: 8),
                    _TabChip(
                      tab: tab,
                      target: OrderTab.cancelled,
                      label: loc.cancelledTxt,
                      count: counts[OrderTab.cancelled] ?? 0,
                      onChanged: onChanged,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  bool shouldRebuild(covariant OrderTabBarDelegate oldDelegate) {
    return oldDelegate.tab != tab ||
        oldDelegate.counts != counts ||
        oldDelegate.hidden != hidden;
  }
}

class _TabChip extends StatelessWidget {
  final OrderTab tab;
  final OrderTab target;
  final String label;
  final int count;
  final ValueChanged<OrderTab> onChanged;

  const _TabChip({
    required this.tab,
    required this.target,
    required this.label,
    required this.count,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = tab == target;
    return GestureDetector(
      onTap: () => onChanged(target),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceVariant.withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: selected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? theme.colorScheme.onPrimary.withOpacity(0.2)
                    : theme.colorScheme.onSurfaceVariant.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
