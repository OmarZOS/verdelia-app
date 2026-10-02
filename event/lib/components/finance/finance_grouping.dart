import 'package:verdelia_core/business/finance/FinancialDocument.dart';

class FinanceGrouping {
  final Map<int, List<int>> _documentGroups = {};

  Map<int, List<int>> get documentGroups => Map.unmodifiable(_documentGroups);

  List<FinancialDocument> groupDocuments(
    List<FinancialDocument> allDocuments,
  ) {
    _documentGroups.clear();

    final sourceIdToDocuments = <int, List<FinancialDocument>>{};

    for (final doc in allDocuments) {
      final sourceId = doc.sourceId ?? 0;
      if (sourceId == 0) continue;
      sourceIdToDocuments.putIfAbsent(sourceId, () => []);
      sourceIdToDocuments[sourceId]!.add(doc);
    }

    final primaryDocuments = <FinancialDocument>[];

    for (final entry in sourceIdToDocuments.entries) {
      final documents = entry.value;
      if (documents.isEmpty) continue;

      _sortDocumentsByStrength(documents);

      final primaryDoc = documents.first;
      primaryDocuments.add(primaryDoc);

      final relatedIds = documents
          .where((d) => d.documentId != primaryDoc.documentId)
          .map((d) => d.documentId ?? 0)
          .where((id) => id > 0)
          .toList();

      if (relatedIds.isNotEmpty) {
        _documentGroups[primaryDoc.documentId ?? 0] = relatedIds;
      }

      _updatePrimaryDocument(primaryDoc, documents);
    }

    primaryDocuments.sort((a, b) {
      final dateA = a.issueDate ?? DateTime(1970);
      final dateB = b.issueDate ?? DateTime(1970);
      return dateB.compareTo(dateA);
    });

    return primaryDocuments;
  }

  void _sortDocumentsByStrength(List<FinancialDocument> documents) {
    final order = {
      'invoice': 1,
      'cart_with_payments': 2,
      'cart_with_receipt': 2,
      'receipt': 3,
      'deposit': 4,
      'pending_cart': 5,
    };
    documents.sort((a, b) {
      final aOrder = order[a.documentType?.toLowerCase() ?? ''] ?? 99;
      final bOrder = order[b.documentType?.toLowerCase() ?? ''] ?? 99;
      return aOrder.compareTo(bOrder);
    });
  }

  void _updatePrimaryDocument(
      FinancialDocument primaryDoc, List<FinancialDocument> group) {
    if (group.length <= 1) return;

    double maxCartInvoiceAmount = 0.0;
    double totalPaid = 0.0;
    double totalDeposited = 0.0;
    final countedPaymentIds = <String>{};
    final countedDepositIds = <String>{};

    // First pass: Find main cart/invoice
    for (final doc in group) {
      final docType = doc.documentType?.toLowerCase() ?? '';
      if (docType.contains('cart') || docType == 'invoice') {
        final docAmount = doc.documentAmount ?? 0.0;
        if (docAmount > maxCartInvoiceAmount) {
          maxCartInvoiceAmount = docAmount;
        }
        totalPaid += doc.totalPaid ?? 0.0;
        totalDeposited += doc.totalDeposited ?? 0.0;
      }
    }

    // Second pass: Add receipts and deposits
    for (final doc in group) {
      final docType = doc.documentType?.toLowerCase() ?? '';
      final docId = '${doc.documentType}_${doc.documentId}';

      if (docType == 'receipt') {
        final receiptAmount = doc.documentAmount ?? 0.0;
        if (!countedPaymentIds.contains(docId)) {
          totalPaid += receiptAmount;
          countedPaymentIds.add(docId);
        }
      } else if (docType == 'deposit') {
        final depositAmount = doc.documentAmount ?? 0.0;
        if (!countedDepositIds.contains(docId)) {
          totalDeposited += depositAmount;
          countedDepositIds.add(docId);
        }
      }
    }

    final outstandingBalance =
        (maxCartInvoiceAmount - totalPaid - totalDeposited)
            .clamp(0.0, maxCartInvoiceAmount);
    final combinedStatus = _determineCombinedStatus(
        group, maxCartInvoiceAmount, totalPaid, totalDeposited);

    // Update the primary document
    final updatedDoc = FinancialDocument(
      documentType: primaryDoc.documentType,
      documentId: primaryDoc.documentId,
      documentNumber: primaryDoc.documentNumber,
      sourceId: primaryDoc.sourceId,
      sourceType: primaryDoc.sourceType,
      supplierId: primaryDoc.supplierId,
      customerId: primaryDoc.customerId,
      customerType: primaryDoc.customerType,
      customerPersonId: primaryDoc.customerPersonId,
      sellerId: primaryDoc.sellerId,
      documentAmount: maxCartInvoiceAmount,
      issueDate: primaryDoc.issueDate,
      dueDate: primaryDoc.dueDate,
      totalPaid: totalPaid,
      totalDeposited: totalDeposited,
      additionalFees: 0.0,
      outstandingBalance: outstandingBalance,
      documentStatus: primaryDoc.documentStatus,
      paymentStatus: combinedStatus,
      daysIssued: primaryDoc.daysIssued,
      createdAt: primaryDoc.createdAt,
      updatedAt: primaryDoc.updatedAt,
    );

    final index = group.indexOf(primaryDoc);
    if (index != -1) {
      group[index] = updatedDoc;
    }
  }

  String _determineCombinedStatus(
    List<FinancialDocument> group,
    double baseAmount,
    double totalPaid,
    double totalDeposited,
  ) {
    final totalPayments = totalPaid + totalDeposited;

    if (baseAmount == 0) return 'unknown';
    if (totalPayments >= baseAmount) return 'paid';

    final hasDepositDoc =
        group.any((d) => d.documentType?.toLowerCase() == 'deposit');
    final hasReceiptDoc =
        group.any((d) => d.documentType?.toLowerCase() == 'receipt');

    if (hasDepositDoc && !hasReceiptDoc && totalDeposited > 0) {
      return 'deposited';
    }
    if (!hasDepositDoc && hasReceiptDoc && totalPaid > 0) {
      return 'partially_paid';
    }
    if (totalPayments > 0) return 'partially_paid';

    return 'unpaid';
  }

  bool isPrimaryDocument(FinancialDocument doc) {
    return _documentGroups.containsKey(doc.documentId);
  }

  List<FinancialDocument>? getRelatedDocuments(
    int primaryDocumentId,
    List<FinancialDocument> allDocuments,
  ) {
    final relatedIds = _documentGroups[primaryDocumentId];
    if (relatedIds == null) return null;

    final uniqueIds = Set.from(relatedIds);
    return allDocuments
        .where((doc) =>
            uniqueIds.contains(doc.documentId) &&
            doc.documentId != primaryDocumentId)
        .toList();
  }

  void clear() {
    _documentGroups.clear();
  }
}
