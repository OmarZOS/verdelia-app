import 'package:flutter/material.dart';
import 'package:verdelia_core/business/finance/Cart.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:verdelia_core/business/finance/ProvidedService.dart';
import 'package:verdelia_core/business/services/CartService.dart';
import 'package:locator/locator.dart';

class CartFilter {
  final String? status;
  final bool? hasInvoice;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? showProductsOnly;
  final bool? showServicesOnly;

  const CartFilter({
    this.status,
    this.hasInvoice,
    this.startDate,
    this.endDate,
    this.showProductsOnly,
    this.showServicesOnly,
  });

  CartFilter copyWith({
    String? status,
    bool? hasInvoice,
    DateTime? startDate,
    DateTime? endDate,
    bool? showProductsOnly,
    bool? showServicesOnly,
  }) {
    return CartFilter(
      status: status ?? this.status,
      hasInvoice: hasInvoice ?? this.hasInvoice,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      showProductsOnly: showProductsOnly ?? this.showProductsOnly,
      showServicesOnly: showServicesOnly ?? this.showServicesOnly,
    );
  }

  bool matches(Cart cart) {
    if (status != null && cart.cartStatus != status) return false;
    if (hasInvoice != null && cart.hasInvoice != hasInvoice) return false;
    if (startDate != null) {
      final cartDate = DateTime.tryParse(cart.cartCreatedAt ?? '');
      if (cartDate != null && cartDate.isBefore(startDate!)) return false;
    }
    if (endDate != null) {
      final cartDate = DateTime.tryParse(cart.cartCreatedAt ?? '');
      if (cartDate != null && cartDate.isAfter(endDate!)) return false;
    }
    return true;
  }
}

class CartChangeNotifier with ChangeNotifier {
  final CartService? _cartService = AppLocator.get<CartService>();

  // State
  final Cart _localCart = Cart.local();
  final List<Cart> _apiCarts = [];
  bool _isLoading = false;
  String? _lastError;
  CartFilter _filter = const CartFilter();

  // ============ PUBLIC GETTERS ============
  List<CartItem> get cartItems => _localCart.items;
  List<CartItem> get productItems => _localCart.productItems;
  List<CartItem> get serviceItems => _localCart.serviceItems;
  Cart get cart => _localCart;
  int get cartItemCount => _localCart.totalQuantity;
  int get productItemCount => _localCart.productItems.length;
  int get serviceItemCount => _localCart.serviceItems.length;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  double get cartSubtotal => _localCart.subtotal;
  double get cartTotal => _localCart.totalAmount;
  List<Cart> get apiCarts => List.unmodifiable(_apiCarts);
  CartFilter get filter => _filter;
  bool get hasCartService => _cartService != null;
  bool get hasProductsInCart => _localCart.productItems.isNotEmpty;
  bool get hasServicesInCart => _localCart.serviceItems.isNotEmpty;
  bool get isEmpty => _localCart.isEmpty;
  bool get isNotEmpty => _localCart.isNotEmpty;

  List<Cart> get filteredCarts => _apiCarts.where(_filter.matches).toList();

  double get totalApiCartAmount {
    return _apiCarts.fold(
        0.0, (sum, cart) => sum + (cart.cartTotalAmount ?? 0));
  }

  int get totalApiCarts => _apiCarts.length;

  int get completedApiCarts {
    return _apiCarts
        .where((c) => c.cartStatus?.toLowerCase() == 'completed')
        .length;
  }

  // ============ STATE MANAGEMENT HELPERS ============
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _lastError = error;
    notifyListeners();
  }

  void _clearError() {
    _lastError = null;
    notifyListeners();
  }

  Future<int> _getCurrentUserId() async {
    // Implement actual user ID retrieval
    return 1;
  }

  void _updateCartInList(Cart cart) {
    final index = _apiCarts.indexWhere((c) => c.cartId == cart.cartId);
    if (index != -1) {
      _apiCarts[index] = cart;
    } else {
      _apiCarts.add(cart);
    }
    notifyListeners();
  }

  // ============ FILTER METHODS ============
  void setFilter(CartFilter newFilter) {
    _filter = newFilter;
    notifyListeners();
  }

  void clearFilter() {
    _filter = const CartFilter();
    notifyListeners();
  }

  void filterProductsOnly() {
    setFilter(
        _filter.copyWith(showProductsOnly: true, showServicesOnly: false));
  }

  void filterServicesOnly() {
    setFilter(
        _filter.copyWith(showProductsOnly: false, showServicesOnly: true));
  }

  void showAllItems() {
    setFilter(_filter.copyWith(showProductsOnly: null, showServicesOnly: null));
  }

  // ============ LOCAL CART METHODS ============
  void addProduct(Product product, [int quantity = 1]) {
    _localCart.addProduct(product, quantity);
    _clearError();
    notifyListeners();
  }

  void addService(
    ProvidedService service, {
    int quantity = 1,
    String? scheduledDate,
    String? scheduledTime,
  }) {
    _localCart.addService(
      service,
      quantity: quantity,
      scheduledDate: scheduledDate,
      scheduledTime: scheduledTime,
    );
    _clearError();
    notifyListeners();
  }

  void addItem(dynamic item, [int quantity = 1]) {
    if (item is Product) {
      addProduct(item, quantity);
    } else if (item is ProvidedService) {
      addService(item, quantity: quantity);
    } else {
      throw ArgumentError('Item must be either Product or ProvidedService');
    }
  }

  void removeItem({Product? product, ProvidedService? service}) {
    _localCart.removeItem(
      productId: product?.id_product,
      serviceId: service?.id,
    );
    notifyListeners();
  }

  void updateQuantity({
    Product? product,
    ProvidedService? service,
    required int newQuantity,
  }) {
    if (product != null) {
      if (newQuantity > 0) {
        _localCart.updateQuantity(
            productId: product.id_product, quantity: newQuantity);
      } else {
        removeItem(product: product);
      }
    } else if (service != null) {
      if (newQuantity > 0) {
        _localCart.updateQuantity(serviceId: service.id, quantity: newQuantity);
      } else {
        removeItem(service: service);
      }
    }
    notifyListeners();
  }

  void updateServiceScheduling({
    required ProvidedService service,
    String? scheduledDate,
    String? scheduledTime,
  }) {
    _localCart.updateServiceScheduling(
      serviceId: service.id,
      scheduledDate: scheduledDate,
      scheduledTime: scheduledTime,
    );
    notifyListeners();
  }

  void clearCart() {
    _localCart.clear();
    notifyListeners();
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  bool hasProductInCart(Product product) {
    return _localCart.hasProduct(product.id_product ?? 0);
  }

  bool hasServiceInCart(ProvidedService service) {
    return _localCart.hasService(service.id);
  }

  CartItem? getProductCartItem(Product product) {
    return _localCart.getProductItem(product.id_product ?? 0);
  }

  CartItem? getServiceCartItem(ProvidedService service) {
    return _localCart.getServiceItem(service.id);
  }

  // ============ API CART METHODS ============
  Future<void> fetchCarts({int? userId, bool reset = false}) async {
    if (_cartService == null) {
      _setError('CartService not available');
      return;
    }
    if (_isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      if (reset) _apiCarts.clear();
      final userIdToUse = userId ?? await _getCurrentUserId();
      final carts =
          await _cartService.getAllCarts(0, 30, sellerId: userIdToUse);
      if (carts.isNotEmpty) _apiCarts.addAll(carts);
    } catch (e, stackTrace) {
      _setError('Failed to fetch carts: ${e.toString()}');
      debugPrint('Error fetching carts: $e\n$stackTrace');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchCartDetails(int cartId) async {
    if (_cartService == null) return;
    _setLoading(true);
    _clearError();

    try {
      final cart = await _cartService.getCart(cartId);
      if (cart != null) _updateCartInList(cart);
    } catch (e, stackTrace) {
      _setError('Failed to fetch cart details: ${e.toString()}');
      debugPrint('Error fetching cart details: $e\n$stackTrace');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchCartItems(int cartId) async {
    if (_cartService == null) return;
    try {
      final items = await _cartService!.getCart(cartId);
      final index = _apiCarts.indexWhere((c) => c.cartId == cartId);
      if (index != -1) {
        debugPrint('Fetched items for cart $cartId');
      }
    } catch (e) {
      debugPrint('Error fetching cart items: $e');
    }
  }

  Future<Cart?> createCart({
    required int providerId,
    String? notes,
    int? personRef,
    int? sellingUserId,
  }) async {
    if (_cartService == null) {
      _setError('CartService not available');
      return null;
    }

    _setLoading(true);
    try {
      // final cartData = _localCart.toJsonForApi();

      // final newCart = Cart(
      //   cartProductProviderId: providerId,
      //   cartNotes: notes,
      //   cartPersonRef: personRef,
      //   cartSellingUser: sellingUserId,
      //   cartStatus: 'open',
      //   cartCreatedAt: DateTime.now().toIso8601String(),
      //   cartUpdatedAt: DateTime.now().toIso8601String(),
      //   cartTotalAmount: _localCart.totalAmount,
      // );

      final createdCart = await _cartService!.addCart(_localCart);
      if (createdCart != null) {
        _apiCarts.insert(0, createdCart);
        return createdCart;
      }
      return null;
    } catch (e, stackTrace) {
      _setError('Failed to create cart: ${e.toString()}');
      debugPrint('Error creating cart: $e\n$stackTrace');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateCartStatus(int cartId, String newStatus) async {
    if (_cartService == null) return false;
    final index = _apiCarts.indexWhere((c) => c.cartId == cartId);
    if (index == -1) return false;

    try {
      final updatedCart = _apiCarts[index];
      final result = await _cartService!.updateCart(updatedCart);
      if (result != null) {
        _apiCarts[index] = result;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating cart status: $e');
      return false;
    }
  }

  Future<bool> deleteCart(int cartId) async {
    if (_cartService == null) return false;
    _setLoading(true);
    try {
      final success = await _cartService!.deleteCart(cartId.toString());
      return success == 0;
    } catch (e) {
      _setError('Failed to delete cart: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<Cart?> checkoutLocalCart({
    required int providerId,
    String? notes,
    int? personRef,
    int? sellingUserId,
  }) async {
    if (_localCart.isEmpty) {
      _setError('Cannot checkout empty cart');
      return null;
    }

    final cart = await createCart(
      providerId: providerId,
      notes: notes ?? 'Checkout from local cart',
      personRef: personRef,
      sellingUserId: sellingUserId,
    );

    if (cart != null) {
      _localCart.clear();
      notifyListeners();
    }
    return cart;
  }

  List<CartItem> getFilteredItems() {
    if (_filter.showProductsOnly == true) {
      return _localCart.productItems;
    } else if (_filter.showServicesOnly == true) {
      return _localCart.serviceItems;
    }
    return _localCart.items;
  }

  int get totalServiceDuration {
    return _localCart.serviceItems.fold(0, (total, item) {
      final service = item.service;
      if (service != null) {
        return total + (service.actualDuration * item.quantity);
      }
      return total;
    });
  }

  Map<String, List<CartItem>> get scheduledServicesByDate {
    final Map<String, List<CartItem>> result = {};

    for (final item in _localCart.serviceItems) {
      if (item.scheduledDate != null) {
        result.putIfAbsent(item.scheduledDate!, () => []).add(item);
      }
    }

    return result;
  }

  bool get hasScheduledServices {
    return _localCart.serviceItems.any((item) => item.scheduledDate != null);
  }

  List<Cart> getAllCartsForDisplay() {
    final allCarts = List<Cart>.from(_apiCarts);
    if (_localCart.isNotEmpty) {
      allCarts.insert(
          0,
          Cart(
            cartId: null,
            cartStatus: 'local',
            cartNotes: 'Current shopping cart',
            cartTotalAmount: _localCart.totalAmount,
            cartCreatedAt: DateTime.now().toIso8601String(),
          ));
    }
    return allCarts;
  }
}
