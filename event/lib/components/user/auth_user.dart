import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:verdelia_core/app/AppUser.dart';
import 'package:verdelia_core/app/Services/UserService.dart';
import 'auth_state.dart';
import 'auth_persistence.dart';
import 'auth_token.dart';

class AuthUserManager {
  final AppUserService _userService;
  final AuthState _state;
  final AuthPersistence _persistence;
  final AuthTokenManager _tokenManager;

  AuthUserManager({
    required AppUserService userService,
    required AuthState state,
    required AuthPersistence persistence,
    required AuthTokenManager tokenManager,
  })  : _userService = userService,
        _state = state,
        _persistence = persistence,
        _tokenManager = tokenManager;

  Future<void> fetch(String userId, {String? callerKey}) async {
    _state.setLoading(true);

    try {
      if (!await _tokenManager.ensureValid(callerKey: callerKey)) {
        throw Exception('Invalid or expired token');
      }

      final user = await _userService.getAppUser(userId);
      _state.setUser(user!);
      _state.cacheUser(user);
      await _saveAuthData();
    } catch (e) {
      debugPrint('❌ Error fetching user: $e');
      rethrow;
    } finally {
      _state.setLoading(false);
    }
  }

  Future<AppUser?> fetchPassively(String userId, {String? callerKey}) async {
    try {
      // Check cache first
      final cached = _state.getCachedUser(int.parse(userId));
      if (cached != null) return cached;

      if (!await _tokenManager.ensureValid(callerKey: callerKey)) {
        return null;
      }

      final user = await _userService.getAppUser(userId);
      if (user != null) {
        _state.cacheUser(user);
      }
      return user;
    } catch (e) {
      debugPrint('❌ Error fetching user passively: $e');
      return null;
    }
  }

  Future<void> update(AppUser user, {String? callerKey}) async {
    _state.setLoading(true);

    try {
      if (!await _tokenManager.ensureValid(callerKey: callerKey)) {
        throw Exception('Invalid or expired token');
      }

      await _userService.updateAppUser(user);
      await fetch('${user.idAppUser}', callerKey: callerKey);
    } catch (e) {
      debugPrint('❌ Error updating user: $e');
      rethrow;
    } finally {
      _state.setLoading(false);
    }
  }

  Future<void> _saveAuthData() async {
    if (_state.appUser != null &&
        _state.token != null &&
        _state.isAuthenticated) {
      final userJson = _state.appUser!.toJson();
      await _persistence.save(
        token: _state.token!,
        refreshToken: _state.refreshToken ?? '',
        userData: jsonEncode(userJson),
        isAuthenticated: _state.isAuthenticated,
        expiry: _state.tokenExpiry?.toIso8601String() ?? '',
      );
    }
  }

  void clearCache() {
    _state.clearUserCache();
  }
}
