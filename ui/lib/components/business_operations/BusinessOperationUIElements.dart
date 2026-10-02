// lib/ui/components/business_operations/business_operation_badges.dart

import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

import 'package:verdelia_core/business/finance/BusinessOperation.dart';
import 'package:ui/components/business_operations/BusinessOperationsUIManager.dart';
import 'package:ui/components/finance/financial_ui_manager.dart';

// ---------------------------------------------------------------------------
// Invoice status badge (replaces the old PaymentStatusBadge)
// ---------------------------------------------------------------------------

class InvoiceStatusBadge extends StatelessWidget {
  final String? status;
  final bool compact;

  const InvoiceStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = BusinessOperationsUIManager.getInvoiceStatusConfig(status);
    final theme = Theme.of(context);

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: config.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(config.icon, size: 12, color: config.color),
            const SizedBox(width: 4),
            Text(
              config.displayName,
              style: TextStyle(
                color: config.color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: config.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 16, color: config.color),
          const SizedBox(width: 8),
          Text(
            config.displayName,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: config.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Backwards-compatible alias. If anything in the app still references
/// `PaymentStatusBadge`, this keeps it compiling. Prefer switching call
/// sites to `InvoiceStatusBadge` — the concept was renamed upstream.
class PaymentStatusBadge extends InvoiceStatusBadge {
  const PaymentStatusBadge({
    super.key,
    required String super.status,
    super.compact,
  });
}

// ---------------------------------------------------------------------------
// Lifecycle status rail (cart_status / delivery_status)
// ---------------------------------------------------------------------------

class StatusRail extends StatelessWidget {
  final String? status;

  const StatusRail({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = BusinessOperationsUIManager.getLifecycleStatusConfig(status);

    return Container(
      width: 4,
      height: 110,
      decoration: BoxDecoration(
        color: config.color,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: config.color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info badge (generic label + value chip)
// ---------------------------------------------------------------------------

class InfoBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData? icon;

  const InfoBadge({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Source badge (cart vs delivery)
// ---------------------------------------------------------------------------

class SourceBadge extends StatelessWidget {
  final BusinessOperation operation;
  final bool showIcon;

  const SourceBadge({
    super.key,
    required this.operation,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config =
        BusinessOperationsUIManager.getSourceTypeConfig(operation.sourceType);
    final color = BusinessOperationsUIManager.getSourceBadgeColor(
      operation.sourceType,
      theme.colorScheme,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(config.icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            config.displayName,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Amount display
// ---------------------------------------------------------------------------

class AmountDisplay extends StatelessWidget {
  final String label;
  final double value;
  final Color? color;
  final bool highlight;

  const AmountDisplay({
    super.key,
    required this.label,
    required this.value,
    this.color,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayColor = color ??
        (highlight ? theme.colorScheme.error : theme.colorScheme.onSurface);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        const SizedBox(height: 4),
        Text(
          FinancialUIManager.formatCurrency(value, context),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: displayColor,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Document info row (source + invoice status + optional warnings)
// ---------------------------------------------------------------------------

class DocumentInfoRow extends StatelessWidget {
  final BusinessOperation operation;
  final bool showLabels;

  const DocumentInfoRow({
    super.key,
    required this.operation,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final widgets = <Widget>[];

    // Source: cart or delivery
    widgets.add(SourceBadge(operation: operation));

    // Invoice status
    if (operation.invoiceStatus != null &&
        operation.invoiceStatus!.isNotEmpty) {
      final invConfig = BusinessOperationsUIManager.getInvoiceStatusConfig(
        operation.invoiceStatus,
      );
      widgets.add(
        InfoBadge(
          label: showLabels ? l10n.invoiceStatus : '',
          value: invConfig.displayName,
          color: invConfig.color,
          icon: invConfig.icon,
        ),
      );
    }

    // Lifecycle status
    if (operation.status != null && operation.status!.isNotEmpty) {
      final lifeConfig = BusinessOperationsUIManager.getLifecycleStatusConfig(
        operation.status,
      );
      widgets.add(
        InfoBadge(
          label: showLabels ? 'Status' : '',
          value: lifeConfig.displayName,
          color: lifeConfig.color,
          icon: lifeConfig.icon,
        ),
      );
    }

    // // Inconsistency warnings
    // if (operation.invoiceMismatch) {
    //   widgets.add(
    //     InfoBadge(
    //       label: '',
    //       value: 'Invoice mismatch',
    //       color: Colors.orange,
    //       icon: Icons.warning_amber_rounded,
    //     ),
    //   );
    // }
    // if (!operation.paymentStatusConsistent) {
    //   widgets.add(
    //     InfoBadge(
    //       label: '',
    //       value: 'Payment mismatch',
    //       color: theme.colorScheme.error,
    //       icon: Icons.error_outline,
    //     ),
    //   );
    // }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: widgets,
    );
  }
}

// ---------------------------------------------------------------------------
// Financial info block (settlement layer)
// ---------------------------------------------------------------------------

class FinancialInfoBlock extends StatelessWidget {
  final BusinessOperation operation;

  /// Kept for API compatibility. The new envelope doesn't ship a deposit
  /// total, so this is a no-op for now. If the backend re-introduces a
  /// deposit figure, wire it through here.
  final bool showDeposit;

  const FinancialInfoBlock({
    super.key,
    required this.operation,
    this.showDeposit = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AmountDisplay(
                  label: l10n.balance,
                  value: operation.dueAmount,
                  highlight: operation.dueAmount > 0,
                ),
              ),
              Expanded(
                child: AmountDisplay(
                  label: l10n.paid,
                  value: operation.paidAmount,
                  color: Colors.green,
                ),
              ),
              Expanded(
                child: AmountDisplay(
                  label: l10n.totalAmount,
                  value: operation.grandTotal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
