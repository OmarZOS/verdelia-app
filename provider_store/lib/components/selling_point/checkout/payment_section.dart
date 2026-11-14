import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:event/cart_change_notifier.dart';
import 'package:provider_store/components/selling_point/checkout/payment_details_section.dart';
import 'package:provider_store/components/selling_point/checkout/payment_method_section.dart';
import 'payment_type_section.dart';
import 'package:provider/provider.dart';

class PaymentSection extends StatelessWidget {
  final String paymentType;
  final String paymentMethod;
  final ValueChanged<String> onPaymentTypeChanged;

  /// Fires with the deposit amount, in [Decimal].
  final ValueChanged<Decimal> onDepositChanged;

  final ValueChanged<DateTime> onInstallmentDateChanged;
  final ValueChanged<String> onPaymentMethodChanged;
  final ValueChanged<String?> onCardDetailsChanged;
  final ValueChanged<String?> onBankDetailsChanged;
  final ValueChanged<String?> onMobileProviderChanged;
  final ValueChanged<String> onCardTypeChanged;

  const PaymentSection({
    super.key,
    required this.paymentType,
    required this.paymentMethod,
    required this.onPaymentTypeChanged,
    required this.onDepositChanged,
    required this.onInstallmentDateChanged,
    required this.onPaymentMethodChanged,
    required this.onCardDetailsChanged,
    required this.onBankDetailsChanged,
    required this.onMobileProviderChanged,
    required this.onCardTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          // Payment Type
          PaymentTypeSection(
            selectedType: paymentType,
            // `CartChangeNotifier.cartTotal` is `Decimal` after the
            // notifier migration; `PaymentTypeSection.totalAmount`
            // is expected to be `Decimal` after its own migration.
            totalAmount: context.read<CartChangeNotifier>().cartTotal,
            onTypeChanged: onPaymentTypeChanged,
            onDepositChanged: (d) {
              // `d` is `Decimal?` from PaymentTypeSection's
              // `ValueChanged<Decimal?>` callback. Forward with the
              // zero fallback the old `?? 0.0` provided.
              onDepositChanged.call(d ?? Decimal.zero);
            },
            onInstallmentDateChanged: (DateTime? value) {
              onInstallmentDateChanged
                  .call(value ?? DateTime.now().add(Duration(days: 7)));
            },
          ),

          const SizedBox(height: 16),

          // Payment Method
          PaymentMethodSection(
            selectedMethod: paymentMethod,
            onChanged: onPaymentMethodChanged,
          ),

          const SizedBox(height: 16),

          // Payment Details
          PaymentDetailsSection(
            paymentMethod: paymentMethod,
            onCardDetailsChanged: onCardDetailsChanged,
            onBankDetailsChanged: onBankDetailsChanged,
            onMobileProviderChanged: onMobileProviderChanged,
            onCardTypeChanged: onCardTypeChanged,
          ),
        ],
      ),
    );
  }
}
