// lib/business/iProduct.dart

import 'package:decimal/decimal.dart';

import 'NamingContribution.dart';

/// One row from the `iproduct` table — an imported / AI-enriched product.
///
/// ## Read shape (from the operations response, `product.origin`)
///
/// ```json
/// {
///   "info_source": "csv_import",
///   "category_id": null,
///   "id_iproduct": 22,
///   "last_price_update": "2026-10-23T13:56:31",
///   "created_at": "2026-10-23T13:56:31",
///   "last_update": "2026-10-23T13:56:31",
///   "brand": "BrandC",
///   "model_name": "None",
///   "estimated_price": 75.07,
///   "image_url": "",
///   "price_currency": "DZD",
///   "naming_id": 509,
///   "barcode": "8541952005253",
///   "info_confidence": 0.89,
///   "generic_name": "Splint 9b2f",
///   "naming": { ...NamingContribution... }
/// }
/// ```
///
/// The read shape uses **flat, unprefixed** names. The write model
/// (`Iproduct_API`) uses the same flat names minus the server-owned
/// columns (`id_iproduct`, `created_at`, `last_update`, `naming_id`).
///
/// ## Money
///
/// [iproductEstimatedPriceDA] is [Decimal] (it's the AI-estimated price
/// of the imported product — a real amount, multiplied by quantity in
/// downstream pricing). [iproductInfoConfidence] is a `[0, 1]` score,
/// kept as [Decimal] because the threshold comparison (`>= 0.75`) and
/// future arithmetic benefit from exactness. The `double` conversion
/// happens only inside the serialisation methods, at the JSON boundary.
class IProduct {
  final int? idIproduct;
  final String iproductBarcode;
  final String iproductName;
  final String iproductBrand;

  /// AI-estimated price, in [Decimal].
  final Decimal iproductEstimatedPriceDA;

  final String iproductPriceCurrency;
  final String iproductGlutenStatus;
  final String iproductInfoSource;

  /// Confidence score in `[0, 1]`, in [Decimal].
  final Decimal iproductInfoConfidence;

  final DateTime? iproductLastPriceUpdate;
  final String? iproductImageUrl;
  final DateTime iproductCreatedAt;
  final DateTime iproductUpdatedAt;
  final String iproductModelName;

  final int? iproductNamingRef;
  final int? iproductCategoryId;

  final NamingContribution? namingContribution;

  /// Parses a price from a JSON value.
  ///
  /// * [Decimal] → passthrough
  /// * `int`     → `Decimal.fromInt`
  /// * `double`  → `Decimal.tryParse(v.toString())` (shortest round-trip)
  /// * `String`  → strip non-numeric characters (keep `.` and digits,
  ///                convert `,` to `.`), then `Decimal.tryParse`
  /// * otherwise → `Decimal.zero`
  static Decimal _parsePrice(dynamic priceData) {
    if (priceData == null) return Decimal.zero;
    if (priceData is Decimal) return priceData;
    if (priceData is int) return Decimal.fromInt(priceData);
    if (priceData is double) {
      if (priceData.isNaN || priceData.isInfinite) return Decimal.zero;
      return Decimal.tryParse(priceData.toString()) ?? Decimal.zero;
    }
    if (priceData is String) {
      final cleaned =
          priceData.replaceAll(RegExp(r'[^\d.,]'), '').replaceAll(',', '.');
      return Decimal.tryParse(cleaned) ?? Decimal.zero;
    }
    return Decimal.zero;
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
    Decimal? iproductInfoConfidence,
    this.iproductLastPriceUpdate,
    this.iproductImageUrl,
    required this.iproductCreatedAt,
    required this.iproductUpdatedAt,
    required this.iproductModelName,
    this.iproductNamingRef,
    this.iproductCategoryId,
    this.namingContribution,
  }) : iproductInfoConfidence = iproductInfoConfidence ?? Decimal.zero;

  factory IProduct.empty() {
    final now = DateTime.now();
    return IProduct(
      idIproduct: null,
      iproductBarcode: '',
      iproductName: '',
      iproductBrand: '',
      iproductEstimatedPriceDA: Decimal.zero,
      iproductPriceCurrency: 'DZD',
      iproductGlutenStatus: 'unknown',
      iproductInfoSource: 'manual',
      iproductInfoConfidence: Decimal.zero,
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

  static String _validateGlutenStatus(String status) {
    const validStatuses = [
      'gluten_free',
      'contains_gluten',
      'may_contain_gluten',
      'unknown',
    ];

    final lowerStatus = status.toLowerCase().trim();
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

    if (validStatuses.contains(lowerStatus)) return lowerStatus;
    if (statusMap.containsKey(lowerStatus)) return statusMap[lowerStatus]!;
    for (final validStatus in validStatuses) {
      if (lowerStatus.contains(validStatus)) return validStatus;
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
        iproductInfoConfidence: Decimal.zero,
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
    final name = _extractName(json);
    final brand = _extractBrand(json, name);
    final price = _extractPrice(json);
    final glutenStatus = _extractGlutenStatus(json);
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
    if (name != null && name.isNotEmpty && name != 'Unknown') return name;

    final productName = json['product_name']?.toString();
    if (productName != null && productName.isNotEmpty) return productName;

    return 'Unknown Product';
  }

  static String _extractBrand(Map<String, dynamic> json, String productName) {
    final brand = json['brand']?.toString();
    if (brand != null && brand.isNotEmpty && brand != 'Unknown') return brand;

    if (productName.contains(' ')) {
      final words = productName.split(' ');
      if (words.length > 1) return words.first;
    }
    return 'Unknown Brand';
  }

  static Decimal _extractPrice(Map<String, dynamic> json) {
    const priceFields = [
      'estimated_price_DA',
      'price_da',
      'price',
      'estimated_price',
    ];
    for (final field in priceFields) {
      final value = json[field];
      if (value != null) {
        final parsed = _parsePrice(value);
        if (parsed > Decimal.zero) return parsed;
      }
    }
    return Decimal.zero;
  }

  static String _extractGlutenStatus(Map<String, dynamic> json) {
    const glutenFields = [
      'gluten_status',
      'gluten_tolerability',
      'gluten',
      'gluten_content',
    ];
    for (final field in glutenFields) {
      final value = json[field]?.toString();
      if (value != null && value.isNotEmpty) {
        final validated = _validateGlutenStatus(value);
        if (validated != 'unknown') return validated;
      }
    }
    return 'unknown';
  }

  /// Parse an iproduct from **either** the read shape (flat
  /// `generic_name`, `brand`, `estimated_price`, ...) or the write
  /// shape (`Iproduct_API`, same flat names minus server-owned
  /// columns). The read shape wins when both are present.
  factory IProduct.fromJson(Map<String, dynamic> json) {
    String readString(List<String> keys, {String fallback = ''}) {
      for (final key in keys) {
        final value = json[key];
        if (value is String && value.isNotEmpty) return value;
        if (value != null) return value.toString();
      }
      return fallback;
    }

    Decimal readDecimal(List<String> keys, {Decimal? fallback}) {
      for (final key in keys) {
        final parsed = _readDecimal(json[key]);
        if (parsed != null) return parsed;
      }
      return fallback ?? Decimal.zero;
    }

    int? readIntOrNull(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value is int) return value;
        if (value is num) return value.toInt();
        if (value is String && value.isNotEmpty) {
          final parsed = int.tryParse(value);
          if (parsed != null) return parsed;
        }
      }
      return null;
    }

    DateTime? readDate(List<String> keys, {bool required = false}) {
      for (final key in keys) {
        final value = json[key];
        if (value == null) continue;
        if (value is String && value.isNotEmpty) {
          final parsed = DateTime.tryParse(value);
          if (parsed != null) return parsed;
        }
        if (value is DateTime) return value;
      }
      return required ? DateTime.fromMillisecondsSinceEpoch(0) : null;
    }

    // Nested naming block: read-side uses `naming`; write-side uses
    // `naming` too (both are the same shape from NamingContribution_API).
    NamingContribution? naming;
    final rawNaming = json['naming'] ?? json['naming_contribution'];
    if (rawNaming is Map) {
      try {
        naming = NamingContribution.fromJson(
          Map<String, dynamic>.from(rawNaming),
        );
      } catch (_) {}
    }

    return IProduct(
      idIproduct: readIntOrNull(const [
        'id_iproduct',
        'iproduct_id',
        'id',
      ]),

      // Read-side name is `generic_name`; write-side name is
      // `generic_name` too. The prefixed form is a legacy fallback.
      iproductName: readString(
        const ['generic_name', 'iproduct_name', 'product_name', 'name'],
      ),

      iproductBarcode: readString(
        const ['barcode', 'iproduct_barcode'],
      ),

      iproductBrand: readString(
        const ['brand', 'iproduct_brand'],
      ),

      // Read-side name is `estimated_price`; write-side name is
      // `estimated_price`. The `_DA` suffix is a legacy fallback.
      iproductEstimatedPriceDA: readDecimal(
        const [
          'estimated_price',
          'iproduct_estimated_price_DA',
          'iproduct_estimated_price',
        ],
      ),

      iproductPriceCurrency: readString(
        const ['price_currency', 'iproduct_price_currency'],
        fallback: 'DZD',
      ),

      // `gluten_status` is not on the iproduct row in the DB. Some
      // older payloads emit it under `gluten_status`; use it when
      // present, else fall back to `unknown`.
      iproductGlutenStatus: readString(
        const ['gluten_status', 'iproduct_gluten_status'],
        fallback: 'unknown',
      ),

      iproductInfoSource: readString(
        const ['info_source', 'iproduct_info_source'],
        fallback: 'openai',
      ),

      iproductModelName: readString(
        const ['model_name', 'iproduct_model_name'],
        fallback: 'None',
      ),

      iproductInfoConfidence: readDecimal(
        const ['info_confidence', 'iproduct_info_confidence'],
      ),

      iproductImageUrl: () {
        final url = readString(
          const ['image_url', 'iproduct_image_url'],
        );
        return url.isEmpty ? null : url;
      }(),

      iproductLastPriceUpdate: readDate(
        const ['last_price_update', 'iproduct_last_price_update'],
      ),

      // Read-side `created_at` / `last_update`; legacy prefixed forms
      // as fallbacks. `updated_at` is what the API write model calls
      // the timestamp, `last_update` is the ORM column, so accept both.
      iproductCreatedAt: readDate(
        const ['created_at', 'iproduct_created_at'],
        required: true,
      )!,

      iproductUpdatedAt: readDate(
            const [
              'last_update',
              'updated_at',
              'iproduct_updated_at',
              'iproduct_last_update',
            ],
          ) ??
          readDate(
            const ['created_at', 'iproduct_created_at'],
            required: true,
          )!,

      iproductNamingRef: readIntOrNull(
        const ['naming_id', 'iproduct_naming_ref'],
      ),

      iproductCategoryId: readIntOrNull(
        const ['category_id', 'iproduct_category_id'],
      ),

      namingContribution: naming,
    );
  }

  /// Serialises the iproduct for **local persistence**. Round-trips
  /// with [IProduct.fromJson] because both sides use the read-side
  /// field names (`generic_name`, `brand`, `estimated_price`, ...).
  ///
  /// Do **not** send this to the API. The write contract is
  /// [toIproductApiJson].
  ///
  /// Monetary values are emitted via [_decimalToWire] so the JSON
  /// number is the shortest round-trip form of the [Decimal].
  Map<String, dynamic> toJson() {
    return {
      if (idIproduct != null) 'id_iproduct': idIproduct,
      'generic_name': iproductName,
      'barcode': iproductBarcode,
      'brand': iproductBrand,
      'estimated_price': _decimalToWire(iproductEstimatedPriceDA),
      'price_currency': iproductPriceCurrency,
      'gluten_status': iproductGlutenStatus,
      'info_source': iproductInfoSource,
      'info_confidence': _decimalToWire(iproductInfoConfidence),
      if (iproductLastPriceUpdate != null)
        'last_price_update': iproductLastPriceUpdate!.toIso8601String(),
      'image_url': iproductImageUrl,
      'created_at': iproductCreatedAt.toIso8601String(),
      'last_update': iproductUpdatedAt.toIso8601String(),
      'model_name': iproductModelName,
      if (iproductNamingRef != null) 'naming_id': iproductNamingRef,
      if (iproductCategoryId != null) 'category_id': iproductCategoryId,
      if (namingContribution != null) 'naming': namingContribution!.toJson(),
    };
  }

  /// The writeable fields of `Iproduct_API`.
  ///
  /// Server-owned columns (`id_iproduct`, `created_at`, `last_update`,
  /// `naming_id`) are excluded. The naming block is included when the
  /// client has one — the server uses `naming.en` to create or reuse
  /// the NamingContribution row and copies it into `generic_name` for
  /// backward compatibility.
  Map<String, dynamic> toIproductApiJson() {
    return {
      'generic_name': iproductName,
      'barcode': iproductBarcode,
      'brand': iproductBrand,
      'estimated_price': _decimalToWire(iproductEstimatedPriceDA),
      'price_currency': iproductPriceCurrency,
      'info_source': iproductInfoSource,
      'info_confidence': _decimalToWire(iproductInfoConfidence),
      'model_name': iproductModelName,
      'image_url': iproductImageUrl ?? '',
      if (namingContribution != null) 'naming': namingContribution!.toJson(),
    };
  }

  IProduct copyWith({
    int? idIproduct,
    String? iproductBarcode,
    String? iproductName,
    String? iproductBrand,
    Decimal? iproductEstimatedPriceDA,
    String? iproductPriceCurrency,
    String? iproductGlutenStatus,
    String? iproductInfoSource,
    Decimal? iproductInfoConfidence,
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

  String nameFor(String lang) {
    final resolved = namingContribution?.nameFor(lang) ?? '';
    if (resolved.isNotEmpty) return resolved;
    return iproductName;
  }

  bool get isGlutenFree => iproductGlutenStatus == 'gluten_free';
  bool get containsGluten => iproductGlutenStatus == 'contains_gluten';
  bool get mayContainGluten => iproductGlutenStatus == 'may_contain_gluten';
  bool get hasUnknownGlutenStatus => iproductGlutenStatus == 'unknown';

  /// Confidence threshold — exactly `0.75`, in [Decimal].
  bool get isHighConfidence => iproductInfoConfidence >= Decimal.parse('0.75');

  bool get isAiSourced =>
      iproductInfoSource.isNotEmpty && iproductInfoSource != 'manual';

  String get formattedPrice =>
      '${iproductEstimatedPriceDA.toStringAsFixed(2)} $iproductPriceCurrency';

  bool get isPriceRecent {
    if (iproductLastPriceUpdate == null) return false;
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return iproductLastPriceUpdate!.isAfter(thirtyDaysAgo);
  }

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

// ============================================================================
// Decimal helpers
// ============================================================================

/// Coerces any JSON value to [Decimal].
///
/// * [Decimal] → passthrough
/// * `int`     → `Decimal.fromInt`
/// * `double`  → `Decimal.tryParse(v.toString())` (shortest round-trip,
///                NOT the binary expansion)
/// * `String`  → `Decimal.tryParse`
/// * anything else, or a non-finite `double` → `null`
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
// Top-level helpers
// ============================================================================

List<IProduct> parseIProducts(List<dynamic> jsonList) {
  return jsonList
      .whereType<Map>()
      .map((json) => IProduct.fromJson(Map<String, dynamic>.from(json)))
      .toList();
}

List<Map<String, dynamic>> iProductsToJson(List<IProduct> products) {
  return products.map((product) => product.toJson()).toList();
}

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
