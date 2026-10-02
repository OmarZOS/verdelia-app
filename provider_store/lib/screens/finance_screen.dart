import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:event/finance_change_notifier.dart';
import 'package:provider_store/components/finance/invoice_list.dart';
import 'package:provider_store/components/finance/finance_filters.dart';

class FinanceScreen extends StatelessWidget {
  /// The notifier that owns the provider scope, documents, filters, and
  /// analytics for the finance screen.
  ///
  /// Passed in by the caller — the screen does not look it up from the
  /// widget tree. The caller is expected to wrap this widget in a
  /// `Consumer<FinanceChangeNotifier>` (or `context.watch`) so the screen
  /// rebuilds when the notifier notifies.
  final FinanceChangeNotifier financeNotifier;

  const FinanceScreen({
    super.key,
    required this.financeNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _AppBar(
            notifier: financeNotifier,
          ),
          Expanded(
            child: EnhancedInvoiceList(
              notifier: financeNotifier,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== APP BAR ====================

class _AppBar extends StatelessWidget {
  final FinanceChangeNotifier notifier;

  const _AppBar({required this.notifier});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;
    final hasProvider = notifier.hasProvider;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          _IconBadge(
            icon: Icons.currency_exchange,
            colorScheme: colorScheme,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.financeAndPricing,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  loc.manageInvoicesAndConfigurePricing,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          _ExportButton(
            onPressed: hasProvider ? () => _handleExport(context) : null,
            colorScheme: colorScheme,
            tooltip: loc.exportData,
          ),
        ],
      ),
    );
  }

  void _handleExport(BuildContext context) {
    // notifier.exportAnalyticsData();

    final loc = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc?.exportingData ?? 'Exporting...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ==================== ICON BADGE ====================

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final ColorScheme colorScheme;

  const _IconBadge({
    required this.icon,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primaryContainer],
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: colorScheme.onPrimary, size: 22),
    );
  }
}

// ==================== EXPORT BUTTON ====================

class _ExportButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final ColorScheme colorScheme;
  final String tooltip;

  const _ExportButton({
    required this.onPressed,
    required this.colorScheme,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(Icons.download, color: colorScheme.primary),
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: colorScheme.primary.withOpacity(0.1),
        padding: const EdgeInsets.all(10),
      ),
    );
  }
}
