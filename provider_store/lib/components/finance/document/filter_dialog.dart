// lib/views/finance/widgets/filter_dialog.dart
import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:event/finance_change_notifier.dart';
import 'package:ui/components/finance/financial_ui_manager.dart';

class FilterDialog extends StatefulWidget {
  final FinanceChangeNotifier notifier;

  const FilterDialog({super.key, required this.notifier});

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    localizations.filteredTxt,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Document type filter
              Text(
                'Document Type',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                children: [
                  _buildDialogFilterChip(
                    'All',
                    widget.notifier.filter.documentType == null,
                    () => setState(() {
                      widget.notifier.setFilter(
                          widget.notifier.filter.copyWith(documentType: null));
                    }),
                  ),
                  _buildDialogFilterChip(
                    'Invoices',
                    widget.notifier.filter.documentType == 'invoice',
                    () => setState(() {
                      widget.notifier.setFilter(widget.notifier.filter
                          .copyWith(documentType: 'invoice'));
                    }),
                  ),
                  _buildDialogFilterChip(
                    'Deposits',
                    widget.notifier.filter.documentType == 'deposit',
                    () => setState(() {
                      widget.notifier.setFilter(widget.notifier.filter
                          .copyWith(documentType: 'deposit'));
                    }),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Status filter
              Text(
                'Payment Status',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildDialogFilterChip(
                    'All',
                    widget.notifier.filter.status == null,
                    () => setState(() {
                      widget.notifier.setFilter(
                          widget.notifier.filter.copyWith(status: null));
                    }),
                  ),
                  _buildDialogFilterChip(
                    'Paid',
                    widget.notifier.filter.status == 'paid',
                    () => setState(() {
                      widget.notifier.setFilter(
                          widget.notifier.filter.copyWith(status: 'paid'));
                    }),
                  ),
                  _buildDialogFilterChip(
                    'Unpaid',
                    widget.notifier.filter.status == 'unpaid',
                    () => setState(() {
                      widget.notifier.setFilter(
                          widget.notifier.filter.copyWith(status: 'unpaid'));
                    }),
                  ),
                  _buildDialogFilterChip(
                    'Overdue',
                    widget.notifier.filter.status == 'overdue',
                    () => setState(() {
                      widget.notifier.setFilter(
                          widget.notifier.filter.copyWith(status: 'overdue'));
                    }),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        widget.notifier.clearFilter();
                        Navigator.pop(context);
                      },
                      child: Text(localizations.clearAll),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(localizations.apply),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDialogFilterChip(
      String label, bool selected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: selected
          ? FinancialUIManager.infoColor.withOpacity(0.1)
          : Colors.grey.withOpacity(0.1),
      selectedColor: FinancialUIManager.infoColor.withOpacity(0.2),
      checkmarkColor: FinancialUIManager.infoColor,
      labelStyle: TextStyle(
        color: selected ? FinancialUIManager.infoColor : Colors.grey,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
