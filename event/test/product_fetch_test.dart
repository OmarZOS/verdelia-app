import 'package:event/components/product/product_cache.dart';
import 'package:event/components/product/product_fetch.dart';
import 'package:event/components/product/product_state.dart';
import 'package:event/product_change_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:verdelia_core/business/services/ProductService.dart';
import 'package:locator/locator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeProductService extends ProductService {
  int callCount = 0;
  int categoryCallCount = 0;
  int forceRefreshCategoryCallCount = 0;
  List<ProductCategory>? categoryResults = const [
    ProductCategory(
      productCategoryId: 12,
      productCategoryDesc: 'health.diagnostics.blood_testing',
    ),
  ];

  @override
  Future<List<ProductCategory>?> getCategories({
    bool forceRefresh = false,
    String? callerKey,
  }) async {
    categoryCallCount++;
    if (forceRefresh) forceRefreshCategoryCallCount++;
    return categoryResults;
  }

  @override
  Future<List<Product>?> getAllProducts({
    int userId = 0,
    int providerId = 0,
    int category = 0,
    String query = "",
    int offset = 0,
    int limit = 10,
    bool includeHidden = false,
    String? domain,
    String? subdomain,
    String? callerKey,
  }) async {
    callCount++;
    return [
      Product(
        id_product: 101,
        product_provider_id: 1,
        product_category_id: 1,
        id_product_category: 1,
        product_ref_id: 1,
        product_nameRaw: 'Fresh Product',
        product_brand: 'Brand',
        product_quantifier: 'kg',
        product_barcode: '123',
        product_category_name: 'Fruit',
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
      SharedPreferences.setMockInitialValues({});
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

    test('persists non-empty categories between notifier instances', () async {
      final service = FakeProductService();
      AppLocator.registerSingletonService<ProductService>(service);

      final firstNotifier = ProductNotifier();
      final firstResult = await firstNotifier.fetchCategories();
      expect(firstResult.single.productCategoryId, 12);
      expect(service.categoryCallCount, 1);
      firstNotifier.dispose();

      final secondNotifier = ProductNotifier();
      final restoredResult = await secondNotifier.fetchCategories();

      expect(restoredResult.single.productCategoryId, 12);
      expect(service.categoryCallCount, 1);
      secondNotifier.dispose();
    });

    test('fetches categories again when the saved category list is empty',
        () async {
      final service = FakeProductService()..categoryResults = const [];
      AppLocator.registerSingletonService<ProductService>(service);

      final notifier = ProductNotifier();
      expect(await notifier.fetchCategories(), isEmpty);
      expect(await notifier.fetchCategories(), isEmpty);

      expect(service.categoryCallCount, 2);
      notifier.dispose();
    });

    test('force refresh bypasses the persisted category list', () async {
      final service = FakeProductService();
      AppLocator.registerSingletonService<ProductService>(service);

      final notifier = ProductNotifier();
      await notifier.fetchCategories();
      await notifier.fetchCategories(forceRefresh: true);

      expect(service.categoryCallCount, 2);
      expect(service.forceRefreshCategoryCallCount, 1);
      notifier.dispose();
    });
  });
}
