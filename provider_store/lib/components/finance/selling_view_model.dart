import 'package:flutter/material.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:event/cart_change_notifier.dart';
import 'package:event/product_change_notifier.dart';
import 'package:event/supplier_change_notifier.dart';

class SellingViewModel extends ChangeNotifier {
  SupplierChangeNotifier? _supplierNotifier;
  ProductNotifier? _productNotifier;
  CartChangeNotifier? _cartNotifier;
  int? _selectedSupplierId;
  String _searchQuery = '';

  int? get selectedSupplierId => _selectedSupplierId;
  String get searchQuery => _searchQuery;

  set searchQuery(String value) {
    if (_searchQuery != value) {
      _searchQuery = value;
      notifyListeners();
    }
  }

  bool get isLoading => _productNotifier?.isLoading ?? false;
  int get cartItemCount => _cartNotifier?.cartItemCount ?? 0;
  double get cartTotal => _cartNotifier?.cartTotal ?? 0;

  List<Product> get filteredProducts {
    final products = _productNotifier?.products ?? [];
    if (_searchQuery.isEmpty) return products;

    final query = _searchQuery.toLowerCase();
    return products.where((product) {
      final name = product.product_name?.toLowerCase() ?? '';
      final brand = product.product_brand?.toLowerCase() ?? '';
      final barcode = product.product_barcode?.toLowerCase() ?? '';

      return name.contains(query) ||
          brand.contains(query) ||
          barcode.contains(query);
    }).toList();
  }

  void updateProviders(
    SupplierChangeNotifier supplierNotifier,
    ProductNotifier productNotifier,
    CartChangeNotifier cartNotifier,
    String currentSearchQuery,
  ) {
    final shouldUpdate = _supplierNotifier != supplierNotifier ||
        _productNotifier != productNotifier ||
        _cartNotifier != cartNotifier ||
        _searchQuery != currentSearchQuery;

    if (!shouldUpdate) return;

    _supplierNotifier = supplierNotifier;
    _productNotifier = productNotifier;
    _cartNotifier = cartNotifier;
    _searchQuery = currentSearchQuery;

    _initializeSupplier();
    notifyListeners();
  }

  void _initializeSupplier() {
    final suppliers = _supplierNotifier?.suppliers ?? [];
    if (suppliers.isNotEmpty && _selectedSupplierId == null) {
      _selectedSupplierId = suppliers.first.idProductProvider;
      _productNotifier?.fetchProducts(
        providerId: _selectedSupplierId!,
        reset: true,
      );
    }
  }

  void selectSupplier(int? supplierId) {
    if (_selectedSupplierId == supplierId) return;

    _selectedSupplierId = supplierId;
    if (supplierId != null) {
      _productNotifier?.fetchProducts(providerId: supplierId, reset: true);
    }
    notifyListeners();
  }
}
