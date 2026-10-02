// lib/business/Product.dart

import 'dart:developer';

import 'package:verdelia_core/app/VerdeliaImage.dart';
import 'package:verdelia_core/business/iProduct.dart';

/// A single product as returned by the API.
///
/// The model carries the fields the payload actually contains. Helper
/// coercers (`_asInt`, `_asDouble`, `_asString`) tolerate the shapes the
/// backend occasionally emits (numeric strings, `1.0` for `1`, null for
/// absent values) so parsing never throws.
class Product {
  // ==================== Identity ====================

  final int? id_product;
  final int? product_provider_id;
  final int? product_category_id;
  final int? id_product_category;
  final int? id_product_image;
  final int? product_ref_id;
  final int? product_owner_id;
  final int? product_origin_id;

  // ==================== Descriptive ====================

  /// Raw flat name from the payload. The public [product_name] getter
  /// composes from this and the nested naming contribution.
  final String? product_nameRaw;

  final String? product_brand;
  final String? product_barcode;
  final String? product_quantifier;
  final String? product_description;
  final String? product_category_name;

  // ==================== Pricing & stock ====================

  final double? product_price;
  final double? product_base_price;
  final int? product_quantity;
  final int? product_reserved_quantity;

  // ==================== Status ====================

  final String? product_visibility;

  // ==================== Timestamps ====================

  final DateTime? product_created_at;
  final DateTime? product_last_updated;

  // ==================== Media ====================

  String? product_image_url;
  VerdeliaImage? productImage;

  // ==================== Nested snapshots ====================

  final Map<String, dynamic>? product_category;
  final Map<String, dynamic>? product_provider;

  /// Linked imported product, when the backend includes it.
  ///
  /// Carries the trilingual naming contribution and the AI-provenance
  /// metadata that the flat Product row doesn't have. Null for
  /// products without an origin.
  final IProduct? product_origin;

  // ==================== Constructor ====================

  Product({
    required this.id_product,
    required this.product_provider_id,
    required this.product_category_id,
    required this.id_product_category,
    required this.id_product_image,
    required this.product_ref_id,
    required this.product_nameRaw,
    required this.product_brand,
    required this.product_quantifier,
    required this.product_barcode,
    required this.product_category_name,
    required this.product_image_url,
    required this.product_price,
    required this.product_quantity,
    required this.product_description,
    required this.product_created_at,
    required this.product_last_updated,
    required this.product_owner_id,
    this.product_base_price,
    this.product_reserved_quantity,
    this.product_visibility,
    this.product_origin_id,
    this.product_category,
    this.product_provider,
    this.product_origin,
  });

  // ==================== Name access ====================

  /// Customer-facing name. Always English unless the caller opts into
  /// another language via [nameFor] or [preferredNameLanguage].
  String get product_name => _resolveName(_nameLanguage);

  String get productNameEn => _resolveName('en');
  String get productNameAr => _resolveName('ar');
  String get productNameFr => _resolveName('fr');

  /// Resolve the name in a specific language without mutating state.
  String nameFor(String lang) => _resolveName(lang);

  String _nameLanguage = 'en';

  set preferredNameLanguage(String lang) {
    _nameLanguage = lang;
  }

  /// Resolve a name for a given language, falling back in order:
  /// requested language → English → Arabic → French → flat field → ''.
  ///
  /// Delegates the trilingual fallback to [NamingContribution.nameFor]
  /// so the fallback policy lives in one place. When there's no naming
  /// contribution at all, uses the flat `product_nameRaw` field.
  String _resolveName(String lang) {
    final naming = product_origin?.namingContribution;
    if (naming != null) {
      final resolved = naming.nameFor(lang);
      if (resolved.isNotEmpty) return resolved;
    }
    return (product_nameRaw ?? '').trim();
  }

  // ==================== Factories ====================

  factory Product.empty() {
    return Product(
      id_product: null,
      product_provider_id: null,
      product_category_id: null,
      id_product_category: null,
      id_product_image: null,
      product_ref_id: null,
      product_nameRaw: '',
      product_brand: '',
      product_quantifier: '',
      product_barcode: '',
      product_category_name: '',
      product_image_url: null,
      product_price: 0.0,
      product_quantity: 0,
      product_description: '',
      product_created_at: null,
      product_last_updated: null,
      product_owner_id: null,
      product_base_price: 0.0,
      product_reserved_quantity: 0,
      product_visibility: 'VISIBLE',
      product_origin_id: null,
      product_category: null,
      product_provider: null,
      product_origin: null,
    );
  }

  factory Product.fromJson(dynamic json) {
    final map = _asMap(json);
    if (map.isEmpty) return Product.empty();

    final image = _parseLastImage(map['product_image']);
    final categoryMap = _asMapOrNull(map['product_category']);
    final providerMap = _asMapOrNull(map['product_provider']);
    final originMap = _asMapOrNull(map['product_origin']);

    final categoryName = _asString(categoryMap?['product_category_name']) ??
        _asString(map['product_category_name']) ??
        'Missing';

    final providerId = _asIntOrNull(map['product_provider_id']) ??
        _asIntOrNull(providerMap?['id_product_provider']) ??
        0;

    return Product(
      id_product: _asIntOrNull(map['id_product']),
      product_provider_id: providerId,
      product_category_id: _asIntOrNull(map['product_category_id']),
      id_product_category: _asIntOrNull(map['product_category_id']),
      id_product_image: image.id,
      product_ref_id: _asIntOrNull(map['product_ref_id']),
      product_nameRaw: _asString(map['product_name']) ?? '',
      product_brand: _asString(map['product_brand']) ?? '',
      product_barcode: _asString(map['product_barcode']) ?? '',
      product_quantifier: _asString(map['product_quantifier']) ?? '',
      product_category_name: categoryName,
      product_image_url: image.url ?? '',
      product_price: _asDoubleOrNull(map['product_price']),
      product_quantity: _asIntOrNull(map['product_quantity']),
      product_description: _asString(map['product_description']) ?? '',
      product_created_at: _parseDate(map['created']),
      product_last_updated: _parseDate(map['last_updated']),
      product_owner_id: _asIntOrNull(map['product_owner']),
      product_base_price: _asDoubleOrNull(map['product_base_price']),
      product_reserved_quantity: _asIntOrNull(map['product_reserved_quantity']),
      product_visibility: _asString(map['product_visibility']) ?? 'VISIBLE',
      product_origin_id: _asIntOrNull(map['product_origin_id']),
      product_category: categoryMap,
      product_provider: providerMap,
      // Parse the origin once, typed. `IProduct.fromJson` is already the
      // canonical parser for that shape.
      product_origin: originMap == null ? null : IProduct.fromJson(originMap),
    );
  }

  factory Product.fromSearchJson(dynamic json) {
    if (json == null) return Product.empty();
    return Product.fromJson(json);
  }

  // ==================== copyWith ====================

  Product copyWith({
    int? id_product,
    int? product_provider_id,
    int? product_category_id,
    int? id_product_category,
    int? id_product_image,
    int? product_ref_id,
    int? product_owner_id,
    int? product_origin_id,
    String? product_nameRaw,
    String? product_brand,
    String? product_barcode,
    String? product_quantifier,
    String? product_description,
    String? product_category_name,
    String? product_image_url,
    double? product_price,
    double? product_base_price,
    int? product_quantity,
    int? product_reserved_quantity,
    String? product_visibility,
    DateTime? product_created_at,
    DateTime? product_last_updated,
    Map<String, dynamic>? product_category,
    Map<String, dynamic>? product_provider,
    IProduct? product_origin,
  }) {
    return Product(
      id_product: id_product ?? this.id_product,
      product_provider_id: product_provider_id ?? this.product_provider_id,
      product_category_id: product_category_id ?? this.product_category_id,
      id_product_category: id_product_category ?? this.id_product_category,
      id_product_image: id_product_image ?? this.id_product_image,
      product_ref_id: product_ref_id ?? this.product_ref_id,
      product_owner_id: product_owner_id ?? this.product_owner_id,
      product_origin_id: product_origin_id ?? this.product_origin_id,
      product_nameRaw: product_nameRaw ?? this.product_nameRaw,
      product_brand: product_brand ?? this.product_brand,
      product_barcode: product_barcode ?? this.product_barcode,
      product_quantifier: product_quantifier ?? this.product_quantifier,
      product_description: product_description ?? this.product_description,
      product_category_name:
          product_category_name ?? this.product_category_name,
      product_image_url: product_image_url ?? this.product_image_url,
      product_price: product_price ?? this.product_price,
      product_base_price: product_base_price ?? this.product_base_price,
      product_quantity: product_quantity ?? this.product_quantity,
      product_reserved_quantity:
          product_reserved_quantity ?? this.product_reserved_quantity,
      product_visibility: product_visibility ?? this.product_visibility,
      product_created_at: product_created_at ?? this.product_created_at,
      product_last_updated: product_last_updated ?? this.product_last_updated,
      product_category: product_category ?? this.product_category,
      product_provider: product_provider ?? this.product_provider,
      product_origin: product_origin ?? this.product_origin,
    );
  }

  // ==================== Serialisation ====================

  Map<String, dynamic> toJson() {
    final originJson = product_origin?.toJson();
    return {
      'product': {
        'id_product': id_product ?? 0,
        'product_provider_id': product_provider_id ?? 0,
        'product_category_id': product_category_id ?? 0,
        'id_product_category': product_category_id ?? 0,
        'id_product_image': id_product_image ?? 0,
        // Write the raw flat name, not the resolved one. Writing the
        // resolved name would overwrite `naming.en` with a translated
        // string on the server whenever the caller set a preferred
        // language. The write path sends the seller's canonical name.
        'product_name': product_nameRaw ?? '',
        'product_brand': product_brand ?? '',
        'product_barcode': product_barcode ?? '',
        'product_quantifier': product_quantifier ?? '',
        'product_category_desc': product_category_name ?? '',
        'product_price': product_price ?? 0,
        'product_base_price': product_base_price ?? 0,
        'product_quantity': product_quantity ?? 0,
        'product_reserved_quantity': product_reserved_quantity ?? 0,
        'product_visibility': product_visibility ?? 'VISIBLE',
        'product_description': product_description ?? '',
        'product_owner': product_owner_id ?? 0,
        if (product_origin_id != null) 'product_origin_id': product_origin_id,
      },
      'image': {
        'id_product_image': id_product_image ?? 0,
        'product_image_url': product_image_url ?? '',
        'product_ref_id': product_ref_id ?? 0,
      },
      // Only include the origin when it exists. An empty origin on a
      // create would be noise; on an update it would strip the link.
      if (originJson != null) 'product_origin': originJson,
    };
  }

  // ==================== Convenience getters ====================

  int get product_available_quantity {
    final total = product_quantity ?? 0;
    final reserved = product_reserved_quantity ?? 0;
    return (total - reserved).clamp(0, total);
  }

  bool get isVisible =>
      (product_visibility ?? 'VISIBLE').toUpperCase() == 'VISIBLE';

  bool get isInStock => product_available_quantity > 0;

  double? get unitMargin {
    final base = product_base_price ?? 0;
    if (base <= 0) return null;
    return (product_price ?? 0) - base;
  }

  double? get unitMarginPercent {
    final base = product_base_price ?? 0;
    if (base <= 0) return null;
    return ((product_price ?? 0) - base) / base;
  }

  // ==================== Equality ====================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id_product == id_product;
  }

  @override
  int get hashCode => id_product.hashCode;

  @override
  String toString() =>
      'Product(id: $id_product, name: $product_name, price: $product_price)';
}

// ==================== Parse helpers ====================

double? _asDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

int? _asIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is num) return v.toInt();
  if (v is String) {
    final asInt = int.tryParse(v);
    if (asInt != null) return asInt;
    return double.tryParse(v)?.toInt();
  }
  return null;
}

String? _asString(dynamic v) {
  if (v == null) return null;
  if (v is String) return v;
  return v.toString();
}

Map<String, dynamic> _asMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  return const {};
}

Map<String, dynamic>? _asMapOrNull(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  return null;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is int) {
    final ms = v > 1000000000000 ? v : v * 1000;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }
  if (v is String) {
    if (v.isEmpty) return null;
    try {
      return DateTime.parse(v);
    } catch (_) {
      return null;
    }
  }
  return null;
}

/// Extract the id and url of the last entry in a `product_image` list.
/// Returns zero/null when the list is missing or malformed.
({int id, String? url}) _parseLastImage(dynamic raw) {
  if (raw is! List || raw.isEmpty) return (id: 0, url: null);
  final last = raw.last;
  if (last is! Map) return (id: 0, url: null);
  final map = Map<String, dynamic>.from(last);
  return (
    id: _asIntOrNull(map['id_product_image']) ?? 0,
    url: _asString(map['product_image_url']),
  );
}

// ==================== ProductCategory ====================

class ProductCategory {
  final int product_provider_type_id;
  final String product_category_desc;

  const ProductCategory({
    required this.product_provider_type_id,
    required this.product_category_desc,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      product_provider_type_id: _asIntOrNull(json['id_product_category']) ?? 0,
      product_category_desc: _asString(json['product_category_desc']) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id_product_provider_type': product_provider_type_id,
        'product_provider_type_desc': product_category_desc,
      };
}
