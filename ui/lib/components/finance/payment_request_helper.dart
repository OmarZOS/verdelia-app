import 'package:verdelia_core/business/finance/FinancialDocument.dart';
import 'package:event/finance_change_notifier.dart';

class PaymentRequestHelper {
  // Determine payment method from context (you can expand this)
  static String determinePaymentMethod(String? method) {
    return method?.toLowerCase() ?? 'cash';
  }

  // // Create payment object from form data
  // static Payment createPayment({
  //   required double amount,
  //   required FinancialDocument? sourceDocument,
  //   required String notes,
  //   String? method,
  // }) {
  //   return Payment.create(
  //     amount: amount,
  //     method: determinePaymentMethod(method),
  //     invoiceId: sourceDocument?.documentId ?? 0,
  //     reference: sourceDocument?.documentNumber ?? '',
  //     notes: notes,
  //     status: 'pending',
  //   );
  // }

  // // Create deposit object from form data
  // static Deposit createDeposit({
  //   required double amount,
  //   required FinancialDocument? sourceDocument,
  //   required String notes,
  //   String? method,
  // }) {
  //   // Determine which ID to use based on source type
  //   int cartId = 0;
  //   int invoiceId = 0;
  //   int receiptId = 0;

  //   if (sourceDocument != null) {
  //     final sourceType = sourceDocument.sourceType?.toLowerCase() ?? '';
  //     final docId = sourceDocument.documentId ?? 0;

  //     if (sourceType.contains('cart')) {
  //       cartId = docId;
  //     } else if (sourceType.contains('invoice')) {
  //       invoiceId = docId;
  //     } else if (sourceType.contains('receipt')) {
  //       receiptId = docId;
  //     }
  //   }

  //   return Deposit.create(
  //     amount: amount,
  //     method: determinePaymentMethod(method),
  //     cartId: cartId,
  //     invoiceId: invoiceId,
  //     receiptId: receiptId,
  //     reference: sourceDocument?.documentNumber ?? '',
  //     notes: notes,
  //   );
  // }

  // Create installment request
  static Map<String, dynamic> createInstallmentRequest({
    required DateTime date,
    required String notes,
    double? amount,
  }) {
    return {
      'type': 'installment',
      'date': date.toIso8601String(),
      'notes': notes,
      'amount': amount,
      'status': 'scheduled',
    };
  }

  // Validate deposit amount
  // static String? validateDepositAmount(
  //   String? input,
  //   FinancialDocument? sourceDocument,
  // ) {
  //   if (input == null || input.isEmpty) {
  //     return 'Please enter a deposit amount';
  //   }

  //   final deposit = double.tryParse(input);
  //   if (deposit == null || deposit <= 0) {
  //     return 'Please enter a valid deposit amount';
  //   }

  //   if (sourceDocument != null) {
  //     final remaining = sourceDocument.remainingAmount;
  //     if (deposit > remaining) {
  //       return 'Deposit cannot exceed remaining amount of \$${remaining.toStringAsFixed(2)}';
  //     }
  //   }

  //   return null;
  // }
}
