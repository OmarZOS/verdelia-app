import 'package:flutter/material.dart';
import 'package:verdelia_core/business/product_form_data.dart';

class FormControllers {
  final TextEditingController barcode = TextEditingController();
  final TextEditingController name = TextEditingController();
  final TextEditingController brand = TextEditingController();
  final TextEditingController basePrice = TextEditingController();
  final TextEditingController price = TextEditingController();
  final TextEditingController quantity = TextEditingController();
  final TextEditingController description = TextEditingController();
  final TextEditingController origin = TextEditingController();

  void dispose() {
    barcode.dispose();
    name.dispose();
    brand.dispose();
    basePrice.dispose();
    price.dispose();
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
    quantity.text = formData.quantity?.toString() ?? '';
    description.text = formData.productDescription ?? '';
    origin.text = formData.originId?.toString() ?? '';
  }

  /// Format a nullable double for a text field. Uses two decimals when the
  /// value is present and non-zero; blank when absent, so the field starts
  /// empty for new products instead of showing "0.00".
  static String _asText(double? v) {
    if (v == null) return '';
    if (v == 0) return '';
    return v.toStringAsFixed(2);
  }
}
