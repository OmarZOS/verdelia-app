// lib/provider_store/components/inventory/category_tile.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

/// A horizontal strip of category chips for the current supplier.
///
/// Reads the supplier's product set to decide which categories are
/// "present" (i.e. at least one product belongs to them) and only
/// renders those. The first chip is always an "All" entry that clears
/// the filter.
///
/// Renders nothing when the supplier has fewer than two distinct
/// categories — a single-category filter adds no value.
class CategoryTile extends StatelessWidget {
  /// Categories present for the supplier, in display order. Caller is
  /// responsible for filtering + sorting; the tile just renders.
  final List<ProductCategory> categories;

  /// Currently selected category id, or 0 for "All".
  final int selectedCategoryId;

  /// Called when the user taps a chip. `0` means "All".
  final ValueChanged<int> onCategorySelected;

  /// Optional map from category id → count, shown as a small badge on
  /// each chip. Null hides the counts.
  final Map<int, int>? productCounts;

  const CategoryTile({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    this.productCounts,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final localeLang = Localizations.localeOf(context).languageCode;

    // Nothing to filter by — collapse entirely.
    if (categories.length < 2) return const SizedBox.shrink();

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length + 1, // +1 for the "All" chip
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          // Index 0 is always "All".
          if (index == 0) {
            return _CategoryChip(
              label: loc.all,
              selected: selectedCategoryId == 0,
              icon: Icons.grid_view_rounded,
              onTap: () => onCategorySelected(0),
            );
          }

          final category = categories[index - 1];
          final label = category.nameFor(localeLang);
          final count = productCounts?[category.productCategoryId];

          return _CategoryChip(
            label: label.isEmpty ? category.productCategoryDesc : label,
            selected: selectedCategoryId == category.productCategoryId,
            icon: Icons.category_outlined,
            count: count,
            onTap: () => onCategorySelected(category.productCategoryId),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData icon;
  final int? count;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.icon,
    this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final background =
        selected ? cs.primary : cs.surfaceContainerHighest.withOpacity(0.6);
    final foreground = selected ? cs.onPrimary : cs.onSurfaceVariant;
    final border = selected ? cs.primary : cs.outlineVariant.withOpacity(0.5);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: foreground),
              const SizedBox(width: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: foreground,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 6),
                _CountBadge(
                  count: count!,
                  foreground: foreground,
                  background: selected
                      ? cs.onPrimary.withOpacity(0.18)
                      : cs.primary.withOpacity(0.12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final Color foreground;
  final Color background;

  const _CountBadge({
    required this.count,
    required this.foreground,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.2,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
