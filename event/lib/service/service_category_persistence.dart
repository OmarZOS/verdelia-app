// lib/event/service/service_category_persistence.dart

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verdelia_core/business/finance/ProvidedService.dart';

/// Persists the service category list across launches so the picker
/// is populated immediately on cold start.
///
/// Mirrors [ProductCategoryPersistence]: writes a versioned JSON blob
/// under a single key, and returns null on any read/parse failure so
/// the caller falls through to a network fetch rather than rendering
/// a half-broken list.
class ServiceCategoryPersistence {
  static const _storageKey = 'service_categories_v1';

  Future<List<ProvidedServiceCategory>?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;

      final categories = decoded
          .whereType<Map>()
          .map((e) =>
              ProvidedServiceCategory.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);

      if (categories.isEmpty) return null;
      return categories;
    } catch (error, stackTrace) {
      debugPrint(
        '[ServiceCategoryPersistence] load failed: $error\n$stackTrace',
      );
      return null;
    }
  }

  Future<void> save(List<ProvidedServiceCategory> categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(
        categories.map((c) => c.toJson()).toList(growable: false),
      );
      await prefs.setString(_storageKey, encoded);
    } catch (error, stackTrace) {
      debugPrint(
        '[ServiceCategoryPersistence] save failed: $error\n$stackTrace',
      );
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (error, stackTrace) {
      debugPrint(
        '[ServiceCategoryPersistence] clear failed: $error\n$stackTrace',
      );
    }
  }
}
