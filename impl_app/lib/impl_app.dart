library impl_app;

import 'dart:developer';

import 'package:app_constants/app_constants.dart';
import 'package:verdelia_core/app/AppUser.dart';
import 'package:verdelia_core/app/VerdeliaException.dart';
import 'package:verdelia_core/app/ManagementRule.dart';
import 'package:verdelia_core/app/Person.dart';
import 'package:verdelia_core/app/Services/UserService.dart';
import 'package:verdelia_core/mediation/StorageService.dart';
import 'package:locator/locator.dart';

class AppUserServiceImpl extends AppUserService {
  final StorageService _storageService = AppLocator.get<StorageService>();
  List<AppUserCategory> _categories = [];

  String _getCallerKey(String method, {String? id, String? suffix}) {
    final parts = [method];
    if (id != null) parts.add(id);
    if (suffix != null) parts.add(suffix);
    if (parts.length == 1)
      parts.add(DateTime.now().millisecondsSinceEpoch.toString());
    return parts.join('_');
  }

  void _storeSuccess(String key, dynamic data,
      {int? code, String? responseCode}) {
    _storageService.setSuccessResponse(key, data,
        statusCode: code ?? 200, responseCode: responseCode ?? 'SUCCESS');
  }

  void _storeFailure(String key, dynamic data,
      {int? code, String? errorCode, String? message}) {
    _storageService.setFailureResponse(key,
        data: data,
        statusCode: code ?? 500,
        errorCode: errorCode,
        message: message);
  }

  @override
  Future<int?> addAppUser(AppUser appUser, {String? callerKey}) async {
    final key =
        callerKey ?? _getCallerKey('addAppUser', suffix: appUser.appUserName);
    try {
      final result = await _storageService.insert(
        '${AppConstants.apiBaseUrl}${AppConstants.addAppUserEndpoint}',
        appUser.toJson(),
        callerKey: key,
      );
      final userId = result?['idAppUser'] as int?;
      if (userId != null)
        _storeSuccess(key, userId);
      else
        _storeFailure(key, null, code: 500, errorCode: 'ADD_FAILED');
      return userId;
    } catch (e) {
      _storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      return null;
    }
  }

  @override
  Future<AppUser?> updateAppUser(AppUser appUser, {String? callerKey}) async {
    final key = callerKey ??
        _getCallerKey('updateAppUser', id: appUser.idAppUser.toString());
    try {
      final result = await _storageService.update(
        '${AppConstants.apiBaseUrl}${AppConstants.updateAppUserEndpoint}',
        "",
        {},
        appUser.toJson(),
        callerKey: key,
      );
      if (result == null) {
        _storeFailure(key, null, code: 500, errorCode: 'UPDATE_FAILED');
        return null;
      }
      final user = AppUser.fromJson(result as Map<String, dynamic>);
      _storeSuccess(key, user);
      return user;
    } catch (e) {
      _storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      return null;
    }
  }

  @override
  Future<int?> deleteAppUser(String appUserId, {String? callerKey}) async {
    final key = callerKey ?? _getCallerKey('deleteAppUser', id: appUserId);
    try {
      final result = await _storageService.delete(
        '${AppConstants.apiBaseUrl}${AppConstants.deleteAppUserEndpoint}/$appUserId',
        appUserId,
        callerKey: key,
      );
      if (result == 200 || result == 204)
        _storeSuccess(key, true);
      else
        _storeFailure(key, false, code: result);
      return result;
    } catch (e) {
      _storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      return null;
    }
  }

  @override
  Future<int?> updateAppUserImage(AppUser updatedAppUser,
      {String? callerKey}) async {
    final key = callerKey ??
        _getCallerKey('updateAppUserImage',
            id: updatedAppUser.idAppUser.toString());
    try {
      final result = await _storageService.update(
        '${AppConstants.apiBaseUrl}${AppConstants.updateAppUserImageEndpoint}',
        updatedAppUser.idAppUser.toString(),
        {'image_url': updatedAppUser.appUserImageUrl ?? ''},
        updatedAppUser.toJson(),
        callerKey: key,
      );
      if (result != null)
        _storeSuccess(key, true);
      else
        _storeFailure(key, false);
      return result as int?;
    } catch (e) {
      _storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      return null;
    }
  }

  @override
  Future<AppUser?> getAppUser(String id, {String? callerKey}) async {
    final key = callerKey ?? _getCallerKey('getAppUser', id: id);
    try {
      final data = await _storageService.get(
        '${AppConstants.apiBaseUrl}${AppConstants.appUserEndpoint}',
        id,
        callerKey: key,
      );
      if (data == null) {
        _storeFailure(key, null, code: 404, errorCode: 'NOT_FOUND');
        return AppUser.empty();
      }
      final user = data is Map
          ? AppUser.fromJson(data as Map<String, dynamic>)
          : (data is List && data.isNotEmpty
              ? AppUser.fromJson(data[0] as Map<String, dynamic>)
              : null);
      if (user != null)
        _storeSuccess(key, user);
      else
        _storeFailure(key, data, code: 500, errorCode: 'INVALID_RESPONSE');
      return user ?? AppUser.empty();
    } catch (e) {
      _storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      return AppUser.empty();
    }
  }

  @override
  Future<List<ManagementRule>?> getManagementRules(
      int orgId, int supplierId, int userId, int offset, int limit,
      {String? callerKey}) async {
    final key = callerKey ?? _getCallerKey('getManagementRules');
    try {
      final data = await _storageService.getAll(
        '${AppConstants.apiBaseUrl}${AppConstants.getStaffEndpoint}'
        '?org_id=$orgId&provider_id=$supplierId&user_id=$userId&offset=$offset&limit=$limit',
        callerKey: key,
      );
      if (data == null) {
        _storeSuccess(key, [], responseCode: 'EMPTY');
        return [];
      }
      List<ManagementRule> rules = [];
      if (data is List) {
        rules = data
            .map((j) => ManagementRule.fromJson(j as Map<String, dynamic>))
            .toList();
      } else if (data is Map && data['data'] is List) {
        rules = (data['data'] as List)
            .map((j) => ManagementRule.fromJson(j as Map<String, dynamic>))
            .toList();
      }
      _storeSuccess(key, rules);
      return rules;
    } catch (e) {
      _storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      return null;
    }
  }

  @override
  Future<ManagementRule?> addUserToSupplier(
      int appUserId, int supplierId, int orgId, int privilege,
      {bool fromQR = false, String? callerKey}) async {
    final key = callerKey ?? _getCallerKey('addUserToSupplier');
    try {
      final result = await _storageService.insert(
        '${AppConstants.apiBaseUrl}${AppConstants.addRuleEndpoint}',
        {
          "id_management_rule": 0,
          "rule_ref_org": orgId,
          "rule_ref_provider": supplierId,
          "rule_ref_user": appUserId,
          "management_rule_code": privilege,
          "management_rule_status": fromQR ? "ACTIVE" : "PENDING",
          "management_rule_expiry": null,
        },
        callerKey: key,
      );
      if (result == null) {
        _storeFailure(key, null, errorCode: 'ADD_FAILED');
        return null;
      }
      final rule = ManagementRule.fromJson(result as Map<String, dynamic>);
      _storeSuccess(key, rule);
      return rule;
    } catch (e) {
      _storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      return null;
    }
  }

  @override
  Future<ManagementRule?> updateManagementRule(
      int ruleId, int appUserId, int supplierId, int orgId, int privilege,
      {String? callerKey}) async {
    final key = callerKey ??
        _getCallerKey('updateManagementRule', id: ruleId.toString());
    try {
      final result = await _storageService.update(
        '${AppConstants.apiBaseUrl}${AppConstants.updateStaffEndpoint}',
        ruleId.toString(),
        {},
        {
          "id_management_rule": ruleId,
          "rule_ref_org": orgId,
          "rule_ref_provider": supplierId,
          "rule_ref_user": appUserId,
          "management_rule_code": privilege,
          "management_rule_status": "ACTIVE",
          "management_rule_expiry": null,
        },
        callerKey: key,
      );
      if (result == null) {
        _storeFailure(key, null, errorCode: 'UPDATE_FAILED');
        return null;
      }
      final rule = ManagementRule.fromJson(result as Map<String, dynamic>);
      _storeSuccess(key, rule);
      return rule;
    } catch (e) {
      _storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      return null;
    }
  }

  @override
  Future<bool> deleteManagementRule(int ruleId, {String? callerKey}) async {
    final key = callerKey ??
        _getCallerKey('deleteManagementRule', id: ruleId.toString());
    try {
      final result = await _storageService.delete(
        '${AppConstants.apiBaseUrl}${AppConstants.deleteStaffEndpoint}',
        ruleId.toString(),
        callerKey: key,
      );
      final success = result != null && result >= 200 && result < 300;
      if (success)
        _storeSuccess(key, true);
      else
        _storeFailure(key, false);
      return success;
    } catch (e) {
      _storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      return false;
    }
  }

  @override
  Future<List<AppUser>?> searchAppUsers(String query, int offset, int limit,
      {String? callerKey}) async {
    final key = callerKey ?? _getCallerKey('searchAppUsers', suffix: query);
    try {
      final data = await _storageService.getAll(
        '${AppConstants.apiBaseUrl}${AppConstants.searchAppUserEndpoint}/$query?offset=$offset&limit=$limit',
        callerKey: key,
      );
      if (data == null) {
        _storeSuccess(key, [], responseCode: 'EMPTY');
        return [];
      }
      List<AppUser> users = [];
      if (data is List) {
        users = AppUser.fromJsonList(data);
      } else if (data is Map && data['data'] is List) {
        users = AppUser.fromJsonList(data['data'] as List);
      }
      _storeSuccess(key, users);
      return users;
    } catch (e) {
      _storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      return [];
    }
  }

  @override
  Future<List<Person>?> searchPeople(String query, int offset, int limit,
      {String? callerKey}) async {
    final key = callerKey ?? _getCallerKey('searchPeople', suffix: query);
    try {
      final data = await _storageService.getAll(
        '${AppConstants.apiBaseUrl}${AppConstants.searchPersonsByNameEndpoint}/$query?offset=$offset&limit=$limit',
        callerKey: key,
      );
      if (data == null) {
        _storeSuccess(key, [], responseCode: 'EMPTY');
        return [];
      }

      List<Person> people = [];
      try {
        if (data is List) {
          for (final item in data) {
            try {
              final person = Person.fromJson(item as Map<String, dynamic>);
              people.add(person);
            } catch (e) {
              log('Error parsing person: $e', name: 'AppUserServiceImpl');
              // Continue to next item
            }
          }
        } else if (data is Map && data['data'] is List) {
          for (final item in data['data'] as List) {
            try {
              final person = Person.fromJson(item as Map<String, dynamic>);
              people.add(person);
            } catch (e) {
              log('Error parsing person: $e', name: 'AppUserServiceImpl');
              // Continue to next item
            }
          }
        }
      } catch (e) {
        log('Error processing search results: $e', name: 'AppUserServiceImpl');
        return [];
      }

      _storeSuccess(key, people);
      log('✅ Found ${people.length} people for query: "$query"',
          name: 'AppUserServiceImpl');
      return people;
    } catch (e) {
      _storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      log('❌ Search people failed: $e', name: 'AppUserServiceImpl');
      return [];
    }
  }

  @override
  Future<Person?> getPerson(String id, {String? callerKey}) async {
    final key = callerKey ?? _getCallerKey('getPerson', id: id);
    try {
      final data = await _storageService.get(
        '${AppConstants.apiBaseUrl}${AppConstants.personEndpoint}',
        id,
        callerKey: key,
      );
      if (data == null) {
        _storeFailure(key, null, code: 404, errorCode: 'NOT_FOUND');
        return Person.empty();
      }
      Person? person;
      if (data is Map) {
        person = Person.fromJson(data as Map<String, dynamic>);
      } else if (data is List && data.isNotEmpty) {
        person = Person.fromJson(data[0] as Map<String, dynamic>);
      }
      if (person != null)
        _storeSuccess(key, person);
      else
        _storeFailure(key, data, errorCode: 'INVALID_RESPONSE');
      return person ?? Person.empty();
    } catch (e) {
      _storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      return Person.empty();
    }
  }

  @override
  Future<List<AppUserCategory>>? getCategories({String? callerKey}) async {
    final key = callerKey ?? _getCallerKey('getCategories');
    if (_categories.isNotEmpty) {
      _storeSuccess(key, _categories, responseCode: 'CACHED');
      return _categories;
    }
    try {
      final data = await _storageService.getAll(
        '${AppConstants.apiBaseUrl}${AppConstants.getAppUserCategoriesEndpoint}',
        callerKey: key,
      );
      if (data == null) return [];
      List<AppUserCategory> categories = [];
      if (data is List) {
        categories = data
            .map((j) => AppUserCategory.fromJson(j as Map<String, dynamic>))
            .toList();
      } else if (data is Map && data['data'] is List) {
        categories = (data['data'] as List)
            .map((j) => AppUserCategory.fromJson(j as Map<String, dynamic>))
            .toList();
      }
      _categories = categories;
      _storeSuccess(key, categories);
      return categories;
    } catch (e) {
      _storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      return [];
    }
  }

  void clearCache() => _categories.clear();
  Future<List<AppUserCategory>> refreshCategories({String? callerKey}) async {
    _categories.clear();
    return await getCategories(callerKey: callerKey) ?? [];
  }
}
