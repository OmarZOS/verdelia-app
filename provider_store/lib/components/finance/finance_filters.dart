import 'package:flutter/material.dart';
import 'package:verdelia_core/business/finance/FinancialDocument.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

/// Date filter values used by the finance screen.
///
/// Keep in sync with the `switch` in `FinanceViewModel._applyDateFilter`.

class DateFilterSelector extends StatefulWidget {
  final DateFilter selectedFilter;
  final ValueChanged<DateFilter> onFilterChanged;

  const DateFilterSelector({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  State<DateFilterSelector> createState() => _DateFilterSelectorState();
}

class _DateFilterSelectorState extends State<DateFilterSelector> {
  static const _filters = <DateFilter>[
    DateFilter.today,
    DateFilter.week,
    DateFilter.month,
    DateFilter.quarter,
    DateFilter.year,
    DateFilter.all,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((filter) {
            final isSelected = widget.selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                label: Text(
                  _labelFor(filter, loc),
                  style: TextStyle(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected && filter != widget.selectedFilter) {
                    widget.onFilterChanged(filter);
                  }
                },
                showCheckmark: false,
                backgroundColor: theme.colorScheme.surfaceVariant,
                selectedColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withOpacity(0.3),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _labelFor(DateFilter filter, AppLocalizations loc) {
    switch (filter) {
      case DateFilter.today:
        return loc.today;
      case DateFilter.week:
        return loc.thisWeek;
      case DateFilter.month:
        return loc.thisMonth;
      case DateFilter.quarter:
        return loc.thisQuarter;
      case DateFilter.year:
        return loc.thisYear;
      case DateFilter.all:
        return loc.allTime;
    }
  }
}
