import 'dart:developer';
import 'package:event/TraceableNotifier.dart';
import 'package:event/components/personnel/personnel_cache.dart';
import 'package:event/components/personnel/personnel_crud.dart';
import 'package:event/components/personnel/personnel_persistence.dart';
import 'package:event/components/personnel/personnel_rules.dart';
import 'package:event/components/personnel/personnel_search.dart';
import 'package:event/components/personnel/personnel_state.dart';
import 'package:verdelia_core/app/AppUser.dart';
import 'package:verdelia_core/app/ManagementRule.dart';
import 'package:verdelia_core/app/Person.dart';
import 'package:verdelia_core/app/Services/UserService.dart';
import 'package:verdelia_core/business/finance/Customer.dart';
import 'package:verdelia_core/mediation/StorageService.dart';
import 'package:locator/locator.dart';

class PersonnelNotifier extends TraceableNotifier {
  final AppUserService _userService;
  final StorageService _storageService;

  // Components
  late final PersonnelState _state;
  late final PersonnelCache _cache;
  late final PersonnelPersistence _persistence;
  late final PersonnelRules _rules;
  late final PersonnelSearch _search;
  late final PersonnelCrud _crud;

  PersonnelNotifier({
    AppUserService? userService,
    StorageService? storageService,
  })  : _userService = userService ?? AppLocator.get<AppUserService>(),
        _storageService = storageService ?? AppLocator.get<StorageService>() {
    _initComponents();
    _loadPersistedData();
    _logInfo('PersonnelNotifier initialized');
  }

  void _initComponents() {
    _state = PersonnelState();
    _cache = PersonnelCache();
    _persistence = PersonnelPersistence();
    _rules = PersonnelRules(
      cache: _cache,
      state: _state,
      persistence: _persistence,
    );
    _search = PersonnelSearch(
      userService: _userService,
      cache: _cache,
      state: _state,
    );
    _crud = PersonnelCrud(
      userService: _userService,
      storageService: _storageService,
      cache: _cache,
      state: _state,
      rules: _rules,
      persistence: _persistence,
    );
  }

  Future<void> _loadPersistedData() async {
    await _persistence.load();
    _logInfo('Persisted data loaded');
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
    _logInfo('PersonnelNotifier disposed');
  }

  void _notify() {
    if (!_state.isLoading) {
      notifyListeners();
    }
  }

  // ============ LOGGING HELPERS ============

  void _logInfo(String message) {
    log(message, name: 'PersonnelNotifier', level: 0);
  }

  void _logWarning(String message) {
    log(message, name: 'PersonnelNotifier', level: 1);
  }

  void _logError(String message, {Object? error, StackTrace? stackTrace}) {
    log(
      message,
      name: 'PersonnelNotifier',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
  }

  void _logDebug(String message) {
    log(message, name: 'PersonnelNotifier', level: 0);
  }

  // ============ PUBLIC GETTERS ============

  List<AppUser> get personnel => _state.personnel;
  List<AppUser> get searchResults => _state.searchResults;
  List<Person> get personSearchResults => _state.personSearchResults;
  bool get isLoading => _state.isLoading;
  String get searchQuery => _state.searchQuery;
  String? get error => _state.error;
  bool get hasMore => _state.hasMore;
  Map<int, List<int>> get accessibleSuppliers => _persistence.all;

  int get totalCount {
    final uniqueUserIds = <int>{};
    for (final userIds in _cache.supplierPersonnelMappings.values) {
      uniqueUserIds.addAll(userIds);
    }
    return uniqueUserIds.length;
  }

  // ============ USER CONTEXT ============

  Future<void> updatePersistedAccessibleSuppliers(
    int userId,
    List<int> supplierIds,
  ) async {
    _logInfo(
        'Updating persisted accessible suppliers for user $userId: $supplierIds');

    // Update persistence
    await _persistence.updateSuppliers(userId, supplierIds);

    _logInfo('Persisted accessible suppliers updated for user $userId');
  }

  /// Add a supplier to persisted accessible suppliers for a user
  Future<void> addPersistedAccessibleSupplier(
    int userId,
    int supplierId,
  ) async {
    _logInfo(
        'Adding persisted accessible supplier for user $userId: $supplierId');
    await _persistence.addSupplier(userId, supplierId);
  }

  /// Remove a supplier from persisted accessible suppliers for a user
  Future<void> removePersistedAccessibleSupplier(
    int userId,
    int supplierId,
  ) async {
    _logInfo(
        'Removing persisted accessible supplier for user $userId: $supplierId');
    await _persistence.removeSupplier(userId, supplierId);
  }

  /// Get accessible suppliers for a user from persistence
  List<int> getPersistedAccessibleSuppliers(int userId) {
    final suppliers = _persistence.getAccessibleSuppliers(userId);
    _logDebug('Retrieved persisted suppliers for user $userId: $suppliers');
    return suppliers;
  }

  /// Clear all persisted accessible suppliers
  Future<void> clearPersistedAccessibleSuppliers() async {
    _logInfo('Clearing all persisted accessible suppliers');
    await _persistence.clearAll();
    _notify();
  }

  /// Get all persisted accessible suppliers
  Map<int, List<int>> getAllPersistedAccessibleSuppliers() {
    return Map.unmodifiable(_persistence.all);
  }

  void setCurrentUserId(int userId) {
    _logInfo('Setting current user ID: $userId');
    _persistence.setCurrentUser(userId);
  }

  Future<void> clearPersistedData() async {
    _logInfo('Clearing persisted data');
    await _persistence.clear();
    _cache.clearAll();
    _notify();
  }

  // ============ ACCESSIBLE SUPPLIERS ============

  /// Get accessible supplier IDs for a user
  List<int> getAccessibleSupplierIds(int userId) {
    // Only return IDs from rules, NOT suppliers
    final rules = _rules.getRulesForUser(userId);
    return rules
        .map((rule) => rule.productProvider?.idProductProvider)
        .where((id) => id != null && id > 0)
        .cast<int>()
        .toList();
  }

  /// Check if a user has access to a supplier
  bool hasAccessToSupplier(int userId, int supplierId) {
    return _rules.hasAnyAccessToSupplier(userId, supplierId);
  }

  // ============ RULES & PRIVILEGES ============

  List<ManagementRule> getRulesForUser(int userId, {int supplierId = 0}) {
    final rules = _rules.getRulesForUser(userId, supplierId: supplierId);
    _logDebug(
        'Retrieved ${rules.length} rules for user $userId${supplierId > 0 ? ', supplier $supplierId' : ''}');
    return rules;
  }

  List<ManagementRule> getPendingRulesForUser(int userId,
      {int supplierId = 0}) {
    final rules = _rules.getPendingRulesForUser(userId, supplierId: supplierId);
    _logDebug(
        'Retrieved ${rules.length} pending rules for user $userId${supplierId > 0 ? ', supplier $supplierId' : ''}');
    return rules;
  }

  bool hasPrivilege(int userId, int supplierId, String privilegeId) {
    final result = _rules.hasPrivilege(userId, supplierId, privilegeId);
    _logDebug(
        'Privilege check for user $userId, supplier $supplierId, privilege $privilegeId: $result');
    return result;
  }

  bool hasAnyAccessToSupplier(int userId, int supplierId) {
    final result = _rules.hasAnyAccessToSupplier(userId, supplierId);
    _logDebug('Access check for user $userId, supplier $supplierId: $result');
    return result;
  }

  bool hasPendingRulesForSupplier(int userId, int supplierId) {
    final result = _rules.hasPendingRulesForSupplier(userId, supplierId);
    _logDebug(
        'Pending rules check for user $userId, supplier $supplierId: $result');
    return result;
  }

  ManagementRule? getRuleForUser({
    required int userId,
    int ruleId = 0,
    int supplierId = 0,
  }) {
    final rule = _rules.getRuleForUser(
      userId: userId,
      ruleId: ruleId,
      supplierId: supplierId,
    );
    if (rule != null) {
      _logDebug(
          'Found rule for user $userId${ruleId > 0 ? ", rule $ruleId" : ""}: ${rule.idManagementRule}');
    } else {
      _logDebug(
          'No rule found for user $userId${ruleId > 0 ? ", rule $ruleId" : ""}');
    }
    return rule;
  }

  Map<String, int> getSupplierStats(int supplierId) {
    final stats = _rules.getSupplierStats(supplierId);
    _logDebug('Retrieved stats for supplier $supplierId: $stats');
    return stats;
  }

  void syncRuleState(ManagementRule updatedRule) {
    _logInfo('Syncing rule state for rule ${updatedRule.idManagementRule}');
    _rules.syncRuleState(updatedRule);
    _notify();
  }

  // ============ PERSONNEL ============

  List<AppUser> getPersonnelForSupplier(int supplierId,
      {bool includePending = false}) {
    final activeUsers = _getActiveUsersForSupplier(supplierId);
    if (!includePending) return activeUsers;

    final pendingUsers = _getPendingUsersForSupplier(supplierId);
    if (pendingUsers.isEmpty) return activeUsers;

    final activeIds = activeUsers.map((user) => user.idAppUser ?? 0).toSet();
    final allUsers = List<AppUser>.from(activeUsers);

    for (final user in pendingUsers) {
      if (!activeIds.contains(user.idAppUser)) {
        allUsers.add(user);
      }
    }

    _logDebug(
        'Retrieved ${allUsers.length} personnel for supplier $supplierId${includePending ? ' (including pending)' : ''}');
    return allUsers;
  }

  List<AppUser> _getActiveUsersForSupplier(int supplierId) {
    if (supplierId == 0) {
      final users = _cache.activeRules.keys
          .map((userId) => _cache.getUser(userId))
          .whereType<AppUser>()
          .toList();
      _logDebug('Retrieved ${users.length} active users across all suppliers');
      return users;
    }

    final userIds = _cache.getActiveUserIdsForSupplier(supplierId);
    final users =
        userIds.map((id) => _cache.getUser(id)).whereType<AppUser>().toList();
    _logDebug(
        'Retrieved ${users.length} active users for supplier $supplierId');
    return users;
  }

  List<AppUser> _getPendingUsersForSupplier(int supplierId) {
    final pendingUsers = <AppUser>[];

    for (final entry in _cache.pendingRules.entries) {
      final userId = entry.key;
      final rules = entry.value;

      final hasSupplierRule = rules.any((rule) {
        final providerId = rule.productProvider?.idProductProvider;
        return providerId == supplierId || supplierId == 0;
      });

      if (hasSupplierRule) {
        final user = _cache.getUser(userId);
        if (user != null) pendingUsers.add(user);
      }
    }

    _logDebug(
        'Retrieved ${pendingUsers.length} pending users for supplier $supplierId');
    return pendingUsers;
  }

  // ============ CUSTOMER ============

  Future<Customer?> getCustomerDisplayInfo({
    required int customerId,
    required String customerType,
    int? personId,
    String? callerKey,
  }) async {
    final key = callerKey ??
        _generateKey('getCustomerDisplayInfo', id: customerId.toString());

    _logInfo('Getting customer info for ID: $customerId, type: $customerType');

    try {
      if (customerType == 'user') {
        final user = await _userService.getAppUser(customerId.toString());
        if (user != null) {
          _storeSuccess(key, user, responseCode: 'USER_FOUND');
          _logInfo('Found user customer: ${user.appUserName}');
          return Customer.fromUser(user);
        }
        _logWarning('User not found for ID: $customerId');
      } else if (customerType == 'person' && personId != null) {
        final person = await _userService.getPerson(personId.toString());
        if (person != null) {
          _storeSuccess(key, person, responseCode: 'PERSON_FOUND');
          _logInfo('Found person customer: ${person.fullName}');
          return Customer.fromPerson(person);
        }
        _logWarning('Person not found for ID: $personId');
      } else {
        final customer = Customer.fromJson({
          'name': 'Customer #$customerId',
          'type': customerType,
          'email': '',
        });
        _storeSuccess(key, customer, responseCode: 'DEFAULT_CUSTOMER');
        _logInfo('Created default customer for ID: $customerId');
        return customer;
      }

      _storeFailure(key, null,
          statusCode: 404, responseCode: 'CUSTOMER_NOT_FOUND');
      _logWarning(
          'Customer not found for ID: $customerId, type: $customerType');
      return null;
    } catch (e) {
      _storeFailure(key, e.toString(), responseCode: 'CUSTOMER_FETCH_ERROR');
      _logError('Error fetching customer info', error: e);
      return null;
    }
  }

  // ============ TEAM MANAGEMENT ============

  Future<bool> addTeamMember(
    int userId, {
    int supplierId = 0,
    int orgId = 0,
    int privilege = 0,
    bool fromQR = false,
    String? callerKey,
  }) async {
    _logInfo(
        'Adding team member: user $userId, supplier $supplierId, org $orgId, privilege $privilege${fromQR ? ' (from QR)' : ''}');

    final result = await _crud.addTeamMember(
      userId,
      supplierId: supplierId,
      orgId: orgId,
      privilege: privilege,
      fromQR: fromQR,
      callerKey: callerKey,
    );

    _logInfo('Team member added: $result');
    _notify();
    return result;
  }

  Future<bool> updateTeamMemberPrivileges({
    required int ruleId,
    required int userId,
    required int supplierId,
    required int orgId,
    required int privilege,
    String? callerKey,
  }) async {
    _logInfo(
        'Updating team member privileges: rule $ruleId, user $userId, supplier $supplierId, privilege $privilege');

    final result = await _crud.updatePrivileges(
      ruleId: ruleId,
      userId: userId,
      supplierId: supplierId,
      orgId: orgId,
      privilege: privilege,
      callerKey: callerKey,
    );

    _logInfo('Team member privileges updated: $result');
    _notify();
    return result;
  }

  Future<bool> removeUserFromSupplier(
    int ruleId,
    int userId,
    int supplierId, {
    String? callerKey,
  }) async {
    _logInfo('Removing user $userId from supplier $supplierId (rule $ruleId)');

    final result = await _crud.removeUserFromSupplier(
      ruleId,
      userId,
      supplierId,
      callerKey: callerKey,
    );

    _logInfo('User removed from supplier: $result');
    _notify();
    return result;
  }

  // ============ SEARCH ============

  void clearSearch({int supplierId = 0}) {
    _logDebug(
        'Clearing search${supplierId > 0 ? ' for supplier $supplierId' : ''}');
    _search.clear(supplierId: supplierId);
    _notify();
  }

  Future<void> searchPersonnel(String query, {int supplierId = 0}) async {
    _logDebug(
        'Searching personnel for query: "$query"${supplierId > 0 ? ', supplier $supplierId' : ''}');
    final searchFuture = _search.search(query, supplierId: supplierId);
    _notify();
    await searchFuture;
    _notify();
  }

  // ============ LOADING ============

  /// Load personnel with proper user caching
  Future<void> loadPersonnel({
    int userId = 0,
    bool reset = false,
    int supplierId = 0,
    bool includePending = false,
    String? callerKey,
  }) async {
    final key = callerKey ?? _generateKey('loadPersonnel');

    _logInfo(
        'Loading personnel - userId: $userId, reset: $reset, supplierId: $supplierId, includePending: $includePending');

    if (_state.isLoading && !reset) {
      _logWarning('Already loading personnel, skipping request');
      return;
    }

    if (reset) {
      _state.resetPagination();
      _logDebug('Pagination reset');
    }

    _state.setLoading(true);

    try {
      final rules = await _userService.getManagementRules(
        0,
        supplierId,
        userId,
        _state.currentPage * 50,
        50,
      );

      if (rules == null || rules.isEmpty) {
        _state.hasMore = false;
        _logInfo('No more rules to load');
      } else {
        _logInfo('Loaded ${rules.length} rules');

        // 👇 CRITICAL FIX: Extract and cache users from rules
        final users = _extractUsersFromRules(rules);
        _logInfo('Extracted ${users.length} users from rules');

        // Cache users
        for (final user in users) {
          if (user.idAppUser != null && user.idAppUser! > 0) {
            _cache.cacheUser(user);
            _logDebug(
                'Cached user: ${user.displayName} (ID: ${user.idAppUser})');
          }
        }

        // Also cache users from pending rules if included
        if (includePending) {
          final pendingRules = rules.where((r) => r.isPending).toList();
          if (pendingRules.isNotEmpty) {
            final pendingUsers = _extractUsersFromRules(pendingRules);
            for (final user in pendingUsers) {
              if (user.idAppUser != null && user.idAppUser! > 0) {
                _cache.cacheUser(user);
                _logDebug(
                    'Cached pending user: ${user.displayName} (ID: ${user.idAppUser})');
              }
            }
          }
        }

        // Use batch sync for better performance
        _rules.syncRulesBatch(rules);

        // Update personnel list
        _state.personnel.addAll(users);
        _state.currentPage++;
      }

      _state.setError(null);
      _storeSuccess(key, _state.personnel, responseCode: 'PERSONNEL_LOADED');
      _logInfo(
          'Personnel loaded successfully, total: ${_state.personnel.length}');
    } catch (e, stackTrace) {
      _state.setError('Failed to load personnel: ${e.toString()}');
      _storeFailure(key, e.toString(), responseCode: 'LOAD_PERSONNEL_ERROR');
      _logError('Failed to load personnel', error: e, stackTrace: stackTrace);
    } finally {
      _state.setLoading(false);
      _notify();
    }
  }

  /// Extract AppUser objects from ManagementRule list
  List<AppUser> _extractUsersFromRules(List<ManagementRule> rules) {
    final users = <AppUser>[];
    final seenUserIds = <int>{};

    for (final rule in rules) {
      final user = rule.appUser;
      if (user != null && user.idAppUser != null && user.idAppUser! > 0) {
        if (!seenUserIds.contains(user.idAppUser)) {
          seenUserIds.add(user.idAppUser!);
          users.add(user);
        }
      }
    }

    return users;
  }

  // ============ CACHE MANAGEMENT ============

  void clearAllCache() {
    _logInfo('Clearing all cache');
    _cache.clearAll();
    _state.reset();
    _notify();
  }

  void logCacheStats() {
    final stats = _cache.getStats();
    _logInfo('''
    PersonnelNotifier Cache Stats:
    - Users: ${stats['users']}
    - Privileges: ${stats['privileges']}
    - Pending Rules: ${stats['pendingRules']}
    - Active Rules: ${stats['activeRules']}
    - Supplier Mappings: ${stats['supplierMappings']}
    - Personnel: ${_state.personnel.length}
    - Persisted Suppliers: ${_persistence.all.length}
    ''');
  }

  // ============ HELPERS ============

  String _generateKey(String operation, {String? id, String? suffix}) {
    final parts = [operation];
    if (id != null) parts.add(id);
    if (suffix != null) parts.add(suffix);
    parts.add(DateTime.now().millisecondsSinceEpoch.toString());
    return parts.join('_');
  }

  void _storeSuccess(String key, data,
      {int? statusCode, String? responseCode}) {
    _storageService.setSuccessResponse(key, data,
        statusCode: statusCode ?? 200, responseCode: responseCode);
    _logDebug('Stored success response for key: $key');
  }

  void _storeFailure(String key, data,
      {int? statusCode, String? responseCode}) {
    _storageService.setFailureResponse(key,
        data: data,
        statusCode: statusCode ?? 500,
        errorCode: responseCode,
        message: data.toString());
    _logDebug('Stored failure response for key: $key');
  }

  // ============ RESET ============

  void reset() {
    _logInfo('Resetting PersonnelNotifier');
    _state.reset();
    _cache.clearAll();
    _notify();
  }

  // ============ INVITATION MANAGEMENT ============

  Future<bool> answerInvitation({
    required int ruleId,
    required int answer,
    String? callerKey,
    String? token,
  }) async {
    final key =
        callerKey ?? _generateKey('answerInvitation', id: ruleId.toString());

    _logInfo(
        'Answering invitation - ruleId: $ruleId, answer: ${answer == 0 ? 'ACCEPT' : 'REJECT'}');

    try {
      final result = await _crud.answerInvitation(
          ruleId: ruleId, answer: answer, callerKey: key, token: token);

      _logInfo('Invitation answered successfully: $result');
      _notify();
      return result;
    } catch (e, stackTrace) {
      _storeFailure(key, e.toString(), responseCode: 'ANSWER_INVITATION_ERROR');
      _logError('Failed to answer invitation',
          error: e, stackTrace: stackTrace);
      return false;
    }
  }
}
