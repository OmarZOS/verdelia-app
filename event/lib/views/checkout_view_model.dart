// lib/checkout/CheckoutViewModel.dart
//
// CheckoutViewModel — owns the checkout flow state.
//
// Changelog (this revision):
//
//   * `processCartCheckout` is gone. The ViewModel now has a single
//     entry point — `processCheckout(cartNotifier)` — and reads the
//     one live cart off the notifier. To check out an API-loaded
//     cart, the caller calls `cartNotifier.loadCartForCheckout(cart)`
//     first, then `processCheckout`.
//   * Everything else from the previous revision is preserved:
//     single-notify `_process`, `CartPayloadBuilder.effectivePaymentStatus`,
//     delivery payload guards, shared reset body.
//
// Money: `_depositAmount` and every total in `calculateTotals` are
// `Decimal`. `CartPayloadBuilder.depositAmount` and `computeTotals` are
// `Decimal`-typed after the builder migration, so the ViewModel's
// deposit field must match.

import 'dart:convert';
import 'dart:developer' as developer;

import 'package:decimal/decimal.dart';
import 'package:event/cart_change_notifier.dart';
import 'package:flutter/foundation.dart';
import 'package:verdelia_core/app/AppUser.dart';
import 'package:verdelia_core/app/Person.dart';
import 'package:verdelia_core/business/Delivery.dart';
import 'package:verdelia_core/business/finance/Cart.dart';
import 'package:verdelia_core/business/finance/cart_payload_builder.dart';
import 'package:verdelia_core/business/services/CartService.dart';
import 'package:locator/locator.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ==================== CONSTANTS ====================

abstract class _DocType {
  static const receipt = 'receipt';
  static const invoice = 'invoice';
  static const invoiceReceipt = 'invoice_receipt';
  static const none = 'none';
}

abstract class _PayType {
  static const payment = 'payment';
  static const deposit = 'deposit';
  static const installment = 'installment';
}

abstract class _PayMethod {
  static const cash = 'cash';
  static const card = 'card';
  static const bank = 'bank';
  static const mobile = 'mobile';
}

abstract class _PayStatus {
  static const completed = 'completed';
  static const pending = 'pending';
}

// ==================== CHECKOUT PARAMETER ====================

class CheckoutParameter {
  final String key;
  final String value;

  const CheckoutParameter({required this.key, required this.value});

  Map<String, dynamic> toMap() => {'key': key, 'value': value};

  factory CheckoutParameter.fromMap(Map<String, dynamic> map) =>
      CheckoutParameter(
        key: map['key'] as String? ?? '',
        value: map['value'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      other is CheckoutParameter && other.key == key && other.value == value;

  @override
  int get hashCode => Object.hash(key, value);
}

// ==================== CHECKOUT RESULT ====================

@immutable
class CheckoutResult {
  final bool isSuccess;
  final String message;
  final int? orderId;

  /// Settlement the backend actually recorded for this checkout, when
  /// the response carried one. Null when the flow didn't request a
  /// payment, or when the response didn't include settlement data.
  final String? recordedPaymentStatus;

  const CheckoutResult._({
    required this.isSuccess,
    required this.message,
    this.orderId,
    this.recordedPaymentStatus,
  });

  factory CheckoutResult.success(
    String message, {
    int? orderId,
    String? recordedPaymentStatus,
  }) =>
      CheckoutResult._(
        isSuccess: true,
        message: message,
        orderId: orderId,
        recordedPaymentStatus: recordedPaymentStatus,
      );

  factory CheckoutResult.failure(String message) =>
      CheckoutResult._(isSuccess: false, message: message);
}

// ==================== VIEW MODEL ====================

class CheckoutViewModel extends ChangeNotifier {
  final CartService _cartService = AppLocator.get<CartService>();

  static const String _prefsKey = 'checkout_parameters';

  /// Standard Algerian VAT as a fraction, in [Decimal].
  static final Decimal vatRate = Decimal.parse('0.19');

  /// Sentinel for "no customer chosen yet" — distinct from a real
  /// customer whose `idAppUser` is legitimately zero (which can't
  /// happen in this app, but the field is nullable so we treat it as
  /// a guest marker).
  static const int _guestUserId = 0;

  // ─── Customer ───
  AppUser? _selectedCustomer;
  Person? _selectedPerson;

  // ─── Document ───
  String _documentType = _DocType.receipt;
  bool _applyVAT = false;

  // ─── Payment ───
  String _paymentType = _PayType.payment;
  String _paymentMethod = _PayMethod.cash;

  /// Deposit amount, in [Decimal]. Zero unless [_paymentType] is
  /// `deposit`.
  Decimal _depositAmount = Decimal.zero;

  String? _dueDate;
  String _cardType = 'visa';
  String? _cardDetails;
  String? _bankDetails;
  String? _mobileProvider;

  // ─── Delivery ───
  String _deliveryType = 'pickup';
  DeliveryData? _deliveryData;

  // ─── Notes & parameters ───
  String _notes = '';
  List<CheckoutParameter> _parameters = [];
  final List<CheckoutParameter> _savedParameters = [];
  bool _isLoadingParameters = false;

  // ─── Lifecycle ───
  bool _isProcessing = false;
  CheckoutResult? _lastCheckoutResult;

  // ==================== GETTERS ====================

  AppUser? get selectedCustomer => _selectedCustomer;
  Person? get selectedPerson => _selectedPerson;

  String get documentType => _documentType;
  bool get applyVAT => _applyVAT;

  String get paymentType => _paymentType;
  String get paymentMethod => _paymentMethod;

  /// Deposit amount, in [Decimal].
  Decimal get depositAmount => _depositAmount;

  String? get dueDate => _dueDate;
  String get cardType => _cardType;
  String? get cardDetails => _cardDetails;
  String? get bankDetails => _bankDetails;
  String? get mobileProvider => _mobileProvider;

  String get deliveryType => _deliveryType;
  DeliveryData? get deliveryData => _deliveryData;

  String get notes => _notes;
  List<CheckoutParameter> get parameters => List.unmodifiable(_parameters);
  List<CheckoutParameter> get savedParameters =>
      List.unmodifiable(_savedParameters);
  bool get isLoadingParameters => _isLoadingParameters;

  bool get isProcessing => _isProcessing;
  CheckoutResult? get lastCheckoutResult => _lastCheckoutResult;

  /// Payment status the wire payload will carry.
  ///
  /// Delegates to the same `CartPayloadBuilder` that produces the
  /// request body, so the ViewModel and the backend agree on what was
  /// recorded.
  ///
  ///     cash + full payment → completed
  ///     everything else     → pending
  String get effectivePaymentStatus {
    return CartPayloadBuilder(
      providerId: 0,
      sellingUserId: 0,
      cart: Cart.local(),
      applyVAT: _applyVAT,
      paymentType: _payTypeFrom(_paymentType),
      paymentMethod: _payMethodFrom(_paymentMethod),
      depositAmount: _depositAmount,
    ).effectivePaymentStatus;
  }

  bool get isGuestCustomer =>
      _selectedCustomer != null && _selectedCustomer!.idAppUser == _guestUserId;

  bool get hasRealCustomer =>
      (_selectedCustomer != null &&
          _selectedCustomer!.idAppUser != _guestUserId) ||
      _selectedPerson != null;

  String get customerName {
    final customer = _selectedCustomer;
    if (customer != null) {
      if (customer.idAppUser == _guestUserId) return 'Guest';
      final name =
          '${customer.personFirstName ?? ''} ${customer.personLastName ?? ''}'
              .trim();
      return name.isEmpty ? 'Guest' : name;
    }
    final person = _selectedPerson;
    if (person != null) return person.fullName;
    return 'No customer selected';
  }

  // ==================== CONSTRUCTOR ====================

  CheckoutViewModel() {
    _loadSavedParameters();
    _syncVatWithDocumentType();
  }

  // ==================== CHECKOUT FLOW ====================

  /// The only checkout entry point.
  ///
  /// Uses whatever cart `cartNotifier.cart` currently holds. To check
  /// out an API-loaded cart, call `cartNotifier.loadCartForCheckout(cart)`
  /// first.
  Future<CheckoutResult> processCheckout({
    required CartChangeNotifier cartNotifier,
    required int sellingUserId,
    required int providerId,
  }) async {
    final result = await _process(
      cart: cartNotifier.cart,
      sellingUserId: sellingUserId,
      providerId: providerId,
    );

    if (result.isSuccess) {
      cartNotifier.clearCart();
      resetAfterCheckout();
    }
    return result;
  }

  /// Shared implementation.
  Future<CheckoutResult> _process({
    required Cart cart,
    required int sellingUserId,
    required int providerId,
  }) async {
    if (_isProcessing) {
      return CheckoutResult.failure('Checkout already in progress');
    }

    _isProcessing = true;
    _lastCheckoutResult = null;
    notifyListeners();

    var result = CheckoutResult.failure('Checkout did not complete');
    try {
      if (cart.isEmpty) {
        result = CheckoutResult.failure('Cart is empty');
      } else {
        final payload = _buildPayload(
          cart: cart,
          sellingUserId: sellingUserId,
          providerId: providerId,
        );
        result = await _submit(payload);
      }
    } catch (e, stack) {
      developer.log(
        'Checkout failed',
        name: 'CheckoutViewModel',
        error: e,
        stackTrace: stack,
      );
      result = CheckoutResult.failure('Checkout failed: $e');
    } finally {
      _lastCheckoutResult = result;
      _isProcessing = false;
      notifyListeners();
    }
    return result;
  }

  Future<CheckoutResult> _submit(Map<String, dynamic> payload) async {
    try {
      final response = await _cartService.addCart(payload);

      if (response == null || response.cartId == null) {
        return CheckoutResult.failure('Failed to place order');
      }

      final cartId = response.cartId!;
      final recordedStatus = _recordedStatusFrom(response);

      return CheckoutResult.success(
        'Order placed successfully. Order ID: $cartId',
        orderId: cartId,
        recordedPaymentStatus: recordedStatus,
      );
    } catch (e, stack) {
      developer.log(
        'Order submission failed',
        name: 'CheckoutViewModel',
        error: e,
        stackTrace: stack,
      );
      return CheckoutResult.failure('Order submission error: $e');
    }
  }

  /// Best-effort settlement summary from the cart response.
  ///
  /// Precedence:
  ///   - a completed invoice → 'completed'
  ///   - a pending invoice   → 'pending'
  ///   - no settlement data  → the ViewModel's own derivation
  String _recordedStatusFrom(Cart response) {
    for (final invoice in response.invoices) {
      final s = invoice.invoiceStatus.toLowerCase();
      if (s == _PayStatus.completed) return _PayStatus.completed;
      if (s == _PayStatus.pending) return _PayStatus.pending;
    }
    return effectivePaymentStatus;
  }

  // ==================== PAYLOAD BUILDER ====================

  Map<String, dynamic> _buildPayload({
    required Cart cart,
    required int sellingUserId,
    required int providerId,
  }) {
    return CartPayloadBuilder(
      providerId: providerId,
      sellingUserId: sellingUserId,
      cart: cart,
      customer: _selectedCustomer,
      person: _selectedPerson,
      documentType: _docTypeFrom(_documentType),
      applyVAT: _applyVAT,
      paymentType: _payTypeFrom(_paymentType),
      paymentMethod: _payMethodFrom(_paymentMethod),
      // `CartPayloadBuilder.depositAmount` is `Decimal?` after the
      // builder migration. Passing the non-null `_depositAmount`
      // (defaulted to `Decimal.zero`) works directly.
      depositAmount: _depositAmount,
      dueDate: _dueDate == null ? null : DateTime.tryParse(_dueDate!),
      delivery: _buildDeliveryPayload(),
      notes: _notes,
      parameters: {
        for (final p in _parameters) p.key: p.value,
      },
    ).build();
  }

  CartDeliveryPayload? _buildDeliveryPayload() {
    if (_deliveryType == 'pickup' || _deliveryData == null) return null;

    final addressId = _deliveryData!.deliveryAddressId;
    final providerId = _deliveryData!.deliveryProviderId;
    if (addressId == null || providerId == null) {
      developer.log(
        'Delivery requested without address/provider id; '
        'omitting delivery payload.',
        name: 'CheckoutViewModel',
      );
      return null;
    }

    return CartDeliveryPayload(
      deliveryShippingMethod:
          _deliveryData!.deliveryShippingMethod ?? 'standard',
      deliverySpecialInstructions: _deliveryData!.deliverySpecialInstructions,
      deliveryAddressId: addressId,
      deliveryProviderId: providerId,
      deliveryStatus: 'pending',
      deliverySourceType: 'cart',
    );
  }

  static DocType _docTypeFrom(String s) => switch (s) {
        'invoice' => DocType.invoice,
        'invoice_receipt' => DocType.invoiceReceipt,
        'none' => DocType.none,
        _ => DocType.receipt,
      };

  static PayType _payTypeFrom(String s) => switch (s) {
        'deposit' => PayType.deposit,
        'installment' => PayType.installment,
        _ => PayType.payment,
      };

  static PayMethod _payMethodFrom(String s) => switch (s) {
        'card' => PayMethod.card,
        'bank' => PayMethod.bank,
        'mobile' => PayMethod.mobile,
        _ => PayMethod.cash,
      };

  // ==================== CUSTOMER MANAGEMENT ====================

  void setSelectedCustomer(AppUser? customer, Person? person) {
    _selectedCustomer = customer;
    _selectedPerson = person;
    notifyListeners();
  }

  Future<Person?> createNewCustomer(Person person) async {
    _isProcessing = true;
    notifyListeners();
    try {
      _selectedPerson = person;
      return person;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // ==================== DOCUMENT / PAYMENT / DELIVERY ====================

  void setDocumentType(String type) {
    if (_documentType == type) return;
    _documentType = type;
    _syncVatWithDocumentType();
    notifyListeners();
  }

  void _syncVatWithDocumentType() {
    _applyVAT = _documentType.contains('invoice');
  }

  void setApplyVAT(bool apply) {
    if (_applyVAT == apply) return;
    _applyVAT = apply;
    notifyListeners();
  }

  void setPaymentType(String type) {
    if (_paymentType == type) return;
    _paymentType = type;

    if (type != _PayType.deposit) {
      _depositAmount = Decimal.zero;
    }
    if (type != _PayType.installment) {
      _dueDate = null;
    }
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    if (_paymentMethod == method) return;
    _paymentMethod = method;
    notifyListeners();
  }

  /// Set the deposit amount, in [Decimal].
  ///
  /// The caller is expected to supply a non-negative value. `canCheckout`
  /// enforces the upper bound against `computeTotals(...).total`.
  void setDepositAmount(Decimal amount) {
    if (_depositAmount == amount) return;
    _depositAmount = amount;
    if (_paymentType == _PayType.deposit) {
      _dueDate = null;
    }
    notifyListeners();
  }

  void setInstallmentDate(DateTime dueDate) {
    _dueDate = dueDate.toIso8601String();
    if (_paymentType != _PayType.installment) {
      _paymentType = _PayType.installment;
      _depositAmount = Decimal.zero;
    }
    notifyListeners();
  }

  void setCardType(String type) {
    if (_cardType == type) return;
    _cardType = type;
    notifyListeners();
  }

  void setCardDetails(String? details) {
    _cardDetails = details;
    notifyListeners();
  }

  void setBankDetails(String? details) {
    _bankDetails = details;
    notifyListeners();
  }

  void setMobileProvider(String? provider) {
    _mobileProvider = provider;
    notifyListeners();
  }

  void setDeliveryType(String type) {
    if (_deliveryType == type) return;
    _deliveryType = type;
    notifyListeners();
  }

  void setDeliveryData(DeliveryData data) {
    _deliveryData = data;
    notifyListeners();
  }

  void setNotes(String notes) {
    if (_notes == notes) return;
    _notes = notes;
    notifyListeners();
  }

  // ==================== PARAMETERS ====================

  void setParameters(List<CheckoutParameter> parameters) {
    _parameters = List.of(parameters);
    notifyListeners();
  }

  void addParameter(String key, String value) {
    if (_parameters.any((p) => p.key == key)) return;
    _parameters.add(CheckoutParameter(key: key, value: value));
    notifyListeners();
  }

  void removeParameter(int index) {
    if (index < 0 || index >= _parameters.length) return;
    _parameters.removeAt(index);
    notifyListeners();
  }

  void clearCurrentParameters() {
    if (_parameters.isEmpty) return;
    _parameters.clear();
    notifyListeners();
  }

  void useSavedParameter(CheckoutParameter parameter) {
    if (_parameters.any((p) => p.key == parameter.key)) return;
    _parameters.add(parameter);
    notifyListeners();
  }

  Future<void> saveParameter(CheckoutParameter parameter) async {
    if (_savedParameters.any((p) => p.key == parameter.key)) return;
    _savedParameters.add(parameter);
    await _persistParameters();
  }

  Future<void> updateParameter(int index, CheckoutParameter parameter) async {
    if (index < 0 || index >= _savedParameters.length) return;
    _savedParameters[index] = parameter;
    await _persistParameters();
  }

  Future<void> deleteParameter(int index) async {
    if (index < 0 || index >= _savedParameters.length) return;
    _savedParameters.removeAt(index);
    await _persistParameters();
  }

  Future<void> _loadSavedParameters() async {
    _isLoadingParameters = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_prefsKey) ?? const [];
      _savedParameters
        ..clear()
        ..addAll(raw.map(_decodeParameter).whereType<CheckoutParameter>());
    } catch (e) {
      developer.log(
        'Failed to load saved parameters',
        name: 'CheckoutViewModel',
        error: e,
      );
    } finally {
      _isLoadingParameters = false;
      notifyListeners();
    }
  }

  CheckoutParameter? _decodeParameter(String jsonString) {
    try {
      final map = json.decode(jsonString) as Map<String, dynamic>;
      return CheckoutParameter.fromMap(map);
    } catch (e) {
      developer.log(
        'Failed to parse saved parameter',
        name: 'CheckoutViewModel',
        error: e,
      );
      return null;
    }
  }

  Future<void> _persistParameters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded =
          _savedParameters.map((p) => json.encode(p.toMap())).toList();
      await prefs.setStringList(_prefsKey, encoded);
      notifyListeners();
    } catch (e) {
      developer.log(
        'Failed to persist parameters',
        name: 'CheckoutViewModel',
        error: e,
      );
    }
  }

  // ==================== RESET ====================

  void clearAll() {
    _resetMutableState();
    notifyListeners();
  }

  void resetAfterCheckout() {
    _resetMutableState();
    notifyListeners();
  }

  void _resetMutableState() {
    _selectedCustomer = null;
    _selectedPerson = null;
    _documentType = _DocType.receipt;
    _paymentType = _PayType.payment;
    _paymentMethod = _PayMethod.cash;
    _deliveryType = 'pickup';
    _notes = '';
    _dueDate = null;
    _parameters = [];
    _cardDetails = null;
    _bankDetails = null;
    _mobileProvider = null;
    _cardType = 'visa';
    _depositAmount = Decimal.zero;
    _lastCheckoutResult = null;
    _deliveryData = null;
    _syncVatWithDocumentType();
  }

  // ==================== TOTALS / VALIDATION ====================

  /// Breakdown of the cart's monetary totals, in [Decimal].
  ///
  /// - `subtotal`: net (ex-VAT) subtotal
  /// - `vatAmount`: VAT portion
  /// - `vatRate`: the applied rate as a fraction (`0.19` when VAT is on)
  /// - `total`: VAT-inclusive cart total
  /// - `paidMoney`: amount being charged now
  /// - `balanceDue`: `total - paidMoney`, non-negative
  Map<String, Decimal> calculateTotals(CartChangeNotifier cartNotifier) {
    final builder = _totalsBuilderFor(cartNotifier.cart);
    final t = builder.computeTotals(cartNotifier.cart.totalAmount);

    // Balance is `total - paid`, clamped to zero. `Decimal` has no
    // `.clamp`, so manual compare.
    final diff = t.total - t.paid;
    final Decimal balanceDue = diff < Decimal.zero ? Decimal.zero : diff;

    return {
      'subtotal': t.subtotal,
      'vatAmount': t.vat,
      'vatRate': _applyVAT ? vatRate : Decimal.zero,
      'total': t.total,
      'paidMoney': t.paid,
      'balanceDue': balanceDue,
    };
  }

  bool canCheckout(CartChangeNotifier cartNotifier) {
    if (cartNotifier.cart.isEmpty) return false;

    if (_documentType.contains('invoice') && !hasRealCustomer) return false;

    if (_paymentType == _PayType.deposit) {
      final builder = _totalsBuilderFor(cartNotifier.cart);
      final totals = builder.computeTotals(cartNotifier.cart.totalAmount);
      if (_depositAmount <= Decimal.zero || _depositAmount > totals.total) {
        return false;
      }
    }
    return true;
  }

  CartPayloadBuilder _totalsBuilderFor(Cart cart) {
    return CartPayloadBuilder(
      providerId: 0,
      sellingUserId: 0,
      cart: cart,
      applyVAT: _applyVAT,
      paymentType: _payTypeFrom(_paymentType),
      paymentMethod: _payMethodFrom(_paymentMethod),
      depositAmount: _depositAmount,
    );
  }

  /// Flat summary map for display and telemetry.
  ///
  /// Monetary entries are [Decimal]; callers that `jsonEncode` the
  /// result should convert them with `double.parse(v.toString())` (or
  /// whatever wire helper the caller uses) at the boundary.
  Map<String, dynamic> getCheckoutSummary(CartChangeNotifier cartNotifier) {
    final totals = calculateTotals(cartNotifier);
    return {
      'customer': customerName,
      ...totals,
      'itemCount': cartNotifier.cart.itemCount,
      'productCount': cartNotifier.productItemCount,
      'serviceCount': cartNotifier.serviceItemCount,
      'documentType': _documentType,
      'paymentType': _paymentType,
      'paymentMethod': _paymentMethod,
      'paymentStatus': effectivePaymentStatus,
      'depositAmount': _depositAmount,
      'applyVAT': _applyVAT,
    };
  }
}
