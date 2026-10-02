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
    } else {
      if (image != null) {
        image.setupImage(
          filepath: image.filepath,
          filename: image.filename,
          entityType: 'product',
          ownerId: '${product.product_owner_id ?? 0}',
          entityId: '${product.id_product}',
        );
        product.product_image_url = await image.uploadImage();
      }
      result = await _service.updateProduct(product);
      if (result == null) return null;
    }

    if (isCreate && image != null) {
      final productId = result.id_product;
      if (productId == null || productId <= 0) {
        throw StateError('Created product did not return a valid ID.');
      }
      image.setupImage(
        filepath: image.filepath,
        filename: image.filename,
        entityType: 'product',
        ownerId: '${result.product_owner_id ?? product.product_owner_id ?? 0}',
        entityId: '$productId',
      );
      final imageUrl = await image.uploadImage();
      if (imageUrl == null || imageUrl.isEmpty) {
        throw StateError('Image upload did not return an image path.');
      }

      final productWithImage = result.copyWith(product_image_url: imageUrl);
      result = await _service.updateProduct(productWithImage);
      if (result == null) {
        throw StateError(
          'Product was created, but its image URL could not be saved.',
        );
      }
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
}
