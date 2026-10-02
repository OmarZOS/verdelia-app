// lib/ui/screens/finance/enhanced_invoice_list.dart

import 'package:flutter/material.dart';
import 'package:verdelia_core/business/finance/Customer.dart';
import 'package:verdelia_core/business/finance/FinancialDocument.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:event/finance_change_notifier.dart';
import 'package:event/personnel_notifier.dart';
import 'package:provider_store/components/finance/document/document_details_sheet.dart';
import 'package:ui/components/finance/financial_ui_manager.dart';
import 'package:ui/screens/payment_form_screen.dart';
import 'package:provider/provider.dart';

class EnhancedInvoiceList extends StatefulWidget {
  final FinanceChangeNotifier notifier;

  final int? currentUserId;
  final ValueChanged<FinancialDocument>? onDocumentTap;
  final ValueChanged<FinancialDocument>? onDocumentLongPress;
  final VoidCallback? onCreateDocument;
  final bool showSummary;
  final bool showFilters;
  final bool showSearch;
  final bool enablePagination;

  const EnhancedInvoiceList({
    super.key,
    required this.notifier,
    this.currentUserId,
    this.onDocumentTap,
    this.onDocumentLongPress,
    this.onCreateDocument,
    this.showSummary = true,
    this.showFilters = true,
    this.showSearch = true,
    this.enablePagination = true,
  });

  @override
  State<EnhancedInvoiceList> createState() => _EnhancedInvoiceListState();
}

class _EnhancedInvoiceListState extends State<EnhancedInvoiceList> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isRefreshing = false;

  FinanceChangeNotifier get _notifier => widget.notifier;

  @override
  void initState() {
    super.initState();
    if (widget.enablePagination) {
      _scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_notifier.hasMoreDocuments &&
          !_notifier.isLoading &&
          _notifier.hasProvider) {
        _notifier.fetchDocuments(reset: false);
      }
    }
  }

  Future<void> _refresh() async {
    if (!_notifier.hasProvider) return;
    setState(() => _isRefreshing = true);
    try {
      await _notifier.fetchDocuments(reset: true);
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _notifier,
      builder: (context, child) {
        final notifier = _notifier;
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, notifier),
                if (widget.showSummary && notifier.filteredDocuments.isNotEmpty)
                  _buildSummarySection(context, notifier),
                if (widget.showFilters) _buildFilterSection(context, notifier),
                Expanded(
                  child: notifier.hasProvider
                      ? _buildContent(context, notifier)
                      : _buildNoProviderState(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==================== HEADER ====================

  Widget _buildHeader(BuildContext context, FinanceChangeNotifier notifier) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final docs = notifier.filteredDocuments;
    final canRefresh = notifier.hasProvider && !_isRefreshing;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.financialDocuments,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (docs.isNotEmpty)
                  Text(
                    loc.documentsCount(docs.length),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: canRefresh ? _refresh : null,
            icon: _isRefreshing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: loc.refresh,
          ),
          if (widget.showSearch)
            IconButton(
              onPressed: notifier.hasProvider
                  ? () => _showSearchDialog(context, notifier)
                  : null,
              icon: const Icon(Icons.search),
              tooltip: loc.search,
            ),
          if (widget.onCreateDocument != null)
            IconButton(
              onPressed: notifier.hasProvider ? widget.onCreateDocument : null,
              icon: const Icon(Icons.add),
              tooltip: loc.addDocument,
            ),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context, FinanceChangeNotifier notifier) {
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.searchDocuments),
        content: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: loc.searchByNumberOrCustomer,
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onSubmitted: (value) {
            notifier.setSearchQuery(value);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () {
              notifier.setSearchQuery(_searchController.text);
              Navigator.pop(context);
            },
            child: Text(loc.search),
          ),
        ],
      ),
    );
  }

  // ==================== SUMMARY ====================

  Widget _buildSummarySection(
      BuildContext context, FinanceChangeNotifier notifier) {
    final loc = AppLocalizations.of(context)!;
    final docs = notifier.filteredDocuments;
    final totalAmount = notifier.totalAmount;
    final paidAmount = docs.fold(0.0, (sum, doc) => sum + doc.totalReceived);
    final overdueAmount = docs
            .where((doc) => doc.isOverdue && !doc.isPaid)
            .fold(0.0, (sum, doc) => sum + doc.documentAmount) +
        docs
            .where((doc) => doc.isOverdue && doc.isPartiallyPaid)
            .fold(0.0, (sum, doc) => sum + doc.remainingAmount);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryItem(
                    label: loc.total,
                    value:
                        FinancialUIManager.formatCurrency(totalAmount, context),
                    color: FinancialUIManager.infoColor,
                  ),
                  _SummaryItem(
                    label: loc.paid,
                    value:
                        FinancialUIManager.formatCurrency(paidAmount, context),
                    color: FinancialUIManager.paidColor,
                  ),
                  _SummaryItem(
                    label: loc.overdue,
                    value: FinancialUIManager.formatCurrency(
                        overdueAmount, context),
                    color: FinancialUIManager.unpaidColor,
                  ),
                  _SummaryItem(
                    label: loc.count,
                    value: '${docs.length}',
                    color: FinancialUIManager.pendingColor,
                  ),
                ],
              ),
              if (totalAmount > 0) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: paidAmount / totalAmount,
                  backgroundColor:
                      FinancialUIManager.unpaidColor.withOpacity(0.2),
                  color: FinancialUIManager.paidColor,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ==================== FILTERS ====================

  Widget _buildFilterSection(
      BuildContext context, FinanceChangeNotifier notifier) {
    final loc = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: loc.all,
              selected: notifier.filter.documentType == null &&
                  notifier.filter.status == null,
              onTap: () => notifier.setFilter(const FinanceDocumentFilter()),
            ),
            _FilterChip(
              label: loc.invoices,
              selected: notifier.filter.documentType == 'invoice',
              onTap: () => notifier.setFilter(
                notifier.filter.copyWith(
                  documentType: notifier.filter.documentType == 'invoice'
                      ? null
                      : 'invoice',
                ),
              ),
            ),
            _FilterChip(
              label: loc.unpaid,
              selected: notifier.filter.status == 'unpaid',
              onTap: () => notifier.setFilter(
                notifier.filter.copyWith(
                  status: notifier.filter.status == 'unpaid' ? null : 'unpaid',
                ),
              ),
            ),
            _FilterChip(
              label: loc.overdue,
              selected: notifier.filter.status == 'overdue',
              onTap: () => notifier.setFilter(
                notifier.filter.copyWith(
                  status:
                      notifier.filter.status == 'overdue' ? null : 'overdue',
                ),
              ),
            ),
            if (widget.currentUserId != null)
              _FilterChip(
                label: loc.myDocuments,
                selected: notifier.filter.clientId == widget.currentUserId,
                onTap: () => notifier.setFilter(
                  notifier.filter.copyWith(
                    clientId: notifier.filter.clientId == widget.currentUserId
                        ? null
                        : widget.currentUserId,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==================== CONTENT ====================

  Widget _buildNoProviderState(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.storefront_outlined,
              size: 72,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              loc.selectSupplierFirstText,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              loc.selectSupplierToViewText,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, FinanceChangeNotifier notifier) {
    final loc = AppLocalizations.of(context)!;
    final docs = notifier.filteredDocuments;

    if (notifier.isLoading && docs.isEmpty) {
      return FinancialUIManager.buildLoadingState(
        context: context,
        message: loc.loadingFinancialDocuments,
      );
    }

    if (docs.isEmpty && !notifier.isLoading) {
      return _buildEmptyState(context, notifier);
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: docs.length + (notifier.hasMoreDocuments ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= docs.length) {
            return _buildLoadMoreIndicator(notifier, context);
          }
          final document = docs[index];
          return _DocumentCard(
            document: document,
            notifier: notifier,
            onTap: () {
              if (widget.onDocumentTap != null) {
                widget.onDocumentTap!(document);
              } else {
                _showDocumentDetails(context, document);
              }
            },
            onLongPress: () => widget.onDocumentLongPress?.call(document),
            onDownload: () => _downloadDocument(context, document),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, FinanceChangeNotifier notifier) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final isFiltered = !notifier.filter.isEmpty;
    final hasSearchQuery = notifier.currentSearchQuery != null &&
        notifier.currentSearchQuery!.isNotEmpty;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isFiltered
                      ? Icons.filter_alt_outlined
                      : Icons.receipt_long_outlined,
                  size: 72,
                  color: theme.colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 24),
                Text(
                  isFiltered
                      ? loc.noMatchingDocuments
                      : hasSearchQuery
                          ? loc.noResultsFound
                          : loc.noDocumentsYet,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    isFiltered
                        ? loc.tryAdjustingFilters
                        : hasSearchQuery
                            ? loc.noDocumentsMatch(
                                notifier.currentSearchQuery ?? '',
                              )
                            : loc.startCreatingFirstDocument,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                if (isFiltered)
                  FilledButton.icon(
                    onPressed: () => notifier.clearFilter(),
                    icon: const Icon(Icons.filter_alt_off),
                    label: Text(loc.clearFilters),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadMoreIndicator(
      FinanceChangeNotifier notifier, BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (notifier.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          notifier.hasMoreDocuments ? loc.loadMore : loc.noMoreDocuments,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  void _downloadDocument(BuildContext context, FinancialDocument document) {
    _notifier.downloadDocumentWithProgress(
      document: document,
      context: context,
    );
  }

  void _showDocumentDetails(BuildContext context, FinancialDocument document) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DocumentDetailsSheet(document: document),
    );
  }
}

// ==================== SUMMARY ITEM ====================

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ==================== FILTER CHIP ====================

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        backgroundColor: selected
            ? FinancialUIManager.infoColor.withOpacity(0.1)
            : theme.colorScheme.surfaceVariant.withOpacity(0.1),
        selectedColor: FinancialUIManager.infoColor.withOpacity(0.2),
        checkmarkColor: FinancialUIManager.infoColor,
        labelStyle: TextStyle(
          color: selected
              ? FinancialUIManager.infoColor
              : theme.colorScheme.onSurfaceVariant,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: selected ? FinancialUIManager.infoColor : Colors.transparent,
          ),
        ),
      ),
    );
  }
}

// ==================== DOCUMENT CARD ====================

class _DocumentCard extends StatelessWidget {
  final FinancialDocument document;
  final FinanceChangeNotifier notifier;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback onDownload;

  const _DocumentCard({
    required this.document,
    required this.notifier,
    required this.onTap,
    this.onLongPress,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = document.isOverdue && !document.isPaid;
    final isPartiallyPaid = document.isPartiallyPaid;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: isOverdue ? 4 : (isPartiallyPaid ? 3 : 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isOverdue
                ? FinancialUIManager.unpaidColor.withOpacity(0.3)
                : isPartiallyPaid
                    ? Colors.orange.withOpacity(0.3)
                    : theme.colorScheme.outline.withOpacity(0.1),
            width: isOverdue ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderRow(context),
                const SizedBox(height: 12),
                _buildDueDateIndicator(context),
                const SizedBox(height: 8),
                _buildAmountRow(context),
                const SizedBox(height: 12),
                _buildPaymentProgress(context),
                const SizedBox(height: 12),
                _buildFooterRow(context),
                const SizedBox(height: 12),
                _buildActionsRow(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: FinancialUIManager.getDocumentColor(
                    document.documentType,
                    Theme.of(context),
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  FinancialUIManager.getDocumentIcon(document.documentType),
                  color: FinancialUIManager.getDocumentColor(
                    document.documentType,
                    Theme.of(context),
                  ),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCustomerName(context),
                    const SizedBox(height: 2),
                    _buildDocumentTypeRow(context),
                  ],
                ),
              ),
            ],
          ),
        ),
        FinancialUIManager.buildStatusBadge(
          context: context,
          status: document.paymentStatus,
        ),
      ],
    );
  }

  Widget _buildCustomerName(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    final customerId = document.customerId ?? 0;
    final personId = document.customerPersonId ?? 0;

    if (customerId <= 0 && personId <= 0) {
      return Text(
        _guestLabel(document, loc),
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        overflow: TextOverflow.ellipsis,
      );
    }

    return FutureBuilder<Customer?>(
      future: context.read<PersonnelNotifier>().getCustomerDisplayInfo(
            customerId: customerId,
            customerType: document.customerType,
            personId: personId > 0 ? personId : null,
          ),
      builder: (context, snapshot) {
        final hasCustomer = snapshot.hasData && snapshot.data != null;
        final customerName = hasCustomer
            ? snapshot.data!.displayName
            : loc.customerWithId(customerId);

        return Text(
          customerName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }

  String _guestLabel(FinancialDocument doc, AppLocalizations loc) {
    final cartId = doc.sourceId ?? 0;
    return cartId > 0 ? loc.guestWithId(cartId.toString()) : loc.guestLabel;
  }

  Widget _buildDocumentTypeRow(BuildContext context) {
    final theme = Theme.of(context);
    final documentTypeName =
        FinancialUIManager.getDocumentTypeDisplay(document.documentType);
    final sourceTypeIcon = _getSourceTypeIcon(document.sourceType);
    final sourceTypeColor = _getSourceTypeColor(document.sourceType, theme);

    return Row(
      children: [
        Text(
          documentTypeName,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.secondary,
          ),
        ),
        if (sourceTypeIcon != null) ...[
          const SizedBox(width: 6),
          Icon(sourceTypeIcon, size: 14, color: sourceTypeColor),
        ],
      ],
    );
  }

  IconData? _getSourceTypeIcon(String? sourceType) {
    switch (sourceType) {
      case 'cart_based':
        return Icons.shopping_cart;
      case 'order_based':
        return Icons.receipt;
      case 'invoice_based':
        return Icons.description;
      case 'direct_invoice':
        return Icons.request_quote;
      default:
        return null;
    }
  }

  Color _getSourceTypeColor(String? sourceType, ThemeData theme) {
    switch (sourceType) {
      case 'cart_based':
        return Colors.purple;
      case 'order_based':
        return Colors.teal;
      case 'invoice_based':
        return Colors.indigo;
      case 'direct_invoice':
        return Colors.deepOrange;
      default:
        return theme.colorScheme.secondary;
    }
  }

  Widget _buildDueDateIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    if (document.dueDate == null) return const SizedBox.shrink();
    if (document.isPaid) return const SizedBox.shrink();

    if (document.isCanceled) {
      return Row(
        children: [
          const Icon(
            Icons.cancel,
            size: 14,
            color: FinancialUIManager.canceledColor,
          ),
          const SizedBox(width: 6),
          Text(
            loc.canceled,
            style: theme.textTheme.bodySmall?.copyWith(
              color: FinancialUIManager.canceledColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    final isPastDue = document.isOverdue;
    final daysUntilDue = document.daysUntilDue;

    Color color;
    String label;
    IconData icon = Icons.schedule;

    if (isPastDue) {
      color = FinancialUIManager.unpaidColor;
      label = loc.overdue;
      icon = Icons.warning;
    } else if (daysUntilDue <= 7) {
      color = Colors.orange;
      label = loc.dueSoon;
      icon = Icons.notification_important;
    } else {
      color = Colors.green;
      label = loc.onTrack;
      icon = Icons.schedule;
    }

    if (document.isPartiallyPaid && isPastDue) {
      color = Colors.orange.shade700;
      label = loc.partialOverdue;
    } else if (document.isPartiallyPaid && !isPastDue) {
      color = Colors.teal;
      label = loc.partiallyPaid;
    }

    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAmountRow(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final isPaid = document.isPaid;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.amount,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              FinancialUIManager.formatCurrency(
                  document.documentAmount, context),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              isPaid ? loc.paid : loc.balance,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isPaid
                  ? FinancialUIManager.formatCurrency(
                      document.totalReceived, context)
                  : FinancialUIManager.formatCurrency(
                      document.remainingAmount, context),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isPaid
                    ? FinancialUIManager.paidColor
                    : (document.remainingAmount > 0
                        ? FinancialUIManager.unpaidColor
                        : FinancialUIManager.paidColor),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentProgress(BuildContext context) {
    final totalAmount = document.documentAmount;
    final totalReceived = document.totalReceived;
    final paymentPercentage =
        totalAmount > 0 ? (totalReceived / totalAmount) : 0.0;
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(paymentPercentage * 100).toStringAsFixed(0)}% '
              '${_getPaymentStatusLabel(loc)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _getPaymentStatusColor(),
              ),
            ),
            Text(
              FinancialUIManager.formatCurrency(totalReceived, context),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: paymentPercentage.clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade200,
            color: _getPaymentStatusColor(),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  String _getPaymentStatusLabel(AppLocalizations loc) {
    if (document.isPaid) return loc.paid;
    if (document.isPartiallyPaid) return loc.partial;
    if (document.isOverdue) return loc.overdue;
    return loc.unpaid;
  }

  Color _getPaymentStatusColor() {
    if (document.isPaid) return FinancialUIManager.paidColor;
    if (document.isPartiallyPaid) return Colors.orange;
    if (document.isOverdue) return FinancialUIManager.unpaidColor;
    return FinancialUIManager.pendingColor;
  }

  Widget _buildFooterRow(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final isOverdue = document.isOverdue && !document.isPaid;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 16,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(width: 6),
            Text(
              FinancialUIManager.formatDate(document.issueDate),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(width: 12),
            if (document.documentNumber.isNotEmpty)
              Row(
                children: [
                  Icon(
                    Icons.receipt,
                    size: 14,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    document.documentNumber,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
          ],
        ),
        if (isOverdue)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: FinancialUIManager.unpaidColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning,
                  size: 12,
                  color: FinancialUIManager.unpaidColor,
                ),
                const SizedBox(width: 4),
                Text(
                  loc.overdueDays(document.daysOverdue),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: FinancialUIManager.unpaidColor,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildActionsRow(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final isPaid = document.isPaid;
    final isPartiallyPaid = document.isPartiallyPaid;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onDownload,
            icon: Icon(
              Icons.download,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            label: Text(
              loc.download,
              style: TextStyle(color: theme.colorScheme.primary),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        if (!isPaid && !document.isCanceled) ...[
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentFormScreen(
                      amountDue: document.remainingAmount,
                      onSubmit: (amount, method, notes) async {
                        final result = await notifier.submitPayment(
                          invoiceId: document.documentId,
                          amount: amount,
                          method: method,
                          notes: notes,
                        );
                        return result.isSuccess ? null : result.message;
                      },
                    ),
                  ),
                );
              },
              icon: Icon(
                Icons.payment,
                size: 16,
                color: theme.colorScheme.onPrimary,
              ),
              label: Text(
                isPartiallyPaid ? loc.payRemaining : loc.payNow,
                style: TextStyle(color: theme.colorScheme.onPrimary),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                backgroundColor: isPartiallyPaid
                    ? Colors.orange
                    : FinancialUIManager.infoColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
