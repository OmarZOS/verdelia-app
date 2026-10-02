// lib/screens/business_operation_details_screen.dart

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

    final settlementRatio = operation.grandTotal > 0
        ? (operation.paidAmount / operation.grandTotal).clamp(0.0, 1.0)
        : 0.0;

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
                FinancialUIManager.formatCurrency(
                    operation.grandTotal, context),
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

    // Human-readable label per status. The `_unknown` fallback keeps
    // the raw status visible if the backend sends something we don't
    // map yet.
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
  final double paid;
  final double due;
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
              color: due > 0 ? const Color(0xFFFFD27C) : Colors.white70,
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final double value;
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

    final rows = <_MoneyRow>[
      _MoneyRow(loc.productSubtotalLabel, operation.productSubtotal),
      _MoneyRow(loc.serviceSubtotalLabel, operation.serviceSubtotal),
      _MoneyRow(
        loc.grossSubtotalLabel,
        operation.grossSubtotal,
        emphasis: _Emphasis.subtotal,
      ),
      if (operation.discountAmount > 0)
        _MoneyRow(
          loc.discountLabel,
          -operation.discountAmount,
          emphasis: _Emphasis.negative,
        ),
      if (operation.taxAmount > 0) _MoneyRow(loc.taxLabel, operation.taxAmount),
      if (operation.deliveryRevenue > 0)
        _MoneyRow(loc.deliveryLabel, operation.deliveryRevenue),
      _MoneyRow(
        loc.grandTotalLabel,
        operation.grandTotal,
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
  final double value;
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

    final margin = operation.marginAmount;
    final marginColor = margin >= 0 ? const Color(0xFF1E8E5A) : cs.error;
    final cost = operation.totalCost;
    final roi = operation.roi;

    return _Card(
      title: loc.profitabilityTitle,
      icon: Icons.trending_up_rounded,
      trailing: _Pill(
        label: roi == null
            ? '—'
            : '${(roi * 100).toStringAsFixed(1)}% ${loc.roiLabel}',
        color: roi == null
            ? cs.onSurfaceVariant
            : (roi >= 0 ? const Color(0xFF1E8E5A) : cs.error),
      ),
      child: Column(
        children: [
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
          if (cost > 0) ...[
            const SizedBox(height: 8),
            _CostBar(
              productCost: operation.productCost,
              consumable: operation.consumableServiceCost,
              nonConsumable: operation.nonConsumableServiceCost,
              labor: operation.laborCost,
              delivery: operation.deliveryCost,
            ),
          ],
        ],
      ),
    );
  }
}

class _CostBar extends StatelessWidget {
  final double productCost;
  final double consumable;
  final double nonConsumable;
  final double labor;
  final double delivery;

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

    final segments = <_CostSegment>[
      if (productCost > 0)
        _CostSegment(loc.costSegmentProducts, productCost, cs.primary),
      if (consumable > 0)
        _CostSegment(loc.costSegmentConsumables, consumable, cs.secondary),
      if (nonConsumable > 0)
        _CostSegment(loc.costSegmentAmortized, nonConsumable, cs.tertiary),
      if (labor > 0)
        _CostSegment(loc.costSegmentLabor, labor, const Color(0xFF8B6CD9)),
      if (delivery > 0)
        _CostSegment(
            loc.costSegmentDelivery, delivery, const Color(0xFFD08B1C)),
    ];

    final total = segments.fold<double>(0, (s, e) => s + e.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 10,
            child: Row(
              children: segments.map((s) {
                final flex = ((s.value / total) * 1000).round().clamp(1, 1000);
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
  final double value;
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
  final Map<String, dynamic> item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;

    final product = item['ordered_product'] as Map<String, dynamic>?;
    final name = product?['product_name'] as String? ??
        loc.productFallbackName('${item['ordered_product_id']}');
    final qty = (item['ordered_quantity'] as num?)?.toInt() ?? 0;
    final price = (item['unit_price'] as num?)?.toDouble() ?? 0;
    final vat = (item['applied_vat'] as num?)?.toDouble() ?? 0;
    final status = item['ordered_item_delivery_status'] as String?;

    final lineTotal = qty * price;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
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
                    if (vat > 0)
                      _MiniChip(
                        label: '${loc.vatLabel} ${vat.toStringAsFixed(0)}%',
                        color: cs.primary,
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
  final Map<String, dynamic> service;
  const _ServiceRow({required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;

    final provided =
        service['ordered_service_service'] as Map<String, dynamic>?;
    final name = provided?['provided_service_name'] as String? ??
        loc.serviceFallbackName('${service['ordered_service_service_id']}');
    final qty = (service['ordered_service_quantity'] as num?)?.toInt() ?? 0;
    final total =
        (service['ordered_service_total_price'] as num?)?.toDouble() ?? 0;
    final scheduled = service['ordered_service_scheduled_at'] as String?;
    final status = service['ordered_service_delivery_status'] as String?;

    final resourceReqs =
        (provided?['service_resource_requirement'] as List<dynamic>?) ??
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
                  final consumable =
                      rr['service_resource_requirement_is_consumable'] == 1 ||
                          rr['service_resource_requirement_is_consumable'] ==
                              true;
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

  static String _shortDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
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
        child: _kvBlock(operation.cart!, loc),
      );
    }
    if (operation.isDelivery && operation.delivery != null) {
      return _Card(
        title: loc.deliveryDetailsTitle,
        icon: Icons.local_shipping_outlined,
        child: _kvBlock(operation.delivery!, loc),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _kvBlock(Map<String, dynamic> m, AppLocalizations loc) {
    final entries = <_Kv>[
      if (m['id_delivery'] != null)
        _Kv(loc.deliveryIdLabel, '${m['id_delivery']}'),
      if (m['delivery_status'] != null)
        _Kv(loc.metaStatusLabel, '${m['delivery_status']}'),
      if (m['delivery_shipping_method'] != null)
        _Kv(loc.deliveryMethodLabel, '${m['delivery_shipping_method']}'),
      if (m['delivery_fee'] != null)
        _Kv(loc.deliveryFeeLabel, '${m['delivery_fee']}'),
      if (m['cart_id'] != null) _Kv(loc.cartIdLabel, '${m['cart_id']}'),
      if (m['cart_status'] != null)
        _Kv(loc.metaStatusLabel, '${m['cart_status']}'),
      if (m['cart_total_amount'] != null)
        _Kv(loc.totalLabel, '${m['cart_total_amount']}'),
      if (m['cart_created_at'] != null)
        _Kv(loc.metaCreatedLabel, '${m['cart_created_at']}'),
      if (m['delivery_created_at'] != null)
        _Kv(loc.metaCreatedLabel, '${m['delivery_created_at']}'),
    ];

    return Column(
      children: entries.map((e) => _KvRow(kv: e)).toList(),
    );
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
