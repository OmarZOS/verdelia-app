// lib/ui/components/business_operations/business_operations_stats.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/business/finance/BusinessOperation.dart';
import 'package:ui/components/finance/financial_ui_manager.dart';

/// Stats panel for the business operations screen.
///
/// Reads the pre-aggregated [BusinessOperationsStatsData] the backend ships
/// in the response envelope. The quick-stats block is authoritative —
/// the backend aggregated over the whole filtered window, not just the
/// current page. The distribution chart is derived locally from the page's
/// operations, because the envelope's bucket aggregates are not chart-ready.
class BusinessOperationsStats extends StatelessWidget {
  /// The authoritative aggregate from the envelope. When null, the widget
  /// renders a compact placeholder. Do not synthesize a fallback from
  /// [operations] — page-level numbers are not the dashboard numbers.
  final BusinessOperationsStatsData? stats;

  /// Current page of operations. Used only for the source-distribution chart.
  final List<BusinessOperation> operations;

  const BusinessOperationsStats({
    super.key,
    required this.stats,
    required this.operations,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          _QuickStats(stats: stats, localizations: loc),
          const SizedBox(height: 16),
          _DistributionCharts(
            operations: operations,
            localizations: loc,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick stats — authoritative totals from the envelope
// ---------------------------------------------------------------------------

class _QuickStats extends StatelessWidget {
  final BusinessOperationsStatsData? stats;
  final AppLocalizations localizations;

  const _QuickStats({
    required this.stats,
    required this.localizations,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // No stats in the envelope: render a neutral placeholder that matches
    // the real card's shape so the layout doesn't jump.
    if (stats == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant.withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              Icons.query_stats,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Statistics unavailable',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      );
    }

    final totals = stats!.totals;
    final ratios = stats!.ratios;

    // Collection rate is the right "progress ring" number: paid / (paid + due).
    final collectionRate = ratios.collectionRate ?? 0.0;
    final paidPercentage = (collectionRate * 100).clamp(0, 100).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withOpacity(0.08),
            colorScheme.surfaceVariant.withOpacity(0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CircularProgress(
                value: paidPercentage / 100,
                label: '${paidPercentage.toStringAsFixed(1)}%',
                color: colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatRow(
                      label: localizations.totalAmount,
                      value: _fmt(totals.grandTotal, context),
                      color: colorScheme.onSurface,
                    ),
                    const SizedBox(height: 8),
                    _StatRow(
                      label: localizations.totalPaid,
                      value: _fmt(totals.paidAmount, context),
                      color: Colors.green,
                    ),
                    const SizedBox(height: 8),
                    _StatRow(
                      label: localizations.outstanding,
                      value: _fmt(totals.dueAmount, context),
                      color:
                          totals.dueAmount > 0 ? Colors.orange : Colors.green,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          // Secondary metrics row: margin + ROI + avg ticket + ops count.
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Margin',
                  value: _fmt(totals.marginAmount, context),
                  color: totals.marginAmount >= 0
                      ? Colors.green
                      : colorScheme.error,
                ),
              ),
              Expanded(
                child: _MetricTile(
                  label: 'ROI',
                  value: _fmtPercent(ratios.overallRoi),
                  color: (ratios.overallRoi ?? 0) >= 0
                      ? Colors.green
                      : colorScheme.error,
                ),
              ),
              Expanded(
                child: _MetricTile(
                  label: 'Avg Ticket',
                  value: _fmt(ratios.averageTicket, context),
                  color: colorScheme.onSurface,
                ),
              ),
              Expanded(
                child: _MetricTile(
                  label: 'Operations',
                  value: '${stats!.counts.operations}',
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircularProgress extends StatelessWidget {
  final double value;
  final String label;
  final Color color;

  const _CircularProgress({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 70,
          height: 70,
          child: CircularProgressIndicator(
            value: value,
            strokeWidth: 8,
            backgroundColor: color.withOpacity(0.1),
            color: color,
            strokeCap: StrokeCap.round,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Distribution chart — derived from the current page of operations
// ---------------------------------------------------------------------------

class _DistributionCharts extends StatelessWidget {
  final List<BusinessOperation> operations;
  final AppLocalizations localizations;

  const _DistributionCharts({
    required this.operations,
    required this.localizations,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final distribution = _calculateSourceDistribution();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.pie_chart_outline,
                size: 18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                localizations.sourceDistribution,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _PieChartWithLegend(
            distribution: distribution,
            localizations: localizations,
          ),
        ],
      ),
    );
  }

  Map<String, double> _calculateSourceDistribution() {
    final distribution = <String, double>{};
    for (final op in operations) {
      final key = op.sourceType; // 'cart' | 'delivery'
      distribution.update(
        key,
        (v) => v + op.grandTotal,
        ifAbsent: () => op.grandTotal,
      );
    }
    return distribution;
  }
}

class _PieChartWithLegend extends StatelessWidget {
  final Map<String, double> distribution;
  final AppLocalizations localizations;

  const _PieChartWithLegend({
    required this.distribution,
    required this.localizations,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final total = distribution.values.fold(0.0, (sum, v) => sum + v);

    if (distribution.isEmpty || total <= 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(
                Icons.pie_chart,
                size: 48,
                color: colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 12),
              Text(
                localizations.noDataAvailable,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    final pieSections = <PieChartSectionData>[];
    final legendItems = <_LegendItemData>[];

    final colors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      Colors.amber,
      Colors.teal,
      Colors.purple,
    ];

    int colorIndex = 0;
    distribution.forEach((key, value) {
      final percentage = total > 0 ? (value / total * 100) : 0.0;
      final color = colors[colorIndex % colors.length];

      pieSections.add(
        PieChartSectionData(
          value: value,
          color: color,
          radius: 60,
          title: '${percentage.toStringAsFixed(1)}%',
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          titlePositionPercentageOffset: 0.6,
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
      );

      legendItems.add(_LegendItemData(
        label: _localizedSourceName(key, localizations),
        value: value,
        percentage: percentage,
        color: color,
      ));

      colorIndex++;
    });

    return Row(
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: PieChart(
              PieChartData(
                sections: pieSections,
                centerSpaceRadius: 40,
                startDegreeOffset: -90,
                sectionsSpace: 2,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {},
                ),
              ),
              swapAnimationDuration: const Duration(milliseconds: 300),
              swapAnimationCurve: Curves.easeInOut,
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: legendItems
                .map((item) => _LegendItem(data: item, showValue: true))
                .toList(),
          ),
        ),
      ],
    );
  }

  String _localizedSourceName(String source, AppLocalizations loc) {
    switch (source.toLowerCase()) {
      case 'cart':
        return loc.cart;
      case 'delivery':
        return loc.order;
      default:
        return source;
    }
  }
}

class _LegendItemData {
  final String label;
  final double value;
  final double percentage;
  final Color color;

  _LegendItemData({
    required this.label,
    required this.value,
    required this.percentage,
    required this.color,
  });
}

class _LegendItem extends StatelessWidget {
  final _LegendItemData data;
  final bool showValue;

  const _LegendItem({
    required this.data,
    this.showValue = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: data.color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (showValue)
                  Text(
                    '${_fmt(data.value, context)} • '
                    '${data.percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

String _fmt(double v, BuildContext context) =>
    FinancialUIManager.formatCurrency(v, context);

String _fmtPercent(double? v) {
  if (v == null) return '—';
  return '${(v * 100).toStringAsFixed(1)}%';
}
