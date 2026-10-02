import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:event/views/finance_view_model.dart';

/// Segmented navigation for the finance screen.
///
/// The list of tabs is derived from the [FinanceTab] enum so this widget
/// can't drift out of sync with the view model. If a tab is added to the
/// enum, it shows up here automatically (as long as `_configFor` handles it).
class TabNavigation extends StatelessWidget {
  final int currentTab;
  final ValueChanged<int> onTabSelected;

  const TabNavigation({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;

    // Drive off the enum so we can never be "missing" a tab.
    final tabs = FinanceTab.values;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 56,
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final tab = tabs[index];
          return _TabItem(
            index: index,
            icon: _iconFor(tab),
            label: _labelFor(tab, loc),
            isSelected: currentTab == index,
            onTap: () {
              if (index != currentTab) onTabSelected(index);
            },
          );
        }),
      ),
    );
  }

  IconData _iconFor(FinanceTab tab) {
    switch (tab) {
      case FinanceTab.invoices:
        return Icons.receipt_long_rounded;
      case FinanceTab.businessOperations:
        return Icons.insights_rounded;
      case FinanceTab.pricingConfig:
        return Icons.price_change_rounded;
    }
  }

  String _labelFor(FinanceTab tab, AppLocalizations loc) {
    switch (tab) {
      case FinanceTab.invoices:
        return loc.invoices;
      case FinanceTab.businessOperations:
        // Add `loc.businessOperations` to your ARB. Until then, fall back
        // to the enum's title so the label isn't empty.
        return loc.businessOperations;
      case FinanceTab.pricingConfig:
        return loc.pricing;
    }
  }
}

class _TabItem extends StatelessWidget {
  final int index;
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabItem({
    required this.index,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
