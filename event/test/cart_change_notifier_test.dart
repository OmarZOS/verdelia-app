import 'package:flutter_test/flutter_test.dart';
import 'package:event/cart_change_notifier.dart';
import 'package:mocktail/mocktail.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:verdelia_core/business/finance/Cart.dart';
import 'package:verdelia_core/business/finance/ProvidedService.dart';
import 'package:verdelia_core/business/services/CartService.dart';
import 'package:locator/locator.dart';

class MockCartService extends Mock implements CartService {}

void main() {
  late CartChangeNotifier notifier;
  MockCartService mockService = MockCartService();
  AppLocator.registerSingletonService<CartService>(mockService);

  setUp(() {
    notifier = CartChangeNotifier();
  });

  group('Local cart operations', () {
    test('cart starts empty', () {
      expect(notifier.isEmpty, true);
      expect(notifier.cartItemCount, 0);
    });

    test('add product increases quantity', () {
      final product = Product.empty().copyWith(id_product: 1);

      notifier.addProduct(product);

      expect(notifier.cartItemCount, 1);
      expect(notifier.hasProductsInCart, true);
    });

    test('remove product removes item', () {
      final product = Product.empty().copyWith(id_product: 1);

      notifier.addProduct(product);
      notifier.removeItem(product: product);

      expect(notifier.cartItemCount, 0);
      expect(notifier.isEmpty, true);
    });

    test('update quantity updates item', () {
      final product = Product.empty().copyWith(id_product: 1);

      notifier.addProduct(product);
      notifier.updateQuantity(product: product, newQuantity: 3);

      final item = notifier.getProductCartItem(product);

      expect(item?.quantity, 3);
    });

    test('clear cart removes all items', () {
      final product = Product.empty().copyWith(id_product: 1);

      notifier.addProduct(product);
      notifier.clearCart();

      expect(notifier.cartItemCount, 0);
      expect(notifier.isEmpty, true);
    });
  });

  group('Service operations', () {
    test('add service increases service count', () {
      final service =
          ProvidedService.empty().copyWith(id: 10, actualDuration: 30);

      notifier.addService(service);

      expect(notifier.serviceItemCount, 1);
      expect(notifier.hasServicesInCart, true);
    });

    test('update service scheduling', () {
      final service =
          ProvidedService.empty().copyWith(id: 10, actualDuration: 30);

      notifier.addService(service);

      notifier.updateServiceScheduling(
        service: service,
        scheduledDate: "2026-01-01",
        scheduledTime: "10:00",
      );

      final item = notifier.getServiceCartItem(service);

      expect(item?.scheduledDate, "2026-01-01");
    });
  });

  group('Filtering', () {
    test('filter products only', () {
      notifier.filterProductsOnly();

      expect(notifier.filter.showProductsOnly, true);
      expect(notifier.filter.showServicesOnly, false);
    });

    test('clear filter resets filter', () {
      notifier.filterProductsOnly();
      notifier.clearFilter();

      expect(notifier.filter.showProductsOnly, null);
      expect(notifier.filter.showServicesOnly, null);
    });
  });

  group('API operations', () {
    test('fetch carts loads carts', () async {
      final carts = [
        Cart(cartId: 1, cartTotalAmount: 10),
        Cart(cartId: 2, cartTotalAmount: 20),
      ];

      when(() => mockService.getAllCarts(any(), any(),
          sellerId: any(named: 'sellerId'))).thenAnswer((_) async => carts);

      await notifier.fetchCarts();

      expect(notifier.totalApiCarts, 2);
    });

    test('create cart adds cart to list', () async {
      final cart = Cart(cartId: 1, cartTotalAmount: 50);

      when(() => mockService.addCart(any())).thenAnswer((_) async => cart);

      final result = await notifier.createCart(providerId: 1);

      expect(result, isNotNull);
      expect(notifier.totalApiCarts, 1);
    });

    test('delete cart success', () async {
      when(() => mockService.deleteCart(any())).thenAnswer((_) async => 0);

      final success = await notifier.deleteCart(1);

      expect(success, true);
    });
  });

  group('Computed properties', () {
    test('totalApiCartAmount sums correctly', () async {
      final carts = [
        Cart(cartId: 1, cartTotalAmount: 10),
        Cart(cartId: 2, cartTotalAmount: 30),
      ];

      when(() => mockService.getAllCarts(any(), any(),
          sellerId: any(named: 'sellerId'))).thenAnswer((_) async => carts);

      await notifier.fetchCarts();

      expect(notifier.totalApiCartAmount, 40);
    });
  });
}
