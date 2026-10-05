import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

class CartHeader extends StatelessWidget {
  /// Total units in the cart (sum of quantities, not number of lines).
  final int itemCount;

  /// Optional number of distinct cart lines. When supplied and
  /// different from [itemCount], the subtitle shows both — e.g.
  /// "12 items · 3 products".
  final int? lineCount;

  final VoidCallback onClose;

  const CartHeader({
    super.key,
    required this.itemCount,
    required this.onClose,
    this.lineCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      child: Row(
        children: [
          _CartBadge(
            itemCount: itemCount,
            colorScheme: colorScheme,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  loc.cartTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle(loc),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          _CloseButton(
            onClose: onClose,
            colorScheme: colorScheme,
            tooltip: loc.close,
          ),
        ],
      ),
    );
  }

  /// Builds the subtitle line.
  ///
  /// - Empty cart → "Cart is empty"
  /// - One unit → "1 item"
  /// - N units, no line count → "N items"
  /// - N units, M lines → "N items · M products"
  String _subtitle(AppLocalizations loc) {
    if (itemCount <= 0) return loc.cartIsEmpty;

    final itemsLabel = loc.itemCountLabel(itemCount);

    if (lineCount != null && lineCount! > 0 && lineCount != itemCount) {
      return '$itemsLabel · ${loc.lineCountLabel(lineCount!)}';
    }
    return itemsLabel;
  }
}

// ══════════════════════════════════════════════════════════════════
// Cart icon with badge
// ══════════════════════════════════════════════════════════════════

class _CartBadge extends StatelessWidget {
  final int itemCount;
  final ColorScheme colorScheme;

  const _CartBadge({
    required this.itemCount,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primaryContainer,
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_checkout,
              color: colorScheme.onPrimary,
              size: 22,
            ),
          ),
          if (itemCount > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                constraints: const BoxConstraints(minWidth: 20),
                height: 20,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: colorScheme.error,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colorScheme.surface,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  itemCount > 99 ? '99+' : itemCount.toString(),
                  style: TextStyle(
                    color: colorScheme.onError,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                  ),
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Close button
// ══════════════════════════════════════════════════════════════════

class _CloseButton extends StatelessWidget {
  final VoidCallback onClose;
  final ColorScheme colorScheme;
  final String tooltip;

  const _CloseButton({
    required this.onClose,
    required this.colorScheme,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onClose,
      tooltip: tooltip,
      icon: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.close,
          size: 20,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
