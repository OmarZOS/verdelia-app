import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/business/finance/BusinessOperation.dart';
import 'package:ui/components/finance/financial_ui_manager.dart';
import 'operation_items_list.dart';
import 'operation_summary.dart';

class OperationBody extends StatelessWidget {
  final BusinessOperation operation;

  const OperationBody({required this.operation});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary
        Padding(
          padding: const EdgeInsets.all(20),
          child: OperationSummary(operation: operation),
        ),

        // Section divider
        Container(
          height: 8,
          color: colorScheme.surfaceContainerHigh,
        ),

        // Items list
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.itemsText,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              OperationItemsList(operation: operation),
            ],
          ),
        ),

        if (operation.totalPaid > 0 || operation.balanceDue > 0)
          _PaymentDetails(operation: operation),

        _FooterActions(operation: operation),
      ],
    );
  }
}

class _PaymentDetails extends StatelessWidget {
  final BusinessOperation operation;

  const _PaymentDetails({required this.operation});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.paymentDetails,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _PaymentRow(
            label: localizations.totalAmount,
            value: _formatCurrency(operation.totalAmount, context),
            color: colorScheme.onSurface,
          ),
          _PaymentRow(
            label: localizations.totalPaid,
            value: _formatCurrency(operation.totalPaid, context),
            color: colorScheme.primary,
          ),
          _PaymentRow(
            label: localizations.totalDeposited,
            value: _formatCurrency(operation.totalDeposited, context),
            color: colorScheme.secondary,
          ),
          Divider(
            color: colorScheme.outlineVariant,
            height: 24,
          ),
          _PaymentRow(
            label: localizations.balanceDue,
            value: _formatCurrency(operation.balanceDue, context),
            color: operation.balanceDue > 0
                ? colorScheme.error
                : colorScheme.onSurface,
            isBold: true,
          ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isBold;

  const _PaymentRow({
    required this.label,
    required this.value,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: color,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// FOOTER ACTIONS
// -----------------------------------------------------------------------------

class _FooterActions extends StatelessWidget {
  final BusinessOperation operation;

  const _FooterActions({required this.operation});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      color: colorScheme.surfaceContainerLow,
      child: Row(
        children: [
          if (operation.balanceDue > 0)
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _processPayment(context),
                icon: const Icon(Icons.payment),
                label: Text(localizations.processPayment),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          if (operation.balanceDue > 0) const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _sendReminder(context),
              icon: const Icon(Icons.email),
              label: Text(localizations.sendReminder),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _processPayment(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.processingPayment)),
    );
  }

  void _sendReminder(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.sendingReminder)),
    );
  }
}

// -----------------------------------------------------------------------------
// HELPERS
// -----------------------------------------------------------------------------

String _formatCurrency(double amount, BuildContext context) {
  return FinancialUIManager.formatCurrency(amount, context);
}

String _formatStatus(String status, BuildContext context) {
  final localizations = AppLocalizations.of(context)!;

  switch (status) {
    case 'fully_paid':
      return localizations.fullyPaid;
    case 'partially_paid':
      return localizations.partiallyPaid;
    case 'unpaid':
      return localizations.unpaid;
    case 'overdue':
      return localizations.overdue;
    default:
      return status
          .split('_')
          .map((w) => w[0].toUpperCase() + w.substring(1))
          .join(' ');
  }
}

Color _getStatusColor(String status, ColorScheme colorScheme) {
  switch (status) {
    case 'paid':
    case 'fully_paid':
      return colorScheme.primary;
    case 'partial':
    case 'partially_paid':
      return colorScheme.tertiary;
    case 'unpaid':
      return colorScheme.error;
    case 'overdue':
      return colorScheme.error;
    default:
      return colorScheme.onSurface;
  }
}

IconData _getStatusIcon(String status) {
  switch (status) {
    case 'paid':
    case 'fully_paid':
      return Icons.check_circle;
    case 'partial':
    case 'partially_paid':
      return Icons.pending;
    case 'unpaid':
    case 'overdue':
      return Icons.error_outline;
    default:
      return Icons.help_outline;
  }
}
