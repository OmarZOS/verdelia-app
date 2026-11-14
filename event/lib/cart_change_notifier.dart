// lib/event/cart_change_notifier.dart
//
// CartChangeNotifier — owns the single cart the user is building
// and checking out.
//
//   * `cart` returns the one live cart. Every mutation method
//     (addProduct / addService / removeItem / updateQuantity / …)
//     operates on it.
//   * `apiCarts` is a read-only **history** list. It is populated
//     by `fetchCarts` and never checked out directly. To check out a
//     cart from history, call `loadCartForCheckout(cart)` first.
//   * `createCart` and `checkoutLocalCart` are gone — they built a
//     payload that disagreed with CheckoutViewModel's. Submission
//     lives in CheckoutViewModel, which owns the CartPayloadBuilder
//     and the CartService call.

import 'package:decimal/decimal.dart';
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

  /// The single live cart. All mutations and checkout read from it.
  Cart _currentCart = Cart.local();

  /// Read-only history of carts fetched from the API. Never checked
  /// out directly.
  final List<Cart> _cartHistory = [];

  bool _isLoading = false;
  String? _lastError;
  CartFilter _filter = const CartFilter();

  // ============ PUBLIC GETTERS ============

  /// The cart to build and check out.
  Cart get cart => _currentCart;

  List<CartItem> get cartItems => _currentCart.items;
  List<CartItem> get productItems => _currentCart.productItems;
  List<CartItem> get serviceItems => _currentCart.serviceItems;

  int get cartItemCount => _currentCart.totalQuantity;
  int get productItemCount => _currentCart.productItems.length;
  int get serviceItemCount => _currentCart.serviceItems.length;

  /// Live-cart subtotal, in [Decimal].
  Decimal get cartSubtotal => _currentCart.subtotal;

  /// Live-cart total, in [Decimal].
  Decimal get cartTotal => _currentCart.totalAmount;

  bool get isEmpty => _currentCart.isEmpty;
  bool get isNotEmpty => _currentCart.isNotEmpty;
  bool get hasProductsInCart => _currentCart.productItems.isNotEmpty;
  bool get hasServicesInCart => _currentCart.serviceItems.isNotEmpty;

  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  bool get hasCartService => _cartService != null;

  // ============ HISTORY ============

  List<Cart> get apiCarts => List.unmodifiable(_cartHistory);
  List<Cart> get filteredCarts => _cartHistory.where(_filter.matches).toList();

  /// Sum of every historical cart's `cartTotalAmount`, in [Decimal].
  ///
  /// `Cart.cartTotalAmount` is `Decimal?` after the `Cart.dart`
  /// migration; the `?? Decimal.zero` fallback matches the old `?? 0`.
  Decimal get totalApiCartAmount => _cartHistory.fold(
        Decimal.zero,
        (sum, cart) => sum + (cart.cartTotalAmount ?? Decimal.zero),
      );

  int get totalApiCarts => _cartHistory.length;

  int get completedApiCarts => _cartHistory
      .where((c) => c.cartStatus?.toLowerCase() == 'completed')
      .length;

  CartFilter get filter => _filter;

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
    // Implement actual user ID retrieval.
    return 1;
  }

  void _upsertHistory(Cart cart) {
    final index = _cartHistory.indexWhere((c) => c.cartId == cart.cartId);
    if (index != -1) {
      _cartHistory[index] = cart;
    } else {
      _cartHistory.add(cart);
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

  // ============ LIVE CART MUTATIONS ============

  void addProduct(Product product, [int quantity = 1]) {
    _currentCart.addProduct(product, quantity);
    _clearError();
    notifyListeners();
  }

  void addService(
    ProvidedService service, {
    int quantity = 1,
    String? scheduledDate,
    String? scheduledTime,
  }) {
    _currentCart.addService(
      service,
      quantity: quantity,
      scheduledDate: scheduledDate,
      scheduledTime: scheduledTime,
    );
    _clearError();
    notifyListeners();
  }

  /// Add a new product or update the existing line's quantity, and
  /// optionally set a custom price, in a single `notifyListeners`
  /// cycle.
  ///
  /// Prefer this over calling [addItem] / [updateQuantity] followed
  /// by [updateItemPrice] — those fire two rebuilds and briefly
  /// expose the catalog price before the custom price lands.
  ///
  /// `customPrice` semantics match [updateItemPrice]: `null` clears
  /// the override; any non-null value is the effective unit price.
  void addOrUpdateProduct(
    Product product,
    int quantity, {
    Decimal? customPrice,
  }) {
    final existing = _currentCart.getProductItem(product.id_product ?? 0);
    if (existing != null) {
      _currentCart.updateQuantity(
        productId: product.id_product,
        quantity: quantity,
      );
    } else {
      _currentCart.addProduct(product, quantity);
    }
    _currentCart.updateItemPrice(
      productId: product.id_product,
      customPrice: customPrice,
    );
    _clearError();
    notifyListeners();
  }

  /// Add a new service or update the existing line's quantity, and
  /// optionally reschedule, in a single `notifyListeners` cycle.
  void addOrUpdateService(
    ProvidedService service,
    int quantity, {
    String? scheduledDate,
    String? scheduledTime,
    Decimal? customPrice,
  }) {
    final existing = _currentCart.getServiceItem(service.id);
    if (existing != null) {
      _currentCart.updateQuantity(
        serviceId: service.id,
        quantity: quantity,
      );
    } else {
      _currentCart.addService(
        service,
        quantity: quantity,
        scheduledDate: scheduledDate,
        scheduledTime: scheduledTime,
      );
    }
    if (scheduledDate != null || scheduledTime != null) {
      _currentCart.updateServiceScheduling(
        serviceId: service.id,
        scheduledDate: scheduledDate,
        scheduledTime: scheduledTime,
      );
    }
    if (customPrice != null) {
      _currentCart.updateItemPrice(
        serviceId: service.id,
        customPrice: customPrice,
      );
    }
    _clearError();
    notifyListeners();
  }

  void addItem(Object item, [int quantity = 1]) {
    if (item is Product) {
      addProduct(item, quantity);
    } else if (item is ProvidedService) {
      addService(item, quantity: quantity);
    } else {
      throw ArgumentError('Item must be either Product or ProvidedService');
    }
  }

  void removeItem({Product? product, ProvidedService? service}) {
    _currentCart.removeItem(
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
        _currentCart.updateQuantity(
            productId: product.id_product, quantity: newQuantity);
      } else {
        removeItem(product: product);
      }
    } else if (service != null) {
      if (newQuantity > 0) {
        _currentCart.updateQuantity(
            serviceId: service.id, quantity: newQuantity);
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
    _currentCart.updateServiceScheduling(
      serviceId: service.id,
      scheduledDate: scheduledDate,
      scheduledTime: scheduledTime,
    );
    notifyListeners();
  }

  /// Set or clear a line-level price override on the live cart.
  ///
  /// `customPrice: null` clears the override (falls back to catalog).
  /// `customPrice: Decimal.zero` marks the line free. Any other
  /// non-null value is the effective unit price.
  void updateItemPrice({
    int? productId,
    int? serviceId,
    required Decimal? customPrice,
  }) {
    _currentCart.updateItemPrice(
      productId: productId,
      serviceId: serviceId,
      customPrice: customPrice,
    );
    notifyListeners();
  }

  /// Replace the live cart with a fresh empty one.
  void clearCart() {
    _currentCart = Cart.local();
    notifyListeners();
  }

  /// Replace the live cart with a specific cart — typically one
  /// pulled from history and re-opened for editing.
  void loadCartForCheckout(Cart cart) {
    _currentCart = cart;
    notifyListeners();
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  bool hasProductInCart(Product product) =>
      _currentCart.hasProduct(product.id_product ?? 0);

  bool hasServiceInCart(ProvidedService service) =>
      _currentCart.hasService(service.id);

  CartItem? getProductCartItem(Product product) =>
      _currentCart.getProductItem(product.id_product ?? 0);

  CartItem? getServiceCartItem(ProvidedService service) =>
      _currentCart.getServiceItem(service.id);

  // ============ HISTORY FETCHES ============

  Future<void> fetchCarts({int? userId, bool reset = false}) async {
    if (_cartService == null) {
      _setError('CartService not available');
      return;
    }
    if (_isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      if (reset) _cartHistory.clear();
      final userIdToUse = userId ?? await _getCurrentUserId();
      final carts =
          await _cartService.getAllCarts(0, 30, sellerId: userIdToUse);
      if (carts.isNotEmpty) _cartHistory.addAll(carts);
      notifyListeners();
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
      if (cart != null) _upsertHistory(cart);
    } catch (e, stackTrace) {
      _setError('Failed to fetch cart details: ${e.toString()}');
      debugPrint('Error fetching cart details: $e\n$stackTrace');
    } finally {
      _setLoading(false);
    }
  }

  /// Update a persisted cart's status.
  Future<bool> updateCartStatus(int cartId, String newStatus) async {
    if (_cartService == null) return false;
    final index = _cartHistory.indexWhere((c) => c.cartId == cartId);
    if (index == -1) return false;

    try {
      final original = _cartHistory[index];
      final toUpdate = original.copyWith(cartStatus: newStatus);
      final result = await _cartService.updateCart(toUpdate);
      if (result != null) {
        _cartHistory[index] = result;
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
      final result = await _cartService.deleteCart(cartId.toString());
      // Assuming the service returns 0 on success.
      return result == 0;
    } catch (e) {
      _setError('Failed to delete cart: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============ DISPLAY HELPERS ============

  List<CartItem> getFilteredItems() {
    if (_filter.showProductsOnly == true) {
      return _currentCart.productItems;
    } else if (_filter.showServicesOnly == true) {
      return _currentCart.serviceItems;
    }
    return _currentCart.items;
  }

  int get totalServiceDuration {
    return _currentCart.serviceItems.fold(0, (total, item) {
      final service = item.service;
      if (service != null) {
        return total + (service.actualDuration * item.quantity);
      }
      return total;
    });
  }

  Map<String, List<CartItem>> get scheduledServicesByDate {
    final Map<String, List<CartItem>> result = {};

    for (final item in _currentCart.serviceItems) {
      final date = item.scheduledDate;
      if (date != null) {
        result.putIfAbsent(date, () => []).add(item);
      }
    }

    return result;
  }

  bool get hasScheduledServices =>
      _currentCart.serviceItems.any((item) => item.scheduledDate != null);

  /// Whether the live cart has at least one line item.
  bool get hasLiveCartWithItems => _currentCart.isNotEmpty;

  /// History with the live cart **prepended** as a distinct entry.
  ///
  /// The live entry is *not* a `Cart` in the persisted sense — it has
  /// `cartId == null` and `cartStatus == 'local'`. Do not pass it to
  /// `updateCartStatus` or `deleteCart`. For "is this the live cart?"
  /// checks, compare with [hasLiveCartWithItems] before iterating, or
  /// check `cart.cartId == null`.
  List<Cart> getAllCartsForDisplay() {
    final allCarts = List<Cart>.from(_cartHistory);
    if (_currentCart.isNotEmpty) {
      allCarts.insert(
        0,
        Cart(
          cartId: null,
          cartStatus: 'local',
          cartNotes: 'Current shopping cart',
          // `Cart.cartTotalAmount` is `Decimal?` after the
          // Cart.dart migration; the live cart's `totalAmount` is
          // `Decimal`, so the assignment type-checks.
          cartTotalAmount: _currentCart.totalAmount,
          cartCreatedAt: DateTime.now().toIso8601String(),
        ),
      );
    }
    return allCarts;
  }
}
