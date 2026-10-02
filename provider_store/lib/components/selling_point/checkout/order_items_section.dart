import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:event/cart_change_notifier.dart';
import 'package:verdelia_core/business/finance/Cart.dart';

class OrderItemsSection extends StatelessWidget {
  const OrderItemsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row(
          //   children: [
          //     Icon(
          //       Icons.shopping_cart,
          //       color: theme.colorScheme.primary,
          //       size: 20,
          //     ),
          //     const SizedBox(width: 8),
          //     Text(
          //       loc.orderItems,
          //       style: theme.textTheme.titleMedium?.copyWith(
          //         fontWeight: FontWeight.w600,
          //       ),
          //     ),
          //     const Spacer(),
          //     Consumer<CartChangeNotifier>(
          //       builder: (context, cart, child) => Text(
          //         '${cart.cartItems.length} ${cart.cartItems.length == 1 ? 'item' : 'items'}',
          //         style: theme.textTheme.bodySmall?.copyWith(
          //           color: theme.colorScheme.onSurfaceVariant,
          //         ),
          //       ),
          //     ),
          //   ],
          // ),
          const SizedBox(height: 12),
          Consumer<CartChangeNotifier>(
            builder: (context, cart, child) {
              if (cart.cartItems.isEmpty) {
                return _buildEmptyCartState(context, loc, theme);
              }

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.1),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ...cart.cartItems.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildCartItem(item, context, loc, theme),
                          )),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(
    CartItem item,
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
  ) {
    return Row(
      children: [
        // Item Icon
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: item.isService
                ? theme.colorScheme.secondary.withOpacity(0.1)
                : theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            item.isService ? Icons.construction : Icons.inventory_2,
            color: item.isService
                ? theme.colorScheme.secondary
                : theme.colorScheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),

        // Item Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.itemName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${item.quantity} × ${loc.price(item.unitPrice?.toStringAsFixed(2) ?? '0.00')}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (item.isService && item.scheduledDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Scheduled: ${item.scheduledDate}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Item Total
        Text(
          loc.price(item.totalPrice.toStringAsFixed(2)),
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyCartState(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Your cart is empty',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add items to proceed with checkout',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
