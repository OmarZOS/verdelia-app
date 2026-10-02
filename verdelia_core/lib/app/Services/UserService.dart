// UserService.dart
import 'package:verdelia_core/app/VerdeliaImage.dart';
import 'package:verdelia_core/app/ManagementRule.dart';
import 'package:verdelia_core/app/Person.dart';
import 'package:verdelia_core/app/TraceableService.dart';

import '../AppUser.dart';

// AppUserService.dart
abstract class AppUserService extends TraceableService {
  Future<List<AppUserCategory>?>? getCategories({String? callerKey}) async {
    return null;
  }

  Future<AppUser?> getAppUser(String idAppUser, {String? callerKey}) async {
    return null;
  }

  Future<Person?> getPerson(String idPerson, {String? callerKey}) async {
    return null;
  }

  Future<List<ManagementRule>?>? getManagementRules(
      int orgId, int supplierId, int userId, int offset, int limit,
      {String? callerKey}) async {
    return null;
  }

  Future<List<AppUser>?> searchAppUsers(String query, int offset, int limit,
      {String? callerKey}) async {
    return null;
  }

  Future<List<Person>?> searchPeople(String query, int offset, int limit,
      {String? callerKey}) async {
    return null;
  }

  Future<AppUser?> updateAppUser(AppUser appUser, {String? callerKey}) async {
    return null;
  }

  Future<int?> addAppUser(AppUser appUser, {String? callerKey}) async {
    return null;
  }

  Future<int?> updateAppUserImage(AppUser updatedAppUser,
      {String? callerKey}) async {
    return null;
  }

  Future<int?> deleteAppUser(String appUserId, {String? callerKey}) async {
    return null;
  }

  Future<ManagementRule?> addUserToSupplier(
      int appUserId, int supplierId, int orgId, int privilege,
      {bool fromQR = false, String? callerKey}) async {
    return null;
  }

  Future<ManagementRule?> updateManagementRule(
      int ruleId, int appUserId, int supplierId, int orgId, int privilege,
      {String? callerKey}) async {
    return null;
  }

  Future<bool> deleteManagementRule(int ruleId, {String? callerKey}) async {
    return false;
  }
}
