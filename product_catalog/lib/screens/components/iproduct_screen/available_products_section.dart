import 'package:flutter/material.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:event/product_change_notifier.dart';
import 'package:product_catalog/screens/components/ProductCard.dart';
import 'package:provider/provider.dart';

class AvailableProductsSection extends StatelessWidget {
  final String barcode;

  const AvailableProductsSection({super.key, required this.barcode});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<ProductNotifier>(
      builder: (context, productNotifier, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final alreadySearched = productNotifier.currentSearchQuery == barcode;
          if (!productNotifier.isLoading && !alreadySearched) {
            productNotifier.searchProducts(barcode, reset: true);
          }
        });

        final isRelevantSearch = productNotifier.currentSearchQuery == barcode;

        if (productNotifier.isLoading && isRelevantSearch) {
          return _buildProductsLoading(context);
        }

        final products = productNotifier.products;
        final matchingProducts = products.where((product) {
          return product.product_barcode == barcode ||
              product.product_barcode!.contains(barcode);
        }).toList();

        if (matchingProducts.isEmpty) {
          if (!productNotifier.isLoading && isRelevantSearch) {
            return _buildNoProductsFound(context);
          }
          return _buildProductsLoading(context);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Available Products',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Live Search',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Real products from providers matching this barcode',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            _buildProductsList(matchingProducts),
          ],
        );
      },
    );
  }

  Widget _buildProductsLoading(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Searching for products...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoProductsFound(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 56,
            color: colorScheme.onSurfaceVariant.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No products found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList(List<Product> products) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) => ProductCard(product: products[index]),
      ),
    );
  }
}
