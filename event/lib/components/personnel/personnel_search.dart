import 'dart:async';
import 'dart:developer';
import 'package:verdelia_core/app/AppUser.dart';
import 'package:verdelia_core/app/Person.dart';
import 'package:flutter/foundation.dart';
import 'package:verdelia_core/app/Services/UserService.dart';
import 'personnel_cache.dart';
import 'personnel_state.dart';

class PersonnelSearch {
  final AppUserService _userService;
  final PersonnelCache _cache;
  final PersonnelState _state;
  Timer? _debounceTimer;
  String? _lastSearchQuery;
  int? _lastSupplierId;

  static const _itemsPerPage = 50;
  static const _debounceDelayMs = 500;

  PersonnelSearch({
    required AppUserService userService,
    required PersonnelCache cache,
    required PersonnelState state,
  })  : _userService = userService,
        _cache = cache,
        _state = state;

  void dispose() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  void cancelDebounce() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  void clear({int supplierId = 0}) {
    _debounceTimer?.cancel();
    _debounceTimer = null;

    _lastSearchQuery = null;
    _lastSupplierId = null;

    _state.setSearchQuery('');
    _state.searchResults = [];
    _state.personSearchResults = [];
    _state.setError(null);
    _state.setLoading(false);
    _state.hasSearched = false;
  }

  Future<void> search(String query, {int supplierId = 0}) async {
    final trimmed = query.trim();
    _state.setSearchQuery(trimmed);
    _state.hasSearched = trimmed.isNotEmpty;

    _debounceTimer?.cancel();

    if (trimmed.isEmpty) {
      _state.searchResults = [];
      _state.personSearchResults = [];
      _state.setLoading(false);
      _state.setError(null);
      _lastSearchQuery = null;
      _lastSupplierId = null;
      return;
    }

    _lastSearchQuery = trimmed;
    _lastSupplierId = supplierId;

    // Check cache first
    final cached = _cache.getSearchResults(trimmed, supplierId: supplierId);
    if (cached != null && cached.isValid()) {
      log('📦 Using cached search results for: "$trimmed" (${cached.totalCount} results)',
          name: 'PersonnelSearch');
      _updateSearchResults(cached.users, cached.people);
      return;
    }

    _state.setLoading(true);
    _state.searchResults = [];
    _state.personSearchResults = [];
    _state.setError(null);

    _debounceTimer = Timer(
      const Duration(milliseconds: _debounceDelayMs),
      () => _performSearch(trimmed, supplierId),
    );
  }

  Future<void> _performSearch(String query, int supplierId) async {
    if (_lastSearchQuery != query || _lastSupplierId != supplierId) {
      log('⏭️ Skipping outdated search for: "$query"', name: 'PersonnelSearch');
      return;
    }

    try {
      log('🔍 Performing search for: "$query" (supplier: $supplierId)',
          name: 'PersonnelSearch');

      final results = await Future.wait([
        _searchAppUsers(query, supplierId),
        _searchPeople(query, supplierId),
      ]);

      final users = results[0] as List<AppUser>? ?? [];
      final people = results[1] as List<Person>? ?? [];

      // Cache users individually
      _cache.cacheUsersBatch(users);

      // Update state
      _updateSearchResults(users, people);

      // Cache results
      _cache.cacheSearchResults(
        query,
        users: users,
        people: people,
        supplierId: supplierId,
      );

      _state.setError(null);

      log('✅ Search completed: ${users.length} users, ${people.length} people',
          name: 'PersonnelSearch');
    } catch (e, stackTrace) {
      log('❌ Search failed: $e',
          name: 'PersonnelSearch', error: e, stackTrace: stackTrace);
      _state.setError('Search failed: ${e.toString()}');
      _state.searchResults = [];
      _state.personSearchResults = [];
    } finally {
      _state.setLoading(false);
    }
  }

  void _updateSearchResults(List<AppUser> users, List<Person> people) {
    _state.searchResults = users;
    _state.personSearchResults = people;
  }

  Future<List<AppUser>?> _searchAppUsers(String query, int supplierId) async {
    try {
      final results = await _userService.searchAppUsers(
        query,
        0,
        _itemsPerPage,
      );

      // Cache users from results
      if (results != null) {
        _cache.cacheUsersBatch(results);
      }

      return results;
    } catch (e) {
      log('Error searching app users: $e', name: 'PersonnelSearch');
      return [];
    }
  }

  Future<List<Person>?> _searchPeople(String query, int supplierId) async {
    try {
      final results = await _userService.searchPeople(
        query,
        0,
        _itemsPerPage,
      );
      return results;
    } catch (e) {
      log('Error searching people: $e', name: 'PersonnelSearch');
      return [];
    }
  }

  List<AppUser> getActiveUsersForSupplier(int supplierId) {
    if (supplierId == 0) {
      return _cache.activeRules.keys
          .map((userId) => _cache.getUser(userId))
          .whereType<AppUser>()
          .toList();
    }

    final userIds = _cache.getActiveUserIdsForSupplier(supplierId);
    return userIds
        .map((id) => _cache.getUser(id))
        .whereType<AppUser>()
        .toList();
  }
}
