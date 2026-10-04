library impl_app;

import 'dart:developer';

import 'package:app_constants/app_constants.dart';
import 'package:verdelia_core/app/AppUser.dart';
import 'package:verdelia_core/app/VerdeliaException.dart';
import 'package:verdelia_core/app/ManagementRule.dart';
import 'package:verdelia_core/app/Person.dart';
import 'package:verdelia_core/app/Services/UserService.dart';
import 'package:verdelia_core/app/finance/Plan.dart';
import 'package:verdelia_core/app/finance/Subscription.dart';
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

  // ==================== Plans ====================

  @override
  Future<List<Plan>?> getPlans({
    String? planType,
    String? billingCycle,
    String? callerKey,
  }) async {
    final key = callerKey ?? _getCallerKey('getPlans');
    try {
      final params = <String, String>{};
      if (planType != null && planType.isNotEmpty) {
        params['plan_type'] = planType;
      }
      if (billingCycle != null && billingCycle.isNotEmpty) {
        params['billing_cycle'] = billingCycle;
      }

      final queryString = params.isEmpty
          ? ''
          : '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';

      final data = await _storageService.getAll(
        '${AppConstants.apiBaseUrl}${AppConstants.getPlansEndpoint}$queryString',
        callerKey: key,
      );

      if (data == null) {
        _storeSuccess(key, const <Plan>[], responseCode: 'EMPTY');
        return const <Plan>[];
      }

      List<Plan> plans = const [];
      if (data is List) {
        plans = Plan.listFromJson(data);
      } else if (data is Map && data['data'] is List) {
        plans = Plan.listFromJson(data['data']);
      } else if (data is Map && data['items'] is List) {
        plans = Plan.listFromJson(data['items']);
      }

      _storeSuccess(key, plans);
      return plans;
    } catch (e) {
      _storeFailure(
        key,
        e.toString(),
        errorCode: e is VerdeliaException ? e.message : 'ERROR',
      );
      return null;
    }
  }

  @override
  Future<Plan?> getPlan(int planId, {String? callerKey}) async {
    final key = callerKey ?? _getCallerKey('getPlan', id: planId.toString());
    try {
      final data = await _storageService.getAll(
        '${AppConstants.apiBaseUrl}${AppConstants.getPlanEndpoint}/$planId',
        callerKey: key,
      );

      if (data == null) {
        _storeFailure(key, null, code: 404, errorCode: 'PLAN_NOT_FOUND');
        return null;
      }

      Plan? plan;
      if (data is Map) {
        final inner = data['data'];
        if (inner is Map) {
          plan = Plan.fromJson(Map<String, dynamic>.from(inner));
        } else if (data.containsKey('id_plan') ||
            data.containsKey('plan_name')) {
          plan = Plan.fromJson(Map<String, dynamic>.from(data));
        }
      } else if (data is List && data.isNotEmpty && data.first is Map) {
        plan = Plan.fromJson(
          Map<String, dynamic>.from(data.first as Map),
        );
      }

      if (plan != null) {
        _storeSuccess(key, plan);
      } else {
        _storeFailure(key, data, errorCode: 'INVALID_RESPONSE');
      }
      return plan;
    } catch (e) {
      _storeFailure(
        key,
        e.toString(),
        errorCode: e is VerdeliaException ? e.message : 'ERROR',
      );
      return null;
    }
  }

  // ==================== Subscription reads ====================

  @override
  Future<Subscription?> getSubscription(int userId, {String? callerKey}) async {
    final key =
        callerKey ?? _getCallerKey('getSubscription', id: userId.toString());
    try {
      final data = await _storageService.getAll(
        '${AppConstants.apiBaseUrl}'
        '${AppConstants.subscriptionBaseEndpoint}/$userId'
        '${AppConstants.subscriptionSuffix}',
        callerKey: key,
      );

      // Null covers both "404 no subscription" and other read
      // failures. Both are non-exceptional here — the caller treats
      // null as "no active subscription" and renders the upgrade CTA.
      if (data == null) {
        _storeSuccess(key, null, responseCode: 'NO_SUBSCRIPTION');
        return null;
      }

      Subscription? subscription;
      if (data is Map) {
        final inner = data['data'];
        if (inner is Map) {
          subscription = Subscription.fromJson(
            Map<String, dynamic>.from(inner),
          );
        } else if (data.containsKey('id_subscription') ||
            data.containsKey('subscription_plan_id')) {
          subscription = Subscription.fromJson(
            Map<String, dynamic>.from(data),
          );
        }
      } else if (data is List && data.isNotEmpty && data.first is Map) {
        subscription = Subscription.fromJson(
          Map<String, dynamic>.from(data.first as Map),
        );
      }

      if (subscription != null) {
        _storeSuccess(key, subscription);
      } else {
        _storeSuccess(key, null, responseCode: 'NO_SUBSCRIPTION');
      }
      return subscription;
    } catch (e) {
      _storeFailure(
        key,
        e.toString(),
        errorCode: e is VerdeliaException ? e.message : 'ERROR',
      );
      return null;
    }
  }

  @override
  Future<bool> isSubscriptionActive(int userId, {String? callerKey}) async {
    final key = callerKey ??
        _getCallerKey('isSubscriptionActive', id: userId.toString());
    try {
      final data = await _storageService.getAll(
        '${AppConstants.apiBaseUrl}'
        '${AppConstants.subscriptionBaseEndpoint}/$userId'
        '${AppConstants.subscriptionStatusSuffix}',
        callerKey: key,
      );

      // Default to false when the call fails or the response is
      // unrecognized. A false here hides premium features rather than
      // showing them to a user who may not be entitled.
      if (data is! Map) {
        _storeSuccess(key, false, responseCode: 'UNKNOWN');
        return false;
      }

      final inner = data['data'];
      final source = inner is Map ? inner : data;
      final active = source['active'] == true;

      _storeSuccess(key, active);
      return active;
    } catch (e) {
      _storeFailure(
        key,
        e.toString(),
        errorCode: e is VerdeliaException ? e.message : 'ERROR',
      );
      return false;
    }
  }

  // ==================== Subscription writes ====================

  @override
  Future<SubscriptionPurchaseResult?> initiateSubscription({
    required int userId,
    required int planId,
    required String paymentMethod,
    String? notes,
    String? callerKey,
  }) async {
    final key = callerKey ??
        _getCallerKey(
          'initiateSubscription',
          id: userId.toString(),
          suffix: 'plan_$planId',
        );
    try {
      // The backend reads these from query params, not the body.
      final params = <String, String>{
        'plan_id': planId.toString(),
        'payment_method': paymentMethod,
      };
      if (notes != null && notes.isNotEmpty) {
        params['notes'] = notes;
      }

      final queryString =
          params.entries.map((e) => '${e.key}=${e.value}').join('&');

      final result = await _storageService.insert(
        '${AppConstants.apiBaseUrl}'
        '${AppConstants.subscriptionBaseEndpoint}/$userId'
        '${AppConstants.subscriptionInitiateSuffix}?$queryString',
        const <String, dynamic>{}, // no JSON body — query params only
        callerKey: key,
      );

      if (result == null) {
        _storeFailure(
          key,
          null,
          code: 500,
          errorCode: 'SUBSCRIPTION_INITIATE_FAILED',
        );
        return null;
      }

      Map<String, dynamic> payload;
      if (result is Map<String, dynamic>) {
        final inner = result['data'];
        payload = inner is Map<String, dynamic>
            ? inner
            : Map<String, dynamic>.from(result);
      } else {
        _storeFailure(key, result, errorCode: 'INVALID_RESPONSE');
        return null;
      }

      final purchase = SubscriptionPurchaseResult.fromJson(payload);
      _storeSuccess(key, purchase);
      return purchase;
    } catch (e) {
      _storeFailure(
        key,
        e.toString(),
        errorCode: e is VerdeliaException ? e.message : 'ERROR',
      );
      return null;
    }
  }

  @override
  Future<Subscription?> linkFreePlan({
    required int userId,
    required int planId,
    String? callerKey,
  }) async {
    final key = callerKey ??
        _getCallerKey(
          'linkFreePlan',
          id: userId.toString(),
          suffix: 'plan_$planId',
        );
    try {
      final result = await _storageService.insert(
        '${AppConstants.apiBaseUrl}'
        '${AppConstants.subscriptionBaseEndpoint}/$userId'
        '${AppConstants.subscriptionLinkFreeSuffix}?plan_id=$planId',
        const <String, dynamic>{},
        callerKey: key,
      );

      if (result == null) {
        _storeFailure(key, null, code: 400, errorCode: 'PLAN_NOT_FREE');
        return null;
      }

      Map<String, dynamic> payload;
      if (result is Map<String, dynamic>) {
        final inner = result['data'];
        payload = inner is Map<String, dynamic>
            ? inner
            : Map<String, dynamic>.from(result);
      } else {
        _storeFailure(key, result, errorCode: 'INVALID_RESPONSE');
        return null;
      }

      final subJson = payload['subscription'];
      if (subJson is! Map) {
        _storeFailure(key, payload, errorCode: 'INVALID_RESPONSE');
        return null;
      }

      final subscription = Subscription.fromJson(
        Map<String, dynamic>.from(subJson),
      );
      _storeSuccess(key, subscription);
      return subscription;
    } catch (e) {
      _storeFailure(
        key,
        e.toString(),
        errorCode: e is VerdeliaException ? e.message : 'ERROR',
      );
      return null;
    }
  }

  @override
  Future<AppUser?> cancelSubscription({
    required int userId,
    int? refundPaymentId,
    String? callerKey,
  }) async {
    final key =
        callerKey ?? _getCallerKey('cancelSubscription', id: userId.toString());
    try {
      final params = <String, String>{};
      if (refundPaymentId != null) {
        params['refund_payment_id'] = refundPaymentId.toString();
      }

      final queryString = params.isEmpty
          ? ''
          : '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';

      final result = await _storageService.delete(
        '${AppConstants.apiBaseUrl}'
        '${AppConstants.subscriptionBaseEndpoint}/$userId'
        '${AppConstants.subscriptionSuffix}$queryString',
        userId.toString(),
        callerKey: key,
      );

      // A null result means "no subscription to cancel" or a read
      // failure — both benign here. The caller distinguishes by
      // checking the trace.
      if (result == null) {
        _storeSuccess(key, null, responseCode: 'NO_SUBSCRIPTION');
        return null;
      }

      // The backend returns the updated user. Re-fetch the full user
      // so the caller gets a fresh snapshot with the cleared
      // subscription ref and zeroed quota.
      return await getAppUser(userId.toString(), callerKey: key);
    } catch (e) {
      _storeFailure(
        key,
        e.toString(),
        errorCode: e is VerdeliaException ? e.message : 'ERROR',
      );
      return null;
    }
  }
}
