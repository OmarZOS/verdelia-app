import 'dart:developer';

import 'package:verdelia_core/business/Product.dart';
import 'package:verdelia_core/business/services/ProductService.dart';

import 'product_cache.dart';
import 'product_state.dart';

class ProductCrud {
  final ProductService _service;
  final ProductCache _cache;
  final ProductState _state;

  ProductCrud({
    required ProductService service,
    required ProductCache cache,
    required ProductState state,
  })  : _service = service,
        _cache = cache,
        _state = state;

  Future<Product?> createOrUpdate(Product product) async {
    final image = product.productImage;
    final isCreate = product.id_product == 0;

    Product? result;

    if (isCreate) {
      result = await _service.addProduct(product);
      if (result == null) return null;

      // The create path can't upload an image until the product id
      // exists, so upload after insertion and patch the gallery back.
      if (image != null) {
        final productId = result.id_product;
        if (productId == null || productId <= 0) {
          throw StateError('Created product did not return a valid ID.');
        }

        final imageUrl = await _uploadFor(
          image: image,
          ownerId:
              '${result.product_owner_id ?? product.product_owner_id ?? 0}',
          entityId: '$productId',
        );

        final productWithImage = result.copyWith(
          product_images: [
            ...result.product_images,
            ProductImage(id: 0, url: imageUrl),
          ],
        );

        result = await _service.updateProduct(productWithImage);
        if (result == null) {
          throw StateError(
            'Product was created, but its image URL could not be saved.',
          );
        }
      }
    } else {
      // Update path: if the caller attached a new VerdeliaImage, upload
      // it first and append the resulting row to the gallery. The rest
      // of the gallery (existing images) rides along in `toJson`.
      if (image != null) {
        final imageUrl = await _uploadFor(
          image: image,
          ownerId: '${product.product_owner_id ?? 0}',
          entityId: '${product.id_product}',
        );

        product = product.copyWith(
          product_images: [
            ...product.product_images,
            ProductImage(id: 0, url: imageUrl),
          ],
        );
      }

      result = await _service.updateProduct(product);
      if (result == null) return null;
    }

    if (result.id_product != null) {
      _cache.invalidateProduct(result.id_product);
      _cache.cacheProduct(result);
      _updateInList(result);
    }

    return result;
  }

  Future<int?> delete(String idProduct) async {
    try {
      final status = await _service.deleteProduct(idProduct);
      if (status != null) {
        final id = int.parse(idProduct);
        _cache.invalidateProduct(id);
        _state.products.removeWhere((p) => p.id_product == id);
      }
      return status;
    } catch (e) {
      log("Failed to delete product: $e");
      return null;
    }
  }

  void _updateInList(Product product) {
    final index =
        _state.products.indexWhere((p) => p.id_product == product.id_product);
    if (index != -1) {
      _state.products[index] = product;
    }
  }

  /// Configure the [VerdeliaImage] for a given entity and upload it.
  /// Returns the resolved URL, or throws when the upload pipeline
  /// returns nothing usable.
  Future<String> _uploadFor({
    required dynamic image,
    required String ownerId,
    required String entityId,
  }) async {
    image.setupImage(
      filepath: image.filepath,
      filename: image.filename,
      entityType: 'product',
      ownerId: ownerId,
      entityId: entityId,
    );

    final imageUrl = await image.uploadImage();
    if (imageUrl == null || (imageUrl is String && imageUrl.isEmpty)) {
      throw StateError('Image upload did not return an image path.');
    }
    return imageUrl is String ? imageUrl : imageUrl.toString();
  }
}
