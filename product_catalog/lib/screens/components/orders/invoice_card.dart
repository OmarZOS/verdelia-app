import 'package:flutter/material.dart';
import 'package:verdelia_core/business/finance/Order.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'invoice_status_helpers.dart';

/// Expanded invoice card. Shown in the details sheet when the
/// invoice is expanded on the order payload.
class InvoiceCard extends StatelessWidget {
  final Order order;
  final InvoiceSummary invoice;
  final void Function(Order order, InvoiceSummary invoice)? onPayInvoice;

  const InvoiceCard({
    super.key,
    required this.order,
    required this.invoice,
    this.onPayInvoice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final color = invoiceStatusColor(invoice.status, theme);
    final dueFmt = DateFormat('MMM d, yyyy');
    final days = invoice.daysUntilDue;

    String subtitle;
    if (invoice.isPaid) {
      subtitle = loc.invoiceStatusPaidTxt;
    } else if (invoice.isOverdue && days != null) {
      subtitle = loc.invoiceOverdueByTxt(days.abs());
    } else if (days != null) {
      subtitle = loc.invoiceDueInTxt(days);
    } else {
      subtitle = invoiceStatusText(invoice.status, loc);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_outlined, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.reference ?? '#${invoice.invoiceId}',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  invoiceStatusText(invoice.status, loc),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _AmountTile(
                label: loc.invoiceAmountLabel,
                value: loc.price(invoice.grandTotal.toStringAsFixed(2)),
              ),
              const SizedBox(width: 16),
              if (invoice.dueDate != null)
                _AmountTile(
                  label: loc.invoiceDueLabel,
                  value: dueFmt.format(invoice.dueDate!),
                ),
            ],
          ),
          if (invoice.isOutstanding && onPayInvoice != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => onPayInvoice!(order, invoice),
                icon: const Icon(Icons.payment, size: 18),
                label: Text(
                  loc.payInvoiceAmountTxt(
                    loc.price(invoice.grandTotal.toStringAsFixed(2)),
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
          if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.notes,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    invoice.notes!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
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

class _AmountTile extends StatelessWidget {
  final String label;
  final String value;

  const _AmountTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
