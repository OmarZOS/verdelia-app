// lib/screens/business_operation_details_screen.dart

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/business/finance/BusinessOperation.dart';
import 'package:ui/components/finance/financial_ui_manager.dart';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class OperationDetailsScreen extends StatelessWidget {
  final BusinessOperation operation;

  const OperationDetailsScreen({super.key, required this.operation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        top: false,
        child: DefaultTabController(
          length: 1,
          child: CustomScrollView(
            slivers: [
              _OperationHero(operation: operation),
              SliverToBoxAdapter(
                child: _Body(operation: operation),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero header
// ---------------------------------------------------------------------------

class _OperationHero extends StatelessWidget {
  final BusinessOperation operation;
  const _OperationHero({required this.operation});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;

    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      stretch: true,
      backgroundColor: _heroColor(cs, operation),
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          tooltip: loc.share,
          onPressed: () => _share(context, operation),
          icon: const Icon(Icons.ios_share_rounded),
        ),
        IconButton(
          tooltip: loc.print,
          onPressed: () => _print(context, operation),
          icon: const Icon(Icons.print_outlined),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: _HeroBackground(operation: operation),
      ),
    );
  }

  static Color _heroColor(ColorScheme cs, BusinessOperation op) {
    switch ((op.invoiceStatus ?? '').toLowerCase()) {
      case 'paid':
        return const Color(0xFF1E8E5A);
      case 'partially_paid':
        return const Color(0xFFB8791C);
      case 'unpaid':
        return const Color(0xFF9E3B3B);
      default:
        return cs.primary;
    }
  }

  static void _share(BuildContext context, BusinessOperation op) {
    final loc = AppLocalizations.of(context)!;
    final text = _shareSummary(op, loc);
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.sharingOperation)),
    );
  }

  static void _print(BuildContext context, BusinessOperation op) {
    final loc = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.printingOperation)),
    );
  }

  static String _shareSummary(BusinessOperation op, AppLocalizations loc) {
    // `grandTotal`, `paidAmount`, `dueAmount` are `Decimal` after the
    // BusinessOperation migration; `toStringAsFixed(2)` gives the same
    // output `double.toStringAsFixed(2)` did.
    return [
      op.title,
      '${loc.totalLabel}: ${op.grandTotal.toStringAsFixed(2)}',
      '${loc.paidLabel}:  ${op.paidAmount.toStringAsFixed(2)}',
      '${loc.dueLabel}:   ${op.dueAmount.toStringAsFixed(2)}',
    ].join('\n');
  }
}

class _HeroBackground extends StatelessWidget {
  final BusinessOperation operation;
  const _HeroBackground({required this.operation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;

    final hero = _OperationHero._heroColor(cs, operation);

    // Denominator: invoice total when present, otherwise grand total.
    // Both are `Decimal` after the migration.
    final Decimal denominator = operation.invoiceTotal > Decimal.zero
        ? operation.invoiceTotal
        : operation.grandTotal;

    // Settlement ratio = paid / denominator, clamped to `[0, 1]`.
    // `Decimal / Decimal` returns `Rational`, so `.toDecimal(scaleOnInfinitePrecision: 2)` is
    // required; the manual three-branch clamp replaces `num.clamp`.
    // The `LinearProgressIndicator` takes a `double`, so the final
    // value is converted once.
    final double settlementRatio;
    if (denominator <= Decimal.zero) {
      settlementRatio = 0.0;
    } else {
      final raw = (operation.paidAmount / denominator)
          .toDecimal(scaleOnInfinitePrecision: 2);
      if (raw < Decimal.zero) {
        settlementRatio = 0.0;
      } else if (raw > Decimal.one) {
        settlementRatio = 1.0;
      } else {
        settlementRatio = raw.toDouble();
      }
    }

    // Headline amount: invoice total when present, otherwise grand total.
    final Decimal headlineAmount = operation.invoiceTotal > Decimal.zero
        ? operation.invoiceTotal
        : operation.grandTotal;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            hero,
            Color.lerp(hero, Colors.black, 0.35)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, kToolbarHeight + 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      operation.isCart ? loc.cart : loc.order,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '#${operation.sourceId}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  _InvoiceStatusChip(status: operation.invoiceStatus),
                ],
              ),
              const Spacer(),
              Text(
                FinancialUIManager.formatCurrency(headlineAmount, context),
                style: theme.textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                loc.grandTotalLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 16),
              _PaymentProgress(
                paid: operation.paidAmount,
                due: operation.dueAmount,
                ratio: settlementRatio,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvoiceStatusChip extends StatelessWidget {
  final String? status;
  const _InvoiceStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final raw = (status ?? 'unknown').toLowerCase();

    final String label;
    switch (raw) {
      case 'paid':
        label = loc.invoiceStatusPaid;
        break;
      case 'partially_paid':
        label = loc.invoiceStatusPartiallyPaid;
        break;
      case 'unpaid':
        label = loc.invoiceStatusUnpaid;
        break;
      case 'overdue':
        label = loc.invoiceStatusOverdue;
        break;
      case 'canceled':
      case 'cancelled':
        label = loc.invoiceStatusCanceled;
        break;
      case 'refunded':
        label = loc.invoiceStatusRefunded;
        break;
      default:
        label = loc.invoiceStatusUnknown;
        break;
    }

    final color = switch (raw) {
      'paid' => const Color(0xFF7CFFB2),
      'partially_paid' => const Color(0xFFFFD27C),
      'unpaid' => const Color(0xFFFFA8A8),
      _ => Colors.white70,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentProgress extends StatelessWidget {
  final Decimal paid;
  final Decimal due;
  final double ratio;

  const _PaymentProgress({
    required this.paid,
    required this.due,
    required this.ratio,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF7CFFB2)),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _HeroMetric(
              label: loc.paidLabel,
              value: paid,
              color: const Color(0xFF7CFFB2),
            ),
            const SizedBox(width: 20),
            _HeroMetric(
              label: loc.dueLabel,
              value: due,
              color:
                  due > Decimal.zero ? const Color(0xFFFFD27C) : Colors.white70,
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final Decimal value;
  final Color color;

  const _HeroMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.75),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          FinancialUIManager.formatCurrency(value, context),
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _Body extends StatelessWidget {
  final BusinessOperation operation;
  const _Body({required this.operation});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MetaGrid(operation: operation),
          const SizedBox(height: 16),
          _FinancialBreakdownCard(operation: operation),
          const SizedBox(height: 16),
          _ProfitabilityCard(operation: operation),
          const SizedBox(height: 16),
          if (operation.items.isNotEmpty) ...[
            _ItemsCard(operation: operation),
            const SizedBox(height: 16),
          ],
          if (operation.services.isNotEmpty) ...[
            _ServicesCard(operation: operation),
            const SizedBox(height: 16),
          ],
          _MetaCard(operation: operation),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Meta grid
// ---------------------------------------------------------------------------

class _MetaGrid extends StatelessWidget {
  final BusinessOperation operation;
  const _MetaGrid({required this.operation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;

    final items = <_MetaTile>[
      _MetaTile(
        icon: Icons.tag,
        label: loc.metaOperationLabel,
        value: '${operation.sourceType} #${operation.sourceId}',
      ),
      if (operation.supplierId != null)
        _MetaTile(
          icon: Icons.storefront_outlined,
          label: loc.supplier,
          value: '#${operation.supplierId}',
        ),
      if (operation.clientId != null)
        _MetaTile(
          icon: Icons.person_outline,
          label: loc.client,
          value: '#${operation.clientId}',
        ),
      if (operation.createdAt != null)
        _MetaTile(
          icon: Icons.schedule,
          label: loc.metaCreatedLabel,
          value: _fmtDate(operation.createdAt!),
        ),
      if (operation.status != null)
        _MetaTile(
          icon: Icons.flag_outlined,
          label: loc.metaStatusLabel,
          value: operation.status!.replaceAll('_', ' '),
        ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((m) => _MetaChip(tile: m)).toList(),
      ),
    );
  }

  static String _fmtDate(DateTime d) {
    final local = d.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

class _MetaTile {
  final IconData icon;
  final String label;
  final String value;
  const _MetaTile({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _MetaChip extends StatelessWidget {
  final _MetaTile tile;
  const _MetaChip({required this.tile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(tile.icon, size: 14, color: cs.primary),
          const SizedBox(width: 6),
          Text(
            '${tile.label}: ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          Text(
            tile.value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Financial breakdown
// ---------------------------------------------------------------------------

class _FinancialBreakdownCard extends StatelessWidget {
  final BusinessOperation operation;
  const _FinancialBreakdownCard({required this.operation});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    // When the invoiced total disagrees with the operation's
    // grand_total (which can happen when they're computed from
    // different bases), show both so the user isn't staring at two
    // numbers that don't reconcile.
    //
    // `.abs()` on a `Decimal` returns `Decimal`; the `>` comparison
    // against `Decimal.parse('0.01')` is exact.
    final invoicedDiffers = operation.invoiceTotal > Decimal.zero &&
        (operation.invoiceTotal - operation.grandTotal).abs() >
            Decimal.parse('0.01');

    final rows = <_MoneyRow>[
      _MoneyRow(loc.productSubtotalLabel, operation.productSubtotal),
      _MoneyRow(loc.serviceSubtotalLabel, operation.serviceSubtotal),
      _MoneyRow(
        loc.grossSubtotalLabel,
        operation.grossSubtotal,
        emphasis: _Emphasis.subtotal,
      ),
      if (operation.discountAmount > Decimal.zero)
        _MoneyRow(
          loc.discountLabel,
          -operation.discountAmount,
          emphasis: _Emphasis.negative,
        ),
      if (operation.taxAmount > Decimal.zero)
        _MoneyRow(loc.taxLabel, operation.taxAmount),
      if (operation.deliveryRevenue > Decimal.zero)
        _MoneyRow(loc.deliveryLabel, operation.deliveryRevenue),
      _MoneyRow(
        loc.grandTotalLabel,
        operation.grandTotal,
        emphasis: _Emphasis.total,
      ),
      if (invoicedDiffers)
        _MoneyRow(
          loc.invoiceTotalLabel,
          operation.invoiceTotal,
          emphasis: _Emphasis.total,
        ),
    ];

    return _Card(
      title: loc.commercialBreakdownTitle,
      icon: Icons.receipt_long_outlined,
      child: Column(
        children: rows.map((r) => _MoneyRowWidget(row: r)).toList(),
      ),
    );
  }
}

enum _Emphasis { none, subtotal, total, negative }

class _MoneyRow {
  final String label;
  final Decimal value;
  final _Emphasis emphasis;
  const _MoneyRow(this.label, this.value, {this.emphasis = _Emphasis.none});
}

class _MoneyRowWidget extends StatelessWidget {
  final _MoneyRow row;
  const _MoneyRowWidget({required this.row});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final labelColor = switch (row.emphasis) {
      _Emphasis.subtotal => cs.onSurface,
      _Emphasis.total => cs.onSurface,
      _ => cs.onSurfaceVariant,
    };

    final valueColor = switch (row.emphasis) {
      _Emphasis.total => cs.primary,
      _Emphasis.negative => cs.error,
      _ => cs.onSurface,
    };

    final bold =
        row.emphasis == _Emphasis.total || row.emphasis == _Emphasis.subtotal;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: row.emphasis == _Emphasis.total ? 8 : 6,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              row.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: labelColor,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            FinancialUIManager.formatCurrency(row.value, context),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: valueColor,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profitability card
// ---------------------------------------------------------------------------

class _ProfitabilityCard extends StatelessWidget {
  final BusinessOperation operation;
  const _ProfitabilityCard({required this.operation});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;

    final Decimal margin = operation.marginAmount;
    final Color marginColor =
        margin >= Decimal.zero ? const Color(0xFF1E8E5A) : cs.error;
    final Decimal cost = operation.totalCost;
    final Decimal? roi = operation.roi;
    // Cost being 0 doesn't mean the operation is free; it usually
    // means the backend didn't populate any cost fields. Show a hint
    // rather than "Total Cost: 0.00".
    final bool hasCost = cost > Decimal.zero;

    return _Card(
      title: loc.profitabilityTitle,
      icon: Icons.trending_up_rounded,
      trailing: _Pill(
        label: roi == null
            ? '—'
            : '${(roi * Decimal.fromInt(100)).toStringAsFixed(1)}% ${loc.roiLabel}',
        color: roi == null
            ? cs.onSurfaceVariant
            : (roi >= Decimal.zero ? const Color(0xFF1E8E5A) : cs.error),
      ),
      child: Column(
        children: [
          if (hasCost) ...[
            _MoneyRowWidget(
              row: _MoneyRow(
                loc.totalCostLabel,
                cost,
                emphasis: _Emphasis.subtotal,
              ),
            ),
            _MoneyRowWidget(
              row: _MoneyRow(
                loc.marginLabel,
                margin,
                emphasis: _Emphasis.total,
              ),
            ),
            const SizedBox(height: 8),
            _CostBar(
              productCost: operation.productCost,
              consumable: operation.consumableServiceCost,
              nonConsumable: operation.nonConsumableServiceCost,
              labor: operation.laborCost,
              delivery: operation.deliveryCost,
            ),
          ] else ...[
            _MoneyRowWidget(
              row: _MoneyRow(
                loc.marginLabel,
                margin,
                emphasis: _Emphasis.total,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              loc.costNotAvailable,
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
}

class _CostBar extends StatelessWidget {
  final Decimal productCost;
  final Decimal consumable;
  final Decimal nonConsumable;
  final Decimal labor;
  final Decimal delivery;

  const _CostBar({
    required this.productCost,
    required this.consumable,
    required this.nonConsumable,
    required this.labor,
    required this.delivery,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;

    // Segments, in `Decimal`. `Expanded` needs an `int` flex value, so
    // the per-segment flex computation is the one place the file
    // converts `Decimal → double → int`.
    final segments = <_CostSegment>[
      if (productCost > Decimal.zero)
        _CostSegment(loc.costSegmentProducts, productCost, cs.primary),
      if (consumable > Decimal.zero)
        _CostSegment(loc.costSegmentConsumables, consumable, cs.secondary),
      if (nonConsumable > Decimal.zero)
        _CostSegment(loc.costSegmentAmortized, nonConsumable, cs.tertiary),
      if (labor > Decimal.zero)
        _CostSegment(loc.costSegmentLabor, labor, const Color(0xFF8B6CD9)),
      if (delivery > Decimal.zero)
        _CostSegment(
            loc.costSegmentDelivery, delivery, const Color(0xFFD08B1C)),
    ];

    final Decimal total = segments.fold(Decimal.zero, (s, e) => s + e.value);

    if (total <= Decimal.zero || segments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 10,
            child: Row(
              children: segments.map((s) {
                // `(s.value / total) * 1000` in `Decimal`, then
                // `.toDouble().round().clamp(1, 1000)` to get the
                // `int` flex value.
                final double rawFlex =
                    ((s.value / total).toDecimal(scaleOnInfinitePrecision: 2) *
                            Decimal.fromInt(1000))
                        .toDouble();
                final int flex = rawFlex.round().clamp(1, 1000);
                return Expanded(
                  flex: flex,
                  child: ColoredBox(color: s.color),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: segments.map((s) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: s.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${s.label} ${FinancialUIManager.formatCurrency(s.value, context)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _CostSegment {
  final String label;
  final Decimal value;
  final Color color;
  const _CostSegment(this.label, this.value, this.color);
}

// ---------------------------------------------------------------------------
// Items
// ---------------------------------------------------------------------------

class _ItemsCard extends StatelessWidget {
  final BusinessOperation operation;
  const _ItemsCard({required this.operation});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return _Card(
      title: loc.itemsTitle,
      icon: Icons.inventory_2_outlined,
      trailing: _Pill(
        label: '${operation.itemCount}',
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      child: Column(
        children: operation.items.map((item) => _ItemRow(item: item)).toList(),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final BusinessOperationItem item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;

    final product = item.product;
    final name = (product?.productName.trim().isNotEmpty ?? false)
        ? product!.productName.trim()
        : loc.productFallbackName('${item.orderedProductId ?? 0}');

    final qty = item.orderedQuantity;
    final Decimal price = item.unitPrice;
    final Decimal vat = item.appliedVat;
    final status = item.deliveryStatus;
    final Decimal discount = item.discountAmount;
    final Decimal lineTotal = item.lineSubtotal;

    // Typed fields from the OrderedProduct snapshot — no raw maps.
    final brand = product?.productBrand.trim();
    final barcode = product?.productBarcode.trim();
    final quantifier = product?.productQuantifier?.trim();
    final description = product?.productDescription.trim();
    final availableQty = product?.productQuantity;
    final categoryId = product?.productCategoryId;
    final providerId = product?.productProviderId;

    final details = <_InfoLine>[
      if (brand != null && brand.isNotEmpty)
        _InfoLine(Icons.sell_outlined, loc.itemBrandLabel, brand),
      if (quantifier != null && quantifier.isNotEmpty)
        _InfoLine(Icons.straighten_outlined, loc.itemUnitLabel, quantifier),
      if (barcode != null && barcode.isNotEmpty)
        _InfoLine(Icons.qr_code_2_outlined, loc.itemBarcodeLabel, barcode),
      if (availableQty != null)
        _InfoLine(
          Icons.inventory_outlined,
          loc.itemAvailableLabel,
          '$availableQty',
        ),
      if (categoryId != null)
        _InfoLine(
          Icons.category_outlined,
          loc.itemCategoryLabel,
          '#$categoryId',
        ),
      if (providerId != null)
        _InfoLine(
          Icons.storefront_outlined,
          loc.itemProviderLabel,
          '#$providerId',
        ),
      if (description != null && description.isNotEmpty)
        _InfoLine(Icons.notes_outlined, loc.itemDescriptionLabel, description),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(letter: _initial(name)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 8,
                      runSpacing: 2,
                      children: [
                        _MiniChip(
                          label: '× $qty',
                          color: cs.onSurfaceVariant,
                        ),
                        _MiniChip(
                          label: '@ ${price.toStringAsFixed(2)}',
                          color: cs.onSurfaceVariant,
                        ),
                        if (vat > Decimal.zero)
                          _MiniChip(
                            label: '${loc.vatLabel} ${vat.toStringAsFixed(0)}%',
                            color: cs.primary,
                          ),
                        if (discount > Decimal.zero)
                          _MiniChip(
                            label: '- ${discount.toStringAsFixed(2)}',
                            color: cs.error,
                          ),
                        if (status != null)
                          _MiniChip(
                            label: _statusLabel(status, loc),
                            color: _statusColor(status, cs),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                FinancialUIManager.formatCurrency(lineTotal, context),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: details.map((d) => d.build(context)).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _initial(String s) {
    if (s.isEmpty) return '?';
    return s.trim()[0].toUpperCase();
  }

  static String _statusLabel(String s, AppLocalizations loc) {
    switch (s.toLowerCase()) {
      case 'delivered':
      case 'completed':
        return loc.itemStatusDelivered;
      case 'processing':
        return loc.itemStatusProcessing;
      case 'pending':
        return loc.itemStatusPending;
      case 'cancelled':
      case 'canceled':
        return loc.itemStatusCancelled;
      case 'returned':
        return loc.itemStatusReturned;
      case 'partial':
        return loc.itemStatusPartial;
      default:
        return s.replaceAll('_', ' ');
    }
  }

  static Color _statusColor(String s, ColorScheme cs) {
    switch (s.toLowerCase()) {
      case 'delivered':
      case 'completed':
        return const Color(0xFF1E8E5A);
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

class _InfoLine {
  final IconData icon;
  final String label;
  final String value;
  const _InfoLine(this.icon, this.label, this.value);

  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 12, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String letter;
  const _Avatar({required this.letter});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          color: cs.onPrimaryContainer,
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Services
// ---------------------------------------------------------------------------

class _ServicesCard extends StatelessWidget {
  final BusinessOperation operation;
  const _ServicesCard({required this.operation});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return _Card(
      title: loc.servicesTitle,
      icon: Icons.handyman_outlined,
      trailing: _Pill(
        label: '${operation.serviceCount}',
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      child: Column(
        children:
            operation.services.map((svc) => _ServiceRow(service: svc)).toList(),
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  final BusinessOperationServiceLine service;
  const _ServiceRow({required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;

    // The service payload nests the provided-service snapshot under
    // `service`, but some endpoints inline it directly. Support both
    // shapes so a payload change doesn't silently drop the details.
    final outer = service.providedServiceRaw;
    final provided = outer?['service'] is Map<String, dynamic>
        ? outer!['service'] as Map<String, dynamic>
        : outer;

    final providedName =
        (provided?['provided_service_name'] as String?)?.trim();
    final name = (providedName != null && providedName.isNotEmpty)
        ? providedName
        : loc.serviceFallbackName('${service.orderedServiceServiceId ?? 0}');

    final qty = service.orderedServiceQuantity;

    // `totalPrice` is `Decimal` after the BusinessOperationServiceLine
    // migration. `formatCurrency` receives it directly.
    final Decimal total = service.totalPrice;

    final scheduled = service.scheduledAt;
    final status = service.deliveryStatus;

    // Same two-shape tolerance as above.
    final resourceReqs =
        (provided?['service_resource_requirement'] as List<dynamic>?) ??
            (outer?['service_resource_requirement'] as List<dynamic>?) ??
            const [];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(letter: _initial(name)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 8,
                      runSpacing: 2,
                      children: [
                        _MiniChip(
                          label: '× $qty',
                          color: cs.onSurfaceVariant,
                        ),
                        if (scheduled != null)
                          _MiniChip(
                            label: _shortDate(scheduled),
                            color: cs.onSurfaceVariant,
                          ),
                        if (status != null)
                          _MiniChip(
                            label: _statusLabel(status, loc),
                            color: _statusColor(status, cs),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                FinancialUIManager.formatCurrency(total, context),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          if (resourceReqs.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: resourceReqs.map((r) {
                  final rr = r as Map<String, dynamic>;
                  final consumable = _isTruthy(
                      rr['service_resource_requirement_is_consumable']);
                  final n =
                      rr['service_resource_requirement_name'] as String? ??
                          loc.resourceFallbackName;
                  final q = rr['service_resource_requirement_quantity'];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(
                          consumable
                              ? Icons.local_fire_department_outlined
                              : Icons.build_outlined,
                          size: 12,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '$n × $q',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: (consumable ? cs.secondary : cs.tertiary)
                                .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            consumable
                                ? loc.resourceKindConsumable
                                : loc.resourceKindAmortized,
                            style: TextStyle(
                              color: consumable ? cs.secondary : cs.tertiary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _initial(String s) {
    if (s.isEmpty) return '?';
    return s.trim()[0].toUpperCase();
  }

  static String _shortDate(DateTime d) {
    final local = d.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  static String _statusLabel(String s, AppLocalizations loc) {
    switch (s.toLowerCase()) {
      case 'delivered':
      case 'completed':
        return loc.serviceStatusCompleted;
      case 'scheduled':
        return loc.serviceStatusScheduled;
      case 'in_progress':
        return loc.serviceStatusInProgress;
      case 'processing':
        return loc.serviceStatusProcessing;
      case 'pending':
        return loc.serviceStatusPending;
      case 'cancelled':
      case 'canceled':
        return loc.serviceStatusCancelled;
      case 'no_show':
        return loc.serviceStatusNoShow;
      default:
        return s.replaceAll('_', ' ');
    }
  }

  static Color _statusColor(String s, ColorScheme cs) {
    switch (s.toLowerCase()) {
      case 'delivered':
      case 'completed':
        return const Color(0xFF1E8E5A);
      case 'scheduled':
      case 'processing':
      case 'in_progress':
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

  static bool _isTruthy(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.toLowerCase();
      return s == '1' || s == 'true';
    }
    return false;
  }
}

// ---------------------------------------------------------------------------
// Meta card
// ---------------------------------------------------------------------------

class _MetaCard extends StatelessWidget {
  final BusinessOperation operation;
  const _MetaCard({required this.operation});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (operation.isCart && operation.cart != null) {
      return _Card(
        title: loc.cartDetailsTitle,
        icon: Icons.shopping_cart_outlined,
        child: _cartBlock(context, operation.cart!, loc),
      );
    }
    if (operation.isDelivery && operation.delivery != null) {
      return _Card(
        title: loc.deliveryDetailsTitle,
        icon: Icons.local_shipping_outlined,
        child: _deliveryBlock(context, operation.delivery!, loc),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _cartBlock(
    BuildContext context,
    Map<String, dynamic> m,
    AppLocalizations loc,
  ) {
    // The payload uses `subtotal`, `created_at`, and `updated_at`.
    // The old shape used `cart_total_amount`, `cart_created_at`, and
    // `cart_updated_at`. Try the wire name first, then the legacy one
    // so both responses render.
    final cartTotal =
        m['subtotal'] ?? m['cart_total_amount'] ?? m['cart_subtotal'];
    final createdAt = m['created_at'] ?? m['cart_created_at'];
    final updatedAt = m['updated_at'] ?? m['cart_updated_at'];

    final entries = <_Kv>[
      if (m['cart_id'] != null) _Kv(loc.cartIdLabel, '${m['cart_id']}'),
      if (m['cart_status'] != null)
        _Kv(loc.metaStatusLabel, '${m['cart_status']}'),
      if (cartTotal != null)
        _Kv(loc.totalLabel, _formatMoney(context, cartTotal)),
      if (createdAt != null)
        _Kv(loc.metaCreatedLabel, _formatDateString(createdAt)),
      if (updatedAt != null)
        _Kv(loc.metaUpdatedLabel, _formatDateString(updatedAt)),
    ];

    if (entries.isEmpty) return const SizedBox.shrink();
    return Column(
      children: entries.map((e) => _KvRow(kv: e)).toList(),
    );
  }

  Widget _deliveryBlock(
    BuildContext context,
    Map<String, dynamic> m,
    AppLocalizations loc,
  ) {
    // Payload uses `created_at` / `updated_at`; legacy shape uses the
    // prefixed names.
    final createdAt = m['created_at'] ?? m['delivery_created_at'];
    final updatedAt = m['updated_at'] ?? m['delivery_updated_at'];

    final entries = <_Kv>[
      if (m['id_delivery'] != null)
        _Kv(loc.deliveryIdLabel, '${m['id_delivery']}'),
      if (m['delivery_status'] != null)
        _Kv(loc.metaStatusLabel, '${m['delivery_status']}'),
      if (m['delivery_shipping_method'] != null)
        _Kv(loc.deliveryMethodLabel, '${m['delivery_shipping_method']}'),
      if (m['delivery_fee'] != null)
        _Kv(loc.deliveryFeeLabel, _formatMoney(context, m['delivery_fee'])),
      if (m['delivery_goods_description'] != null)
        _Kv(loc.deliveryGoodsLabel, '${m['delivery_goods_description']}'),
      if (m['delivery_package_count'] != null)
        _Kv(loc.deliveryPackagesLabel, '${m['delivery_package_count']}'),
      if (createdAt != null)
        _Kv(loc.metaCreatedLabel, _formatDateString(createdAt)),
      if (updatedAt != null)
        _Kv(loc.metaUpdatedLabel, _formatDateString(updatedAt)),
    ];

    if (entries.isEmpty) return const SizedBox.shrink();
    return Column(
      children: entries.map((e) => _KvRow(kv: e)).toList(),
    );
  }

  /// Cart / delivery meta reads come from the raw operation payload map,
  /// not from typed fields, so the value can be `num` or `String`. This
  /// path is `double` at the boundary — the raw map doesn't carry
  /// `Decimal`, and there's nothing to make exact here. `formatCurrency`
  /// is expected to accept `num` after the money migration.
  static String _formatMoney(BuildContext context, dynamic v) {
    final d = _toDecimal(v);
    return FinancialUIManager.formatCurrency(d, context);
  }

  static Decimal _toDecimal(dynamic v) {
    if (v == null) return Decimal.zero;
    if (v is Decimal) return v;
    if (v is int) return Decimal.fromInt(v);
    if (v is BigInt) return Decimal.parse(v.toString());
    if (v is double) {
      // Parse via string to avoid binary float artifacts like 0.1 + 0.2.
      return Decimal.tryParse(v.toString()) ?? Decimal.zero;
    }
    return Decimal.tryParse(v.toString()) ?? Decimal.zero;
  }

  static String _formatDateString(dynamic v) {
    if (v is DateTime) {
      final local = v.toLocal();
      return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
          '${local.day.toString().padLeft(2, '0')} '
          '${local.hour.toString().padLeft(2, '0')}:'
          '${local.minute.toString().padLeft(2, '0')}';
    }
    if (v is String) {
      final d = DateTime.tryParse(v);
      if (d != null) return _formatDateString(d);
    }
    return v?.toString() ?? '';
  }
}

class _Kv {
  final String k;
  final String v;
  const _Kv(this.k, this.v);
}

class _KvRow extends StatelessWidget {
  final _Kv kv;
  const _KvRow({required this.kv});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              kv.k,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            kv.v,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared primitives
// ---------------------------------------------------------------------------

class _Card extends StatefulWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _Card({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  State<_Card> createState() => _CardState();
}

class _CardState extends State<_Card> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(widget.icon, size: 16, color: cs.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (widget.trailing != null) ...[
                    widget.trailing!,
                    const SizedBox(width: 6),
                  ],
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
