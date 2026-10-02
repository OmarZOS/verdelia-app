import 'package:flutter/material.dart';
import 'package:verdelia_core/business/finance/Cart.dart';
import 'package:event/cart_change_notifier.dart';
import 'package:provider_store/components/selling_point/cart_summary/cart_summary_footer.dart';
import 'package:provider_store/components/selling_point/cart_summary/cart_summary_header.dart';
import 'package:provider_store/components/selling_point/cart_summary/cart_summary_items.dart';

class CartSummarySheet extends StatelessWidget {
  final CartChangeNotifier cart;
  final ScrollController? scrollController;

  const CartSummarySheet({
    super.key,
    required this.cart,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CartHeader(
              itemCount: cart.cartItemCount,
              onClose: () => Navigator.pop(context),
            ),
            const Divider(height: 1),
            Expanded(
              child: CartItemsList(
                // cartNotifier: cart,
                scrollController: scrollController,
              ),
            ),
            CartFooter(),
          ],
        ),
      ),
    );
  }
}
