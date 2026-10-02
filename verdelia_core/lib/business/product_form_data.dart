import 'dart:io';

import '../app/VerdeliaImage.dart';
import 'Product.dart';
import 'iProduct.dart';

class ProductFormData {
  // Form fields
  String? productName;
  String? productBrand;
  String? productBarcode;
  String? productDescription;
  VerdeliaImage? image;
  File? imageFile;
  int? typeId;

  /// Customer-facing price (what the buyer pays). Stored as `product_price`.
  double? price;

  /// Supplier-side cost (what the supplier paid or produces it for).
  /// Stored as `product_base_price`. Optional — a product can be listed
  /// without a known cost, in which case margin is undefined.
  double? productBasePrice;

  int? quantity;
  String? quantifier;
  int? ownerId;
  int? providerId;
  int? categoryId;
  int? productId;
  int? imageId;
  String? imageUrl;
  bool isUpdate = false;
  int selectedProviderId = 0;

  bool lockProvider = false;

  /// "VISIBLE" | "HIDDEN". Defaults to VISIBLE for new products.
  /// Preserved on update so the toggle in the editor view round-trips.
  String visibility = 'VISIBLE';

  /// Quantity already reserved by carts and pending orders. Read-only
  /// from the form's perspective, but carried through so the Product
  /// built by [toProduct] keeps the current value on update.
  int? reservedQuantity;

  /// Origin reference, populated only from assistant-provided data.
  int? originId;

  /// Assistant-origin data synced into this form, if any.
  IProduct? assistantOrigin;

  // ==================== Convert to Product ====================

  /// Build the Product for the write path.
  ///
  /// Origin metadata is opt-in and must be supplied only when assistant
  /// data remains unedited.
  Product toProduct({IProduct? assistantProductOrigin}) {
    return Product(
      id_product: productId ?? 0,
      // Always use the (possibly locked) selected provider.
      product_provider_id: selectedProviderId,
      product_quantifier: quantifier ?? 'pc',
      product_owner_id: ownerId ?? 1,
      id_product_category: typeId ?? categoryId ?? 1,
      product_category_id: typeId ?? categoryId ?? 1,
      id_product_image: imageId,
      product_ref_id: productId,
      // Write path sends the flat name. Read path resolves it via the
      // `product_name` getter on the Product model.
      product_nameRaw: productName ?? '',
      product_brand: productBrand ?? '',
      product_barcode: productBarcode ?? '',
      product_image_url: imageUrl,
      product_category_name: '',
      product_price: price ?? 0.0,
      product_base_price: productBasePrice ?? 0.0,
      product_quantity: quantity ?? 0,
      product_reserved_quantity: reservedQuantity ?? 0,
      product_visibility: visibility,
      product_origin_id: assistantProductOrigin?.idIproduct,
      product_description: productDescription ?? '',
      product_created_at: null,
      product_last_updated: null,
      product_origin: assistantProductOrigin,
    );
  }

  // ==================== Populate from Product ====================

  /// Seed the form from an existing Product.
  ///
  /// [productName] takes the resolved name from the model's getter, so
  /// the editor shows whichever language the caller has selected (or
  /// English by default).
  void populateFromProduct(Product product) {
    // Resolved name — English unless the caller set a preferred
    // language on the Product instance before calling this.
    productName = product.product_name;
    productBrand = product.product_brand;
    productBarcode = product.product_barcode;
    imageUrl = product.product_image_url;
    typeId = product.product_category_id ?? 1;
    price = product.product_price;
    productBasePrice = product.product_base_price;
    quantity = product.product_quantity;
    quantifier = product.product_quantifier ?? 'pc';
    ownerId = product.product_owner_id;
    productDescription = product.product_description;
    providerId = product.product_provider_id;
    categoryId = product.product_category_id;
    productId = product.id_product;
    imageId = product.id_product_image;
    isUpdate = true;
    selectedProviderId = product.product_provider_id ?? 0;
    lockProvider = true;

    // Fields carried through on update
    visibility = product.product_visibility ?? 'VISIBLE';
    reservedQuantity = product.product_reserved_quantity;
  }
}
