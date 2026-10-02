// finance_change_notifier.dart
import 'dart:async';
import 'dart:developer';

import 'package:event/components/finance/finance_download.dart';
import 'package:flutter/material.dart';
import 'package:verdelia_core/business/finance/FinancialDocument.dart';
import 'package:verdelia_core/business/finance/business_analytics.dart';
import 'package:verdelia_core/business/finance/services/InvoiceService.dart';
import 'package:event/components/finance/finance_analytics.dart';
import 'package:event/components/finance/finance_constants.dart';
import 'package:event/components/finance/finance_document_operations.dart';
import 'package:event/components/finance/finance_filter.dart';
import 'package:event/components/finance/finance_grouping.dart';
import 'package:event/components/finance/finance_pagination.dart';
import 'package:event/components/finance/finance_search.dart';
import 'package:event/components/finance/finance_state.dart';
import 'package:locator/locator.dart';

// ==================== DEBUG LOGGER ====================

void _log(String tag, String message, {Object? error, StackTrace? stack}) {
  final ts = DateTime.now().toIso8601String().substring(11, 23);
  if (error != null) {
    debugPrint('[$ts][FinanceNotifier][$tag] $message\n  error: $error');
    if (stack != null) debugPrint('  stack: $stack');
  } else {
    debugPrint('[$ts][FinanceNotifier][$tag] $message');
  }
}

/// Finance domain notifier.
///
/// Owns everything related to financial documents and their analytics.
/// Business operations (carts, deliveries, per-supplier operation summaries)
/// are handled by [BusinessOperationNotifier] — this class does not touch
/// them.
class FinanceChangeNotifier extends ChangeNotifier {
  // ==================== DEPENDENCIES ====================

  final InvoiceService _invoiceService = AppLocator.get<InvoiceService>();

  // ==================== COMPONENTS ====================

  final FinanceAnalytics _analytics = FinanceAnalytics();
  final FinanceCache _cache = FinanceCache();
  final FinanceDocumentOperations _documentOps = FinanceDocumentOperations();
  FinanceFilter _filter = FinanceFilter();

  FinanceDocumentFilter get filter => _filter.current;
  final FinanceGrouping _grouping = FinanceGrouping();
  final FinancePagination _pagination = FinancePagination();
  final FinanceSearch _search = FinanceSearch();
  final FinanceState _state = FinanceState();

  // ==================== PROVIDER SCOPE ====================

  int _providerId = 0;
  int get providerId => _providerId;
  bool get hasProvider => _providerId > 0;

  // ==================== CONSTRUCTOR ====================

  FinanceChangeNotifier() {
    _log('init', 'FinanceChangeNotifier created');
  }

  // ==================== DOCUMENT GETTERS ====================

  List<FinancialDocument> get filteredDocuments => _applyFilters();

  List<FinancialDocument> get documents => _documentOps.primaryDocuments;

  bool get isLoading => _state.isLoading;
  bool get isRefreshing => _state.isRefreshing;
  bool get hasMoreDocuments => _pagination.hasMore;
  String? get currentSearchQuery => _search.currentQuery;

  // Analytics
  bool get isCalculatingAnalytics => _analytics.isCalculating;
  double get totalRevenue => _analytics.totalRevenue;
  double get totalCollected => _analytics.totalCollected;
  double get totalOutstanding => _analytics.totalOutstanding;
  int get totalTransactions => _analytics.totalTransactions;
  Map<String, double> get revenueBySource => _analytics.revenueBySource;
  Map<String, double> get collectionsByStatus => _analytics.collectionsByStatus;
  Map<String, double> get revenueByDocumentType =>
      _analytics.revenueByDocumentType;
  AnalyticsCache? get analyticsCache => _analytics.cache;
  double get collectionRate => _analytics.collectionRate;

  // Download state
  double _downloadProgress = 0.0;
  double get downloadProgress => _downloadProgress;
  bool get isDownloading => _isDownloading;
  bool _isDownloading = false;

  double get totalAmount {
    return filteredDocuments.fold(
        0.0, (sum, doc) => sum + (doc.documentAmount ?? 0));
  }

  // ==================== PROVIDER SCOPE ====================

  Future<void> setProvider(int newProviderId) async {
    if (newProviderId == _providerId) {
      _log('setProvider', 'no-op (already on provider $_providerId)');
      return;
    }
    if (newProviderId < 0) {
      _log('setProvider', 'rejected (negative id $newProviderId)');
      return;
    }

    _log('setProvider',
        'switching $_providerId → $newProviderId (clearing state)');

    _providerId = newProviderId;

    // Clear all document state.
    _documentOps.clear();
    _grouping.clear();
    _cache.clear();
    _pagination.reset();
    _analytics.reset();

    notifyListeners();

    if (_providerId > 0) {
      _log('setProvider', 'fetching documents for provider $_providerId');
      await _fetchDocuments(reset: true);
    } else {
      _log('setProvider', 'no provider (0) — skipping fetch');
    }
  }

  // ==================== CORE METHODS ====================

  Future<void> refreshAll({FinanceDocumentFilter? filter}) async {
    if (_state.isRefreshing) {
      _log('refreshAll', 'skipped (already refreshing)');
      return;
    }

    _log(
        'refreshAll',
        'starting (${filter != null ? "with new filter" : "keeping filter"}, '
            'provider=$_providerId)');

    _state.setRefreshing(true);
    notifyListeners();

    try {
      if (filter != null) {
        _filter.setFilter(filter);
      }
      await _fetchDocuments(reset: true);
    } finally {
      _state.setRefreshing(false);
      notifyListeners();
      _log('refreshAll', 'done');
    }
  }

  Future<void> fetchDocuments({
    bool reset = false,
    int personId = 0,
    int clientId = 0,
    int sellerId = 0,
    int cartId = 0,
    int orderId = 0,
    int depositId = 0,
    int invoiceId = 0,
  }) async {
    _log('fetchDocuments',
        'reset=$reset CALLER: ${StackTrace.current.toString().split("\n")[1].trim()}');
    await _fetchDocuments(
      reset: reset,
      personId: personId,
      clientId: clientId,
      sellerId: sellerId,
      cartId: cartId,
      orderId: orderId,
      depositId: depositId,
      invoiceId: invoiceId,
    );
  }

  Future<void> _fetchDocuments({
    bool reset = false,
    int personId = 0,
    int clientId = 0,
    int sellerId = 0,
    int cartId = 0,
    int orderId = 0,
    int depositId = 0,
    int invoiceId = 0,
  }) async {
    if (_state.isLoading) {
      _log('_fetchDocuments', 'skipped (already loading)');
      return;
    }
    if (!reset && !_pagination.hasMore) {
      _log('_fetchDocuments', 'skipped (no more documents)');
      return;
    }
    if (!hasProvider) {
      _log('_fetchDocuments', 'skipped (no provider selected)');
      if (_documentOps.allDocuments.isNotEmpty) {
        _documentOps.clear();
        _grouping.clear();
        _cache.clear();
        _analytics.reset();
        notifyListeners();
      }
      return;
    }

    if (reset) {
      _log('_fetchDocuments', 'resetting state before fetch');
      _documentOps.clear();
      _grouping.clear();
      _pagination.reset();
      _cache.clear();
      _analytics.reset();
    }

    _setLoading(true);

    final offset = _pagination.nextOffset;
    _log(
        '_fetchDocuments',
        'GET provider=$_providerId offset=$offset '
            'limit=${FinanceConstants.pageSize}');

    try {
      final fetched = await _invoiceService.getAllFinanceDocs(
        offset,
        FinanceConstants.pageSize,
        supplierId: _providerId,
        personId: personId,
        clientId: clientId,
        sellerId: sellerId,
        cartId: cartId,
        orderId: orderId,
        depositId: depositId,
        invoiceId: invoiceId,
      );

      if (fetched == null) {
        _log('_fetchDocuments', 'response was null');
        _pagination.setHasMore(false);
        return;
      }

      _log('_fetchDocuments',
          'received ${fetched.length} document(s) for provider $_providerId');

      if (fetched.isEmpty) {
        _log('_fetchDocuments', 'empty result → no more documents');
        _pagination.setHasMore(false);
        return;
      }

      // Defensive scope filter — drop anything from another provider.
      final scoped = fetched
          .where((d) => d.supplierId == null || d.supplierId == _providerId)
          .toList();

      if (scoped.length != fetched.length) {
        final sample = fetched.first;
        _log(
            '_fetchDocuments',
            'dropped ${fetched.length - scoped.length} out-of-scope. '
                'Sample: docId=${sample.documentId} '
                'supplierId=${sample.supplierId} '
                'type=${sample.documentType} '
                'sourceId=${sample.sourceId}');
      }

      _addDocuments(scoped);
      _groupDocuments();

      // Pagination uses the *server* response size, not the scoped count.
      _pagination.update(fetched.length);

      _calculateAnalytics();
      _log(
          '_fetchDocuments',
          'done: allDocs=${_documentOps.allDocuments.length} '
              'grouped=${_documentOps.primaryDocuments.length} '
              'transactions=${_analytics.totalTransactions} '
              'revenue=${_analytics.totalRevenue.toStringAsFixed(2)}');
    } catch (e, stackTrace) {
      _log('_fetchDocuments', 'FAILED', error: e, stack: stackTrace);
    } finally {
      _setLoading(false);
    }
  }

  // ==================== FILTER MANAGEMENT ====================

  void setFilter(FinanceDocumentFilter newFilter) {
    _log(
        'setFilter',
        'applying filter (docType=${newFilter.documentType}, '
            'status=${newFilter.status}, supplier=${newFilter.supplierId}, '
            'search="${newFilter.searchQuery ?? ""}")');
    _filter.setFilter(newFilter);
    _cache.clear();
    notifyListeners();
  }

  void clearFilter() {
    _log('clearFilter', 'clearing all filter fields');
    _filter.clear();
    _cache.clear();
    notifyListeners();
  }

  void setSearchQuery(String? query) {
    _log('setSearchQuery', 'query="${query ?? ""}"');
    _search.setQuery(query);
    _filter.update(searchQuery: query);
    _cache.clear();
    notifyListeners();
  }

  void clearSearch() {
    _log('clearSearch', 'clearing search query');
    _search.clear();
    _filter.update(searchQuery: null);
    _cache.clear();
    notifyListeners();
  }

  // ==================== DOCUMENT OPERATIONS ====================

  Future<FinancialDocument?> submitFinancialDocument(
      dynamic financeData) async {
    _log('submitFinancialDocument', 'submitting');
    _setLoading(true);
    try {
      final data = await _invoiceService.addFinancialDocument(financeData);
      if (data != null) {
        _log('submitFinancialDocument',
            'succeeded (docId=${data.documentId}), refreshing');
        await refreshAll();
        return data;
      }
      _log('submitFinancialDocument', 'service returned null');
      return null;
    } catch (e, stack) {
      _log('submitFinancialDocument', 'FAILED', error: e, stack: stack);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<PaymentSubmitResult> submitPayment({
    required int invoiceId,
    required double amount,
    required String method,
    String status = "pending",
    String? notes,
  }) async {
    _log('submitPayment',
        'invoice=$invoiceId amount=$amount method=$method status=$status');

    if (invoiceId <= 0) {
      _log('submitPayment', 'REJECTED: no invoice linked');
      return const PaymentSubmitResult.failure(
          'No invoice linked to this document.');
    }
    if (amount <= 0) {
      _log('submitPayment', 'REJECTED: amount <= 0');
      return const PaymentSubmitResult.failure(
          'Payment amount must be greater than zero.');
    }
    if (method.trim().isEmpty) {
      _log('submitPayment', 'REJECTED: empty method');
      return const PaymentSubmitResult.failure('Payment method is required.');
    }
    if (method.toLowerCase() == "cash") status = "completed";

    _setLoading(true);
    try {
      final payment = await _invoiceService.addFinancialDocument({
        "payment_invoice_id": invoiceId,
        "payment_amount": amount,
        "payment_method": method,
        "payment_status": status,
        "payment_notes": notes ?? '',
      });

      if (payment == null) {
        _log('submitPayment', 'service returned null');
        return const PaymentSubmitResult.failure('Payment was not recorded.');
      }

      _log('submitPayment',
          'recorded (docId=${payment.documentId}), refreshing');
      await refreshAll();

      return PaymentSubmitResult.success(
        'Payment recorded.',
        paymentId: payment.documentId,
      );
    } catch (e, stack) {
      _log('submitPayment', 'FAILED', error: e, stack: stack);
      return PaymentSubmitResult.failure('$e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> downloadDocumentWithProgress({
    required FinancialDocument document,
    required BuildContext context,
    String? format,
    Function(double)? onProgress,
  }) async {
    if (_isDownloading) {
      _log('download', 'skipped (already downloading)');
      return;
    }

    _log('download', 'starting (docId=${document.documentId} format=$format)');

    _isDownloading = true;
    _downloadProgress = 0.0;
    notifyListeners();

    try {
      for (int i = 0; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        _downloadProgress = i / 10;
        onProgress?.call(_downloadProgress);
        notifyListeners();
      }
      _log('download', 'done (simulated)');
    } finally {
      _isDownloading = false;
      _downloadProgress = 0.0;
      notifyListeners();
    }
  }

  // ==================== ANALYTICS ====================

  Future<void> refreshAnalytics() async {
    if (_analytics.isCalculating) {
      _log('refreshAnalytics', 'skipped (already calculating)');
      return;
    }
    if (_documentOps.primaryDocuments.isEmpty) {
      _log('refreshAnalytics', 'skipped (no documents)');
      return;
    }

    _log('refreshAnalytics',
        'recalculating over ${_documentOps.primaryDocuments.length} docs');

    await _analytics.refresh(_documentOps.primaryDocuments);
    notifyListeners();
  }

  void _calculateAnalytics() {
    _analytics.calculate(_documentOps.primaryDocuments);
    _log(
        '_calculateAnalytics',
        'revenue=${_analytics.totalRevenue.toStringAsFixed(2)} '
            'collected=${_analytics.totalCollected.toStringAsFixed(2)} '
            'outstanding=${_analytics.totalOutstanding.toStringAsFixed(2)} '
            'txn=${_analytics.totalTransactions} '
            'rate=${_analytics.collectionRate.toStringAsFixed(1)}%');
  }

  // ==================== STATISTICS HELPERS ====================

  Map<String, double> getAmountByStatus() =>
      _analytics.getAmountByStatus(filteredDocuments);

  Map<String, int> getTransactionCountBySource() =>
      _analytics.getTransactionCountBySource(filteredDocuments);

  Map<String, double> getAverageAmountByDocumentType() =>
      _analytics.getAverageAmountByDocumentType(filteredDocuments);

  Map<int, double> getTopCustomersByRevenue({int limit = 10}) =>
      _analytics.getTopCustomersByRevenue(filteredDocuments, limit: limit);

  Map<DateTime, double> getDailyRevenueTrend({int days = 30}) =>
      _analytics.getDailyRevenueTrend(filteredDocuments, days: days);

  // ==================== PRIVATE HELPERS ====================

  void _addDocuments(List<FinancialDocument> newDocuments) {
    final before = _documentOps.allDocuments.length;
    _documentOps.addDocuments(newDocuments);
    final after = _documentOps.allDocuments.length;

    _log(
        '_addDocuments',
        'added=${after - before} skipped=${newDocuments.length - (after - before)} '
            'total=$after');

    _cache.clear();
    notifyListeners();
  }

  void _groupDocuments() {
    final primaries = _grouping.groupDocuments(_documentOps.allDocuments);

    _documentOps.setPrimaryDocuments(primaries);
    _documentOps.setDocumentGroups(_grouping.documentGroups);

    _log(
        '_groupDocuments',
        'grouping ${_documentOps.allDocuments.length} docs into '
            '${primaries.length} source group(s)');

    _cache.clear();
    notifyListeners();
  }

  /// Apply the current filter + provider scope to the loaded documents.
  ///
  /// Cached by `providerId + filter.toCacheKey()`, so switching providers or
  /// changing any filter field invalidates the entry naturally.
  List<FinancialDocument> _applyFilters() {
    final cacheKey = '$_providerId|${_filter.current.toCacheKey()}';
    final cached = _cache.get(cacheKey);
    if (cached != null) return cached;

    // 1. Provider scope
    var filtered = _documentOps.primaryDocuments.where((doc) {
      if (hasProvider &&
          doc.supplierId != null &&
          doc.supplierId != _providerId) {
        return false;
      }
      return true;
    }).toList();

    // 2. User-facing filter (delegated)
    filtered = _filter.apply(filtered);

    // 3. Search (delegated)
    if (_search.isSearching && _search.currentQuery != null) {
      final query = _search.currentQuery!.toLowerCase();
      filtered = filtered.where((doc) {
        if (doc.documentNumber?.toLowerCase().contains(query) == true) {
          return true;
        }
        if (doc.customerId?.toString().contains(query) == true) return true;
        if (doc.supplierId?.toString().contains(query) == true) return true;
        if (doc.documentType?.toLowerCase().contains(query) == true)
          return true;
        if (doc.paymentStatus?.toLowerCase().contains(query) == true)
          return true;
        return false;
      }).toList();
    }

    _cache.set(cacheKey, filtered);
    _log(
        '_applyFilters',
        'cache miss → filtered ${_documentOps.primaryDocuments.length} → '
            '${filtered.length} key=${_shortKey(cacheKey)}');
    return filtered;
  }

  void _setLoading(bool loading) {
    _log('_setLoading', 'isLoading=$loading');
    _state.setLoading(loading);
    notifyListeners();
  }

  void clearCache() {
    _log('clearCache', 'clearing all state (provider stays $_providerId)');
    _documentOps.clear();
    _grouping.clear();
    _cache.clear();
    _pagination.reset();
    _search.clear();
    _analytics.reset();
    notifyListeners();
  }

  // ==================== DOCUMENT HELPERS ====================

  bool isPrimaryDocument(FinancialDocument doc) =>
      _grouping.isPrimaryDocument(doc);

  List<FinancialDocument>? getRelatedDocuments(int primaryDocumentId) =>
      _grouping.getRelatedDocuments(
          primaryDocumentId, _documentOps.allDocuments);

  // ==================== DEBUG HELPERS ====================

  void dumpState() {
    _log('dumpState', '───── FinanceChangeNotifier state ─────');
    _log(
        'dumpState',
        'provider=$_providerId '
            'loading=${_state.isLoading} refreshing=${_state.isRefreshing}');
    _log(
        'dumpState',
        'docs: all=${_documentOps.allDocuments.length} '
            'primary=${_documentOps.primaryDocuments.length} '
            'groups=${_documentOps.documentGroups.length}');
    _log(
        'dumpState',
        'pagination: page=${_pagination.currentPage} '
            'hasMore=${_pagination.hasMore}');
    _log('dumpState', 'filter: ${_filter.current.toCacheKey()}');
    _log(
        'dumpState',
        'analytics: txn=${_analytics.totalTransactions} '
            'revenue=${_analytics.totalRevenue.toStringAsFixed(2)} '
            'collected=${_analytics.totalCollected.toStringAsFixed(2)} '
            'outstanding=${_analytics.totalOutstanding.toStringAsFixed(2)}');
    _log('dumpState', '──────────────────────────────────────');
  }

  String _shortKey(String key) {
    if (key.length <= 24) return key;
    return '${key.substring(0, 12)}…${key.substring(key.length - 8)}';
  }
}

// ==================== FILTER CLASS (kept for compatibility) ====================

@immutable
class FinanceDocumentFilter {
  final String? documentType;
  final String? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;
  final int? supplierId;
  final int? personId;
  final int? clientId;
  final int? sellerId;
  final int? cartId;
  final int? orderId;
  final int? depositId;
  final int? invoiceId;
  final String? searchQuery;
  final bool? hasAttachments;
  final bool? isPaid;

  const FinanceDocumentFilter({
    this.documentType,
    this.status,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    this.supplierId,
    this.personId,
    this.clientId,
    this.sellerId,
    this.cartId,
    this.orderId,
    this.depositId,
    this.invoiceId,
    this.searchQuery,
    this.hasAttachments,
    this.isPaid,
  });

  FinanceDocumentFilter copyWith({
    String? documentType,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    int? supplierId,
    int? personId,
    int? clientId,
    int? sellerId,
    int? cartId,
    int? orderId,
    int? depositId,
    int? invoiceId,
    String? searchQuery,
    bool? hasAttachments,
    bool? isPaid,
  }) {
    return FinanceDocumentFilter(
      documentType: documentType ?? this.documentType,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      supplierId: supplierId ?? this.supplierId,
      personId: personId ?? this.personId,
      clientId: clientId ?? this.clientId,
      sellerId: sellerId ?? this.sellerId,
      cartId: cartId ?? this.cartId,
      orderId: orderId ?? this.orderId,
      depositId: depositId ?? this.depositId,
      invoiceId: invoiceId ?? this.invoiceId,
      searchQuery: searchQuery ?? this.searchQuery,
      hasAttachments: hasAttachments ?? this.hasAttachments,
      isPaid: isPaid ?? this.isPaid,
    );
  }

  bool get isEmpty =>
      documentType == null &&
      status == null &&
      startDate == null &&
      endDate == null &&
      minAmount == null &&
      maxAmount == null &&
      supplierId == null &&
      personId == null &&
      clientId == null &&
      sellerId == null &&
      cartId == null &&
      orderId == null &&
      depositId == null &&
      invoiceId == null &&
      searchQuery == null &&
      hasAttachments == null &&
      isPaid == null;

  String toCacheKey() {
    return [
      documentType,
      status,
      startDate?.toIso8601String(),
      endDate?.toIso8601String(),
      minAmount,
      maxAmount,
      supplierId,
      personId,
      clientId,
      sellerId,
      cartId,
      orderId,
      depositId,
      invoiceId,
      searchQuery,
      hasAttachments,
      isPaid,
    ].map((v) => v?.toString() ?? '').join('|');
  }
}

// ==================== PAYMENT RESULT ====================

@immutable
class PaymentSubmitResult {
  final bool isSuccess;
  final String message;
  final int? paymentId;

  const PaymentSubmitResult._({
    required this.isSuccess,
    required this.message,
    this.paymentId,
  });

  const PaymentSubmitResult.success(String message, {int? paymentId})
      : this._(isSuccess: true, message: message, paymentId: paymentId);

  const PaymentSubmitResult.failure(String message)
      : this._(isSuccess: false, message: message);
}

// ==================== EXTENSIONS ====================

extension FinancialDocumentExtensions on FinancialDocument {
  bool get isPaid {
    final status = paymentStatus?.toLowerCase() ?? '';
    return status.contains('paid') ||
        status.contains('fully_paid') ||
        status.contains('deposit_fully_covered');
  }

  bool get isUnpaid {
    return !isPaid && paymentStatus?.toLowerCase().contains('unpaid') == true;
  }

  bool get isOverdue {
    if (dueDate == null) return false;
    if (isPaid) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  int get daysOverdue {
    if (!isOverdue || dueDate == null) return 0;
    return DateTime.now().difference(dueDate!).inDays;
  }

  double get remainingAmount {
    return documentAmount - (totalPaid + totalDeposited);
  }

  double get paymentPercentage {
    if (documentAmount == 0) return 0;
    return ((totalPaid + totalDeposited) / documentAmount * 100).clamp(0, 100);
  }
}
