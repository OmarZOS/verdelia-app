// lib/business/Cart.dart

import 'package:decimal/decimal.dart';

import 'package:verdelia_core/app/AppUser.dart';
import 'package:verdelia_core/app/Person.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:verdelia_core/business/finance/Order.dart';
import 'package:verdelia_core/business/finance/OrderedItem.dart';
import 'package:verdelia_core/business/finance/OrderedService.dart';
import 'package:verdelia_core/business/finance/ProvidedService.dart';

// ============================================================================
// Decimal helpers
// ============================================================================

/// Zero, shared as a constant so the code reads `Decimal.zero` and
/// allocates once.
extension _DecimalZero on Decimal {
  static final Decimal zero = Decimal.zero;
}

/// Coerces any JSON value to [Decimal].
///
/// * [Decimal] → passthrough
/// * `int`     → `Decimal.fromInt`
/// * `double`  → `Decimal.parse(v.toString())` (shortest round-trip,
///                NOT the binary expansion)
/// * `String`  → `Decimal.tryParse`
/// * anything else → `null`
///
/// Rejects non-finite `double`s so a malformed payload can't poison
/// downstream arithmetic.
Decimal? _readDecimal(dynamic v) {
  if (v == null) return null;
  if (v is Decimal) return v;
  if (v is int) return Decimal.fromInt(v);
  if (v is double) {
    if (v.isNaN || v.isInfinite) return null;
    return Decimal.tryParse(v.toString());
  }
  if (v is String) return Decimal.tryParse(v);
  return null;
}

/// Converts a [Decimal] to the shortest `double` that round-trips.
/// For the JSON wire boundary only — never use this for arithmetic.
double _decimalToDouble(Decimal v) => double.parse(v.toString());

/// Serialises a [Decimal] for JSON. Emits a `num` so `jsonEncode`
/// writes it as a JSON number, not a string.
num _decimalToWire(Decimal v) => _decimalToDouble(v);

// ============================================================================
// CartItem
// ============================================================================

/// One line on a cart — either a product or a service.
///
/// The two kinds of line go to different sub-objects on the API
/// (`OrderedItem_API` and `OrderedService_API`) and the two sub-objects
/// use **different naming conventions**:
///
/// * `OrderedItem_API` is **flat**: `product_id`, `ordered_quantity`,
///   `unit_price`, `vat_rate`, `product_discount`.
/// * `OrderedService_API` is **prefixed**: `ordered_service_service_id`,
///   `ordered_service_quantity`, `ordered_service_unit_price`,
///   `ordered_service_total_price`, `ordered_service_scheduled_at`.
///
/// **Serialisation split**
///
/// [toJson] is a **persistence-only** serializer: it round-trips with
/// [Cart.fromJson] and mirrors the *read* shape so a local cart survives
/// a save/reload cycle. It is **not** a create-payload serializer — the
/// create shape lives in [CartPayloadBuilder] (which delegates product
/// lines to `OrderedItem.toOrderedItemApiJson()` and builds service lines
/// inline with VAT stripped). Do not call [toJson] from an API write
/// path.
///
/// **Money**
///
/// Every monetary field (`unitPrice`, `totalPrice`, `lineDiscount`,
/// `customPrice`, `discountPercent`) is a [Decimal]. Prices are compared
/// and multiplied only in `Decimal`; the `double` conversion happens
/// once, at the JSON boundary in [toJson] via [_decimalToWire].
class CartItem {
  final Product? product;
  final ProvidedService? service;
  final Decimal? customPrice; // null → use default price

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

  // ── Pricing ────────────────────────────────────────────────────

  /// Effective unit price after any custom override.
  Decimal? get unitPrice {
    final custom = customPrice;
    if (custom != null && custom > Decimal.zero) return custom;
    if (product != null) return _readDecimal(product!.product_price);
    if (service != null) return _readDecimal(service!.finalPrice);
    return Decimal.zero;
  }

  /// Catalog unit price (the "reference" price used to compute
  /// discount).
  Decimal? get catalogUnitPrice {
    if (product != null) return _readDecimal(product!.product_price);
    if (service != null) return _readDecimal(service!.finalPrice);
    return Decimal.zero;
  }

  /// Total discount for this line = (catalog − custom) × qty.
  /// Zero when there's no custom price.
  Decimal get lineDiscount {
    final catalog = catalogUnitPrice ?? Decimal.zero;
    final effective = unitPrice ?? Decimal.zero;
    if (effective >= catalog) return Decimal.zero;
    return (catalog - effective) * Decimal.fromInt(quantity);
  }

  Decimal get totalPrice =>
      (unitPrice ?? Decimal.zero) * Decimal.fromInt(quantity);

  bool get hasCustomPrice {
    final custom = customPrice;
    final catalog = catalogUnitPrice ?? Decimal.zero;
    return custom != null && custom > Decimal.zero && custom != catalog;
  }

  // ── Identity ───────────────────────────────────────────────────

  int get itemId => product?.id_product ?? service?.id ?? 0;

  String get itemName => product?.product_name ?? service?.name ?? '';

  bool get isService => service != null;
  bool get isProduct => product != null;

  String? get durationFormatted => service?.durationFormatted;

  String get description =>
      product?.product_description ?? service?.description ?? '';

  // ── VAT ────────────────────────────────────────────────────────

  /// VAT as a fraction in [0, 1]. This is how
  /// `Product.product_vat_value` stores it.
  Decimal get vatFraction {
    final raw = _readDecimal(product?.product_vat_value);
    return raw ?? Decimal.zero;
  }

  /// VAT as a percentage in [0, 100] — the form `OrderedItem_API.vat_rate`
  /// expects. If [vatFraction] is already `19.0` (some backends store it
  /// as a percent), this returns `19.0` rather than `1900.0`. The clamp
  /// is what saves us from the two conventions colliding.
  Decimal get appliedVatPercent {
    final raw = vatFraction;
    // If the value is > 1, it's already a percentage.
    if (raw > Decimal.one) return _clampDecimal(raw, Decimal.zero, _hundred);
    // Otherwise treat it as a fraction.
    return _clampDecimal(
      raw * _hundred,
      Decimal.zero,
      _hundred,
    );
  }

  // ── Discount as percentage ────────────────────────────────────

  /// Percentage discount on this line, for `OrderedItem_API.product_discount`.
  ///
  /// Semantics per the API: `20.0` → sell at 80% of catalog, `0.0` →
  /// catalog, `100.0` → free. Returns `Decimal.zero` when the catalog
  /// is unknown.
  Decimal get discountPercent {
    final catalog = catalogUnitPrice ?? Decimal.zero;
    if (catalog <= Decimal.zero) return Decimal.zero;
    final effective = unitPrice ?? Decimal.zero;
    return ((catalog - effective) / catalog)
            .toDecimal(scaleOnInfinitePrecision: 2) *
        _hundred;
  }

  // ── copyWith ──────────────────────────────────────────────────

  CartItem copyWith({
    Product? product,
    ProvidedService? service,
    String? scheduledDate,
    String? scheduledTime,
    Decimal? customPrice,
    int? quantity,
    bool clearCustomPrice = false,
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

  // ── Serialisation (persistence) ──────────────────────────────

  /// Serialises this line for **local persistence only**.
  ///
  /// Round-trips with [Cart.fromJson]. Emits the read-side field names
  /// so a saved cart reloads with the same shape it would have received
  /// from `GET /business/carts/{id}`.
  ///
  /// **Do not use this for API create requests.** The write contract
  /// lives in [CartPayloadBuilder]:
  ///
  ///   * product lines → `OrderedItem.toOrderedItemApiJson()` (which
  ///     pins the exact field names `OrderedItem_API` accepts), and
  ///   * service lines → `CartPayloadBuilder._buildOrderedServices()`
  ///     (which strips VAT because `OrderedService_API` prices are
  ///     VAT-exclusive).
  ///
  /// This method emits VAT-*inclusive* prices and the line's own VAT,
  /// matching [unitPrice] / [totalPrice] — i.e. what the local UI
  /// shows. That is deliberately different from the write shape.
  ///
  /// Monetary values are emitted via [_decimalToWire], so the JSON
  /// number is the shortest round-trip form of the Decimal.
  Map<String, dynamic> toJson() {
    if (product != null) {
      final json = <String, dynamic>{
        'product_id': product!.id_product,
        'ordered_quantity': quantity,
        'unit_price': _decimalToWire(unitPrice ?? Decimal.zero),
        'vat_rate': _decimalToWire(appliedVatPercent),
      };
      if (hasCustomPrice) {
        json['product_discount'] = _decimalToWire(discountPercent);
      }
      return json;
    }

    if (service != null) {
      final json = <String, dynamic>{
        'ordered_service_service_id': service!.id,
        'ordered_service_quantity': quantity,
        'ordered_service_unit_price': _decimalToWire(unitPrice ?? Decimal.zero),
        'ordered_service_total_price': _decimalToWire(totalPrice),
      };
      if (scheduledDate != null) {
        // `OrderedService_API.ordered_service_scheduled_at` is a
        // datetime. Combine the date-only value with the optional
        // time into an ISO-8601 string the model can parse.
        final d = scheduledDate!;
        final t = scheduledTime;
        final combined = t != null ? '${d}T$t' : d;
        json['ordered_service_scheduled_at'] = combined;
      }
      return json;
    }

    return <String, dynamic>{};
  }

  @override
  String toString() {
    return 'CartItem(${isProduct ? 'Product' : 'Service'}: $itemName, '
        'Quantity: $quantity, Total: DZD$totalPrice)';
  }
}

// ============================================================================
// Cart
// ============================================================================

/// A cart, in either of two states:
///
/// * **Local cart** — the user is still adding items in the app. The
///   `_items` map is populated; `cartId` is null.
/// * **API cart** — the cart has been persisted by the server. `cartId`
///   is set, `orderedItems` / `orderedServices` are populated from the
///   response, and the local `_items` map is empty.
///
/// ## Wire shapes
///
/// The **read** response (from `/business/carts/{id}` and from the
/// operations list) carries flat `cart_*`-prefixed fields, a
/// **single** `invoice` object (not a list), and `ordered_item` /
/// `ordered_service` arrays of `OrderedItem` / `OrderedService` rows.
///
/// The **write** contract is `CartCreateRequest`, built by
/// [CartPayloadBuilder.build]. Do **not** hand-build create bodies from
/// this class — the builder knows which VAT convention each sub-object
/// uses, and it is the only place the wire field names live.
///
/// `Cart_API` itself only has nine fields — see [toCartApiJson]. Every
/// other field the read shape carries (`cart_id`, `cart_product_provider_id`,
/// timestamps, invoices, deposits, ...) is server-owned and must NOT be
/// sent on write.
///
/// ## Money
///
/// Every monetary field — [cartTotalAmount], [subtotal],
/// [combinedTotal], [CartItem.unitPrice], [Invoice.invoiceTotalAmount],
/// [Deposit.depositAmount], [Receipt.receiptAmount] — is a [Decimal].
/// Nothing in this file does money arithmetic in `double`. The only
/// conversion to `double` happens inside [toJson] / [toCartApiJson] /
/// [Invoice.toJson] / [Deposit.toJson] / [Receipt.toJson] via
/// [_decimalToWire], at the JSON boundary.
class Cart {
  // ── Local cart items ─────────────────────────────────────────
  final Map<String, CartItem> _items = {};

  // ── Persisted cart fields (read response) ────────────────────
  final int? cartId;
  final String? cartStatus;
  final int? cartProductProviderId;
  final int? cartPersonRef;
  final int? cartSellingUser;
  final int? cartClientUser;
  final String? cartNotes;
  final String? cartCreatedAt;
  final String? cartUpdatedAt;
  final Decimal? cartTotalAmount;
  final List<Invoice> invoices;
  final List<Receipt> receipts;
  final List<Deposit> deposits;

  // ── API line items (read response) ───────────────────────────
  final List<OrderedItem> orderedItems;
  final List<OrderedService> orderedServices;

  // ── Nested inlined users / persons ───────────────────────────
  final Map<String, dynamic>? personData;
  final Map<String, dynamic>? userData;

  // ── Constructor ──────────────────────────────────────────────
  Cart({
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
    this.orderedItems = const [],
    this.orderedServices = const [],
    this.personData,
    this.userData,
  });

  Cart copyWith({
    int? cartId,
    String? cartStatus,
    int? cartProductProviderId,
    int? cartPersonRef,
    int? cartSellingUser,
    int? cartClientUser,
    String? cartNotes,
    String? cartCreatedAt,
    String? cartUpdatedAt,
    Decimal? cartTotalAmount,
    List<Invoice>? invoices,
    List<Receipt>? receipts,
    List<Deposit>? deposits,
    List<OrderedItem>? orderedItems,
    List<OrderedService>? orderedServices,
    Map<String, dynamic>? personData,
    Map<String, dynamic>? userData,
    List<CartItem>? items,
  }) {
    final copy = Cart(
      cartId: cartId ?? this.cartId,
      cartStatus: cartStatus ?? this.cartStatus,
      cartProductProviderId:
          cartProductProviderId ?? this.cartProductProviderId,
      cartPersonRef: cartPersonRef ?? this.cartPersonRef,
      cartSellingUser: cartSellingUser ?? this.cartSellingUser,
      cartClientUser: cartClientUser ?? this.cartClientUser,
      cartNotes: cartNotes ?? this.cartNotes,
      cartCreatedAt: cartCreatedAt ?? this.cartCreatedAt,
      cartUpdatedAt: cartUpdatedAt ?? this.cartUpdatedAt,
      cartTotalAmount: cartTotalAmount ?? this.cartTotalAmount,
      invoices: invoices ?? this.invoices,
      receipts: receipts ?? this.receipts,
      deposits: deposits ?? this.deposits,
      orderedItems: orderedItems ?? this.orderedItems,
      orderedServices: orderedServices ?? this.orderedServices,
      personData: personData ?? this.personData,
      userData: userData ?? this.userData,
    );

    // Seed the new instance's local lines. `copy` has an empty `_items`
    // map at this point because the named constructor does not accept
    // it. We replay the items through the same public mutators the
    // original uses so that any per-item invariants (the key format,
    // the product/service assertion, the quantity clamp) hold.
    //
    // Products whose `id_product` is null are skipped — `addProduct`
    // would throw, and a product without an id cannot be re-added
    // through the public API anyway.
    final source = items ?? this.items;
    for (final item in source) {
      if (item.isProduct && item.product != null) {
        if (item.product!.id_product == null) continue;
        copy.addProduct(item.product!, item.quantity);
      } else if (item.isService && item.service != null) {
        copy.addService(
          item.service!,
          quantity: item.quantity,
          scheduledDate: item.scheduledDate,
          scheduledTime: item.scheduledTime,
        );
      }
      // Preserve the custom price override. `addProduct` / `addService`
      // don't know about it, so apply it after the fact.
      if (item.customPrice != null) {
        copy.updateItemPrice(
          productId: item.isProduct ? item.product?.id_product : null,
          serviceId: item.isService ? item.service?.id : null,
          customPrice: item.customPrice,
        );
      }
    }

    return copy;
  }

  // ── Local-only constructor ───────────────────────────────────
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

  // ========================================================================
  // READ FACTORIES
  // ========================================================================

  /// Parse a cart from the **read** endpoint (`GET /business/carts/{id}`)
  /// or from an operation's nested `cart` block.
  ///
  /// Wire shape (abbreviated, from the sample payload):
  ///
  /// ```json
  /// {
  ///   "cart_id": 4,
  ///   "cart_status": "pending",
  ///   "provider_id": 1,
  ///   "client_user_id": 4,
  ///   "selling_user_id": 4,
  ///   "client_person_id": null,
  ///   "notes": "...",
  ///   "subtotal": 972.25,
  ///   "created_at": "2026-10-23T20:41:32",
  ///   "updated_at": "2026-10-23T20:41:33",
  ///   "invoice": { ...single invoice object, NOT a list... },
  ///   "ordered_item": [ ... ],
  ///   "ordered_service": [ ... ]
  /// }
  /// ```
  ///
  /// Fields accepted as fallbacks:
  ///   * `provider_id` ← also `cart_product_provider_id` / `product_provider_id`
  ///   * `client_user_id` ← also `cart_client_user` / `client_user`
  ///   * `selling_user_id` ← also `cart_selling_user` / `selling_user`
  ///   * `client_person_id` ← also `cart_person_ref` / `person_ref`
  ///   * `notes` ← also `cart_notes`
  ///   * `created_at` ← also `cart_created_at`
  ///   * `updated_at` ← also `cart_updated_at`
  ///   * `subtotal` ← also `cart_total_amount` / `total_amount` / `total`
  factory Cart.fromJson(Map<String, dynamic> json) {
    // The read payload nests `invoice` as a single Map, not a List.
    // Tolerate both for backward compatibility with the older shape.
    final invoiceRaw = json['invoice'];
    final invoices = _parseListOrSingle(invoiceRaw, Invoice.fromJson);

    final receipts = _parseListOrSingle(json['receipt'], Receipt.fromJson);
    final deposits = _parseListOrSingle(json['deposit'], Deposit.fromJson);

    return Cart(
      cartId: _readInt(json, const ['cart_id', 'cartId', 'id']),
      cartStatus: _readString(json, const ['cart_status', 'status']),
      cartProductProviderId: _readInt(
        json,
        const [
          'provider_id',
          'product_provider_id',
          'cart_product_provider_id',
        ],
      ),
      cartPersonRef: _readInt(
        json,
        const ['client_person_id', 'cart_person_ref', 'person_ref'],
      ),
      cartSellingUser: _readInt(
        json,
        const ['selling_user_id', 'cart_selling_user', 'selling_user'],
      ),
      cartClientUser: _readInt(
        json,
        const ['client_user_id', 'cart_client_user', 'client_user'],
      ),
      cartNotes: _readString(json, const ['notes', 'cart_notes']),
      cartCreatedAt: _readString(json, const ['created_at', 'cart_created_at']),
      cartUpdatedAt: _readString(json, const ['updated_at', 'cart_updated_at']),
      cartTotalAmount: _readDecimalFrom(
        json,
        const [
          'subtotal',
          'cart_total_amount',
          'total_amount',
          'total',
        ],
      ),
      invoices: invoices,
      receipts: receipts,
      deposits: deposits,
      orderedItems: _parseOrderedItems(json['ordered_item']),
      orderedServices: _parseOrderedServices(json['ordered_service']),
      personData: _asMapOrNull(json['person']),
      userData:
          _asMapOrNull(json['app_user']) ?? _asMapOrNull(json['app_user_']),
    );
  }

  /// Parse a cart from the **create response** (`POST /business/carts`).
  ///
  /// The create response is shape-compatible with the read response but
  /// often carries only a subset (no invoices / deposits yet). Both
  /// factories delegate to the same underlying reader; the difference
  /// is that `fromResponseJson` tolerates a wrapped `{data: {...}}`
  /// envelope and a legacy `[deposit, cart]` array.
  factory Cart.fromResponseJson(dynamic json) {
    if (json == null) {
      throw const FormatException('Null cart response');
    }

    // Legacy shape: array of `[depositData, cartData]`.
    if (json is List) {
      return _fromLegacyListResponse(json);
    }

    if (json is! Map) {
      throw FormatException(
        'Unexpected cart response type: ${json.runtimeType}',
      );
    }

    final asMap = Map<String, dynamic>.from(json);

    // Unwrap `{data: {...}}` envelope if present.
    final envelope = asMap['data'];
    final data = envelope is Map ? Map<String, dynamic>.from(envelope) : asMap;

    final cartId = _readInt(data, const ['cart_id', 'cartId', 'id']);
    if (cartId == null) {
      throw const FormatException('Cart response is missing cart_id');
    }

    return Cart.fromJson({...data, 'cart_id': cartId});
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
      throw const FormatException(
        'No cart data found in legacy list response',
      );
    }

    final deposits = <Deposit>[];
    final depositJson = depositReceiptData?['deposit'];
    if (depositJson is Map) {
      try {
        deposits.add(Deposit.fromJson(Map<String, dynamic>.from(depositJson)));
      } catch (_) {}
    }

    final receipts = <Receipt>[];
    final receiptJson = depositReceiptData?['receipt'];
    if (receiptJson is Map) {
      try {
        receipts.add(Receipt.fromJson(Map<String, dynamic>.from(receiptJson)));
      } catch (_) {}
    }

    return Cart.fromJson({
      ...cartData,
      'deposit':
          deposits.isEmpty ? null : deposits.map((e) => e.toJson()).toList(),
      'receipt':
          receipts.isEmpty ? null : receipts.map((e) => e.toJson()).toList(),
    });
  }

  // ========================================================================
  // WRITE BODIES
  // ========================================================================

  /// The `Cart_API` sub-object, without the top-level wrapper.
  ///
  /// Useful for `PATCH /business/carts/{id}/status` and for any other
  /// endpoint that takes a `Cart_API` directly. Nine fields; nothing
  /// else belongs here.
  ///
  /// **Do not** use this to build a create body — that's
  /// [CartPayloadBuilder.build]. This method only emits the subset that
  /// `Cart_API` itself accepts, and the builder is where the full
  /// `CartCreateRequest` (including line items, client, delivery and
  /// payment intent) comes together.
  Map<String, dynamic> toCartApiJson({
    bool? cartPayment,
    bool? cartDeposit,
    Decimal? cartPaidMoney,
    String? cartPaymentMethod,
  }) {
    return <String, dynamic>{
      'cart_status': cartStatus ?? 'open',
      if (cartTotalAmount != null)
        'cart_total_amount': _decimalToWire(cartTotalAmount!),
      if (cartNotes != null) 'cart_notes': cartNotes,
      if (cartPayment != null) 'cart_payment': cartPayment,
      if (cartDeposit != null) 'cart_deposit': cartDeposit,
      if (cartPaidMoney != null)
        'cart_paid_money': _decimalToWire(cartPaidMoney),
      if (cartPaymentMethod != null) 'cart_payment_method': cartPaymentMethod,
    };
  }

  // ========================================================================
  // LOCAL PERSISTENCE
  // ========================================================================

  /// Serialises the **full cart snapshot** for local persistence.
  ///
  /// This method is NOT an API body. Its shape round-trips with
  /// [Cart.fromJson] because both sides use the same read-friendly
  /// field names. The API write bodies are built by
  /// [CartPayloadBuilder.build] (for `POST /business/carts`) and
  /// [toCartApiJson] (for `Cart_API`-shaped endpoints).
  ///
  /// The `ordered_item` / `ordered_service` lists here are built from
  /// `_items` (the local cart lines). For an **API cart**, use
  /// `orderedItems` / `orderedServices` directly — they're already in
  /// the read shape.
  ///
  /// Monetary values are emitted via [_decimalToWire] so the persisted
  /// JSON round-trips exactly.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (cartId != null) json['cart_id'] = cartId;
    if (cartStatus != null) json['cart_status'] = cartStatus;
    if (cartProductProviderId != null) {
      json['provider_id'] = cartProductProviderId;
    }
    if (cartPersonRef != null) json['client_person_id'] = cartPersonRef;
    if (cartSellingUser != null) json['selling_user_id'] = cartSellingUser;
    if (cartClientUser != null) json['client_user_id'] = cartClientUser;
    if (cartNotes != null) json['notes'] = cartNotes;
    if (cartCreatedAt != null) json['created_at'] = cartCreatedAt;
    if (cartUpdatedAt != null) json['updated_at'] = cartUpdatedAt;
    if (cartTotalAmount != null) {
      json['subtotal'] = _decimalToWire(cartTotalAmount!);
    }

    // `invoice` is a single object in the read shape. If the local
    // cart has more than one, emit only the first — the read endpoint
    // returns one invoice per cart.
    if (invoices.isNotEmpty) json['invoice'] = invoices.first.toJson();
    if (receipts.isNotEmpty) {
      json['receipt'] = receipts.map((e) => e.toJson()).toList();
    }
    if (deposits.isNotEmpty) {
      json['deposit'] = deposits.map((e) => e.toJson()).toList();
    }

    // Local cart lines, serialised in the **read** shape so the round
    // trip through `fromJson` is lossless. `CartItem.toJson` is the
    // persistence serializer; the create serializer lives in
    // `CartPayloadBuilder`.
    if (_items.isNotEmpty) {
      json['ordered_item'] = _items.values
          .where((i) => i.isProduct)
          .map((i) => i.toJson())
          .toList();
      json['ordered_service'] = _items.values
          .where((i) => i.isService)
          .map((i) => i.toJson())
          .toList();
    } else {
      if (orderedItems.isNotEmpty) {
        json['ordered_item'] = orderedItems.map((e) => e.toJson()).toList();
      }
      if (orderedServices.isNotEmpty) {
        json['ordered_service'] =
            orderedServices.map((e) => e.toJson()).toList();
      }
    }

    if (personData != null) json['person'] = personData;
    if (userData != null) json['app_user'] = userData;

    return json;
  }

  // ========================================================================
  // LOCAL CART MUTATIONS
  // ========================================================================

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

  bool removeItem({int? productId, int? serviceId}) {
    final key = _generateItemKey(productId: productId, serviceId: serviceId);
    return _items.remove(key) != null;
  }

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

  void updateItemPrice({
    int? productId,
    int? serviceId,
    required Decimal? customPrice,
  }) {
    final key = _generateItemKey(productId: productId, serviceId: serviceId);
    final existing = _items[key];
    if (existing == null) return;

    _items[key] = existing.copyWith(
      customPrice: customPrice,
      clearCustomPrice: customPrice == null,
    );
  }

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

  void clear() => _items.clear();

  // ========================================================================
  // LOCAL CART READS
  // ========================================================================

  List<CartItem> get items => _items.values.toList();
  List<CartItem> get productItems =>
      items.where((item) => item.isProduct).toList();
  List<CartItem> get serviceItems =>
      items.where((item) => item.isService).toList();

  CartItem? getProductItem(int productId) {
    final key = _generateItemKey(productId: productId);
    final item = _items[key];
    return item?.isProduct == true ? item : null;
  }

  CartItem? getServiceItem(int serviceId) {
    final key = _generateItemKey(serviceId: serviceId);
    final item = _items[key];
    return item?.isService == true ? item : null;
  }

  bool hasProduct(int productId) {
    final key = _generateItemKey(productId: productId);
    return _items.containsKey(key) && _items[key]!.isProduct;
  }

  bool hasService(int serviceId) {
    final key = _generateItemKey(serviceId: serviceId);
    return _items.containsKey(key) && _items[key]!.isService;
  }

  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  /// Sum of every local line's total, in [Decimal]. Exact.
  Decimal get subtotal => items.fold(
        Decimal.zero,
        (sum, item) => sum + item.totalPrice,
      );

  /// The cart's monetary total. For a **local cart** this is exactly the
  /// sum of the line totals. For an **API cart** prefer [cartTotalAmount]
  /// (the server's authoritative subtotal) and use this only as a
  /// fallback.
  Decimal get totalAmount => subtotal;

  int get itemCount => _items.length;

  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  // ========================================================================
  // API CART READS
  // ========================================================================

  bool get isLocalCart => cartId == null;
  bool get isApiCart => cartId != null;

  Invoice? get primaryInvoice => invoices.isNotEmpty ? invoices.first : null;
  bool get hasInvoice => invoices.isNotEmpty;
  bool get hasReceipt => receipts.isNotEmpty;
  bool get hasDeposit => deposits.isNotEmpty;

  String get formattedDate {
    if (cartCreatedAt != null) {
      final date = DateTime.tryParse(cartCreatedAt!);
      if (date != null) return '${date.day}/${date.month}/${date.year}';
    }
    return DateTime.now().toIso8601String().split('T').first;
  }

  /// Whether this cart has any line items — local or from the API.
  bool get hasAnyItems =>
      _items.isNotEmpty ||
      orderedItems.isNotEmpty ||
      orderedServices.isNotEmpty;

  /// Every line on the cart — local lines first, then API lines.
  List<dynamic> getAllItems() {
    final all = <dynamic>[];
    all.addAll(_items.values);
    all.addAll(orderedItems);
    all.addAll(orderedServices);
    return all;
  }

  /// Sum of every line on the cart, regardless of source.
  ///
  /// Uses each line model's own `totalPrice` getter — `CartItem` and
  /// `OrderedItem` both resolve discount + VAT for their own line, and
  /// `OrderedService.totalPrice` is the server's authoritative value.
  /// Recomputing from `unitPrice × quantity` here would drop the
  /// discount on products and double-count VAT on some shapes.
  ///
  /// For an **API cart**, prefer [cartTotalAmount] — the server's
  /// authoritative subtotal — and use this only as a fallback when the
  /// total wasn't returned.
  Decimal get combinedTotal {
    Decimal total = Decimal.zero;

    total = total +
        _items.values.fold(Decimal.zero, (sum, item) => sum + item.totalPrice);

    total = total +
        orderedItems.fold(Decimal.zero, (sum, item) => sum + item.totalPrice);

    total = total +
        orderedServices.fold(
          Decimal.zero,
          (sum, service) => sum + service.totalPrice,
        );

    return total;
  }

  // ========================================================================
  // HELPERS
  // ========================================================================

  String _generateItemKey({int? productId, int? serviceId}) {
    if (productId != null) return 'product_$productId';
    if (serviceId != null) return 'service_$serviceId';
    throw ArgumentError('Either productId or serviceId must be provided');
  }

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

  static Decimal? _readDecimalFrom(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final k in keys) {
      final v = map[k];
      if (v == null) continue;
      final parsed = _readDecimal(v);
      if (parsed != null) return parsed;
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

  static Map<String, dynamic>? _asMapOrNull(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  static List<T> _parseListOrSingle<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final out = <T>[];
    if (raw is Map) {
      try {
        out.add(fromJson(Map<String, dynamic>.from(raw)));
      } catch (_) {}
    } else if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          try {
            out.add(fromJson(Map<String, dynamic>.from(e)));
          } catch (_) {}
        }
      }
    }
    return out;
  }

  static List<OrderedItem> _parseOrderedItems(dynamic raw) {
    if (raw is! List) return const [];
    final out = <OrderedItem>[];
    for (final e in raw) {
      if (e is Map) {
        try {
          out.add(OrderedItem.fromJson(Map<String, dynamic>.from(e)));
        } catch (_) {}
      }
    }
    return out;
  }

  static List<OrderedService> _parseOrderedServices(dynamic raw) {
    if (raw is! List) return const [];
    final out = <OrderedService>[];
    for (final e in raw) {
      if (e is Map) {
        try {
          out.add(OrderedService.fromJson(Map<String, dynamic>.from(e)));
        } catch (_) {}
      }
    }
    return out;
  }

  // ========================================================================
  // Equality
  // ========================================================================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Cart && other.cartId == cartId;
  }

  @override
  int get hashCode => cartId?.hashCode ?? 0;

  @override
  String toString() {
    return 'Cart(items: ${items.length}, products: ${productItems.length}, '
        'services: ${serviceItems.length}, total: DZD$totalAmount)';
  }
}

// ============================================================================
// Decimal helpers (module-level, used by CartItem and Cart)
// ============================================================================

/// `100` as a `Decimal`. Used to convert between fraction and percent.
final Decimal _hundred = Decimal.fromInt(100);

/// Clamp a [Decimal] to `[lo, hi]` — `num.clamp` doesn't accept `Decimal`.
Decimal _clampDecimal(Decimal value, Decimal lo, Decimal hi) {
  if (value < lo) return lo;
  if (value > hi) return hi;
  return value;
}

// ============================================================================
// Invoice
// ============================================================================

/// One invoice attached to a cart.
///
/// **Wire shape** (from the read payload — the `invoice` key on a cart):
///
/// ```json
/// {
///   "invoice_id": 14,
///   "invoice_reference": null,
///   "grand_total": 972.25,
///   "invoice_status": "paid",
///   "invoice_type": "invoice",
///   "invoice_issue_date": "2026-10-23",
///   "invoice_due_date": "2026-11-22",
///   "invoice_notes": null,
///   "created_at": "2026-10-23T20:41:32",
///   "updated_at": "2026-10-23T20:41:33"
/// }
/// ```
///
/// The previous version read `invoice_number`, `invoice_total_amount`,
/// `invoice_created_at`, `invoice_updated_at`, `invoice_issue_date`,
/// and `invoice_cart_id` — **none** of which the payload emits. Every
/// field was null after parsing.
class Invoice {
  final int invoiceId;
  final int? invoiceCartId;
  final String? invoiceReference;
  final String invoiceIssueDate;
  final String? invoiceNotes;
  final String invoiceUpdatedAt;

  /// Grand total, in [Decimal]. The server's `Numeric` column arrives
  /// as a JSON number; [_readDecimal] parses it with the shortest
  /// round-trip representation so `972.25` stays `972.25`, not
  /// `972.2499999999999`.
  final Decimal invoiceTotalAmount;

  final String invoiceStatus;
  final String? invoiceDueDate;
  final String invoiceCreatedAt;

  const Invoice({
    required this.invoiceId,
    this.invoiceCartId,
    this.invoiceReference,
    required this.invoiceIssueDate,
    this.invoiceNotes,
    required this.invoiceUpdatedAt,
    required this.invoiceTotalAmount,
    required this.invoiceStatus,
    this.invoiceDueDate,
    required this.invoiceCreatedAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      invoiceId: (json['invoice_id'] as num?)?.toInt() ?? 0,
      invoiceCartId: (json['cart_id'] as num?)?.toInt(),
      invoiceReference: json['invoice_reference'] as String?,
      invoiceIssueDate: (json['invoice_issue_date'] as String?) ?? '',
      invoiceNotes: json['invoice_notes'] as String?,
      invoiceUpdatedAt: (json['updated_at'] as String?) ?? '',
      invoiceTotalAmount: _readDecimal(json['grand_total']) ?? Decimal.zero,
      invoiceStatus: (json['invoice_status'] as String?) ?? 'unpaid',
      invoiceDueDate: json['invoice_due_date'] as String?,
      invoiceCreatedAt: (json['created_at'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'invoice_id': invoiceId,
        'cart_id': invoiceCartId,
        'invoice_reference': invoiceReference,
        'invoice_issue_date': invoiceIssueDate,
        'invoice_notes': invoiceNotes,
        'updated_at': invoiceUpdatedAt,
        'grand_total': _decimalToWire(invoiceTotalAmount),
        'invoice_status': invoiceStatus,
        'invoice_due_date': invoiceDueDate,
        'created_at': invoiceCreatedAt,
      };
}

// ============================================================================
// Receipt
// ============================================================================

/// One receipt attached to a cart.
///
/// There is no `receipt` table in the database schema — the previous
/// model was written against a table that doesn't exist. Kept for
/// backward compatibility with callers that reference the type, but
/// it will never populate from any current endpoint.
class Receipt {
  final int receiptId;
  final int? receiptPaymentId;
  final String? receiptNumber;
  final Decimal receiptAmount;
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
      receiptId: (json['receipt_id'] as num?)?.toInt() ?? 0,
      receiptPaymentId: (json['receipt_payment_id'] as num?)?.toInt(),
      receiptNumber: json['receipt_number'] as String?,
      receiptAmount: _readDecimal(json['receipt_amount']) ?? Decimal.zero,
      receiptNotes: json['receipt_notes'] as String?,
      receiptCreatedAt: (json['receipt_created_at'] as String?) ?? '',
      receiptCartRef: (json['receipt_cart_ref'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'receipt_id': receiptId,
        'receipt_payment_id': receiptPaymentId,
        'receipt_number': receiptNumber,
        'receipt_amount': _decimalToWire(receiptAmount),
        'receipt_notes': receiptNotes,
        'receipt_created_at': receiptCreatedAt,
        'receipt_cart_ref': receiptCartRef,
      };
}

// ============================================================================
// Deposit
// ============================================================================

/// One deposit attached to a cart.
///
/// Matches `Deposit_API` from `api_models.py`. Deposits are created
/// through `/business/deposits`, not as part of the cart payload, but
/// the read response may include them when a deposit has been made
/// against the cart's invoice.
class Deposit {
  final int depositId;
  final int? depositCartId;
  final int? depositInvoiceId;
  final Decimal depositAmount;
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
      depositId: (json['deposit_id'] as num?)?.toInt() ?? 0,
      depositCartId: (json['deposit_cart_id'] as num?)?.toInt(),
      depositInvoiceId: (json['deposit_invoice_id'] as num?)?.toInt(),
      depositAmount: _readDecimal(json['deposit_amount']) ?? Decimal.zero,
      depositMethod: (json['deposit_method'] as String?) ?? 'cash',
      depositReference: json['deposit_reference'] as String?,
      depositNotes: json['deposit_notes'] as String?,
      depositCreatedAt: (json['deposit_created_at'] as String?) ?? '',
      depositUpdatedAt: (json['deposit_updated_at'] as String?) ?? '',
      depositReceiptId: (json['deposit_receipt_id'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'deposit_id': depositId,
        'deposit_cart_id': depositCartId,
        'deposit_invoice_id': depositInvoiceId,
        'deposit_amount': _decimalToWire(depositAmount),
        'deposit_method': depositMethod,
        'deposit_reference': depositReference,
        'deposit_notes': depositNotes,
        'deposit_created_at': depositCreatedAt,
        'deposit_updated_at': depositUpdatedAt,
        'deposit_receipt_id': depositReceiptId,
      };
}
