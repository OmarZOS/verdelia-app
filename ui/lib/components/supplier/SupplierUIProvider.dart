import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:event/supplier_change_notifier.dart';
import 'package:provider/provider.dart';
import 'package:ui/components/hierarchical_category_picker.dart';
import 'package:ui/utils/category_hierarchy.dart';

/// 供应商UI提供者 - 基于实际供应商分类，仅使用ColorScheme颜色
class SupplierUIProvider {
  // 单例实例
  static final SupplierUIProvider _instance = SupplierUIProvider._internal();
  factory SupplierUIProvider() => _instance;
  SupplierUIProvider._internal();

  // ==================== 供应商分类配置 (基于你的数据) ====================

  /// 供应商分类定义 (ID -> 配置)
  static final Map<int, SupplierCategoryConfig> _supplierCategories = {
    0: SupplierCategoryConfig(
      id: 0,
      key: 'all',
      name: 'All',
      icon: Icons.all_inclusive_rounded,
      svgAsset: null,
      priority: 0,
      description: 'All supplier categories',
    ),
    1: SupplierCategoryConfig(
      id: 1,
      key: 'restaurant',
      name: 'Restaurant',
      icon: Icons.restaurant_rounded,
      // svgAsset: 'assets/icons/supplier_restaurant.svg',
      priority: 1,
      description: 'Restaurants and food services',
    ),
    2: SupplierCategoryConfig(
      id: 2,
      key: 'bakery',
      name: 'Bakery',
      icon: Icons.bakery_dining_rounded,
      // svgAsset: 'assets/icons/supplier_bakery.svg',
      priority: 2,
      description: 'Bakeries and pastry shops',
    ),
    3: SupplierCategoryConfig(
      id: 3,
      key: 'factory',
      name: 'Factory',
      icon: Icons.factory_rounded,
      // svgAsset: 'assets/icons/supplier_factory.svg',
      priority: 3,
      description: 'Manufacturing factories',
    ),
    4: SupplierCategoryConfig(
      id: 4,
      key: 'supermarket',
      name: 'Supermarket',
      icon: Icons.storefront_rounded,
      // svgAsset: 'assets/icons/supplier_supermarket.svg',
      priority: 4,
      description: 'Supermarkets and hypermarkets',
    ),
    5: SupplierCategoryConfig(
      id: 5,
      key: 'grocery_store',
      name: 'Grocery Store',
      icon: Icons.local_grocery_store_rounded,
      // svgAsset: 'assets/icons/supplier_grocery.svg',
      priority: 5,
      description: 'Grocery stores and convenience stores',
    ),
    6: SupplierCategoryConfig(
      id: 6,
      key: 'distributor',
      name: 'Distributor',
      icon: Icons.local_shipping_rounded,
      // svgAsset: 'assets/icons/supplier_distributor.svg',
      priority: 6,
      description: 'Wholesale distributors',
    ),
  };

  // ==================== 公共方法 ====================

  /// 根据分类ID获取配置
  SupplierCategoryConfig getCategoryConfig(int categoryId) {
    return _supplierCategories[categoryId] ?? _supplierCategories[0]!;
  }

  /// 获取所有可用的分类ID
  List<int> getAllCategoryIds() {
    return _supplierCategories.keys.where((id) => id > 0).toList();
  }

  /// 获取实际存在的分类ID（从你的数据库数据中）
  List<int> getExistingCategoryIds() {
    return [1, 2, 3, 4, 5, 6]; // 你的实际分类ID
  }

  /// 获取本地化的分类名称
  String getLocalizedCategoryName(int categoryId, AppLocalizations l10n) {
    final config = getCategoryConfig(categoryId);
    return _getLocalizedName(config.key, l10n);
  }

  /// 获取分类英文名称（用于显示或调试）
  String getCategoryEnglishName(int categoryId) {
    return getCategoryConfig(categoryId).name;
  }

  /// 获取分类图标
  IconData getCategoryIcon(int categoryId) {
    return getCategoryConfig(categoryId).icon;
  }

  /// 获取分类SVG图标路径
  String? getCategorySvgPath(int categoryId) {
    return getCategoryConfig(categoryId).svgAsset;
  }

  /// 获取分类描述
  String getCategoryDescription(int categoryId) {
    return getCategoryConfig(categoryId).description;
  }

  // ==================== UI 组件生成器 ====================

  /// 生成分类芯片组件
  Widget buildCategoryChip({
    required BuildContext context,
    required int categoryId,
    required bool isSelected,
    required VoidCallback onTap,
    bool showIcon = true,
    bool showLabel = true,
    bool compact = false,
    bool useSvg = true,
    bool showEnglishName = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final config = getCategoryConfig(categoryId);

    // 确定显示的文本
    final displayText = showEnglishName
        ? config.name
        : getLocalizedCategoryName(categoryId, l10n);

    // 未选中状态的颜色
    final unselectedBackground = colorScheme.surfaceVariant;
    final unselectedBorder = colorScheme.outline.withOpacity(0.3);
    final unselectedText = colorScheme.onSurfaceVariant;
    final unselectedIcon = colorScheme.onSurfaceVariant;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected ? colorScheme.primary : unselectedBackground,
        borderRadius: BorderRadius.circular(compact ? 16 : 20),
        border: Border.all(
          color: isSelected ? colorScheme.primary : unselectedBorder,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(compact ? 16 : 20),
        child: InkWell(
          borderRadius: BorderRadius.circular(compact ? 16 : 20),
          onTap: onTap,
          child: Padding(
            padding: compact
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showIcon) ...[
                  _buildCategoryIcon(
                    categoryId: categoryId,
                    context: context,
                    isSelected: isSelected,
                    useSvg: useSvg,
                    compact: compact,
                  ),
                  if (showLabel) const SizedBox(width: 8),
                ],
                if (showLabel) ...[
                  Selector<SupplierChangeNotifier, String>(
                    selector: (_, notifier) {
                      if (showEnglishName || categoryId == 0) return '';
                      final matchingCategories =
                          notifier.supplierCategories.where(
                        (category) =>
                            category.productProviderTypeId == categoryId,
                      );
                      if (matchingCategories.isEmpty) return '';
                      final category = matchingCategories.first;
                      return localizedCategoryHierarchy(
                        categoryPath: category.productCategoryDesc,
                        localizedLeaf: category.nameFor(languageCode),
                        localizations: l10n,
                      );
                    },
                    builder: (context, categoryLabel, _) => Text(
                      categoryLabel.isNotEmpty ? categoryLabel : displayText,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color:
                            isSelected ? colorScheme.onPrimary : unselectedText,
                        fontWeight: FontWeight.w600,
                        fontSize: compact ? 12 : 14,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建分类图标
  Widget _buildCategoryIcon({
    required int categoryId,
    required BuildContext context,
    required bool isSelected,
    required bool useSvg,
    required bool compact,
  }) {
    final config = getCategoryConfig(categoryId);
    final colorScheme = Theme.of(context).colorScheme;
    final size = compact ? 16.0 : 20.0;

    // 图标颜色：选中时用onPrimary，未选中时用onSurfaceVariant
    final iconColor =
        isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant;

    // 如果是"全部"分类，使用Material Icon
    if (categoryId == 0) {
      return Icon(
        config.icon,
        size: size,
        color: iconColor,
      );
    }

    // 如果使用SVG且有SVG资源
    if (useSvg && config.svgAsset != null) {
      try {
        return SvgPicture.asset(
          config.svgAsset!,
          width: size,
          height: size,
          colorFilter: ColorFilter.mode(
            iconColor,
            BlendMode.srcIn,
          ),
        );
      } catch (e) {
        // 如果SVG加载失败，回退到Material Icon
        return Icon(
          config.icon,
          size: size,
          color: iconColor,
        );
      }
    }

    // 使用Material Icon
    return Icon(
      config.icon,
      size: size,
      color: iconColor,
    );
  }

  /// 生成分类筛选器行（基于实际存在的分类）
  Widget buildCategoryFilterRow({
    required BuildContext context,
    required List<int> availableCategoryIds,
    required int? selectedCategoryId,
    required ValueChanged<CategorySelection> onCategoryChanged,
    String? selectedDomain,
    String? selectedSubdomain,
    bool showAllOption = true,
    bool scrollable = true,
    ScrollController? scrollController,
    bool showEnglishNames = false,
  }) {
    final categoryIdsToShow = availableCategoryIds.isNotEmpty
        ? availableCategoryIds
        : getExistingCategoryIds();

    final supplierCategories = context
        .watch<SupplierChangeNotifier>()
        .supplierCategories
        .where((category) =>
            categoryIdsToShow.contains(category.productProviderTypeId))
        .toList();

    final languageCode = Localizations.localeOf(context).languageCode;
    final localizations = AppLocalizations.of(context)!;

    return HierarchicalCategoryPicker(
      label: localizations.categoryText,
      options: supplierCategories
          .map(
            (category) => HierarchicalCategoryOption(
              id: category.productProviderTypeId,
              path: category.productCategoryDesc,
              leafLabel: category.nameFor(
                showEnglishNames ? 'en' : languageCode,
              ),
            ),
          )
          .toList(),
      selectedId: selectedCategoryId ?? 0,
      selectedDomain: selectedDomain,
      selectedSubdomain: selectedSubdomain,
      allowAllOption: showAllOption,
      allLabel: localizations.allText,
      onChanged: onCategoryChanged,
      showLabel: false,
    );
  }

  /// 生成搜索栏组件
  Widget buildSearchBar({
    required BuildContext context,
    required TextEditingController controller,
    required String query,
    required ValueChanged<String> onChanged,
    FocusNode? focusNode,
    VoidCallback? onClear,
    String? hintText,
    double height = 48,
    EdgeInsetsGeometry? padding,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(
            Icons.search_rounded,
            color: colorScheme.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                height: 1.2,
              ),
              decoration: InputDecoration(
                hintText: hintText ?? l10n.searchSuppliersText,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.2,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: padding ?? EdgeInsets.zero,
              ),
            ),
          ),
          if (query.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.clear_rounded,
                color: colorScheme.onSurfaceVariant,
                size: 18,
              ),
              onPressed: onClear,
              splashRadius: 16,
            ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  /// 生成供应商卡片中的分类标签（也使用ColorScheme颜色）
  Widget buildSupplierCategoryTag({
    required BuildContext context,
    required int categoryId,
    bool showIcon = true,
    bool compact = true,
  }) {
    final config = getCategoryConfig(categoryId);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              config.icon,
              size: compact ? 12 : 14,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            config.name,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: compact ? 10 : 12,
                ),
          ),
        ],
      ),
    );
  }

  static Future<String> getSupplierText(int supplierId, String supplierLabel,
      SupplierChangeNotifier supplierNotifier) async {
    try {
      final supplier = await supplierNotifier.getSupplierById(
        supplierId,
        forceRefresh: false,
        // notify: false,
      );

      final supplierName = supplier?.providerName.trim() ?? '';

      return supplierName.isNotEmpty ? '$supplierName' : supplierLabel;
    } catch (e) {
      debugPrint('Error getting supplier name: $e');
      return supplierLabel;
    }
  }

  // ==================== 私有辅助方法 ====================

  /// 获取本地化名称
  String _getLocalizedName(String key, AppLocalizations l10n) {
    switch (key) {
      case 'all':
        return l10n.allText;
      case 'restaurant':
        return l10n.supplierCategoryRestaurant;
      case 'bakery':
        return l10n.supplierCategoryBakery;
      case 'factory':
        return l10n.supplierCategoryFactory;
      case 'supermarket':
        return l10n.supplierCategorySupermarket;
      case 'grocery_store':
        return l10n.supplierCategoryGroceryStore;
      case 'distributor':
        return l10n.supplierCategoryDistributor;
      default:
        return key.replaceAll('_', ' ');
    }
  }
}

/// 供应商分类配置模型
class SupplierCategoryConfig {
  final int id;
  final String key;
  final String name;
  final IconData icon;
  final String? svgAsset;
  final int priority;
  final String description;

  const SupplierCategoryConfig({
    required this.id,
    required this.key,
    required this.name,
    required this.icon,
    this.svgAsset,
    required this.priority,
    required this.description,
  });
}
