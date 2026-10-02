import 'package:flutter/material.dart';
import 'package:provider_store/components/selling_point/selling_items/item_card_with_controls.dart';
import 'package:provider/provider.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:event/cart_change_notifier.dart';
import 'package:event/product_change_notifier.dart';
import 'package:provider_store/components/selling_point/selling_items/products/product_card.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

class ProductGrid extends StatelessWidget {
  final CartChangeNotifier cartNotifier;

  const ProductGrid({super.key, required this.cartNotifier});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final productNotifier = context.watch<ProductNotifier>();
    final products = productNotifier.products;
    final isLoading = productNotifier.isLoading;

    if (isLoading) {
      return _buildLoadingState(context, localizations);
    }

    if (products.isEmpty) {
      return _buildEmptyState(context, localizations);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return ItemCardWithConfiguration(
          item: products[index],
          // cartNotifier: cartNotifier,
          isProduct: true, quantity: 0, onAddToCart: () {},
          onRemoveFromCart: () {}, onConfigure: () {},
        );
      },
    );
  }

  Widget _buildLoadingState(
      BuildContext context, AppLocalizations localizations) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            CircularProgressIndicator(color: colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              localizations.loadingProducts,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, AppLocalizations localizations) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.inventory_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              localizations.noProductsAvailable,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
