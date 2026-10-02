// lib/provider_store/components/selling_point/selling_items/item_card_with_controls.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:verdelia_core/business/finance/ProvidedService.dart';

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
        // Force the non-positioned child to fill the tile's bounds so
        // the inner Column has a bounded height. Without this, the
        // Column is measured against an unbounded height constraint and
        // Flexible/Spacer inside it don't allocate space correctly —
        // the card overflows the tile no matter how its internals are
        // sized.
        fit: StackFit.expand,
        children: [
          // Card content — column with image at top, flexible info in
          // the middle, quantity bar (when present) pinned at the
          // bottom. All layout is done by the column now; the stack
          // only overlays the two buttons.
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

  // Controls live inside the content column now. These are the
  // dimensions the column uses to lay out the bottom bar. No
  // "reserved space" is needed — the bar takes exactly the space
  // it needs and the flexible content above it shrinks to fit.
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
      children: [
        // Fixed-height image header.
        Flexible(
          child: _buildImageSection(context: context),
        ),
        // Flexible content. This is the section that shrinks when
        // the tile is short. Wrapped in Flexible so the column can
        // allocate less space to it when the quantity bar is present.
        Padding(
          padding: EdgeInsets.fromLTRB(padding, padding, padding, padding),
          child: isProduct
              ? _buildProductInfo(context)
              : _buildServiceInfo(context),
        ),

        // Quantity bar — participates in layout. When present, it
        // takes its natural height (controlsHeight plus inset above
        // and below) at the bottom of the column.
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
    final icon = isProduct ? Icons.inventory_2_rounded : Icons.handyman_rounded;

    // Consistent with the grid delegate: image is 45% of tile width,
    // bounded so tiny tiles still get a visible header and huge tiles
    // don't let the image dominate.
    final imageHeight = (tileHeight * 0.35).clamp(64.0, 110.0);
    final iconSize = (imageHeight * 0.50).clamp(24.0, 48.0);

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
        child: Center(
          child: Icon(icon, size: iconSize, color: colorScheme.primary),
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
        // Title — capped at 2 lines. On short tiles the ellipsis
        // truncates; the layout above guarantees there's room for at
        // least one line.
        Flexible(
          child: Text(
            product.product_name ?? 'Unnamed Product',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: titleSize,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 2),
        if ((product.product_brand ?? '').isNotEmpty)
          Text(
            product.product_brand!,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: metaSize,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        const Spacer(),
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
        const SizedBox(height: 2),
        if (service.description.isNotEmpty)
          Text(
            service.description,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: metaSize,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        const Spacer(),
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
              ),
            ),
          ],
        ),
      ],
    );
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
              // The quantity label is the flexible part. Give it a min
              // width of two digits so single-digit quantities look
              // right and don't collapse the row.
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
