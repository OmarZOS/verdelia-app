import 'dart:typed_data';

import 'package:verdelia_core/app/TraceableService.dart';

import '../../finance/FinancialDocument.dart';

// FinanceDocervice.dart
abstract class InvoiceService extends TraceableService {
  Future<List<FinancialDocument>?>? getAllFinanceDocs(int offset, int limit,
      {int supplierId = 0,
      int personId = 0,
      int clientId = 0,
      int sellerId = 0,
      int cartId = 0,
      int orderId = 0,
      int depositId = 0,
      int invoiceId = 0}) async {
    return null;
  }

  Future<FinancialDocument?> getFinancialDocument(
      String idFinancialDocument) async {
    return null;
  }

  Future<FinancialDocument?> addFinancialDocument(
      dynamic financialDocument) async {
    return null;
  }

  Future<FinancialDocument?> updateFinancialDocument(
      FinancialDocument updatedFinancialDocument) async {
    return null;
  }

  Future<int?> deleteFinancialDocument(String financialDocumentId) async {
    return null;
  }
}
