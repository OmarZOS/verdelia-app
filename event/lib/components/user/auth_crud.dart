import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:verdelia_core/app/AppUser.dart';
import 'package:verdelia_core/app/Services/UserService.dart';
import 'auth_state.dart';
import 'auth_token.dart';
import 'auth_user.dart';

class AuthCrudManager {
  final AppUserService _userService;
  final AuthState _state;
  final AuthTokenManager _tokenManager;
  final AuthUserManager _userManager;

  AuthCrudManager({
    required AppUserService userService,
    required AuthState state,
    required AuthTokenManager tokenManager,
    required AuthUserManager userManager,
  })  : _userService = userService,
        _state = state,
        _tokenManager = tokenManager,
        _userManager = userManager;

  Future<int?> addUser(AppUser user, {String? callerKey}) async {
    _state.setLoading(true);

    try {
      if (!await _tokenManager.ensureValid(callerKey: callerKey)) {
        throw Exception('Invalid or expired token');
      }

      final status = await _userService.addAppUser(user);
      if (status != null && status > 0) {
        await _userManager.fetch('${user.idAppUser}', callerKey: callerKey);
      }
      return status;
    } catch (e) {
      debugPrint('❌ Error adding user: $e');
      rethrow;
    } finally {
      _state.setLoading(false);
    }
  }

  Future<int?> updateImage(AppUser user, {String? callerKey}) async {
    _state.setLoading(true);

    try {
      if (!await _tokenManager.ensureValid(callerKey: callerKey)) {
        throw Exception('Invalid or expired token');
      }

      final status = await _userService.updateAppUserImage(user);
      if (status != null && status > 0) {
        await _userManager.fetch('${user.idAppUser}', callerKey: callerKey);
      }
      return status;
    } catch (e) {
      debugPrint('❌ Error updating user image: $e');
      rethrow;
    } finally {
      _state.setLoading(false);
    }
  }

  Future<int?> deleteUser(String id, {String? callerKey}) async {
    _state.setLoading(true);

    try {
      if (!await _tokenManager.ensureValid(callerKey: callerKey)) {
        throw Exception('Invalid or expired token');
      }

      final status = await _userService.deleteAppUser(id);
      if (status != null && status > 0) {
        // Clear from cache
        final userId = int.tryParse(id);
        if (userId != null) {
          _state.userCache.remove(userId);
        }
      }
      return status;
    } catch (e) {
      debugPrint('❌ Error deleting user: $e');
      rethrow;
    } finally {
      _state.setLoading(false);
    }
  }
}
