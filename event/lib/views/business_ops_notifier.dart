// lib/business/finance/BusinessOperationNotifier.dart
//
// ChangeNotifier that owns the business-operations state:
//   - current page of operations
//   - aggregate stats (totals, ratios, counts, distributions)
//   - pagination metadata
//   - active time window
//   - loading / error / empty states
//   - filter inputs (supplier, client, date range)
//
// The notifier never touches the network directly. It delegates to a
// BusinessOperationService and normalizes every result into a single,
// UI-friendly shape.

import 'package:flutter/foundation.dart';

import 'package:verdelia_core/business/finance/BusinessOperation.dart';
import 'package:verdelia_core/business/services/BusinessOperationService.dart';

/// A loaded snapshot of one request: operations + stats + metadata.
@immutable
class BusinessOperationSnapshot {
  final List<BusinessOperation> operations;
  final BusinessOperationsStatsData? stats;
  final BusinessOperationsPagination pagination;
  final BusinessOperationsWindow window;

  const BusinessOperationSnapshot({
    required this.operations,
    required this.stats,
    required this.pagination,
    required this.window,
  });

  static const BusinessOperationSnapshot empty = BusinessOperationSnapshot(
    operations: [],
    stats: null,
    pagination: BusinessOperationsPagination(
      offset: 0,
      limit: 0,
      returned: 0,
      totalInWindow: 0,
    ),
    window: BusinessOperationsWindow(),
  );

  bool get isEmpty => operations.isEmpty;
  bool get isNotEmpty => operations.isNotEmpty;
}

/// Lifecycle state of the notifier.
enum BusinessOperationStatus { idle, loading, refreshing, ready, error }

class BusinessOperationNotifier extends ChangeNotifier {
  BusinessOperationNotifier({
    required BusinessOperationService service,
    int defaultPageSize = 50,
  })  : _service = service,
        _pageSize = defaultPageSize;

  final BusinessOperationService _service;
  final int _pageSize;

  // ---------------------------------------------------------------------
  // Filter inputs (mutated by setters, applied on load/refresh)
  // ---------------------------------------------------------------------

  int _supplierId = 0;
  int _clientId = 0;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  bool _includeStats = true;

  int get supplierId => _supplierId;
  int get clientId => _clientId;
  DateTime? get dateFrom => _dateFrom;
  DateTime? get dateTo => _dateTo;
  bool get includeStats => _includeStats;
  int get pageSize => _pageSize;

  // ---------------------------------------------------------------------
  // Loaded state
  // ---------------------------------------------------------------------

  BusinessOperationSnapshot _snapshot = BusinessOperationSnapshot.empty;
  BusinessOperationStatus _status = BusinessOperationStatus.idle;
  Object? _error;
  int _page = 0;

  List<BusinessOperation> get operations => _snapshot.operations;
  BusinessOperationsStatsData? get stats => _snapshot.stats;
  BusinessOperationsPagination get pagination => _snapshot.pagination;
  BusinessOperationsWindow get window => _snapshot.window;

  BusinessOperationStatus get status => _status;
  Object? get error => _error;
  int get page => _page;

  // Convenience accessors for common UI bindings.
  BusinessOperationsTotals? get totals => _snapshot.stats?.totals;
  BusinessOperationsRatios? get ratios => _snapshot.stats?.ratios;
  BusinessOperationsCounts? get counts => _snapshot.stats?.counts;
  Map<String, BusinessOperationsBucket> get byStatus =>
      _snapshot.stats?.byStatus ?? const {};
  Map<String, BusinessOperationsBucket> get bySource =>
      _snapshot.stats?.bySource ?? const {};
  Map<String, BusinessOperationsBucket> get bySupplier =>
      _snapshot.stats?.bySupplier ?? const {};
  Map<String, BusinessOperationsBucket> get byClient =>
      _snapshot.stats?.byClient ?? const {};
  Map<String, BusinessOperationsBucket> get byDay =>
      _snapshot.stats?.byDay ?? const {};

  bool get isLoading => _status == BusinessOperationStatus.loading;
  bool get isRefreshing => _status == BusinessOperationStatus.refreshing;
  bool get isBusy => isLoading || isRefreshing;
  bool get hasError => _status == BusinessOperationStatus.error;
  bool get isEmpty =>
      _status == BusinessOperationStatus.ready && _snapshot.isEmpty;
  bool get hasOperations => _snapshot.isNotEmpty;

  bool get hasNextPage {
    final loaded = _snapshot.pagination.offset + _snapshot.pagination.returned;
    return loaded < _snapshot.pagination.totalInWindow;
  }

  bool get hasPreviousPage => _page > 0;

  // ---------------------------------------------------------------------
  // Filter mutators — each triggers a fresh load
  // ---------------------------------------------------------------------

  Future<void> setSupplierId(int value) async {
    if (value == _supplierId) return;
    _supplierId = value;
    _page = 0;
    await load();
  }

  Future<void> setClientId(int value) async {
    if (value == _clientId) return;
    _clientId = value;
    _page = 0;
    await load();
  }

  Future<void> setDateRange(DateTime? from, DateTime? to) async {
    if (from == _dateFrom && to == _dateTo) return;
    _dateFrom = from;
    _dateTo = to;
    _page = 0;
    await load();
  }

  Future<void> clearDateRange() => setDateRange(null, null);

  Future<void> setIncludeStats(bool value) async {
    if (value == _includeStats) return;
    _includeStats = value;
    await load();
  }

  // ---------------------------------------------------------------------
  // Load / refresh / pagination
  // ---------------------------------------------------------------------

  /// Full load — shows the spinner, resets to page 0, replaces the snapshot.
  Future<void> load() async {
    await _runLoad(
      page: 0,
      mode: BusinessOperationStatus.loading,
    );
  }

  /// Silent refresh — keeps the current page and data visible while reloading.
  Future<void> refresh() async {
    await _runLoad(
      page: _page,
      mode: BusinessOperationStatus.refreshing,
    );
  }

  Future<void> nextPage() async {
    if (!hasNextPage || isBusy) return;
    await _runLoad(page: _page + 1, mode: BusinessOperationStatus.loading);
  }

  Future<void> previousPage() async {
    if (!hasPreviousPage || isBusy) return;
    await _runLoad(page: _page - 1, mode: BusinessOperationStatus.loading);
  }

  Future<void> goToPage(int page) async {
    if (page < 0 || isBusy) return;
    await _runLoad(page: page, mode: BusinessOperationStatus.loading);
  }

  Future<void> _runLoad({
    required int page,
    required BusinessOperationStatus mode,
  }) async {
    _status = mode;
    _error = null;
    notifyListeners();

    try {
      final envelope = await _service.getAllBusinessOperations(
        page,
        _pageSize,
        supplierId: _supplierId,
        clientId: _clientId,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        includeStats: _includeStats,
      );

      if (envelope == null) {
        _status = BusinessOperationStatus.error;
        _error = 'Failed to load business operations';
        notifyListeners();
        return;
      }

      _page = page;
      _snapshot = BusinessOperationSnapshot(
        operations: envelope.operations,
        stats: envelope.stats,
        pagination: envelope.pagination,
        window: envelope.window,
      );
      _status = BusinessOperationStatus.ready;
      notifyListeners();
    } catch (e, st) {
      debugPrint('BusinessOperationNotifier load failed: $e\n$st');
      _status = BusinessOperationStatus.error;
      _error = e;
      notifyListeners();
    }
  }

  /// Drop everything and return to a clean idle state.
  void reset() {
    _snapshot = BusinessOperationSnapshot.empty;
    _status = BusinessOperationStatus.idle;
    _error = null;
    _page = 0;
    notifyListeners();
  }
}
