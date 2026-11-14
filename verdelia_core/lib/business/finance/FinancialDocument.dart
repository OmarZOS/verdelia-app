// financial_document.dart
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

enum DateFilter {
  today,
  week,
  month,
  quarter,
  year,
  all,
}

/// A financial document (invoice, receipt, deposit, etc.).
///
/// Read from an invoice row plus its related cart / order / delivery
/// / payment collections. The read shape uses ORM column names, not
/// the API write-model names — see the field-level comments.
///
/// ## Money
///
/// Every monetary field ([documentAmount], [totalPaid],
/// [totalDeposited], [additionalFees], [outstandingBalance],
/// [totalReceived], [paymentPercentage]) is a [Decimal]. The `double`
/// conversion happens only inside [toJson] (and in [Payment.toJson] /
/// [AdditionalFee.toJson]), at the JSON boundary.
class FinancialDocument {
  final String documentType;
  final int documentId;
  final String documentNumber;
  final int sourceId;
  final String sourceType;

  final int supplierId;
  final int customerId;
  final String customerType;
  final int customerPersonId;
  final int sellerId;

  /// Invoice grand total, in [Decimal].
  final Decimal documentAmount;

  final DateTime issueDate;
  final DateTime? dueDate;

  /// Sum of payments in state `completed` / `paid`, in [Decimal].
  final Decimal totalPaid;

  /// Sum of payments in state `deposit` / `deposited`, in [Decimal].
  final Decimal totalDeposited;

  /// Additional fees attached to the invoice, in [Decimal].
  final Decimal additionalFees;

  /// Remaining balance = amount − received, in [Decimal]. Never negative.
  final Decimal outstandingBalance;

  final String documentStatus;
  final String paymentStatus;
  final int daysIssued;

  final DateTime createdAt;
  final DateTime updatedAt;

  final List<dynamic> payments;
  final List<dynamic> deliveries;
  final List<dynamic> placedOrders;
  final List<dynamic> additionalFeesList;

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

  factory FinancialDocument.fromJson(Map<String, dynamic> json) {
    final invoiceId = (json['invoice_id'] as num?)?.toInt() ?? 0;

    // Read-side names from the invoice payload:
    //   grand_total     (write model calls it invoice_total_amount)
    //   invoice_reference (not invoice_number)
    //   created_at      (not invoice_created_at)
    //   updated_at      (not invoice_updated_at)
    final totalAmount = _readDecimalOrZero(
      json['grand_total'] ?? json['invoice_total_amount'],
    );
    final status = (json['invoice_status'] as String?) ?? 'unpaid';
    final dueDate = _parseDate(json['invoice_due_date']);
    final createdAt = _parseDateTime(
          json['created_at'] ?? json['invoice_created_at'],
        ) ??
        DateTime.now();
    final updatedAt = _parseDateTime(
          json['updated_at'] ?? json['invoice_updated_at'],
        ) ??
        DateTime.now();
    final invoiceType = (json['invoice_type'] as String?) ?? 'invoice';
    final invoiceNumber =
        (json['invoice_reference'] ?? json['invoice_number'] ?? '') as String;
    final issueDate = _parseDate(json['invoice_issue_date']) ?? DateTime.now();

    final cartData = json['cart'] as List? ?? [];
    final payments = json['payment'] as List? ?? [];
    final deliveries = json['delivery'] as List? ?? [];
    final placedOrders = json['placed_order'] as List? ?? [];
    final additionalFees = json['additional_fee'] as List? ?? [];

    final sourceType = _determineSourceType(cartData, placedOrders);

    int providerId = 0;
    int clientId = 0;
    int sellerId = 0;
    int sourceId = 0;
    String cartStatus = '';

    if (sourceType == 'cart_based' && cartData.isNotEmpty) {
      final cart = _asMap(cartData[0]);
      // Read-side names: provider_id, client_user_id, selling_user_id.
      sourceId = _readInt(cart, const ['cart_id']);
      providerId = _readInt(
        cart,
        const [
          'provider_id',
          'cart_product_provider_id',
          'product_provider_id'
        ],
      );
      clientId = _readInt(cart, const ['client_user_id', 'cart_client_user']);
      sellerId = _readInt(cart, const ['selling_user_id', 'cart_selling_user']);
      cartStatus = (cart['cart_status'] as String?) ?? '';
    } else if (sourceType == 'order_based' && placedOrders.isNotEmpty) {
      final order = _asMap(placedOrders[0]);
      sourceId = _readInt(order, const ['id_placed_order']);
      clientId = _readInt(order, const ['ordering_user_id']);

      if (deliveries.isNotEmpty) {
        final delivery = _asMap(deliveries[0]);
        // Read-side names: delivery_provider_id, recipient_person_id.
        providerId = _readInt(
          delivery,
          const ['delivery_provider_id', 'delivery_provider'],
        );
        clientId = _readInt(
          delivery,
          const ['recipient_person_id', 'recipient_person'],
        );
      }
    }

    Decimal totalPaid = Decimal.zero;
    Decimal totalDeposited = Decimal.zero;

    for (final raw in payments) {
      final payment = _asMap(raw);
      final amount = _readDecimalOrZero(payment['payment_amount']);
      final paymentState = (payment['payment_status'] as String?) ?? 'pending';

      if (paymentState == 'completed' || paymentState == 'paid') {
        totalPaid += amount;
      } else if (paymentState == 'deposit' || paymentState == 'deposited') {
        totalDeposited += amount;
      }
    }

    final totalReceived = totalPaid + totalDeposited;
    String computedPaymentStatus;
    if (totalAmount > Decimal.zero && totalReceived >= totalAmount) {
      computedPaymentStatus = 'paid';
    } else if (totalReceived > Decimal.zero) {
      computedPaymentStatus = 'partially_paid';
    } else {
      final normalized = status.toLowerCase();
      if (normalized == 'paid' || normalized == 'refunded') {
        computedPaymentStatus = normalized;
      } else {
        computedPaymentStatus = 'unpaid';
      }
    }

    // Manual clamp — `num.clamp` isn't available on `Decimal`.
    Decimal outstanding = Decimal.zero;
    if (totalAmount > Decimal.zero) {
      final diff = totalAmount - totalReceived;
      if (diff < Decimal.zero) {
        outstanding = Decimal.zero;
      } else if (diff > totalAmount) {
        outstanding = totalAmount;
      } else {
        outstanding = diff;
      }
    }

    final docType = _determineDocumentType(invoiceType, cartStatus);
    final daysIssued = DateTime.now().difference(issueDate).inDays;

    return FinancialDocument(
      documentType: docType,
      documentId: invoiceId,
      documentNumber:
          invoiceNumber.isNotEmpty ? invoiceNumber : 'INV-$invoiceId',
      sourceId: sourceId,
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
      additionalFees: Decimal.zero,
      outstandingBalance: outstanding,
      documentStatus: status,
      paymentStatus: computedPaymentStatus,
      daysIssued: daysIssued,
      createdAt: createdAt,
      updatedAt: updatedAt,
      payments: payments,
      deliveries: deliveries,
      placedOrders: placedOrders,
      additionalFeesList: additionalFees,
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  static int _readInt(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final v = map[key];
      if (v == null) continue;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) {
        final parsed = int.tryParse(v);
        if (parsed != null) return parsed;
      }
    }
    return 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
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
    if (invoiceType == 'deposit') return 'deposit';
    if (invoiceType == 'receipt') return 'receipt';
    return 'invoice';
  }

  static String _determineSourceType(List cartData, List placedOrders) {
    if (cartData.isNotEmpty) return 'cart_based';
    if (placedOrders.isNotEmpty) return 'order_based';
    return 'invoice_based';
  }

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
      'document_amount': _decimalToWire(documentAmount),
      'issue_date': issueDate.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'total_paid': _decimalToWire(totalPaid),
      'total_deposited': _decimalToWire(totalDeposited),
      'additional_fees': _decimalToWire(additionalFees),
      'outstanding_balance': _decimalToWire(outstandingBalance),
      'document_status': documentStatus,
      'payment_status': paymentStatus,
      'days_issued': daysIssued,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  int get daysUntilDue {
    if (dueDate == null) return 0;
    return dueDate!.difference(DateTime.now()).inDays;
  }

  int get daysOverdue {
    if (dueDate == null) return 0;
    final now = DateTime.now();
    if (dueDate!.isBefore(now)) {
      return now.difference(dueDate!).inDays;
    }
    return 0;
  }

  Decimal get totalReceived => totalPaid + totalDeposited;

  /// Percentage of [documentAmount] that's been received, in [Decimal].
  /// Clamped to `[0, 100]`.
  Decimal get paymentPercentage {
    if (documentAmount == Decimal.zero) return Decimal.zero;
    final pct = (totalReceived / documentAmount)
            .toDecimal(scaleOnInfinitePrecision: 2) *
        Decimal.fromInt(100);
    if (pct < Decimal.zero) return Decimal.zero;
    if (pct > Decimal.fromInt(100)) return Decimal.fromInt(100);
    return pct;
  }

  bool get isPaid =>
      paymentStatus == 'paid' || outstandingBalance <= Decimal.parse('0.01');
  bool get isUnpaid =>
      paymentStatus == 'unpaid' && outstandingBalance > Decimal.parse('0.01');
  bool get isPartiallyPaid =>
      paymentStatus == 'partially_paid' &&
      outstandingBalance > Decimal.parse('0.01');
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
    if (isOverdue) return 'Overdue $daysOverdue days';
    return 'Due in $daysUntilDue days';
  }

  Color get statusColor {
    if (isPaid) return Colors.green;
    if (isOverdue) return Colors.red;
    if (isPartiallyPaid) return Colors.orange;
    if (isCanceled) return Colors.grey;
    return Colors.blue;
  }

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
    Decimal? documentAmount,
    DateTime? issueDate,
    DateTime? dueDate,
    Decimal? totalPaid,
    Decimal? totalDeposited,
    Decimal? additionalFees,
    Decimal? outstandingBalance,
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

class Payment {
  final int id;
  final int invoiceId;

  /// Payment amount, in [Decimal].
  final Decimal amount;

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

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: (json['payment_id'] as num?)?.toInt() ?? 0,
      invoiceId: (json['payment_invoice_id'] as num?)?.toInt() ?? 0,
      amount: _readDecimalOrZero(json['payment_amount']),
      method: (json['payment_method'] as String?) ?? '',
      status: (json['payment_status'] as String?) ?? '',
      reference: (json['payment_reference'] as String?) ?? '',
      notes: (json['payment_notes'] as String?) ?? '',
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
      'payment_amount': _decimalToWire(amount),
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

  /// Fee amount, in [Decimal].
  Decimal additionalFeeAmount;

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
      additionalFeeId: (json['additional_fee_id'] as num?)?.toInt() ?? 0,
      additionalFeePaymentId:
          (json['additional_fee_payment_id'] as num?)?.toInt() ?? 0,
      additionalFeeName: (json['additional_fee_name'] as String?) ?? '',
      additionalFeeAmount: _readDecimalOrZero(json['additional_fee_amount']),
      additionalFeeDescription:
          (json['additional_fee_description'] as String?) ?? '',
      additionalFeeDocumentUrl:
          (json['additional_fee_document_url'] as String?) ?? '',
      additionalFeeUserId:
          (json['additional_fee_user_id'] as num?)?.toInt() ?? 0,
      additionalFeeOnProviderId:
          (json['additional_fee_on_provider_id'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'additional_fee_id': additionalFeeId,
      'additional_fee_payment_id': additionalFeePaymentId,
      'additional_fee_name': additionalFeeName,
      'additional_fee_amount': _decimalToWire(additionalFeeAmount),
      'additional_fee_description': additionalFeeDescription,
      'additional_fee_document_url': additionalFeeDocumentUrl,
      'additional_fee_user_id': additionalFeeUserId,
      'additional_fee_on_provider_id': additionalFeeOnProviderId,
    };
  }

  factory AdditionalFee.create({
    required int paymentId,
    required String name,
    required Decimal amount,
    String description = '',
    String documentUrl = '',
    int userId = 0,
    int onProviderId = 0,
  }) {
    return AdditionalFee(
      additionalFeeId: 0,
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

// ============================================================================
// Decimal helpers
// ============================================================================

/// Coerces any JSON value to [Decimal].
///
/// * [Decimal] → passthrough
/// * `int`     → `Decimal.fromInt`
/// * `double`  → `Decimal.tryParse(v.toString())` (shortest round-trip,
///                NOT the binary expansion)
/// * `String`  → `Decimal.tryParse`
/// * anything else, or a non-finite `double` → `null`
Decimal? _readDecimal(dynamic v) {
  if (v == null) return null;
  if (v is Decimal) return v;
  if (v is int) return Decimal.fromInt(v);
  if (v is double) {
    if (v.isNaN || v.isInfinite) return null;
    return Decimal.tryParse(v.toString());
  }
  if (v is String) return Decimal.tryParse(v);
  return null;
}

/// Coerces any JSON value to a [Decimal], defaulting to zero.
Decimal _readDecimalOrZero(dynamic v) => _readDecimal(v) ?? Decimal.zero;

/// Converts a [Decimal] to the shortest `double` that round-trips.
/// For the JSON wire boundary only — never use this for arithmetic.
double _decimalToDouble(Decimal v) => double.parse(v.toString());

/// Serialises a [Decimal] for JSON. Emits a `num` so `jsonEncode`
/// writes it as a JSON number, not a string.
num _decimalToWire(Decimal v) => _decimalToDouble(v);
