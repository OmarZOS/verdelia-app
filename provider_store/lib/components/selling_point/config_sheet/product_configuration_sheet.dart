import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:event/cart_change_notifier.dart';

class ProductConfigurationSheet extends StatefulWidget {
  final Product product;
  final CartChangeNotifier cartNotifier;
  final int? currentQuantity;

  const ProductConfigurationSheet({
    super.key,
    required this.product,
    required this.cartNotifier,
    this.currentQuantity,
  });

  @override
  State<ProductConfigurationSheet> createState() =>
      _ProductConfigurationSheetState();
}

class _ProductConfigurationSheetState extends State<ProductConfigurationSheet> {
  late int _quantity;
  late TextEditingController _notesController;
  late TextEditingController _customPriceController;
  double? _customPrice;

  @override
  void initState() {
    super.initState();

    final existing = widget.cartNotifier.getProductCartItem(widget.product);

    _quantity = widget.currentQuantity ?? existing?.quantity ?? 1;

    _customPrice = existing?.customPrice;

    _notesController = TextEditingController();
    _customPriceController = TextEditingController(
      text: _customPrice?.toStringAsFixed(2) ?? '',
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    _customPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final product = widget.product;
    final price = _customPrice ?? product.product_price ?? 0;
    final stock = product.product_quantity ?? 0;
    final total = _quantity * price;
    final cartItem = widget.cartNotifier.getProductCartItem(widget.product);
    final isInCart = cartItem != null;
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.inventory_2_rounded,
                            color: colorScheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.product_name ?? loc.unnamedProduct,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (product.product_barcode != null) ...[
                                    Flexible(
                                      child: Text(
                                        product.product_barcode!,
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '·',
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          stock > 0 ? Colors.green : Colors.red,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    stock > 0
                                        ? loc.inStock(stock)
                                        : loc.outOfStock,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          stock > 0 ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                          tooltip: loc.close,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Quantity ──
                    _Section(
                      colorScheme: colorScheme,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.quantityLabel,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _QuantityButton(
                                icon: Icons.remove,
                                onPressed: _quantity > 1
                                    ? () => setState(() => _quantity--)
                                    : null,
                                color: colorScheme.primary,
                                semanticLabel: loc.decreaseQuantity,
                              ),
                              Expanded(
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$_quantity',
                                        style: theme.textTheme.headlineMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                      Text(
                                        loc.itemsLabel,
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              _QuantityButton(
                                icon: Icons.add,
                                onPressed: _quantity < stock
                                    ? () => setState(() => _quantity++)
                                    : null,
                                color: colorScheme.primary,
                                semanticLabel: loc.increaseQuantity,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            loc.maxAvailable(stock),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Price ──
                    _Section(
                      colorScheme: colorScheme,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.attach_money_rounded,
                                size: 18,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                loc.priceLabel,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              if (_customPrice != null)
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _customPrice = null;
                                      _customPriceController.clear();
                                    });
                                  },
                                  child: Text(
                                    loc.resetToDefault,
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loc.defaultPrice,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    Text(
                                      loc.price((product.product_price ?? 0)
                                          .toStringAsFixed(2)),
                                      style:
                                          theme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextField(
                                  controller: _customPriceController,
                                  decoration: InputDecoration(
                                    labelText: loc.customPrice,
                                    suffixText: loc.currencySymbol ?? 'DA',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  onChanged: (value) {
                                    final parsed = double.tryParse(value);
                                    setState(() {
                                      _customPrice =
                                          (parsed != null && parsed > 0)
                                              ? parsed
                                              : null;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          if (_customPrice != null) ...[
                            const SizedBox(height: 8),
                            _DiscountPreview(
                              catalogPrice: product.product_price ?? 0,
                              customPrice: _customPrice!,
                              quantity: _quantity,
                              loc: loc,
                              colorScheme: colorScheme,
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Notes ──
                    _Section(
                      colorScheme: colorScheme,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.notes_rounded,
                                size: 18,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                loc.notesLabel,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: loc.addNotesHint,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: colorScheme.surface,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Total ──
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.totalLabel,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  loc.price(total.toStringAsFixed(2)),
                                  style:
                                      theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                loc.qtyTimesPrice(
                                  _quantity,
                                  '${loc.currencySymbol ?? 'DA'}${price.toStringAsFixed(2)}',
                                ),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (_customPrice != null)
                                Text(
                                  loc.customPriceApplied,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.tertiary,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Actions ──
                    Row(
                      children: [
                        if (isInCart) ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                widget.cartNotifier
                                    .removeItem(product: widget.product);
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                loc.removeLabel,
                                style: TextStyle(
                                  color: colorScheme.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: FilledButton(
                            onPressed: stock > 0
                                ? () {
                                    if (_quantity <= 0) return;

                                    final existing = widget.cartNotifier
                                        .getProductCartItem(widget.product);
                                    if (existing != null) {
                                      widget.cartNotifier.updateQuantity(
                                        product: widget.product,
                                        newQuantity: _quantity,
                                      );
                                    } else {
                                      widget.cartNotifier
                                          .addItem(widget.product, _quantity);
                                    }

                                    widget.cartNotifier.cart.updateItemPrice(
                                      productId: widget.product.id_product,
                                      customPrice: _customPrice,
                                    );

                                    Navigator.pop(context);
                                  }
                                : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              stock == 0
                                  ? loc.outOfStock
                                  : (isInCart
                                      ? loc.updateLabel
                                      : loc.addToCartLabel),
                              style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
}

// ─────────────────────────────────────────────────────────────
// Shared section wrapper.
// ─────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final Widget child;
  final ColorScheme colorScheme;

  const _Section({required this.child, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Small discount preview row when a custom price is active.
// ─────────────────────────────────────────────────────────────

class _DiscountPreview extends StatelessWidget {
  final double catalogPrice;
  final double customPrice;
  final int quantity;
  final AppLocalizations loc;
  final ColorScheme colorScheme;

  const _DiscountPreview({
    required this.catalogPrice,
    required this.customPrice,
    required this.quantity,
    required this.loc,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unitDiscount = (catalogPrice - customPrice).clamp(0.0, catalogPrice);
    final lineDiscount = unitDiscount * quantity;
    final percent =
        catalogPrice > 0 ? (unitDiscount / catalogPrice) * 100 : 0.0;

    if (unitDiscount <= 0) {
      return Row(
        children: [
          Icon(Icons.info_outline,
              size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              loc.customPriceAboveCatalog,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.tertiary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.local_offer_rounded,
              size: 14, color: colorScheme.tertiary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              loc.discountPreview(
                loc.price(lineDiscount.toStringAsFixed(2)),
                percent.toStringAsFixed(0),
              ),
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onTertiaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final String? semanticLabel;

  const _QuantityButton({
    required this.icon,
    required this.onPressed,
    required this.color,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color:
              enabled ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color:
                enabled ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: IconButton(
          icon: Icon(
            icon,
            size: 20,
            color: enabled ? color : Colors.grey,
          ),
          onPressed: onPressed,
          splashRadius: 24,
        ),
      ),
    );
  }
}
