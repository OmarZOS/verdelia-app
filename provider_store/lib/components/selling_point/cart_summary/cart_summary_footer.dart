import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:event/cart_change_notifier.dart';
import 'package:event/product_change_notifier.dart';
import 'package:provider_store/screens/checkout_screen.dart';
import 'package:provider/provider.dart';

class CartFooter extends StatelessWidget {
  const CartFooter({super.key});

  // ══════════════════════════════════════════════════════════════════
  // Actions
  // ══════════════════════════════════════════════════════════════════

  void _checkout(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          supplierId: context.read<ProductNotifier>().currentProviderId,
        ),
      ),
    );
  }

  Future<void> _clearCart(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final cart = context.read<CartChangeNotifier>();
    final navigator = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.clearCartTitle),
        content: Text(loc.clearCartConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(loc.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            child: Text(loc.clear),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    cart.clearCart();
    // Close the cart sheet after clearing. The dialog is already
    // dismissed by the time we get here.
    if (navigator.canPop()) navigator.pop();
  }

  // ══════════════════════════════════════════════════════════════════
  // Build
  // ══════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Consumer<CartChangeNotifier>(
      builder: (context, cart, _) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final loc = AppLocalizations.of(context)!;

        if (cart.cartItems.isEmpty) {
          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    loc.continueShopping,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: colorScheme.outlineVariant.withOpacity(0.5),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CartTotals(cart: cart),
                const SizedBox(height: 16),
                _QuickActions(
                  onCheckout: () => _checkout(context),
                  onClearCart: () => _clearCart(context),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      loc.continueShopping,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Totals
// ══════════════════════════════════════════════════════════════════

class _CartTotals extends StatelessWidget {
  final CartChangeNotifier cart;

  const _CartTotals({required this.cart});

  /// VAT rate. Kept as a named constant so it's obvious it's a
  /// placeholder and where to change it. Real tax should come from
  /// the provider or the cart's per-item VAT, not a magic number.
  static const double _vatRate = 0.19;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;

    // The cart's total is treated as tax-inclusive: VAT is extracted
    // from it rather than added on top. If your backend treats the
    // total as tax-exclusive, reverse the two lines below.
    final total = cart.cartSubtotal;
    final taxAmount = total * _vatRate / (1 + _vatRate);
    final subtotal = total - taxAmount;

    final productLines = cart.productItemCount;
    final serviceLines = cart.serviceItemCount;
    final totalLines = productLines + serviceLines;
    final hasAnyLines = totalLines > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _TotalRow(
            label: loc.subtotal,
            value: loc.price(subtotal.toStringAsFixed(2)),
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),
          _TotalRow(
            label: loc.tax,
            value: loc.price(taxAmount.toStringAsFixed(2)),
            theme: theme,
            colorScheme: colorScheme,
          ),
          Divider(
            height: 20,
            color: colorScheme.outlineVariant.withOpacity(0.5),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  loc.total,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerEnd,
                  child: Text(
                    loc.price(total.toStringAsFixed(2)),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.primary,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
          if (hasAnyLines)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      loc.itemsText,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      loc.items(totalLines, productLines, serviceLines),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.end,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _TotalRow({
    required this.label,
    required this.value,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Quick actions
// ══════════════════════════════════════════════════════════════════

class _QuickActions extends StatelessWidget {
  final VoidCallback onCheckout;
  final VoidCallback onClearCart;

  const _QuickActions({
    required this.onCheckout,
    required this.onClearCart,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Below 380dp, the three actions can't share a row without
        // the labels ellipsizing down to nothing in French or Arabic.
        // Drop to a two-row layout: secondary actions on top, primary
        // checkout full-width below.
        final narrow = constraints.maxWidth < 380;

        final clearButton = OutlinedButton.icon(
          onPressed: onClearCart,
          icon: Icon(
            Icons.delete_outline,
            size: 18,
            color: colorScheme.error,
          ),
          label: Text(
            loc.clear,
            style: TextStyle(color: colorScheme.error),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            side: BorderSide(color: colorScheme.error.withOpacity(0.4)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        final checkoutButton = FilledButton.icon(
          onPressed: onCheckout,
          icon: const Icon(Icons.payment, size: 18),
          label: Text(
            loc.checkout,
            style: const TextStyle(fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: clearButton),
                ],
              ),
              const SizedBox(height: 10),
              checkoutButton,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: clearButton),
            const SizedBox(width: 10),
            Expanded(flex: 2, child: checkoutButton),
          ],
        );
      },
    );
  }
}
