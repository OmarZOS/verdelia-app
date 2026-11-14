// lib/business/finance/business_analytics.dart

import 'package:decimal/decimal.dart';

import 'package:verdelia_core/business/finance/BusinessOperation.dart';

/// Analytics over [BusinessOperation] rows.
///
/// All totals are derived from the operation model produced by the backend's
/// `/business/` endpoint. When the envelope ships its own `stats.totals` and
/// `stats.ratios`, prefer reading those directly — this class exists for the
/// cases where you only have the operations list (e.g. client-side drills,
/// per-page breakdowns, distribution lookups the envelope doesn't precompute).
///
/// ## Money
///
/// Every aggregate ([totalRevenue], [totalCollected], [totalOutstanding],
/// [totalCost], [totalMargin]), every per-group map, and the two ratio
/// getters ([collectionRate], [overallRoi]) are [Decimal]. The `double`
/// conversion happens only inside [BusinessAnalyticsCache] if a caller
/// chooses to widen it back for legacy display; this file keeps it
/// `Decimal` end-to-end.
class BusinessAnalytics {
  bool _isCalculating = false;

  Decimal _totalRevenue = Decimal.zero;
  Decimal _totalCollected = Decimal.zero;
  Decimal _totalOutstanding = Decimal.zero;
  Decimal _totalCost = Decimal.zero;
  Decimal _totalMargin = Decimal.zero;
  int _totalTransactions = 0;

  final Map<String, Decimal> _revenueBySource = {};
  final Map<String, Decimal> _revenueByInvoiceStatus = {};
  final Map<String, Decimal> _dueByInvoiceStatus = {};
  final Map<String, Decimal> _revenueBySupplier = {};
  final Map<String, Decimal> _revenueByClient = {};
  final Map<String, Decimal> _revenueByDay = {};

  BusinessAnalyticsCache? _cache;

  bool get isCalculating => _isCalculating;
  Decimal get totalRevenue => _totalRevenue;
  Decimal get totalCollected => _totalCollected;
  Decimal get totalOutstanding => _totalOutstanding;
  Decimal get totalCost => _totalCost;
  Decimal get totalMargin => _totalMargin;
  int get totalTransactions => _totalTransactions;

  Map<String, Decimal> get revenueBySource =>
      Map.unmodifiable(_revenueBySource);
  Map<String, Decimal> get revenueByInvoiceStatus =>
      Map.unmodifiable(_revenueByInvoiceStatus);
  Map<String, Decimal> get dueByInvoiceStatus =>
      Map.unmodifiable(_dueByInvoiceStatus);
  Map<String, Decimal> get revenueBySupplier =>
      Map.unmodifiable(_revenueBySupplier);
  Map<String, Decimal> get revenueByClient =>
      Map.unmodifiable(_revenueByClient);
  Map<String, Decimal> get revenueByDay => Map.unmodifiable(_revenueByDay);

  BusinessAnalyticsCache? get cache => _cache;

  /// Collection rate = `paid / (paid + due) * 100`, in [Decimal].
  /// Matches the backend's `stats.ratios.collection_rate`.
  ///
  /// `.toDecimal(scaleOnInfinitePrecision: 2)` on the division: `Decimal / Decimal` returns a
  /// `Rational`, which can't be assigned to a `Decimal`.
  Decimal get collectionRate {
    final billable = _totalCollected + _totalOutstanding;
    if (billable <= Decimal.zero) return Decimal.zero;
    return (_totalCollected / billable).toDecimal(scaleOnInfinitePrecision: 2) *
        Decimal.fromInt(100);
  }

  /// Overall ROI = `(revenue - cost) / cost`, in [Decimal]. Null when
  /// cost is zero (matching the backend's nullable `overall_roi`).
  ///
  /// `.toDecimal(scaleOnInfinitePrecision: 2)` on the division, same reason as [collectionRate].
  Decimal? get overallRoi {
    if (_totalCost <= Decimal.zero) return null;
    return ((_totalRevenue - _totalCost) / _totalCost)
        .toDecimal(scaleOnInfinitePrecision: 2);
  }

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
      // All money fields on `BusinessOperation` are non-null `Decimal`
      // after the model migration.
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
    _totalRevenue = Decimal.zero;
    _totalCollected = Decimal.zero;
    _totalOutstanding = Decimal.zero;
    _totalCost = Decimal.zero;
    _totalMargin = Decimal.zero;
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

  /// Total amount grouped by invoice status, in [Decimal].
  Map<String, Decimal> getAmountByInvoiceStatus(
    List<BusinessOperation> operations,
  ) {
    final amounts = <String, Decimal>{};
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

  /// Average grand total grouped by source type, in [Decimal].
  ///
  /// The per-group division needs `.toDecimal(scaleOnInfinitePrecision: 2)`.
  Map<String, Decimal> getAverageAmountBySource(
    List<BusinessOperation> operations,
  ) {
    final sums = <String, Decimal>{};
    final counts = <String, int>{};
    for (final op in operations) {
      sums[op.sourceType] =
          (sums[op.sourceType] ?? Decimal.zero) + op.grandTotal;
      counts[op.sourceType] = (counts[op.sourceType] ?? 0) + 1;
    }
    return {
      for (final entry in sums.entries)
        entry.key: counts[entry.key]! > 0
            ? (entry.value / Decimal.fromInt(counts[entry.key]!))
                .toDecimal(scaleOnInfinitePrecision: 2)
            : Decimal.zero,
    };
  }

  /// Top clients by grand total, in [Decimal].
  Map<int, Decimal> getTopClientsByRevenue(
    List<BusinessOperation> operations, {
    int limit = 10,
  }) {
    final revenue = <int, Decimal>{};
    for (final op in operations) {
      final id = op.clientId;
      if (id == null) continue;
      revenue[id] = (revenue[id] ?? Decimal.zero) + op.grandTotal;
    }
    final sorted = revenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(limit));
  }

  /// Top suppliers by grand total, in [Decimal].
  Map<int, Decimal> getTopSuppliersByRevenue(
    List<BusinessOperation> operations, {
    int limit = 10,
  }) {
    final revenue = <int, Decimal>{};
    for (final op in operations) {
      final id = op.supplierId;
      if (id == null) continue;
      revenue[id] = (revenue[id] ?? Decimal.zero) + op.grandTotal;
    }
    final sorted = revenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(limit));
  }

  /// Daily revenue trend over the last [days] days, in [Decimal].
  ///
  /// Days with no operations are present with value `Decimal.zero`.
  Map<DateTime, Decimal> getDailyRevenueTrend(
    List<BusinessOperation> operations, {
    int days = 30,
  }) {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days - 1));

    final dailyRevenue = <DateTime, Decimal>{};
    for (var i = 0; i < days; i++) {
      final d = startDate.add(Duration(days: i));
      dailyRevenue[DateTime(d.year, d.month, d.day)] = Decimal.zero;
    }

    for (final op in operations) {
      final created = op.createdAt;
      if (created == null) continue;
      if (created.isBefore(startDate) || created.isAfter(endDate)) continue;
      final key = DateTime(created.year, created.month, created.day);
      dailyRevenue[key] = (dailyRevenue[key] ?? Decimal.zero) + op.grandTotal;
    }

    return dailyRevenue;
  }

  /// Margin breakdown by source type, in [Decimal].
  Map<String, Decimal> getMarginBySource(
    List<BusinessOperation> operations,
  ) {
    final margin = <String, Decimal>{};
    for (final op in operations) {
      _accumulate(margin, op.sourceType, op.marginAmount);
    }
    return margin;
  }

  // ---------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------

  static void _accumulate(
    Map<String, Decimal> map,
    String key,
    Decimal amount,
  ) {
    map[key] = (map[key] ?? Decimal.zero) + amount;
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
  final Decimal totalRevenue;
  final Decimal totalCollected;
  final Decimal totalOutstanding;
  final Decimal totalCost;
  final Decimal totalMargin;
  final int transactionCount;
  final Map<String, Decimal> revenueBySource;
  final Map<String, Decimal> revenueByInvoiceStatus;
  final Map<String, Decimal> dueByInvoiceStatus;
  final Map<String, Decimal> revenueBySupplier;
  final Map<String, Decimal> revenueByClient;
  final Map<String, Decimal> revenueByDay;
  final Decimal collectionRate;
  final Decimal? overallRoi;

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

  /// Average ticket = `totalRevenue / transactionCount`, in [Decimal].
  ///
  /// `.toDecimal(scaleOnInfinitePrecision: 2)` on the division.
  Decimal get averageTicket => transactionCount > 0
      ? (totalRevenue / Decimal.fromInt(transactionCount))
          .toDecimal(scaleOnInfinitePrecision: 2)
      : Decimal.zero;
}

/// Settlement-focused snapshot. Used by `FinanceAnalytics`, which
/// doesn't need cost / margin / per-supplier / per-client breakdowns.
///
/// Kept separate from [BusinessAnalyticsCache] on purpose: the two
/// domains have different shapes, and this one is what `FinanceAnalytics`
/// consumes.
class AnalyticsCache {
  final Decimal totalRevenue;
  final Decimal totalCollected;
  final Decimal totalOutstanding;
  final int transactionCount;
  final Map<String, Decimal> revenueBySource;
  final Map<String, Decimal> collectionsByStatus;
  // final Map<String, Decimal> revenueByDocumentType;
  final Decimal collectionRate;

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
