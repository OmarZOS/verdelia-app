import 'package:flutter/material.dart';
import 'package:provider_store/components/selling_point/checkout/checkout_button.dart';
import 'package:provider_store/components/selling_point/checkout/order_summary_section.dart';
import 'package:provider/provider.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:event/cart_change_notifier.dart';

class CheckoutFooter extends StatelessWidget {
  final VoidCallback onCheckoutPressed;

  const CheckoutFooter({
    super.key,
    required this.onCheckoutPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Consumer<CartChangeNotifier>(
            builder: (context, cart, child) => OrderSummarySection(
              subtotal: cart.cartTotal * 0.81,
              tax: cart.cartTotal * 0.19,
            ),
          ),
          const SizedBox(height: 16),
          CheckoutButton(onPressed: onCheckoutPressed),
        ],
      ),
    );
  }
}
