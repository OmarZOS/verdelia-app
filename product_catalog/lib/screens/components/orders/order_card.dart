import 'package:flutter/material.dart';
import 'package:verdelia_core/business/finance/Order.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

import 'delivery_summary_row.dart';
import 'fulfilment_rollup.dart';
import 'invoice_status_helpers.dart';
import 'order_status_chip.dart';
import 'order_status_helpers.dart';

/// One order row on the list. Pure view: no data fetching, no
/// navigation side-effects beyond the tap callback.
class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const OrderCard({super.key, required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final items = order.orderedItems;
    final itemCount = order.itemCount;
    final rollup = FulfilmentRollup.fromItems(items);
    final invoice = order.invoice;
    final dateLabel = kOrderDateFmt.format(order.placedOrderCreation);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        elevation: 0,
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    OrderStatusChip(status: order.status),
                    if (invoice != null && invoice.isOutstanding) ...[
                      const SizedBox(width: 6),
                      InvoiceChip(
                        invoice: invoice,
                        color: invoiceStatusColor(invoice.status, theme),
                        label: invoiceStatusText(invoice.status, loc),
                        isOverdue: invoice.isOverdue,
                      ),
                    ],
                    const Spacer(),
                    Text(
                      loc.price(order.totalPrice.toStringAsFixed(2)),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _Avatar(
                      name: items.isNotEmpty
                          ? items.first.orderedProduct?.productName
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _title(items, loc),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _subtitle(items, itemCount, loc),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (rollup.total > 0 && !rollup.allDelivered) ...[
                  const SizedBox(height: 10),
                  FulfilmentStrip(rollup: rollup),
                ],
                if (items.any((i) => i.delivery != null)) ...[
                  const SizedBox(height: 8),
                  DeliverySummaryRow(items: items),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '#${order.idPlacedOrder}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color:
                            theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _title(List<dynamic> items, AppLocalizations loc) {
    if (items.isEmpty) return loc.noItemsTxt;
    final first = items.first.orderedProduct?.productName as String?;
    if (first != null && first.isNotEmpty) {
      return items.length == 1 ? first : '$first…';
    }
    return loc.itemsText;
  }

  String _subtitle(List<dynamic> items, int count, AppLocalizations loc) {
    if (items.isEmpty) return '';
    final noun = count == 1 ? loc.itemSingular : loc.itemPlural;
    if (items.length <= 1) return '$count $noun';
    return '$count $noun • ${items.length - 1} ${loc.moreTxt}';
  }
}

class _Avatar extends StatelessWidget {
  final String? name;

  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = (name != null && name!.isNotEmpty)
        ? name!.characters.first.toUpperCase()
        : '?';
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
