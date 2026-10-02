// components/category_dropdown.dart
import 'package:flutter/material.dart';
import 'package:verdelia_core/business/finance/ProvidedService.dart';

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
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: DropdownButtonFormField<int>(
            value:
                categories.any((category) => category.id == selectedCategoryId)
                    ? selectedCategoryId
                    : null,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
            ),
            hint: Text(
              isLoading ? 'Loading categories...' : 'Select a category',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant.withOpacity(0.6),
              ),
            ),
            items: categories
                .map((category) => DropdownMenuItem<int>(
                      value: category.id,
                      child: Text(
                        category.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                    ))
                .toList(),
            validator: (value) {
              if (value == null || value == 0) {
                return 'Please select a category';
              }
              return null;
            },
            onChanged: onChanged,
            disabledHint:
                isLoading ? const Text('Loading categories...') : null,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface,
            ),
            icon: Icon(
              Icons.arrow_drop_down,
              color: colors.onSurfaceVariant,
            ),
            dropdownColor: colors.surface,
            isExpanded: true,
          ),
        ),
      ],
    );
  }
}
