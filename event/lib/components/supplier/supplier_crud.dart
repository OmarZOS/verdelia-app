import 'dart:developer';

import 'package:verdelia_core/app/VerdeliaException.dart';
import 'package:verdelia_core/business/Supplier.dart';
import 'package:verdelia_core/business/services/SupplierService.dart';
import 'package:verdelia_core/mediation/StorageService.dart';
import 'supplier_cache.dart';
import 'supplier_state.dart';
import 'supplier_persistence.dart';

class SupplierCrud {
  final SupplierService _service;
  final StorageService _storage;
  final SupplierCache _cache;
  final SupplierState _state;
  final SupplierPersistence _persistence;

  SupplierCrud({
    required SupplierService service,
    required StorageService storage,
    required SupplierCache cache,
    required SupplierState state,
    required SupplierPersistence persistence,
  })  : _service = service,
        _storage = storage,
        _cache = cache,
        _state = state,
        _persistence = persistence;

  String _generateKey(String op, {String? id, String? suffix}) {
    final parts = [op];
    if (id != null) parts.add(id);
    if (suffix != null) parts.add(suffix);
    parts.add(DateTime.now().millisecondsSinceEpoch.toString());
    return parts.join('_');
  }

  Future<Supplier> createOrUpdate(Supplier supplier, String token) async {
    final isCreating = supplier.idProductProvider == 0;
    final key = _generateKey(isCreating ? 'create' : 'update',
        id: isCreating ? null : supplier.idProductProvider.toString());

    _state.isLoading = true;

    try {
      if (supplier.supplierImage != null) {
        final url = await supplier.supplierImage?.uploadImage();
        supplier = supplier.copyWith(supplierImageUrl: url);
      }

      final result = isCreating
          ? await _service.addSupplier(supplier, token: token)
          : await _service.updateSupplier(supplier, token: token);

      if (result == null) {
        throw VerdeliaException('Failed to save supplier');
      }

      _cache.invalidate(supplierId: result.idProductProvider);
      _cache.cacheSupplier(result);
      _updateInList(result);

      if (isCreating) {
        await _persistence.addSupplier(
            _persistence.currentUserId, result.idProductProvider);
      }

      _storeSuccess(key, result, isCreating ? 'CREATED' : 'UPDATED');
      return result;
    } finally {
      _state.isLoading = false;
    }
  }

  Future<bool> delete(int id, String token) async {
    final key = _generateKey('delete', id: id.toString());

    try {
      final status = await _service.deleteSupplier(id.toString(), token: token);
      final success = status != null && (status == 200 || status == 204);

      if (success) {
        _state.suppliers.removeWhere((s) => s.idProductProvider == id);
        _cache.invalidate(supplierId: id);
        await _persistence.removeSupplier(_persistence.currentUserId, id);
        _storeSuccess(key, true, 'DELETED');
      }

      return success;
    } catch (e) {
      _storeFailure(key, e);
      return false;
    }
  }

  void _updateInList(Supplier supplier) {
    final index = _state.suppliers
        .indexWhere((s) => s.idProductProvider == supplier.idProductProvider);
    if (index != -1) {
      _state.suppliers[index] = supplier;
    }
  }

  void _storeSuccess(String key, data, String code) {
    _storage.setSuccessResponse(key, data, statusCode: 200, responseCode: code);
  }

  void _storeFailure(String key, error) {
    _storage.setFailureResponse(key,
        data: error,
        statusCode: 500,
        errorCode: 'ERROR',
        message: error.toString());
  }
}
