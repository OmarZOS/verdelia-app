import 'package:flutter/material.dart';
import 'package:provider_store/components/selling_point/checkout/checkout_button.dart';
import 'package:provider_store/components/selling_point/checkout/order_summary_section.dart';
import 'package:provider/provider.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:event/cart_change_notifier.dart';

class CheckoutFooter extends StatelessWidget {
  /// Called when the user taps the checkout button. When null, the
  /// button is disabled — greyed out, no ripple, no hit target.
  final VoidCallback? onCheckoutPressed;

  /// Optional explicit "processing" state. When true, the button is
  /// disabled and can render a loading indicator (depending on
  /// [CheckoutButton]'s implementation). When null, the button is
  /// driven entirely by [onCheckoutPressed]'s nullability.
  final bool? isLoading;

  const CheckoutFooter({
    super.key,
    required this.onCheckoutPressed,
    this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(
            color: cs.outlineVariant.withOpacity(0.5),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.05),
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
          CheckoutButton(
            // Pass the disabled state through. If the caller supplies
            // an explicit isLoading flag, force-disable even when a
            // callback is present; otherwise defer to the callback's
            // nullability.
            onPressed: (isLoading == true) ? null : onCheckoutPressed,
            isLoading: isLoading ?? false,
          ),
        ],
      ),
    );
  }
}
