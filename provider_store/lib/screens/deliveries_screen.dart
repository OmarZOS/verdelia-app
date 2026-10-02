import 'package:flutter/material.dart';
import 'package:provider_store/components/delivery/DeliveryListView.dart';
import 'package:provider_store/components/delivery/DeliveryDetailsSheet.dart';
import 'package:provider/provider.dart';
import 'package:event/delivery_change_notifier.dart';
import 'package:verdelia_core/business/Delivery.dart';
import 'package:ui/components/store/StoreDashboardHeader.dart';

// ============================================================================
// DELIVERY TABBED VIEW
// ============================================================================
//
// The strip enumerates every state the delivery state machine can
// produce. Grouped into three phases so the operator's mental model
// matches the workflow:
//
//   Active   — pre-shipment: pending, processing, confirmed
//   In flight — moving: shipped, in transit, out for delivery
//   Closed   — terminal: delivered, failed, cancelled, returned, refunded
//
// Each phase is a top-level tab. Under each tab, the individual states
// are chips with their own counts, so an operator can see at a glance
// where the work is sitting.

class DeliveryTabbedView extends StatefulWidget {
  final DeliveryChangeNotifier? notifier;
  final int selectedSupplierId;
  final bool isLoading;
  final VoidCallback? onRefresh;
  final Function(String)? onSearch;

  const DeliveryTabbedView({
    super.key,
    this.notifier,
    this.selectedSupplierId = 0,
    this.isLoading = false,
    this.onRefresh,
    this.onSearch,
  });

  @override
  State<DeliveryTabbedView> createState() => _DeliveryTabbedViewState();
}

/// A phase groups related delivery statuses under one top-level tab.
enum _Phase {
  active,
  inFlight,
  closed;

  String get label {
    switch (this) {
      case _Phase.active:
        return 'Active';
      case _Phase.inFlight:
        return 'In flight';
      case _Phase.closed:
        return 'Closed';
    }
  }

  IconData get icon {
    switch (this) {
      case _Phase.active:
        return Icons.schedule_rounded;
      case _Phase.inFlight:
        return Icons.local_shipping_rounded;
      case _Phase.closed:
        return Icons.inventory_2_rounded;
    }
  }

  /// The statuses that belong to this phase, in lifecycle order.
  List<DeliveryStatus> get statuses {
    switch (this) {
      case _Phase.active:
        return const [
          DeliveryStatus.pending,
          DeliveryStatus.processing,
          DeliveryStatus.confirmed,
        ];
      case _Phase.inFlight:
        return const [
          DeliveryStatus.shipped,
          DeliveryStatus.inTransit,
          DeliveryStatus.outForDelivery,
        ];
      case _Phase.closed:
        return const [
          DeliveryStatus.delivered,
          DeliveryStatus.failed,
          DeliveryStatus.cancelled,
          DeliveryStatus.returned,
          DeliveryStatus.refunded,
        ];
    }
  }
}

class _DeliveryTabbedViewState extends State<DeliveryTabbedView>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  bool _showSearch = false;
  bool _showFilters = false;
  bool _isRefreshing = false;
  bool _initialized = false;

  /// Which status is currently selected inside the active phase.
  /// Null means "all statuses in the phase".
  DeliveryStatus? _activeStatusFilter;

  late DeliveryChangeNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _notifier = widget.notifier ?? context.read<DeliveryChangeNotifier>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.notifier == null) {
      _notifier = context.read<DeliveryChangeNotifier>();
    }
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _loadDeliveriesForCurrentSupplier());
    }
  }

  @override
  void didUpdateWidget(covariant DeliveryTabbedView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedSupplierId != widget.selectedSupplierId) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _loadDeliveriesForCurrentSupplier());
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!mounted) return;
    // Clear the per-status chip when the phase changes; the previous
    // selection may not exist under the new phase.
    setState(() => _activeStatusFilter = null);
  }

  void _loadDeliveriesForCurrentSupplier() {
    final supplierId = widget.selectedSupplierId > 0
        ? widget.selectedSupplierId
        : _notifier.currentProviderId;

    if (supplierId > 0) {
      _notifier.fetchDeliveries(providerId: supplierId, reset: true);
      return;
    }
    if (_notifier.deliveries.isEmpty) {
      _notifier.fetchFirstPage();
    }
  }

  _Phase get _currentPhase => _Phase.values[_tabController.index];

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme, cs),
            _buildPhaseStrip(theme, cs),
            _buildStatusChips(theme, cs),
            if (_showFilters) _buildFilterRow(theme, cs),
            const SizedBox(height: 4),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  // ==================== HEADER ====================

  Widget _buildHeader(ThemeData theme, ColorScheme cs) {
    final busy = _isRefreshing || _notifier.isLoading;

    return DashboardHeader(
      leadingIcon: Icons.local_shipping_rounded,
      title: 'Deliveries',
      subtitle: _subtitleForCurrentPhase(),
      actions: [
        _headerAction(
          icon: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded),
          onPressed: busy ? null : _refreshData,
          tooltip: 'Refresh',
        ),
        _headerAction(
          icon: Icon(
            _showFilters ? Icons.filter_alt_rounded : Icons.filter_alt_outlined,
            size: 22,
            color: _showFilters ? cs.primary : null,
          ),
          onPressed: _toggleFilters,
          tooltip: 'Filters',
        ),
        _headerAction(
          icon: Icon(
            _showSearch ? Icons.search_off_rounded : Icons.search_rounded,
            size: 22,
            color: _showSearch ? cs.primary : null,
          ),
          onPressed: _toggleSearch,
          tooltip: _showSearch ? 'Close search' : 'Search',
        ),
      ],
      searchBar: _showSearch ? _buildSearchBar(theme, cs) : null,
    );
  }

  Widget _headerAction({
    required Widget icon,
    VoidCallback? onPressed,
    String? tooltip,
  }) {
    return IconButton(
      icon: icon,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      tooltip: tooltip,
      splashRadius: 22,
    );
  }

  String _subtitleForCurrentPhase() {
    final phase = _currentPhase;
    final count = _phaseCount(phase);
    return '$count ${phase.label.toLowerCase()}';
  }

  int _phaseCount(_Phase phase) {
    return phase.statuses.fold<int>(
      0,
      (sum, status) => sum + _countForStatus(status),
    );
  }

  // ==================== PHASE STRIP ====================

  Widget _buildPhaseStrip(ThemeData theme, ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: cs.primary,
          boxShadow: [
            BoxShadow(
              color: cs.primary.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: EdgeInsets.zero,
        dividerColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        labelColor: cs.onPrimary,
        unselectedLabelColor: cs.onSurfaceVariant,
        labelStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        tabs: _Phase.values.map((phase) {
          return Tab(
            height: 40,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(phase.icon, size: 15),
                const SizedBox(width: 6),
                Text(phase.label),
                const SizedBox(width: 6),
                _CountBubble(count: _phaseCount(phase)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==================== STATUS CHIPS ====================

  /// The chips below the phase strip. Each represents a specific
  /// status within the current phase, with its own count. Tapping a
  /// chip filters the list to that status. Tapping the leading "All"
  /// chip clears the filter.
  Widget _buildStatusChips(ThemeData theme, ColorScheme cs) {
    final phase = _currentPhase;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _statusChip(
              label: 'All',
              count: _phaseCount(phase),
              selected: _activeStatusFilter == null,
              onTap: () => setState(() => _activeStatusFilter = null),
            ),
            const SizedBox(width: 8),
            for (final status in phase.statuses) ...[
              _statusChip(
                label: _statusLabel(status),
                count: _countForStatus(status),
                selected: _activeStatusFilter == status,
                onTap: () => setState(() => _activeStatusFilter = status),
                color: _statusColor(status, cs),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusChip({
    required String label,
    required int count,
    required bool selected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final cs = Theme.of(context).colorScheme;
    final accent = color ?? cs.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? accent.withOpacity(0.12)
                : cs.surfaceContainerHighest.withOpacity(0.35),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? accent.withOpacity(0.55)
                  : cs.outlineVariant.withOpacity(0.4),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? accent : cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 6),
              _InlineCount(count: count, active: selected, accent: accent),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== SEARCH ====================

  Widget _buildSearchBar(ThemeData theme, ColorScheme cs) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        autofocus: true,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, size: 20),
          hintText: 'Search by ID, customer, address…',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    widget.onSearch?.call('');
                    setState(() {});
                  },
                )
              : null,
        ),
        onChanged: (value) {
          widget.onSearch?.call(value);
          setState(() {});
        },
        style: theme.textTheme.bodyMedium,
      ),
    );
  }

  // ==================== FILTERS ====================

  Widget _buildFilterRow(ThemeData theme, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _filterChip(
              icon: Icons.today_rounded,
              label: 'Due today',
              onTap: () => _applyQuickFilter('today'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _filterChip(
              icon: Icons.warning_amber_rounded,
              label: 'Delayed',
              onTap: () => _applyQuickFilter('delayed'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _filterChip(
              icon: Icons.priority_high_rounded,
              label: 'Unassigned',
              onTap: () => _applyQuickFilter('unassigned'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        side: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
      ),
    );
  }

  void _applyQuickFilter(String key) {
    // The notifier doesn't yet expose date-range filters; wire them
    // here when it does, or send them through `onSearch` if the
    // backend supports query fragments.
    debugPrint('Quick filter → $key');
  }

  // ==================== CONTENT ====================

  Widget _buildContent() {
    return TabBarView(
      controller: _tabController,
      children: _Phase.values.map(_buildPhaseContent).toList(),
    );
  }

  Widget _buildPhaseContent(_Phase phase) {
    // When a specific status is selected, we filter to that status.
    // Otherwise we ask the list view for the whole phase, which is
    // the set of statuses in `phase.statuses`.
    final statuses =
        _activeStatusFilter != null ? [_activeStatusFilter!] : phase.statuses;

    final emptyTitle = _emptyTitleFor(phase);
    final emptyMessage = _emptyMessageFor(phase);

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: DeliveryListView(
        notifier: _notifier,
        statuses: statuses,
        emptyTitle: emptyTitle,
        emptyMessage: emptyMessage,
      ),
    );
  }

  String _emptyTitleFor(_Phase phase) {
    switch (phase) {
      case _Phase.active:
        return 'No active deliveries';
      case _Phase.inFlight:
        return 'Nothing is moving right now';
      case _Phase.closed:
        return 'No closed deliveries';
    }
  }

  String _emptyMessageFor(_Phase phase) {
    switch (phase) {
      case _Phase.active:
        return 'Deliveries that are pending, processing, or confirmed '
            'will appear here.';
      case _Phase.inFlight:
        return 'Deliveries that are shipped, in transit, or out for '
            'delivery will appear here.';
      case _Phase.closed:
        return 'Delivered, failed, cancelled, returned, or refunded '
            'deliveries will appear here.';
    }
  }

  // ==================== COUNT HELPERS ====================

  int _countForStatus(DeliveryStatus status) {
    // `_notifier.deliveries` is whatever the last fetch loaded. If the
    // backend returns per-status counts, prefer those. Otherwise this
    // is a client-side rollup of the current page.
    return _notifier.deliveries
        .where((d) => d.delivery_status == status)
        .length;
  }

  String _statusLabel(DeliveryStatus status) {
    // Uses the enum's `label` getter as the source of truth. If you
    // want localized labels, wire them through `AppLocalizations` here.
    switch (status) {
      case DeliveryStatus.pending:
        return 'Pending';
      case DeliveryStatus.processing:
        return 'Processing';
      case DeliveryStatus.confirmed:
        return 'Confirmed';
      case DeliveryStatus.shipped:
        return 'Shipped';
      case DeliveryStatus.inTransit:
        return 'In transit';
      case DeliveryStatus.outForDelivery:
        return 'Out for delivery';
      case DeliveryStatus.delivered:
        return 'Delivered';
      case DeliveryStatus.failed:
        return 'Failed';
      case DeliveryStatus.cancelled:
        return 'Cancelled';
      case DeliveryStatus.returned:
        return 'Returned';
      case DeliveryStatus.refunded:
        return 'Refunded';
    }
  }

  Color _statusColor(DeliveryStatus status, ColorScheme cs) {
    switch (status) {
      case DeliveryStatus.pending:
        return const Color(0xFFF59E0B);
      case DeliveryStatus.processing:
        return const Color(0xFF3B82F6);
      case DeliveryStatus.confirmed:
        return const Color(0xFF0EA5E9);
      case DeliveryStatus.shipped:
        return const Color(0xFF8B5CF6);
      case DeliveryStatus.inTransit:
        return const Color(0xFF8B5CF6);
      case DeliveryStatus.outForDelivery:
        return const Color(0xFFF97316);
      case DeliveryStatus.delivered:
        return const Color(0xFF10B981);
      case DeliveryStatus.failed:
        return const Color(0xFFEF4444);
      case DeliveryStatus.cancelled:
        return const Color(0xFF6B7280);
      case DeliveryStatus.returned:
        return const Color(0xFFF59E0B);
      case DeliveryStatus.refunded:
        return const Color(0xFF06B6D4);
    }
  }

  // ==================== FAB + ACTIONS ====================

  bool _shouldShowFab() {
    // New deliveries only make sense on the Active phase. You can't
    // create one that's already shipped or delivered.
    return _currentPhase == _Phase.active;
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    try {
      final supplierId = widget.selectedSupplierId > 0
          ? widget.selectedSupplierId
          : _notifier.currentProviderId;

      if (supplierId > 0) {
        await _notifier.fetchDeliveries(providerId: supplierId, reset: true);
      } else if (widget.onRefresh != null) {
        widget.onRefresh!();
      } else {
        await _notifier.refreshDeliveries();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Refresh failed: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (_showSearch) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _searchFocusNode.requestFocus();
        });
      } else {
        _searchController.clear();
        widget.onSearch?.call('');
      }
    });
  }

  void _toggleFilters() {
    setState(() => _showFilters = !_showFilters);
  }
}

// ============================================================================
// COUNT BUBBLES
// ============================================================================

/// Big animated count bubble used inside the phase strip.
class _CountBubble extends StatelessWidget {
  final int count;

  const _CountBubble({required this.count});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.7, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          ),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: Container(
        key: ValueKey(count),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        constraints: const BoxConstraints(minWidth: 18),
        decoration: BoxDecoration(
          color: cs.onSurface.withOpacity(0.10),
          borderRadius: BorderRadius.circular(9),
        ),
        alignment: Alignment.center,
        child: Text(
          count > 99 ? '99+' : '$count',
          style: TextStyle(
            fontSize: 11,
            height: 1.2,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
      ),
    );
  }
}

/// Small inline count used inside the per-status chips.
class _InlineCount extends StatelessWidget {
  final int count;
  final bool active;
  final Color accent;

  const _InlineCount({
    required this.count,
    required this.active,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      constraints: const BoxConstraints(minWidth: 18),
      decoration: BoxDecoration(
        color:
            active ? accent.withOpacity(0.18) : cs.onSurface.withOpacity(0.08),
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: TextStyle(
          fontSize: 11,
          height: 1.2,
          fontWeight: FontWeight.w700,
          color: active ? accent : cs.onSurfaceVariant,
        ),
      ),
    );
  }
}
