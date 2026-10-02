import 'dart:async';
import 'dart:developer';
import 'package:verdelia_core/business/Product.dart';
import 'package:verdelia_core/business/services/ProductService.dart';
import 'product_cache.dart';
import 'product_state.dart';

class ProductPolling {
  final ProductService _service;
  final ProductCache _cache;
  final ProductState _state;

  Timer? _timer;

  ProductPolling({
    required ProductService service,
    required ProductCache cache,
    required ProductState state,
  })  : _service = service,
        _cache = cache,
        _state = state;

  void start(Product product) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await _poll(product);
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _poll(Product product) async {
    try {
      final updated =
          await _service.focusOnProduct(product.id_product.toString());
      if (updated != null &&
          updated.product_quantity != product.product_quantity) {
        _cache.cacheProduct(updated);

        final index = _state.products
            .indexWhere((p) => p.id_product == updated.id_product);
        if (index != -1) {
          _state.products[index] = updated;
        }
      }
    } catch (e) {
      // Silent fail for polling
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
