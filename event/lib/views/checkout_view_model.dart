import 'dart:convert';
import 'dart:developer' as developer;

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

/// Document types the checkout flow understands.
abstract class _DocType {
  static const receipt = 'receipt';
  static const invoice = 'invoice';
  static const invoiceReceipt = 'invoice_receipt';
  static const none = 'none';
}

/// Payment intents the checkout flow understands.
abstract class _PayType {
  static const payment = 'payment';
  static const deposit = 'deposit';
  static const installment = 'installment';
}

/// Payment methods the checkout flow understands.
abstract class _PayMethod {
  static const cash = 'cash';
  static const card = 'card';
  static const bank = 'bank';
  static const mobile = 'mobile';
}

/// Payment statuses recorded on the cart.
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

  const CheckoutResult._({
    required this.isSuccess,
    required this.message,
    this.orderId,
  });

  factory CheckoutResult.success(String message, {int? orderId}) =>
      CheckoutResult._(isSuccess: true, message: message, orderId: orderId);

  factory CheckoutResult.failure(String message) =>
      CheckoutResult._(isSuccess: false, message: message);
}

// ==================== VIEW MODEL ====================

class CheckoutViewModel extends ChangeNotifier {
  final CartService _cartService = AppLocator.get<CartService>();

  static const String _prefsKey = 'checkout_parameters';
  static const double vatRate = 0.19;

  // ─── Customer ───
  AppUser? _selectedCustomer;
  Person? _selectedPerson;

  // ─── Document ───
  String _documentType = _DocType.receipt;
  bool _applyVAT = false;

  // ─── Payment ───
  String _paymentType = _PayType.payment;
  String _paymentMethod = _PayMethod.cash;
  double _depositAmount = 0.0;
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
  double get depositAmount => _depositAmount;
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

  /// Payment status derived from the payment method and intent.
  ///
  ///   cash + full payment → completed (settled on the spot)
  ///   everything else     → pending  (awaits gateway or confirmation)
  String get effectivePaymentStatus {
    if (_paymentType == _PayType.payment && _paymentMethod == _PayMethod.cash) {
      return _PayStatus.completed;
    }
    return _PayStatus.pending;
  }

  bool get isGuestCustomer =>
      _selectedCustomer != null && _selectedCustomer!.idAppUser == 0;

  bool get hasRealCustomer =>
      (_selectedCustomer != null && _selectedCustomer!.idAppUser != 0) ||
      _selectedPerson != null;

  String get customerName {
    final customer = _selectedCustomer;
    if (customer != null) {
      if (customer.idAppUser == 0) return 'Guest';
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

  /// Checkout using the current local cart (from CartChangeNotifier).
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

  /// Checkout with a specific cart (used by API-backed carts).
  Future<CheckoutResult> processCartCheckout({
    required Cart cart,
    required int sellingUserId,
    required int providerId,
  }) async {
    return _process(
      cart: cart,
      sellingUserId: sellingUserId,
      providerId: providerId,
    );
  }

  /// Shared implementation for both checkout entry points.
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

    try {
      if (cart.isEmpty) {
        return _finish(CheckoutResult.failure('Cart is empty'));
      }

      final payload = _buildPayload(
        cart: cart,
        sellingUserId: sellingUserId,
        providerId: providerId,
      );
      final result = await _submit(payload);
      return _finish(result);
    } catch (e, stack) {
      developer.log(
        'Checkout failed',
        name: 'CheckoutViewModel',
        error: e,
        stackTrace: stack,
      );
      return _finish(CheckoutResult.failure('Checkout failed: $e'));
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  CheckoutResult _finish(CheckoutResult result) {
    _lastCheckoutResult = result;
    notifyListeners();
    return result;
  }

  Future<CheckoutResult> _submit(Map<String, dynamic> payload) async {
    try {
      final cart = await _cartService.addCart(payload);

      if (cart?.cartId == null) {
        return CheckoutResult.failure('Failed to place order');
      }

      final cartId = cart!.cartId!;
      final wantsPaymentNow =
          _paymentType == _PayType.payment || _paymentType == _PayType.deposit;

      if (wantsPaymentNow && effectivePaymentStatus == null) {
        return CheckoutResult.failure(
          'Cart created but payment was not recorded (ID $cartId)',
        );
      }

      return CheckoutResult.success(
        'Order placed successfully. Order ID: $cartId',
        orderId: cartId,
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

  // ==================== PAYLOAD BUILDER ====================

  /// Map the ViewModel's UI state into a `CartPayloadBuilder` and produce
  /// the exact request body the backend expects.
  ///
  /// All wire-format knowledge lives in `CartPayloadBuilder`; this method is
  /// only responsible for translating ViewModel strings into its enums.
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
      depositAmount: _depositAmount,
      dueDate: _dueDate == null ? null : DateTime.tryParse(_dueDate!),
      delivery: _buildDeliveryPayload(),
      notes: _notes,
      parameters: {
        for (final p in _parameters) p.key: p.value,
      },
    ).build();
  }

  /// Translate the ViewModel's `DeliveryData` into the backend's
  /// `Delivery_API` shape. Returns null for pickups so the field is omitted.
  CartDeliveryPayload? _buildDeliveryPayload() {
    if (_deliveryType == 'pickup' || _deliveryData == null) return null;

    return CartDeliveryPayload(
      deliveryShippingMethod:
          _deliveryData!.deliveryShippingMethod ?? 'standard',
      deliverySpecialInstructions: _deliveryData!.deliverySpecialInstructions,
      deliveryAddressId: _deliveryData!.deliveryAddressId ?? 0,
      deliveryProviderId: _deliveryData!.deliveryProviderId ?? 0,
      deliveryStatus: 'pending',
      deliverySourceType: 'cart',
      // Fill remaining fields from _deliveryData as available.
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
    _applyVAT = apply;
    notifyListeners();
  }

  void setPaymentType(String type) {
    if (_paymentType == type) return;
    _paymentType = type;

    if (type != _PayType.deposit) {
      _depositAmount = 0.0;
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

  void setDepositAmount(double amount) {
    if (_depositAmount == amount) return;
    _depositAmount = amount;
    // A deposit is paid now, not deferred — drop any pending due date.
    if (_paymentType == _PayType.deposit) {
      _dueDate = null;
    }
    notifyListeners();
  }

  void setInstallmentDate(DateTime dueDate) {
    _dueDate = dueDate.toIso8601String();
    // A date only makes sense when the intent is installment.
    if (_paymentType != _PayType.installment) {
      _paymentType = _PayType.installment;
      _depositAmount = 0.0;
    }
    notifyListeners();
  }

  void setCardType(String type) {
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
    _notes = notes;
    notifyListeners();
  }

  // ==================== PARAMETERS ====================

  void setParameters(List<CheckoutParameter> parameters) {
    _parameters = List.of(parameters);
    notifyListeners();
  }

  void addParameter(String key, String value) {
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
    _depositAmount = 0.0;
    _lastCheckoutResult = null;
    _deliveryData = null;
    _syncVatWithDocumentType();
    notifyListeners();
  }

  void resetAfterCheckout() {
    _selectedCustomer = null;
    _selectedPerson = null;
    _notes = '';
    _parameters = [];
    _cardDetails = null;
    _bankDetails = null;
    _mobileProvider = null;
    _depositAmount = 0.0;
    _lastCheckoutResult = null;
    _deliveryData = null;
    _syncVatWithDocumentType();
    notifyListeners();
  }

  // ==================== TOTALS / VALIDATION ====================

  /// Public totals helper used by the UI. Delegates to a builder instance
  /// so the arithmetic has one source of truth.
  Map<String, double> calculateTotals(CartChangeNotifier cartNotifier) {
    final t = CartPayloadBuilder(
      providerId: 0,
      sellingUserId: 0,
      cart: cartNotifier.cart,
      applyVAT: _applyVAT,
      paymentType: _payTypeFrom(_paymentType),
      depositAmount: _depositAmount,
    ).computeTotals(cartNotifier.cart.totalAmount);

    return {
      'subtotal': t.subtotal,
      'vatAmount': t.vat,
      'vatRate': _applyVAT ? vatRate : 0.0,
      'total': t.total,
      'paidMoney': t.paid,
      'balanceDue': t.total - t.paid,
    };
  }

  bool canCheckout(CartChangeNotifier cartNotifier) {
    if (cartNotifier.cart.isEmpty) return false;

    if (_paymentType == _PayType.deposit) {
      final totals = CartPayloadBuilder(
        providerId: 0,
        sellingUserId: 0,
        cart: cartNotifier.cart,
        applyVAT: _applyVAT,
        paymentType: PayType.deposit,
        depositAmount: _depositAmount,
      ).computeTotals(cartNotifier.cart.totalAmount);
      if (_depositAmount <= 0 || _depositAmount > totals.total) return false;
    }
    return true;
  }

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
