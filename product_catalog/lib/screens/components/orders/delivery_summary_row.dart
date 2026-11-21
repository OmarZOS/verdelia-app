import 'package:flutter/material.dart';
import 'package:verdelia_core/business/finance/OrderedItem.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

import 'delivery_status_helpers.dart';

/// Compact one-line delivery summary for the order card.
class DeliverySummaryRow extends StatelessWidget {
  final List<OrderedItem> items;

  const DeliverySummaryRow({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final deliveries =
        items.map((i) => i.delivery).whereType<OrderItemDelivery>().toList();
    if (deliveries.isEmpty) return const SizedBox.shrink();

    final statuses =
        deliveries.map((d) => d.deliveryStatus?.toLowerCase()).toSet();

    final String label;
    if (deliveries.length == 1) {
      final d = deliveries.first;
      final method = humanizeShippingMethod(d.deliveryShippingMethod, loc);
      final status = deliveryStatusText(d.deliveryStatus, loc);
      label = method.isEmpty ? status : '$method · $status';
    } else if (statuses.length == 1) {
      label =
          '${deliveries.length} × ${deliveryStatusText(deliveries.first.deliveryStatus, loc)}';
    } else {
      label = '${deliveries.length} ${loc.deliveriesTxt}';
    }

    final color = deliveries.any((d) => d.isDelivered)
        ? Colors.green.shade700
        : deliveries.any((d) => d.isInTransit)
            ? Colors.blue.shade700
            : deliveries.any((d) => d.isConfirmed)
                ? Colors.teal.shade700
                : theme.colorScheme.onSurfaceVariant;

    return Row(
      children: [
        Icon(Icons.local_shipping_outlined, size: 12, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
