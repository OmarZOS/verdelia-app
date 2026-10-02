// payment_list_item.dart
import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

class PaymentListItem extends StatelessWidget {
  final Map<String, dynamic> payment;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PaymentListItem({
    Key? key,
    required this.payment,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  String _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return '4CAF50'; // Green
      case 'pending':
        return 'FF9800'; // Orange
      case 'failed':
        return 'F44336'; // Red
      case 'refunded':
        return '2196F3'; // Blue
      default:
        return '9E9E9E'; // Grey
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentData = payment['payment'] ?? {};
    final depositData = payment['deposit'] ?? {};

    final amount = paymentData['payment_amount'] ?? 0.0;
    final method = paymentData['payment_method'] ?? 'N/A';
    final status = paymentData['payment_status'] ?? 'Unknown';
    final reference = paymentData['payment_reference'] ?? '';
    AppLocalizations loc = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Payment #${paymentData['payment_id'] ?? ''}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(int.parse('0xFF${_getStatusColor(status)}'))
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            Color(int.parse('0xFF${_getStatusColor(status)}'))
                                .withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color:
                            Color(int.parse('0xFF${_getStatusColor(status)}')),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.attach_money, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    loc.price(amount.toStringAsFixed(2)),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.green,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.credit_card, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    method,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              if (reference.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.tag, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Ref: $reference',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
              if (depositData['deposit_amount'] != null &&
                  depositData['deposit_amount'] > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet,
                        size: 14, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      loc.price(
                          depositData['deposit_amount'].toStringAsFixed(2)),
                      style:
                          const TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: onEdit,
                      tooltip: 'Edit Payment',
                    ),
                  if (onDelete != null)
                    IconButton(
                      icon:
                          const Icon(Icons.delete, size: 20, color: Colors.red),
                      onPressed: onDelete,
                      tooltip: 'Delete Payment',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
