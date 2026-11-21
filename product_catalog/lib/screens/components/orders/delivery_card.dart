import 'package:flutter/material.dart';
import 'package:verdelia_core/business/finance/OrderedItem.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

import 'delivery_status_helpers.dart';
import 'order_status_helpers.dart';

/// Full delivery block for a single [OrderedItem].
///
/// No IDs are shown. Renders: status header, shipping method,
/// address, physical facts (packages/weight/dimensions/HS code),
/// notes (goods/instructions), and timestamps — each tier only when
/// the corresponding data is present.
class DeliveryCard extends StatelessWidget {
  final OrderItemDelivery delivery;

  const DeliveryCard({super.key, required this.delivery});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final statusColor = deliveryStatusColor(delivery.deliveryStatus, theme);
    final method = humanizeShippingMethod(delivery.deliveryShippingMethod, loc);
    final statusLabel = deliveryStatusText(delivery.deliveryStatus, loc);

    final chips = <Widget>[
      if (delivery.deliveryPackageCount != null)
        _FactChip(
          icon: Icons.inventory_2_outlined,
          label: '${delivery.deliveryPackageCount} ${loc.packageCountLabel}',
        ),
      if (delivery.hasWeight)
        _FactChip(
          icon: Icons.scale_outlined,
          label: '${delivery.deliveryTotalWeight} kg',
        ),
      if ((delivery.deliveryCargoDimensions ?? '').trim().isNotEmpty)
        _FactChip(
          icon: Icons.straighten_outlined,
          label: delivery.deliveryCargoDimensions!.trim(),
        ),
      if ((delivery.hsCode ?? '').trim().isNotEmpty)
        _FactChip(
          icon: Icons.qr_code_2_outlined,
          label: delivery.hsCode!.trim(),
        ),
    ];

    final hasNotes =
        (delivery.deliveryGoodsDescription ?? '').trim().isNotEmpty ||
            (delivery.specialInstructions ?? '').trim().isNotEmpty;
    final hasFooter = delivery.createdAt != null || delivery.updatedAt != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping_outlined, size: 14, color: statusColor),
              const SizedBox(width: 6),
              Text(
                loc.deliveryLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
              const Spacer(),
              if (delivery.hasFee) ...[
                Text(
                  loc.price(delivery.deliveryFee.toStringAsFixed(2)),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              _StatusPill(label: statusLabel, color: statusColor),
            ],
          ),
          if (method.isNotEmpty) ...[
            const SizedBox(height: 8),
            _PrimaryRow(icon: Icons.alt_route_outlined, label: method),
          ],
          if (delivery.address != null &&
              delivery.address!.fullAddress.isNotEmpty) ...[
            const SizedBox(height: 4),
            _PrimaryRow(
              icon: Icons.place_outlined,
              label: delivery.address!.fullAddress,
              maxLines: 2,
            ),
          ],
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: chips),
          ],
          if (hasNotes) ...[
            const SizedBox(height: 10),
            if ((delivery.deliveryGoodsDescription ?? '').trim().isNotEmpty)
              _NoteBlock(
                icon: Icons.inventory_outlined,
                label: loc.goodsDescriptionLabel,
                body: delivery.deliveryGoodsDescription!.trim(),
              ),
            if ((delivery.specialInstructions ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              _NoteBlock(
                icon: Icons.info_outline,
                label: loc.specialInstructionsLabel,
                body: delivery.specialInstructions!.trim(),
              ),
            ],
          ],
          if (hasFooter) ...[
            const SizedBox(height: 8),
            Divider(
              height: 1,
              color: theme.colorScheme.outlineVariant.withOpacity(0.3),
            ),
            const SizedBox(height: 6),
            Text(
              [
                if (delivery.createdAt != null)
                  '${loc.createdLabel} ${kOrderDateFmt.format(delivery.createdAt!)}',
                if (delivery.updatedAt != null &&
                    delivery.updatedAt != delivery.createdAt)
                  '${loc.updatedLabel} ${kOrderDateFmt.format(delivery.updatedAt!)}',
              ].join('  ·  '),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PrimaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int maxLines;

  const _PrimaryRow({
    required this.icon,
    required this.label,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _FactChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FactChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteBlock extends StatelessWidget {
  final IconData icon;
  final String label;
  final String body;

  const _NoteBlock({
    required this.icon,
    required this.label,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            body,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
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
