import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:verdelia_core/business/Product.dart';

class ProductCategoryPersistence {
  static const _storageKey = 'product_categories_v1';

  Future<List<ProductCategory>?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_storageKey);
    if (encoded == null) return null;

    final decoded = jsonDecode(encoded);
    if (decoded is! List) return null;

    return decoded
        .whereType<Map>()
        .map((category) => ProductCategory.fromJson(
              Map<String, dynamic>.from(category),
            ))
        .toList(growable: false);
  }

  Future<void> save(List<ProductCategory> categories) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode(categories.map((category) => category.toJson()).toList()),
    );
  }
}
