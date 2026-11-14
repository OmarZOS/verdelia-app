// lib/business/finance/cart_payload_builder.dart
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../app/AppUser.dart';
import '../../app/Person.dart';
import 'Cart.dart';
import 'OrderedItem.dart'; // OrderedItem.toOrderedItemApiJson()

// ── Enums ──
enum DocType { receipt, invoice, invoiceReceipt, none }

enum PayType { payment, deposit, installment }

enum PayMethod { cash, card, bank, mobile }

/// Delivery info carried on a cart. Mirrors the backend's `Delivery_API`.
///
/// ## Money
///
/// [deliveryFee] and [deliveryTotalWeight] are `Decimal?`. The nullable
/// type is required because `Decimal.zero` is a `static final`, not a
/// compile-time constant, so it can't be an optional-parameter default.
/// Callers see `null` as "zero"; internally, every read goes through
/// `?? Decimal.zero`.
@immutable
class CartDeliveryPayload {
  final int idDelivery;
  final int recipientPerson;
  final int recipientProvider;
  final int deliveryPackageCount;

  /// Total cargo weight, in [Decimal]. `null` means zero.
  final Decimal? deliveryTotalWeight;

  final String? deliveryCargoDimensions;
  final String? deliveryGoodsDescription;
  final String? hsCode;
  final String? deliveryMerchantName;
  final String deliveryShippingMethod; // "standard" | "express" | ...
  final String? deliverySpecialInstructions;
  final String deliveryStatus; // "pending" | "in_transit" | ...

  /// Delivery fee, in [Decimal]. `null` means zero.
  final Decimal? deliveryFee;

  final int deliveryAddressId;
  final int deliveryCurrentAddressId;
  final int deliveryProviderId;
  final int deliveryBrokerId;
  final int deliveryInvoiceRef;
  final String deliverySourceType; // "cart" | "placed_order"
  final int deliverySourceId;
  final DateTime? deliveryCreatedAt;
  final DateTime? deliveryUpdatedAt;

  /// Effective fee — `deliveryFee` or `Decimal.zero`. Use this in
  /// arithmetic; `deliveryFee` stays nullable only so the constructor
  /// can be `const`.
  Decimal get fee => deliveryFee ?? Decimal.zero;

  /// Effective weight — `deliveryTotalWeight` or `Decimal.zero`.
  Decimal get weight => deliveryTotalWeight ?? Decimal.zero;

  const CartDeliveryPayload({
    this.idDelivery = 0,
    this.recipientPerson = 0,
    this.recipientProvider = 0,
    this.deliveryPackageCount = 0,
    this.deliveryTotalWeight,
    this.deliveryCargoDimensions,
    this.deliveryGoodsDescription,
    this.hsCode,
    this.deliveryMerchantName,
    this.deliveryShippingMethod = 'standard',
    this.deliverySpecialInstructions,
    this.deliveryStatus = 'pending',
    this.deliveryFee,
    this.deliveryAddressId = 0,
    this.deliveryCurrentAddressId = 0,
    this.deliveryProviderId = 0,
    this.deliveryBrokerId = 0,
    this.deliveryInvoiceRef = 0,
    this.deliverySourceType = 'cart',
    this.deliverySourceId = 0,
    this.deliveryCreatedAt,
    this.deliveryUpdatedAt,
  });

  /// Serialises to the wire shape accepted by `Delivery_API`.
  ///
  /// Notes:
  /// - Optional string fields are sent as `null`, never as the literal
  ///   string `"string"` — the schema allows `null` and a placeholder
  ///   would leak into the seller's delivery UI.
  /// - `delivery_created_at` / `delivery_updated_at` are server-generated
  ///   and are deliberately omitted.
  /// - Monetary values are emitted via [_decimalToWire], so `null` stays
  ///   `null` on the wire (matching the schema's `nullable` fields).
  Map<String, dynamic> toJson() {
    return {
      'id_delivery': idDelivery,
      'recipient_person': recipientPerson,
      'recipient_provider': recipientProvider,
      'delivery_package_count': deliveryPackageCount,
      'delivery_total_weight': _decimalToWireOrNull(deliveryTotalWeight),
      'delivery_cargo_dimensions': deliveryCargoDimensions,
      'delivery_goods_description': deliveryGoodsDescription,
      'hs_code': hsCode,
      'delivery_merchant_name': deliveryMerchantName,
      'delivery_shipping_method': deliveryShippingMethod,
      'delivery_special_instructions': deliverySpecialInstructions,
      'delivery_status': deliveryStatus,
      'delivery_fee': _decimalToWireOrNull(deliveryFee),
      'delivery_address_id': deliveryAddressId,
      'delivery_current_address_id': deliveryCurrentAddressId,
      'delivery_provider_id': deliveryProviderId,
      'delivery_broker_id': deliveryBrokerId,
      'delivery_invoice_ref': deliveryInvoiceRef,
      'delivery_source_type': deliverySourceType,
      'delivery_source_id': deliverySourceId,
    };
  }
}

/// Stateless payload builder — pure function from UI state to wire JSON.
///
/// Wire contract: `CartCreateRequest` in the OpenAPI spec, which nests
/// `Cart_API`, `OrderedItem_API[]`, `OrderedService_API[]`, `Person_API`
/// and `Delivery_API`.
///
/// The builder is the single place that translates the local `Cart` model
/// into the request shape. Everything that touches a wire field name lives
/// here (or in `OrderedItem.toOrderedItemApiJson()`), so there is one
/// source of truth per field.
///
/// ## Money
///
/// [vatRate] and [depositAmount] are [Decimal]. [depositAmount] is
/// nullable only because `Decimal.zero` isn't a compile-time constant —
/// callers see `null` as zero. [effectiveDeposit] is the non-null view
/// for arithmetic.
class CartPayloadBuilder {
  /// Standard Algerian VAT as a fraction (`0.19`), in [Decimal].
  static final Decimal vatRate = Decimal.parse('0.19');

  final int providerId;
  final int sellingUserId;
  final Cart cart;

  final AppUser? customer;
  final Person? person;

  final DocType documentType;
  final bool applyVAT;

  final PayType paymentType;
  final PayMethod paymentMethod;

  /// Deposit amount, in [Decimal]. `null` means zero.
  final Decimal? depositAmount;

  final DateTime? dueDate;

  final CartDeliveryPayload? delivery;

  final String notes;
  final Map<String, String> parameters;

  /// If your cart is being attached to an existing invoice, pass its id here.
  /// Otherwise leave null and the backend will create one.
  final int? existingInvoiceId;

  const CartPayloadBuilder({
    required this.providerId,
    required this.sellingUserId,
    required this.cart,
    this.customer,
    this.person,
    this.documentType = DocType.receipt,
    this.applyVAT = false,
    this.paymentType = PayType.payment,
    this.paymentMethod = PayMethod.cash,
    this.depositAmount,
    this.dueDate,
    this.delivery,
    this.notes = '',
    this.parameters = const {},
    this.existingInvoiceId,
  });

  /// Effective deposit — `depositAmount` or `Decimal.zero`. Use this in
  /// arithmetic; `depositAmount` stays nullable only so the constructor
  /// can be `const`.
  Decimal get effectiveDeposit => depositAmount ?? Decimal.zero;

  /// Mirrors the server-side status the payment will land in. Not used on
  /// the wire — the server derives it — but useful for optimistic UI.
  String get effectivePaymentStatus {
    if (paymentType == PayType.payment && paymentMethod == PayMethod.cash) {
      return 'completed';
    }
    return 'pending';
  }

  Map<String, dynamic> build() {
    final totals = computeTotals(cart.totalAmount);

    final isFullPayment = paymentType == PayType.payment;
    final isDeposit = paymentType == PayType.deposit;
    final isInstallment = paymentType == PayType.installment;
    final wantsPaymentNow = isFullPayment || isDeposit;

    final cartData = <String, dynamic>{
      'cart_status': 'open',
      'cart_total_amount': _decimalToWire(totals.total),
      'cart_notes': notes,
    };

    // Due date is only meaningful when payment is deferred. Emit it only
    // when the caller actually picked one — the schema allows null, and
    // defaulting to "today" would silently mislabel every installment.
    if (isInstallment && dueDate != null) {
      cartData['cart_due_date'] = _dateOnly(dueDate!);
    }

    // Attach to an existing invoice, when the caller supplied one.
    if (existingInvoiceId != null && existingInvoiceId! > 0) {
      cartData['cart_invoice'] = existingInvoiceId;
    }

    // Payment intent: only when the user commits money now.
    if (wantsPaymentNow) {
      cartData['cart_payment'] = isFullPayment;
      cartData['cart_deposit'] = isDeposit;
      cartData['cart_paid_money'] = _decimalToWire(totals.paid);
      cartData['cart_payment_method'] = _paymentMethodForBackend();
    }

    final clientData = _clientPayload();
    final customerRef = _customerReference();

    return <String, dynamic>{
      'provider_id': providerId,
      'seller_user_id': sellingUserId,
      'buyer_user_id': customerRef.userId,
      'cart': cartData,
      'ordered_items': _buildOrderedItems(),
      'ordered_services': _buildOrderedServices(),
      if (clientData.isNotEmpty) 'client': clientData,
      if (delivery != null) 'delivery': delivery!.toJson(),
    };
  }

  String _paymentMethodForBackend() {
    switch (paymentMethod) {
      case PayMethod.cash:
        return 'cash';
      case PayMethod.card:
        return 'card';
      case PayMethod.bank:
        return 'bank_transfer';
      case PayMethod.mobile:
        return 'mobile_money';
    }
  }

  // ── helpers ──

  static String _dateOnly(DateTime d) => d.toIso8601String().split('T').first;

  /// Computes the receipt totals for the cart. `paid` matches exactly what
  /// `cart_paid_money` will carry on the wire, so the builder and the
  /// request share one source of truth for "how much is being charged now".
  _Totals computeTotals(Decimal cartSubtotal) {
    // `cartSubtotal` is VAT-inclusive (matches `Cart.totalAmount`).
    // When `applyVAT` is on, split it into net + VAT for the receipt.
    final Decimal netSubtotal =
        applyVAT ? cartSubtotal.div(Decimal.one + vatRate) : cartSubtotal;
    final Decimal vatAmount = cartSubtotal - netSubtotal;

    final Decimal paid = paymentType == PayType.deposit
        ? _clampNonNegative(effectiveDeposit, cartSubtotal)
        : cartSubtotal;

    return _Totals(
      subtotal: netSubtotal,
      vat: vatAmount,
      total: cartSubtotal,
      paid: paid,
    );
  }

  List<Map<String, dynamic>> _buildOrderedItems() {
    // `unit_price` on the wire is VAT-inclusive. The backend extracts the
    // tax portion using `vat_rate`; it does NOT add it on top.
    //
    // Serialisation goes through `OrderedItem.toOrderedItemApiJson()` so
    // the wire names (`product_id`, `order_ref`, `vat_rate`,
    // `product_discount`) live in exactly one place.
    final Decimal vatPercent =
        applyVAT ? vatRate * Decimal.fromInt(100) : Decimal.zero;

    return cart.items.where((i) => i.isProduct).map((item) {
      final productId = item.product?.id_product ?? 0;

      final Decimal? discountPercent =
          item.hasCustomPrice ? _normalisePercent(item.discountPercent) : null;

      final line = OrderedItem(
        idOrderedItem: 0,
        orderedProductId: productId,
        orderedQuantity: item.quantity,
        appliedVat: vatPercent,
        orderRef: 0,
        unitPrice: item.unitPrice ?? Decimal.zero,
        productDiscount: discountPercent,
      );

      return line.toOrderedItemApiJson();
    }).toList();
  }

  /// Treats `<= 1` as a fraction and scales to percent; leaves larger
  /// values alone (already a percent).
  static Decimal _normalisePercent(Decimal value) {
    return value <= Decimal.one ? value * Decimal.fromInt(100) : value;
  }

  List<Map<String, dynamic>> _buildOrderedServices() {
    // `OrderedService_API` prices are VAT-exclusive; the invoice adds the
    // tax on top. Strip the VAT the cart carries so the server doesn't
    // double it.
    final Decimal factor =
        applyVAT ? Decimal.one.div(Decimal.one + vatRate) : Decimal.one;

    return cart.items.where((i) => i.isService).map((item) {
      final Decimal unitPrice = (item.unitPrice ?? Decimal.zero) * factor;
      final Decimal totalPrice = unitPrice * Decimal.fromInt(item.quantity);

      final String? date = item.scheduledDate;
      final String? time = item.scheduledTime;
      final String? scheduledAt =
          date == null ? null : (time != null ? '${date}T$time' : date);

      return <String, dynamic>{
        'ordered_service_service_id': item.service?.id ?? 0,
        'ordered_service_quantity': item.quantity,
        'ordered_service_unit_price': _decimalToWire(unitPrice),
        'ordered_service_total_price': _decimalToWire(totalPrice),
        'ordered_service_scheduled_at': scheduledAt,
        'resource_requirement_id': 0,
      };
    }).toList();
  }

  _CustomerRef _customerReference() {
    if (customer != null) {
      if (customer!.idAppUser == 0) {
        return const _CustomerRef(personId: null, userId: 0);
      }
      return _CustomerRef(
        personId: customer!.idPerson,
        userId: customer!.idAppUser ?? 0,
      );
    }
    if (person != null) {
      return _CustomerRef(personId: person!.id_person, userId: 0);
    }
    return const _CustomerRef(personId: null, userId: 0);
  }

  Map<String, dynamic> _clientPayload() {
    if (customer != null && customer!.idAppUser != 0) {
      return {
        'id_person': customer!.idPerson,
        'person_details_id': customer!.personDetailsId,
        'id_person_details': customer!.personDetailsId,
        'person_first_name': customer!.personFirstName ?? '',
        'person_last_name': customer!.personLastName ?? '',
        'person_birth_date': _dateOnly(_parseOrNow(customer!.personBirthDate)),
        'person_gender': customer!.personGender.wireValue,
        'person_country_code': customer!.personCountryCode ?? 'DZ',
        'blood_type': 'Unknown',
      };
    }

    if (person != null) {
      final details = person!.person_details;
      return {
        'id_person': person!.id_person,
        'person_details_id': person!.person_details_id,
        'id_person_details': details.id_person_details,
        'person_first_name': details.person_first_name,
        'person_last_name': details.person_last_name,
        'person_birth_date': _dateOnly(
          details.person_birth_date ?? DateTime.now(),
        ),
        'person_gender': details.person_gender.wireValue,
        'person_country_code': details.person_nationality ?? 'DZ',
        'blood_type': 'Unknown',
      };
    }

    return const {};
  }

  static DateTime _parseOrNow(String? s) {
    if (s == null || s.isEmpty) return DateTime.now();
    return DateTime.tryParse(s) ?? DateTime.now();
  }
}

@immutable
class _Totals {
  /// Net (ex-VAT) subtotal, in [Decimal].
  final Decimal subtotal;

  /// VAT portion, in [Decimal].
  final Decimal vat;

  /// VAT-inclusive cart total, in [Decimal].
  final Decimal total;

  /// Amount being charged right now, in [Decimal].
  final Decimal paid;

  const _Totals({
    required this.subtotal,
    required this.vat,
    required this.total,
    required this.paid,
  });
}

@immutable
class _CustomerRef {
  final int? personId;
  final int userId;
  const _CustomerRef({this.personId, required this.userId});
}

// ============================================================================
// Decimal helpers
// ============================================================================

/// Clamp a [Decimal] to `[0, max]`.
Decimal _clampNonNegative(Decimal value, Decimal max) {
  if (value < Decimal.zero) return Decimal.zero;
  if (value > max) return max;
  return value;
}

/// Coerces any JSON value to [Decimal].
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

/// Coerces any JSON value to a [Decimal], defaulting to zero.
Decimal _readDecimalOrZero(dynamic v) => _readDecimal(v) ?? Decimal.zero;

/// Converts a [Decimal] to the shortest `double` that round-trips.
/// For the JSON wire boundary only — never use this for arithmetic.
double _decimalToDouble(Decimal v) => double.parse(v.toString());

/// Serialises a [Decimal] for JSON.
num _decimalToWire(Decimal v) => _decimalToDouble(v);

/// [decimalToWire] with a `null` passthrough, for optional money fields.
num? _decimalToWireOrNull(Decimal? v) => v == null ? null : _decimalToWire(v);

/// Extension for `Decimal / Decimal` which normally returns a
/// `Rational`. Wrapping it keeps every call site returning `Decimal`.
extension _DecimalDiv on Decimal {
  Decimal div(Decimal other) =>
      (this / other).toDecimal(scaleOnInfinitePrecision: 2);
}
