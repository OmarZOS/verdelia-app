import 'package:verdelia_core/business/finance/FinancialDocument.dart';

class FinanceDocumentOperations {
  final List<FinancialDocument> _allDocuments = [];
  final List<FinancialDocument> _primaryDocuments = [];
  final Map<int, List<int>> _documentGroups = {};

  List<FinancialDocument> get allDocuments => List.unmodifiable(_allDocuments);
  List<FinancialDocument> get primaryDocuments =>
      List.unmodifiable(_primaryDocuments);
  Map<int, List<int>> get documentGroups => Map.unmodifiable(_documentGroups);

  void addDocuments(List<FinancialDocument> newDocuments) {
    final existingIds =
        _allDocuments.map((d) => d.documentId).whereType<int>().toSet();

    for (final document in newDocuments) {
      if (document.documentId != null &&
          !existingIds.contains(document.documentId)) {
        _allDocuments.add(document);
      }
    }
  }

  /// Replace the primary documents list with the given documents.
  void setPrimaryDocuments(List<FinancialDocument> docs) {
    _primaryDocuments
      ..clear()
      ..addAll(docs);
  }

  /// Replace the document groups map with the given groups.
  void setDocumentGroups(Map<int, List<int>> groups) {
    _documentGroups
      ..clear()
      ..addAll(groups);
  }

  void clear() {
    _allDocuments.clear();
    _primaryDocuments.clear();
    _documentGroups.clear();
  }
}
