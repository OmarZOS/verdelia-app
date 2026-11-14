// lib/screens/components/form/form_controllers.dart

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:verdelia_core/business/product_form_data.dart';

class FormControllers {
  final TextEditingController barcode = TextEditingController();
  final TextEditingController name = TextEditingController();
  final TextEditingController brand = TextEditingController();
  final TextEditingController basePrice = TextEditingController();
  final TextEditingController price = TextEditingController();
  final TextEditingController vat = TextEditingController();
  final TextEditingController quantity = TextEditingController();
  final TextEditingController description = TextEditingController();
  final TextEditingController origin = TextEditingController();

  void dispose() {
    barcode.dispose();
    name.dispose();
    brand.dispose();
    basePrice.dispose();
    price.dispose();
    vat.dispose();
    quantity.dispose();
    description.dispose();
    origin.dispose();
  }

  void syncWithFormData(ProductFormData formData) {
    name.text = formData.productName ?? '';
    brand.text = formData.productBrand ?? '';
    barcode.text = formData.productBarcode ?? '';
    basePrice.text = _asText(formData.productBasePrice);
    price.text = _asText(formData.price);
    // The VAT field shows the rate as a percentage string with the
    // `%` sign living on the input's suffix, not in the text itself.
    // Form data stores a fraction (`0.19`); the pricing card and
    // this field's UI work in percent (`19.00`). Convert here.
    vat.text = _asVatText(formData.productVatValue);
    quantity.text = formData.quantity?.toString() ?? '';
    description.text = formData.productDescription ?? '';
    origin.text = formData.originId?.toString() ?? '';
  }

  /// Format a nullable [Decimal] for a text field. Uses two decimals when
  /// the value is present and non-zero; blank when absent, so the field
  /// starts empty for new products instead of showing "0.00".
  static String _asText(Decimal? v) {
    if (v == null) return '';
    if (v == Decimal.zero) return '';
    return v.toStringAsFixed(2);
  }

  /// Format a VAT fraction for the tax text field. The field works in
  /// percent, so a stored `0.19` becomes `'19.00'`. Null (unknown) and
  /// zero (explicitly exempt) both display as blank — the user can
  /// tell the two apart from the pricing card, which shows the rate
  /// it will apply; a blank field means "leave the decision to the
  /// pricing card."
  static String _asVatText(Decimal? fraction) {
    if (fraction == null) return '';
    if (fraction == Decimal.zero) return '';
    // `Decimal * Decimal` stays exact: `0.19 * 100` is `19`, not
    // `18.999999999999996` as it would be with `double`.
    return (fraction * Decimal.fromInt(100)).toStringAsFixed(2);
  }
}
