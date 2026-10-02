import 'package:flutter/material.dart';
import 'package:verdelia_core/business/Product.dart';
import 'product_state.dart';

class ProductCart {
  final ProductState _state;

  ProductCart(this._state);

  List<Product> get items => _state.cartItems;
  Map<int, int> get quantities => _state.cartQuantities;
  bool get isLoading => _state.isCartLoading;
  int get totalItems =>
      _state.cartQuantities.values.fold(0, (sum, q) => sum + q);

  double get totalPrice {
    double total = 0;
    for (final item in _state.cartItems) {
      final qty = _state.cartQuantities[item.id_product] ?? 0;
      total += (item.product_price ?? 0) * qty;
    }
    return total;
  }

  void add(Product product, {int quantity = 1}) {
    final id = product.id_product;
    if (id == null) return;

    if (_state.cartQuantities.containsKey(id)) {
      _state.cartQuantities[id] = _state.cartQuantities[id]! + quantity;
    } else {
      _state.cartQuantities[id] = quantity;
      _state.cartItems.add(product);
    }
  }

  void remove(int productId) {
    _state.cartQuantities.remove(productId);
    _state.cartItems.removeWhere((product) => product.id_product == productId);
  }

  void updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      remove(productId);
    } else {
      _state.cartQuantities[productId] = quantity;
    }
  }

  void clear() {
    _state.cartItems.clear();
    _state.cartQuantities.clear();
  }

  bool contains(int productId) => _state.cartQuantities.containsKey(productId);

  int getQuantity(int productId) => _state.cartQuantities[productId] ?? 0;

  void setLoading(bool loading) {
    _state.isCartLoading = loading;
  }
}
