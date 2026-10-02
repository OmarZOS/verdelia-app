import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:event/personnel_notifier.dart';
import 'package:event/supplier_change_notifier.dart';
import 'package:provider/provider.dart';

class PerformanceIndicator extends StatelessWidget {
  final String searchQuery;
  final int? selectedCategoryId;

  const PerformanceIndicator({
    super.key,
    required this.searchQuery,
    this.selectedCategoryId,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<SupplierChangeNotifier, PersonnelNotifier>(
      builder: (context, supplierNotifier, personnelNotifier, child) {
        final totalSuppliers = supplierNotifier.suppliers.length;

        // Filter suppliers by selected category
        final filteredSuppliers =
            selectedCategoryId == null || selectedCategoryId == 0
                ? supplierNotifier.suppliers
                : supplierNotifier.suppliers
                    .where((s) =>
                        s.productProviderTypeId ==
                        selectedCategoryId) // Replace with your actual field
                    .toList();

        final activeBusinesses = filteredSuppliers.length;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPerformanceItem(
                context: context,
                label: AppLocalizations.of(context)!.totalTxt,
                value: '$totalSuppliers',
                icon: Icons.business_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              _buildPerformanceItem(
                context: context,
                label: AppLocalizations.of(context)!.filteredTxt,
                value: '$activeBusinesses',
                icon: Icons.filter_list_rounded,
                color: Theme.of(context).colorScheme.secondary,
              ),
              _buildPerformanceItem(
                context: context,
                label: AppLocalizations.of(context)!.categories,
                value: '${_countCategories(supplierNotifier.suppliers)}',
                icon: Icons.category_rounded,
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ],
          ),
        );
      },
    );
  }

  int _countCategories(List suppliers) {
    final categories = <int>{};
    for (final supplier in suppliers) {
      if (supplier.productProviderTypeId != null) {
        // Replace with your actual field
        categories.add(supplier.productProviderTypeId);
      }
    }
    return categories.length;
  }

  Widget _buildPerformanceItem({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimary.withOpacity(0.8),
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
