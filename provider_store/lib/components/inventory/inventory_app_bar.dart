import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/business/privileges/Privileges.dart';
import 'package:provider_store/components/inventory/product_list.dart';
import 'package:provider_store/screens/inventory_screen.dart';

class InventoryAppBar extends StatelessWidget {
  final VoidCallback onRefresh;
  final bool hasSupplierSelected;
  final PrivilegeLevel privilegeLevel;

  const InventoryAppBar({
    super.key,
    required this.onRefresh,
    required this.hasSupplierSelected,
    required this.privilegeLevel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isManager = privilegeLevel == PrivilegeLevel.manage;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.inventory_2_rounded,
            color:
                isManager ? colorScheme.primary : colorScheme.onSurfaceVariant,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inventory',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  isManager ? 'Manager Access' : 'Viewer Access',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isManager
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: hasSupplierSelected ? onRefresh : null,
            icon: Icon(
              Icons.refresh_rounded,
              color: hasSupplierSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant.withOpacity(0.3),
            ),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }
}
