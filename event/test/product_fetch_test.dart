import 'package:event/components/product/product_cache.dart';
import 'package:event/components/product/product_fetch.dart';
import 'package:event/components/product/product_state.dart';
import 'package:event/product_change_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:verdelia_core/business/services/ProductService.dart';
import 'package:locator/locator.dart';

class FakeProductService extends ProductService {
  int callCount = 0;

  @override
  Future<List<Product>?> getAllProducts({
    int userId = 0,
    int providerId = 0,
    int category = 0,
    String query = "",
    int page = 1,
    int limit = 10,
    String? callerKey,
  }) async {
    callCount++;
    return [
      Product(
        id_product: 101,
        product_provider_id: 1,
        product_category_id: 1,
        id_product_category: 1,
        id_product_image: null,
        product_ref_id: 1,
        product_name: 'Fresh Product',
        product_brand: 'Brand',
        product_quantifier: 'kg',
        product_barcode: '123',
        product_category_name: 'Fruit',
        product_image_url: '',
        product_price: 10.5,
        product_quantity: 3,
        product_description: 'Sample product',
        product_created_at: DateTime.now(),
        product_last_updated: DateTime.now(),
        product_owner_id: 1,
      )
    ];
  }
}

void main() {
  group('ProductFetch', () {
    setUp(() {
      GetIt.instance.reset();
    });

    test('does not auto-fetch on notifier construction', () {
      final service = FakeProductService();
      AppLocator.registerSingletonService<ProductService>(service);

      final notifier = ProductNotifier();

      expect(notifier.products, isEmpty);
      expect(service.callCount, 0);

      notifier.dispose();
    });

    test('fetch can load products when requested explicitly', () async {
      final service = FakeProductService();
      AppLocator.registerSingletonService<ProductService>(service);

      final fetch = ProductFetch(
        service: service,
        cache: ProductCache(),
        state: ProductState(),
      );

      await fetch.fetchProducts();

      expect(service.callCount, 1);
      expect(fetch, isA<ProductFetch>());
    });
  });
}
