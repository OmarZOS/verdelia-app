// personnel_rules.dart

import 'dart:developer';

import 'package:app_constants/app_constants.dart';
import 'package:verdelia_core/app/ManagementRule.dart';
import 'package:verdelia_core/business/privileges/role_bit_mapper.dart';
import 'personnel_cache.dart';
import 'personnel_state.dart';
import 'personnel_persistence.dart';

class PersonnelRules {
  final PersonnelCache _cache;
  final PersonnelState _state;
  final PersonnelPersistence _persistence;

  PersonnelRules({
    required PersonnelCache cache,
    required PersonnelState state,
    required PersonnelPersistence persistence,
  })  : _cache = cache,
        _state = state,
        _persistence = persistence;

  List<ManagementRule> getRulesForUser(int userId, {int supplierId = 0}) {
    final rules = _cache.getActiveRules(userId);
    if (rules == null) return const [];
    if (supplierId == 0) return List.from(rules);

    return rules
        .where((rule) => rule.productProvider?.idProductProvider == supplierId)
        .toList();
  }

  List<ManagementRule> getPendingRulesForUser(int userId,
      {int supplierId = 0}) {
    final rules = _cache.getPendingRules(userId);
    if (rules == null) return const [];
    if (supplierId == 0) return List.from(rules);

    return rules
        .where((rule) => rule.productProvider?.idProductProvider == supplierId)
        .toList();
  }

  bool hasPrivilege(int userId, int supplierId, String privilegeId) {
    final rules = getRulesForUser(userId, supplierId: supplierId);
    return rules.any((rule) =>
        RoleBitMapper.hasPrivilege(rule.managementRuleCode ?? 0, privilegeId));
  }

  bool hasAnyAccessToSupplier(int userId, int supplierId) {
    final rules = getRulesForUser(userId, supplierId: supplierId);
    return rules.isNotEmpty;
  }

  bool hasPendingRulesForSupplier(int userId, int supplierId) {
    final rules = _cache.getPendingRules(userId);
    if (rules == null) return false;
    return rules
        .any((rule) => rule.productProvider?.idProductProvider == supplierId);
  }

  ManagementRule? getRuleForUser({
    required int userId,
    int ruleId = 0,
    int supplierId = 0,
  }) {
    final rules = _cache.getPrivileges(userId);
    if (rules == null) return null;

    return rules.firstWhere(
      (rule) {
        final matchesRuleId = ruleId == 0 || rule.idManagementRule == ruleId;
        final matchesSupplier = supplierId == 0 ||
            rule.productProvider?.idProductProvider == supplierId;
        return matchesRuleId && matchesSupplier;
      },
    );
  }

  /// Sync a single rule state
  void syncRuleState(ManagementRule updatedRule) {
    final ruleId = updatedRule.idManagementRule;
    final userId = updatedRule.appUser?.idAppUser;
    if (ruleId == null || userId == null) {
      _logWarning('Cannot sync rule: missing ruleId or userId');
      return;
    }

    if (_state.isRebuildingState) {
      _logWarning('Already rebuilding state, skipping sync for rule $ruleId');
      return;
    }

    _state.isRebuildingState = true;

    try {
      // Get existing privileges for the user
      final privileges = _cache.privileges[userId] ?? [];
      int existingIndex = -1;

      // Find if rule already exists
      for (int i = 0; i < privileges.length; i++) {
        if (privileges[i].idManagementRule == ruleId) {
          existingIndex = i;
          break;
        }
      }

      // Update or add the rule
      if (existingIndex >= 0) {
        privileges[existingIndex] = updatedRule;
        _logDebug('Updated existing rule $ruleId for user $userId');
      } else {
        privileges.add(updatedRule);
        _logDebug('Added new rule $ruleId for user $userId');
      }

      // Cache the updated privileges
      _cache.cachePrivileges(userId, privileges);

      // Rebuild user state to update active/pending rules
      _rebuildUserState(userId);
    } finally {
      _state.isRebuildingState = false;
    }
  }

  /// Sync multiple rules at once (batch)
  void syncRulesBatch(List<ManagementRule> rules) {
    if (rules.isEmpty) {
      _logDebug('No rules to sync');
      return;
    }

    _logInfo('Syncing ${rules.length} rules in batch');
    _state.isRebuildingState = true;

    try {
      // Group rules by userId
      final rulesByUser = <int, List<ManagementRule>>{};

      for (final rule in rules) {
        final userId = rule.appUser?.idAppUser;
        if (userId == null) {
          _logWarning('Rule ${rule.idManagementRule} has no userId, skipping');
          continue;
        }

        rulesByUser.putIfAbsent(userId, () => []).add(rule);
      }

      // Process each user's rules
      for (final entry in rulesByUser.entries) {
        final userId = entry.key;
        final userRules = entry.value;

        // Get existing privileges
        final privileges = _cache.privileges[userId] ?? [];

        // Update or add each rule
        for (final rule in userRules) {
          final ruleId = rule.idManagementRule;
          if (ruleId == null) continue;

          int existingIndex = -1;
          for (int i = 0; i < privileges.length; i++) {
            if (privileges[i].idManagementRule == ruleId) {
              existingIndex = i;
              break;
            }
          }

          if (existingIndex >= 0) {
            privileges[existingIndex] = rule;
          } else {
            privileges.add(rule);
          }
        }

        // Cache and rebuild
        _cache.cachePrivileges(userId, privileges);
        _rebuildUserState(userId);
        _logInfo('Synced ${userRules.length} rules for user $userId');
      }
    } finally {
      _state.isRebuildingState = false;
    }
  }

  void _rebuildUserState(int userId) {
    final rules = _cache.getPrivileges(userId);
    if (rules == null || rules.isEmpty) {
      _cache.pendingRules.remove(userId);
      _cache.activeRules.remove(userId);
      _cache.userSupplierMappings.remove(userId);
      _logDebug('Removed empty state for user $userId');
      return;
    }

    final pending = <ManagementRule>[];
    final active = <ManagementRule>[];
    final userSuppliers = <int>{};

    for (final rule in rules) {
      final providerId = rule.productProvider?.idProductProvider;
      final status = rule.managementRuleStatus ?? "";
      final isPending = status.toUpperCase() == RuleStates.pending;

      if (isPending) {
        pending.add(rule);
        _logDebug('Rule ${rule.idManagementRule} is PENDING');
      } else {
        active.add(rule);
        _logDebug('Rule ${rule.idManagementRule} is ACTIVE');
        if (providerId != null && providerId > 0) {
          userSuppliers.add(providerId);
          _cache.addSupplierMapping(userId, providerId);
          _persistence.addSupplier(userId, providerId);
        }
      }
    }

    _cache.cachePendingRules(userId, pending);
    _cache.cacheActiveRules(userId, active);
    _cache.userSupplierMappings[userId] = userSuppliers.toList();

    _logInfo(
        'Rebuilt user $userId state: ${active.length} active, ${pending.length} pending, ${userSuppliers.length} suppliers');
  }

  Map<String, int> getSupplierStats(int supplierId) {
    final userIds = _cache.getActiveUserIdsForSupplier(supplierId);
    int admins = 0;
    int managers = 0;

    for (final userId in userIds) {
      final user = _cache.getUser(userId);
      if (user != null) {
        if (user.isAdmin) {
          admins++;
        } else if (user.appUserType?.toString().contains('manager') ?? false) {
          managers++;
        }
      }
    }

    final pendingUsers = _cache.pendingRules.keys
        .where((userId) =>
            _cache.pendingRules[userId]?.any((rule) =>
                rule.productProvider?.idProductProvider == supplierId) ??
            false)
        .length;

    return {
      'active': userIds.length,
      'pending': pendingUsers,
      'admins': admins,
      'managers': managers,
      'total': userIds.length + pendingUsers,
    };
  }

  // ============ LOGGING HELPERS ============

  void _logInfo(String message) {
    log(message, name: 'PersonnelRules', level: 0);
  }

  void _logWarning(String message) {
    log(message, name: 'PersonnelRules', level: 1);
  }

  void _logDebug(String message) {
    log(message, name: 'PersonnelRules', level: 0);
  }
}
