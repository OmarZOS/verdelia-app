// lib/business/finance/cart_payload_builder.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:verdelia_core/app/AppUser.dart';
import 'package:verdelia_core/app/Person.dart';
import 'package:verdelia_core/business/Delivery.dart';
import 'package:verdelia_core/business/finance/Cart.dart';

// ── Enums ──
enum DocType { receipt, invoice, invoiceReceipt, none }

enum PayType { payment, deposit, installment }

enum PayMethod { cash, card, bank, mobile }

/// Delivery info carried on a cart. Mirrors the backend's `Delivery_API`.
@immutable
class CartDeliveryPayload {
  final int idDelivery;
  final int recipientPerson;
  final int recipientProvider;
  final int deliveryPackageCount;
  final double deliveryTotalWeight;
  final String? deliveryCargoDimensions;
  final String? deliveryGoodsDescription;
  final String? hsCode;
  final String? deliveryMerchantName;
  final String deliveryShippingMethod; // "standard" | "express" | ...
  final String? deliverySpecialInstructions;
  final String deliveryStatus; // "pending" | "in_transit" | ...
  final double deliveryFee;
  final int deliveryAddressId;
  final int deliveryCurrentAddressId;
  final int deliveryProviderId;
  final int deliveryBrokerId;
  final int deliveryInvoiceRef;
  final String deliverySourceType; // "cart" | "order" | ...
  final int deliverySourceId;
  final DateTime? deliveryCreatedAt;
  final DateTime? deliveryUpdatedAt;

  const CartDeliveryPayload({
    this.idDelivery = 0,
    this.recipientPerson = 0,
    this.recipientProvider = 0,
    this.deliveryPackageCount = 0,
    this.deliveryTotalWeight = 0,
    this.deliveryCargoDimensions,
    this.deliveryGoodsDescription,
    this.hsCode,
    this.deliveryMerchantName,
    this.deliveryShippingMethod = 'standard',
    this.deliverySpecialInstructions,
    this.deliveryStatus = 'pending',
    this.deliveryFee = 0,
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

  Map<String, dynamic> toJson() {
    final iso = (DateTime? d) =>
        d?.toIso8601String() ?? DateTime.now().toIso8601String();
    return {
      'id_delivery': idDelivery,
      'recipient_person': recipientPerson,
      'recipient_provider': recipientProvider,
      'delivery_package_count': deliveryPackageCount,
      'delivery_total_weight': deliveryTotalWeight,
      'delivery_cargo_dimensions': deliveryCargoDimensions ?? 'string',
      'delivery_goods_description': deliveryGoodsDescription ?? 'string',
      'hs_code': hsCode ?? 'string',
      'delivery_merchant_name': deliveryMerchantName ?? 'string',
      'delivery_shipping_method': deliveryShippingMethod,
      'delivery_special_instructions': deliverySpecialInstructions ?? 'string',
      'delivery_status': deliveryStatus,
      'delivery_fee': deliveryFee,
      'delivery_address_id': deliveryAddressId,
      'delivery_current_address_id': deliveryCurrentAddressId,
      'delivery_provider_id': deliveryProviderId,
      'delivery_broker_id': deliveryBrokerId,
      'delivery_invoice_ref': deliveryInvoiceRef,
      'delivery_source_type': deliverySourceType,
      'delivery_source_id': deliverySourceId,
      'delivery_created_at': iso(deliveryCreatedAt),
      'delivery_updated_at': iso(deliveryUpdatedAt),
    };
  }
}

/// Stateless payload builder — pure function from UI state to wire JSON.
class CartPayloadBuilder {
  static const double vatRate = 0.19;

  final int providerId;
  final int sellingUserId;
  final Cart cart;

  final AppUser? customer;
  final Person? person;

  final DocType documentType;
  final bool applyVAT;

  final PayType paymentType;
  final PayMethod paymentMethod;
  final double depositAmount;
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
    this.depositAmount = 0.0,
    this.dueDate,
    this.delivery,
    this.notes = '',
    this.parameters = const {},
    this.existingInvoiceId,
  });

  Map<String, dynamic> build() {
    final totals = computeTotals(cart.totalAmount);

    final isFullPayment = paymentType == PayType.payment;
    final isDeposit = paymentType == PayType.deposit;
    final isInstallment = paymentType == PayType.installment;
    final wantsPaymentNow = isFullPayment || isDeposit;

    final cartData = <String, dynamic>{
      'cart_status': 'open',
      'cart_total_amount': totals.total,
      'cart_notes': notes,
    };

    // ── Due date: ONLY when payment is deferred (installment). ──
    if (isInstallment) {
      cartData['cart_due_date'] = _dateOnly(dueDate ?? DateTime.now());
    }

    // ── Existing invoice, if we're attaching to one. ──
    if (existingInvoiceId != null && existingInvoiceId! > 0) {
      cartData['cart_invoice'] = existingInvoiceId;
    }

    // ── Payment intent: only when the user commits money now. ──
    if (wantsPaymentNow) {
      cartData['cart_payment'] = isFullPayment;
      cartData['cart_deposit'] = isDeposit;
      cartData['cart_paid_money'] =
          isDeposit ? depositAmount.clamp(0.0, totals.total) : totals.total;
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

  _Totals computeTotals(double cartSubtotal) {
    if (!applyVAT) {
      final paid = paymentType == PayType.deposit
          ? depositAmount.clamp(0.0, cartSubtotal)
          : cartSubtotal;
      return _Totals(
          subtotal: cartSubtotal, vat: 0, total: cartSubtotal, paid: paid);
    }

    final netSubtotal = cartSubtotal / (1 + vatRate);
    final vatAmount = cartSubtotal - netSubtotal;
    final paid = paymentType == PayType.deposit
        ? depositAmount.clamp(0.0, cartSubtotal)
        : cartSubtotal;

    return _Totals(
        subtotal: netSubtotal, vat: vatAmount, total: cartSubtotal, paid: paid);
  }

  List<Map<String, dynamic>> _buildOrderedItems() {
    final factor = applyVAT ? 1.0 / (1 + vatRate) : 1.0;
    final vatPercent = applyVAT ? vatRate * 100 : 0.0;

    return cart.items.where((i) => i.isProduct).map((item) {
      final unitPrice = (item.unitPrice ?? 0.0) * factor;
      return <String, dynamic>{
        'id_ordered_item': 0,
        'ordered_product_id': item.product?.id_product ?? 0,
        'order_ref': 0,
        'product_discount': 0.0,
        'ordered_quantity': item.quantity,
        'unit_price': unitPrice,
        'applied_vat': vatPercent,
      };
    }).toList();
  }

  List<Map<String, dynamic>> _buildOrderedServices() {
    final factor = applyVAT ? 1.0 / (1 + vatRate) : 1.0;

    return cart.items.where((i) => i.isService).map((item) {
      final unitPrice = (item.unitPrice ?? 0.0) * factor;
      final totalPrice = item.totalPrice * factor;
      return <String, dynamic>{
        'ordered_service_service_id': item.service?.id ?? 0,
        'ordered_service_quantity': item.quantity,
        'ordered_service_unit_price': unitPrice,
        'ordered_service_total_price': totalPrice,
        'ordered_service_scheduled_at':
            (item.scheduledDate ?? DateTime.now().toIso8601String()),
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
        'person_gender': (customer!.personGender ?? 'male').toLowerCase(),
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
        'person_gender': (details.person_gender ?? 'male').toLowerCase(),
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
  final double subtotal;
  final double vat;
  final double total;
  final double paid;
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
