import 'dart:collection';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:verdelia_core/business/Supplier.dart';

class _CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final int ttlSeconds;

  _CacheEntry(this.data, {this.ttlSeconds = 300}) : timestamp = DateTime.now();

  bool get isExpired =>
      DateTime.now().difference(timestamp).inSeconds > ttlSeconds;
  bool get isValid => !isExpired;
}

class SupplierCache {
  static const int _maxCacheSize = 100;
  static const int _defaultCacheTTLSeconds = 300;
  static const int _longCacheTTLSeconds = 3600;
  static const int _shortCacheTTLSeconds = 60;

  final Map<int, _CacheEntry<Supplier>> _detailedCache = {};
  final LinkedHashMap<int, _CacheEntry<Supplier>> _lruCache = LinkedHashMap();
  final Map<String, _CacheEntry<List<int>>> _listCache = {};

  bool _enabled = true;
  int _hits = 0;
  int _misses = 0;

  bool get isEnabled => _enabled;
  int get hits => _hits;
  int get misses => _misses;
  int get detailedCacheSize => _detailedCache.length;
  int get lruCacheSize => _lruCache.length;
  int get listCacheSize => _listCache.length;

  void enable(bool enable) {
    if (_enabled != enable) {
      _enabled = enable;
      if (!enable) clearAll();
    }
  }

  void clearAll() {
    _detailedCache.clear();
    _lruCache.clear();
    _listCache.clear();
    _hits = 0;
    _misses = 0;
  }

  void invalidate({int? supplierId, String? listKey}) {
    if (supplierId != null) {
      _detailedCache.remove(supplierId);
      _lruCache.remove(supplierId);
    }
    if (listKey != null) {
      _listCache.remove(listKey);
    }
    if (supplierId == null && listKey == null) {
      clearAll();
    }
  }

  Supplier? getSupplier(int id) {
    if (!_enabled) return null;

    // Check LRU cache first
    final lruEntry = _lruCache[id];
    if (lruEntry != null && !lruEntry.isExpired) {
      // Move to front (recently used)
      _lruCache.remove(id);
      _lruCache[id] = lruEntry;
      _hits++;
      return lruEntry.data;
    }
    if (lruEntry != null && lruEntry.isExpired) {
      _lruCache.remove(id);
    }

    // Check detailed cache
    final entry = _detailedCache[id];
    if (entry != null && entry.isValid) {
      _addToLRU(id, entry.data);
      _hits++;
      return entry.data;
    }

    if (entry != null && entry.isExpired) {
      _detailedCache.remove(id);
    }

    _misses++;
    return null;
  }

  void cacheSupplier(Supplier supplier, {int? ttlSeconds}) {
    if (!_enabled) return;
    final ttl = ttlSeconds ?? _defaultCacheTTLSeconds;
    _detailedCache[supplier.idProductProvider] =
        _CacheEntry(supplier, ttlSeconds: ttl);
    _addToLRU(supplier.idProductProvider, supplier);
  }

  void cacheList(String key, List<Supplier> suppliers, {int? ttlSeconds}) {
    if (!_enabled) return;
    final ids = suppliers.map((s) => s.idProductProvider).toList();
    _listCache[key] = _CacheEntry<List<int>>(ids,
        ttlSeconds: ttlSeconds ?? _defaultCacheTTLSeconds);
    for (final supplier in suppliers) {
      cacheSupplier(supplier);
    }
  }

  List<Supplier>? getList(String key) {
    if (!_enabled) return null;

    final entry = _listCache[key];
    if (entry == null) return null;

    if (entry.isExpired) {
      _listCache.remove(key);
      _misses++;
      return null;
    }

    final suppliers = <Supplier>[];
    for (final id in entry.data) {
      final cached = getSupplier(id);
      if (cached != null) {
        suppliers.add(cached);
      } else {
        _listCache.remove(key);
        _misses++;
        return null;
      }
    }

    _hits++;
    return suppliers;
  }

  void _addToLRU(int id, Supplier supplier) {
    if (!_enabled) return;

    if (_lruCache.containsKey(id)) {
      _lruCache.remove(id);
    }

    while (_lruCache.length >= _maxCacheSize) {
      final oldestKey = _lruCache.keys.first;
      _lruCache.remove(oldestKey);
    }

    _lruCache[id] = _CacheEntry(supplier, ttlSeconds: _defaultCacheTTLSeconds);
  }

  double get hitRate => _hits + _misses > 0 ? _hits / (_hits + _misses) : 0.0;
}
