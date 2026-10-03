import 'package:flutter_test/flutter_test.dart';
import 'package:verdelia_core/business/CategoryHierarchyIndex.dart';

class _Category {
  final String path;

  const _Category(this.path);
}

void main() {
  test('retains domains, subdomains, and categories from dotted paths', () {
    const categories = [
      _Category('health.diagnostics.blood_testing'),
      _Category('health.diagnostics.imaging'),
      _Category('health.primary_care.checkup'),
      _Category('food.beverages.juice'),
      _Category('legacy_category'),
    ];

    final hierarchy = CategoryHierarchyIndex.fromItems(
      categories,
      (category) => category.path,
    );

    expect(hierarchy.domains, containsAll(['health', 'food', 'other']));
    expect(
      hierarchy.subdomainsFor('health'),
      containsAll(['diagnostics', 'primary_care']),
    );
    expect(
      hierarchy.categoriesFor('health', 'diagnostics'),
      [categories[0], categories[1]],
    );
    expect(hierarchy.categoriesFor('other', 'other'), [categories[4]]);
  });
}
