// import 'package:flutter/material.dart';
// import 'package:verdelia_core/business/finance/Cart.dart';
// import 'package:verdelia_core/business/Product.dart';
// import 'package:provider/provider.dart';
// import 'package:event/cart_change_notifier.dart';

// class SellingProductCards extends StatelessWidget {
//   final Product product;
//   final VoidCallback onTap;

//   const SellingProductCard({
//     super.key,
//     required this.product,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;

//     return Consumer<CartChangeNotifier>(
//       builder: (context, cart, child) {
//         final cartItem = _getCartItemForProduct(cart, product);
//         final inCartQuantity = cartItem?.quantity ?? 0;
//         final hasQuantityInCart = inCartQuantity > 0;

//         return GestureDetector(
//           onTap: onTap,
//           child: Container(
//             constraints: const BoxConstraints(
//               minWidth: 150,
//               maxWidth: 200,
//               minHeight: 250,
//               maxHeight: 280,
//             ),
//             decoration: BoxDecoration(
//               color: colorScheme.surface,
//               borderRadius: BorderRadius.circular(16),
//               border: Border.all(
//                 color: colorScheme.outline.withOpacity(0.1),
//                 width: 1,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: colorScheme.shadow.withOpacity(0.1),
//                   blurRadius: 8,
//                   offset: const Offset(0, 2),
//                 ),
//               ],
//             ),
//             clipBehavior: Clip.antiAlias,
//             child: Stack(
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     AspectRatio(
//                       aspectRatio: 5 / 3,
//                       child: _buildProductImage(colorScheme),
//                     ),
//                     Flexible(
//                       child: Padding(
//                         padding: const EdgeInsets.all(12),
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Flexible(
//                               child: Text(
//                                 product.product_name?.isNotEmpty == true
//                                     ? product.product_name!
//                                     : 'Unnamed Product',
//                                 style: theme.textTheme.bodyMedium?.copyWith(
//                                   fontWeight: FontWeight.w600,
//                                   height: 1.2,
//                                 ),
//                                 maxLines: 2,
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                             ),
//                             const SizedBox(height: 8),
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               crossAxisAlignment: CrossAxisAlignment.end,
//                               children: [
//                                 _buildPrice(theme, colorScheme),
//                                 _buildStockButton(context, cart),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 if (hasQuantityInCart) _buildCartBadge(context, inCartQuantity),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildProductImage(ColorScheme colorScheme) {
//     final hasImage = product.product_image_url?.isNotEmpty == true;

//     return Container(
//       color: hasImage ? null : colorScheme.surfaceVariant,
//       child: hasImage
//           ? Image.network(
//               product.product_image_url!,
//               fit: BoxFit.cover,
//               errorBuilder: (context, error, stackTrace) =>
//                   _buildPlaceholderIcon(colorScheme),
//               loadingBuilder: (context, child, loadingProgress) {
//                 if (loadingProgress == null) return child;
//                 return Center(
//                   child: CircularProgressIndicator(
//                     value: loadingProgress.expectedTotalBytes != null
//                         ? loadingProgress.cumulativeBytesLoaded /
//                             loadingProgress.expectedTotalBytes!
//                         : null,
//                     strokeWidth: 2,
//                   ),
//                 );
//               },
//             )
//           : _buildPlaceholderIcon(colorScheme),
//     );
//   }

//   Widget _buildPlaceholderIcon(ColorScheme colorScheme) {
//     return Center(
//       child: Icon(
//         Icons.inventory_2_rounded,
//         size: 32,
//         color: colorScheme.onSurfaceVariant.withOpacity(0.3),
//       ),
//     );
//   }

//   Widget _buildPrice(ThemeData theme, ColorScheme colorScheme) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Text(
//           'Price',
//           style: theme.textTheme.labelSmall?.copyWith(
//             color: colorScheme.onSurfaceVariant,
//             fontSize: 10,
//           ),
//         ),
//         const SizedBox(height: 2),
//         Text(
//           'DZD${product.product_price?.toStringAsFixed(2) ?? '0.00'}',
//           style: theme.textTheme.titleSmall?.copyWith(
//             fontWeight: FontWeight.w700,
//             color: colorScheme.primary,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildStockButton(BuildContext context, CartChangeNotifier cart) {
//     final stock = product.product_quantity ?? 0;
//     final cartItem = _getCartItemForProduct(cart, product);
//     final currentQuantity = cartItem?.quantity ?? 0;

//     return GestureDetector(
//       onTap: () => _showQuantitySelector(context, cart, stock, currentQuantity),
//       child: _StockButton(
//         stock: stock,
//         currentQuantity: currentQuantity,
//       ),
//     );
//   }

//   void _showQuantitySelector(
//     BuildContext context,
//     CartChangeNotifier cart,
//     int stock,
//     int currentQuantity,
//   ) {
//     if (stock <= 0) return;

//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Theme.of(context).colorScheme.surface,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       isScrollControlled: true,
//       builder: (context) {
//         return QuantitySelector(
//           product: product,
//           maxQuantity: stock,
//           currentQuantity: currentQuantity,
//           onQuantitySelected: (quantity) {
//             if (quantity > 0) {
//               cart.addItem(product, quantity);
//             } else {
//               cart.removeItem(product: product);
//             }
//             Navigator.pop(context);
//           },
//         );
//       },
//     );
//   }

//   Widget _buildCartBadge(BuildContext context, int quantity) {
//     final colorScheme = Theme.of(context).colorScheme;

//     return Positioned(
//       top: 8,
//       right: 8,
//       child: Container(
//         width: 24,
//         height: 24,
//         decoration: BoxDecoration(
//           color: colorScheme.primary,
//           shape: BoxShape.circle,
//           boxShadow: [
//             BoxShadow(
//               color: colorScheme.shadow.withOpacity(0.2),
//               blurRadius: 4,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Center(
//           child: Text(
//             quantity.toString(),
//             style: TextStyle(
//               color: colorScheme.onPrimary,
//               fontSize: 11,
//               fontWeight: FontWeight.w800,
//               height: 1.0,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   CartItem? _getCartItemForProduct(CartChangeNotifier cart, Product product) {
//     for (final item in cart.cartItems) {
//       if (item.product?.id_product == product.id_product) {
//         return item;
//       }
//     }
//     return null;
//   }
// }

// class _StockButton extends StatelessWidget {
//   final int stock;
//   final int currentQuantity;

//   const _StockButton({
//     required this.stock,
//     required this.currentQuantity,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;

//     final isOutOfStock = stock <= 0;
//     final isLowStock = stock > 0 && stock <= 10;
//     final hasItemInCart = currentQuantity > 0;

//     Color backgroundColor;
//     Color textColor;
//     String statusText;

//     if (isOutOfStock) {
//       backgroundColor = colorScheme.errorContainer;
//       textColor = colorScheme.onErrorContainer;
//       statusText = 'Out of Stock';
//     } else if (hasItemInCart) {
//       backgroundColor = colorScheme.primary;
//       textColor = colorScheme.onPrimary;
//       statusText = '$currentQuantity in cart';
//     } else if (isLowStock) {
//       backgroundColor = colorScheme.tertiaryContainer;
//       textColor = colorScheme.onTertiaryContainer;
//       statusText = '$stock left';
//     } else {
//       backgroundColor = colorScheme.primaryContainer.withOpacity(0.2);
//       textColor = colorScheme.primary;
//       statusText = 'In Stock';
//     }

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.end,
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Text(
//           'Stock',
//           style: theme.textTheme.labelSmall?.copyWith(
//             color: colorScheme.onSurfaceVariant,
//             fontSize: 10,
//           ),
//         ),
//         const SizedBox(height: 2),
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//           decoration: BoxDecoration(
//             color: backgroundColor,
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(
//               color: isOutOfStock
//                   ? Colors.transparent
//                   : colorScheme.outline.withOpacity(0.1),
//             ),
//             boxShadow: !isOutOfStock
//                 ? [
//                     BoxShadow(
//                       color: colorScheme.shadow.withOpacity(0.05),
//                       blurRadius: 2,
//                       offset: const Offset(0, 1),
//                     ),
//                   ]
//                 : null,
//           ),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               if (hasItemInCart)
//                 Icon(
//                   Icons.shopping_cart_checkout_rounded,
//                   size: 12,
//                   color: textColor,
//                 ),
//               if (hasItemInCart) const SizedBox(width: 4),
//               Text(
//                 statusText,
//                 style: theme.textTheme.labelSmall?.copyWith(
//                   color: textColor,
//                   fontWeight: FontWeight.w600,
//                   fontSize: 11,
//                 ),
//               ),
//               if (!isOutOfStock && !hasItemInCart)
//                 Icon(
//                   Icons.arrow_drop_down_rounded,
//                   size: 16,
//                   color: textColor,
//                 ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

// class QuantitySelector extends StatefulWidget {
//   final Product product;
//   final int maxQuantity;
//   final int currentQuantity;
//   final ValueChanged<int> onQuantitySelected;

//   const QuantitySelector({
//     super.key,
//     required this.product,
//     required this.maxQuantity,
//     required this.currentQuantity,
//     required this.onQuantitySelected,
//   });

//   @override
//   State<QuantitySelector> createState() => _QuantitySelectorState();
// }

// class _QuantitySelectorState extends State<QuantitySelector> {
//   late int _quantity;

//   @override
//   void initState() {
//     super.initState();
//     _quantity = widget.currentQuantity;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;
//     final totalPrice = _quantity * (widget.product.product_price ?? 0);

//     return Padding(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Header
//           Row(
//             children: [
//               Icon(
//                 Icons.add_shopping_cart_rounded,
//                 color: colorScheme.primary,
//                 size: 24,
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Text(
//                   widget.product.product_name ?? 'Product',
//                   style: theme.textTheme.titleMedium?.copyWith(
//                     fontWeight: FontWeight.w600,
//                     color: colorScheme.onSurface,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 20),

//           // Current Stock Info
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: colorScheme.surfaceVariant.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Row(
//               children: [
//                 Icon(
//                   Icons.inventory_rounded,
//                   color: colorScheme.primary,
//                   size: 20,
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Text(
//                     '${widget.maxQuantity} available in stock',
//                     style: theme.textTheme.bodyMedium?.copyWith(
//                       color: colorScheme.onSurface,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 24),

//           // Quantity Selector
//           Center(
//             child: Container(
//               decoration: BoxDecoration(
//                 color: colorScheme.surfaceVariant.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   // Decrease Button
//                   IconButton(
//                     onPressed: _quantity > 0 ? _decreaseQuantity : null,
//                     icon: Icon(
//                       Icons.remove_rounded,
//                       color: _quantity > 0
//                           ? colorScheme.primary
//                           : colorScheme.onSurfaceVariant.withOpacity(0.3),
//                     ),
//                     style: IconButton.styleFrom(
//                       minimumSize: const Size(48, 48),
//                     ),
//                   ),

//                   // Quantity Display
//                   Container(
//                     width: 80,
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Text(
//                           _quantity.toString(),
//                           style: theme.textTheme.headlineMedium?.copyWith(
//                             fontWeight: FontWeight.w700,
//                             color: colorScheme.onSurface,
//                           ),
//                         ),
//                         Text(
//                           'quantity',
//                           style: theme.textTheme.labelSmall?.copyWith(
//                             color: colorScheme.onSurfaceVariant,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),

//                   // Increase Button
//                   IconButton(
//                     onPressed: _quantity < widget.maxQuantity
//                         ? _increaseQuantity
//                         : null,
//                     icon: Icon(
//                       Icons.add_rounded,
//                       color: _quantity < widget.maxQuantity
//                           ? colorScheme.primary
//                           : colorScheme.onSurfaceVariant.withOpacity(0.3),
//                     ),
//                     style: IconButton.styleFrom(
//                       minimumSize: const Size(48, 48),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),

//           // Quick Select Buttons
//           _buildQuickSelectButtons(),
//           const SizedBox(height: 24),

//           // Price Summary
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: colorScheme.primary.withOpacity(0.05),
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
//             ),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Total',
//                         style: theme.textTheme.bodySmall?.copyWith(
//                           color: colorScheme.onSurfaceVariant,
//                         ),
//                       ),
//                       const SizedBox(height: 2),
//                       Text(
//                         'DZD${totalPrice.toStringAsFixed(2)}',
//                         style: theme.textTheme.headlineSmall?.copyWith(
//                           fontWeight: FontWeight.w700,
//                           color: colorScheme.primary,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Text(
//                   '× ${widget.product.product_price?.toStringAsFixed(2) ?? '0.00'} each',
//                   style: theme.textTheme.bodySmall?.copyWith(
//                     color: colorScheme.onSurfaceVariant,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 24),

//           // Action Buttons
//           Row(
//             children: [
//               Expanded(
//                 child: OutlinedButton(
//                   onPressed: () => widget.onQuantitySelected(0),
//                   style: OutlinedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     side: BorderSide(color: colorScheme.outline),
//                   ),
//                   child: Text(
//                     'Remove',
//                     style: TextStyle(
//                       color: colorScheme.error,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: FilledButton(
//                   onPressed: _quantity > 0
//                       ? () => widget.onQuantitySelected(_quantity)
//                       : null,
//                   style: FilledButton.styleFrom(
//                     backgroundColor: colorScheme.primary,
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                   ),
//                   child: Text(
//                     _quantity == widget.currentQuantity
//                         ? 'Update'
//                         : 'Add to Cart',
//                     style: TextStyle(
//                       color: colorScheme.onPrimary,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildQuickSelectButtons() {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;

//     final quickQuantities = _getQuickQuantities();

//     return Wrap(
//       spacing: 8,
//       runSpacing: 8,
//       children: quickQuantities.map((qty) {
//         return ActionChip(
//           label: Text('$qty'),
//           onPressed: () => setState(() => _quantity = qty),
//           backgroundColor: _quantity == qty
//               ? colorScheme.primary
//               : colorScheme.surfaceVariant.withOpacity(0.2),
//           labelStyle: TextStyle(
//             color: _quantity == qty
//                 ? colorScheme.onPrimary
//                 : colorScheme.onSurface,
//             fontWeight: FontWeight.w600,
//           ),
//           avatar: Icon(
//             Icons.add_rounded,
//             size: 16,
//             color: _quantity == qty
//                 ? colorScheme.onPrimary
//                 : colorScheme.onSurfaceVariant,
//           ),
//         );
//       }).toList(),
//     );
//   }

//   List<int> _getQuickQuantities() {
//     final max = widget.maxQuantity;
//     if (max <= 5) return [1, 2, 3, 4, 5].where((q) => q <= max).toList();
//     if (max <= 10) return [1, 3, 5, 8, 10].where((q) => q <= max).toList();
//     return [1, 3, 5, 10, 20].where((q) => q <= max).toList();
//   }

//   void _increaseQuantity() {
//     if (_quantity < widget.maxQuantity) {
//       setState(() => _quantity++);
//     }
//   }

//   void _decreaseQuantity() {
//     if (_quantity > 0) {
//       setState(() => _quantity--);
//     }
//   }
// }
