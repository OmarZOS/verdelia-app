import 'dart:developer';
import 'package:app_constants/app_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:verdelia_core/app/AppUser.dart';
import 'package:verdelia_core/app/ManagementRule.dart';
import 'package:verdelia_core/app/Services/UserService.dart';
import 'package:verdelia_core/mediation/StorageService.dart';
import 'personnel_cache.dart';
import 'personnel_state.dart';
import 'personnel_rules.dart';
import 'personnel_persistence.dart';

class PersonnelCrud {
  final AppUserService _userService;
  final StorageService _storageService;
  final PersonnelCache _cache;
  final PersonnelState _state;
  final PersonnelRules _rules;
  final PersonnelPersistence _persistence;

  PersonnelCrud({
    required AppUserService userService,
    required StorageService storageService,
    required PersonnelCache cache,
    required PersonnelState state,
    required PersonnelRules rules,
    required PersonnelPersistence persistence,
  })  : _userService = userService,
        _storageService = storageService,
        _cache = cache,
        _state = state,
        _rules = rules,
        _persistence = persistence;

  Future<bool> addTeamMember(
    int userId, {
    int supplierId = 0,
    int orgId = 0,
    int privilege = 0,
    bool fromQR = false,
    String? callerKey,
  }) async {
    final key =
        callerKey ?? _generateKey('addTeamMember', id: userId.toString());

    if (_state.isLoading) {
      _storeFailure(key, null,
          statusCode: 429, responseCode: 'ALREADY_LOADING');
      return false;
    }

    _state.setLoading(true);

    try {
      await _userService.addUserToSupplier(
        userId,
        supplierId,
        orgId,
        privilege,
        fromQR: fromQR,
        callerKey: key,
      );

      if (supplierId > 0) {
        await _persistence.addSupplier(userId, supplierId);
      }

      _storeSuccess(key, true, responseCode: 'TEAM_MEMBER_ADDED');
      return true;
    } catch (e) {
      _state.setError('Failed to add team member: ${e.toString()}');
      _storeFailure(key, e.toString(), responseCode: 'ADD_TEAM_MEMBER_FAILED');
      return false;
    } finally {
      _state.setLoading(false);
    }
  }

  Future<bool> updatePrivileges({
    required int ruleId,
    required int userId,
    required int supplierId,
    required int orgId,
    required int privilege,
    String? callerKey,
  }) async {
    final key =
        callerKey ?? _generateKey('updatePrivileges', id: ruleId.toString());

    if (_state.isLoading) {
      _storeFailure(key, null,
          statusCode: 429, responseCode: 'ALREADY_LOADING');
      return false;
    }

    _state.setLoading(true);

    try {
      final updatedRule = await _userService.updateManagementRule(
        ruleId,
        userId,
        supplierId,
        orgId,
        privilege,
        callerKey: key,
      );

      if (updatedRule == null) {
        _storeFailure(key, null, responseCode: 'UPDATE_RULE_NULL');
        return false;
      }

      _rules.syncRuleState(updatedRule);

      if (supplierId > 0) {
        await _persistence.addSupplier(userId, supplierId);
      }

      _storeSuccess(key, updatedRule, responseCode: 'PRIVILEGES_UPDATED');
      return true;
    } catch (e) {
      _state.setError('Failed to update privileges: ${e.toString()}');
      _storeFailure(key, e.toString(),
          responseCode: 'UPDATE_PRIVILEGES_FAILED');
      return false;
    } finally {
      _state.setLoading(false);
    }
  }

  Future<bool> removeUserFromSupplier(
    int ruleId,
    int userId,
    int supplierId, {
    String? callerKey,
  }) async {
    final key = callerKey ?? _generateKey('removeUser', id: ruleId.toString());

    // Remove rule from cache
    final privileges = _cache.getPrivileges(userId);
    if (privileges != null) {
      privileges.removeWhere((r) => r.idManagementRule == ruleId);
      if (privileges.isEmpty) {
        _cache.privileges.remove(userId);
      }
    }

    await _persistence.removeSupplier(userId, supplierId);
    _rebuildUserState(userId);

    try {
      await _userService.deleteManagementRule(ruleId, callerKey: key);
      _storeSuccess(key, true, responseCode: 'USER_REMOVED');
      return true;
    } catch (e) {
      _storeFailure(key, e.toString(), responseCode: 'REMOVE_USER_FAILED');
      return false;
    }
  }

  void _rebuildUserState(int userId) {
    final rules = _cache.getPrivileges(userId);
    if (rules == null) {
      _cache.pendingRules.remove(userId);
      _cache.activeRules.remove(userId);
      _cache.userSupplierMappings.remove(userId);
      return;
    }

    final pending = <ManagementRule>[];
    final active = <ManagementRule>[];
    final userSuppliers = <int>{};

    for (final rule in rules) {
      final providerId = rule.productProvider?.idProductProvider;
      final isPending =
          (rule.managementRuleStatus ?? "").toUpperCase() == RuleStates.pending;

      if (isPending) {
        pending.add(rule);
      } else {
        active.add(rule);
        if (providerId != null && providerId > 0) {
          userSuppliers.add(providerId);
          _cache.addSupplierMapping(userId, providerId);
        }
      }
    }

    _cache.cachePendingRules(userId, pending);
    _cache.cacheActiveRules(userId, active);
    _cache.userSupplierMappings[userId] = userSuppliers.toList();
  }

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
  }

  void _storeFailure(String key, data,
      {int? statusCode, String? responseCode}) {
    _storageService.setFailureResponse(key,
        data: data,
        statusCode: statusCode ?? 500,
        errorCode: responseCode,
        message: data.toString());
  }

  Future<bool> answerInvitation({
    required int ruleId,
    required int answer,
    String? callerKey,
    String? token,
  }) async {
    final key =
        callerKey ?? _generateKey('answerInvitation', id: ruleId.toString());

    if (_state.isLoading) {
      _storeFailure(key, null,
          statusCode: 429, responseCode: 'ALREADY_LOADING');
      return false;
    }

    _state.setLoading(true);

    try {
      final result = await _storageService.update(
          "${AppConstants.apiBaseUrl}${AppConstants.answerStaffInvitationEndpoint}",
          ruleId.toString(),
          {"accept": answer == 0},
          {},
          callerKey: key,
          token: token);

      final statusCode = _storageService.getStatusCode(key);
      final responseCode = _storageService.getResponseCode(key);

      if (statusCode != null && (statusCode < 200 || statusCode >= 300)) {
        _storeFailure(key, result,
            statusCode: statusCode, responseCode: responseCode ?? 'API_ERROR');
        return false;
      }

      // Find and update the rule
      final findResult = _findRuleAndUserId(ruleId);
      if (findResult == null) {
        _storeFailure(key, null,
            statusCode: 404, responseCode: 'RULE_NOT_FOUND');
        return false;
      }

      final (targetRule, targetUserId) = findResult;
      final supplierId = targetRule.productProvider?.idProductProvider;
      final pendingList = _cache.getPendingRules(targetUserId);

      if (pendingList == null) {
        _storeFailure(key, null,
            statusCode: 404, responseCode: 'NO_PENDING_RULES');
        return false;
      }

      final index = pendingList.indexWhere((r) =>
          r.idManagementRule == ruleId &&
          r.productProvider?.idProductProvider == supplierId);

      if (index == -1) {
        _storeFailure(key, null,
            statusCode: 404, responseCode: 'RULE_NOT_IN_PENDING');
        return false;
      }

      if (answer == 0) {
        await _acceptInvitation(
            targetUserId, pendingList, index, targetRule, supplierId);
      } else {
        _rejectInvitation(targetUserId, pendingList, index, ruleId);
      }

      if (answer == 0 && supplierId != null) {
        await _persistence.addSupplier(targetUserId, supplierId);
      }

      _storeSuccess(key, true, responseCode: 'INVITATION_ANSWERED');
      return true;
    } catch (e) {
      _storeFailure(key, e.toString(), responseCode: 'ANSWER_INVITATION_ERROR');
      return false;
    } finally {
      _state.setLoading(false);
    }
  }

// Helper methods for answerInvitation
  (ManagementRule, int)? _findRuleAndUserId(int ruleId) {
    for (final entry in _cache.privileges.entries) {
      for (final rule in entry.value) {
        if (rule.idManagementRule == ruleId) {
          return (rule, entry.key);
        }
      }
    }
    return null;
  }

  Future<void> _acceptInvitation(
    int targetUserId,
    List<ManagementRule> pendingList,
    int index,
    ManagementRule targetRule,
    int? supplierId,
  ) async {
    final updatedRule =
        pendingList[index].copyWith(managementRuleStatus: RuleStates.active);

    pendingList.removeAt(index);
    if (pendingList.isEmpty) _cache.pendingRules.remove(targetUserId);

    _cache.activeRules.putIfAbsent(targetUserId, () => []);
    _cache.activeRules[targetUserId]!.add(updatedRule);

    // Update master list
    final allRules = _cache.privileges[targetUserId]!;
    final allIndex = allRules
        .indexWhere((r) => r.idManagementRule == targetRule.idManagementRule);
    if (allIndex != -1) {
      allRules[allIndex] = updatedRule;
    }

    // Update mappings
    if (supplierId != null && supplierId > 0) {
      _cache.addSupplierMapping(targetUserId, supplierId);
    }

    debugPrint(
        "Rule ${targetRule.idManagementRule} ACCEPTED → moved to ACTIVE");
  }

  void _rejectInvitation(
    int targetUserId,
    List<ManagementRule> pendingList,
    int index,
    int ruleId,
  ) {
    pendingList.removeAt(index);
    if (pendingList.isEmpty) _cache.pendingRules.remove(targetUserId);

    _cache.privileges[targetUserId]!
        .removeWhere((r) => r.idManagementRule == ruleId);

    if (_cache.privileges[targetUserId]!.isEmpty) {
      _cache.privileges.remove(targetUserId);
    }

    debugPrint("Rule $ruleId REJECTED → removed");
  }
}
