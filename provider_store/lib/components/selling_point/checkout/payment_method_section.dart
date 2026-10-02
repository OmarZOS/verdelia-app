import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

class PaymentMethodSection extends StatelessWidget {
  final String selectedMethod;
  final ValueChanged<String> onChanged;

  const PaymentMethodSection({
    super.key,
    required this.selectedMethod,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    // Payment method options with icons and localized labels
    final paymentMethods = [
      PaymentMethodOption(
        id: 'cash',
        icon: Icons.money,
        label: loc?.cash ?? 'Cash',
        color: Colors.green,
      ),
      PaymentMethodOption(
        id: 'card',
        icon: Icons.credit_card,
        label: loc?.card ?? 'Credit Card',
        color: Colors.blue,
      ),
      PaymentMethodOption(
        id: 'bank_transfer',
        icon: Icons.account_balance,
        label: loc?.bankTransfer ?? 'Bank Transfer',
        color: Colors.purple,
      ),
      PaymentMethodOption(
        id: 'mobile_payment',
        icon: Icons.phone_android,
        label: loc?.mobilePayment ?? 'Mobile Payment',
        color: Colors.orange,
      ),
      PaymentMethodOption(
        id: 'check',
        icon: Icons.description,
        label: loc?.check ?? 'Check',
        color: Colors.teal,
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(
                  Icons.payment,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  loc?.paymentMethod ?? 'Payment Method',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          // Payment method chips - horizontally scrollable
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              height: 56, // Fixed height for consistent layout
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: paymentMethods.map((method) {
                      final isSelected = selectedMethod == method.id;

                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                method.icon,
                                size: 16,
                                color: isSelected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                method.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (_) => onChanged(method.id),
                          selectedColor: method.color,
                          backgroundColor: isSelected
                              ? method.color
                              : theme.colorScheme.surfaceVariant
                                  .withOpacity(0.3),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          visualDensity: VisualDensity.compact,
                          elevation: isSelected ? 2 : 0,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),

          // Selected payment method info
          if (selectedMethod.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getPaymentMethodInfo(selectedMethod, paymentMethods)
                    .color
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getPaymentMethodInfo(selectedMethod, paymentMethods)
                      .color
                      .withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getPaymentMethodInfo(selectedMethod, paymentMethods).icon,
                    size: 16,
                    color: _getPaymentMethodInfo(selectedMethod, paymentMethods)
                        .color,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getPaymentMethodInfo(selectedMethod, paymentMethods)
                          .description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper method to get payment method information
  PaymentMethodInfo _getPaymentMethodInfo(
    String methodId,
    List<PaymentMethodOption> options,
  ) {
    final method = options.firstWhere(
      (option) => option.id == methodId,
      orElse: () => PaymentMethodOption(
        id: 'unknown',
        icon: Icons.help_outline,
        label: 'Unknown',
        color: Colors.grey,
      ),
    );

    String description;
    switch (methodId) {
      case 'cash':
        description = 'Payment with physical cash';
        break;
      case 'card':
        description = 'Payment using credit or debit card';
        break;
      case 'bank_transfer':
        description = 'Payment via bank transfer';
        break;
      case 'mobile_payment':
        description = 'Payment using mobile wallet';
        break;
      case 'check':
        description = 'Payment by check';
        break;
      default:
        description = 'Payment method details';
    }

    return PaymentMethodInfo(
      icon: method.icon,
      color: method.color,
      description: description,
    );
  }
}

// Supporting data classes
class PaymentMethodOption {
  final String id;
  final IconData icon;
  final String label;
  final Color color;

  const PaymentMethodOption({
    required this.id,
    required this.icon,
    required this.label,
    required this.color,
  });
}

class PaymentMethodInfo {
  final IconData icon;
  final Color color;
  final String description;

  const PaymentMethodInfo({
    required this.icon,
    required this.color,
    required this.description,
  });
}
