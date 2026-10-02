import 'package:event/views/business_ops_notifier.dart';
import 'package:verdelia_core/business/finance/FinancialDocument.dart';
import 'package:verdelia_core/business/finance/business_analytics.dart';

class FinanceAnalytics {
  bool _isCalculating = false;
  double _totalRevenue = 0.0;
  double _totalCollected = 0.0;
  double _totalOutstanding = 0.0;
  int _totalTransactions = 0;
  final Map<String, double> _revenueBySource = {};
  final Map<String, double> _collectionsByStatus = {};
  final Map<String, double> _revenueByDocumentType = {};
  AnalyticsCache? _cache;

  bool get isCalculating => _isCalculating;
  double get totalRevenue => _totalRevenue;
  double get totalCollected => _totalCollected;
  double get totalOutstanding => _totalOutstanding;
  int get totalTransactions => _totalTransactions;
  Map<String, double> get revenueBySource => Map.unmodifiable(_revenueBySource);
  Map<String, double> get collectionsByStatus =>
      Map.unmodifiable(_collectionsByStatus);
  Map<String, double> get revenueByDocumentType =>
      Map.unmodifiable(_revenueByDocumentType);
  AnalyticsCache? get cache => _cache;
  double get collectionRate =>
      _totalRevenue > 0 ? (_totalCollected / _totalRevenue) * 100 : 0.0;

  Future<void> refresh(List<FinancialDocument> documents) async {
    if (_isCalculating || documents.isEmpty) return;

    _isCalculating = true;
    try {
      calculate(documents);
    } finally {
      _isCalculating = false;
    }
  }

  void calculate(List<FinancialDocument> documents) {
    if (documents.isEmpty) {
      reset();
      return;
    }

    _resetValues();

    for (final doc in documents) {
      final amount = doc.documentAmount ?? 0;
      final paid = doc.totalPaid ?? 0;
      final outstanding = doc.outstandingBalance ?? 0;
      final source = doc.sourceType ?? 'unknown';
      final status = doc.paymentStatus ?? 'unknown';
      final docType = doc.documentType ?? 'unknown';

      _totalRevenue += amount;
      _totalCollected += paid;
      _totalOutstanding += outstanding;
      _totalTransactions++;

      _revenueBySource[source] = (_revenueBySource[source] ?? 0) + amount;
      _collectionsByStatus[status] = (_collectionsByStatus[status] ?? 0) + paid;
      _revenueByDocumentType[docType] =
          (_revenueByDocumentType[docType] ?? 0) + amount;
    }

    _cache = AnalyticsCache(
      totalRevenue: _totalRevenue,
      totalCollected: _totalCollected,
      totalOutstanding: _totalOutstanding,
      transactionCount: _totalTransactions,
      revenueBySource: Map.from(_revenueBySource),
      collectionsByStatus: Map.from(_collectionsByStatus),
      // revenueByDocumentType: Map.from(_revenueByDocumentType),
      collectionRate: collectionRate,
    );
  }

  void reset() {
    _resetValues();
    _cache = null;
  }

  void _resetValues() {
    _totalRevenue = 0.0;
    _totalCollected = 0.0;
    _totalOutstanding = 0.0;
    _totalTransactions = 0;
    _revenueBySource.clear();
    _collectionsByStatus.clear();
    _revenueByDocumentType.clear();
  }

  Map<String, double> getAmountByStatus(List<FinancialDocument> documents) {
    final amounts = <String, double>{};
    for (final doc in documents) {
      final status = doc.paymentStatus ?? 'Unknown';
      amounts[status] = (amounts[status] ?? 0.0) + (doc.documentAmount ?? 0);
    }
    return amounts;
  }

  Map<String, int> getTransactionCountBySource(
      List<FinancialDocument> documents) {
    final counts = <String, int>{};
    for (final doc in documents) {
      final source = doc.sourceType ?? 'Unknown';
      counts[source] = (counts[source] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, double> getAverageAmountByDocumentType(
      List<FinancialDocument> documents) {
    final amountsByType = <String, List<double>>{};
    for (final doc in documents) {
      final type = doc.documentType ?? 'Unknown';
      final amount = doc.documentAmount ?? 0;
      amountsByType.putIfAbsent(type, () => []).add(amount);
    }

    final averages = <String, double>{};
    for (final entry in amountsByType.entries) {
      final total = entry.value.fold(0.0, (sum, amount) => sum + amount);
      averages[entry.key] = total / entry.value.length;
    }
    return averages;
  }

  Map<int, double> getTopCustomersByRevenue(List<FinancialDocument> documents,
      {int limit = 10}) {
    final customerRevenue = <int, double>{};
    for (final doc in documents) {
      final customerId = doc.customerId ?? 0;
      final amount = doc.documentAmount ?? 0;
      customerRevenue[customerId] = (customerRevenue[customerId] ?? 0) + amount;
    }

    final sortedEntries = customerRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sortedEntries.take(limit));
  }

  Map<DateTime, double> getDailyRevenueTrend(List<FinancialDocument> documents,
      {int days = 30}) {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days - 1));

    final dailyRevenue = <DateTime, double>{};
    for (var i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final dateOnly = DateTime(date.year, date.month, date.day);
      dailyRevenue[dateOnly] = 0.0;
    }

    for (final doc in documents) {
      if (doc.issueDate != null &&
          !doc.issueDate!.isBefore(startDate) &&
          !doc.issueDate!.isAfter(endDate)) {
        final dateOnly = DateTime(
          doc.issueDate!.year,
          doc.issueDate!.month,
          doc.issueDate!.day,
        );
        final amount = doc.documentAmount ?? 0;
        dailyRevenue[dateOnly] = (dailyRevenue[dateOnly] ?? 0) + amount;
      }
    }

    return dailyRevenue;
  }
}
