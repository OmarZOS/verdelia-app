import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:event/cart_change_notifier.dart';
import 'package:event/product_change_notifier.dart';
import 'package:provider_store/components/selling_point/cart_summary/cart_summary_screen.dart';
import 'package:provider/provider.dart';

class CartFAB extends StatelessWidget {
  final CartChangeNotifier cartNotifier;
  final ProductNotifier productNotifier;
  final int userId;

  const CartFAB({
    required this.cartNotifier,
    required this.productNotifier,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final cartItemCount = cartNotifier.cartItemCount;
    final cartTotal = cartNotifier.cartTotal;

    if (cartItemCount == 0) return const SizedBox();

    return FloatingActionButton.extended(
      onPressed: () => showCartSummary(context),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      icon: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Text(
          cartItemCount.toString(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      label: Text(
        'DZD${cartTotal.toStringAsFixed(2)}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  void showCartSummary(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        snap: true,
        snapSizes: const [0.5, 0.85, 0.95],
        builder: (context, scrollController) => CartSummarySheet(
          cart: cartNotifier,
          scrollController: scrollController,
        ),
      ),
    );
  }

  void _addToCartWithHaptic(Product product) {
    HapticFeedback.lightImpact(); // or .mediumImpact()
    cartNotifier.addItem(product, 1);
  }
}
