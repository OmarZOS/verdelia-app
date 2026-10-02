import 'package:verdelia_core/business/finance/FinancialDocument.dart';

class FinanceState {
  final List<FinancialDocument> _allDocuments = [];
  final List<FinancialDocument> _groupedDocuments = [];
  bool _isLoading = false;
  bool _isRefreshing = false;

  List<FinancialDocument> get allDocuments => List.unmodifiable(_allDocuments);
  List<FinancialDocument> get groupedDocuments =>
      List.unmodifiable(_groupedDocuments);
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;

  void setLoading(bool loading) {
    _isLoading = loading;
  }

  void setRefreshing(bool refreshing) {
    _isRefreshing = refreshing;
  }

  void setDocuments(List<FinancialDocument> documents) {
    _groupedDocuments.clear();
    _groupedDocuments.addAll(documents);
  }

  void addDocument(FinancialDocument doc) {
    _allDocuments.add(doc);
  }

  void addDocuments(List<FinancialDocument> docs) {
    _allDocuments.addAll(docs);
  }

  void clearDocuments() {
    _allDocuments.clear();
    _groupedDocuments.clear();
  }
}
