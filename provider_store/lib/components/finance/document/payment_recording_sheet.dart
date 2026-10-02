// lib/views/finance/widgets/payment_recording_sheet.dart
import 'package:flutter/material.dart';
import 'package:verdelia_core/business/finance/FinancialDocument.dart';

class PaymentRecordingSheet extends StatelessWidget {
  final FinancialDocument document;

  const PaymentRecordingSheet({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Record Payment',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Add payment form here
          // You can implement a payment form with amount input, payment method selection, etc.
          Text(
            'Recording payment for ${document.documentNumber}',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Implement payment recording logic
              Navigator.pop(context);
            },
            child: const Text('Record Payment'),
          ),
        ],
      ),
    );
  }
}
