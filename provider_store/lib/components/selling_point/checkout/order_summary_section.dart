import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

class OrderSummarySection extends StatelessWidget {
  final double subtotal;
  final double tax;
  final double? discount;
  final double? shipping;

  const OrderSummarySection({
    super.key,
    required this.subtotal,
    required this.tax,
    this.discount,
    this.shipping,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final total = subtotal + tax + (shipping ?? 0) - (discount ?? 0);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  loc.orderSummary,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Subtotal
            _buildSummaryRow(
              context,
              label: loc.subtotal,
              value: subtotal,
            ),

            // Tax
            _buildSummaryRow(
              context,
              label: loc.tax,
              value: tax,
            ),

            // Discount (if any)
            if (discount != null && discount! > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _buildSummaryRow(
                  context,
                  label: 'Discount',
                  value: -discount!,
                  isDiscount: true,
                ),
              ),

            // Shipping (if any)
            if (shipping != null && shipping! > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _buildSummaryRow(
                  context,
                  label: 'Shipping',
                  value: shipping!,
                ),
              ),

            // Divider
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),

            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc.total,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  loc.price(total.toStringAsFixed(2)),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context, {
    required String label,
    required double value,
    bool isDiscount = false,
  }) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          isDiscount && value < 0
              ? '-${loc.price(value.abs().toStringAsFixed(2))}'
              : loc.price(value.toStringAsFixed(2)),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDiscount ? theme.colorScheme.error : null,
          ),
        ),
      ],
    );
  }
}
