import 'package:flutter/material.dart';
import 'package:verdelia_core/business/finance/Order.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

import 'order_status_helpers.dart';

/// Order-status chip with icon + label, coloured via [orderStatusPalette].
class OrderStatusChip extends StatelessWidget {
  final String? status;

  const OrderStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final palette = orderStatusPalette(status, theme, loc);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(palette.icon, size: 11, color: palette.foreground),
          const SizedBox(width: 5),
          Text(
            palette.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: palette.foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Invoice-status chip (smaller, used inline next to the order chip
/// on the order card).
class InvoiceChip extends StatelessWidget {
  final InvoiceSummary invoice;
  final Color color;
  final String label;
  final bool isOverdue;

  const InvoiceChip({
    super.key,
    required this.invoice,
    required this.color,
    required this.label,
    required this.isOverdue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOverdue
                ? Icons.warning_amber_outlined
                : Icons.receipt_long_outlined,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// Structural type so this file doesn't need `Order.dart` just for
/// the two fields it reads. Callers pass the real [InvoiceSummary].
abstract class InvoiceSummaryLike {
  String get status;
  bool get isOverdue;
}
