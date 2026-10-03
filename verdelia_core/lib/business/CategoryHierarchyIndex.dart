class CategoryHierarchyIndex<T> {
  final Map<String, Map<String, List<T>>> _domains;

  CategoryHierarchyIndex._(this._domains);

  factory CategoryHierarchyIndex.fromItems(
    Iterable<T> items,
    String Function(T item) pathOf,
  ) {
    final domains = <String, Map<String, List<T>>>{};
    for (final item in items) {
      final segments = pathOf(item)
          .split('.')
          .map((segment) => segment.trim())
          .where((segment) => segment.isNotEmpty)
          .toList();
      final domain = segments.length >= 2 ? segments[0] : 'other';
      final subdomain = segments.length >= 3 ? segments[1] : 'other';
      (domains[domain] ??= <String, List<T>>{})
          .putIfAbsent(subdomain, () => <T>[])
          .add(item);
    }

    // Build the immutable view with explicit types at each level so the
    // result is Map<String, Map<String, List<T>>> — not dynamic-dynamic.
    final frozenDomains = <String, Map<String, List<T>>>{};
    for (final domainEntry in domains.entries) {
      final frozenSubdomains = <String, List<T>>{};
      for (final subEntry in domainEntry.value.entries) {
        frozenSubdomains[subEntry.key] = List<T>.unmodifiable(subEntry.value);
      }
      frozenDomains[domainEntry.key] =
          Map<String, List<T>>.unmodifiable(frozenSubdomains);
    }

    return CategoryHierarchyIndex._(
      Map<String, Map<String, List<T>>>.unmodifiable(frozenDomains),
    );
  }

  List<String> get domains => List.unmodifiable(_domains.keys);

  List<String> subdomainsFor(String domain) =>
      List.unmodifiable(_domains[domain]?.keys ?? const <String>[]);

  List<T> categoriesFor(String domain, String subdomain) =>
      _domains[domain]?[subdomain] ?? <T>[];

  Map<String, Map<String, List<T>>> get groups => _domains;
}
