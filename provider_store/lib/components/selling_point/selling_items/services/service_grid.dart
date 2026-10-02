import 'package:flutter/material.dart';
import 'package:verdelia_core/business/finance/ProvidedService.dart';
import 'package:event/cart_change_notifier.dart';
import 'package:provider_store/components/selling_point/selling_items/item_card_with_controls.dart';

class ServiceGrid extends StatelessWidget {
  final List<ProvidedService> services;
  final CartChangeNotifier cartNotifier;
  final Function(ProvidedService) onAddToCart;
  final Function(ProvidedService) onRemoveFromCart;
  final Function(ProvidedService) onConfigure;

  const ServiceGrid({
    super.key,
    required this.services,
    required this.cartNotifier,
    required this.onAddToCart,
    required this.onRemoveFromCart,
    required this.onConfigure,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      sliver: SliverGrid(
        gridDelegate: _getGridDelegate(context),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final service = services[index];
            final quantity = _getServiceQuantity(service.id);

            return ItemCardWithConfiguration(
              item: service,
              isProduct: false,
              quantity: quantity,
              onAddToCart: () => onAddToCart(service),
              onRemoveFromCart: () => onRemoveFromCart(service),
              onConfigure: () => onConfigure(service),
            );
          },
          childCount: services.length,
        ),
      ),
    );
  }

  SliverGridDelegate _getGridDelegate(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth > 1200) {
      return const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      );
    } else if (screenWidth > 900) {
      return const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      );
    } else if (screenWidth > 600) {
      return const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      );
    } else {
      return const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      );
    }
  }

  int _getServiceQuantity(int serviceId) {
    return cartNotifier.cartItems
        .where((item) => (item.service?.id ?? 0) == serviceId)
        .fold(0, (sum, item) => sum + item.quantity);
  }
}
