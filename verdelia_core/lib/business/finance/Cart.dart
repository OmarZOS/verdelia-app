import 'package:verdelia_core/app/AppUser.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:verdelia_core/business/finance/Order.dart';
import 'package:verdelia_core/business/finance/OrderedService.dart';
import 'package:verdelia_core/business/finance/ProvidedService.dart';

// Original CartItem class remains exactly the same
class CartItem {
  final Product? product;
  final ProvidedService? service;
  final double? customPrice; // ← NEW: null means "use default price"

  final String? scheduledDate; // For services that need scheduling
  final String? scheduledTime; // For services that need scheduling
  int quantity;

  CartItem({
    this.product,
    this.service,
    this.scheduledDate,
    this.scheduledTime,
    this.customPrice,
    this.quantity = 1,
  }) : assert(
          product != null || service != null,
          'CartItem must have either a product or a service',
        );

  double? get unitPrice {
    if (customPrice != null && customPrice! > 0) return customPrice;
    if (product != null) return product!.product_price;
    if (service != null) return service!.finalPrice;
    return 0.0;
  }

  /// Catalog (un-discounted) unit price.
  double? get catalogUnitPrice {
    if (product != null) return product!.product_price;
    if (service != null) return service!.finalPrice;
    return 0.0;
  }

  /// Total discount for this line = (catalog − custom) × qty.
  /// Zero when no custom price.
  double get lineDiscount {
    final catalog = catalogUnitPrice ?? 0.0;
    final effective = unitPrice ?? 0.0;
    if (effective >= catalog) return 0.0;
    return (catalog - effective) * quantity;
  }

  double get totalPrice => (unitPrice ?? 0) * quantity;

  bool get hasCustomPrice =>
      customPrice != null &&
      customPrice! > 0 &&
      customPrice! != (catalogUnitPrice ?? 0);

  // Get item ID (product ID or service ID)
  int get itemId => product?.id_product ?? service?.id ?? 0;

  // Get item name
  String get itemName => product?.product_name ?? service?.name ?? '';

  // Check if this is a service item
  bool get isService => service != null;

  // Check if this is a product item
  bool get isProduct => product != null;

  // Get duration for service items
  String? get durationFormatted => service?.durationFormatted;

  // Get description
  String get description =>
      product?.product_description ?? service?.description ?? '';

  // Copy with method updated for service
  CartItem copyWith({
    Product? product,
    ProvidedService? service,
    String? scheduledDate,
    String? scheduledTime,
    double? customPrice,
    int? quantity,
    bool clearCustomPrice = false, // ← to explicitly null it
  }) {
    return CartItem(
      product: product ?? this.product,
      service: service ?? this.service,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      customPrice: clearCustomPrice ? null : (customPrice ?? this.customPrice),
      quantity: quantity ?? this.quantity,
    );
  }

  // Convert to JSON for API
  Map<String, dynamic> toJson() {
    final json = {
      'quantity': quantity,
    };

    if (product != null) {
      json['product_id'] = product!.id_product!;
    } else if (service != null) {
      json['provided_service_id'] = service!.id;
    }

    if (scheduledDate != null) {
      json['ordered_service_scheduled_at'] = scheduledDate as int;
    }

    if (scheduledTime != null) {
      json['scheduled_time'] = scheduledTime as int;
    }

    return json;
  }

  @override
  String toString() {
    return 'CartItem(${isProduct ? 'Product' : 'Service'}: $itemName, Quantity: $quantity, Total: DZD$totalPrice)';
  }
}

// Class for API ordered items (from API response)

// Enhanced Cart class that can work with both local and API data
class Cart {
  // Original fields for local cart functionality
  final Map<String, CartItem> _items = {};

  // New fields for API cart data
  final int? cartId;
  final String? cartStatus;
  final int? cartProductProviderId;
  final int? cartPersonRef;
  final int? cartSellingUser;
  final int? cartClientUser;
  final String? cartNotes;
  final String? cartCreatedAt;
  final String? cartUpdatedAt;
  final List<Invoice> invoices;
  final List<Receipt> receipts;
  final List<Deposit> deposits;
  final double? cartTotalAmount;

  // NEW: Store API ordered items and services
  final List<OrderedItem> orderedItems;
  final List<OrderedService> orderedServices;

  // User/Person related data from the API
  final Map<String, dynamic>? personData;
  final Map<String, dynamic>? userData;

  Cart({
    // Local cart constructor
    this.cartId,
    this.cartStatus,
    this.cartProductProviderId,
    this.cartPersonRef,
    this.cartSellingUser,
    this.cartClientUser,
    this.cartNotes,
    this.cartCreatedAt,
    this.cartUpdatedAt,
    this.invoices = const [],
    this.receipts = const [],
    this.deposits = const [],
    this.cartTotalAmount,

    // NEW: API ordered items and services
    this.orderedItems = const [],
    this.orderedServices = const [],
    this.personData,
    this.userData,
  });

  void updateItemPrice({
    int? productId,
    int? serviceId,
    required double? customPrice,
  }) {
    final key = _generateItemKey(productId: productId, serviceId: serviceId);
    final existing = _items[key];
    if (existing == null) return;

    _items[key] = existing.copyWith(
      customPrice: customPrice,
      clearCustomPrice: customPrice == null,
    );
  }

  factory Cart.fromResponseJson(dynamic json) {
    if (json == null) {
      throw const FormatException('Null cart response');
    }

    // ─── Step 1: Normalize to a flat map of the cart fields ───
    Map<String, dynamic> data;

    if (json is List) {
      // Legacy shape: an array of [depositData, cartData].
      // Preserve backward compatibility with the old contract.
      return _fromLegacyListResponse(json);
    }

    if (json is Map) {
      final asMap = Map<String, dynamic>.from(json);

      // Unwrap envelope if present.
      final envelopeData = asMap['data'];
      if (envelopeData is Map) {
        data = Map<String, dynamic>.from(envelopeData);
      } else {
        data = asMap;
      }
    } else {
      throw FormatException(
        'Unexpected cart response type: ${json.runtimeType}',
      );
    }

    // ─── Step 2: Read cart_id with fallbacks ───
    final cartId = _readInt(data, const ['cart_id', 'cartId', 'id']);
    if (cartId == null) {
      throw const FormatException('Cart response is missing cart_id');
    }

    // ─── Step 3: Read the remaining fields, tolerating both naming styles ───
    return Cart(
      cartId: cartId,
      cartStatus: _readString(data, const ['cart_status', 'status']),
      cartProductProviderId: _readInt(data, const [
        'cart_product_provider_id',
        'product_provider_id',
        'provider_id',
      ]),
      cartPersonRef: _readInt(data, const ['cart_person_ref', 'person_ref']),
      cartSellingUser:
          _readInt(data, const ['cart_selling_user', 'selling_user']),
      cartClientUser: _readInt(data, const ['cart_client_user', 'client_user']),
      cartNotes: _readString(data, const ['cart_notes', 'notes']),
      cartCreatedAt: _readString(data, const ['cart_created_at', 'created_at']),
      cartUpdatedAt: _readString(data, const ['cart_updated_at', 'updated_at']),
      cartTotalAmount: _readDouble(data, const [
        'cart_total_amount',
        'total_amount',
        'total',
      ]),
      // These are not populated by the create endpoint — the response only
      // carries metadata. Fetch the full cart separately if needed.
      invoices: const [],
      receipts: const [],
      deposits: const [],
      orderedItems: const [],
      orderedServices: const [],
    );
  }

  static Cart _fromLegacyListResponse(List<dynamic> jsonResponse) {
    Map<String, dynamic>? depositReceiptData;
    Map<String, dynamic>? cartData;

    for (final item in jsonResponse) {
      if (item is! Map<String, dynamic>) continue;

      if (item.containsKey('deposit') || item.containsKey('receipt')) {
        depositReceiptData = item;
      } else if (item.containsKey('cart_id') ||
          item.containsKey('cart_status') ||
          item.containsKey('cart_total_amount')) {
        cartData = item;
      }
    }

    if (cartData == null) {
      throw const FormatException('No cart data found in legacy list response');
    }

    final deposits = <Deposit>[];
    final depositJson = depositReceiptData?['deposit'];
    if (depositJson is Map<String, dynamic>) {
      try {
        deposits.add(Deposit.fromJson(depositJson));
      } catch (_) {}
    }

    final receipts = <Receipt>[];
    final receiptJson = depositReceiptData?['receipt'];
    if (receiptJson is Map<String, dynamic>) {
      try {
        receipts.add(Receipt.fromJson(receiptJson));
      } catch (_) {}
    }

    return Cart(
      cartId: cartData['cart_id'] as int?,
      cartStatus: cartData['cart_status'] as String?,
      cartProductProviderId: cartData['cart_product_provider_id'] as int?,
      cartPersonRef: cartData['cart_person_ref'] as int?,
      cartSellingUser: cartData['cart_selling_user'] as int?,
      cartClientUser: cartData['cart_client_user'] as int?,
      cartNotes: cartData['cart_notes'] as String?,
      cartCreatedAt: cartData['cart_created_at'] as String?,
      cartUpdatedAt: cartData['cart_updated_at'] as String?,
      cartTotalAmount: (cartData['cart_total_amount'] as num?)?.toDouble(),
      invoices: const [],
      receipts: receipts,
      deposits: deposits,
      orderedItems: const [],
      orderedServices: const [],
    );
  }

// ─── Typed readers ───

  static int? _readInt(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      final v = map[k];
      if (v == null) continue;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) {
        final parsed = int.tryParse(v);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static double? _readDouble(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      final v = map[k];
      if (v == null) continue;
      if (v is double) return v;
      if (v is num) return v.toDouble();
      if (v is String) {
        final parsed = double.tryParse(v);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static String? _readString(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      final v = map[k];
      if (v == null) continue;
      return v.toString();
    }
    return null;
  }

  // Factory constructor from API JSON (for detailed cart data)
  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      cartId: json['cart_id'] as int?,
      cartStatus: json['cart_status'] as String?,
      cartProductProviderId: json['cart_product_provider_id'] as int?,
      cartPersonRef: json['cart_person_ref'] as int?,
      cartSellingUser: json['cart_selling_user'] as int?,
      cartClientUser: json['cart_client_user'] as int?,
      cartNotes: json['cart_notes'] as String?,
      cartCreatedAt: json['cart_created_at'] as String?,
      cartUpdatedAt: json['cart_updated_at'] as String?,
      cartTotalAmount: (json['cart_total_amount'] as num?)?.toDouble(),

      invoices: (json['invoice'] as List<dynamic>?)
              ?.map((e) => Invoice.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],

      receipts: (json['receipt'] as List<dynamic>?)
              ?.map((e) => Receipt.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],

      deposits: (json['deposit'] as List<dynamic>?)
              ?.map((e) => Deposit.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],

      // NEW: Parse API ordered items and services
      orderedItems: (json['ordered_item'] as List<dynamic>?)
              ?.map((e) => OrderedItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],

      orderedServices: (json['ordered_service'] as List<dynamic>?)
              ?.map((e) => OrderedService.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],

      personData: json['person'] as Map<String, dynamic>?,
      userData: json['app_user_'] as Map<String, dynamic>?,
    );
  }

  String _generateItemKey({int? productId, int? serviceId}) {
    if (productId != null) {
      return 'product_$productId';
    } else if (serviceId != null) {
      return 'service_$serviceId';
    }
    throw ArgumentError('Either productId or serviceId must be provided');
  }

  // Named constructor for local shopping cart
  Cart.local()
      : cartId = null,
        cartStatus = 'open',
        cartProductProviderId = null,
        cartPersonRef = null,
        cartSellingUser = null,
        cartClientUser = null,
        cartNotes = null,
        cartCreatedAt = null,
        cartUpdatedAt = null,
        cartTotalAmount = null,
        invoices = const [],
        receipts = const [],
        deposits = const [],
        orderedItems = const [],
        orderedServices = const [],
        personData = null,
        userData = null;

  // Add a product to cart
  void addProduct(Product product, [int quantity = 1]) {
    if (quantity <= 0) throw ArgumentError('Quantity must be positive');
    if (product.id_product == null) {
      throw ArgumentError('Product ID cannot be null');
    }

    final key = _generateItemKey(productId: product.id_product);
    _items.update(
      key,
      (existing) => existing.copyWith(quantity: existing.quantity + quantity),
      ifAbsent: () => CartItem(product: product, quantity: quantity),
    );
  }

  // Add a service to cart
  void addService(
    ProvidedService service, {
    int quantity = 1,
    String? scheduledDate,
    String? scheduledTime,
  }) {
    if (quantity <= 0) throw ArgumentError('Quantity must be positive');

    final key = _generateItemKey(serviceId: service.id);
    _items.update(
      key,
      (existing) => existing.copyWith(quantity: existing.quantity + quantity),
      ifAbsent: () => CartItem(
        service: service,
        quantity: quantity,
        scheduledDate: scheduledDate,
        scheduledTime: scheduledTime,
      ),
    );
  }

  // Remove item by ID (product or service)
  bool removeItem({int? productId, int? serviceId}) {
    final key = _generateItemKey(productId: productId, serviceId: serviceId);
    return _items.remove(key) != null;
  }

// Update quantity of an item
  void updateQuantity({
    int? productId,
    int? serviceId,
    required int quantity,
  }) {
    final key = _generateItemKey(productId: productId, serviceId: serviceId);

    if (quantity <= 0) {
      removeItem(productId: productId, serviceId: serviceId);
    } else if (_items.containsKey(key)) {
      _items[key] = _items[key]!.copyWith(quantity: quantity);
    }
  }

  // Update service scheduling information
  void updateServiceScheduling({
    required int serviceId,
    String? scheduledDate,
    String? scheduledTime,
  }) {
    final key = _generateItemKey(serviceId: serviceId);
    if (_items.containsKey(key) && _items[key]!.isService) {
      _items[key] = _items[key]!.copyWith(
        scheduledDate: scheduledDate,
        scheduledTime: scheduledTime,
      );
    }
  }

  // Get all items (products and services)
  List<CartItem> get items => _items.values.toList();

  // Get only product items
  List<CartItem> get productItems =>
      items.where((item) => item.isProduct).toList();

  // Get only service items
  List<CartItem> get serviceItems =>
      items.where((item) => item.isService).toList();

  // Get item by product ID
  CartItem? getProductItem(int productId) {
    final key = _generateItemKey(productId: productId);
    final item = _items[key];
    return item?.isProduct == true ? item : null;
  }

  // Get item by service ID
  CartItem? getServiceItem(int serviceId) {
    final key = _generateItemKey(serviceId: serviceId);
    final item = _items[key];
    return item?.isService == true ? item : null;
  }

  // Check if product is in cart
  bool hasProduct(int productId) {
    final key = _generateItemKey(productId: productId);
    return _items.containsKey(key) && _items[key]!.isProduct;
  }

  // Check if service is in cart
  bool hasService(int serviceId) {
    final key = _generateItemKey(serviceId: serviceId);
    return _items.containsKey(key) && _items[key]!.isService;
  }

  // Calculate total quantity of all items
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  // Calculate subtotal for all items
  double get subtotal => items.fold(
        0.0,
        (sum, item) => sum + item.totalPrice,
      );

  // Calculate total with tax, shipping, etc. (you can customize this)
  double get totalAmount {
    // Add your tax, shipping, or other calculations here
    return subtotal;
  }

  // Clear all items
  void clear() => _items.clear();

  // Get cart item count
  int get itemCount => _items.length;

  // Check if cart is empty
  bool get isEmpty => _items.isEmpty;

  // Check if cart is not empty
  bool get isNotEmpty => _items.isNotEmpty;

  // Convert local cart items to JSON for API submission
  Map<String, dynamic> toJsonForApi() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'total': totalAmount,
      'item_count': itemCount,
    };
  }

  // Merge API cart data with local cart
  // void mergeWithApiCart(Cart apiCart) {
  //   // Clear existing items if needed (or merge based on your logic)
  //   _items.clear();

  //   // Add ordered items from API
  //   for (final orderedItem in apiCart.orderedItems) {
  //     if (orderedItem.product != null) {
  //       final key =
  //           _generateItemKey(productId: orderedItem.product!.id_product);
  //       _items[key] = CartItem(
  //         product: orderedItem.product,
  //         quantity: orderedItem.orderedItemQuantity,
  //       );
  //     }
  //   }

  //   // Add ordered services from API
  //   for (final orderedService in apiCart.orderedServices) {
  //     if (orderedService.service != null) {
  //       final key = _generateItemKey(serviceId: orderedService.service!.id);
  //       _items[key] = CartItem(
  //         service: orderedService.service,
  //         quantity: orderedService.orderedServiceQuantity,
  //         scheduledDate: orderedService.orderedServiceScheduledDate,
  //         scheduledTime: orderedService.orderedServiceScheduledTime,
  //       );
  //     }
  //   }
  // }

  @override
  String toString() {
    return 'Cart(items: ${items.length}, products: ${productItems.length}, services: ${serviceItems.length}, total: DZD$totalAmount)';
  }

  // ============ NEW METHODS FOR API DATA ============

  // Get all items (local + API ordered items + API ordered services)
  List<dynamic> getAllItems() {
    final List<dynamic> allItems = [];

    // Local cart items
    allItems.addAll(_items.values);

    // API ordered items
    allItems.addAll(orderedItems);

    // API ordered services
    allItems.addAll(orderedServices);

    return allItems;
  }

  // Get total from all sources (local + API)
  double get combinedTotal {
    double total = 0;

    // Local cart total
    total += _items.values.fold(0.0, (sum, item) => sum + item.totalPrice);

    // API ordered items total
    total += orderedItems.fold(
        0.0,
        (sum, item) =>
            sum +
            (item.unitPrice *
                item.orderedQuantity *
                (1 - (item.productDiscount ?? 0.0) / 100)));

    // API ordered services total
    total +=
        orderedServices.fold(0.0, (sum, service) => sum + service.totalPrice);

    return total;
  }

  // Check if has any items (local or API)
  bool get hasAnyItems =>
      _items.isNotEmpty ||
      orderedItems.isNotEmpty ||
      orderedServices.isNotEmpty;

  // ============ ORIGINAL GETTERS (unchanged) ============
  double get totalPrice =>
      _items.values.fold(0.0, (sum, item) => sum + item.totalPrice);
  int get productCount => _items.length;
  bool containsProduct(int productId) => _items.containsKey(productId);
  int getProductQuantity(int productId) => _items[productId]?.quantity ?? 0;

  // ============ ADDITIONAL GETTERS ============
  bool get isLocalCart => cartId == null;
  bool get isApiCart => cartId != null;

  Invoice? get primaryInvoice => invoices.isNotEmpty ? invoices.first : null;
  bool get hasInvoice => invoices.isNotEmpty;
  bool get hasReceipt => receipts.isNotEmpty;
  bool get hasDeposit => deposits.isNotEmpty;

  // String get formattedAmount {
  //   if (cartTotalAmount != null) {
  //     return 'DZD${cartTotalAmount!.toStringAsFixed(2)}';
  //   }
  //   return 'DZD${combinedTotal.toStringAsFixed(2)}';
  // }

  String get formattedDate {
    if (cartCreatedAt != null) {
      final date = DateTime.tryParse(cartCreatedAt!);
      if (date != null) return '${date.day}/${date.month}/${date.year}';
    }
    return DateTime.now().toIso8601String().split('T').first;
  }

  // Convert to API JSON format
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (cartId != null) json['cart_id'] = cartId;
    if (cartStatus != null) json['cart_status'] = cartStatus;
    if (cartProductProviderId != null)
      json['cart_product_provider_id'] = cartProductProviderId;
    if (cartPersonRef != null) json['cart_person_ref'] = cartPersonRef;
    if (cartSellingUser != null) json['cart_selling_user'] = cartSellingUser;
    if (cartClientUser != null) json['cart_client_user'] = cartClientUser;
    if (cartNotes != null) json['cart_notes'] = cartNotes;
    if (cartCreatedAt != null) json['cart_created_at'] = cartCreatedAt;
    if (cartUpdatedAt != null) json['cart_updated_at'] = cartUpdatedAt;
    if (cartTotalAmount != null) json['cart_total_amount'] = cartTotalAmount;

    json['invoice'] = invoices.map((e) => e.toJson()).toList();
    json['receipt'] = receipts.map((e) => e.toJson()).toList();
    json['deposit'] = deposits.map((e) => e.toJson()).toList();

    // NEW: Add API ordered items and services
    json['ordered_item'] =
        _items.values.where((t) => t.isProduct).map((e) => e.toJson()).toList();
    json['ordered_service'] =
        _items.values.where((t) => t.isService).map((e) => e.toJson()).toList();

    if (personData != null) json['person'] = personData;
    if (userData != null) json['app_user_'] = userData;

    return json;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Cart && other.cartId == cartId;
  }

  @override
  int get hashCode => cartId?.hashCode ?? 0;
}

// Supporting Invoice class (unchanged)
class Invoice {
  final int invoiceId;
  final int? invoiceCartId;
  final String invoiceIssueDate;
  final String? invoiceNotes;
  final String invoiceUpdatedAt;
  final String invoiceNumber;
  final double invoiceTotalAmount;
  final String invoiceStatus;
  final String? invoiceDueDate;
  final String invoiceCreatedAt;

  const Invoice({
    required this.invoiceId,
    required this.invoiceCartId,
    required this.invoiceIssueDate,
    this.invoiceNotes,
    required this.invoiceUpdatedAt,
    required this.invoiceNumber,
    required this.invoiceTotalAmount,
    required this.invoiceStatus,
    this.invoiceDueDate,
    required this.invoiceCreatedAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      invoiceId: json['invoice_id'] as int,
      invoiceCartId: json['invoice_cart_id'] as int?,
      invoiceIssueDate: json['invoice_issue_date'] as String,
      invoiceNotes: json['invoice_notes'] as String?,
      invoiceUpdatedAt: json['invoice_updated_at'] as String,
      invoiceNumber: json['invoice_number'] as String,
      invoiceTotalAmount: (json['invoice_total_amount'] as num).toDouble(),
      invoiceStatus: json['invoice_status'] as String,
      invoiceDueDate: json['invoice_due_date'] as String?,
      invoiceCreatedAt: json['invoice_created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'invoice_id': invoiceId,
        'invoice_cart_id': invoiceCartId,
        'invoice_issue_date': invoiceIssueDate,
        'invoice_notes': invoiceNotes,
        'invoice_updated_at': invoiceUpdatedAt,
        'invoice_number': invoiceNumber,
        'invoice_total_amount': invoiceTotalAmount,
        'invoice_status': invoiceStatus,
        'invoice_due_date': invoiceDueDate,
        'invoice_created_at': invoiceCreatedAt,
      };
}

// Extended Receipt model based on database schema
class Receipt {
  final int receiptId;
  final int? receiptPaymentId;
  final String? receiptNumber;
  final double receiptAmount;
  final String? receiptNotes;
  final String receiptCreatedAt;
  final int? receiptCartRef;

  Receipt({
    required this.receiptId,
    this.receiptPaymentId,
    this.receiptNumber,
    required this.receiptAmount,
    this.receiptNotes,
    required this.receiptCreatedAt,
    this.receiptCartRef,
  });

  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      receiptId: json['receipt_id'] as int,
      receiptPaymentId: json['receipt_payment_id'] as int?,
      receiptNumber: json['receipt_number'] as String?,
      receiptAmount: (json['receipt_amount'] as num).toDouble(),
      receiptNotes: json['receipt_notes'] as String?,
      receiptCreatedAt: json['receipt_created_at'] as String,
      receiptCartRef: json['receipt_cart_ref'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'receipt_id': receiptId,
        'receipt_payment_id': receiptPaymentId,
        'receipt_number': receiptNumber,
        'receipt_amount': receiptAmount,
        'receipt_notes': receiptNotes,
        'receipt_created_at': receiptCreatedAt,
        'receipt_cart_ref': receiptCartRef,
      };
}

// Extended Deposit model based on database schema
class Deposit {
  final int depositId;
  final int? depositCartId;
  final int? depositInvoiceId;
  final double depositAmount;
  final String depositMethod;
  final String? depositReference;
  final String? depositNotes;
  final String depositCreatedAt;
  final String depositUpdatedAt;
  final int? depositReceiptId;

  Deposit({
    required this.depositId,
    this.depositCartId,
    this.depositInvoiceId,
    required this.depositAmount,
    required this.depositMethod,
    this.depositReference,
    this.depositNotes,
    required this.depositCreatedAt,
    required this.depositUpdatedAt,
    this.depositReceiptId,
  });

  factory Deposit.fromJson(Map<String, dynamic> json) {
    return Deposit(
      depositId: json['deposit_id'] as int,
      depositCartId: json['deposit_cart_id'] as int?,
      depositInvoiceId: json['deposit_invoice_id'] as int?,
      depositAmount: (json['deposit_amount'] as num).toDouble(),
      depositMethod: json['deposit_method'] as String,
      depositReference: json['deposit_reference'] as String?,
      depositNotes: json['deposit_notes'] as String?,
      depositCreatedAt: json['deposit_created_at'] as String,
      depositUpdatedAt: json['deposit_updated_at'] as String,
      depositReceiptId: json['deposit_receipt_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'deposit_id': depositId,
        'deposit_cart_id': depositCartId,
        'deposit_invoice_id': depositInvoiceId,
        'deposit_amount': depositAmount,
        'deposit_method': depositMethod,
        'deposit_reference': depositReference,
        'deposit_notes': depositNotes,
        'deposit_created_at': depositCreatedAt,
        'deposit_updated_at': depositUpdatedAt,
        'deposit_receipt_id': depositReceiptId,
      };
}

class CheckoutData {
  final Cart cart;
  final AppUser? selectedCustomer;
  final double totalAmount;
  final String notes;
  final bool invoice;
  final bool receipt;
  final bool deposit;
  final bool payment;
  final double paidMoney;
  final String paymentMethod;

  CheckoutData({
    required this.cart,
    required this.selectedCustomer,
    required this.totalAmount,
    this.notes = '',
    this.invoice = false,
    this.receipt = false,
    this.deposit = false,
    this.payment = false,
    this.paidMoney = 0.0,
    this.paymentMethod = 'cash',
  });

  Map<String, dynamic> toJson() {
    // Build ordered items from cart (products)
    final List<Map<String, dynamic>> orderedItems = [];

    for (final cartItem in cart.items.where((item) => item.isProduct)) {
      orderedItems.add({
        "id_ordered_item": 0,
        "ordered_product_id": cartItem.product?.id_product ?? 0,
        "order_ref": 0,
        "product_discount": cartItem.lineDiscount,
        "ordered_quantity": cartItem.quantity,
        "unit_price": cartItem.unitPrice ?? 0.0,
        "applied_vat": 0.0,
      });
    }

    // Build provided services from cart (services)
    final List<Map<String, dynamic>> providedServices = [];

    for (final cartItem in cart.items.where((item) => item.isService)) {
      providedServices.add({
        "ordered_service_service_id": cartItem.service?.id ?? 0,
        "ordered_service_quantity": cartItem.quantity,
        "ordered_service_unit_price": cartItem.unitPrice ?? 0.0,
        "ordered_service_total_price": cartItem.totalPrice,
        "ordered_service_scheduled_at": cartItem.scheduledDate ?? "",
        "ordered_service_notes": cartItem.scheduledTime ?? "",
        "resource_requirement_id":
            cartItem.service?.resourceRequirements.first.id ?? 0,
      });
    }

    // Build cart data
    final Map<String, dynamic> apiCart = {
      "cart_id": cart.cartId ?? 0,
      "cart_product_provider_id": cart.cartProductProviderId ?? 0,
      "cart_selling_user": cart.cartSellingUser ?? 0,
      "cart_person_ref": cart.cartPersonRef ?? 0,
      "cart_client_user":
          cart.cartClientUser ?? selectedCustomer?.idAppUser ?? 0,
      "cart_status": "PENDING",
      "cart_total_amount": totalAmount,
      "cart_notes": notes,
      "cart_invoice": invoice,
      "cart_receipt": receipt,
      "cart_deposit": deposit,
      "cart_payment": payment,
      "cart_paid_money": paidMoney,
    };

    // Build client data from selected customer
    final Map<String, dynamic> client = {
      "id_person": selectedCustomer?.idAppUser ?? selectedCustomer?.idPerson,
      "person_details_id": 0,
      "id_person_details": 0,
      "person_first_name": selectedCustomer?.personFirstName ?? "string",
      "person_last_name": selectedCustomer?.personLastName ?? "string",
      "person_birth_date": selectedCustomer?.personBirthDate ?? "string",
      "person_gender": selectedCustomer?.personGender ?? "string",
      "person_nationality": selectedCustomer?.personCountryCode ?? "string",
      "id_blood_type": 0,
    };

    return {
      "api_ordered_items": orderedItems,
      "api_provided_services": providedServices,
      "api_cart": apiCart,
      "client": client,
      "payment_method": paymentMethod,
    };
  }

  // factory CheckoutData.fromViewModel({
  //   required CheckoutViewModel viewModel,
  //   required Cart cart,
  //   required double totalAmount,
  // }) {
  //   return CheckoutData(
  //     cart: cart,
  //     selectedCustomer: viewModel.selectedCustomer,
  //     totalAmount: totalAmount,
  //     notes: viewModel.notes,
  //     invoice: viewModel.documentType == 'invoice',
  //     receipt: viewModel.documentType == 'receipt',
  //     deposit: viewModel.paymentType == 'deposit',
  //     payment: viewModel.paymentType == 'payment',
  //     paidMoney: 0.0, // You'll need to calculate this based on your logic
  //     paymentMethod: viewModel.paymentMethod,
  //   );
  // }
}
