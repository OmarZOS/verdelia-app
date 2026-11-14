// lib/screens/components/form/pricing_state.dart

import 'package:app_constants/app_constants.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

/// Single source of truth for the pricing section.
///
/// The card is a pure view: it reads these values and emits raw user
/// input. All derivation lives here so the card never has to know how
/// base / tax / margin / final relate to each other.
///
/// Two modes:
///   - [PricingMode.byProfit]     → `profitMargin` is the driver,
///                                   `finalPrice` is derived.
///   - [PricingMode.byFinalPrice] → `finalPrice` is the driver,
///                                   `profitMargin` is derived.
///
/// `basePrice` and `taxPercentage` are inputs in both modes; changing
/// either re-derives the dependent value for the current mode.
class PricingState extends ChangeNotifier {
  static final Decimal _defaultTaxPercentage = Decimal.fromInt(19);
  static final Decimal _defaultProfitMargin = Decimal.fromInt(20);

  Decimal _basePrice = Decimal.zero;
  Decimal _taxPercentage = _defaultTaxPercentage;
  Decimal _profitMargin = _defaultProfitMargin;
  Decimal _finalPrice = Decimal.zero;
  PricingMode _mode = PricingMode.byProfit;

  // ==================== Getters ====================

  Decimal get basePrice => _basePrice;
  Decimal get taxPercentage => _taxPercentage;
  Decimal get profitMargin => _profitMargin;
  Decimal get finalPrice => _finalPrice;
  PricingMode get mode => _mode;

  /// Price after tax but before margin. Computed on the fly; never
  /// stored, so it can't drift out of sync with base + tax.
  ///
  /// `base * (1 + tax/100)`. The division is converted to `Decimal`
  /// **immediately** so the rest of the arithmetic stays `Decimal`-typed
  /// (no `Rational` leaks through).
  Decimal get priceAfterTax {
    final taxFraction = (_taxPercentage / Decimal.fromInt(100))
        .toDecimal(scaleOnInfinitePrecision: 2);
    final taxFactor = Decimal.one + taxFraction;
    return _basePrice * taxFactor;
  }

  // ==================== Setters (inputs) ====================

  set basePrice(Decimal value) {
    if (value == _basePrice) return;
    _basePrice = value;
    _recompute();
    notifyListeners();
  }

  set taxPercentage(Decimal value) {
    if (value == _taxPercentage) return;
    _taxPercentage = value;
    _recompute();
    notifyListeners();
  }

  /// User typed into the profit-margin field. Only meaningful in
  /// [PricingMode.byProfit]; in the other mode the margin is derived
  /// and this setter is a no-op so a stray callback can't desync state.
  set profitMargin(Decimal value) {
    if (_mode != PricingMode.byProfit) return;
    if (value == _profitMargin) return;
    _profitMargin = value;
    _deriveFinalFromMargin();
    notifyListeners();
  }

  /// User typed into the final-price field. Only meaningful in
  /// [PricingMode.byFinalPrice]; in the other mode the final price is
  /// derived and this setter is a no-op.
  set finalPrice(Decimal value) {
    if (_mode != PricingMode.byFinalPrice) return;
    if (value == _finalPrice) return;
    _finalPrice = value;
    _deriveMarginFromFinal();
    notifyListeners();
  }

  set mode(PricingMode value) {
    if (value == _mode) return;
    _mode = value;
    _recompute();
    notifyListeners();
  }

  // ==================== Whole-state update ====================

  /// Seed from an existing product (or reset to a known baseline)
  /// without firing per-field derivations mid-flight.
  void load({
    required Decimal basePrice,
    Decimal? taxPercentage,
    Decimal? profitMargin,
    Decimal? finalPrice,
    PricingMode mode = PricingMode.byProfit,
  }) {
    _basePrice = basePrice;
    _taxPercentage = taxPercentage ?? _defaultTaxPercentage;
    _mode = mode;

    if (mode == PricingMode.byProfit) {
      _profitMargin = profitMargin ?? _defaultProfitMargin;
      _deriveFinalFromMargin();
    } else {
      _finalPrice = finalPrice ?? Decimal.zero;
      _deriveMarginFromFinal();
    }

    notifyListeners();
  }

  // ==================== AI suggestion ====================

  /// Apply an AI-suggested selling price. In either mode the final
  /// price becomes the suggestion; the derived field is recomputed.
  void applyAiPrice(Decimal aiPrice) {
    if (aiPrice <= Decimal.zero) return;
    _finalPrice = aiPrice;
    _deriveMarginFromFinal();
    notifyListeners();
  }

  // ==================== Reset ====================

  void reset() {
    _basePrice = Decimal.zero;
    _taxPercentage = _defaultTaxPercentage;
    _profitMargin = _defaultProfitMargin;
    _finalPrice = Decimal.zero;
    _mode = PricingMode.byProfit;
    notifyListeners();
  }

  // ==================== Derivation ====================

  void _recompute() {
    if (_mode == PricingMode.byProfit) {
      _deriveFinalFromMargin();
    } else {
      _deriveMarginFromFinal();
    }
  }

  /// `final = priceAfterTax * (1 + margin/100)`.
  void _deriveFinalFromMargin() {
    final marginFraction = (_profitMargin / Decimal.fromInt(100))
        .toDecimal(scaleOnInfinitePrecision: 2);
    final marginFactor = Decimal.one + marginFraction;
    _finalPrice = priceAfterTax * marginFactor;
  }

  /// `margin = (final - priceAfterTax) / priceAfterTax * 100`.
  ///
  /// Guard against division by zero: `priceAfterTax == 0` (i.e. base
  /// price zero) leaves the margin at `Decimal.zero` rather than
  /// throwing.
  void _deriveMarginFromFinal() {
    final after = priceAfterTax;
    if (after <= Decimal.zero) {
      _profitMargin = Decimal.zero;
      return;
    }
    final ratio =
        ((_finalPrice - after) / after).toDecimal(scaleOnInfinitePrecision: 2);
    _profitMargin = ratio * Decimal.fromInt(100);
  }
}
