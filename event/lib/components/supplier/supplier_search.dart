import 'dart:async';
import 'dart:developer';

import 'package:verdelia_core/business/Supplier.dart';
import 'package:verdelia_core/business/services/SupplierService.dart';
import 'package:verdelia_core/mediation/StorageService.dart';
import 'package:flutter/foundation.dart';
import 'supplier_cache.dart';
import 'supplier_state.dart';
import 'supplier_filter.dart';

class SupplierSearch {
  final SupplierService _service;
  final StorageService _storage;
  final SupplierCache _cache;
  final SupplierState _state;

  Timer? _debounceTimer;
  static const _delayMs = 300;
  static const _itemsPerPage = 50;

  SupplierSearch({
    required SupplierService service,
    required StorageService storage,
    required SupplierCache cache,
    required SupplierState state,
  })  : _service = service,
        _storage = storage,
        _cache = cache,
        _state = state;

  void dispose() => _debounceTimer?.cancel();

  Future<void> search(String query) async {
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      _state.filter = const SupplierFilter();
      return;
    }

    final cacheKey = 'search_${query.toLowerCase()}';
    final cached = _cache.getList(cacheKey);
    if (cached != null) {
      _addSuppliers(cached);
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: _delayMs), () async {
      _state.filter = SupplierFilter(name: query);
      _state.isLoading = true;

      try {
        final results = await _service.searchSuppliersByToken(
          query,
          0,
          _itemsPerPage,
        );
        _cache.cacheList(cacheKey, results);
        _addSuppliers(results);
      } catch (e) {
        debugPrint('Search error: $e');
      } finally {
        _state.isLoading = false;
      }
    });
  }

  Future<void> searchByGeo({
    required double longitude,
    required double latitude,
    required double radiusKm,
    bool reset = false,
  }) async {
    final key =
        'geo_${longitude}_${latitude}_${radiusKm}_${_state.suppliersPage}';

    if (!reset) {
      final cached = _cache.getList(key);
      if (cached != null) {
        _addSuppliers(cached);
        return;
      }
    }

    if (reset) {
      _state.suppliers.clear();
      _state.suppliersPage = 0;
      _state.hasMoreSuppliers = true;
    }

    _state.isLoading = true;

    try {
      final results = await _service.searchSuppliersByGeo(
        longitude,
        latitude,
        _state.suppliersPage * SupplierState.itemsPerPage,
        SupplierState.itemsPerPage,
        radiusKm,
      );

      _cache.cacheList(key, results);
      _addSuppliers(results);

      _state.hasMoreSuppliers = results.length >= SupplierState.itemsPerPage;
      if (_state.hasMoreSuppliers) _state.suppliersPage++;
    } finally {
      _state.isLoading = false;
    }
  }

  void _addSuppliers(List<Supplier> newSuppliers) {
    final existing = _state.suppliers.map((s) => s.idProductProvider).toSet();
    for (final supplier in newSuppliers) {
      if (!existing.contains(supplier.idProductProvider)) {
        _state.suppliers.add(supplier);
        _cache.cacheSupplier(supplier);
      }
    }
  }
}
