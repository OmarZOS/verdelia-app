import 'package:verdelia_core/business/finance/FinancialDocument.dart';

class FinanceCache {
  final Map<String, List<FinancialDocument>> _cache = {};

  List<FinancialDocument>? get(String key) {
    return _cache[key];
  }

  void set(String key, List<FinancialDocument> documents) {
    _cache[key] = documents;
  }

  bool has(String key) {
    return _cache.containsKey(key);
  }

  void clear() {
    _cache.clear();
  }

  void remove(String key) {
    _cache.remove(key);
  }
}
