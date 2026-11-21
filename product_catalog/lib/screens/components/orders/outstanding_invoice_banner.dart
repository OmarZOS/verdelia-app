import 'package:flutter/material.dart';
import 'package:verdelia_core/business/finance/Order.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

import 'invoice_status_helpers.dart';

class OutstandingInvoiceBanner extends StatelessWidget {
  final List<Order> orders;
  final void Function(Order order, InvoiceSummary invoice)? onPayInvoice;

  const OutstandingInvoiceBanner({
    super.key,
    required this.orders,
    this.onPayInvoice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 18,
                    color: Colors.orange.shade800,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.invoicesToPayTitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.orange.shade900,
                        ),
                      ),
                      Text(
                        loc.invoicesToPaySubtitle(orders.length),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade800.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
              children: orders.map((o) {
                final inv = o.invoice!;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: _InvoiceRow(
                    order: o,
                    invoice: inv,
                    onPayInvoice: onPayInvoice,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  final Order order;
  final InvoiceSummary invoice;
  final void Function(Order order, InvoiceSummary invoice)? onPayInvoice;

  const _InvoiceRow({
    required this.order,
    required this.invoice,
    this.onPayInvoice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final overdue = invoice.isOverdue;
    final days = invoice.daysUntilDue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: overdue
              ? theme.colorScheme.error.withOpacity(0.3)
              : theme.colorScheme.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        invoice.reference ?? '#${order.idPlacedOrder}',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusTag(
                      color: overdue
                          ? Colors.red.shade700
                          : Colors.orange.shade800,
                      label: overdue
                          ? loc.invoiceStatusOverdueTxt
                          : invoiceStatusText(invoice.status, loc),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      loc.price(invoice.grandTotal.toStringAsFixed(2)),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (days != null) ...[
                      const SizedBox(width: 10),
                      Text(
                        overdue
                            ? loc.invoiceOverdueByTxt(days.abs())
                            : loc.invoiceDueInTxt(days),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: overdue
                              ? Colors.red.shade700
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (onPayInvoice != null)
            FilledButton(
              onPressed: () => onPayInvoice!(order, invoice),
              style: FilledButton.styleFrom(
                backgroundColor:
                    overdue ? Colors.red.shade600 : Colors.orange.shade700,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: const Size(0, 34),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                loc.payNowTxt,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            )
          else
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
        ],
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  final Color color;
  final String label;

  const _StatusTag({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}
