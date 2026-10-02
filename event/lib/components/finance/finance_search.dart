import 'package:verdelia_core/business/finance/FinancialDocument.dart';

class FinanceSearch {
  String? _currentQuery;
  bool _isSearching = false;
  final List<FinancialDocument> _results = [];

  String? get currentQuery => _currentQuery;
  bool get isSearching => _isSearching;
  List<FinancialDocument> get results => List.unmodifiable(_results);

  void setQuery(String? query) {
    _currentQuery = query;
    _isSearching = query != null && query.isNotEmpty;
    if (!_isSearching) {
      _results.clear();
    }
  }

  void clear() {
    _currentQuery = null;
    _isSearching = false;
    _results.clear();
  }

  void performSearch(List<FinancialDocument> documents, String query) {
    _currentQuery = query;
    _isSearching = query.isNotEmpty;

    if (query.isEmpty) {
      _results.clear();
      return;
    }

    final lowerQuery = query.toLowerCase();
    _results.clear();
    _results.addAll(
      documents.where((doc) {
        // Search in document number
        if (doc.documentNumber?.toLowerCase().contains(lowerQuery) == true) {
          return true;
        }
        // Search in customer name (if available)
        // Add more search fields as needed
        return false;
      }),
    );
  }

  List<FinancialDocument> getFilteredDocuments(
      List<FinancialDocument> documents) {
    if (!_isSearching || _currentQuery == null || _currentQuery!.isEmpty) {
      return documents;
    }
    return _results;
  }
}
