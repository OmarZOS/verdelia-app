// lib/ui/product_card.dart

import 'package:app_constants/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:event/product_change_notifier.dart';
import 'package:provider/provider.dart';
import 'package:ui/utils/category_hierarchy.dart';
import 'package:ui/components/image/image_url.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  /// Which view the card opens when tapped.
  ///
  /// Defaults to [ProductDetailsMode.customer] so a card rendered in a
  /// shop or catalog opens the buyer-facing view. Pass
  /// [ProductDetailsMode.editor] when the card is rendered inside the
  /// supplier dashboard, where tapping a product should open the editor.
  final ProductDetailsMode mode;

  const ProductCard({
    Key? key,
    required this.product,
    this.mode = ProductDetailsMode.customer,
  }) : super(key: key);

  /// Prefer the seller's own image (first gallery entry); fall back to
  /// the linked IProduct's reference image when the gallery is empty or
  /// its primary URL is malformed.
  String? _resolvedImageUrl() {
    return resolveImageUrl(product.primaryImageUrl) ??
        resolveImageUrl(product.product_origin?.iproductImageUrl);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final categoryId = product.product_category_id ?? 0;

    final localeLang = Localizations.localeOf(context).languageCode;
    final localizedName = (localeLang == 'ar' || localeLang == 'fr')
        ? product.nameFor(localeLang)
        : product.product_name;
    final productName = (localizedName ?? '').trim().isNotEmpty
        ? localizedName!.trim()
        : (product.product_name ?? '').trim();

    final brand = (product.product_brand ?? '').trim();

    final localizations = AppLocalizations.of(context)!;

    final categoryHierarchy =
        context.select<ProductNotifier, LocalizedCategoryHierarchy>(
      (notifier) {
        final matchingCategories = notifier.productCategories.where(
          (category) => category.productCategoryId == categoryId,
        );
        if (matchingCategories.isEmpty) {
          return localizedCategoryHierarchyParts(
            categoryPath: product.product_category_name ?? '',
            localizedLeaf: notifier.categoryName(
              categoryId,
              languageCode: localeLang,
            ),
            localizations: localizations,
          );
        }
        final category = matchingCategories.first;
        return localizedCategoryHierarchyParts(
          categoryPath: category.productCategoryDesc,
          localizedLeaf: category.nameFor(localeLang),
          localizations: localizations,
        );
      },
    );

    final imageUrl = _resolvedImageUrl();
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
            Navigator.pushNamed(
              context,
              AppRoutes.productDetails,
              arguments: {
                "product": product,
                "mode":
                    mode == ProductDetailsMode.editor ? "editor" : "customer",
              },
            );
          });
        },
        splashColor: colors.primary.withOpacity(0.06),
        highlightColor: colors.primary.withOpacity(0.03),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Image with soft gradient overlay ────────────────
            Expanded(
              flex: 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: colors.primary.withOpacity(0.05),
                    alignment: Alignment.center,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: imageUrl != null
                          ? Hero(
                              tag: 'product-image-${product.id_product}-card',
                              child: Image.network(
                                imageUrl,
                                key: ValueKey(product.primaryImage?.id),
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: colors.primary.withOpacity(0.6),
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (_, __, ___) =>
                                    _buildFallbackImage(context, categoryId),
                              ),
                            )
                          : _buildPlaceholder(context),
                    ),
                  ),
                  // Subtle top-to-bottom scrim so the badge reads on any image
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
                  // Category badge, top-left
                  if (categoryHierarchy.caption.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      right: 8,
                      child: _CategoryBadge(
                        hierarchy: categoryHierarchy,
                        categoryId: categoryId,
                      ),
                    ),

                  // Gallery count badge, bottom-right — only when the
                  // product actually has more than one image.
                  if (hasGallery)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: _GalleryCountBadge(
                        count: product.product_images.length,
                      ),
                    ),
                ],
              ),
            ),

            // ─── Details ─────────────────────────────────────────
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand (small, muted, above the name)
                    if (brand.isNotEmpty)
                      Text(
                        brand.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onSurface.withOpacity(0.5),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.7,
                        ),
                      ),
                    if (brand.isNotEmpty) const SizedBox(height: 2),

                    // Product name — the star of the card
                    Expanded(
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

                    // Price row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!
                                .price(product.product_price ?? '--'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colors.primary,
                              height: 1.0,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackImage(BuildContext context, int categoryId) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: SvgPicture.asset(
        'assets/icons/$categoryId.svg',
        package: "product_catalog",
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
// Category badge — floats over the image, small pill
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
    // Prefer the leaf for a short pill; fall back to subdomain, then domain.
    final label = hierarchy.leaf.isNotEmpty
        ? hierarchy.leaf
        : (hierarchy.subdomain.isNotEmpty
            ? hierarchy.subdomain
            : hierarchy.domain);

    if (label.isEmpty) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.topLeft,
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
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Gallery count badge — small pill in the bottom-right of the image
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
            ),
          ],
        ),
      ),
    );
  }
}

/// Mirror of the enum declared on the details screen. Keep the two in
/// sync — or, if the details screen already exports the enum, import it
/// from there instead of redeclaring.
enum ProductDetailsMode { customer, editor }
