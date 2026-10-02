// lib/business/iProduct.dart

import 'NamingContribution.dart';

/// One row from the `naming_contribution` table.
///
/// Carries the trilingual name shared by every entity that has one:
/// products, categories, providers, ingredients, roles. The `en` field
/// is the canonical anchor the API resolves by; `ar` and `fr` are
/// optional translations that fall back to `en` when absent.

class IProduct {
  final int? idIproduct;
  final String iproductBarcode;
  final String iproductName;
  final String iproductBrand;
  final double iproductEstimatedPriceDA;

  /// ISO 4217 currency code for [iproductEstimatedPriceDA]. Defaults to
  /// "DZD" when the payload doesn't carry one.
  final String iproductPriceCurrency;

  final String iproductGlutenStatus;
  final String iproductInfoSource;

  /// AI extraction confidence as a fraction in [0, 1]. Zero when the
  /// payload doesn't carry a score.
  final double iproductInfoConfidence;

  final DateTime? iproductLastPriceUpdate;
  final String? iproductImageUrl;
  final DateTime iproductCreatedAt;
  final DateTime iproductUpdatedAt;
  final String iproductModelName;

  /// Foreign key to the naming contribution row, when the backend
  /// sends the raw id alongside the nested object. Null when the
  /// iproduct has no naming contribution.
  final int? iproductNamingRef;

  /// Category reference, when the iproduct is classified. Null for
  /// uncategorised imports.
  final int? iproductCategoryId;

  /// Trilingual naming block, when the backend includes it.
  ///
  /// Null for iproducts created before the naming layer, or whose API
  /// payload didn't carry a `naming_contribution` object.
  final NamingContribution? namingContribution;

  // Helper method to parse price
  static double _parsePrice(dynamic priceData) {
    if (priceData == null) return 0.0;

    if (priceData is num) {
      return priceData.toDouble();
    }

    if (priceData is String) {
      // Remove currency symbols and whitespace
      final cleaned =
          priceData.replaceAll(RegExp(r'[^\d.,]'), '').replaceAll(',', '.');
      return double.tryParse(cleaned) ?? 0.0;
    }

    return 0.0;
  }

  IProduct({
    this.idIproduct,
    required this.iproductBarcode,
    required this.iproductName,
    required this.iproductBrand,
    required this.iproductEstimatedPriceDA,
    this.iproductPriceCurrency = 'DZD',
    required this.iproductGlutenStatus,
    required this.iproductInfoSource,
    this.iproductInfoConfidence = 0.0,
    this.iproductLastPriceUpdate,
    this.iproductImageUrl,
    required this.iproductCreatedAt,
    required this.iproductUpdatedAt,
    required this.iproductModelName,
    this.iproductNamingRef,
    this.iproductCategoryId,
    this.namingContribution,
  });

  // Add this factory method to your IProduct class:
  factory IProduct.empty() {
    final now = DateTime.now();
    return IProduct(
      idIproduct: null,
      iproductBarcode: '',
      iproductName: '',
      iproductBrand: '',
      iproductEstimatedPriceDA: 0.0,
      iproductPriceCurrency: 'DZD',
      iproductGlutenStatus: 'unknown',
      iproductInfoSource: 'manual',
      iproductInfoConfidence: 0.0,
      iproductLastPriceUpdate: null,
      iproductImageUrl: null,
      iproductCreatedAt: now,
      iproductUpdatedAt: now,
      iproductModelName: 'manual',
      iproductNamingRef: null,
      iproductCategoryId: null,
      namingContribution: null,
    );
  }

  // Helper method to validate gluten status
  static String _validateGlutenStatus(String status) {
    const validStatuses = [
      'gluten_free',
      'contains_gluten',
      'may_contain_gluten',
      'unknown',
    ];

    final lowerStatus = status.toLowerCase().trim();

    // Map common variations to standard values
    final statusMap = {
      'free': 'gluten_free',
      'glutenfree': 'gluten_free',
      'sans gluten': 'gluten_free',
      'without gluten': 'gluten_free',
      'has gluten': 'contains_gluten',
      'with gluten': 'contains_gluten',
      'contient du gluten': 'contains_gluten',
      'may contain': 'may_contain_gluten',
      'traces': 'may_contain_gluten',
      'cross contamination': 'may_contain_gluten',
    };

    // Check if it's a valid status
    if (validStatuses.contains(lowerStatus)) {
      return lowerStatus;
    }

    // Check if it's a mapped variation
    if (statusMap.containsKey(lowerStatus)) {
      return statusMap[lowerStatus]!;
    }

    // Check if it contains any valid status
    for (final validStatus in validStatuses) {
      if (lowerStatus.contains(validStatus)) {
        return validStatus;
      }
    }

    return 'unknown';
  }

  factory IProduct.fromPromptResponse({
    required Map<String, dynamic> promptJson,
    required String barcode,
    String? modelName,
    String? imageUrl,
  }) {
    try {
      // Validate barcode
      if (barcode.isEmpty) {
        // throw ArgumentError('Barcode cannot be empty');
      }

      // Extract and clean data
      final extractedData = _extractProductData(promptJson);

      final now = DateTime.now();

      return IProduct(
        idIproduct: null,
        iproductBarcode: barcode,
        iproductName: extractedData['name']!,
        iproductBrand: extractedData['brand']!,
        iproductEstimatedPriceDA: extractedData['price']!,
        iproductPriceCurrency: 'DZD',
        iproductGlutenStatus: extractedData['gluten_status']!,
        iproductInfoSource: extractedData['source']!,
        iproductInfoConfidence: 0.0,
        iproductLastPriceUpdate: now,
        iproductImageUrl: imageUrl,
        iproductCreatedAt: now,
        iproductUpdatedAt: now,
        iproductModelName: modelName ?? 'gemini-ai',
        iproductNamingRef: null,
        iproductCategoryId: null,
        namingContribution: null,
      );
    } catch (e) {
      throw FormatException(
          'Failed to create IProduct from prompt response: $e');
    }
  }

  static Map<String, dynamic> _extractProductData(Map<String, dynamic> json) {
    // Name extraction with fallback
    final name = _extractName(json);

    // Brand extraction with fallback
    final brand = _extractBrand(json, name);

    // Price extraction
    final price = _extractPrice(json);

    // Gluten status extraction
    final glutenStatus = _extractGlutenStatus(json);

    // Source extraction
    final source = json['source']?.toString() ?? 'ai_generated';

    return {
      'name': name,
      'brand': brand,
      'price': price,
      'gluten_status': glutenStatus,
      'source': source,
    };
  }

  static String _extractName(Map<String, dynamic> json) {
    final name = json['name']?.toString();
    if (name != null && name.isNotEmpty && name != 'Unknown') {
      return name;
    }

    // Try product_name as fallback
    final productName = json['product_name']?.toString();
    if (productName != null && productName.isNotEmpty) {
      return productName;
    }

    return 'Unknown Product';
  }

  static String _extractBrand(Map<String, dynamic> json, String productName) {
    final brand = json['brand']?.toString();
    if (brand != null && brand.isNotEmpty && brand != 'Unknown') {
      return brand;
    }

    // Try to extract brand from product name (e.g., "Coca Cola" -> "Coca Cola")
    if (productName.contains(' ')) {
      final words = productName.split(' ');
      if (words.length > 1) {
        return words.first; // Use first word as brand
      }
    }

    return 'Unknown Brand';
  }

  static double _extractPrice(Map<String, dynamic> json) {
    // Try multiple price fields
    final priceFields = [
      'estimated_price_DA',
      'price_da',
      'price',
      'estimated_price',
    ];

    for (final field in priceFields) {
      final value = json[field];
      if (value != null) {
        final parsed = _parsePrice(value);
        if (parsed > 0) return parsed;
      }
    }

    return 0.0;
  }

  static String _extractGlutenStatus(Map<String, dynamic> json) {
    final glutenFields = [
      'gluten_status',
      'gluten_tolerability',
      'gluten',
      'gluten_content',
    ];

    for (final field in glutenFields) {
      final value = json[field]?.toString();
      if (value != null && value.isNotEmpty) {
        final validated = _validateGlutenStatus(value);
        if (validated != 'unknown') {
          return validated;
        }
      }
    }

    return 'unknown';
  }

  factory IProduct.fromJson(Map<String, dynamic> json) {
    // Helper to safely read strings
    String readString(String key, {String fallback = ''}) {
      final value = json[key];
      return (value is String && value.isNotEmpty) ? value : fallback;
    }

    // Helper to safely read numbers. Reads a few alternative keys the
    // backend uses across environments.
    double readDouble(String key, {double fallback = 0.0}) {
      final value = json[key];
      if (value is num) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? fallback;
      }
      return fallback;
    }

    // Helper to safely read nullable ints.
    int? readIntOrNull(String key) {
      final value = json[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String && value.isNotEmpty) return int.tryParse(value);
      return null;
    }

    // Helper to safely parse DateTime
    DateTime? readDate(String key, {bool required = false}) {
      final value = json[key];
      if (value == null) {
        return required ? DateTime.fromMillisecondsSinceEpoch(0) : null;
      }

      if (value is String && value.isNotEmpty) {
        try {
          return DateTime.parse(value);
        } catch (_) {}
      }
      return required ? DateTime.fromMillisecondsSinceEpoch(0) : null;
    }

    return IProduct(
      idIproduct:
          json['id_iproduct'] is int ? json['id_iproduct'] as int : null,

      iproductBarcode: readString('iproduct_barcode'),
      iproductName: readString('iproduct_name'),
      iproductBrand: readString('iproduct_brand'),
      iproductInfoSource:
          readString('iproduct_info_source', fallback: 'openai'),
      iproductModelName: readString('iproduct_model_name'),

      // The backend sends the price under either key depending on the
      // environment. Try the `_DA` form first, fall back to the bare
      // form, then to zero.
      iproductEstimatedPriceDA: readDouble(
        'iproduct_estimated_price_DA',
        fallback: readDouble('iproduct_estimated_price'),
      ),

      iproductPriceCurrency:
          readString('iproduct_price_currency', fallback: 'DZD'),

      iproductGlutenStatus:
          readString('iproduct_gluten_status', fallback: 'unknown'),

      iproductInfoConfidence: readDouble('iproduct_info_confidence'),

      iproductImageUrl: (json['iproduct_image_url'] is String &&
              (json['iproduct_image_url'] as String).isNotEmpty)
          ? json['iproduct_image_url'] as String
          : null,

      iproductLastPriceUpdate: readDate('iproduct_last_price_update'),

      // Required timestamps — fallback to epoch if malformed.
      // `updated_at` is emitted as either `iproduct_updated_at` or
      // `iproduct_last_update` depending on the serializer.
      iproductCreatedAt: readDate('iproduct_created_at', required: true)!,

      iproductUpdatedAt: readDate('iproduct_updated_at') ??
          readDate('iproduct_last_update') ??
          readDate('iproduct_created_at', required: true)!,

      iproductNamingRef: readIntOrNull('iproduct_naming_ref'),
      iproductCategoryId: readIntOrNull('iproduct_category_id'),

      // Parse the nested naming block when present. Older iproducts
      // have no such key; the field stays null and `nameFor` falls
      // back to `iproductName`.
      namingContribution: json['naming_contribution'] == null
          ? null
          : NamingContribution.fromJson(json['naming_contribution']),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      if (idIproduct != null) 'id_iproduct': idIproduct,
      'iproduct_barcode': iproductBarcode,
      'iproduct_name': iproductName,
      'iproduct_brand': iproductBrand,
      'iproduct_estimated_price_DA': iproductEstimatedPriceDA,
      'iproduct_price_currency': iproductPriceCurrency,
      'iproduct_gluten_status': iproductGlutenStatus,
      'iproduct_info_source': iproductInfoSource,
      'iproduct_info_confidence': iproductInfoConfidence,
      'iproduct_last_price_update': iproductLastPriceUpdate?.toIso8601String(),
      'iproduct_image_url': iproductImageUrl,
      'iproduct_created_at': iproductCreatedAt.toIso8601String(),
      'iproduct_updated_at': iproductUpdatedAt.toIso8601String(),
      'iproduct_last_update': iproductUpdatedAt.toIso8601String(),
      'iproduct_model_name': iproductModelName,
      if (iproductNamingRef != null) 'iproduct_naming_ref': iproductNamingRef,
      if (iproductCategoryId != null)
        'iproduct_category_id': iproductCategoryId,
      if (namingContribution != null)
        'naming_contribution': namingContribution!.toJson(),
    };
  }

  // Copy with method for immutability
  IProduct copyWith({
    int? idIproduct,
    String? iproductBarcode,
    String? iproductName,
    String? iproductBrand,
    double? iproductEstimatedPriceDA,
    String? iproductPriceCurrency,
    String? iproductGlutenStatus,
    String? iproductInfoSource,
    double? iproductInfoConfidence,
    DateTime? iproductLastPriceUpdate,
    String? iproductImageUrl,
    DateTime? iproductCreatedAt,
    DateTime? iproductUpdatedAt,
    String? iproductModelName,
    int? iproductNamingRef,
    int? iproductCategoryId,
    NamingContribution? namingContribution,
  }) {
    return IProduct(
      idIproduct: idIproduct ?? this.idIproduct,
      iproductBarcode: iproductBarcode ?? this.iproductBarcode,
      iproductName: iproductName ?? this.iproductName,
      iproductBrand: iproductBrand ?? this.iproductBrand,
      iproductEstimatedPriceDA:
          iproductEstimatedPriceDA ?? this.iproductEstimatedPriceDA,
      iproductPriceCurrency:
          iproductPriceCurrency ?? this.iproductPriceCurrency,
      iproductGlutenStatus: iproductGlutenStatus ?? this.iproductGlutenStatus,
      iproductInfoSource: iproductInfoSource ?? this.iproductInfoSource,
      iproductInfoConfidence:
          iproductInfoConfidence ?? this.iproductInfoConfidence,
      iproductLastPriceUpdate:
          iproductLastPriceUpdate ?? this.iproductLastPriceUpdate,
      iproductImageUrl: iproductImageUrl ?? this.iproductImageUrl,
      iproductCreatedAt: iproductCreatedAt ?? this.iproductCreatedAt,
      iproductUpdatedAt: iproductUpdatedAt ?? this.iproductUpdatedAt,
      iproductModelName: iproductModelName ?? this.iproductModelName,
      iproductNamingRef: iproductNamingRef ?? this.iproductNamingRef,
      iproductCategoryId: iproductCategoryId ?? this.iproductCategoryId,
      namingContribution: namingContribution ?? this.namingContribution,
    );
  }

  // ==================== Convenience ====================

  /// Resolve the iproduct's name in a language. Prefers the naming
  /// contribution when present, falls back to the flat `iproductName`.
  String nameFor(String lang) {
    final resolved = namingContribution?.nameFor(lang) ?? '';
    if (resolved.isNotEmpty) return resolved;
    return iproductName;
  }

  // Helper methods
  bool get isGlutenFree => iproductGlutenStatus == 'gluten_free';
  bool get containsGluten => iproductGlutenStatus == 'contains_gluten';
  bool get mayContainGluten => iproductGlutenStatus == 'may_contain_gluten';
  bool get hasUnknownGlutenStatus => iproductGlutenStatus == 'unknown';

  /// True when the AI extraction ran with a confidence score above the
  /// midpoint. Useful for flagging rows a human should review.
  bool get isHighConfidence => iproductInfoConfidence >= 0.75;

  /// True when the extraction was AI-sourced (i.e. not entered by hand).
  bool get isAiSourced =>
      iproductInfoSource.isNotEmpty && iproductInfoSource != 'manual';

  // Price formatting
  String get formattedPrice =>
      '${iproductEstimatedPriceDA.toStringAsFixed(2)} $iproductPriceCurrency';

  // Check if price is recent (within 30 days)
  bool get isPriceRecent {
    if (iproductLastPriceUpdate == null) return false;
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return iproductLastPriceUpdate!.isAfter(thirtyDaysAgo);
  }

  // Validation methods
  bool get isValidBarcode => iproductBarcode.isNotEmpty;
  bool get isValidName => iproductName.isNotEmpty;
  bool get hasValidGlutenStatus => const [
        'gluten_free',
        'contains_gluten',
        'may_contain_gluten',
        'unknown',
      ].contains(iproductGlutenStatus);

  @override
  String toString() {
    return 'IProduct(id: $idIproduct, name: $iproductName, brand: $iproductBrand, price: $formattedPrice)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IProduct &&
        other.idIproduct == idIproduct &&
        other.iproductBarcode == iproductBarcode;
  }

  @override
  int get hashCode => Object.hash(idIproduct, iproductBarcode);
}

// Helper functions for list operations
List<IProduct> parseIProducts(List<dynamic> jsonList) {
  return jsonList
      .map((json) => IProduct.fromJson(json as Map<String, dynamic>))
      .toList();
}

List<Map<String, dynamic>> iProductsToJson(List<IProduct> products) {
  return products.map((product) => product.toJson()).toList();
}

// Extension for list utilities
extension IProductListExtensions on List<IProduct> {
  List<IProduct> get glutenFreeProducts {
    return where((product) => product.isGlutenFree).toList();
  }

  List<IProduct> get productsWithGluten {
    return where((product) => product.containsGluten).toList();
  }

  List<IProduct> searchByName(String query) {
    if (query.isEmpty) return this;
    final lowerQuery = query.toLowerCase();
    return where((product) =>
        product.iproductName.toLowerCase().contains(lowerQuery) ||
        product.iproductBrand.toLowerCase().contains(lowerQuery)).toList();
  }

  List<IProduct> sortByPrice({bool ascending = true}) {
    return [...this]..sort((a, b) {
        final comparison =
            a.iproductEstimatedPriceDA.compareTo(b.iproductEstimatedPriceDA);
        return ascending ? comparison : -comparison;
      });
  }

  List<IProduct> sortByName({bool ascending = true}) {
    return [...this]..sort((a, b) {
        final comparison = a.iproductName.compareTo(b.iproductName);
        return ascending ? comparison : -comparison;
      });
  }
}
