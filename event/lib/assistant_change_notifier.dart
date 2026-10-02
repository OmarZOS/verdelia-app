import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_constants/app_constants.dart';
import 'package:verdelia_core/app/VerdeliaException.dart';
import 'package:verdelia_core/business/ProductResponse.dart';
import 'package:verdelia_core/business/iProduct.dart';
import 'package:verdelia_core/mediation/StorageService.dart';
import 'package:locator/locator.dart';

import 'components/lib.dart';

class AssistantNotifier extends ChangeNotifier {
  final StorageService _storageService = AppLocator.get<StorageService>();

  // ===== State =====
  IProduct? _currentProduct;
  bool _isLoading = false;
  String? _lastError;
  String? _lastOperation;
  DataSource? source_of_data;
  DateTime? _lastUpdated;

  Completer<void>? _currentOperation;

  // ===== Getters =====
  IProduct? get product => _currentProduct;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  String? get lastOperation => _lastOperation;
  DateTime? get lastUpdated => _lastUpdated;

  // ================================================================
  // PRODUCT FETCHING
  // ================================================================

  Future<void> fetchProductByBarcode(String barcode,
      {bool onlyFromDB = false}) async {
    if (barcode.trim().isEmpty) {
      _setError("Invalid barcode", operation: "barcode_invalid");
      return;
    }

    _beginOperation("barcode_lookup");

    try {
      final endpoint = onlyFromDB
          ? AppConstants.getProductDBSearchByBarcodeEndpoint
          : AppConstants.getProductSearchByBarcodeEndpoint;

      final result = await _storageService.get(
        AppConstants.apiBaseUrl + endpoint,
        barcode,
      );

      if (result is! Map<String, dynamic>) {
        _setError("Invalid server response", operation: "barcode_invalid_api");
        return;
      }

      final parsed = IProductResponse.fromJson(result);

      source_of_data = (parsed.source == "ai"
          ? DataSource.aiGenerated
          : DataSource.databaseFetched);

      if (parsed.products.isEmpty) {
        _setState(
          operation: "barcode_no_product",
          message: "Product not found",
        );
        return;
      }

      _currentProduct = parsed.products.first;

      // AUTO-POPULATE FIELD DATA when product is found
      _populateFieldDataFromProduct(
        _currentProduct!,
        source: source_of_data!,
      );

      _setState(
        operation: "barcode_success",
        message: "Found product: ${_currentProduct!.iproductName}",
      );
    } catch (e) {
      _setError("Error: $e", operation: "barcode_error");
    } finally {
      _endOperation();
    }
  }

  Future<void> recognizeProductFromImage(dynamic imageData) async {
    _beginOperation("image_recognition");

    try {
      final result = await _storageService.insertBinary(
        AppConstants.apiBaseUrl + AppConstants.getProductSearchByImageEndpoint,
        _storageService.toFormData(imageData),
      );

      if (result is! List || result.isEmpty) {
        _setState(operation: "image_no_match", message: "No product detected");
        return;
      }

      final product = result
          .whereType<Map<String, dynamic>>()
          .map(IProduct.fromJson)
          .firstOrNull;

      if (product == null) {
        _setState(operation: "image_empty", message: "Invalid product data");
        return;
      }

      _currentProduct = product;

      // AUTO-POPULATE FIELD DATA when product is recognized
      _populateFieldDataFromProduct(
        product,
        source: DataSource.aiGenerated, // Image recognition is always AI
      );

      _setState(
        operation: "image_success",
        message: "AI identified: ${product.iproductName}",
      );
    } catch (e) {
      _setError("Error: $e", operation: "image_error");
    } finally {
      _endOperation();
    }
  }

  /// Check if any field has been populated from AI/DB
  bool get hasAssistedData {
    return _fieldData.values.any((field) =>
        field.source == DataSource.aiGenerated ||
        field.source == DataSource.databaseFetched);
  }

  // In your AssistantNotifier, update the _populateFieldDataFromProduct method:
  void _populateFieldDataFromProduct(IProduct product,
      {required DataSource source}) {
    final fieldValues = {
      ProductAssistedFields.IPRODUCT_NAME: product.iproductName,
      ProductAssistedFields.IPRODUCT_BRAND: product.iproductBrand,
      ProductAssistedFields.IPRODUCT_BARCODE: product.iproductBarcode,
      ProductAssistedFields.IPRODUCT_ESTIMATED_PRICE_DA:
          product.iproductEstimatedPriceDA,
      ProductAssistedFields.IPRODUCT_GLUTEN_STATUS:
          product.iproductGlutenStatus,
    };

    // Calculate confidence based on source and data quality
    double calculateConfidence(IProduct product) {
      double confidence = 0.8; // Base confidence

      // Boost confidence for database sources
      if (source == DataSource.databaseFetched) confidence += 0.15;

      // Reduce confidence for incomplete data
      if (product.iproductName == null || product.iproductName!.isEmpty) {
        confidence -= 0.2;
      }
      if (product.iproductBrand == null || product.iproductBrand!.isEmpty) {
        confidence -= 0.1;
      }

      return confidence.clamp(0.1, 1.0);
    }

    // Set default values for quantity and quantifier
    final assistedFieldValues = {
      ProductAssistedFields.QUANTIFIER: "pc",
      ProductAssistedFields.QUANTITY: "1"
    };

    // Set all fields at once to avoid multiple notifications
    final allFieldValues = {
      ...fieldValues,
      ...assistedFieldValues,
    };

    setMultipleFields(
      fieldValues: allFieldValues,
      source: source,
      confidence: calculateConfidence(product),
    );

    debugPrint(
        "📝 Populated field data from ${source.name} with confidence: ${calculateConfidence(product)}");
  }

// Add method to manually trigger field data sync
  void syncFieldDataWithCurrentProduct({DataSource? customSource}) {
    if (_currentProduct == null) {
      debugPrint("⚠️ No current product to sync field data");
      return;
    }

    final source = customSource ?? source_of_data ?? DataSource.aiGenerated;
    _populateFieldDataFromProduct(_currentProduct!, source: source);

    _setState(
      operation: "field_data_synced",
      message: "Field data synced with current product",
    );
  }

  // ================================================================
  // PRODUCT MANAGEMENT
  // ================================================================

  /// Set a product manually (for testing or manual creation)
  void setProduct(IProduct product, {String source = "manual"}) {
    _currentProduct = product;
    _setState(
      operation: "product_set",
      message: "Product set: ${product.iproductName} ($source)",
    );
  }

  /// Clear the current product
  void clearProduct() {
    _currentProduct = null;
    _setState(
      operation: "product_cleared",
      message: "Product cleared",
    );
  }

  /// Update specific fields of the current product
  void updateProductFields(Map<String, dynamic> updates) {
    if (_currentProduct == null) return;

    // Create a new product with updated fields
    final updatedProduct = IProduct(
      idIproduct: _currentProduct!.idIproduct,
      iproductName: updates['iproduct_name'] ?? _currentProduct!.iproductName,
      iproductBrand:
          updates['iproduct_brand'] ?? _currentProduct!.iproductBrand,
      iproductBarcode:
          updates['iproduct_barcode'] ?? _currentProduct!.iproductBarcode,
      iproductEstimatedPriceDA: updates['iproduct_estimated_price_DA'] ??
          _currentProduct!.iproductEstimatedPriceDA,
      iproductGlutenStatus: updates['iproduct_gluten_status'] ??
          _currentProduct!.iproductGlutenStatus,
      // iproductDescription: updates['iproduct_description'] ??
      //     _currentProduct!.iproductDescription,
      iproductImageUrl: _currentProduct!.iproductImageUrl,
      iproductInfoSource: _currentProduct!.iproductInfoSource,
      // iproductInfoConfidence: _currentProduct!.iproductInfoConfidence,
      iproductLastPriceUpdate: _currentProduct!.iproductLastPriceUpdate,
      iproductCreatedAt: _currentProduct!.iproductCreatedAt,
      iproductUpdatedAt: _currentProduct!.iproductUpdatedAt,
      iproductModelName: _currentProduct!.iproductModelName,
    );

    _currentProduct = updatedProduct;
    _setState(
      operation: "product_updated",
      message: "Product fields updated",
    );
  }

  // ================================================================
  // STATE HANDLING
  // ================================================================

  void _beginOperation(String op) {
    _cancelCurrentOperation();
    _isLoading = true;
    _lastOperation = "loading_$op";
    _lastError = null;
    _currentOperation = Completer<void>();
    notifyListeners();
  }

  void _endOperation() {
    _isLoading = false;
    _currentOperation?.complete();
    _currentOperation = null;
    notifyListeners();
  }

  void _setState({
    required String operation,
    String? message,
  }) {
    _lastOperation = operation;
    if (message != null) debugPrint("✅ Assistant: $message");
    notifyListeners();
  }

  void _setError(String message, {String? operation}) {
    _lastError = message;
    _lastOperation = operation ?? "error";
    debugPrint("❌ $message");
    notifyListeners();
  }

  void _cancelCurrentOperation() {
    if (_currentOperation != null && !_currentOperation!.isCompleted) {
      _currentOperation!.completeError("Operation cancelled");
      debugPrint("⏹️ Cancelled async operation");
    }
  }

  @override
  void dispose() {
    _cancelCurrentOperation();
    super.dispose();
  }

  void clearAll() {
    _cancelCurrentOperation();
    _currentProduct = null;
    _lastError = null;
    _lastOperation = null;
    _isLoading = false;
    notifyListeners();
    debugPrint("🧹 Cleared all AssistantNotifier state");
  }

  // Field data management
  final Map<String, FieldData> _fieldData = {};
  Map<String, FieldData> get fieldData => Map.unmodifiable(_fieldData);

  /// Get field data for a specific field
  FieldData? getFieldData(String fieldId) {
    return _fieldData[fieldId];
  }

  /// Check if a field has been edited by user
  bool isFieldEdited(String fieldId) {
    return _fieldData[fieldId]?.isEdited ?? false;
  }

  DataSource getFieldSource(String fieldId) {
    return _fieldData[fieldId]?.source ?? DataSource.userInput;
  }

  void setFieldData({
    required String fieldId,
    required dynamic value,
    required DataSource source,
    double confidence = 1.0,
    String? operationId,
  }) {
    // Skip if the user has already touched this field.
    final existing = _fieldData[fieldId];
    if (existing != null &&
        existing.isEdited &&
        source != DataSource.userInput) {
      debugPrint('⏭️ Skipping $fieldId — user already edited it');
      return;
    }

    _fieldData[fieldId] = FieldData(
      value: value,
      source: source,
      confidence: confidence.clamp(0.0, 1.0),
      isEdited: false,
      lastUpdated: DateTime.now(),
      operationId: operationId,
    );

    _setState(
      operation: "field_data_set",
      message: "Updated field: $fieldId",
    );
  }

  void setMultipleFields({
    required Map<String, dynamic> fieldValues,
    required DataSource source,
    double confidence = 1.0,
  }) {
    fieldValues.forEach((key, value) {
      if (value != null) {
        setFieldData(
          fieldId: key,
          value: value,
          source: source,
          confidence: confidence,
        );
      }
    });
  }

  // In your AssistantNotifier, add a safety check:
  void markFieldAsEdited(String fieldId) {
    final existingData = _fieldData[fieldId];

    // Safety check - only proceed if field exists and isn't already edited
    if (existingData != null && !existingData.isEdited) {
      _fieldData[fieldId] = existingData.copyWith(
        isEdited: true,
        lastUpdated: DateTime.now(),
      );

      _lastUpdated = DateTime.now();
      _lastOperation = 'field_edited';
      notifyListeners();

      debugPrint('✏️ Field marked as edited: $fieldId');
    } else {
      debugPrint('ℹ️ Field $fieldId already edited or does not exist');
    }
  }

  /// Get overall confidence score for all fields
  double getProductConfidenceScore() {
    if (_fieldData.isEmpty) return 0.0;

    final confidenceValues = _fieldData.values
        .map((field) => field.confidence)
        .where((conf) => conf > 0.0)
        .toList();

    if (confidenceValues.isEmpty) return 0.0;

    final totalConfidence = confidenceValues.reduce((a, b) => a + b);
    return totalConfidence / confidenceValues.length;
  }

  /// Clear all field data
  void clearFieldData() {
    _fieldData.clear();
    _setState(
      operation: "field_data_cleared",
      message: "Cleared all field data",
    );
  }
}
