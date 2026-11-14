import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

class OrderSummarySection extends StatelessWidget {
  /// Subtotal, in [Decimal].
  final Decimal subtotal;

  /// Tax amount, in [Decimal].
  final Decimal tax;

  /// Discount amount, in [Decimal]. Null when no discount applies.
  final Decimal? discount;

  /// Shipping amount, in [Decimal]. Null when no shipping applies.
  final Decimal? shipping;

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

    // `Decimal + Decimal + Decimal - Decimal` — all closed over
    // `Decimal`. `?? Decimal.zero` matches the old `?? 0` fallback.
    final Decimal total = subtotal +
        tax +
        (shipping ?? Decimal.zero) -
        (discount ?? Decimal.zero);

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
            if (discount != null && discount! > Decimal.zero)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _buildSummaryRow(
                  context,
                  label: 'Discount',
                  // Unary minus on `Decimal` is defined.
                  value: -discount!,
                  isDiscount: true,
                ),
              ),

            // Shipping (if any)
            if (shipping != null && shipping! > Decimal.zero)
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
                  // `Decimal.toStringAsFixed(2)` — same output the
                  // `double` path produced.
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
    required Decimal value,
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
          // `value < Decimal.zero` and `value.abs` (getter, not method).
          // `Decimal.abs` returns a `Decimal`, and `toStringAsFixed(2)`
          // produces the same string the `double` version did.
          isDiscount && value < Decimal.zero
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
