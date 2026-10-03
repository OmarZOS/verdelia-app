// lib/ui/supplier_product_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:event/product_change_notifier.dart';
import 'package:provider/provider.dart';
import 'package:ui/utils/category_hierarchy.dart';
import 'package:ui/components/image/image_url.dart';

class SupplierProductCard extends StatelessWidget {
  final Product product;
  final String supplierName;
  final int stockQuantity;
  final String minOrderQty;
  final VoidCallback? onTap;

  const SupplierProductCard({
    Key? key,
    required this.product,
    required this.supplierName,
    required this.stockQuantity,
    required this.minOrderQty,
    this.onTap,
  }) : super(key: key);

  /// Prefer the seller's own image (first entry in the gallery); fall
  /// back to the linked IProduct's reference image when the gallery is
  /// empty or its primary URL is malformed.
  String? _resolvedImageUrl() {
    return resolveImageUrl(product.primaryImageUrl) ??
        resolveImageUrl(product.product_origin?.iproductImageUrl);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final isLowStock = stockQuantity < 5;
    final isOutOfStock = stockQuantity < 15;
    final priceColor = isOutOfStock
        ? theme.colorScheme.error.withOpacity(0.7)
        : isLowStock
            ? theme.colorScheme.error
            : theme.colorScheme.primary;

    // Locale-aware name. Uses the trilingual naming contribution when
    // the ambient locale is Arabic or French and a translation exists;
    // falls back to the product's own resolved name (English by
    // default) for any other locale.
    final localeLang = Localizations.localeOf(context).languageCode;
    final displayName = (localeLang == 'ar' || localeLang == 'fr')
        ? product.nameFor(localeLang)
        : product.product_name;

    final cachedCategoryName = context.select<ProductNotifier, String>(
      (notifier) {
        final matchingCategories = notifier.productCategories.where(
          (category) =>
              category.productCategoryId == product.product_category_id,
        );
        if (matchingCategories.isEmpty) {
          return localizedCategoryHierarchy(
            categoryPath: product.product_category_name ?? '',
            localizedLeaf: notifier.categoryName(
              product.product_category_id,
              languageCode: localeLang,
            ),
            localizations: loc,
          );
        }
        final category = matchingCategories.first;
        return localizedCategoryHierarchy(
          categoryPath: category.productCategoryDesc,
          localizedLeaf: category.nameFor(localeLang),
          localizations: loc,
        );
      },
    );
    final categoryName =
        cachedCategoryName.isNotEmpty ? cachedCategoryName : '';
    final isDarkMode = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: isOutOfStock ? null : onTap,
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withOpacity(0.5)
                : Colors.black.withOpacity(0.5),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Material(
            borderRadius: BorderRadius.circular(16),
            color: const Color.fromRGBO(0, 0, 0, 0),
            elevation: 4,
            clipBehavior: Clip.antiAlias,
            shadowColor: Colors.transparent,
            child: InkWell(
              onTap: isOutOfStock ? null : onTap,
              splashColor: isOutOfStock
                  ? Colors.transparent
                  : theme.colorScheme.primary.withOpacity(0.1),
              highlightColor: isOutOfStock
                  ? Colors.transparent
                  : theme.colorScheme.primary.withOpacity(0.1),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            _buildProductImage(context, theme),
                            Expanded(
                              child: Align(
                                alignment: Alignment.center,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: priceColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    loc.price(
                                      product.product_price
                                              ?.toStringAsFixed(2) ??
                                          '--',
                                    ),
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: priceColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName.isNotEmpty
                                    ? displayName
                                    : loc.missingText,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isOutOfStock
                                      ? theme.colorScheme.onSurface
                                          .withOpacity(0.5)
                                      : theme.colorScheme.onSurface,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                supplierName,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isOutOfStock
                                      ? theme.colorScheme.onSurfaceVariant
                                          .withOpacity(0.5)
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              if (categoryName.isNotEmpty)
                                _buildCategoryChip(
                                    context, theme, categoryName),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    isOutOfStock
                                        ? Icons.block
                                        : Icons.inventory_2,
                                    size: 16,
                                    color: priceColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Center(
                                    child: Text(
                                      isOutOfStock
                                          ? loc.outOfStock
                                          : loc.availableText(
                                              stockQuantity.toString()),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                ],
                              ),
                              const SizedBox(height: 4),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isOutOfStock)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.black.withOpacity(0.03),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(BuildContext context, ThemeData theme) {
    final imageUrl = _resolvedImageUrl();
    final hasGallery = product.product_images.length > 1;

    return Hero(
      tag: 'product-image-${product.id_product}',
      child: SizedBox(
        width: 80,
        height: 80,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.surfaceVariant,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 2,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            _buildImageFallback(context, theme),
                      )
                    : _buildImageFallback(context, theme),
              ),
            ),

            // Gallery badge — small pill in the bottom-right showing
            // how many images the product has, matching the counter
            // convention from the details slider.
            if (hasGallery)
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.collections_outlined,
                        size: 10,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${product.product_images.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          height: 1,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageFallback(BuildContext context, ThemeData theme) {
    return Center(
      child: product.product_category_id != null
          ? SvgPicture.asset(
              'assets/icons/${product.product_category_id}.svg',
              package: "product_catalog",
              width: 40,
              height: 40,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            )
          : Icon(
              Icons.shopping_bag,
              size: 32,
              color: theme.colorScheme.onSurfaceVariant,
            ),
    );
  }

  Widget _buildCategoryChip(
      BuildContext context, ThemeData theme, String categoryName) {
    return Chip(
      avatar: product.product_category_id != null
          ? SvgPicture.asset(
              'assets/icons/${product.product_category_id}.svg',
              package: "product_catalog",
              color: theme.colorScheme.primary,
              width: 16,
              height: 16,
            )
          : null,
      label: Text(
        categoryName,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
      shape: StadiumBorder(
        side: BorderSide(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      visualDensity: VisualDensity.compact,
    );
  }
}
