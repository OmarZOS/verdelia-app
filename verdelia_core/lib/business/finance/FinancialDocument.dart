// financial_document.dart
import 'package:flutter/material.dart';

enum DateFilter {
  today,
  week,
  month,
  quarter,
  year,
  all,
}

/// Represents a financial document (invoice, receipt, deposit, etc.)
class FinancialDocument {
  // ==================== CORE FIELDS ====================

  final String documentType;
  final int documentId;
  final String documentNumber;
  final int sourceId;
  final String sourceType;

  // ==================== PARTY FIELDS ====================

  final int supplierId;
  final int customerId;
  final String customerType;
  final int customerPersonId;
  final int sellerId;

  // ==================== FINANCIAL FIELDS ====================

  final double documentAmount;
  final DateTime issueDate;
  final DateTime? dueDate;
  final double totalPaid;
  final double totalDeposited;
  final double additionalFees;
  final double outstandingBalance;

  // ==================== STATUS FIELDS ====================

  final String documentStatus;
  final String paymentStatus;
  final int daysIssued;

  // ==================== TIMESTAMPS ====================

  final DateTime createdAt;
  final DateTime updatedAt;

  // ==================== RELATED DATA ====================

  final List<dynamic> payments;
  final List<dynamic> deliveries;
  final List<dynamic> placedOrders;
  final List<dynamic> additionalFeesList;

  // ==================== CONSTRUCTOR ====================

  FinancialDocument({
    required this.documentType,
    required this.documentId,
    required this.documentNumber,
    required this.sourceId,
    required this.sourceType,
    required this.supplierId,
    required this.customerId,
    required this.customerType,
    required this.customerPersonId,
    required this.sellerId,
    required this.documentAmount,
    required this.issueDate,
    this.dueDate,
    required this.totalPaid,
    required this.totalDeposited,
    required this.additionalFees,
    required this.outstandingBalance,
    required this.documentStatus,
    required this.paymentStatus,
    required this.daysIssued,
    required this.createdAt,
    required this.updatedAt,
    this.payments = const [],
    this.deliveries = const [],
    this.placedOrders = const [],
    this.additionalFeesList = const [],
  });

  // ==================== FACTORY FROM JSON ====================

  factory FinancialDocument.fromJson(Map<String, dynamic> json) {
    // Extract invoice data
    final invoiceId = json['invoice_id'] as int? ?? 0;
    final totalAmount = _parseDouble(json['invoice_total_amount']);
    final status = json['invoice_status'] as String? ?? 'unpaid';
    final dueDate = _parseDate(json['invoice_due_date']);
    final createdAt =
        _parseDateTime(json['invoice_created_at']) ?? DateTime.now();
    final updatedAt =
        _parseDateTime(json['invoice_updated_at']) ?? DateTime.now();
    final invoiceType = json['invoice_type'] as String? ?? 'invoice';
    final invoiceNumber = json['invoice_number'] as String? ?? '';
    final issueDate = _parseDate(json['invoice_issue_date']) ?? DateTime.now();
    final taxApplied = json['invoice_tax_applied'] as int? ?? 0;

    // Extract related data
    final cartData = json['cart'] as List? ?? [];
    final payments = json['payment'] as List? ?? [];
    final deliveries = json['delivery'] as List? ?? [];
    final placedOrders = json['placed_order'] as List? ?? [];
    final additionalFees = json['additional_fee'] as List? ?? [];

    // Extract cart data
    int cartId = 0;
    int providerId = 0;
    int clientId = 0;
    int sellerId = 0;
    String cartStatus = '';

    if (cartData.isNotEmpty) {
      final cart = cartData[0] as Map<String, dynamic>;
      cartId = cart['cart_id'] as int? ?? 0;
      providerId = cart['cart_product_provider_id'] as int? ?? 0;
      clientId = cart['cart_client_user'] as int? ?? 0;
      sellerId = cart['cart_selling_user'] as int? ?? 0;
      cartStatus = cart['cart_status'] as String? ?? '';
    }

    // Calculate totals from payments
    double totalPaid = 0.0;
    double totalDeposited = 0.0;
    String paymentStatus = 'unpaid';

    for (final payment in payments) {
      final amount = _parseDouble(payment['payment_amount']);
      final status = payment['payment_status'] as String? ?? 'pending';

      if (status == 'completed' || status == 'paid') {
        totalPaid += amount;
      } else if (status == 'deposit' || status == 'deposited') {
        totalDeposited += amount;
      }
    }

    // Determine payment status
    final totalReceived = totalPaid + totalDeposited;
    if (totalReceived >= totalAmount && totalAmount > 0) {
      paymentStatus = 'paid';
    } else if (totalReceived > 0) {
      paymentStatus = 'partially_paid';
    } else {
      paymentStatus = status; // Use invoice status as fallback
    }

    // Calculate outstanding balance
    final outstanding = (totalAmount - totalReceived).clamp(0.0, totalAmount);

    // Determine document type
    final docType = _determineDocumentType(invoiceType, cartStatus);

    // Determine source type
    final sourceType = _determineSourceType(cartData, placedOrders);

    // Calculate days issued
    final daysIssued =
        issueDate != null ? DateTime.now().difference(issueDate).inDays : 0;

    return FinancialDocument(
      documentType: docType,
      documentId: invoiceId,
      documentNumber:
          invoiceNumber.isNotEmpty ? invoiceNumber : 'INV-$invoiceId',
      sourceId: cartId,
      sourceType: sourceType,
      supplierId: providerId,
      customerId: clientId,
      customerType: 'user',
      customerPersonId: 0,
      sellerId: sellerId,
      documentAmount: totalAmount,
      issueDate: issueDate,
      dueDate: dueDate,
      totalPaid: totalPaid,
      totalDeposited: totalDeposited,
      additionalFees: 0.0,
      outstandingBalance: outstanding,
      documentStatus: status,
      paymentStatus: paymentStatus,
      daysIssued: daysIssued,
      createdAt: createdAt,
      updatedAt: updatedAt,
      payments: payments,
      deliveries: deliveries,
      placedOrders: placedOrders,
      additionalFeesList: additionalFees,
    );
  }

  // ==================== HELPER METHODS ====================

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        // Handle date-only strings like "2026-09-09"
        if (value.length == 10 && value.contains('-')) {
          final parts = value.split('-');
          if (parts.length == 3) {
            return DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            );
          }
        }
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static String _determineDocumentType(String invoiceType, String cartStatus) {
    if (invoiceType == 'invoice') {
      if (cartStatus == 'pending') {
        return 'pending_cart';
      }
      return 'invoice';
    }
    if (invoiceType == 'deposit') {
      return 'deposit';
    }
    if (invoiceType == 'receipt') {
      return 'receipt';
    }
    return 'invoice';
  }

  static String _determineSourceType(List cartData, List placedOrders) {
    if (cartData.isNotEmpty) {
      return 'cart_based';
    }
    if (placedOrders.isNotEmpty) {
      return 'order_based';
    }
    return 'invoice_based';
  }

  // ==================== CONVERT TO JSON ====================

  Map<String, dynamic> toJson() {
    return {
      'document_type': documentType,
      'document_id': documentId,
      'document_number': documentNumber,
      'source_id': sourceId,
      'source_type': sourceType,
      'supplier_id': supplierId,
      'customer_id': customerId,
      'customer_type': customerType,
      'customer_person_id': customerPersonId,
      'seller_id': sellerId,
      'document_amount': documentAmount,
      'issue_date': issueDate.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'total_paid': totalPaid,
      'total_deposited': totalDeposited,
      'additional_fees': additionalFees,
      'outstanding_balance': outstandingBalance,
      'document_status': documentStatus,
      'payment_status': paymentStatus,
      'days_issued': daysIssued,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ==================== GETTERS ====================

  int get daysUntilDue {
    if (dueDate == null) return 0;
    final now = DateTime.now();
    final difference = dueDate!.difference(now);
    return difference.inDays;
  }

  int get daysOverdue {
    if (dueDate == null) return 0;
    final now = DateTime.now();
    if (dueDate!.isBefore(now)) {
      return now.difference(dueDate!).inDays;
    }
    return 0;
  }

  double get totalReceived => totalPaid + totalDeposited;

  double get paymentPercentage {
    if (documentAmount == 0) return 0;
    return (totalReceived / documentAmount * 100).clamp(0, 100);
  }

  bool get isPaid => paymentStatus == 'paid' || outstandingBalance <= 0.01;
  bool get isUnpaid => paymentStatus == 'unpaid' && outstandingBalance > 0.01;
  bool get isPartiallyPaid =>
      paymentStatus == 'partially_paid' && outstandingBalance > 0.01;
  bool get isFullyPaid => isPaid;
  bool get isCanceled => documentStatus == 'canceled';
  bool get isOverdue => daysOverdue > 0 && !isPaid;

  bool get isInvoice =>
      documentType == 'invoice' || documentType == 'cart_with_invoice';
  bool get isDeposit => documentType == 'deposit';
  bool get isPendingCart => documentType == 'pending_cart';
  bool get isReceipt => documentType == 'receipt';

  bool get isCartBased => sourceType == 'cart_based';
  bool get isOrderBased => sourceType == 'order_based';
  bool get isInvoiceBased => sourceType == 'invoice_based';

  // ==================== DISPLAY HELPERS ====================

  String get displayType {
    switch (documentType) {
      case 'invoice':
        return 'Invoice';
      case 'cart_with_invoice':
        return 'Cart Invoice';
      case 'deposit':
        return 'Deposit';
      case 'pending_cart':
        return 'Pending Cart';
      case 'receipt':
        return 'Receipt';
      default:
        return documentType;
    }
  }

  String get displayPaymentStatus {
    if (isPaid) return 'Paid';
    if (isPartiallyPaid) return 'Partial';
    if (isOverdue) return 'Overdue';
    if (isCanceled) return 'Canceled';
    return 'Unpaid';
  }

  String get formattedDueDate {
    if (dueDate == null) return 'No due date';
    if (isOverdue) {
      return 'Overdue $daysOverdue days';
    }
    return 'Due in $daysUntilDue days';
  }

  Color get statusColor {
    if (isPaid) return Colors.green;
    if (isOverdue) return Colors.red;
    if (isPartiallyPaid) return Colors.orange;
    if (isCanceled) return Colors.grey;
    return Colors.blue;
  }

  // ==================== COPY WITH ====================

  FinancialDocument copyWith({
    String? documentType,
    int? documentId,
    String? documentNumber,
    int? sourceId,
    String? sourceType,
    int? supplierId,
    int? customerId,
    String? customerType,
    int? customerPersonId,
    int? sellerId,
    double? documentAmount,
    DateTime? issueDate,
    DateTime? dueDate,
    double? totalPaid,
    double? totalDeposited,
    double? additionalFees,
    double? outstandingBalance,
    String? documentStatus,
    String? paymentStatus,
    int? daysIssued,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<dynamic>? payments,
    List<dynamic>? deliveries,
    List<dynamic>? placedOrders,
    List<dynamic>? additionalFeesList,
  }) {
    return FinancialDocument(
      documentType: documentType ?? this.documentType,
      documentId: documentId ?? this.documentId,
      documentNumber: documentNumber ?? this.documentNumber,
      sourceId: sourceId ?? this.sourceId,
      sourceType: sourceType ?? this.sourceType,
      supplierId: supplierId ?? this.supplierId,
      customerId: customerId ?? this.customerId,
      customerType: customerType ?? this.customerType,
      customerPersonId: customerPersonId ?? this.customerPersonId,
      sellerId: sellerId ?? this.sellerId,
      documentAmount: documentAmount ?? this.documentAmount,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      totalPaid: totalPaid ?? this.totalPaid,
      totalDeposited: totalDeposited ?? this.totalDeposited,
      additionalFees: additionalFees ?? this.additionalFees,
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
      documentStatus: documentStatus ?? this.documentStatus,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      daysIssued: daysIssued ?? this.daysIssued,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      payments: payments ?? this.payments,
      deliveries: deliveries ?? this.deliveries,
      placedOrders: placedOrders ?? this.placedOrders,
      additionalFeesList: additionalFeesList ?? this.additionalFeesList,
    );
  }

  // ==================== OVERRIDES ====================

  @override
  String toString() {
    return 'FinancialDocument(documentId: $documentId, type: $documentType, amount: $documentAmount, status: $paymentStatus)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FinancialDocument && other.documentId == documentId;
  }

  @override
  int get hashCode => documentId.hashCode;
}

// ==================== PAYMENT CLASS ====================

class Payment {
  final int id;
  final int invoiceId;
  final double amount;
  final String method;
  final String status;
  final String reference;
  final String notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? type;

  Payment({
    required this.id,
    required this.invoiceId,
    required this.amount,
    required this.method,
    required this.status,
    required this.reference,
    required this.notes,
    required this.createdAt,
    this.updatedAt,
    this.type,
  });

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['payment_id'] as int? ?? 0,
      invoiceId: json['payment_invoice_id'] as int? ?? 0,
      amount: _parseDouble(json['payment_amount']),
      method: json['payment_method'] as String? ?? '',
      status: json['payment_status'] as String? ?? '',
      reference: json['payment_reference'] as String? ?? '',
      notes: json['payment_notes'] as String? ?? '',
      createdAt: _parseDateTime(json['payment_created_at']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['payment_updated_at']),
      type: json['payment_type'] as String?,
    );
  }
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'payment_id': id,
      'payment_invoice_id': invoiceId,
      'payment_amount': amount,
      'payment_method': method,
      'payment_status': status,
      'payment_reference': reference,
      'payment_notes': notes,
      'payment_created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'payment_updated_at': updatedAt!.toIso8601String(),
      if (type != null) 'payment_type': type,
    };
  }

  bool get isCompleted => status == 'completed' || status == 'paid';
  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed' || status == 'cancelled';
}

@immutable
class PaymentSubmitResult {
  final bool isSuccess;
  final String message;
  final int? paymentId;

  const PaymentSubmitResult._({
    required this.isSuccess,
    required this.message,
    this.paymentId,
  });

  const PaymentSubmitResult.success(String message, {int? paymentId})
      : this._(isSuccess: true, message: message, paymentId: paymentId);

  const PaymentSubmitResult.failure(String message)
      : this._(isSuccess: false, message: message);
}

class AdditionalFee {
  int additionalFeeId;
  int additionalFeePaymentId;
  String additionalFeeName;
  double additionalFeeAmount;
  String additionalFeeDescription;
  String additionalFeeDocumentUrl;
  int additionalFeeUserId;
  int additionalFeeOnProviderId;

  AdditionalFee({
    required this.additionalFeeId,
    required this.additionalFeePaymentId,
    required this.additionalFeeName,
    required this.additionalFeeAmount,
    required this.additionalFeeDescription,
    required this.additionalFeeDocumentUrl,
    required this.additionalFeeUserId,
    required this.additionalFeeOnProviderId,
  });

  factory AdditionalFee.fromJson(Map<String, dynamic> json) {
    return AdditionalFee(
      additionalFeeId: json['additional_fee_id'] ?? 0,
      additionalFeePaymentId: json['additional_fee_payment_id'] ?? 0,
      additionalFeeName: json['additional_fee_name'] ?? '',
      additionalFeeAmount:
          (json['additional_fee_amount'] as num?)?.toDouble() ?? 0.0,
      additionalFeeDescription: json['additional_fee_description'] ?? '',
      additionalFeeDocumentUrl: json['additional_fee_document_url'] ?? '',
      additionalFeeUserId: json['additional_fee_user_id'] ?? 0,
      additionalFeeOnProviderId: json['additional_fee_on_provider_id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'additional_fee_id': additionalFeeId,
      'additional_fee_payment_id': additionalFeePaymentId,
      'additional_fee_name': additionalFeeName,
      'additional_fee_amount': additionalFeeAmount,
      'additional_fee_description': additionalFeeDescription,
      'additional_fee_document_url': additionalFeeDocumentUrl,
      'additional_fee_user_id': additionalFeeUserId,
      'additional_fee_on_provider_id': additionalFeeOnProviderId,
    };
  }

  factory AdditionalFee.create({
    required int paymentId,
    required String name,
    required double amount,
    String description = '',
    String documentUrl = '',
    int userId = 0,
    int onProviderId = 0,
  }) {
    return AdditionalFee(
      additionalFeeId: 0, // Will be set by server
      additionalFeePaymentId: paymentId,
      additionalFeeName: name,
      additionalFeeAmount: amount,
      additionalFeeDescription: description,
      additionalFeeDocumentUrl: documentUrl,
      additionalFeeUserId: userId,
      additionalFeeOnProviderId: onProviderId,
    );
  }
}
