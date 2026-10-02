import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:ui/components/finance/Payment_Type_UI_Manager.dart';

class PaymentTypeSection extends StatefulWidget {
  final String selectedType;
  final double totalAmount;
  final double? depositAmount;
  final DateTime? installmentDate;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<double?> onDepositChanged;
  final ValueChanged<DateTime?> onInstallmentDateChanged;

  const PaymentTypeSection({
    super.key,
    required this.selectedType,
    required this.totalAmount,
    this.depositAmount,
    this.installmentDate,
    required this.onTypeChanged,
    required this.onDepositChanged,
    required this.onInstallmentDateChanged,
  });

  @override
  State<PaymentTypeSection> createState() => _PaymentTypeSectionState();
}

class _PaymentTypeSectionState extends State<PaymentTypeSection> {
  late TextEditingController _depositController;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _depositController = TextEditingController(
      text: widget.depositAmount?.toStringAsFixed(2) ?? '',
    );
    _selectedDate = widget.installmentDate;
  }

  @override
  void didUpdateWidget(covariant PaymentTypeSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.depositAmount != oldWidget.depositAmount) {
      _depositController.text = widget.depositAmount?.toStringAsFixed(2) ?? '';
    }

    if (widget.installmentDate != oldWidget.installmentDate) {
      _selectedDate = widget.installmentDate;
    }
  }

  @override
  void dispose() {
    _depositController.dispose();
    super.dispose();
  }

  void _onDepositChanged(String value) {
    final cleanedValue = value.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleanedValue.isNotEmpty) {
      final amount = double.tryParse(cleanedValue);
      widget.onDepositChanged(amount);
    } else {
      widget.onDepositChanged(null);
    }
  }

  Future<void> _selectDate() async {
    final pickedDate = await PaymentTypeUIManager.showDatePickerDialog(
      context,
      initialDate: _selectedDate,
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
      widget.onInstallmentDateChanged(pickedDate);
    }
  }

  Widget _buildDetailsWidget(String type) {
    final loc = AppLocalizations.of(context)!;

    switch (type) {
      case 'payment':
        return PaymentTypeUIManager.buildFullPaymentDetails(
          context: context,
          totalAmount: widget.totalAmount,
        );
      case 'deposit':
        return PaymentTypeUIManager.buildDepositDetails(
          context: context,
          depositController: _depositController,
          totalAmount: widget.totalAmount,
          depositAmount: widget.depositAmount,
          onDepositChanged: _onDepositChanged,
        );
      case 'installment':
        return PaymentTypeUIManager.buildInstallmentDetails(
          context: context,
          selectedDate: _selectedDate,
          formattedDate: PaymentTypeUIManager.formatDate(_selectedDate),
          totalAmount: widget.totalAmount,
          onDateTap: _selectDate,
          selectDateText: loc.selectDate,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final paymentTypes = PaymentTypeUIManager.getPaymentTypes(loc);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header using manager
            PaymentTypeUIManager.buildHeader(context),
            const SizedBox(height: 20),

            // Payment Type Cards using manager
            Column(
              children: paymentTypes.map((type) {
                return PaymentTypeUIManager.buildPaymentTypeCard(
                  context: context,
                  type: type,
                  isSelected: widget.selectedType == type.id,
                  onTap: () => widget.onTypeChanged(type.id),
                  detailsWidget: widget.selectedType == type.id
                      ? _buildDetailsWidget(type.id)
                      : null,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
