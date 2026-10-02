// lib/ui/components/business_operations/business_operations_filters.dart

import 'package:event/views/business_ops_notifier.dart';
import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class BusinessOperationsFilters extends StatelessWidget {
  const BusinessOperationsFilters({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    final notifier = context.watch<BusinessOperationNotifier>();

    final hasWindow = notifier.dateFrom != null || notifier.dateTo != null;
    final hasSupplierFilter = notifier.supplierId > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(color: cs.outline.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          _FilterChip(
            label: loc.sourceDistribution, // reusing "source" label
            value: _sourceValue(notifier),
            items: const [
              FilterItem(null, 'All'),
              FilterItem('cart', 'Carts'),
              FilterItem('delivery', 'Orders'),
            ],
            onChanged: (value) {
              // The new envelope doesn't accept a source filter server-side,
              // so a source filter is purely a client concern. For now, do
              // nothing here — the badge on each row already distinguishes
              // cart vs delivery, and the pie chart is filtered by the
              // backend's supplier/client/date axes.
              //
              // If you later add a source filter to the backend, wire it to
              // notifier.setSourceType(value).
            },
          ),
          const SizedBox(width: 8),
          _DateRangeChip(notifier: notifier),
          const Spacer(),
          if (hasWindow)
            TextButton.icon(
              onPressed: () {
                if (hasWindow) {
                  notifier.clearDateRange();
                }
              },
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: Icon(Icons.clear_all, size: 14, color: cs.error),
              label: Text(
                loc.clearFilters,
                style: TextStyle(
                  fontSize: 13,
                  color: cs.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String? _sourceValue(BusinessOperationNotifier n) => null;
}

// ---------------------------------------------------------------------------
// Date range chip
// ---------------------------------------------------------------------------

class _DateRangeChip extends StatelessWidget {
  const _DateRangeChip({required this.notifier});

  final BusinessOperationNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final from = notifier.dateFrom;
    final to = notifier.dateTo;
    final hasWindow = from != null || to != null;

    final label = hasWindow
        ? '${_fmt(from)} → ${_fmt(to)}'
        : AppLocalizations.of(context)!.all;

    return GestureDetector(
      onTap: () => _pickRange(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceVariant.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.date_range_outlined,
                size: 14, color: cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 16, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  static String _fmt(DateTime? d) {
    if (d == null) return '—';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: (notifier.dateFrom != null && notifier.dateTo != null)
          ? DateTimeRange(start: notifier.dateFrom!, end: notifier.dateTo!)
          : null,
      helpText: 'Select date range',
    );
    if (picked == null) return;
    await notifier.setDateRange(picked.start, picked.end);
  }
}

// ---------------------------------------------------------------------------
// Filter chip primitive (reused from your original, minus the modal sheet)
// ---------------------------------------------------------------------------

class _FilterChip extends StatelessWidget {
  final String label;
  final String? value;
  final List<FilterItem> items;
  final ValueChanged<String?> onChanged;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final selected = items.firstWhere(
      (item) => item.value == value,
      orElse: () => items.first,
    );

    return GestureDetector(
      onTap: () => _showFilterSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceVariant.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_alt_outlined,
                size: 14, color: cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              '$label: ${selected.displayLabel}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 16, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ...items.map((item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Radio<String?>(
                    value: item.value,
                    groupValue: value,
                    onChanged: (v) {
                      onChanged(v);
                      Navigator.pop(context);
                    },
                    activeColor: cs.primary,
                  ),
                  title: Text(
                    item.displayLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface,
                      fontWeight: item.value == value ? FontWeight.w600 : null,
                    ),
                  ),
                  onTap: () {
                    onChanged(item.value);
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class FilterItem {
  final String? value;
  final String displayLabel;

  const FilterItem(this.value, this.displayLabel);
}
