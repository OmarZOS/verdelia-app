import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

class PaymentDetailsSection extends StatefulWidget {
  final String paymentMethod;
  final ValueChanged<String?> onCardDetailsChanged;
  final ValueChanged<String?> onBankDetailsChanged;
  final ValueChanged<String?> onMobileProviderChanged;
  final ValueChanged<String> onCardTypeChanged;

  const PaymentDetailsSection({
    super.key,
    required this.paymentMethod,
    required this.onCardDetailsChanged,
    required this.onBankDetailsChanged,
    required this.onMobileProviderChanged,
    required this.onCardTypeChanged,
  });

  @override
  State<PaymentDetailsSection> createState() => _PaymentDetailsSectionState();
}

class _PaymentDetailsSectionState extends State<PaymentDetailsSection> {
  late String _cardType;
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _bankController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  late String _mobileProvider;

  @override
  void initState() {
    super.initState();
    _cardType = 'visa';
    _mobileProvider = 'orange_money';
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _bankController.dispose();
    _accountController.dispose();
    _referenceController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _buildDetailsContent(),
    );
  }

  Widget _buildDetailsContent() {
    switch (widget.paymentMethod) {
      case 'card':
        return _buildCardDetails();
      case 'bank_transfer':
        return _buildBankTransferDetails();
      case 'mobile_payment':
        return _buildMobilePaymentDetails();
      case 'check':
        return _buildCheckDetails();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCardDetails() {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Card(
      key: const ValueKey('card_details'),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.credit_card,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  loc.cardDetails,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Card Type
            DropdownButtonFormField<String>(
              value: _cardType,
              decoration: InputDecoration(
                labelText: loc.cardType,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
              items: [
                DropdownMenuItem(
                  value: 'visa',
                  child: Text(loc.visa),
                ),
                DropdownMenuItem(
                  value: 'mastercard',
                  child: Text(loc.mastercard),
                ),
                DropdownMenuItem(
                  value: 'amex',
                  child: Text(loc.amex),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _cardType = value);
                  widget.onCardTypeChanged(value);
                }
              },
            ),
            const SizedBox(height: 12),

            // Card Number
            TextFormField(
              controller: _cardNumberController,
              decoration: InputDecoration(
                labelText: loc.cardNumber,
                hintText: '**** **** **** ****',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
                prefixIcon: Icon(
                  Icons.credit_card_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              keyboardType: TextInputType.number,
              onChanged: widget.onCardDetailsChanged,
            ),
            const SizedBox(height: 12),

            // Expiry & CVV
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _expiryController,
                    decoration: InputDecoration(
                      labelText: loc.expiryDate,
                      hintText: 'MM/YY',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cvvController,
                    decoration: InputDecoration(
                      labelText: 'CVV',
                      hintText: '***',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankTransferDetails() {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Card(
      key: const ValueKey('bank_transfer_details'),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  loc.bankTransferDetails,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Bank Name
            TextFormField(
              controller: _bankController,
              decoration: InputDecoration(
                labelText: loc.bankName,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
                prefixIcon: Icon(
                  Icons.business,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              onChanged: widget.onBankDetailsChanged,
            ),
            const SizedBox(height: 12),

            // Account Number
            TextFormField(
              controller: _accountController,
              decoration: InputDecoration(
                labelText: loc.accountNumber,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
                prefixIcon: Icon(
                  Icons.numbers,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),

            // Reference
            TextFormField(
              controller: _referenceController,
              decoration: InputDecoration(
                labelText: loc.reference,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
                prefixIcon: Icon(
                  Icons.tag,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobilePaymentDetails() {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Card(
      key: const ValueKey('mobile_payment_details'),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.phone_android,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  loc.mobilePaymentDetails,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Service Provider
            DropdownButtonFormField<String>(
              value: _mobileProvider,
              decoration: InputDecoration(
                labelText: loc.serviceProvider,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
              items: [
                DropdownMenuItem(
                  value: 'orange_money',
                  child: Text(loc.orangeMoney),
                ),
                DropdownMenuItem(
                  value: 'ooredoo_money',
                  child: Text(loc.ooredooMoney),
                ),
                DropdownMenuItem(
                  value: 'nedjma_pay',
                  child: Text(loc.nedjmaPay),
                ),
                DropdownMenuItem(
                  value: 'paypal',
                  child: Text(loc.paypal),
                ),
                DropdownMenuItem(
                  value: 'stc_pay',
                  child: Text(loc.stcPay),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _mobileProvider = value);
                  widget.onMobileProviderChanged(value);
                }
              },
            ),
            const SizedBox(height: 12),

            // Phone Number
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: loc.phoneNumber,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
                prefixIcon: Icon(
                  Icons.phone,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckDetails() {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Card(
      key: const ValueKey('check_details'),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.description,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  loc.checkDetails,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      loc.checkPaymentNote,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
