import 'package:verdelia_core/business/finance/FinancialDocument.dart';

extension FinanceSearchExtensions on List<FinancialDocument> {
  List<FinancialDocument> search(String query) {
    if (query.isEmpty) return this;

    final lowerQuery = query.toLowerCase();
    return where((doc) {
      // Search in document number
      if (doc.documentNumber?.toLowerCase().contains(lowerQuery) == true) {
        return true;
      }
      // Search in customer ID
      if (doc.customerId?.toString().contains(query) == true) {
        return true;
      }
      // Search in supplier ID
      if (doc.supplierId?.toString().contains(query) == true) {
        return true;
      }
      // Search in document type
      if (doc.documentType?.toLowerCase().contains(lowerQuery) == true) {
        return true;
      }
      // Search in status
      if (doc.paymentStatus?.toLowerCase().contains(lowerQuery) == true) {
        return true;
      }
      return false;
    }).toList();
  }

  List<FinancialDocument> searchByNumber(String query) {
    if (query.isEmpty) return this;
    final lowerQuery = query.toLowerCase();
    return where((doc) =>
            doc.documentNumber?.toLowerCase().contains(lowerQuery) == true)
        .toList();
  }

  List<FinancialDocument> searchByCustomer(String query) {
    if (query.isEmpty) return this;
    return where((doc) => doc.customerId?.toString().contains(query) == true)
        .toList();
  }
}
