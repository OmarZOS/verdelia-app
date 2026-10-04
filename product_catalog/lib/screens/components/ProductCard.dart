// lib/ui/product_card.dart

import 'package:app_constants/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:product_catalog/screens/components/product/editor_widgets.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:event/product_change_notifier.dart';
import 'package:provider/provider.dart';
import 'package:ui/utils/category_hierarchy.dart';
import 'package:ui/components/image/image_url.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  /// Which view the card opens when tapped.
  final ProductDetailsMode mode;

  const ProductCard({
    Key? key,
    required this.product,
    this.mode = ProductDetailsMode.customer,
  }) : super(key: key);

  String? _resolvedImageUrl() {
    final candidates = <String?>[
      product.primaryImageUrl,
      ...product.imageUrls,
      product.product_origin?.iproductImageUrl,
    ];

    for (final candidate in candidates) {
      final resolved = resolveImageUrl(candidate);
      if (resolved != null && resolved.isNotEmpty) {
        return resolved;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final categoryId = product.product_category_id ?? 0;
    final l10n = AppLocalizations.of(context)!;

    final localeLang = Localizations.localeOf(context).languageCode;
    final localizedName = (localeLang == 'ar' || localeLang == 'fr')
        ? product.nameFor(localeLang)
        : product.product_name;
    final productName = (localizedName ?? '').trim().isNotEmpty
        ? localizedName!.trim()
        : (product.product_name ?? '').trim();

    final brand = (product.product_brand ?? '').trim();

    final categoryHierarchy =
        context.select<ProductNotifier, LocalizedCategoryHierarchy>(
      (notifier) {
        for (final category in notifier.productCategories) {
          if (category.productCategoryId == categoryId) {
            return localizedCategoryHierarchyParts(
              categoryPath: category.productCategoryDesc,
              localizedLeaf: category.nameFor(localeLang),
              localizations: l10n,
            );
          }
        }
        return localizedCategoryHierarchyParts(
          categoryPath: product.product_category_name ?? '',
          localizedLeaf: notifier.categoryName(
            categoryId,
            languageCode: localeLang,
          ),
          localizations: l10n,
        );
      },
    );

    final hasGallery = product.product_images.length > 1;

    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: colors.outlineVariant.withOpacity(0.6),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Future.delayed(const Duration(milliseconds: 150), () {
            if (!context.mounted) return;
            Navigator.pushNamed(
              context,
              AppRoutes.productDetails,
              arguments: {
                'product': product,
                'mode':
                    mode == ProductDetailsMode.editor ? 'editor' : 'customer',
              },
            );
          });
        },
        splashColor: colors.primary.withOpacity(0.06),
        highlightColor: colors.primary.withOpacity(0.03),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // If the card is inside a tight fixed-height cell (e.g. a
            // GridView with `childAspectRatio: 1.2`), the two
            // `Expanded` slots fight each other for the leftover
            // space. Below ~240dp we drop to a flex layout with
            // explicit proportions that always sum to the available
            // height, so neither the image nor the details section
            // overflows.
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ─── Image ───
                // Fixed 55% of the available height when bounded,
                // otherwise a natural 180dp placeholder for the
                // unbounded case (a ListView cell).
                if (constraints.hasBoundedHeight)
                  SizedBox(
                    height: constraints.maxHeight * 0.55,
                    child: _buildImageSection(
                      context,
                      colors,
                      categoryHierarchy,
                      categoryId,
                      hasGallery,
                    ),
                  )
                else
                  SizedBox(
                    height: 180,
                    child: _buildImageSection(
                      context,
                      colors,
                      categoryHierarchy,
                      categoryId,
                      hasGallery,
                    ),
                  ),

                // ─── Details ───
                Flexible(
                  child: _buildDetailsSection(
                    context,
                    theme,
                    colors,
                    productName,
                    brand,
                    l10n,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // IMAGE SECTION
  // ============================================================

  Widget _buildImageSection(
    BuildContext context,
    ColorScheme colors,
    LocalizedCategoryHierarchy categoryHierarchy,
    int categoryId,
    bool hasGallery,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        FallbackNetworkImage(
          candidates: <String?>[
            product.primaryImageUrl,
            ...product.imageUrls,
            product.product_origin?.iproductImageUrl,
          ],
          fit: BoxFit.cover,
          placeholderBuilder: (context) => _buildPlaceholder(context),
        ),

        // Top scrim so the category badge stays legible on any image.
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: 56,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.28),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),

        if (categoryHierarchy.caption.isNotEmpty ||
            categoryHierarchy.leaf.isNotEmpty)
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: _CategoryBadge(
              hierarchy: categoryHierarchy,
              categoryId: categoryId,
            ),
          ),

        if (hasGallery)
          Positioned(
            right: 8,
            bottom: 8,
            child: _GalleryCountBadge(
              count: product.product_images.length,
            ),
          ),
      ],
    );
  }

  // ============================================================
  // DETAILS SECTION
  // ============================================================

  Widget _buildDetailsSection(
    BuildContext context,
    ThemeData theme,
    ColorScheme colors,
    String productName,
    String brand,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Brand line — fixed 1 line, ellipsized.
          if (brand.isNotEmpty) ...[
            Text(
              brand.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurface.withOpacity(0.5),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.7,
              ),
            ),
            const SizedBox(height: 2),
          ],

          // Product name — up to 2 lines, ellipsized.
          Flexible(
            child: Text(
              productName.isNotEmpty ? productName : '—',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
                height: 1.2,
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Price row — price on the left (flexible), arrow on the
          // right (fixed 28dp). Both pinned to the bottom of the
          // details column via MainAxisAlignment.end on the outer
          // column if needed.
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  l10n.price(product.product_price ?? '--'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.primary,
                    height: 1.0,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 15,
                  color: colors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PLACEHOLDERS
  // ============================================================

  Widget _buildFallbackImage(BuildContext context, int categoryId) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: SvgPicture.asset(
        'assets/icons/$categoryId.svg',
        package: 'product_catalog',
        width: 40,
        height: 40,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        size: 32,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Category badge
// ══════════════════════════════════════════════════════════════════

class _CategoryBadge extends StatelessWidget {
  final LocalizedCategoryHierarchy hierarchy;
  final int categoryId;

  const _CategoryBadge({
    required this.hierarchy,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context) {
    // Prefer leaf for a short pill; fall back to subdomain, then domain.
    final label = hierarchy.leaf.isNotEmpty
        ? hierarchy.leaf
        : (hierarchy.subdomain.isNotEmpty
            ? hierarchy.subdomain
            : hierarchy.domain);

    if (label.isEmpty) return const SizedBox.shrink();

    final tooltipMessage = hierarchy.hasHierarchy ? hierarchy.fullLabel : null;

    final chip = Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        // The badge sits over the image; cap its width so it never
        // eats the whole thumbnail on a narrow card.
        constraints: const BoxConstraints(maxWidth: 140),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.55),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/icons/$categoryId.svg',
                package: 'product_catalog',
                width: 11,
                height: 11,
                color: Colors.white.withOpacity(0.9),
                placeholderBuilder: (_) => const SizedBox.shrink(),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (tooltipMessage == null) return chip;

    return Tooltip(
      message: tooltipMessage,
      waitDuration: const Duration(milliseconds: 400),
      child: chip,
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Gallery count badge
// ══════════════════════════════════════════════════════════════════

class _GalleryCountBadge extends StatelessWidget {
  final int count;

  const _GalleryCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.collections_outlined,
              size: 11,
              color: Colors.white,
            ),
            const SizedBox(width: 3),
            Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                height: 1.0,
                letterSpacing: 0.2,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
              maxLines: 1,
              softWrap: false,
            ),
          ],
        ),
      ),
    );
  }
}

/// Mirror of the enum declared on the details screen.
enum ProductDetailsMode { customer, editor }
