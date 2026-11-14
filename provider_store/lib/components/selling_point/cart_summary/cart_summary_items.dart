import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/business/finance/Cart.dart';
import 'package:event/cart_change_notifier.dart';
import 'package:provider/provider.dart';

class CartItemsList extends StatelessWidget {
  final ScrollController? scrollController;

  const CartItemsList({
    super.key,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CartChangeNotifier>(
      builder: (context, cartNotifier, child) {
        final cartItems = cartNotifier.cartItems;

        if (cartItems.isEmpty) return const _EmptyCartState();

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          itemCount: cartItems.length,
          itemBuilder: (context, index) {
            return _CartItemRow(
              cartItem: cartItems[index],
              isLast: index == cartItems.length - 1,
            );
          },
        );
      },
    );
  }
}

class _EmptyCartState extends StatelessWidget {
  const _EmptyCartState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Your cart is empty',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add products to get started',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemRow extends StatelessWidget {
  final CartItem cartItem;
  final bool isLast;

  const _CartItemRow({
    required this.cartItem,
    required this.isLast,
  });

  void _updateQuantity(BuildContext context, int delta) {
    final cartNotifier = context.read<CartChangeNotifier>();
    final newQuantity = cartItem.quantity + delta;

    if (cartItem.product != null) {
      if (newQuantity > 0) {
        cartNotifier.updateQuantity(
          product: cartItem.product!,
          newQuantity: newQuantity,
        );
      } else {
        cartNotifier.removeItem(product: cartItem.product!);
      }
    } else if (cartItem.service != null) {
      if (newQuantity > 0) {
        cartNotifier.updateQuantity(
          service: cartItem.service!,
          newQuantity: newQuantity,
        );
      } else {
        cartNotifier.removeItem(service: cartItem.service!);
      }
    }
  }

  void _removeItem(BuildContext context) {
    final cartNotifier = context.read<CartChangeNotifier>();
    if (cartItem.product != null) {
      cartNotifier.removeItem(product: cartItem.product!);
    } else if (cartItem.service != null) {
      cartNotifier.removeItem(service: cartItem.service!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;

    final product = cartItem.product;
    final service = cartItem.service;

    final itemName = product?.product_name ?? service?.name ?? '';

    // ── Price computation ──
    // `Product.product_price` is `Decimal?`; `ProvidedService.finalPrice`
    // is `Decimal` (non-null). The old `_catalogPrice(double?, double?)`
    // helper becomes a `Decimal` version below.
    final Decimal catalogPrice = _catalogPrice(
      product?.product_price,
      service?.finalPrice,
    );

    // `CartItem.customPrice` is `Decimal?`. `unitPrice` on `CartItem`
    // resolves the override if set, falling back to catalog.
    final Decimal effectivePrice = cartItem.customPrice ?? catalogPrice;
    final bool hasDiscount = effectivePrice < catalogPrice;
    final Decimal unitDiscount =
        hasDiscount ? catalogPrice - effectivePrice : Decimal.zero;
    final Decimal lineDiscount =
        unitDiscount * Decimal.fromInt(cartItem.quantity);
    final Decimal subtotal =
        effectivePrice * Decimal.fromInt(cartItem.quantity);

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasDiscount
              ? colorScheme.primary.withOpacity(0.25)
              : colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withOpacity(0.1),
                  colorScheme.primaryContainer.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              product != null ? Icons.inventory : Icons.handyman_rounded,
              color: colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemName,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Price line: catalog (struck) → effective
                Row(
                  children: [
                    if (hasDiscount) ...[
                      Text(
                        loc.price(catalogPrice.toStringAsFixed(2)),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      loc.price(effectivePrice.toStringAsFixed(2)),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: hasDiscount
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        fontWeight:
                            hasDiscount ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                // Schedule (services)
                if (cartItem.scheduledDate != null ||
                    cartItem.scheduledTime != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${cartItem.scheduledDate ?? ''} ${cartItem.scheduledTime ?? ''}'
                          .trim(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.secondary,
                      ),
                    ),
                  ),

                // Discount chip
                if (hasDiscount)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: _DiscountChip(
                      unitDiscount: unitDiscount,
                      lineDiscount: lineDiscount,
                      catalogPrice: catalogPrice,
                      quantity: cartItem.quantity,
                      colorScheme: colorScheme,
                      loc: loc,
                    ),
                  ),

                const SizedBox(height: 8),

                _QuantityControls(
                  quantity: cartItem.quantity,
                  onDecrease: () => _updateQuantity(context, -1),
                  onIncrease: () => _updateQuantity(context, 1),
                  onRemove: () => _removeItem(context),
                  colorScheme: colorScheme,
                ),
              ],
            ),
          ),

          // Totals (right-aligned)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (hasDiscount) ...[
                Text(
                  loc.price((catalogPrice * Decimal.fromInt(cartItem.quantity))
                      .toStringAsFixed(2)),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
              ],
              Text(
                loc.price(subtotal.toStringAsFixed(2)),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color:
                      hasDiscount ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${cartItem.quantity} × ${loc.price(effectivePrice.toStringAsFixed(2))}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (hasDiscount) ...[
                const SizedBox(height: 2),
                Text(
                  '− ${loc.price(lineDiscount.toStringAsFixed(2))}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.tertiary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Returns the catalog price as a [Decimal], defaulting to zero
  /// when neither side carries one.
  ///
  /// `Product.product_price` is `Decimal?` after the Product migration;
  /// `ProvidedService.finalPrice` is `Decimal` (non-null) after the
  /// ProvidedService migration.
  Decimal _catalogPrice(Decimal? productPrice, Decimal? servicePrice) {
    return productPrice ?? servicePrice ?? Decimal.zero;
  }
}

// ─────────────────────────────────────────────────────────────
// Small chip under the price line: "Discount: −X DA (−Y%)"
// ─────────────────────────────────────────────────────────────

class _DiscountChip extends StatelessWidget {
  final Decimal unitDiscount;
  final Decimal lineDiscount;

  /// Catalog price of one unit. Needed to compute the discount
  /// percentage. The original `_effectivePrice()` helper always
  /// returned `0.0`, so the percent always rendered as `100%`.
  final Decimal catalogPrice;

  final int quantity;
  final ColorScheme colorScheme;
  final AppLocalizations loc;

  const _DiscountChip({
    required this.unitDiscount,
    required this.lineDiscount,
    required this.catalogPrice,
    required this.quantity,
    required this.colorScheme,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // `.toDecimal(scaleOnInfinitePrecision: 2)` on the division: `Decimal / Decimal` returns a
    // `Rational`, which can't be assigned to a `Decimal`. The
    // percent is `unitDiscount / catalogPrice * 100`, clamped to
    // `[0, 100]` — `Decimal` has no `.clamp`, so manual compare.
    Decimal percent = Decimal.zero;
    if (catalogPrice > Decimal.zero) {
      final raw =
          (unitDiscount / catalogPrice).toDecimal(scaleOnInfinitePrecision: 2) *
              Decimal.fromInt(100);
      if (raw < Decimal.zero) {
        percent = Decimal.zero;
      } else if (raw > Decimal.fromInt(100)) {
        percent = Decimal.fromInt(100);
      } else {
        percent = raw;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: colorScheme.tertiary.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_offer_rounded,
            size: 11,
            color: colorScheme.tertiary,
          ),
          const SizedBox(width: 4),
          Text(
            quantity > 1
                ? '${loc.price(lineDiscount.toStringAsFixed(2))} off (${percent.toStringAsFixed(0)}%)'
                : '${loc.price(unitDiscount.toStringAsFixed(2))} off (${percent.toStringAsFixed(0)}%)',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onTertiaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityControls extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onRemove;
  final ColorScheme colorScheme;

  const _QuantityControls({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QuantityButton(
            icon: Icons.remove,
            onTap: onDecrease,
            isActive: quantity > 1,
            colorScheme: colorScheme,
          ),
          Container(
            width: 40,
            alignment: Alignment.center,
            child: Text(
              quantity.toString(),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _QuantityButton(
            icon: Icons.add,
            onTap: onIncrease,
            isActive: true,
            colorScheme: colorScheme,
          ),
          const SizedBox(width: 8),
          _RemoveButton(onTap: onRemove, colorScheme: colorScheme),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  final ColorScheme colorScheme;

  const _QuantityButton({
    required this.icon,
    required this.onTap,
    required this.isActive,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isActive ? onTap : null,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? colorScheme.primary.withOpacity(0.1)
                : Colors.transparent,
          ),
          child: Center(
            child: Icon(
              icon,
              size: 16,
              color: isActive
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant.withOpacity(0.4),
            ),
          ),
        ),
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _RemoveButton({
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Remove',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.error.withOpacity(0.1),
            ),
            child: Icon(
              Icons.delete_outline,
              size: 16,
              color: colorScheme.error,
            ),
          ),
        ),
      ),
    );
  }
}
