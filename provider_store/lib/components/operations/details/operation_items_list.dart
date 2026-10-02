// lib/ui/components/business_operations/operation_items_list.dart

import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

import 'package:verdelia_core/business/finance/BusinessOperation.dart';
import 'package:ui/components/finance/financial_ui_manager.dart';

/// Renders the ordered items that ship inside the operation envelope.
///
/// The envelope already carries `operation.items` for both cart- and
/// delivery-sourced operations, so this widget no longer needs to fetch
/// from `CartChangeNotifier` or `OrderChangeNotifier`. It is now a pure
/// presentational widget over the raw item maps.
class OperationItemsList extends StatelessWidget {
  final BusinessOperation operation;

  const OperationItemsList({super.key, required this.operation});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (operation.items.isEmpty) {
      return _EmptyItemsState(localizations: loc);
    }

    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: operation.items.length,
          separatorBuilder: (_, __) => Divider(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            height: 16,
          ),
          itemBuilder: (context, index) {
            return _ItemCard(item: operation.items[index]);
          },
        ),
        const SizedBox(height: 16),
        _ItemsTotalSummary(
          items: operation.items,
          // Prefer the backend-reported total for the operation; fall back
          // to a local sum only when the envelope doesn't carry it.
          grandTotal: operation.grandTotal,
          taxAmount: operation.taxAmount,
          discountAmount: operation.discountAmount,
          productSubtotal: operation.productSubtotal,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// One item card — reads the raw map shape from the envelope
// ---------------------------------------------------------------------------

class _ItemCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _ItemCard({required this.item});

  // Helpers that read defensively off the raw map.

  Map<String, dynamic>? get _product =>
      item['ordered_product'] as Map<String, dynamic>?;

  String get _name {
    final p = _product;
    return (p?['product_name'] as String?) ??
        'Product #${item['ordered_product_id']}';
  }

  String? get _description => _product?['product_description'] as String?;

  num get _quantity => (item['ordered_quantity'] as num?) ?? 1;
  num get _unitPrice => (item['unit_price'] as num?) ?? 0;
  num get _vat => (item['applied_vat'] as num?) ?? 0;
  num get _discount => (item['product_discount'] as num?) ?? 0;
  String? get _status => item['ordered_item_delivery_status'] as String?;

  num get _lineTotal {
    final gross = _quantity * _unitPrice;
    final afterDiscount = gross - _discount;
    // applied_vat is a percentage rate in this schema.
    final withTax = afterDiscount * (1 + _vat / 100);
    return withTax;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 20,
              color: cs.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _InfoText('× ${_quantity.toString()}'),
                    const SizedBox(width: 12),
                    _InfoText(FinancialUIManager.formatCurrency(
                        _unitPrice.toDouble(), context)),
                    if (_vat > 0) ...[
                      const SizedBox(width: 12),
                      _InfoText('VAT ${_vat.toStringAsFixed(0)}%'),
                    ],
                  ],
                ),
                if (_description != null && _description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (_status != null) ...[
                  const SizedBox(height: 4),
                  _StatusChip(label: _status!),
                ],
                if (_discount > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Discount ${FinancialUIManager.formatCurrency(_discount.toDouble(), context)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            FinancialUIManager.formatCurrency(_lineTotal.toDouble(), context),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoText extends StatelessWidget {
  final String text;
  const _InfoText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  const _StatusChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _colorFor(label, cs);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.replaceAll('_', ' '),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static Color _colorFor(String s, ColorScheme cs) {
    switch (s.toLowerCase()) {
      case 'delivered':
      case 'completed':
        return Colors.green;
      case 'processing':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
      case 'canceled':
        return cs.error;
      default:
        return cs.onSurfaceVariant;
    }
  }
}

// ---------------------------------------------------------------------------
// Totals summary — uses authoritative envelope numbers when available
// ---------------------------------------------------------------------------

class _ItemsTotalSummary extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final double grandTotal;
  final double taxAmount;
  final double discountAmount;
  final double productSubtotal;

  const _ItemsTotalSummary({
    required this.items,
    required this.grandTotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.productSubtotal,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;

    // If the envelope delivered a non-zero product subtotal, use it —
    // it reflects only this supplier's slice after server-side filtering.
    // Otherwise fall back to a local sum over the items we see.
    final subtotal = productSubtotal > 0 ? productSubtotal : _localSubtotal();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _Row(
            label: 'Subtotal',
            amount: subtotal,
          ),
          if (discountAmount > 0) ...[
            const SizedBox(height: 8),
            _Row(
              label: 'Discount',
              amount: -discountAmount,
              color: Colors.orange,
            ),
          ],
          const SizedBox(height: 8),
          _Row(
            label: 'Tax',
            amount: taxAmount,
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                FinancialUIManager.formatCurrency(grandTotal, context),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                    ),
              ),
            ],
          ),
          // Hint when grand total differs from the item sum — usually
          // because the operation includes services or delivery revenue.
          if ((grandTotal - subtotal - taxAmount + discountAmount).abs() >
              0.01) ...[
            const SizedBox(height: 8),
            Text(
              'Includes services and/or delivery revenue',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  double _localSubtotal() {
    double sum = 0;
    for (final item in items) {
      final qty = (item['ordered_quantity'] as num?) ?? 0;
      final price = (item['unit_price'] as num?) ?? 0;
      sum += qty * price;
    }
    return sum;
  }
}

class _Row extends StatelessWidget {
  final String label;
  final double amount;
  final Color? color;

  const _Row({
    required this.label,
    required this.amount,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
        ),
        Text(
          FinancialUIManager.formatCurrency(amount, context),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color ?? cs.onSurface,
              ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyItemsState extends StatelessWidget {
  final AppLocalizations localizations;

  const _EmptyItemsState({required this.localizations});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2,
              size: 48,
              color: cs.onSurfaceVariant.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No items found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'This operation has no associated items',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
