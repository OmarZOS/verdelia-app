import 'package:event/finance_change_notifier.dart';
import 'package:verdelia_core/business/finance/FinancialDocument.dart';

class FinanceFilter {
  FinanceDocumentFilter _current = const FinanceDocumentFilter();

  FinanceDocumentFilter get current => _current;
  bool get hasActiveFilters => !_current.isEmpty;

  void setFilter(FinanceDocumentFilter filter) {
    _current = filter;
  }

  void clear() {
    _current = const FinanceDocumentFilter();
  }

  void update({
    String? documentType,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    int? supplierId,
    int? personId,
    int? clientId,
    int? sellerId,
    int? cartId,
    int? orderId,
    int? depositId,
    int? invoiceId,
    String? searchQuery,
    bool? hasAttachments,
    bool? isPaid,
  }) {
    _current = _current.copyWith(
      documentType: documentType,
      status: status,
      startDate: startDate,
      endDate: endDate,
      minAmount: minAmount,
      maxAmount: maxAmount,
      supplierId: supplierId,
      personId: personId,
      clientId: clientId,
      sellerId: sellerId,
      cartId: cartId,
      orderId: orderId,
      depositId: depositId,
      invoiceId: invoiceId,
      searchQuery: searchQuery,
      hasAttachments: hasAttachments,
      isPaid: isPaid,
    );
  }

  List<FinancialDocument> apply(List<FinancialDocument> documents) {
    return documents.where((doc) {
      // Document type filter
      if (_current.documentType != null && _current.documentType!.isNotEmpty) {
        if (doc.documentType != _current.documentType) return false;
      }

      // Status filter
      if (_current.status != null && _current.status!.isNotEmpty) {
        if (!_matchesStatus(doc, _current.status!)) return false;
      }

      // Date range filter
      if (_current.startDate != null &&
          doc.issueDate.isBefore(_current.startDate!)) {
        return false;
      }
      if (_current.endDate != null &&
          doc.issueDate.isAfter(_current.endDate!)) {
        return false;
      }

      // Amount range filter
      if (_current.minAmount != null &&
          doc.documentAmount < _current.minAmount!) {
        return false;
      }
      if (_current.maxAmount != null &&
          doc.documentAmount > _current.maxAmount!) {
        return false;
      }

      // Entity filters
      if (_current.supplierId != null &&
          doc.supplierId != _current.supplierId) {
        return false;
      }
      if (_current.clientId != null && doc.customerId != _current.clientId) {
        return false;
      }
      if (_current.personId != null &&
          doc.customerPersonId != _current.personId) {
        return false;
      }
      if (_current.sellerId != null && doc.sellerId != _current.sellerId) {
        return false;
      }

      // Search query
      if (_current.searchQuery != null && _current.searchQuery!.isNotEmpty) {
        final query = _current.searchQuery!.toLowerCase();
        final matches =
            doc.documentNumber?.toLowerCase().contains(query) ?? false;
        if (!matches) return false;
      }

      // Paid status
      if (_current.isPaid != null && _current.isPaid! != doc.isPaid) {
        return false;
      }

      return true;
    }).toList();
  }

  bool _matchesStatus(FinancialDocument doc, String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return doc.isPaid;
      case 'unpaid':
        return doc.isUnpaid;
      case 'overdue':
        return doc.isOverdue;
      case 'partially_paid':
        return doc.paymentStatus.toLowerCase().contains('partial');
      default:
        return doc.paymentStatus == status;
    }
  }
}
