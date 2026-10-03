// lib/business/Product.dart

import 'dart:developer';

import '../app/VerdeliaImage.dart';
import 'NamingContribution.dart';
import 'iProduct.dart';

/// A single product as returned by the API.
///
/// The model carries the fields the payload actually contains. Helper
/// coercers (`_asInt`, `_asDouble`, `_asString`) tolerate the shapes the
/// backend occasionally emits (numeric strings, `1.0` for `1`, null for
/// absent values) so parsing never throws.

/// One row of `product_image` as it arrives in a product payload.
///
/// Separate from [VerdeliaImage]: that class is the *upload* side
/// (local file → multipart). This is the *read* side (JSON row →
/// typed value), so a gallery can be iterated without re-parsing the
/// raw map at every call site.
class ProductImage {
  final int id;
  final String? url;
  final int? productRefId;

  const ProductImage({
    required this.id,
    required this.url,
    this.productRefId,
  });

  static const empty = ProductImage(id: 0, url: null);

  bool get hasUrl => url != null && url!.isNotEmpty;

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: _asIntOrNull(json['id_product_image']) ?? 0,
      url: _asString(json['product_image_url']),
      productRefId: _asIntOrNull(json['product_ref_id']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id_product_image': id,
        'product_image_url': url ?? '',
        if (productRefId != null) 'product_ref_id': productRefId,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductImage &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id;

  @override
  String toString() => 'ProductImage(id: $id, url: $url)';
}

class Product {
  // ==================== Identity ====================

  final int? id_product;
  final int? product_provider_id;
  final int? product_category_id;
  final int? id_product_category;
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

  VerdeliaImage? productImage;

  /// Full gallery, in payload order. Empty when the payload has no
  /// images. This is the single source of truth for the product's
  /// image URLs — order it, index it, take the first, whatever the
  /// caller needs.
  final List<ProductImage> product_images;

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
    required this.product_ref_id,
    required this.product_nameRaw,
    required this.product_brand,
    required this.product_quantifier,
    required this.product_barcode,
    required this.product_category_name,
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
    this.product_images = const [],
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

  // ==================== Image access ====================

  /// First image, or null when the gallery is empty.
  ProductImage? get primaryImage =>
      product_images.isNotEmpty ? product_images.first : null;

  /// Convenience: URL of the first image, or null when there is none.
  /// Replaces the old flat `product_image_url` field.
  String? get primaryImageUrl => primaryImage?.url;

  /// True when there is more than one image.
  bool get hasGallery => product_images.length > 1;

  /// Every usable URL, in payload order. Malformed entries are filtered
  /// out at parse time, so this is safe to hand straight to a
  /// `PageView` or a carousel.
  List<String> get imageUrls => product_images
      .where((img) => img.hasUrl)
      .map((img) => img.url!)
      .toList(growable: false);

  // ==================== Factories ====================

  factory Product.empty() {
    return Product(
      id_product: null,
      product_provider_id: null,
      product_category_id: null,
      id_product_category: null,
      product_ref_id: null,
      product_nameRaw: '',
      product_brand: '',
      product_quantifier: '',
      product_barcode: '',
      product_category_name: '',
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
      product_images: const [],
    );
  }

  factory Product.fromJson(dynamic json) {
    final map = _asMap(json);
    if (map.isEmpty) return Product.empty();

    // Seller gallery first.
    final sellerImages = _parseProductImages(map['product_image']);

    final categoryMap = _asMapOrNull(map['product_category']);
    final providerMap = _asMapOrNull(map['product_provider']);
    final originMap = _asMapOrNull(map['product_origin']);

    // Parse the origin once — we need its image URL for the gallery.
    final origin = originMap == null ? null : IProduct.fromJson(originMap);

    // Compose the final gallery: the origin's reference image (if any)
    // goes first, followed by the seller's own images.
    //
    // Deduplicate so the same URL isn't shown twice when the seller
    // happened to attach the reference image alongside their own.
    final images = _composeGallery(
      originImageUrl: origin?.iproductImageUrl,
      sellerImages: sellerImages,
    );

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
      product_ref_id: _asIntOrNull(map['product_ref_id']),
      product_nameRaw: _asString(map['product_name']) ?? '',
      product_brand: _asString(map['product_brand']) ?? '',
      product_barcode: _asString(map['product_barcode']) ?? '',
      product_quantifier: _asString(map['product_quantifier']) ?? '',
      product_category_name: categoryName,
      product_images: images,
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
      product_origin: origin,
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
    int? product_ref_id,
    int? product_owner_id,
    int? product_origin_id,
    String? product_nameRaw,
    String? product_brand,
    String? product_barcode,
    String? product_quantifier,
    String? product_description,
    String? product_category_name,
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
    List<ProductImage>? product_images,
  }) {
    return Product(
      id_product: id_product ?? this.id_product,
      product_provider_id: product_provider_id ?? this.product_provider_id,
      product_category_id: product_category_id ?? this.product_category_id,
      id_product_category: id_product_category ?? this.id_product_category,
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
      product_images: product_images ?? this.product_images,
    );
  }

  // ==================== Serialisation ====================

  Map<String, dynamic> toJson() {
    final originJson = product_origin?.toJson();

    // The write path sends ONE image per call. The server owns the rest
    // of the gallery; it's only told about the specific row that
    // changed — either a new upload (id 0) or an in-place update of an
    // existing row.
    //
    // Selection rule:
    //   1. Any entry with `id == 0` → a freshly-uploaded image that
    //      hasn't been persisted yet. Send it.
    //   2. Otherwise → the first gallery entry (the primary image).
    //      Sending it unchanged is a harmless no-op on the server.
    //
    // This keeps the client-side gallery complete for rendering while
    // respecting the API's single-image-per-write contract.
    final newImage = product_images
        .cast<ProductImage?>()
        .firstWhere((img) => img?.id == 0, orElse: () => null);

    final imageToSend = newImage ?? primaryImage;

    final imageJson = imageToSend == null
        ? null
        : {
            'id_product_image': imageToSend.id,
            'product_image_url': imageToSend.url ?? '',
            'product_ref_id': imageToSend.productRefId ?? id_product ?? 0,
          };

    return {
      'product': {
        'id_product': id_product ?? 0,
        'product_provider_id': product_provider_id ?? 0,
        'product_category_id': product_category_id ?? 0,
        'id_product_category': product_category_id ?? 0,
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
      if (imageJson != null) 'image': imageJson,
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

/// Parse every entry in a `product_image` list. Malformed entries are
/// skipped rather than aborting the whole list.
List<ProductImage> _parseProductImages(dynamic raw) {
  if (raw is! List) return const [];
  final out = <ProductImage>[];
  for (final entry in raw) {
    if (entry is! Map) continue;
    final map = Map<String, dynamic>.from(entry);
    final id = _asIntOrNull(map['id_product_image']) ?? 0;
    final url = _asString(map['product_image_url']);
    if (id == 0 && (url == null || url.isEmpty)) continue;
    out.add(ProductImage(
      id: id,
      url: url,
      productRefId: _asIntOrNull(map['product_ref_id']),
    ));
  }
  return List.unmodifiable(out);
}

/// Compose the final gallery from the origin's reference image plus
/// the seller's own images.
///
/// The origin's image — when present — is always first, so the
/// product's primary image is the reference image rather than whatever
/// the seller attached. Duplicates (same URL) are collapsed, keeping
/// the origin's entry and dropping the matching seller entry.
///
/// The origin image is given a synthetic id of 0 so it never gets
/// confused with a real `product_image` row on the write path.
List<ProductImage> _composeGallery({
  required String? originImageUrl,
  required List<ProductImage> sellerImages,
}) {
  final out = <ProductImage>[];
  final seen = <String>{};

  // 1. Origin reference image first.
  final originUrl = _cleanUrlForGallery(originImageUrl);
  if (originUrl != null) {
    out.add(ProductImage(id: 0, url: originUrl));
    seen.add(originUrl);
  }

  // 2. Seller images, skipping any whose URL already appears.
  for (final img in sellerImages) {
    final url = _cleanUrlForGallery(img.url);
    if (url == null) continue;
    if (seen.contains(url)) continue;

    out.add(ProductImage(
      id: img.id,
      url: url,
      productRefId: img.productRefId,
    ));
    seen.add(url);
  }

  return List.unmodifiable(out);
}

/// Trim + drop placeholder strings. Kept local because the model
/// doesn't resolve URLs to full http(s) form — that's the
/// presentation layer's job. This only guards against empty / literal
/// "null" values reaching the gallery.
String? _cleanUrlForGallery(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final lower = trimmed.toLowerCase();
  if (lower == 'null' ||
      lower == 'undefined' ||
      lower == 'none' ||
      lower == '-' ||
      lower == 'n/a') {
    return null;
  }
  return trimmed;
}

// ==================== ProductCategory ====================

class ProductCategory {
  /// FK to `product_category.id_product_category`.
  final int productCategoryId;

  /// Flat English label from `product_category_name`.
  /// Kept for backward compatibility — prefer [nameFor] or [naming].
  final String productCategoryDesc;

  /// FK to the trilingual naming contribution row, when exposed
  /// directly on the category (nullable in the payload).
  final int? productCategoryNamingRef;

  /// Icon URL from `product_category_icon` (nullable in your JSON).
  final String? iconUrl;

  /// Trilingual naming block (fr / ar / en + status + icon).
  /// Null when the backend returned only the flat shape.
  final NamingContribution? naming;

  const ProductCategory({
    required this.productCategoryId,
    required this.productCategoryDesc,
    this.productCategoryNamingRef,
    this.iconUrl,
    this.naming,
  });

  factory ProductCategory.empty() => const ProductCategory(
        productCategoryId: 0,
        productCategoryDesc: '',
      );

  ProductCategory copyWith({
    int? productCategoryId,
    String? productCategoryDesc,
    int? productCategoryNamingRef,
    String? iconUrl,
    NamingContribution? naming,
  }) {
    return ProductCategory(
      productCategoryId: productCategoryId ?? this.productCategoryId,
      productCategoryDesc: productCategoryDesc ?? this.productCategoryDesc,
      productCategoryNamingRef:
          productCategoryNamingRef ?? this.productCategoryNamingRef,
      iconUrl: iconUrl ?? this.iconUrl,
      naming: naming ?? this.naming,
    );
  }

  /// Parse a single category row. Supports both shapes:
  ///
  /// New shape (as returned by the product-category endpoint):
  /// ```json
  /// {
  ///   "id_product_category": 10,
  ///   "product_category_name": "Canned & Packaged Goods",
  ///   "product_category_naming_ref": 10,
  ///   "product_category_icon": null,
  ///   "naming_contribution": {
  ///     "naming_contribution_fr": "Conserves et produits emballés",
  ///     "naming_contribution_ar": "المعلبات والأغذية المعبأة",
  ///     "naming_contribution_en": "Canned & Packaged Goods",
  ///     "naming_contribution_status": "APP_TRANSLATED",
  ///     "naming_contribution_icon_url": null
  ///   }
  /// }
  /// ```
  ///
  /// Legacy shape:
  /// ```json
  /// {
  ///   "id_product_category": 10,
  ///   "product_category_desc": "Canned & Packaged Goods"
  /// }
  /// ```
  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    try {
      final id = _asInt(
          json['id_product_category'] ?? json['id_product_provider_type']);

      // Name fallback chain: new name field → old desc field → "".
      final flatName = _asString(
        json['product_category_name'] ?? json['product_category_desc'],
      );

      final namingRef = _asIntOrNull(
        json['product_category_naming_ref'],
      );

      final icon = _asString(json['product_category_icon']);

      NamingContribution? naming;
      final namingJson = json['naming_contribution'];
      if (namingJson != null && namingJson is Map<String, dynamic>) {
        naming = NamingContribution.fromJson(namingJson);
      }

      return ProductCategory(
        productCategoryId: id,
        productCategoryDesc: flatName,
        productCategoryNamingRef: namingRef,
        iconUrl: icon.isNotEmpty ? icon : null,
        naming: naming,
      );
    } catch (_) {
      return ProductCategory.empty();
    }
  }

  /// Parse a full list returned by the product-category endpoint.
  static List<ProductCategory> listFromJson(dynamic json) {
    if (json is! List) return const [];
    return json
        .whereType<Map<String, dynamic>>()
        .map(ProductCategory.fromJson)
        .toList(growable: false);
  }

  Map<String, dynamic> toJson() => {
        'id_product_category': productCategoryId,
        'product_category_name': productCategoryDesc,
        if (productCategoryNamingRef != null)
          'product_category_naming_ref': productCategoryNamingRef,
        if (iconUrl != null) 'product_category_icon': iconUrl,
        if (naming != null) 'naming_contribution': naming!.toJson(),
      };

  // ==================== Naming accessors ====================

  /// Return the category name in [lang]. Prefers the trilingual
  /// naming contribution; falls back to [productCategoryDesc].
  ///
  /// [lang] accepts the usual BCP-47 short codes: `'en'`, `'fr'`, `'ar'`.
  String nameFor(String lang) {
    final resolved = naming?.nameFor(lang) ?? '';
    if (resolved.isNotEmpty) return resolved;
    return productCategoryDesc;
  }

  /// Icon URL preferring the naming block, falling back to the flat
  /// top-level icon.
  String? get resolvedIconUrl {
    final fromNaming = naming?.iconUrl;
    if (fromNaming != null && fromNaming.isNotEmpty) return fromNaming;
    return iconUrl;
  }

  /// English-preferring display name. Kept for backward compatibility.
  String get displayName {
    if (naming?.en.isNotEmpty == true) return naming!.en;
    return productCategoryDesc;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductCategory &&
          runtimeType == other.runtimeType &&
          productCategoryId == other.productCategoryId;

  @override
  int get hashCode => productCategoryId;

  @override
  String toString() =>
      'ProductCategory(id: $productCategoryId, name: $productCategoryDesc, '
      'naming: ${naming != null})';

  // ==================== Helpers ====================

  static int _asInt(dynamic value) => _asIntOrNull(value) ?? 0;

  static int? _asIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String _asString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    return value.toString().trim();
  }
}
