import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:event/cart_change_notifier.dart';

class ProductConfigurationSheet extends StatefulWidget {
  final Product product;
  final CartChangeNotifier cartNotifier;
  final int? currentQuantity;

  /// Called when the user confirms the configuration. The parent
  /// owns persistence — the sheet just reports what the user chose.
  final void Function({required int quantity, double? customPrice})? onConfirm;

  const ProductConfigurationSheet({
    super.key,
    required this.product,
    required this.cartNotifier,
    this.currentQuantity,
    this.onConfirm,
  });

  @override
  State<ProductConfigurationSheet> createState() =>
      _ProductConfigurationSheetState();
}

class _ProductConfigurationSheetState extends State<ProductConfigurationSheet> {
  late int _quantity;
  late final TextEditingController _customPriceController;
  late final TextEditingController _quantityController;
  late final FocusNode _quantityFocus;

  double? _customPrice;

  @override
  void initState() {
    super.initState();

    final existing = widget.cartNotifier.getProductCartItem(widget.product);
    final stock = widget.product.product_quantity ?? 0;

    final seed = widget.currentQuantity ?? existing?.quantity ?? 1;
    _quantity = seed.clamp(1, stock > 0 ? stock : 1);

    _customPrice = existing?.customPrice;

    _customPriceController = TextEditingController(
      text: _customPrice != null ? _customPrice!.toStringAsFixed(2) : '',
    );
    _quantityController = TextEditingController(text: _quantity.toString());

    // Commit the typed quantity when the user taps away or presses
    // done. Committing on every keystroke would fight with the
    // user's own typing (e.g. typing "12" would fire a commit on "1"
    // then again on "12").
    _quantityFocus = FocusNode()..addListener(_onQuantityFocusChanged);
  }

  void _onQuantityFocusChanged() {
    if (!_quantityFocus.hasFocus) {
      _commitTypedQuantity();
    }
  }

  @override
  void dispose() {
    _quantityFocus
      ..removeListener(_onQuantityFocusChanged)
      ..dispose();
    _customPriceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final product = widget.product;
    final loc = AppLocalizations.of(context)!;
    final stock = product.product_quantity ?? 0;
    final unitPrice = _customPrice ?? product.product_price ?? 0;
    final total = _quantity * unitPrice;
    final cartItem = widget.cartNotifier.getProductCartItem(widget.product);
    final isInCart = cartItem != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DragHandle(colorScheme: colorScheme),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(
                        product: product,
                        stock: stock,
                        loc: loc,
                        onClose: () => Navigator.pop(context),
                      ),
                      const SizedBox(height: 24),
                      _Section(
                        colorScheme: colorScheme,
                        child: _QuantitySection(
                          stock: stock,
                          loc: loc,
                          theme: theme,
                          colorScheme: colorScheme,
                          controller: _quantityController,
                          focusNode: _quantityFocus,
                          onDecrement: _quantity > 1 ? _decrement : null,
                          onIncrement: _quantity < stock ? _increment : null,
                          onSubmitted: _commitTypedQuantity,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _Section(
                        colorScheme: colorScheme,
                        child: _PriceSection(
                          product: product,
                          customPrice: _customPrice,
                          controller: _customPriceController,
                          loc: loc,
                          theme: theme,
                          colorScheme: colorScheme,
                          onCustomPriceChanged: (value) {
                            final parsed = double.tryParse(value);
                            setState(() {
                              _customPrice = (parsed != null && parsed > 0)
                                  ? parsed
                                  : null;
                            });
                          },
                          onResetPrice: () {
                            setState(() {
                              _customPrice = null;
                              _customPriceController.clear();
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      _TotalBlock(
                        total: total,
                        quantity: _quantity,
                        unitPrice: unitPrice,
                        hasCustomPrice: _customPrice != null,
                        loc: loc,
                        theme: theme,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 20),
                      _Actions(
                        isInCart: isInCart,
                        stock: stock,
                        loc: loc,
                        colorScheme: colorScheme,
                        onRemove: () {
                          widget.cartNotifier
                              .removeItem(product: widget.product);
                          Navigator.pop(context);
                        },
                        onConfirm: () => _confirm(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // Quantity handling
  // ══════════════════════════════════════════════════════════════════

  void _increment() {
    final stock = widget.product.product_quantity ?? 0;
    if (_quantity >= stock) return;
    setState(() => _quantity++);
    _syncQuantityField();
  }

  void _decrement() {
    if (_quantity <= 1) return;
    setState(() => _quantity--);
    _syncQuantityField();
  }

  /// Parse the quantity field and sync `_quantity`. Called on blur
  /// and on submit.
  ///
  /// Rules:
  ///   - Empty / non-numeric input reverts to the current `_quantity`.
  ///   - Values < 1 clamp to 1.
  ///   - Values > stock clamp to stock (or to 1 if stock is 0).
  void _commitTypedQuantity() {
    final stock = widget.product.product_quantity ?? 0;
    final maxAllowed = stock > 0 ? stock : 1;

    final parsed = int.tryParse(_quantityController.text.trim());
    final resolved = (parsed ?? _quantity).clamp(1, maxAllowed);

    if (resolved != _quantity) {
      setState(() => _quantity = resolved);
    }
    // Always rewrite the field, even when the value didn't change, so
    // the user sees the clamped/normalized form after blur.
    final text = resolved.toString();
    if (_quantityController.text != text) {
      _quantityController.text = text;
      _quantityController.selection = TextSelection.collapsed(
        offset: text.length,
      );
    }
  }

  /// Sync the field's text from `_quantity` after a +/- button
  /// changes the model. Does not touch the field when it has focus,
  /// so tapping + while the field is focused doesn't yank the cursor.
  void _syncQuantityField() {
    if (_quantityFocus.hasFocus) return;
    final text = _quantity.toString();
    if (_quantityController.text != text) {
      _quantityController.text = text;
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // Confirm
  // ══════════════════════════════════════════════════════════════════

  void _confirm(BuildContext context) {
    // Make sure any in-flight typed value is committed before saving.
    _commitTypedQuantity();

    if (_quantity <= 0) return;
    final stock = widget.product.product_quantity ?? 0;
    if (stock <= 0) return;

    // If a callback was provided, delegate to the parent. The parent
    // knows about the cart shape, how to persist notes, and whether
    // it wants to add or update the item.
    if (widget.onConfirm != null) {
      widget.onConfirm!(
        quantity: _quantity,
        customPrice: _customPrice,
      );
      Navigator.pop(context);
      return;
    }

    // Fallback: no callback supplied. Do the same work as before so
    // existing call sites keep working.
    final existing = widget.cartNotifier.getProductCartItem(widget.product);
    if (existing != null) {
      widget.cartNotifier.updateQuantity(
        product: widget.product,
        newQuantity: _quantity,
      );
    } else {
      widget.cartNotifier.addItem(widget.product, _quantity);
    }

    widget.cartNotifier.cart.updateItemPrice(
      productId: widget.product.id_product,
      customPrice: _customPrice,
    );

    Navigator.pop(context);
  }
}

// ══════════════════════════════════════════════════════════════════
// Shared pieces
// ══════════════════════════════════════════════════════════════════

class _DragHandle extends StatelessWidget {
  final ColorScheme colorScheme;

  const _DragHandle({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withOpacity(0.2),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Product product;
  final int stock;
  final AppLocalizations loc;
  final VoidCallback onClose;

  const _Header({
    required this.product,
    required this.stock,
    required this.loc,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasBarcode =
        product.product_barcode != null && product.product_barcode!.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.inventory_2_rounded,
            color: cs.primary,
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
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (hasBarcode)
                    Text(
                      product.product_barcode!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: stock > 0 ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        stock > 0 ? loc.inStock(stock) : loc.outOfStock,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: stock > 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: onClose,
          tooltip: loc.close,
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final Widget child;
  final ColorScheme colorScheme;

  const _Section({required this.child, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;

  const _SectionTitle({
    required this.icon,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Quantity section — editable field + stepper buttons
// ══════════════════════════════════════════════════════════════════

class _QuantitySection extends StatelessWidget {
  final int stock;
  final AppLocalizations loc;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final VoidCallback onSubmitted;

  const _QuantitySection({
    required this.stock,
    required this.loc,
    required this.theme,
    required this.colorScheme,
    required this.controller,
    required this.focusNode,
    required this.onDecrement,
    required this.onIncrement,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.production_quantity_limits_rounded,
          title: loc.quantityLabel,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _QuantityButton(
              icon: Icons.remove,
              onPressed: onDecrement,
              color: colorScheme.primary,
              semanticLabel: loc.decreaseQuantity,
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Editable quantity. Sized to fit 1–5 digits
                    // without reflowing as the user types, and
                    // constrained so a very wide string can't push
                    // the +/- buttons off the row.
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 64,
                        maxWidth: 120,
                      ),
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(5),
                        ],
                        onSubmitted: (_) => onSubmitted(),
                        onEditingComplete: onSubmitted,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                          height: 1.1,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 8,
                          ),
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: colorScheme.primary.withOpacity(0.3),
                            ),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: colorScheme.primary.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loc.itemsLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _QuantityButton(
              icon: Icons.add,
              onPressed: onIncrement,
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
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Price section
// ══════════════════════════════════════════════════════════════════

class _PriceSection extends StatelessWidget {
  final Product product;
  final double? customPrice;
  final TextEditingController controller;
  final AppLocalizations loc;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final ValueChanged<String> onCustomPriceChanged;
  final VoidCallback onResetPrice;

  const _PriceSection({
    required this.product,
    required this.customPrice,
    required this.controller,
    required this.loc,
    required this.theme,
    required this.colorScheme,
    required this.onCustomPriceChanged,
    required this.onResetPrice,
  });

  @override
  Widget build(BuildContext context) {
    final catalogPrice = product.product_price ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.attach_money_rounded,
          title: loc.priceLabel,
          trailing: customPrice != null
              ? TextButton(
                  onPressed: onResetPrice,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    loc.resetToDefault,
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 12,
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              '${loc.defaultPrice}: ',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              loc.price(catalogPrice.toStringAsFixed(2)),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: loc.customPrice,
            suffixText: loc.currencySymbol,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          onChanged: onCustomPriceChanged,
        ),
        if (customPrice != null) ...[
          const SizedBox(height: 8),
          _DiscountPreview(
            catalogPrice: catalogPrice,
            customPrice: customPrice!,
            loc: loc,
            colorScheme: colorScheme,
          ),
        ],
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Notes section
// ══════════════════════════════════════════════════════════════════

class _NotesSection extends StatelessWidget {
  final TextEditingController controller;
  final AppLocalizations loc;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _NotesSection({
    required this.controller,
    required this.loc,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(icon: Icons.notes_rounded, title: loc.notesLabel),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          maxLines: 3,
          minLines: 2,
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
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Total + actions
// ══════════════════════════════════════════════════════════════════

class _TotalBlock extends StatelessWidget {
  final double total;
  final int quantity;
  final double unitPrice;
  final bool hasCustomPrice;
  final AppLocalizations loc;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _TotalBlock({
    required this.total,
    required this.quantity,
    required this.unitPrice,
    required this.hasCustomPrice,
    required this.loc,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
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
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    loc.price(total.toStringAsFixed(2)),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  loc.qtyTimesPrice(
                    quantity,
                    loc.price(unitPrice.toStringAsFixed(2)),
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (hasCustomPrice)
                  Text(
                    loc.customPriceApplied,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.tertiary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  final bool isInCart;
  final int stock;
  final AppLocalizations loc;
  final ColorScheme colorScheme;
  final VoidCallback onRemove;
  final VoidCallback onConfirm;

  const _Actions({
    required this.isInCart,
    required this.stock,
    required this.loc,
    required this.colorScheme,
    required this.onRemove,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final canConfirm = stock > 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 340;

        final removeButton = isInCart
            ? OutlinedButton(
                onPressed: onRemove,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: colorScheme.error,
                  side: BorderSide(color: colorScheme.error.withOpacity(0.4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  loc.removeLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            : null;

        final confirmButton = FilledButton(
          onPressed: canConfirm ? onConfirm : null,
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            !canConfirm
                ? loc.outOfStock
                : isInCart
                    ? loc.updateLabel
                    : loc.addToCartLabel,
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );

        if (removeButton == null) {
          return SizedBox(width: double.infinity, child: confirmButton);
        }

        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              removeButton,
              const SizedBox(height: 8),
              confirmButton,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: removeButton),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: confirmButton),
          ],
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Discount preview + quantity button
// ══════════════════════════════════════════════════════════════════

class _DiscountPreview extends StatelessWidget {
  final double catalogPrice;
  final double customPrice;
  final AppLocalizations loc;
  final ColorScheme colorScheme;

  const _DiscountPreview({
    required this.catalogPrice,
    required this.customPrice,
    required this.loc,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unitDiscount = (catalogPrice - customPrice).clamp(0.0, catalogPrice);

    if (unitDiscount <= 0) {
      return Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 14,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              loc.customPriceAboveCatalog,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    final percent =
        catalogPrice > 0 ? (unitDiscount / catalogPrice) * 100 : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.tertiary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_offer_rounded,
            size: 14,
            color: colorScheme.tertiary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              percent != null
                  ? loc.discountPreview(
                      loc.price(unitDiscount.toStringAsFixed(2)),
                      percent.toStringAsFixed(0),
                    )
                  : loc.price(unitDiscount.toStringAsFixed(2)),
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onTertiaryContainer,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
      enabled: enabled,
      label: semanticLabel,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Material(
          color:
              enabled ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.08),
          shape: const CircleBorder(),
          child: IconButton(
            icon: Icon(
              icon,
              size: 20,
              color: enabled ? color : Colors.grey.shade400,
            ),
            onPressed: onPressed,
            splashRadius: 24,
          ),
        ),
      ),
    );
  }
}
