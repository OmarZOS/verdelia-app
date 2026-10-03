// lib/screens/product_details/editor_view.dart

import 'package:app_constants/app_constants.dart';
import 'package:app_constants/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:event/product_change_notifier.dart';
import 'package:product_catalog/screens/components/description.dart';
import 'package:provider/provider.dart';
import 'package:ui/components/product/product_image_gallery.dart';

import 'editor_widgets.dart';
import 'provider_tile.dart';

class EditorProductView extends StatefulWidget {
  final Product product;
  final bool isRTL;
  final ValueChanged<Product> onProductUpdated;

  const EditorProductView({
    super.key,
    required this.product,
    required this.isRTL,
    required this.onProductUpdated,
  });

  @override
  State<EditorProductView> createState() => _EditorProductViewState();
}

class _EditorProductViewState extends State<EditorProductView> {
  late ProductNotifier _productNotifier;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _productNotifier = context.read<ProductNotifier>();
  }

  /// Product name resolved for the current locale.
  ///
  /// Prefers the linked IProduct's naming contribution when present —
  /// the origin carries the AI-extracted names, which are often more
  /// complete than the flat Product row. Falls back to the Product's
  /// own resolved name when there's no origin or the origin is empty.
  ///
  /// This is passed to [EditorHero] as `displayName` so the hero does
  /// not have to re-resolve the name itself.
  String get _localizedName {
    final origin = widget.product.product_origin;
    final localeLang = Localizations.localeOf(context).languageCode;

    // 1. Origin's trilingual naming contribution.
    if (origin != null) {
      final fromOrigin = origin.nameFor(localeLang);
      if (fromOrigin.isNotEmpty) return fromOrigin;
    }

    // 2. The Product's own name for the current locale.
    final localized = (localeLang == 'ar' || localeLang == 'fr')
        ? widget.product.nameFor(localeLang)
        : widget.product.product_name;
    if (localized.isNotEmpty) return localized;

    // 3. Raw flat name from the backend.
    final raw = (widget.product.product_nameRaw ?? '').trim();
    if (raw.isNotEmpty) return raw;

    // 4. Nothing usable — let the caller decide the placeholder.
    return '';
  }

  Future<void> _toggleVisibility() async {
    final productId = widget.product.id_product;
    if (productId == null || productId <= 0) return;

    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final nextVisibility = widget.product.isVisible ? 'HIDDEN' : 'VISIBLE';

    final status = await _productNotifier.updateProductVisibility(
      productId,
      nextVisibility,
    );

    if (!mounted) return;

    if (status == 200) {
      final refreshed = _productNotifier.products.firstWhere(
        (p) => p.id_product == productId,
        orElse: () => widget.product.copyWith(
          product_visibility: nextVisibility,
        ),
      );
      widget.onProductUpdated(refreshed);

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            nextVisibility == 'VISIBLE'
                ? loc.productNowVisibleMessage
                : loc.productNowHiddenMessage,
          ),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(loc.productVisibilityUpdateFailedMessage)),
      );
    }
  }

  Future<void> _navigateToEdit() async {
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

  void _showDeleteConfirmation() {
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.deleteProductTitle),
        content: Text(
          loc.deleteProductConfirmation(
            _localizedName.isNotEmpty
                ? _localizedName
                : loc.thisProductFallback,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(loc.cancelButton),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);

              final status = await _productNotifier.deleteProduct(
                '${widget.product.id_product}',
              );

              if (!mounted) return;

              if (status == 200) {
                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(content: Text(loc.productDeletedMessage)),
                );
              } else {
                messenger.showSnackBar(
                  SnackBar(content: Text(loc.productDeleteFailedMessage)),
                );
              }
            },
            child: Text(loc.deleteButton),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = widget.product;
    final hasGallery = product.product_images.length > 1;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: EditorHero(
              product: product,
              isRTL: widget.isRTL,
              displayName: _localizedName,
            ),
          ),

          // Gallery strip — same surface the customer view uses, so
          // editors can see the full gallery and open it in the
          // full-screen slider. Only rendered when there's more than
          // one image; the hero already shows the first.
          if (hasGallery)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: ProductImageThumbnailStrip(
                  images: product.product_images,
                  size: 64,
                  spacing: 10,
                ),
              ),
            ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                PricingHero(product: product),
                const SizedBox(height: 20),
                EditorActions(
                  onEdit: _navigateToEdit,
                  onToggleVisibility: _toggleVisibility,
                  isVisible: product.isVisible,
                ),
                const SizedBox(height: 20),
                StockCard(product: product),
                const SizedBox(height: 20),
                MetadataCard(product: product),
                if ((product.product_description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Description(product: product),
                ],
                const SizedBox(height: 20),
                ProviderTile(
                  providerId: product.product_provider_id ?? 0,
                ),
                const SizedBox(height: 20),
                DangerZoneCard(onDelete: _showDeleteConfirmation),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
