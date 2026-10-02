// lib/ui/product_card.dart

import 'dart:developer';

import 'package:app_constants/app_constants.dart';
import 'package:app_constants/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/business/Product.dart';

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

  @override
  Widget build(BuildContext context) {
    final categoryId = product.product_category_id ?? 0;

    // Resolve the product name in the ambient locale when it's one of
    // the three languages the naming contribution carries. Falls back
    // to English for any other locale, which `product.product_name`
    // handles itself.
    final localeLang = Localizations.localeOf(context).languageCode;
    final localizedName = (localeLang == 'ar' || localeLang == 'fr')
        ? product.nameFor(localeLang)
        : product.product_name;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
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
                // Route args always carry the mode. It defaults to
                // "customer" so the details screen doesn't have to
                // fall back to its own default.
                "mode":
                    mode == ProductDetailsMode.editor ? "editor" : "customer",
              },
            );
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            Expanded(
              child: Container(
                alignment: Alignment.center,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: product.product_image_url != null
                      ? Hero(
                          tag: 'product-image-${product.id_product}-card',
                          child: Image.network(
                            product.product_image_url!,
                            key: ValueKey(product.id_product_image),
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return _buildFallbackImage(context, categoryId);
                            },
                          ),
                        )
                      : _buildPlaceholder(context),
                ),
              ),
            ),

            // Text section
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 20,
                    child: Text(
                      localizedName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Chip(
                    avatar: SvgPicture.asset(
                      'assets/icons/${product.product_category_id}.svg',
                      package: "product_catalog",
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    label: Text(
                      AppLocalizations.of(context)!
                          .productCategoryTextList
                          .split(",")[(product.product_category_id ?? 1) - 1],
                    ),
                    backgroundColor:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.2),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!
                              .price(product.product_price ?? '--'),
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackImage(BuildContext context, int categoryId) {
    return Container(
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.3),
      child: Center(
        child: SvgPicture.asset(
          'assets/icons/$categoryId.svg',
          package: "product_catalog",
          width: 40,
          height: 40,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 40,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
    );
  }
}

/// Mirror of the enum declared on the details screen. Keep the two in
/// sync — or, if the details screen already exports the enum, import it
/// from there instead of redeclaring.
enum ProductDetailsMode { customer, editor }
