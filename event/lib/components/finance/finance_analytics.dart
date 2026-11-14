// lib/event/views/finance_analytics.dart
import 'package:decimal/decimal.dart';

import 'package:event/views/business_ops_notifier.dart';
import 'package:verdelia_core/business/finance/FinancialDocument.dart';
import 'package:verdelia_core/business/finance/business_analytics.dart';

class FinanceAnalytics {
  bool _isCalculating = false;

  Decimal _totalRevenue = Decimal.zero;
  Decimal _totalCollected = Decimal.zero;
  Decimal _totalOutstanding = Decimal.zero;
  int _totalTransactions = 0;

  final Map<String, Decimal> _revenueBySource = {};
  final Map<String, Decimal> _collectionsByStatus = {};
  final Map<String, Decimal> _revenueByDocumentType = {};
  AnalyticsCache? _cache;

  bool get isCalculating => _isCalculating;
  Decimal get totalRevenue => _totalRevenue;
  Decimal get totalCollected => _totalCollected;
  Decimal get totalOutstanding => _totalOutstanding;
  int get totalTransactions => _totalTransactions;
  Map<String, Decimal> get revenueBySource =>
      Map.unmodifiable(_revenueBySource);
  Map<String, Decimal> get collectionsByStatus =>
      Map.unmodifiable(_collectionsByStatus);
  Map<String, Decimal> get revenueByDocumentType =>
      Map.unmodifiable(_revenueByDocumentType);
  AnalyticsCache? get cache => _cache;

  /// Collection rate as a percentage (`0..100`), in [Decimal].
  ///
  /// `.toDecimal(scaleOnInfinitePrecision: 2)` on the division: `Decimal / Decimal` returns a
  /// `Rational`, which can't be assigned to a `Decimal`.
  Decimal get collectionRate {
    if (_totalRevenue <= Decimal.zero) return Decimal.zero;
    return (_totalCollected / _totalRevenue)
            .toDecimal(scaleOnInfinitePrecision: 2) *
        Decimal.fromInt(100);
  }

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
      // All money fields on `FinancialDocument` are non-null after the
      // model migration, so no `?? 0` fallbacks are needed.
      final amount = doc.documentAmount;
      final paid = doc.totalPaid;
      final outstanding = doc.outstandingBalance;
      final source = doc.sourceType;
      final status = doc.paymentStatus;
      final docType = doc.documentType;

      _totalRevenue += amount;
      _totalCollected += paid;
      _totalOutstanding += outstanding;
      _totalTransactions++;

      _revenueBySource[source] =
          (_revenueBySource[source] ?? Decimal.zero) + amount;
      _collectionsByStatus[status] =
          (_collectionsByStatus[status] ?? Decimal.zero) + paid;
      _revenueByDocumentType[docType] =
          (_revenueByDocumentType[docType] ?? Decimal.zero) + amount;
    }

    _cache = AnalyticsCache(
      totalRevenue: _totalRevenue,
      totalCollected: _totalCollected,
      totalOutstanding: _totalOutstanding,
      transactionCount: _totalTransactions,
      revenueBySource: Map<String, Decimal>.from(_revenueBySource),
      collectionsByStatus: Map<String, Decimal>.from(_collectionsByStatus),
      // FIX: the original commented this out, so the getter was always
      // empty after a `calculate`. Uncomment once `AnalyticsCache`
      // declares the field.
      // revenueByDocumentType: Map.from(_revenueByDocumentType),
      collectionRate: collectionRate,
    );
  }

  void reset() {
    _resetValues();
    _cache = null;
  }

  void _resetValues() {
    _totalRevenue = Decimal.zero;
    _totalCollected = Decimal.zero;
    _totalOutstanding = Decimal.zero;
    _totalTransactions = 0;
    _revenueBySource.clear();
    _collectionsByStatus.clear();
    _revenueByDocumentType.clear();
  }

  Map<String, Decimal> getAmountByStatus(List<FinancialDocument> documents) {
    final amounts = <String, Decimal>{};
    for (final doc in documents) {
      final status = doc.paymentStatus;
      amounts[status] = (amounts[status] ?? Decimal.zero) + doc.documentAmount;
    }
    return amounts;
  }

  Map<String, int> getTransactionCountBySource(
      List<FinancialDocument> documents) {
    final counts = <String, int>{};
    for (final doc in documents) {
      final source = doc.sourceType;
      counts[source] = (counts[source] ?? 0) + 1;
    }
    return counts;
  }

  /// Average document amount, grouped by `documentType`, in [Decimal].
  ///
  /// The per-group division needs `.toDecimal(scaleOnInfinitePrecision: 2)` for the same reason
  /// as [collectionRate].
  Map<String, Decimal> getAverageAmountByDocumentType(
      List<FinancialDocument> documents) {
    final amountsByType = <String, List<Decimal>>{};
    for (final doc in documents) {
      final type = doc.documentType;
      amountsByType.putIfAbsent(type, () => []).add(doc.documentAmount);
    }

    final averages = <String, Decimal>{};
    for (final entry in amountsByType.entries) {
      final total = entry.value.fold(
        Decimal.zero,
        (sum, amount) => sum + amount,
      );
      final count = Decimal.fromInt(entry.value.length);
      averages[entry.key] =
          (total / count).toDecimal(scaleOnInfinitePrecision: 2);
    }
    return averages;
  }

  Map<int, Decimal> getTopCustomersByRevenue(
    List<FinancialDocument> documents, {
    int limit = 10,
  }) {
    final customerRevenue = <int, Decimal>{};
    for (final doc in documents) {
      final customerId = doc.customerId;
      customerRevenue[customerId] =
          (customerRevenue[customerId] ?? Decimal.zero) + doc.documentAmount;
    }

    final sortedEntries = customerRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sortedEntries.take(limit));
  }

  Map<DateTime, Decimal> getDailyRevenueTrend(
    List<FinancialDocument> documents, {
    int days = 30,
  }) {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days - 1));

    final dailyRevenue = <DateTime, Decimal>{};
    for (var i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final dateOnly = DateTime(date.year, date.month, date.day);
      dailyRevenue[dateOnly] = Decimal.zero;
    }

    for (final doc in documents) {
      // `issueDate` is non-null on the migrated `FinancialDocument`.
      final issueDate = doc.issueDate;
      if (!issueDate.isBefore(startDate) && !issueDate.isAfter(endDate)) {
        final dateOnly = DateTime(
          issueDate.year,
          issueDate.month,
          issueDate.day,
        );
        dailyRevenue[dateOnly] =
            (dailyRevenue[dateOnly] ?? Decimal.zero) + doc.documentAmount;
      }
    }

    return dailyRevenue;
  }
}
