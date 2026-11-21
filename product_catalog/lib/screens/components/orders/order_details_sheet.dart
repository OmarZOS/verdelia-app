import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:product_catalog/screens/components/orders/delivery_group.dart';
import 'package:verdelia_core/business/finance/Order.dart';
import 'package:verdelia_core/business/finance/OrderedItem.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

import 'delivery_card.dart';
import 'fulfilment_rollup.dart';
import 'invoice_card.dart';
import 'order_status_chip.dart';
import 'order_status_helpers.dart';

/// Bottom-sheet content for one order's details.
class OrderDetailsSheet extends StatelessWidget {
  final Order order;
  final void Function(Order order, InvoiceSummary invoice)? onPayInvoice;

  const OrderDetailsSheet({
    super.key,
    required this.order,
    this.onPayInvoice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final items = order.orderedItems;
    final rollup = FulfilmentRollup.fromItems(items);

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.orderDetailsTitle,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '#${order.idPlacedOrder}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  OrderStatusChip(status: order.status),
                ],
              ),
              const SizedBox(height: 16),
              if (order.hasExpandedInvoice)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InvoiceCard(
                    order: order,
                    invoice: order.invoice!,
                    onPayInvoice: onPayInvoice,
                  ),
                ),
              if (rollup.total > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FulfilmentSummaryCard(rollup: rollup),
                ),
              _MetaCard(order: order),
              const SizedBox(height: 16),
              ...DeliveryGroup.fromItems(items).map(
                (group) => _DeliveryGroupSection(group: group),
              ),
              const SizedBox(height: 16),
              _PriceBreakdown(
                subtotal: order.totalPrice,
                discount: order.orderDiscount ?? Decimal.zero,
                deliveryFee: _deliveryFeeTotal(order),
                net: order.finalTotal,
              ),
              const SizedBox(height: 24),
              Center(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_outlined),
                  label: Text(loc.close),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrderItemCard extends StatelessWidget {
  final OrderedItem item;
  final bool showDelivery;

  const _OrderItemCard({
    required this.item,
    this.showDelivery = true,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final name = item.orderedProduct?.productName ?? '';
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
    final palette = orderStatusPalette(
      item.orderedItemDeliveryStatus,
      theme,
      loc,
    );
    final delivery = item.delivery;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
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
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isNotEmpty ? name : loc.unknownItemTxt,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.qtyTxt(
                        item.orderedQuantity,
                        loc.price(item.unitPrice.toStringAsFixed(2)),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if ((item.orderedItemDeliveryStatus ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: palette.background,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(palette.icon,
                                size: 11, color: palette.foreground),
                            const SizedBox(width: 4),
                            Text(
                              palette.label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: palette.foreground,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                loc.price(item.lineTotal.toStringAsFixed(2)),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          if (showDelivery && delivery != null) ...[
            const SizedBox(height: 10),
            DeliveryCard(delivery: delivery),
          ],
        ],
      ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  final Order order;

  const _MetaCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    Widget row(IconData icon, String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 10),
            SizedBox(
              width: 90,
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          row(
            Icons.calendar_today_outlined,
            loc.dateLabel,
            kOrderDateFmt.format(order.placedOrderCreation),
          ),
          if (order.hasOrderingUser)
            row(
              Icons.person_outline,
              loc.customerLabel,
              order.orderingUserName,
            ),
          if (order.paymentMethod != null)
            row(
              Icons.payment_outlined,
              loc.paymentMethodLabel,
              order.paymentMethod!,
            ),
          if (!order.hasExpandedInvoice && order.paymentStatus != null)
            row(
              Icons.check_circle_outline,
              loc.paymentStatusLabel,
              order.paymentStatus!,
            ),
        ],
      ),
    );
  }
}

class _PriceBreakdown extends StatelessWidget {
  final Decimal subtotal;
  final Decimal discount;
  final Decimal deliveryFee;
  final Decimal net;

  const _PriceBreakdown({
    required this.subtotal,
    required this.discount,
    required this.deliveryFee,
    required this.net,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    Widget line(String label, String value,
        {bool emphasized = false, Color? color}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
                color: emphasized
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
                color: color ??
                    (emphasized
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          line(loc.subtotal, loc.price(subtotal.toStringAsFixed(2))),
          if (discount > Decimal.zero)
            line(
              loc.discount,
              '- ${loc.price(discount.toStringAsFixed(2))}',
              color: theme.colorScheme.error,
            ),
          // NEW: delivery fee, only when the order actually has one.
          if (deliveryFee > Decimal.zero)
            line(
              loc.deliveryFeeLabel,
              loc.price(deliveryFee.toStringAsFixed(2)),
            ),
          Divider(
            height: 20,
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          ),
          line(
            loc.totalTxt,
            loc.price(net.toStringAsFixed(2)),
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

class _DeliveryGroupSection extends StatelessWidget {
  final DeliveryGroup group;

  const _DeliveryGroupSection({required this.group});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (group.hasDelivery) ...[
          DeliveryCard(delivery: group.delivery!),
          const SizedBox(height: 8),
        ] else ...[
          // The unassigned group is just a section heading; no
          // delivery header because there is nothing to show.
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              loc.orderItemsTxt,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
        // Item count caption under the delivery header, so the user
        // knows how many lines share this delivery without opening
        // each item.
        if (group.hasDelivery && group.items.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${group.items.length} ${loc.itemsText.toLowerCase()}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ...group.items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _OrderItemCard(item: item, showDelivery: false),
          ),
        ),
      ],
    );
  }
}

/// Sum of delivery fees across distinct delivery ids on this order.
///
/// Two items in the same delivery carry the same fee twice (once per
/// line), so summing `orderedItemDeliveryFee` would double-count.
/// Summing per-delivery is correct because each `OrderItemDelivery`
/// carries the fee exactly once.
Decimal _deliveryFeeTotal(Order order) {
  final seen = <int>{};
  var total = Decimal.zero;
  for (final item in order.orderedItems) {
    final d = item.delivery;
    if (d == null || !d.hasFee) continue;
    if (!seen.add(d.idDelivery)) continue;
    total += d.deliveryFee;
  }
  return total;
}
