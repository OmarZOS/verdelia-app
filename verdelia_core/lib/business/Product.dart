// lib/business/Product.dart

import 'dart:developer';

import 'package:decimal/decimal.dart';

import '../app/VerdeliaImage.dart';
import 'NamingContribution.dart';
import 'iProduct.dart';

/// A single product as returned by the API.
///
/// The model carries the fields the payload actually contains. Helper
/// coercers (`_asInt`, `_readDecimal`, `_asString`) tolerate the shapes
/// the backend occasionally emits (numeric strings, `1.0` for `1`, null
/// for absent values) so parsing never throws.
///
/// ## Money
///
/// [unit_price], [base_price], [vat_rate], [total_quantity] and
/// [reserved_quantity] are [Decimal]. [unitMargin] and
/// [unitMarginPercent] are [Decimal] getters. The `double` conversion
/// happens only inside [toJson], at the JSON boundary.

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

// ==================== Product ====================

class Product {
  // ── Identity ──────────────────────────────────────────────────
  final int? id_product;
  final int? product_provider_id;
  final int? product_category_id;
  final int? id_product_category;
  final int? product_ref_id;
  final int? product_owner_id;

  /// The importer row id (`iproduct.id_iproduct`). Null for
  /// seller-created products with no imported origin.
  final int? product_origin_id;

  // ── Descriptive ───────────────────────────────────────────────

  /// Flat English name from the payload's `generic_name` (or
  /// `product_name` on write). Prefer the [product_name] getter —
  /// it walks the trilingual fallback chain.
  final String? genericNameRaw;

  final String? product_brand;
  final String? product_barcode;
  final String? product_quantifier;
  final String? product_description;
  final String? product_category_name;

  // ── Pricing & stock ───────────────────────────────────────────

  /// **API wire name:** `unit_price`. This is the customer-facing,
  /// VAT-inclusive price the server bills against.
  ///
  /// The old model called this `product_price`, which the API never
  /// emitted — so the field was always null and every downstream
  /// invoice/order total came out zero. See the class docstring.
  final Decimal? unit_price;

  /// **API wire name:** `product_base_price`. Supplier-side cost.
  final Decimal? base_price;

  /// **API wire name:** `vat_rate` on the read response,
  /// `product_vat_value` on the write payload. Stored once under the
  /// write name so `toJson` is a straight projection.
  final Decimal? vat_rate;

  /// **API wire name:** `product_quantity` (total on-hand). Response
  /// emits it as a number, so parse with `_readDecimal` and cast at
  /// the accessor boundary if you need an int.
  final Decimal? total_quantity;

  /// **API wire name:** `reserved_quantity`. Same numeric handling as
  /// [total_quantity].
  final Decimal? reserved_quantity;

  /// **API wire name:** `available_quantity`. The server already
  /// computes `on_hand - reserved` — prefer this authoritative value
  /// in [product_available_quantity].
  final int? server_available_quantity;

  // ── Status ────────────────────────────────────────────────────
  final String? product_visibility;

  // ── Timestamps ────────────────────────────────────────────────
  final DateTime? product_created_at;
  final DateTime? product_last_updated;

  // ── Media ─────────────────────────────────────────────────────

  VerdeliaImage? productImage;

  /// Full gallery, in payload order (origin reference first, then
  /// seller-uploaded images). The single source of truth for the
  /// product's image URLs.
  final List<ProductImage> product_images;

  // ── Nested snapshots ─────────────────────────────────────────

  final Map<String, dynamic>? product_category;
  final Map<String, dynamic>? product_provider;

  /// Linked imported product, when the response includes an `origin`
  /// object. Carries the trilingual naming contribution and the
  /// AI-provenance metadata the flat Product row doesn't have.
  final IProduct? product_origin;

  // ── Constructor ──────────────────────────────────────────────

  Product({
    required this.id_product,
    required this.product_provider_id,
    required this.product_category_id,
    required this.id_product_category,
    required this.product_ref_id,
    required this.genericNameRaw,
    required this.product_brand,
    required this.product_quantifier,
    required this.product_barcode,
    required this.product_category_name,
    required this.unit_price,
    required this.total_quantity,
    required this.product_description,
    required this.product_created_at,
    required this.product_last_updated,
    required this.product_owner_id,
    this.base_price,
    this.vat_rate,
    this.reserved_quantity,
    this.server_available_quantity,
    this.product_visibility,
    this.product_origin_id,
    this.product_category,
    this.product_provider,
    this.product_origin,
    this.product_images = const [],
  });

  // ── Name access ──────────────────────────────────────────────

  String get product_name => _resolveName(_nameLanguage);
  String get productNameEn => _resolveName('en');
  String get productNameAr => _resolveName('ar');
  String get productNameFr => _resolveName('fr');

  String nameFor(String lang) => _resolveName(lang);

  String _nameLanguage = 'en';

  set preferredNameLanguage(String lang) {
    _nameLanguage = lang;
  }

  /// Trilingual fallback: requested → en → ar → fr → flat → ''.
  ///
  /// The naming contribution lives on the imported product's `origin`
  /// block (the payload key is `origin`, not `product_origin`). When
  /// it's absent, falls back to `genericNameRaw`.
  String _resolveName(String lang) {
    final naming = product_origin?.namingContribution;
    if (naming != null) {
      final resolved = naming.nameFor(lang);
      if (resolved.isNotEmpty) return resolved;
    }
    return (genericNameRaw ?? '').trim();
  }

  // ── Image access ─────────────────────────────────────────────

  ProductImage? get primaryImage =>
      product_images.isNotEmpty ? product_images.first : null;

  String? get primaryImageUrl => primaryImage?.url;

  bool get hasGallery => product_images.length > 1;

  List<String> get imageUrls => product_images
      .where((img) => img.hasUrl)
      .map((img) => img.url!)
      .toList(growable: false);

  // ── Factories ────────────────────────────────────────────────

  factory Product.empty() {
    return Product(
      id_product: null,
      product_provider_id: null,
      product_category_id: null,
      id_product_category: null,
      product_ref_id: null,
      genericNameRaw: '',
      product_brand: '',
      product_quantifier: '',
      product_barcode: '',
      product_category_name: '',
      unit_price: Decimal.zero,
      total_quantity: Decimal.zero,
      product_description: '',
      product_created_at: null,
      product_last_updated: null,
      product_owner_id: null,
      base_price: Decimal.zero,
      reserved_quantity: Decimal.zero,
      server_available_quantity: 0,
      product_visibility: 'VISIBLE',
      product_origin_id: null,
      product_category: null,
      product_provider: null,
      product_origin: null,
      product_images: const [],
    );
  }

  /// Parse a product response.
  ///
  /// Wire-name mapping:
  ///   * `unit_price`        → [unit_price]
  ///   * `product_base_price`→ [base_price]
  ///   * `vat_rate`          → [vat_rate]
  ///   * `product_quantity`  → [total_quantity]  (double on wire)
  ///   * `reserved_quantity` → [reserved_quantity] (double on wire)
  ///   * `available_quantity`→ [server_available_quantity]
  ///   * `generic_name`      → [genericNameRaw] (falls back to `product_name`)
  ///   * `origin`            → [product_origin] (payload key is `origin`)
  ///   * `product_image`     → [product_images]
  factory Product.fromJson(dynamic json) {
    final map = _asMap(json);
    if (map.isEmpty) return Product.empty();

    final sellerImages = _parseProductImages(map['product_image']);

    final categoryMap = _asMapOrNull(map['product_category']);
    final providerMap = _asMapOrNull(map['product_provider']);

    final originMap =
        _asMapOrNull(map['origin']) ?? _asMapOrNull(map['product_origin']);

    final origin = originMap == null ? null : IProduct.fromJson(originMap);

    final images = _composeGallery(
      originImageUrl: origin?.iproductImageUrl,
      sellerImages: sellerImages,
    );

    final categoryName = _asString(categoryMap?['product_category_name']) ??
        _asString(map['product_category_name']) ??
        'Missing';

    // The flat write shape uses `product_provider_id`, but the read
    // shape (both the inner `ordered_item.product` block and the
    // `getAllProducts` response) uses `provider_id` at the top level
    // and `product_provider.id_product_provider` when nested. Read
    // all three, in that order.
    final providerId = _asIntOrNull(map['product_provider_id']) ??
        _asIntOrNull(map['provider_id']) ??
        _asIntOrNull(providerMap?['id_product_provider']);

    // Same story for the category id. The read shape uses
    // `category_id` at the top level; the write shape uses
    // `product_category_id` / `id_product_category`; the nested
    // object uses `id_product_category`.
    final categoryId = _asIntOrNull(map['product_category_id']) ??
        _asIntOrNull(map['category_id']) ??
        _asIntOrNull(map['id_product_category']) ??
        _asIntOrNull(categoryMap?['id_product_category']);

    return Product(
      id_product: _asIntOrNull(map['id_product']),
      product_provider_id: providerId,
      product_category_id: categoryId,
      id_product_category: categoryId,
      product_ref_id: _asIntOrNull(map['product_ref_id']),
      genericNameRaw: _asString(map['generic_name']) ??
          _asString(map['product_name']) ??
          '',
      product_brand:
          _asString(map['brand']) ?? _asString(map['product_brand']) ?? '',
      product_barcode:
          _asString(map['barcode']) ?? _asString(map['product_barcode']) ?? '',
      product_quantifier: _asString(map['quantifier']) ??
          _asString(map['product_quantifier']) ??
          '',
      product_category_name: categoryName,
      product_images: images,
      unit_price: _readDecimal(
        map['unit_price'] ?? map['product_price'],
      ),
      base_price: _readDecimal(
        map['product_base_price'] ?? map['base_price'],
      ),
      vat_rate: _readDecimal(
        map['vat_rate'] ?? map['product_vat_value'],
      ),
      total_quantity: _readDecimal(
        map['product_quantity'] ?? map['available_quantity'],
      ),
      reserved_quantity: _readDecimal(
        map['reserved_quantity'] ?? map['product_reserved_quantity'],
      ),
      server_available_quantity: _asIntOrNull(map['available_quantity']),
      product_description: _asString(map['product_description']) ?? '',
      product_created_at: _parseDate(map['created']),
      product_last_updated: _parseDate(map['last_updated']),
      product_owner_id: _asIntOrNull(map['user_id'] ?? map['product_owner']),
      product_visibility:
          _asString(map['visibility'] ?? map['product_visibility']) ??
              'VISIBLE',
      product_origin_id:
          _asIntOrNull(map['origin_id'] ?? map['product_origin_id']),
      product_category: categoryMap,
      product_provider: providerMap,
      product_origin: origin,
    );
  }

  factory Product.fromSearchJson(dynamic json) {
    if (json == null) return Product.empty();
    return Product.fromJson(json);
  }

  // ── copyWith ─────────────────────────────────────────────────

  Product copyWith({
    int? id_product,
    int? product_provider_id,
    int? product_category_id,
    int? id_product_category,
    int? product_ref_id,
    int? product_owner_id,
    int? product_origin_id,
    String? genericNameRaw,
    String? product_brand,
    String? product_barcode,
    String? product_quantifier,
    String? product_description,
    String? product_category_name,
    Decimal? unit_price,
    Decimal? base_price,
    Decimal? vat_rate,
    Decimal? total_quantity,
    Decimal? reserved_quantity,
    int? server_available_quantity,
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
      genericNameRaw: genericNameRaw ?? this.genericNameRaw,
      product_brand: product_brand ?? this.product_brand,
      product_barcode: product_barcode ?? this.product_barcode,
      product_quantifier: product_quantifier ?? this.product_quantifier,
      product_description: product_description ?? this.product_description,
      product_category_name:
          product_category_name ?? this.product_category_name,
      unit_price: unit_price ?? this.unit_price,
      base_price: base_price ?? this.base_price,
      vat_rate: vat_rate ?? this.vat_rate,
      total_quantity: total_quantity ?? this.total_quantity,
      reserved_quantity: reserved_quantity ?? this.reserved_quantity,
      server_available_quantity:
          server_available_quantity ?? this.server_available_quantity,
      product_visibility: product_visibility ?? this.product_visibility,
      product_created_at: product_created_at ?? this.product_created_at,
      product_last_updated: product_last_updated ?? this.product_last_updated,
      product_category: product_category ?? this.product_category,
      product_provider: product_provider ?? this.product_provider,
      product_origin: product_origin ?? this.product_origin,
      product_images: product_images ?? this.product_images,
    );
  }

  // ── Serialisation ────────────────────────────────────────────

  Map<String, dynamic> toJson() {
    final originJson = product_origin?.toJson();

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
        'id_product_category': id_product_category ?? 0,
        'product_name': genericNameRaw ?? '',
        'product_brand': product_brand ?? '',
        'product_barcode': product_barcode ?? '',
        'product_quantifier': product_quantifier ?? '',
        'product_category_desc': product_category_name ?? '',
        'unit_price': _decimalToWire(unit_price ?? Decimal.zero),
        'product_base_price': _decimalToWire(base_price ?? Decimal.zero),
        'product_vat_value': _decimalToWire(vat_rate ?? Decimal.zero),
        'product_quantity': _decimalToWire(total_quantity ?? Decimal.zero),
        'product_reserved_quantity':
            _decimalToWire(reserved_quantity ?? Decimal.zero),
        'product_visibility': product_visibility ?? 'VISIBLE',
        'product_description': product_description ?? '',
        'product_owner': product_owner_id ?? 0,
        // NOTE: `product_origin_id` is intentionally omitted. It is
        // not on `Product_API`. The origin is attached via the
        // `iproduct` sibling on the create payload (see
        // [toCreateJson]).
      },
      if (imageJson != null) 'image': imageJson,
      if (originJson != null) 'product_origin': originJson,
    };
  }

  // ── Convenience getters ─────────────────────────────────────

  /// On-hand quantity minus reserved quantity. Prefers the server's
  /// authoritative `available_quantity` when the response included
  /// one; falls back to arithmetic when it didn't.
  int get product_available_quantity {
    final server = server_available_quantity;
    if (server != null) return server;
    final total = total_quantity?.toBigInt().toInt() ?? 0;
    final reserved = reserved_quantity?.toBigInt().toInt() ?? 0;
    final diff = total - reserved;
    if (diff < 0) return 0;
    if (diff > total) return total;
    return diff;
  }

  bool get isVisible =>
      (product_visibility ?? 'VISIBLE').toUpperCase() == 'VISIBLE';

  bool get isInStock => product_available_quantity > 0;

  /// Kept for backward compatibility with callers that read
  /// `product.product_price`. Equivalent to [unit_price].
  Decimal? get product_price => unit_price;

  /// Kept for backward compatibility. Equivalent to [base_price].
  Decimal? get product_base_price => base_price;

  /// Kept for backward compatibility. Equivalent to [vat_rate].
  Decimal? get product_vat_value => vat_rate;

  /// Kept for backward compatibility. Equivalent to
  /// `total_quantity.toInt()`.
  int? get product_quantity => total_quantity?.toBigInt().toInt();

  /// Kept for backward compatibility.
  int? get product_reserved_quantity => reserved_quantity?.toBigInt().toInt();

  /// `unit_price − base_price`, in [Decimal]. Null when [base_price]
  /// is zero or absent.
  Decimal? get unitMargin {
    final base = base_price ?? Decimal.zero;
    if (base <= Decimal.zero) return null;
    return (unit_price ?? Decimal.zero) - base;
  }

  /// `(unit_price − base_price) / base_price`, in [Decimal]. Null when
  /// [base_price] is zero or absent.
  ///
  /// `.toDecimal(scaleOnInfinitePrecision: 2)` on the division: `Decimal / Decimal` returns a
  /// `Rational`, which can't be assigned to a `Decimal`.
  Decimal? get unitMarginPercent {
    final base = base_price ?? Decimal.zero;
    if (base <= Decimal.zero) return null;
    final diff = (unit_price ?? Decimal.zero) - base;
    return (diff / base).toDecimal(scaleOnInfinitePrecision: 2);
  }

  // ── Equality ─────────────────────────────────────────────────

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id_product == id_product;
  }

  @override
  int get hashCode => id_product.hashCode;

  @override
  String toString() =>
      'Product(id: $id_product, name: $product_name, price: $unit_price)';
}

// ==================== Parse helpers ====================

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

/// Coerces any JSON value to a [Decimal], defaulting to zero.
Decimal _readDecimalOrZero(dynamic v) => _readDecimal(v) ?? Decimal.zero;

/// Converts a [Decimal] to the shortest `double` that round-trips.
/// For the JSON wire boundary only — never use this for arithmetic.
double _decimalToDouble(Decimal v) => double.parse(v.toString());

/// Serialises a [Decimal] for JSON. Emits a `num` so `jsonEncode`
/// writes it as a JSON number, not a string.
num _decimalToWire(Decimal v) => _decimalToDouble(v);

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

  String nameFor(String lang) {
    final resolved = naming?.nameFor(lang) ?? '';
    if (resolved.isNotEmpty) return resolved;
    return productCategoryDesc;
  }

  String? get resolvedIconUrl {
    final fromNaming = naming?.iconUrl;
    if (fromNaming != null && fromNaming.isNotEmpty) return fromNaming;
    return iconUrl;
  }

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
