import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/app/ManagementRule.dart';
import 'package:verdelia_core/business/Supplier.dart';

class SupplierSelector extends StatelessWidget {
  final int? selectedSupplierId;
  final List<Supplier> accessibleSuppliers;
  final ValueChanged<int?> onSupplierChanged;

  const SupplierSelector({
    super.key,
    this.selectedSupplierId,
    required this.accessibleSuppliers,
    required this.onSupplierChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (accessibleSuppliers.isEmpty) {
      return _buildNoSuppliersState(context);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          _SupplierChipsRow(
            suppliers: accessibleSuppliers,
            selectedId: selectedSupplierId,
            onSelect: onSupplierChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildNoSuppliersState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.store_mall_directory_outlined,
            color: colorScheme.onSurfaceVariant.withOpacity(0.5),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              localizations.noSuppliersAvailable,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplierChipsRow extends StatelessWidget {
  final List<Supplier> suppliers;
  final int? selectedId;
  final ValueChanged<int?> onSelect;

  const _SupplierChipsRow({
    required this.suppliers,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // _AllChip(
          //   isSelected: selectedId == null,
          //   onSelect: () => onSelect(null),
          // ),
          // const SizedBox(width: 8),
          ...suppliers.map((supplier) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _SupplierChip(
                supplier: supplier,
                isSelected: supplier.idProductProvider == selectedId,
                onSelect: () => onSelect(supplier.idProductProvider),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _AllChip extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onSelect;

  const _AllChip({
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.all_inclusive_rounded,
              size: 16,
              color: isSelected ? colorScheme.onPrimary : colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'All',
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupplierChip extends StatelessWidget {
  final Supplier supplier;
  final bool isSelected;
  final VoidCallback onSelect;

  const _SupplierChip({
    required this.supplier,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                    spreadRadius: -2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.onPrimary.withOpacity(0.2)
                    : colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.store_rounded,
                size: 14,
                color: isSelected ? colorScheme.onPrimary : colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _getSupplierName(supplier),
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSupplierName(Supplier supplier) {
    final name = supplier.providerName;
    if ((name?.length ?? 0) > 15) {
      return '${name?.substring(0, 13)}...';
    }
    return name ?? "";
  }
}
