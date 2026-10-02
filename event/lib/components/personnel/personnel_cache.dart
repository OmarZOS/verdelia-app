import 'dart:developer';

import 'package:verdelia_core/app/AppUser.dart';
import 'package:verdelia_core/app/ManagementRule.dart';
import 'package:verdelia_core/app/Person.dart';

class PersonnelCache {
  // Existing caches
  final Map<int, AppUser> users = {};
  final Map<int, List<ManagementRule>> privileges = {};
  final Map<int, List<ManagementRule>> pendingRules = {};
  final Map<int, List<ManagementRule>> activeRules = {};
  final Map<int, List<int>> userSupplierMappings = {};
  final Map<int, List<int>> supplierPersonnelMappings = {};

  // Search caches
  final Map<String, SearchCacheEntry> _searchCache = {};
  final Map<int, List<int>> _supplierSearchCache =
      {}; // supplierId -> list of user IDs from search

  // Cache configuration
  static const Duration _cacheDuration = Duration(minutes: 5);
  static const int _maxSearchCacheSize = 50;

  void clearAll() {
    users.clear();
    privileges.clear();
    pendingRules.clear();
    activeRules.clear();
    userSupplierMappings.clear();
    supplierPersonnelMappings.clear();
    _searchCache.clear();
    _supplierSearchCache.clear();
  }

  // ============ USER CACHE ============

  void cacheUser(AppUser user) {
    if (user.idAppUser != null && user.idAppUser! > 0) {
      final existing = users[user.idAppUser!];
      // Only update if the new user has more data or is different
      if (existing == null ||
          existing.appUserName != user.appUserName ||
          existing.appUserEmail != user.appUserEmail ||
          existing.appUserImageUrl != user.appUserImageUrl) {
        users[user.idAppUser!] = user;
        log('Cached user: ${user.displayName} (ID: ${user.idAppUser})');
      }
    }
  }

  void cacheUsersBatch(List<AppUser> userList) {
    for (final user in userList) {
      cacheUser(user);
    }
  }

  AppUser? getUser(int userId) {
    return users[userId];
  }

  List<AppUser> getUsers(List<int> userIds) {
    return userIds.map((id) => users[id]).whereType<AppUser>().toList();
  }

  // ============ PRIVILEGE CACHE ============

  void cachePrivileges(int userId, List<ManagementRule> rules) {
    privileges[userId] = rules;
  }

  List<ManagementRule>? getPrivileges(int userId) {
    return privileges[userId];
  }

  void cachePendingRules(int userId, List<ManagementRule> rules) {
    pendingRules[userId] = rules;
  }

  List<ManagementRule>? getPendingRules(int userId) {
    return pendingRules[userId];
  }

  void cacheActiveRules(int userId, List<ManagementRule> rules) {
    activeRules[userId] = rules;
  }

  List<ManagementRule>? getActiveRules(int userId) {
    return activeRules[userId];
  }

  // ============ SUPPLIER MAPPINGS ============

  void addSupplierMapping(int userId, int supplierId) {
    final mappings = userSupplierMappings[userId] ?? [];
    if (!mappings.contains(supplierId)) {
      mappings.add(supplierId);
      userSupplierMappings[userId] = mappings;
    }

    final personnel = supplierPersonnelMappings[supplierId] ?? [];
    if (!personnel.contains(userId)) {
      personnel.add(userId);
      supplierPersonnelMappings[supplierId] = personnel;
    }
  }

  void removeSupplierMapping(int userId, int supplierId) {
    userSupplierMappings[userId]?.remove(supplierId);
    if (userSupplierMappings[userId]?.isEmpty ?? false) {
      userSupplierMappings.remove(userId);
    }

    supplierPersonnelMappings[supplierId]?.remove(userId);
    if (supplierPersonnelMappings[supplierId]?.isEmpty ?? false) {
      supplierPersonnelMappings.remove(supplierId);
    }
  }

  List<int> getActiveUserIdsForSupplier(int supplierId) {
    return supplierPersonnelMappings[supplierId] ?? [];
  }

  List<int> getSupplierIdsForUser(int userId) {
    return userSupplierMappings[userId] ?? [];
  }

  // ============ SEARCH CACHE ============

  /// Get cached search results for a query
  /// Returns null if not found or expired
  SearchCacheEntry? getSearchResults(String query, {int supplierId = 0}) {
    final key = _generateCacheKey(query, supplierId);
    final entry = _searchCache[key];

    if (entry == null) return null;

    // Check if cache is expired
    if (!entry.isValid()) {
      _searchCache.remove(key);
      return null;
    }

    return entry;
  }

  /// Cache search results for a query
  void cacheSearchResults(
    String query, {
    required List<AppUser> users,
    required List<Person> people,
    int supplierId = 0,
  }) {
    final key = _generateCacheKey(query, supplierId);

    // Limit cache size - evict oldest entries if needed
    if (_searchCache.length >= _maxSearchCacheSize) {
      _evictOldestCacheEntries();
    }

    _searchCache[key] = SearchCacheEntry(
      users: users,
      people: people,
      timestamp: DateTime.now(),
    );

    // Store user IDs for supplier search cache
    if (supplierId > 0) {
      final userIds = users.map((u) => u.idAppUser).whereType<int>().toList();
      _supplierSearchCache[supplierId] = userIds;
    }
  }

  /// Get cached users for a specific supplier
  List<AppUser> getCachedUsersForSupplier(int supplierId) {
    final userIds = _supplierSearchCache[supplierId] ?? [];
    return getUsers(userIds);
  }

  /// Clear all search cache
  void clearSearchCache() {
    _searchCache.clear();
    _supplierSearchCache.clear();
  }

  /// Clear search cache for a specific supplier
  void clearSearchCacheForSupplier(int supplierId) {
    _searchCache.removeWhere((key, _) => key.endsWith('_$supplierId'));
    _supplierSearchCache.remove(supplierId);
  }

  /// Invalidate expired search cache entries
  void invalidateSearchCache() {
    final now = DateTime.now();
    _searchCache.removeWhere((key, entry) {
      return now.difference(entry.timestamp) > _cacheDuration;
    });
  }

  // ============ CACHE MANAGEMENT ============

  /// Evict the oldest cache entries when cache is full
  void _evictOldestCacheEntries() {
    if (_searchCache.isEmpty) return;

    // Sort by timestamp and remove oldest
    final sortedKeys = _searchCache.keys.toList()
      ..sort((a, b) =>
          _searchCache[a]!.timestamp.compareTo(_searchCache[b]!.timestamp));

    // Remove oldest 50% of entries
    final toRemove = sortedKeys.take(_maxSearchCacheSize ~/ 2).toList();
    for (final key in toRemove) {
      _searchCache.remove(key);
    }
  }

  /// Generate a consistent cache key from query and supplier ID
  String _generateCacheKey(String query, int supplierId) {
    return 'search_${query.toLowerCase().trim()}_${supplierId ?? 0}';
  }

  // ============ USER INVALIDATION ============

  /// Invalidate all cache entries for a specific user
  void invalidateUser(int userId) {
    // Remove from main caches
    users.remove(userId);
    privileges.remove(userId);
    pendingRules.remove(userId);
    activeRules.remove(userId);
    userSupplierMappings.remove(userId);

    // Remove from search cache
    _searchCache.removeWhere((key, entry) {
      return entry.users.any((u) => u.idAppUser == userId);
    });

    // Remove from supplier search cache
    _supplierSearchCache.removeWhere((_, userIds) {
      return userIds.contains(userId);
    });
  }

  // ============ STATS ============

  Map<String, int> getStats() {
    return {
      'users': users.length,
      'privileges': privileges.length,
      'pendingRules': pendingRules.length,
      'activeRules': activeRules.length,
      'supplierMappings': supplierPersonnelMappings.length,
      'searchCacheEntries': _searchCache.length,
      'supplierSearchCacheEntries': _supplierSearchCache.length,
    };
  }

  // ============ CACHE CLEANUP ============

  /// Clean up expired and orphaned cache entries
  void cleanupCache() {
    // Remove expired search entries
    invalidateSearchCache();

    // Remove orphaned supplier search cache entries
    _supplierSearchCache.removeWhere((supplierId, userIds) {
      // Keep only if supplier has active personnel
      final activeUsers = supplierPersonnelMappings[supplierId] ?? [];
      return userIds.any((id) => !activeUsers.contains(id));
    });
  }
}

// ============ SEARCH CACHE ENTRY ============

class SearchCacheEntry {
  final List<AppUser> users;
  final List<Person> people;
  final DateTime timestamp;

  SearchCacheEntry({
    required this.users,
    required this.people,
    required this.timestamp,
  });

  /// Check if cache entry is still valid (not expired)
  bool isValid({Duration? maxAge}) {
    final age = DateTime.now().difference(timestamp);
    final max = maxAge ?? PersonnelCache._cacheDuration;
    return age < max;
  }

  /// Get total number of results
  int get totalCount => users.length + people.length;

  /// Get all user IDs from this cache entry
  List<int> getUserIds() {
    return users.map((u) => u.idAppUser).whereType<int>().toList();
  }

  /// Get all person IDs from this cache entry
  List<int> getPersonIds() {
    return people.map((p) => p.id_person).whereType<int>().toList();
  }

  @override
  String toString() {
    return 'SearchCacheEntry(users: ${users.length}, people: ${people.length}, '
        'age: ${DateTime.now().difference(timestamp).inSeconds}s)';
  }
}
