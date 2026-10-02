// lib/screens/business_operations_screen.dart

import 'package:event/views/business_ops_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/business/finance/BusinessOperation.dart';
import 'package:verdelia_core/business/services/BusinessOperationService.dart';
import 'package:locator/locator.dart';

import 'package:provider_store/components/operations/business_operations_filters.dart';
import 'package:provider_store/components/operations/business_operations_header.dart';
import 'package:provider_store/components/operations/business_operations_list.dart';
import 'package:provider_store/components/operations/business_operations_stats.dart';
import 'package:provider_store/screens/business_operation_details_screen.dart';

class BusinessOperationsScreen extends StatefulWidget {
  /// Optional: lock the screen to a single supplier.
  /// Pass 0 (or omit) to show all suppliers the current user can see.
  final int supplierId;

  /// Optional initial date range.
  final DateTime? initialDateFrom;
  final DateTime? initialDateTo;

  /// If true, hide the supplier filter and stats-by-supplier bucket.
  final bool lockToSupplier;

  const BusinessOperationsScreen({
    super.key,
    this.supplierId = 0,
    this.initialDateFrom,
    this.initialDateTo,
    this.lockToSupplier = false,
  });

  @override
  State<BusinessOperationsScreen> createState() =>
      _BusinessOperationsScreenState();
}

class _BusinessOperationsScreenState extends State<BusinessOperationsScreen> {
  late final BusinessOperationNotifier _notifier;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Pull the service from the locator, not from a provider above this
    // widget. Using context.read here would fail because initState runs
    // before the widget is attached to the tree in a way that provider
    // can resolve.
    _notifier = BusinessOperationNotifier(
      service: AppLocator.get<BusinessOperationService>(),
      defaultPageSize: 50,
    );

    // Apply the initial filters, then load. Use a post-frame callback so
    // the widget is fully mounted before we start touching state.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      if (widget.supplierId > 0) {
        await _notifier.setSupplierId(widget.supplierId);
      }

      if (widget.initialDateFrom != null || widget.initialDateTo != null) {
        await _notifier.setDateRange(
          widget.initialDateFrom,
          widget.initialDateTo,
        );
      }

      // If neither filter setter triggered a load, load now.
      if (widget.supplierId == 0 && widget.initialDateFrom == null) {
        await _notifier.load();
      }
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _notifier.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      _notifier.nextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BusinessOperationNotifier>.value(
      value: _notifier,
      child: Consumer<BusinessOperationNotifier>(
        builder: (context, notifier, _) {
          return Scaffold(
            body: RefreshIndicator(
              onRefresh: notifier.refresh,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Header
                  const SliverToBoxAdapter(
                    child: BusinessOperationsHeader(),
                  ),

                  // KPI strip from stats.totals
                  if (notifier.totals != null)
                    SliverToBoxAdapter(
                      child: _KpiStrip(
                        totals: notifier.totals!,
                        ratios: notifier.ratios,
                        counts: notifier.counts,
                      ),
                    ),

                  // Filters
                  const SliverToBoxAdapter(
                    child: BusinessOperationsFilters(),
                  ),

                  // Time window banner
                  if (notifier.window.dateFrom != null ||
                      notifier.window.dateTo != null)
                    SliverToBoxAdapter(
                      child: _TimeWindowBanner(window: notifier.window),
                    ),

                  // Initial loading
                  if (notifier.isLoading && !notifier.hasOperations)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),

                  // Error
                  if (notifier.hasError)
                    SliverToBoxAdapter(
                      child: _ErrorState(
                        error: notifier.error,
                        onRetry: notifier.load,
                      ),
                    ),

                  // Stats summary
                  if (notifier.hasOperations && notifier.stats != null)
                    SliverToBoxAdapter(
                      child: BusinessOperationsStats(
                        stats: notifier.stats,
                        operations: notifier.operations,
                      ),
                    ),

                  // Operations list
                  if (notifier.hasOperations)
                    BusinessOperationsList(
                      operations: notifier.operations,
                      isLoadingMore: notifier.isLoading && notifier.page > 0,
                      hasMore: notifier.hasNextPage,
                      onLoadMore: notifier.nextPage,
                      onTapOperation: (op) =>
                          _openDetails(context, op, notifier),
                    ),

                  // Pagination footer
                  if (notifier.hasOperations)
                    SliverToBoxAdapter(
                      child: _PaginationFooter(
                        page: notifier.page,
                        pagination: notifier.pagination,
                        hasNext: notifier.hasNextPage,
                        hasPrev: notifier.hasPreviousPage,
                        isBusy: notifier.isBusy,
                        onPrev: notifier.previousPage,
                        onNext: notifier.nextPage,
                      ),
                    ),

                  // Empty state
                  if (notifier.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(onRetry: notifier.refresh),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openDetails(
    BuildContext context,
    BusinessOperation operation,
    BusinessOperationNotifier notifier,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OperationDetailsScreen(operation: operation),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// KPI strip
// ---------------------------------------------------------------------------

class _KpiStrip extends StatelessWidget {
  final BusinessOperationsTotals totals;
  final BusinessOperationsRatios? ratios;
  final BusinessOperationsCounts? counts;

  const _KpiStrip({
    required this.totals,
    this.ratios,
    this.counts,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _Kpi(
                  label: 'Revenue',
                  value: totals.grandTotal,
                  color: cs.primary,
                ),
                _Kpi(
                  label: 'Margin',
                  value: totals.marginAmount,
                  color: totals.marginAmount >= 0 ? Colors.green : cs.error,
                ),
                _Kpi(
                  label: 'Due',
                  value: totals.dueAmount,
                  color: totals.dueAmount > 0 ? Colors.orange : Colors.green,
                ),
                _Kpi(
                  label: 'Paid',
                  value: totals.paidAmount,
                  color: Colors.teal,
                ),
                if (ratios?.overallRoi != null)
                  _Kpi(
                    label: 'ROI',
                    value: ratios!.overallRoi!,
                    color: ratios!.overallRoi! >= 0 ? Colors.green : cs.error,
                    isRatio: true,
                  ),
                _Kpi(
                  label: 'Avg Ticket',
                  value: ratios?.averageTicket ?? 0,
                  color: cs.primary,
                ),
              ],
            ),
          ),
          if (counts != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${counts!.operations} operations',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${counts!.carts} carts · '
                  '${counts!.deliveries} deliveries',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool isRatio;

  const _Kpi({
    required this.label,
    required this.value,
    required this.color,
    this.isRatio = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final display = isRatio
        ? '${(value * 100).toStringAsFixed(1)}%'
        : value.toStringAsFixed(2);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            display,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Time window banner
// ---------------------------------------------------------------------------

class _TimeWindowBanner extends StatelessWidget {
  final BusinessOperationsWindow window;
  const _TimeWindowBanner({required this.window});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    String fmt(DateTime? d) => d == null
        ? '—'
        : '${d.year}-${d.month.toString().padLeft(2, '0')}-'
            '${d.day.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        children: [
          Icon(Icons.date_range, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            '${fmt(window.dateFrom)} → ${fmt(window.dateTo)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pagination footer
// ---------------------------------------------------------------------------

class _PaginationFooter extends StatelessWidget {
  final int page;
  final BusinessOperationsPagination pagination;
  final bool hasNext;
  final bool hasPrev;
  final bool isBusy;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _PaginationFooter({
    required this.page,
    required this.pagination,
    required this.hasNext,
    required this.hasPrev,
    required this.isBusy,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: hasPrev && !isBusy ? onPrev : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Previous'),
          ),
          Column(
            children: [
              Text(
                'Page ${page + 1}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              Text(
                '${pagination.offset + pagination.returned} of '
                '${pagination.totalInWindow}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: hasNext && !isBusy ? onNext : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Next'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error / empty states
// ---------------------------------------------------------------------------

class _ErrorState extends StatelessWidget {
  final Object? error;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 56, color: cs.error),
          const SizedBox(height: 16),
          Text(
            'Failed to load operations',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => onRetry(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback? onRetry;
  const _EmptyState({this.onRetry});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assessment_outlined,
              size: 80,
              color: cs.onSurfaceVariant.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              loc.noBusinessOperations,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                loc.generateOperationsToSeeData,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            if (onRetry != null)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(loc.retry),
              ),
          ],
        ),
      ),
    );
  }
}
