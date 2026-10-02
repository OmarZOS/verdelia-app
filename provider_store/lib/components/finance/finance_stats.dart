import 'package:event/views/finance_view_model.dart';
import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/business/finance/BusinessOperation.dart';
import 'package:event/finance_change_notifier.dart';
import 'package:provider/provider.dart';

class FinanceStats extends StatelessWidget {
  final VoidCallback? onCreateInvoice;
  final VoidCallback? onViewAllTransactions;

  const FinanceStats({
    super.key,
    this.onCreateInvoice,
    this.onViewAllTransactions,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceChangeNotifier>(
      builder: (context, notifier, child) {
        if (!notifier.hasProvider) {
          return _buildNoProviderState(context);
        }

        final operations = notifier.businessOperations;
        final analytics = notifier.analyticsCache;

        if (operations.isEmpty || analytics == null) {
          return _buildEmptyState(context, notifier);
        }

        return _buildContent(context, notifier, analytics);
      },
    );
  }

  // ==================== STATES ====================

  Widget _buildNoProviderState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
              size: 64,
              color: colorScheme.onSurfaceVariant.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              loc.selectSupplierFirstText,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                loc.selectSupplierToViewText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, FinanceChangeNotifier notifier) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              loc.noAnalyticsData,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                loc.generateInvoicesToSeeAnalytics,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            if (notifier.isLoading)
              const CircularProgressIndicator()
            else
              FilledButton.icon(
                onPressed: () => notifier.refreshBusinessOperations(),
                icon: Icon(
                  Icons.refresh,
                  color: colorScheme.onPrimary,
                ),
                label: Text(
                  loc.loadAnalyticsData,
                  style: TextStyle(color: colorScheme.onPrimary),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    FinanceChangeNotifier notifier,
    AnalyticsCache analytics,
  ) {
    final loc = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSummaryCard(context, analytics, loc),
          const SizedBox(height: 16),
          _buildStatsGrid(context, analytics, loc),
          const SizedBox(height: 16),
          _buildRecentTransactions(context, notifier, loc),
        ],
      ),
    );
  }

  // ==================== SUMMARY CARD ====================

  Widget _buildSummaryCard(
    BuildContext context,
    AnalyticsCache analytics,
    AppLocalizations loc,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: colorScheme.onPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                loc.financialOverview,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _formatCurrency(analytics.totalRevenue, loc),
            style: theme.textTheme.headlineLarge?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            loc.totalRevenue,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimary.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMiniStat(
                label: loc.collectionRate,
                value: '${analytics.collectionRate.toStringAsFixed(1)}%',
                color: colorScheme.onPrimary,
              ),
              const SizedBox(width: 16),
              _buildMiniStat(
                label: loc.totalTransactions,
                value: '${analytics.transactionCount}',
                color: colorScheme.onPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== STATS GRID ====================

  Widget _buildStatsGrid(
    BuildContext context,
    AnalyticsCache analytics,
    AppLocalizations loc,
  ) {
    final averageTransaction = analytics.transactionCount > 0
        ? analytics.totalRevenue / analytics.transactionCount
        : 0.0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          context,
          title: loc.totalCollected,
          value: _formatCurrency(analytics.totalCollected, loc),
          icon: Icons.money,
          color: Colors.green,
        ),
        _buildStatCard(
          context,
          title: loc.totalOutstanding,
          value: _formatCurrency(analytics.totalOutstanding, loc),
          icon: Icons.pending_actions,
          color: Colors.orange,
        ),
        _buildStatCard(
          context,
          title: loc.averageTransaction,
          value: _formatCurrency(averageTransaction, loc),
          icon: Icons.analytics,
          color: Theme.of(context).colorScheme.tertiary,
        ),
        _buildStatCard(
          context,
          title: loc.transactions,
          value: '${analytics.transactionCount}',
          icon: Icons.receipt,
          color: Theme.of(context).colorScheme.inversePrimary,
        ),
      ],
    );
  }

  // ==================== RECENT TRANSACTIONS ====================

  Widget _buildRecentTransactions(
    BuildContext context,
    FinanceChangeNotifier notifier,
    AppLocalizations loc,
  ) {
    final recentOperations = notifier.recentOperations;
    if (recentOperations.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                loc.recentTransactions,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                '${loc.last} ${recentOperations.length}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: recentOperations
                .map((operation) => _buildOperationRow(context, operation, loc))
                .toList(),
          ),
          const SizedBox(height: 12),
          if (notifier.businessOperations.length > 10)
            Center(
              child: TextButton(
                onPressed: onViewAllTransactions,
                child: Text(
                  loc.viewAllTransactions,
                  style: TextStyle(color: colorScheme.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOperationRow(
    BuildContext context,
    BusinessOperation operation,
    AppLocalizations loc,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final isPaid = operation.balanceDue <= 0;
    final sourceName = operation.sourceTable;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPaid
            ? colorScheme.primary.withOpacity(0.05)
            : colorScheme.secondary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isPaid
                  ? colorScheme.primary.withOpacity(0.1)
                  : colorScheme.tertiary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPaid ? Icons.check_circle : Icons.pending,
              size: 16,
              color: isPaid ? colorScheme.primary : colorScheme.tertiary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$sourceName #${operation.cartId}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${loc.supplier}: ${operation.supplierId ?? '—'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                loc.price(operation.totalAmount.toStringAsFixed(2)),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                operation.paymentStatus,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isPaid ? colorScheme.primary : colorScheme.tertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== REUSABLE PIECES ====================

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.9),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double amount, AppLocalizations loc) {
    return loc.price(amount.toStringAsFixed(2));
  }
}
