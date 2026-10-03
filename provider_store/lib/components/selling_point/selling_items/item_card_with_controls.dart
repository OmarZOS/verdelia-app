// lib/provider_store/components/selling_point/selling_items/item_card_with_controls.dart

import 'package:event/service_change_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:verdelia_core/business/finance/ProvidedService.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:ui/components/image/fallback_network_image.dart';

class ItemCardWithConfiguration extends StatelessWidget {
  final dynamic item;
  final bool isProduct;
  final int quantity;
  final VoidCallback onAddToCart;
  final VoidCallback onRemoveFromCart;
  final VoidCallback onRemoveAll;
  final VoidCallback onConfigure;

  const ItemCardWithConfiguration({
    super.key,
    required this.item,
    required this.isProduct,
    required this.quantity,
    required this.onAddToCart,
    required this.onRemoveFromCart,
    required this.onRemoveAll,
    required this.onConfigure,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width / 2;
        final tileHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : tileWidth / 0.85;

        final scale = (tileWidth / 180).clamp(0.75, 1.6);

        return _CardBody(
          item: item,
          isProduct: isProduct,
          quantity: quantity,
          scale: scale,
          tileHeight: tileHeight,
          onAddToCart: onAddToCart,
          onRemoveFromCart: onRemoveFromCart,
          onRemoveAll: onRemoveAll,
          onConfigure: onConfigure,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────

class _CardBody extends StatelessWidget {
  final dynamic item;
  final bool isProduct;
  final int quantity;
  final double scale;
  final double tileHeight;
  final VoidCallback onAddToCart;
  final VoidCallback onRemoveFromCart;
  final VoidCallback onRemoveAll;
  final VoidCallback onConfigure;

  const _CardBody({
    required this.item,
    required this.isProduct,
    required this.quantity,
    required this.scale,
    required this.tileHeight,
    required this.onAddToCart,
    required this.onRemoveFromCart,
    required this.onRemoveAll,
    required this.onConfigure,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasQuantity = quantity > 0;

    final radius = (16 * scale).clamp(12.0, 22.0);
    final circleButtonSize = (32 * scale).clamp(26.0, 40.0);
    final circleIconSize = (16 * scale).clamp(13.0, 20.0);
    final badgeMinWidth = (24 * scale).clamp(20.0, 30.0);
    final badgeHeight = (24 * scale).clamp(20.0, 30.0);
    final badgeFontSize = (12 * scale).clamp(10.0, 14.0);
    final controlsHeight = (36 * scale).clamp(30.0, 44.0);
    final controlsRadius = controlsHeight / 2;
    final overlayButtonSize = (32 * scale).clamp(26.0, 38.0);
    final overlayIconSize = (18 * scale).clamp(15.0, 22.0);
    final cardPadding = (12 * scale).clamp(8.0, 18.0);
    final controlsInset = (8 * scale).clamp(6.0, 12.0);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onAddToCart();
              },
              child: _ItemContent(
                item: item,
                isProduct: isProduct,
                quantity: quantity,
                scale: scale,
                radius: radius,
                padding: cardPadding,
                tileHeight: tileHeight,
                controlsInset: controlsInset,
                controlsHeight: controlsHeight,
                controlsRadius: controlsRadius,
                overlayButtonSize: overlayButtonSize,
                overlayIconSize: overlayIconSize,
                onAdd: onAddToCart,
                onRemove: onRemoveFromCart,
                onRemoveAll: onRemoveAll,
              ),
            ),
          ),

          // Config button overlay — top right.
          Positioned(
            top: controlsInset,
            right: controlsInset,
            child: _CircleButton(
              icon: Icons.settings_rounded,
              onTap: onConfigure,
              background: colorScheme.primary.withOpacity(0.15),
              border: colorScheme.primary.withOpacity(0.3),
              foreground: colorScheme.primary,
              size: circleButtonSize,
              iconSize: circleIconSize,
            ),
          ),

          // Quantity badge overlay — top left.
          if (hasQuantity)
            Positioned(
              top: controlsInset,
              left: controlsInset,
              child: Container(
                constraints: BoxConstraints(minWidth: badgeMinWidth),
                height: badgeHeight,
                padding: EdgeInsets.symmetric(
                  horizontal: (6 * scale).clamp(4.0, 8.0),
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(badgeHeight / 2),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '×$quantity',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: badgeFontSize,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color background;
  final Color border;
  final Color foreground;
  final double size;
  final double iconSize;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    required this.background,
    required this.border,
    required this.foreground,
    required this.size,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            border: Border.all(color: border, width: 1.5),
          ),
          child: Icon(icon, size: iconSize, color: foreground),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────

class _ItemContent extends StatelessWidget {
  final dynamic item;
  final bool isProduct;
  final int quantity;
  final double scale;
  final double radius;
  final double padding;
  final double tileHeight;

  final double controlsInset;
  final double controlsHeight;
  final double controlsRadius;
  final double overlayButtonSize;
  final double overlayIconSize;

  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onRemoveAll;

  const _ItemContent({
    required this.item,
    required this.isProduct,
    required this.quantity,
    required this.scale,
    required this.radius,
    required this.padding,
    required this.tileHeight,
    required this.controlsInset,
    required this.controlsHeight,
    required this.controlsRadius,
    required this.overlayButtonSize,
    required this.overlayIconSize,
    required this.onAdd,
    required this.onRemove,
    required this.onRemoveAll,
  });

  @override
  Widget build(BuildContext context) {
    final hasQuantity = quantity > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      // Shrink-wrap vertically when the parent has no bounded height
      // (e.g. inside a ListView on the services tab). When the parent
      // *does* provide a bounded tile, this still respects the parent's
      // height because the children have fixed heights + MainAxisSize.min
      // collapses to their sum.
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildImageSection(context: context),
        Padding(
          padding: EdgeInsets.all(padding),
          child: isProduct
              ? _buildProductInfo(context)
              : _buildServiceInfo(context),
        ),
        if (hasQuantity)
          Padding(
            padding: EdgeInsets.fromLTRB(
              controlsInset,
              controlsInset * 0.5,
              controlsInset,
              controlsInset,
            ),
            child: _QuantityControls(
              currentQuantity: quantity,
              onAdd: onAdd,
              onRemove: onRemove,
              onRemoveAll: onRemoveAll,
              height: controlsHeight,
              radius: controlsRadius,
              buttonSize: overlayButtonSize,
              iconSize: overlayIconSize,
            ),
          ),
      ],
    );
  }

  Widget _buildImageSection({required BuildContext context}) {
    final colorScheme = Theme.of(context).colorScheme;

    final imageHeight = (tileHeight * 0.35).clamp(64.0, 110.0);
    final iconSize = (imageHeight * 0.50).clamp(24.0, 48.0);

    final Widget content = isProduct && item is Product
        ? _buildProductImage(
            context: context,
            product: item as Product,
            fallbackIcon: Icons.inventory_2_rounded,
            fallbackIconSize: iconSize,
          )
        : Center(
            child: Icon(
              Icons.handyman_rounded,
              size: iconSize,
              color: colorScheme.primary,
            ),
          );

    return SizedBox(
      height: imageHeight,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(radius),
            topRight: Radius.circular(radius),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(radius),
            topRight: Radius.circular(radius),
          ),
          child: content,
        ),
      ),
    );
  }

  Widget _buildProductImage({
    required BuildContext context,
    required Product product,
    required IconData fallbackIcon,
    required double fallbackIconSize,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    final candidates = <String?>[
      product.primaryImageUrl,
      ...product.imageUrls,
      product.product_origin?.iproductImageUrl,
    ];

    final hasAnyCandidate = candidates.any(
      (c) => c != null && c.isNotEmpty,
    );
    if (!hasAnyCandidate) {
      return Center(
        child: Icon(
          fallbackIcon,
          size: fallbackIconSize,
          color: colorScheme.primary,
        ),
      );
    }

    return FallbackNetworkImage(
      candidates: candidates,
      fit: BoxFit.cover,
      placeholderBuilder: (context) => Container(
        color: colorScheme.primary.withOpacity(0.1),
        alignment: Alignment.center,
        child: Icon(
          fallbackIcon,
          size: fallbackIconSize,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  // ─── Product info ─────────────────────────────────────────

  Widget _buildProductInfo(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;
    final product = item as Product;
    final price = product.product_price ?? 0;
    final stock = product.product_quantity ?? 0;

    final titleSize = (13 * scale).clamp(11.0, 16.0);
    final metaSize = (10 * scale).clamp(9.0, 12.0);
    final priceSize = (13 * scale).clamp(11.0, 16.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          product.product_name ?? 'Unnamed Product',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: titleSize,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if ((product.product_brand ?? '').isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            product.product_brand!,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: metaSize,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 6),
        Text(
          '${price.toStringAsFixed(2)} ${loc.currencySymbol ?? 'DA'}',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
            fontSize: priceSize,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Container(
              width: (6 * scale).clamp(5.0, 9.0),
              height: (6 * scale).clamp(5.0, 9.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: stock > 0 ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                stock > 0 ? loc.inStock(stock) : loc.outOfStock,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: metaSize,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Service info ─────────────────────────────────────────

  Widget _buildServiceInfo(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;
    final service = item as ProvidedService;

    final titleSize = (13 * scale).clamp(11.0, 16.0);
    final metaSize = (10 * scale).clamp(9.0, 12.0);
    final priceSize = (13 * scale).clamp(11.0, 17.0);

    final subtitle = _serviceSubtitle(context, service);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          service.name,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: titleSize,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: metaSize,
            ),
            // Exactly one line. Anything that doesn't fit is ellipsised.
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        ],
        const SizedBox(height: 6),
        Text(
          '${service.finalPrice.toStringAsFixed(2)} ${loc.currencySymbol ?? 'DA'}',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
            fontSize: priceSize,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Icon(
              Icons.schedule_rounded,
              size: (12 * scale).clamp(10.0, 15.0),
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 2),
            Flexible(
              child: Text(
                service.durationFormatted,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: metaSize,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Picks the best one-line subtitle for a service.
  ///
  /// Order of preference:
  ///   1. Category label resolved through [ServiceNotifier] by id —
  ///      picks up the trilingual naming contribution so
  ///      `health.diagnostics.diagnostic_imaging` becomes
  ///      "Diagnostic Imaging" (or its localized equivalent).
  ///   2. Nested category's own `nameFor`, in case the notifier hasn't
  ///      loaded yet but the service payload carried the category
  ///      inline.
  ///   3. Free-form description as a last resort.
  ///   4. Empty string — no subtitle row rendered at all.
  String _serviceSubtitle(
    BuildContext context,
    ProvidedService service,
  ) {
    final localeLang = Localizations.localeOf(context).languageCode;

    // Resolve the category through the notifier by id. Wrapped in a
    // try/catch because the card can be rendered outside the
    // ServiceNotifier scope (previews, tests). In that case we fall
    // through to the inline category.
    try {
      final categoryName = context.read<ServiceNotifier>().categoryName(
            service.categoryId,
            languageCode: localeLang,
          );
      if (categoryName.isNotEmpty) return categoryName;
    } catch (_) {
      // ServiceNotifier not in scope — fall through.
    }

    final fromService = service.category?.nameFor(localeLang).trim() ?? '';
    if (fromService.isNotEmpty) return fromService;

    final description = service.description.trim();
    if (description.isNotEmpty) return description;

    return '';
  }
}

// ─────────────────────────────────────────────────────────────

class _QuantityControls extends StatelessWidget {
  final int currentQuantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onRemoveAll;
  final double height;
  final double radius;
  final double buttonSize;
  final double iconSize;

  const _QuantityControls({
    required this.currentQuantity,
    required this.onAdd,
    required this.onRemove,
    required this.onRemoveAll,
    required this.height,
    required this.radius,
    required this.buttonSize,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final labelSize = (15 * (height / 36)).clamp(12.0, 18.0);
    final dividerHeight = (20 * (height / 36)).clamp(14.0, 26.0);

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: Container(
        height: height,
        padding: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.95),
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicWidth(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _OverlayIconButton(
                icon: Icons.remove_rounded,
                onTap: currentQuantity > 0 ? onRemove : null,
                colorScheme: colorScheme,
                size: buttonSize,
                iconSize: iconSize,
              ),
              Container(
                constraints: BoxConstraints(minWidth: buttonSize * 1.2),
                alignment: Alignment.center,
                child: Text(
                  currentQuantity.toString(),
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: labelSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _OverlayIconButton(
                icon: Icons.add_rounded,
                onTap: onAdd,
                colorScheme: colorScheme,
                size: buttonSize,
                iconSize: iconSize,
              ),
              Container(
                width: 1,
                height: dividerHeight,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: colorScheme.onPrimary.withOpacity(0.3),
              ),
              _OverlayIconButton(
                icon: Icons.delete_outline_rounded,
                onTap: onRemoveAll,
                colorScheme: colorScheme,
                tint: colorScheme.error,
                size: buttonSize,
                iconSize: iconSize,
              ),
              SizedBox(width: (4 * height / 36).clamp(2.0, 6.0)),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverlayIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final ColorScheme colorScheme;
  final Color? tint;
  final double size;
  final double iconSize;

  const _OverlayIconButton({
    required this.icon,
    required this.onTap,
    required this.colorScheme,
    this.tint,
    required this.size,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final iconColor = tint ?? colorScheme.onPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                onTap!();
              }
            : null,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: enabled
                ? colorScheme.onPrimary.withOpacity(0.15)
                : Colors.transparent,
          ),
          child: Icon(
            icon,
            size: iconSize,
            color: enabled ? iconColor : iconColor.withOpacity(0.35),
          ),
        ),
      ),
    );
  }
}
