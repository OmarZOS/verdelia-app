// components/category_dropdown.dart
import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/business/finance/ProvidedService.dart';
import 'package:ui/components/hierarchical_category_picker.dart';

class CategoryDropdown extends StatelessWidget {
  final List<ProvidedServiceCategory> categories;
  final int selectedCategoryId;
  final bool isLoading;
  final void Function(int?) onChanged;

  const CategoryDropdown({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.isLoading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final localizations = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Row(
            children: [
              Text(
                'Category',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colors.onSurface,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  '*',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.error,
                  ),
                ),
              ),
              if (isLoading)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        FormField<int>(
          initialValue: selectedCategoryId == 0 ? null : selectedCategoryId,
          validator: (value) =>
              value == null || value == 0 ? 'Please select a category' : null,
          builder: (field) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HierarchicalCategoryPicker(
                label: localizations.category,
                showLabel: false,
                options: categories
                    .map(
                      (category) => HierarchicalCategoryOption(
                        id: category.id,
                        path: category.name,
                        leafLabel: category.nameFor(languageCode),
                      ),
                    )
                    .toList(),
                selectedId: field.value ?? selectedCategoryId,
                onChanged: (id) {
                  field.didChange(id.leafId);
                  onChanged(id.leafId);
                },
              ),
              if (field.errorText != null)
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 6),
                  child: Text(
                    field.errorText!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
