import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:event/cart_change_notifier.dart';
import 'package:event/product_change_notifier.dart';
import 'package:event/views/checkout_view_model.dart';
import 'package:provider_store/screens/checkout_screen.dart';
import 'package:provider/provider.dart';

class CartFooter extends StatelessWidget {
  const CartFooter({super.key});

  void _checkout(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          supplierId: context.read<ProductNotifier>().currentProviderId,
        ),
      ),
    );
    // _clearCart(context, context.read<CartChangeNotifier>());
    // final checkoutViewModel = context.read<CheckoutViewModel>();
    // final cartNotifier = context.read<CartChangeNotifier>();

    // TODO: Implement checkout logic
    // Navigator.pop(context);
    // Show checkout dialog or navigate to checkout screen
  }

  void _saveAsQuote(BuildContext context) {
    debugPrint(context.read<CartChangeNotifier>().cart.toJson().toString());
    // TODO: Implement save as quote
    // Navigator.pop(context);
  }

  void _clearCart(BuildContext context, CartChangeNotifier cart) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text(
            'Are you sure you want to clear all items from the cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              cart.clearCart();
              Navigator.pop(context);
              Navigator.pop(context); // Close cart summary
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartChangeNotifier>(
      builder: (context, cart, child) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        if (cart.cartItems.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Continue Shopping'),
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              top: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Totals
              _CartTotals(cart: cart),
              const SizedBox(height: 16),

              // Quick Actions
              _QuickActions(
                onCheckout: () => _checkout(context),
                onSaveQuote: () => _saveAsQuote(context),
                onClearCart: () => _clearCart(context, cart),
              ),

              // Continue shopping
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Continue Shopping'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CartTotals extends StatelessWidget {
  final CartChangeNotifier cart;

  const _CartTotals({
    required this.cart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final total = cart.cartSubtotal;
    final taxAmount = total * 0.19; // 10% tax
    final subtotal = total - taxAmount;
    final loc = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.subtotal,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                loc.price(subtotal.toStringAsFixed(2)),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.tax,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                loc.price(taxAmount.toStringAsFixed(2)),
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.total,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                loc.price(total.toStringAsFixed(2)),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          if (cart.productItemCount > 0 || cart.serviceItemCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    loc.itemsText,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    loc.items(cart.productItemCount + cart.serviceItemCount,
                        cart.productItemCount, cart.serviceItemCount),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
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

class _QuickActions extends StatelessWidget {
  final VoidCallback onCheckout;
  final VoidCallback onSaveQuote;
  final VoidCallback onClearCart;

  const _QuickActions({
    required this.onCheckout,
    required this.onSaveQuote,
    required this.onClearCart,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        // Clear cart
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onClearCart,
            icon: Icon(Icons.delete_outline, color: colorScheme.error),
            label: const Text('Clear'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: colorScheme.error.withOpacity(0.5)),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Save quote
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onSaveQuote,
            icon: const Icon(Icons.save_alt),
            label: const Text('Save Quote'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Checkout
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: onCheckout,
            icon: const Icon(Icons.payment),
            label: const Text('Checkout'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
