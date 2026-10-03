import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

class CategoryPicker extends StatefulWidget {
  final ValueChanged<int> onCategoryChanged;
  final List<String> categories;
  final List<int>? categoryIds;
  final int category_id;
  final Function pathFunction;
  final String package;

  const CategoryPicker({
    super.key,
    required this.onCategoryChanged,
    required this.categories,
    this.categoryIds,
    required this.pathFunction,
    required this.category_id,
    required this.package,
  });

  @override
  State<CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<CategoryPicker> {
  late int _selectedCategoryIndex;
  final double _itemHeight = 58.0;
  final double _pickerHeight = 200.0;

  @override
  void initState() {
    super.initState();
    final selectedIndex = widget.categoryIds?.indexOf(widget.category_id) ??
        widget.category_id - 1;
    _selectedCategoryIndex = selectedIndex < 0 ? 0 : selectedIndex;
  }

  int _categoryIdAt(int index) => widget.categoryIds?[index] ?? index + 1;

  @override
  void didUpdateWidget(covariant CategoryPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryIds != widget.categoryIds ||
        oldWidget.categories != widget.categories) {
      final selectedIndex = widget.categoryIds?.indexOf(widget.category_id) ??
          widget.category_id - 1;
      _selectedCategoryIndex = selectedIndex < 0 ? 0 : selectedIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => _showEnhancedPicker(context),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SvgPicture.asset(
              widget.pathFunction(_categoryIdAt(_selectedCategoryIndex)),
              // 'assets/icons/${_selectedCategoryIndex + 1}.svg',
              color: theme.colorScheme.primary,
              width: 32,
              height: 32,
              package: widget.package,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.categoryText,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.categories[_selectedCategoryIndex],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: theme.textTheme.bodyLarge!.fontSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEnhancedPicker(BuildContext context) async {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    await showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        minHeight: 300, // This sets the height to half of screen
      ),
      builder: (context) => SizedBox(
        height: _pickerHeight + MediaQuery.of(context).padding.bottom,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    loc.categoryText,
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
            ),
            const Divider(height: 1),
            Expanded(
              child: ListWheelScrollView(
                itemExtent: _itemHeight,
                diameterRatio: 1.5,
                perspective: 0.005,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (index) {
                  setState(() => _selectedCategoryIndex = index);
                },
                children:
                    List<Widget>.generate(widget.categories.length, (index) {
                  return Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: _selectedCategoryIndex == index
                            ? theme.colorScheme.primary.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            widget.pathFunction(_categoryIdAt(index)),
                            // 'assets/icons/${index + 1}.svg',
                            color: theme.colorScheme.primary,
                            width: 24,
                            height: 24,
                            package: widget.package,
                            // "product_catalog"
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              widget.categories[index],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: _selectedCategoryIndex == index
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16).copyWith(
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  widget.onCategoryChanged(
                    _categoryIdAt(_selectedCategoryIndex),
                  );
                  Navigator.pop(context);
                },
                child: Text(loc.confirm),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
