import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/business/finance/Cart.dart';
import 'package:verdelia_core/business/finance/Order.dart';
import 'package:event/order_change_notifier.dart';
import 'package:event/user_change_notifier.dart';
import 'package:event/cart_change_notifier.dart';
import 'package:provider/provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final cartNotifier = Provider.of<CartChangeNotifier>(context);
    final userNotifier = Provider.of<AppUserNotifier>(context);
    final orderNotifier = Provider.of<OrderChangeNotifier>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.cartText),
      ),
      floatingActionButton: _buildCheckoutButton(
          context, cartNotifier, orderNotifier, userNotifier),
      body: _buildCartContent(context, cartNotifier),
    );
  }

  Widget _buildCheckoutButton(
    BuildContext context,
    CartChangeNotifier cartNotifier,
    OrderChangeNotifier orderNotifier,
    AppUserNotifier userNotifier,
  ) {
    return FloatingActionButton(
      onPressed: cartNotifier.cart.items.isEmpty
          ? null
          : () =>
              _processOrder(context, cartNotifier, orderNotifier, userNotifier),
      backgroundColor: cartNotifier.cart.items.isEmpty
          ? Colors.grey
          : Theme.of(context).colorScheme.primary,
      elevation: 4,
      child: Icon(
        Icons.done,
        color: cartNotifier.cart.items.isEmpty
            ? Colors.grey[400]
            : Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  Future<void> _processOrder(
    BuildContext context,
    CartChangeNotifier cartNotifier,
    OrderChangeNotifier orderNotifier,
    AppUserNotifier userNotifier,
  ) async {
    final localizations = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final orderData = Order.buildOrderData(
          cartNotifier.cart.items, userNotifier.appUser!.idAppUser!);

      final response = await orderNotifier.submitOrder(orderData);

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: response.isSuccess ? Colors.green : Colors.amber,
        ),
      );

      if (response.isSuccess) {
        Navigator.pop(context);
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('${localizations.serverError}: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildCartContent(
      BuildContext context, CartChangeNotifier cartNotifier) {
    final localizations = AppLocalizations.of(context)!;

    if (cartNotifier.cart.items.isEmpty) {
      return Center(
        child: Text(
          localizations.emptyCartTxt,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: cartNotifier.cart.items.length,
      itemBuilder: (context, index) {
        final item = cartNotifier.cart.items[index];
        return _buildCartItem(context, item, cartNotifier);
      },
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    CartItem item,
    CartChangeNotifier cartNotifier,
  ) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          leading: SvgPicture.asset(
            'assets/icons/${item.product?.product_category_id}.svg',
            package: "product_catalog",
            color: colorScheme.primary,
            width: 36,
          ),
          title: Text(
            item.product?.product_name ?? localizations.missingText,
            style: theme.textTheme.bodyLarge,
          ),
          subtitle: Row(
            children: [
              // Decrease quantity button
              IconButton(
                icon: const Icon(Icons.remove, color: Colors.red, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => cartNotifier.updateQuantity(
                    product: item.product, newQuantity: item.quantity - 1),
              ),

              // Quantity display
              Container(
                width: 36,
                alignment: Alignment.center,
                child: Text(
                  item.quantity.toString(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Increase quantity button
              IconButton(
                icon: const Icon(Icons.add, color: Colors.green, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => cartNotifier.updateQuantity(
                    product: item.product, newQuantity: item.quantity + 1),
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => cartNotifier.removeItem(product: item.product),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          minVerticalPadding: 0,
        ),
      ),
    );
  }
}
