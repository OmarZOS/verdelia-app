// lib/screens/product_details/customer_view.dart

import 'package:app_constants/app_constants.dart';
import 'package:app_constants/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:event/cart_change_notifier.dart';
import 'package:event/product_change_notifier.dart';
import 'package:product_catalog/screens/cart_screen.dart';
import 'package:product_catalog/screens/components/ProductOwner.dart';
import 'package:product_catalog/screens/components/add_to_cart.dart';
import 'package:product_catalog/screens/components/description.dart';
import 'package:product_catalog/screens/components/dialogue/confirmation_dialogue.dart';
import 'package:product_catalog/screens/components/quantity_and_ref.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:ui/SupplierProductCard.dart';
import 'package:ui/components/product/product_image_gallery.dart';
import 'package:ui/utils/category_hierarchy.dart';
import 'package:ui/components/image/image_url.dart';

import 'provider_tile.dart';
import 'shared_widgets.dart';

class CustomerProductView extends StatefulWidget {
  final Product product;
  final bool isRTL;
  final bool isLoggedIn;
  final bool isDarkMode;
  final ValueChanged<Product> onProductUpdated;

  const CustomerProductView({
    super.key,
    required this.product,
    required this.isRTL,
    required this.isLoggedIn,
    required this.isDarkMode,
    required this.onProductUpdated,
  });

  @override
  State<CustomerProductView> createState() => _CustomerProductViewState();
}

class _CustomerProductViewState extends State<CustomerProductView> {
  late final PanelController _panelController;
  int _quantity = 1;
  late ProductNotifier _productNotifier;

  @override
  void initState() {
    super.initState();
    _panelController = PanelController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _productNotifier = context.read<ProductNotifier>();
  }

  String get _localizedName {
    final localeLang = Localizations.localeOf(context).languageCode;
    if (localeLang == 'ar' || localeLang == 'fr') {
      return widget.product.nameFor(localeLang);
    }
    return widget.product.product_name;
  }

  /// Prefer the seller's own gallery image; fall back to the linked
  /// IProduct's reference image when the gallery is empty or its
  /// primary URL is malformed.
  String? _resolvedImageUrl() {
    final candidates = <String?>[
      widget.product.primaryImageUrl,
      ...widget.product.imageUrls,
      widget.product.product_origin?.iproductImageUrl,
    ];

    for (final candidate in candidates) {
      final resolved = resolveImageUrl(candidate);
      if (resolved != null && resolved.isNotEmpty) {
        return resolved;
      }
    }
    return null;
  }

  void _updateQuantity(int newValue) {
    if (!mounted) return;
    setState(() => _quantity = newValue);
  }

  void _addToCart(BuildContext context) {
    Provider.of<CartChangeNotifier>(context, listen: false)
        .addItem(widget.product, _quantity);
    _panelController.close();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.putSuccess),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton:
          widget.isLoggedIn ? _buildFloatingCartButton(context) : null,
      appBar: _buildAppBar(context),
      body: SlidingUpPanel(
        controller: _panelController,
        minHeight: widget.isLoggedIn ? 80 : 0,
        maxHeight: widget.isLoggedIn ? 320 : 0,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        color: theme.colorScheme.surface,
        backdropEnabled: true,
        backdropOpacity: 0.5,
        backdropColor: widget.isDarkMode
            ? Colors.white.withOpacity(0.5)
            : Colors.black.withOpacity(0.5),
        panel: _buildSlidingPanel(context),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.only(
                  top: AppConstants.kDefaultPaddin,
                  left: AppConstants.kDefaultPaddin,
                  right: AppConstants.kDefaultPaddin,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.background,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProductHeader(context),
                    // Gallery strip — shown whenever the product has
                    // more than one image, so the buyer can preview the
                    // rest of the gallery without leaving the page.
                    if (widget.product.product_images.length > 1) ...[
                      const SizedBox(height: 12),
                      ProductImageThumbnailStrip(
                        images: widget.product.product_images,
                        size: 64,
                        spacing: 10,
                        onImageRemoved: (image) {
                          _productNotifier.removeProductImage(
                            product: widget.product,
                            image: image,
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: AppConstants.kDefaultPaddin),
                    Consumer<ProductNotifier>(
                      builder: (context, notifier, _) {
                        final current = notifier.products.firstWhere(
                          (p) => p.id_product == widget.product.id_product,
                          orElse: () => widget.product,
                        );
                        return QuantityAndRef(product: current);
                      },
                    ),
                    const SizedBox(height: AppConstants.kDefaultPaddin / 2),
                    Description(product: widget.product),
                    if (widget.isLoggedIn) ...[
                      const SizedBox(height: AppConstants.kDefaultPaddin / 2),
                      AddToCart(
                        product: widget.product,
                        onAddToCartPressed: _panelController.open,
                      ),
                    ],
                    const SizedBox(height: AppConstants.kDefaultPaddin / 2),
                    _buildSimilarProducts(context),
                    ProviderTile(
                      providerId: widget.product.product_provider_id ?? 0,
                    ),
                    if (widget.isLoggedIn) const SizedBox(height: 160),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingCartButton(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'floating-button-0',
      backgroundColor: Theme.of(context).colorScheme.primary,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CartScreen()),
        );
        _productNotifier.fetchProducts(reset: true);
      },
      child: Consumer<CartChangeNotifier>(
        builder: (context, cart, _) {
          return Badge(
            isLabelVisible: cart.cartItemCount > 0,
            label: Text('${cart.cartItemCount}'),
            child: const Icon(Icons.shopping_cart, color: Colors.white),
          );
        },
      ),
    );
  }

  Widget _buildSlidingPanel(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PanelHandle(),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildProductThumbnail(theme),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _localizedName.isNotEmpty
                          ? _localizedName
                          : AppLocalizations.of(context)!.missingText,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.price(
                        ((widget.product.product_price ?? 0) * _quantity)
                            .toStringAsFixed(2),
                      ),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildQuantityControls(context, theme),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => _addToCart(context),
            child: Text(
              AppLocalizations.of(context)!.cartAddConfirmationMessage,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductThumbnail(ThemeData theme) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(
        width: 24,
        height: 24,
        child: SvgPicture.asset(
          'assets/icons/${widget.product.product_category_id ?? 1}.svg',
          package: 'product_catalog',
        ),
      ),
    );
  }

  Widget _buildQuantityControls(BuildContext context, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppLocalizations.of(context)!.productQuantity,
          style: theme.textTheme.bodyLarge,
        ),
        Row(
          children: [
            IconButton(
              onPressed:
                  _quantity > 1 ? () => _updateQuantity(_quantity - 1) : null,
              icon: Icon(
                Icons.remove_circle,
                size: 32,
                color: _quantity > 1
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
              ),
            ),
            Container(
              width: 40,
              alignment: Alignment.center,
              child: Text(
                '$_quantity',
                style: theme.textTheme.titleMedium,
              ),
            ),
            IconButton(
              onPressed: () => _updateQuantity(_quantity + 1),
              icon: Icon(
                Icons.add_circle,
                size: 32,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProductHeader(BuildContext context) {
    final theme = Theme.of(context);
    final product = widget.product;
    final imageUrl = _resolvedImageUrl();

    final textColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if ((product.product_brand ?? '').isNotEmpty) ...[
          Text(
            product.product_brand!.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.55),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Text(
          _localizedName,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            height: 1.15,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppConstants.kDefaultPaddin),
        Text(
          AppLocalizations.of(context)!.priceText,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          AppLocalizations.of(context)!
              .price((product.product_price ?? 0).toString()),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.primary,
            height: 1.0,
          ),
        ),
      ],
    );

    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = (screenWidth * 0.42).clamp(120.0, 220.0);
    final hasGallery = product.product_images.length > 1;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppConstants.kDefaultPaddin,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: textColumn),
          const SizedBox(width: AppConstants.kDefaultPaddin),
          SizedBox(
            width: imageSize,
            height: imageSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _buildProductImage(context, imageUrl, product),
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
        ],
      ),
    );
  }

  Widget _buildProductImage(
    BuildContext context,
    String? imageUrl,
    Product product,
  ) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(20);

    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: radius,
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.image_outlined,
          size: 40,
          color: theme.colorScheme.onSurface.withOpacity(0.4),
        ),
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        color: theme.colorScheme.primary.withOpacity(0.05),
        child: Hero(
          tag: 'product-image-${product.id_product}-card',
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: theme.colorScheme.surfaceContainerHighest,
              alignment: Alignment.center,
              child: Icon(
                Icons.broken_image_outlined,
                size: 40,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: theme.colorScheme.primary.withOpacity(0.6),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSimilarProducts(BuildContext context) {
    final theme = Theme.of(context);
    final localeLang = Localizations.localeOf(context).languageCode;
    final localizations = AppLocalizations.of(context)!;
    ProductCategory? productCategory;
    for (final category in _productNotifier.productCategories) {
      if (category.productCategoryId == widget.product.product_category_id) {
        productCategory = category;
        break;
      }
    }
    final resolvedCategoryName = localizedCategoryHierarchy(
      categoryPath: productCategory?.productCategoryDesc ??
          widget.product.product_category_name ??
          '',
      localizedLeaf: productCategory?.nameFor(localeLang) ??
          _productNotifier.categoryName(
            widget.product.product_category_id,
            languageCode: localeLang,
          ),
      localizations: localizations,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            localizations.similarProductsFromCategory(resolvedCategoryName),
            textAlign: widget.isRTL ? TextAlign.right : TextAlign.left,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        Consumer<ProductNotifier>(
          builder: (context, notifier, _) {
            if (notifier.isLoading) {
              return SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, __) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: 360,
                      decoration: BoxDecoration(
                        color: widget.isDarkMode
                            ? Colors.white.withOpacity(0.5)
                            : Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              );
            }

            if (notifier.products.isEmpty) return const SizedBox.shrink();

            return SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: notifier.products.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final p = notifier.products[index];
                  if (p.id_product == widget.product.id_product) {
                    return const SizedBox.shrink();
                  }
                  return SizedBox(
                    width: 360,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Material(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Future.delayed(
                            const Duration(milliseconds: 150),
                            () async {
                              await Navigator.pushNamed(
                                context,
                                AppRoutes.productDetails,
                                arguments: {
                                  'product': p,
                                  'mode': 'customer',
                                },
                              );
                              notifier.fetchProducts(reset: true);
                            },
                          ),
                          child: SupplierProductCard(
                            product: p,
                            supplierName: p.product_brand ?? '',
                            stockQuantity: p.product_quantity ?? 0,
                            minOrderQty: '1',
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final product = widget.product;
    final isOwner = isProductOwner(context, product.product_owner_id ?? 0);

    return AppBar(
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (isOwner)
          IconButton(
            icon: Icon(
              Icons.delete,
              color: Theme.of(context).colorScheme.tertiary,
            ),
            onPressed: () => _showDeleteConfirmation(context),
          ),
        if (isOwner)
          IconButton(
            icon: Icon(
              Icons.edit,
              color: Theme.of(context).colorScheme.secondary,
            ),
            onPressed: _navigateToEditScreen,
          ),
        const SizedBox(width: AppConstants.kDefaultPaddin / 2),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showConfirmationDialog(
      context,
      AppLocalizations.of(context)!.productdeletionConfirmationMessage,
      () async {
        final messenger = ScaffoldMessenger.of(context);
        final loc = AppLocalizations.of(context)!;
        final navigator = Navigator.of(context);

        final statusCode = await _productNotifier.deleteProduct(
          '${widget.product.id_product}',
        );

        if (!mounted) return;

        if (statusCode == 200) {
          navigator.pop();
          messenger.showSnackBar(
            SnackBar(content: Text(loc.deleteSuccess)),
          );
        } else if (statusCode == 406 || statusCode == 422) {
          messenger.showSnackBar(
            SnackBar(content: Text(loc.deleteFailure)),
          );
        } else {
          messenger.showSnackBar(
            SnackBar(content: Text(loc.serverError)),
          );
        }
      },
    );
  }

  Future<void> _navigateToEditScreen() async {
    final updated = await Navigator.pushNamed(
      context,
      AppRoutes.productCreate,
      arguments: {'product': widget.product},
    );

    if (!mounted) return;

    if (updated is Product) {
      widget.onProductUpdated(updated);
    } else {
      final refreshed = _productNotifier.products.firstWhere(
        (p) => p.id_product == widget.product.id_product,
        orElse: () => widget.product,
      );
      widget.onProductUpdated(refreshed);
    }
  }
}

// ══════════════════════════════════════════════════════════════════
// Gallery count badge — floats over the header image
// ══════════════════════════════════════════════════════════════════

class _GalleryCountBadge extends StatelessWidget {
  final int count;

  const _GalleryCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.collections_outlined,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.0,
              letterSpacing: 0.2,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
