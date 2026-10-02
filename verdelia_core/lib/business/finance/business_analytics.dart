// lib/business/finance/business_analytics.dart

import 'package:verdelia_core/business/finance/BusinessOperation.dart';

/// Analytics over [BusinessOperation] rows.
///
/// All totals are derived from the operation model produced by the backend's
/// `/business/` endpoint. When the envelope ships its own `stats.totals` and
/// `stats.ratios`, prefer reading those directly — this class exists for the
/// cases where you only have the operations list (e.g. client-side drills,
/// per-page breakdowns, distribution lookups the envelope doesn't precompute).
class BusinessAnalytics {
  bool _isCalculating = false;
  double _totalRevenue = 0.0;
  double _totalCollected = 0.0;
  double _totalOutstanding = 0.0;
  double _totalCost = 0.0;
  double _totalMargin = 0.0;
  int _totalTransactions = 0;

  final Map<String, double> _revenueBySource = {};
  final Map<String, double> _revenueByInvoiceStatus = {};
  final Map<String, double> _dueByInvoiceStatus = {};
  final Map<String, double> _revenueBySupplier = {};
  final Map<String, double> _revenueByClient = {};
  final Map<String, double> _revenueByDay = {};

  BusinessAnalyticsCache? _cache;

  bool get isCalculating => _isCalculating;
  double get totalRevenue => _totalRevenue;
  double get totalCollected => _totalCollected;
  double get totalOutstanding => _totalOutstanding;
  double get totalCost => _totalCost;
  double get totalMargin => _totalMargin;
  int get totalTransactions => _totalTransactions;

  Map<String, double> get revenueBySource => Map.unmodifiable(_revenueBySource);
  Map<String, double> get revenueByInvoiceStatus =>
      Map.unmodifiable(_revenueByInvoiceStatus);
  Map<String, double> get dueByInvoiceStatus =>
      Map.unmodifiable(_dueByInvoiceStatus);
  Map<String, double> get revenueBySupplier =>
      Map.unmodifiable(_revenueBySupplier);
  Map<String, double> get revenueByClient => Map.unmodifiable(_revenueByClient);
  Map<String, double> get revenueByDay => Map.unmodifiable(_revenueByDay);

  BusinessAnalyticsCache? get cache => _cache;

  /// Collection rate = paid / (paid + due).
  /// Matches the backend's `stats.ratios.collection_rate`.
  double get collectionRate {
    final billable = _totalCollected + _totalOutstanding;
    return billable > 0 ? (_totalCollected / billable) * 100 : 0.0;
  }

  /// Overall ROI = (revenue - cost) / cost, matching `stats.ratios.overall_roi`.
  double? get overallRoi =>
      _totalCost > 0 ? (_totalRevenue - _totalCost) / _totalCost : null;

  Future<void> refresh(List<BusinessOperation> operations) async {
    if (_isCalculating || operations.isEmpty) return;
    _isCalculating = true;
    try {
      calculate(operations);
    } finally {
      _isCalculating = false;
    }
  }

  void calculate(List<BusinessOperation> operations) {
    if (operations.isEmpty) {
      reset();
      return;
    }

    _resetValues();

    for (final op in operations) {
      final revenue = op.grandTotal;
      final paid = op.paidAmount;
      final due = op.dueAmount;
      final cost = op.totalCost;

      _totalRevenue += revenue;
      _totalCollected += paid;
      _totalOutstanding += due;
      _totalCost += cost;
      _totalMargin += op.marginAmount;
      _totalTransactions++;

      _accumulate(_revenueBySource, op.sourceType, revenue);
      _accumulate(
        _revenueByInvoiceStatus,
        op.invoiceStatus ?? 'unknown',
        revenue,
      );
      _accumulate(
        _dueByInvoiceStatus,
        op.invoiceStatus ?? 'unknown',
        due,
      );

      if (op.supplierId != null) {
        _accumulate(
          _revenueBySupplier,
          op.supplierId.toString(),
          revenue,
        );
      }
      if (op.clientId != null) {
        _accumulate(
          _revenueByClient,
          op.clientId.toString(),
          revenue,
        );
      }
      if (op.createdAt != null) {
        final day = _dayKey(op.createdAt!);
        _accumulate(_revenueByDay, day, revenue);
      }
    }

    _cache = BusinessAnalyticsCache(
      totalRevenue: _totalRevenue,
      totalCollected: _totalCollected,
      totalOutstanding: _totalOutstanding,
      totalCost: _totalCost,
      totalMargin: _totalMargin,
      transactionCount: _totalTransactions,
      revenueBySource: Map.from(_revenueBySource),
      revenueByInvoiceStatus: Map.from(_revenueByInvoiceStatus),
      dueByInvoiceStatus: Map.from(_dueByInvoiceStatus),
      revenueBySupplier: Map.from(_revenueBySupplier),
      revenueByClient: Map.from(_revenueByClient),
      revenueByDay: Map.from(_revenueByDay),
      collectionRate: collectionRate,
      overallRoi: overallRoi,
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
    _totalCost = 0.0;
    _totalMargin = 0.0;
    _totalTransactions = 0;
    _revenueBySource.clear();
    _revenueByInvoiceStatus.clear();
    _dueByInvoiceStatus.clear();
    _revenueBySupplier.clear();
    _revenueByClient.clear();
    _revenueByDay.clear();
  }

  // ---------------------------------------------------------------------
  // Ad-hoc queries over a list of operations (not memoized)
  // ---------------------------------------------------------------------

  /// Total amount grouped by invoice status.
  Map<String, double> getAmountByInvoiceStatus(
    List<BusinessOperation> operations,
  ) {
    final amounts = <String, double>{};
    for (final op in operations) {
      final key = op.invoiceStatus ?? 'unknown';
      _accumulate(amounts, key, op.grandTotal);
    }
    return amounts;
  }

  /// Number of operations grouped by source type (`cart` / `delivery`).
  Map<String, int> getTransactionCountBySource(
    List<BusinessOperation> operations,
  ) {
    final counts = <String, int>{};
    for (final op in operations) {
      counts[op.sourceType] = (counts[op.sourceType] ?? 0) + 1;
    }
    return counts;
  }

  /// Average grand total grouped by source type.
  Map<String, double> getAverageAmountBySource(
    List<BusinessOperation> operations,
  ) {
    final sums = <String, double>{};
    final counts = <String, int>{};
    for (final op in operations) {
      sums[op.sourceType] = (sums[op.sourceType] ?? 0) + op.grandTotal;
      counts[op.sourceType] = (counts[op.sourceType] ?? 0) + 1;
    }
    return {
      for (final entry in sums.entries)
        entry.key:
            counts[entry.key]! > 0 ? entry.value / counts[entry.key]! : 0.0,
    };
  }

  /// Top clients by grand total.
  Map<int, double> getTopClientsByRevenue(
    List<BusinessOperation> operations, {
    int limit = 10,
  }) {
    final revenue = <int, double>{};
    for (final op in operations) {
      final id = op.clientId;
      if (id == null) continue;
      revenue[id] = (revenue[id] ?? 0) + op.grandTotal;
    }
    final sorted = revenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(limit));
  }

  /// Top suppliers by grand total.
  Map<int, double> getTopSuppliersByRevenue(
    List<BusinessOperation> operations, {
    int limit = 10,
  }) {
    final revenue = <int, double>{};
    for (final op in operations) {
      final id = op.supplierId;
      if (id == null) continue;
      revenue[id] = (revenue[id] ?? 0) + op.grandTotal;
    }
    final sorted = revenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(limit));
  }

  /// Daily revenue trend over the last [days] days.
  ///
  /// Days with no operations are present with value 0.0.
  Map<DateTime, double> getDailyRevenueTrend(
    List<BusinessOperation> operations, {
    int days = 30,
  }) {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days - 1));

    final dailyRevenue = <DateTime, double>{};
    for (var i = 0; i < days; i++) {
      final d = startDate.add(Duration(days: i));
      dailyRevenue[DateTime(d.year, d.month, d.day)] = 0.0;
    }

    for (final op in operations) {
      final created = op.createdAt;
      if (created == null) continue;
      if (created.isBefore(startDate) || created.isAfter(endDate)) continue;
      final key = DateTime(created.year, created.month, created.day);
      dailyRevenue[key] = (dailyRevenue[key] ?? 0) + op.grandTotal;
    }

    return dailyRevenue;
  }

  /// Margin breakdown by source type.
  Map<String, double> getMarginBySource(
    List<BusinessOperation> operations,
  ) {
    final margin = <String, double>{};
    for (final op in operations) {
      _accumulate(margin, op.sourceType, op.marginAmount);
    }
    return margin;
  }

  // ---------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------

  static void _accumulate(
    Map<String, double> map,
    String key,
    double amount,
  ) {
    map[key] = (map[key] ?? 0) + amount;
  }

  static String _dayKey(DateTime d) {
    final local = d.toLocal();
    return '${local.year}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }
}

/// Immutable snapshot of a completed analysis pass.
class BusinessAnalyticsCache {
  final double totalRevenue;
  final double totalCollected;
  final double totalOutstanding;
  final double totalCost;
  final double totalMargin;
  final int transactionCount;
  final Map<String, double> revenueBySource;
  final Map<String, double> revenueByInvoiceStatus;
  final Map<String, double> dueByInvoiceStatus;
  final Map<String, double> revenueBySupplier;
  final Map<String, double> revenueByClient;
  final Map<String, double> revenueByDay;
  final double collectionRate;
  final double? overallRoi;

  const BusinessAnalyticsCache({
    required this.totalRevenue,
    required this.totalCollected,
    required this.totalOutstanding,
    required this.totalCost,
    required this.totalMargin,
    required this.transactionCount,
    required this.revenueBySource,
    required this.revenueByInvoiceStatus,
    required this.dueByInvoiceStatus,
    required this.revenueBySupplier,
    required this.revenueByClient,
    required this.revenueByDay,
    required this.collectionRate,
    required this.overallRoi,
  });

  double get averageTicket =>
      transactionCount > 0 ? totalRevenue / transactionCount : 0.0;
}

class AnalyticsCache {
  final double totalRevenue;
  final double totalCollected;
  final double totalOutstanding;
  final int transactionCount;
  final Map<String, double> revenueBySource;
  final Map<String, double> collectionsByStatus;
  // final Map<String, double> revenueByDocumentType;
  final double collectionRate;

  const AnalyticsCache({
    required this.totalRevenue,
    required this.totalCollected,
    required this.totalOutstanding,
    required this.transactionCount,
    required this.revenueBySource,
    required this.collectionsByStatus,
    // required this.revenueByDocumentType,
    required this.collectionRate,
  });
}
