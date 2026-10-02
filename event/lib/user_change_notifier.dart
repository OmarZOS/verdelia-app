import 'dart:convert';

import 'package:app_constants/app_constants.dart';
import 'package:event/components/user/auth_crud.dart';
import 'package:event/components/user/auth_persistence.dart';
import 'package:event/components/user/auth_response.dart';
import 'package:event/components/user/auth_state.dart';
import 'package:event/components/user/auth_token.dart';
import 'package:event/components/user/auth_user.dart';
import 'package:flutter/material.dart';
import 'package:verdelia_core/app/AppUser.dart';
import 'package:verdelia_core/app/Services/AuthService.dart';
import 'package:verdelia_core/app/Services/UserService.dart';
import 'package:verdelia_core/mediation/StorageService.dart';
import 'package:locator/locator.dart';

class AppUserNotifier extends ChangeNotifier {
  final AppUserService _userService = AppLocator.get<AppUserService>();
  final AuthService _authService = AppLocator.get<AuthService>();
  final StorageService _storageService = AppLocator.get<StorageService>();

  // Components
  late final AuthState _state;
  late final AuthPersistence _persistence;
  late final AuthResponseManager _response;
  late final AuthTokenManager _token;
  late final AuthUserManager _user;
  late final AuthCrudManager _crud;

  AppUserNotifier() {
    _initComponents();
    initializeAuthState();
  }

  void _initComponents() {
    _state = AuthState();
    _persistence = AuthPersistence();
    _response = AuthResponseManager(_storageService);
    _token = AuthTokenManager(
      authService: _authService,
      state: _state,
      persistence: _persistence,
    );
    _user = AuthUserManager(
      userService: _userService,
      state: _state,
      persistence: _persistence,
      tokenManager: _token,
    );
    _crud = AuthCrudManager(
      userService: _userService,
      state: _state,
      tokenManager: _token,
      userManager: _user,
    );
  }

  void _notify() {
    if (!_state.isLoading) {
      notifyListeners();
    }
  }

  // ============ PUBLIC GETTERS ============

  AppUser? get appUser => _state.appUser;
  String? get token => _state.token;
  String? get refreshToken => _state.refreshToken;
  int? get tokenExpiresIn => _state.expiresIn;
  DateTime? get tokenExpiry => _state.tokenExpiry;
  bool get isAuthenticated => _state.isAuthenticated;
  bool get isLoading => _state.isLoading;
  bool get isRefreshing => _state.isRefreshing;
  int get selectedTabIndex => _state.selectedTabIndex;
  bool get isCookingRecipe => _state.isCookingRecipe;

  // ============ FORCED SIGN-OUT ============

  /// Clears local auth state and persistence after a refresh failure.
  ///
  /// Called when the token manager reports that refresh could not succeed —
  /// the session is unusable, so we drop everything and notify the UI.
  ///
  /// Differs from [signOut] in that it:
  ///   • does not set the loading flag (avoids flickering)
  ///   • records a `REFRESH_FAILED` response code (not `SIGNOUT_SUCCESS`)
  ///   • never rethrows (it's a background teardown)
  Future<void> _forceSignOut({
    required String callerKey,
    required String reason,
  }) async {
    debugPrint('🔒 Forcing sign-out: $reason');

    try {
      await _persistence.clear();
    } catch (e) {
      debugPrint('⚠️ Failed to clear persistence during forced sign-out: $e');
    }

    _state.reset();

    _response.storeFailure(
      callerKey,
      reason,
      statusCode: 401,
      errorCode: 'REFRESH_FAILED',
      message: 'Session expired — please sign in again',
    );

    _notify();
  }

  // ============ INITIALIZATION ============

  Future<void> initializeAuthState({String? callerKey}) async {
    final key = callerKey ?? _response.generateKey('initializeAuthState');

    try {
      _state.setLoading(true);
      _notify();

      final data = await _persistence.load();
      final token = data['token'] as String?;
      final refreshToken = data['refreshToken'] as String?;
      final userData = data['userData'] as String?;
      final isAuthenticated = data['isAuthenticated'] as bool? ?? false;
      final expiry = data['expiry'] as String?;

      debugPrint('🔐 Initializing auth state...');
      debugPrint('   Token: ${token != null ? "YES" : "NO"}');
      debugPrint('   Refresh Token: ${refreshToken != null ? "YES" : "NO"}');
      debugPrint('   User Data: ${userData != null ? "YES" : "NO"}');
      debugPrint('   Is Authenticated: $isAuthenticated');

      // Store tokens first if they exist
      if (token != null) _state.token = token;
      if (refreshToken != null) _state.refreshToken = refreshToken;

      // Restore expiry
      if (expiry != null && expiry.isNotEmpty) {
        _state.tokenExpiry = DateTime.tryParse(expiry);
      }

      // Parse user data — but preserve the existing user if parsing fails.
      if (userData != null && userData.isNotEmpty) {
        final user = _persistence.parseUserData(userData);
        if (user != null) {
          _state.setUser(user);
          debugPrint('✅ User restored: ${user.appUserName}');
        } else {
          debugPrint('⚠️ Failed to parse user data');
          if (_state.appUser == null) {
            await _forceSignOut(
              callerKey: key,
              reason: 'Stored user data is corrupt',
            );
            _state.setLoading(false);
            _notify();
            return;
          }
        }
      }

      // No token + no user → nothing to restore.
      if (token == null || _state.appUser == null) {
        debugPrint('ℹ️ No valid auth state found');
        _response.storeSuccess(
          key,
          null,
          statusCode: 200,
          responseCode: 'NO_AUTH_FOUND',
        );
        _state.setLoading(false);
        _notify();
        return;
      }

      // We have a token + user; figure out whether the token is usable.
      _state.isAuthenticated = true;

      final expired = _state.tokenExpiry != null &&
          DateTime.now().isAfter(_state.tokenExpiry!);

      if (expired) {
        debugPrint('⚠️ Token expired, refreshing...');
        final refreshed = await _token.refresh(callerKey: key);

        if (!refreshed) {
          await _forceSignOut(
            callerKey: key,
            reason: 'Expired token could not be refreshed',
          );
          _state.setLoading(false);
          _notify();
          return;
        }

        debugPrint('✅ Token refreshed successfully');
      } else if (_state.needsTokenRefresh) {
        debugPrint('🔄 Token expiring soon, refreshing...');
        final refreshed = await _token.refresh(callerKey: key);

        if (!refreshed) {
          // Proactive refresh failed — treat as session unusable.
          await _forceSignOut(
            callerKey: key,
            reason: 'Session could not be extended',
          );
          _state.setLoading(false);
          _notify();
          return;
        }

        debugPrint('✅ Token refreshed successfully');
      } else {
        debugPrint('   Token valid until: ${_state.tokenExpiry}');
      }

      // If we're here, the session is usable.
      if (_state.appUser != null) {
        _response.storeSuccess(
          key,
          _state.appUser,
          statusCode: 200,
          responseCode: 'AUTH_RESTORED',
        );
        debugPrint('✅ Auth state restored: ${_state.appUser?.appUserName}');
      }

      _state.setLoading(false);
      _notify();
    } catch (e) {
      debugPrint('❌ Error initializing auth state: $e');
      _response.storeFailure(
        key,
        e.toString(),
        statusCode: 500,
        errorCode: 'INIT_AUTH_ERROR',
        message: 'Failed to initialize auth state',
      );
      _state.setLoading(false);

      try {
        await _persistence.clear();
      } catch (_) {}

      _state.reset();
      _notify();
    }
  }

  // ============ TOKEN MANAGEMENT ============

  /// Force a token refresh now. If it fails, the session is dropped.
  Future<bool> refreshTokenNow({String? callerKey}) async {
    final key = callerKey ?? _response.generateKey('refreshTokenNow');

    final ok = await _token.refresh(callerKey: key);

    if (ok && _state.token != null) {
      _storageService.setAuthToken(_state.token!);
      _notify();
      return true;
    }

    await _forceSignOut(
      callerKey: key,
      reason: 'Token refresh failed',
    );
    return false;
  }

  /// Ensure the current token is valid, refreshing proactively if needed.
  ///
  /// Only forces sign-out when the state is genuinely unusable (no token
  /// or no user). A failed proactive refresh with a still-valid token is
  /// not enough to disconnect the user — that would turn transient network
  /// errors into forced logouts.
  Future<bool> ensureValidToken({String? callerKey}) async {
    final key = callerKey ?? _response.generateKey('ensureValidToken');

    final ok = await _token.ensureValid(callerKey: key);

    if (ok) {
      _notify();
      return true;
    }

    // Only force sign-out if we truly have no session left.
    if (_state.token == null || _state.appUser == null) {
      await _forceSignOut(
        callerKey: key,
        reason: 'Token could not be validated',
      );
      return false;
    }

    _notify();
    return false;
  }

  // ============ USER MANAGEMENT ============

  Future<void> fetchAppUser(String userId, {String? callerKey}) async {
    final key = _response.generateKey('fetchAppUser', id: userId);
    try {
      await _user.fetch(userId, callerKey: key);
      _notify();
      _response.storeSuccess(key, _state.appUser);
    } catch (e) {
      _response.storeFailure(
        key,
        e.toString(),
        errorCode: 'FETCH_USER_ERROR',
        message: 'Failed to fetch user',
      );
      rethrow;
    }
  }

  Future<AppUser?> fetchUserPassively(
    String userId, {
    String? callerKey,
  }) async {
    final key = _response.generateKey('fetchUserPassively', id: userId);
    try {
      final user = await _user.fetchPassively(userId, callerKey: key);
      if (user != null) {
        _response.storeSuccess(key, user);
      } else {
        _response.storeFailure(
          key,
          null,
          statusCode: 404,
          errorCode: 'USER_NOT_FOUND',
        );
      }
      return user;
    } catch (e) {
      _response.storeFailure(
        key,
        e.toString(),
        errorCode: 'FETCH_PASSIVE_ERROR',
        message: 'Failed to fetch user',
      );
      return null;
    }
  }

  Future<void> updateAppUser(AppUser user, {String? callerKey}) async {
    final key = _response.generateKey(
      'updateAppUser',
      id: user.idAppUser?.toString(),
    );
    try {
      await _user.update(user, callerKey: key);
      _notify();
      _response.storeSuccess(key, user);
    } catch (e) {
      _response.storeFailure(
        key,
        e.toString(),
        errorCode: 'UPDATE_USER_ERROR',
        message: 'Failed to update user',
      );
      rethrow;
    }
  }

  // ============ AUTHENTICATION ============

  Future<bool> signInWithUsernameAndPassword(
    String username,
    String password, {
    String? callerKey,
  }) async {
    final key = callerKey ?? _response.generateKey('signIn', suffix: username);

    try {
      _state.setLoading(true);
      _notify();

      debugPrint('🔐 Attempting login for user: $username');

      final result = await _authService.signInWithUsernameAndPassword(
        username,
        password,
        callerKey: key,
      );

      if (result['app_user_id'] != null) {
        final accessToken =
            result['access_token'] ?? result['token']?['access_token'];
        final refreshToken =
            result['refresh_token'] ?? result['token']?['refresh_token'];
        final expiresIn =
            result['expires_in'] ?? result['token']?['expires_in'] ?? 3600;
        final userId = result['app_user_id'] ?? result['user']?['idAppUser'];

        if (accessToken == null) {
          throw Exception('No access token received');
        }

        _state.setTokens(accessToken, refreshToken ?? '', expiresIn);
        _state.isAuthenticated = true;

        await _user.fetch(userId.toString(), callerKey: key);
        await _persistence.save(
          token: _state.token!,
          refreshToken: _state.refreshToken!,
          userData: jsonEncode(_state.appUser!.toJson()),
          isAuthenticated: true,
          expiry: _state.tokenExpiry!.toIso8601String(),
        );

        _response.storeSuccess(
          key,
          result,
          statusCode: 200,
          responseCode: 'LOGIN_SUCCESS',
        );
        debugPrint('✅ Login successful for user: $username');

        _state.setLoading(false);
        _notify();
        return true;
      }

      debugPrint('⚠️ Login failed for user: $username');
      _response.storeFailure(
        key,
        result,
        statusCode: 401,
        errorCode: 'LOGIN_FAILED',
        message: 'Invalid credentials',
      );
      _state.setLoading(false);
      _notify();
      return false;
    } catch (e) {
      debugPrint('❌ Login error: $e');
      _response.storeFailure(
        key,
        e.toString(),
        statusCode: 500,
        errorCode: 'LOGIN_ERROR',
        message: 'Login error occurred',
      );
      _state.setLoading(false);
      _notify();
      rethrow;
    }
  }

  Future<AppUser?> signInWithGoogle(dynamic data, {String? callerKey}) async {
    final key = callerKey ?? _response.generateKey('signInGoogle');

    try {
      _state.setLoading(true);
      _notify();

      debugPrint('🔐 Google sign in initiated');

      _state.token = data['token']?['access_token'] ?? data['access_token'];
      _state.refreshToken =
          data['token']?['refresh_token'] ?? data['refresh_token'];
      _state.expiresIn =
          data['token']?['expires_in'] ?? data['expires_in'] ?? 3600;
      _state.tokenExpiry =
          DateTime.now().add(Duration(seconds: _state.expiresIn!));
      _state.appUser =
          data['user'] != null ? AppUser.fromGoogleJson(data) : null;

      if (_state.token == null || _state.appUser == null) {
        throw Exception('Invalid Google login response');
      }

      _state.isAuthenticated = true;
      await _persistence.save(
        token: _state.token!,
        refreshToken: _state.refreshToken!,
        userData: jsonEncode(_state.appUser!.toJson()),
        isAuthenticated: true,
        expiry: _state.tokenExpiry!.toIso8601String(),
      );

      _response.storeSuccess(
        key,
        _state.appUser,
        statusCode: 200,
        responseCode: 'GOOGLE_LOGIN_SUCCESS',
      );
      debugPrint('✅ Google sign-in successful');

      _state.setLoading(false);
      _notify();
      return _state.appUser;
    } catch (e) {
      debugPrint('❌ Google sign-in error: $e');
      _response.storeFailure(
        key,
        e.toString(),
        statusCode: 500,
        errorCode: 'GOOGLE_SIGNIN_ERROR',
        message: 'Google sign in failed',
      );
      _state.setLoading(false);
      _state.reset();
      await _persistence.clear();
      _notify();
      rethrow;
    }
  }

  Future<AppUser?> signInWithFacebook({String? callerKey}) async {
    final key = callerKey ?? _response.generateKey('signInFacebook');

    try {
      _state.setLoading(true);
      _notify();

      final result = await _authService.signInWithFacebook();

      _state.setLoading(false);
      _notify();

      if (result != null) {
        _response.storeSuccess(
          key,
          result,
          statusCode: 200,
          responseCode: 'FACEBOOK_LOGIN_SUCCESS',
        );
      }
      return result;
    } catch (e) {
      _response.storeFailure(
        key,
        e.toString(),
        statusCode: 500,
        errorCode: 'FACEBOOK_SIGNIN_ERROR',
        message: 'Facebook sign in failed',
      );
      _state.setLoading(false);
      _notify();
      rethrow;
    }
  }

  Future<dynamic> signUpWithData(
    Map<String, dynamic> data, {
    String? callerKey,
  }) async {
    final key = callerKey ??
        _response.generateKey('signUp',
            suffix: data['appUserName']?.toString());

    try {
      _state.setLoading(true);
      _notify();

      final result = await _authService.signUpWithData(data);

      if (result['idAppUser'] != null) {
        final accessToken = result['access_token'];
        final refreshToken = result['refresh_token'];
        final expiresIn = result['expires_in'] ?? 3600;

        if (accessToken != null) {
          _state.setTokens(accessToken, refreshToken ?? '', expiresIn);
          _state.isAuthenticated = true;
          await _user.fetch(result['idAppUser'].toString(), callerKey: key);
          await _persistence.save(
            token: _state.token!,
            refreshToken: _state.refreshToken!,
            userData: jsonEncode(_state.appUser!.toJson()),
            isAuthenticated: true,
            expiry: _state.tokenExpiry!.toIso8601String(),
          );
        }

        _response.storeSuccess(
          key,
          result,
          statusCode: 200,
          responseCode: 'SIGNUP_SUCCESS',
        );
      } else {
        _response.storeFailure(
          key,
          result,
          statusCode: 400,
          errorCode: 'SIGNUP_FAILED',
          message: 'Sign up failed',
        );
      }

      _state.setLoading(false);
      _notify();
      return result;
    } catch (e) {
      _response.storeFailure(
        key,
        e.toString(),
        statusCode: 500,
        errorCode: 'SIGNUP_ERROR',
        message: 'Sign up failed',
      );
      _state.setLoading(false);
      _notify();
      rethrow;
    }
  }

  Future<void> signInAsGuest({String? callerKey}) async {
    final key = callerKey ?? _response.generateKey('signInGuest');

    _state.appUser = AppUser.empty();
    _state.isAuthenticated = false;
    _state.token = null;
    _state.refreshToken = null;
    _state.tokenExpiry = null;
    await _persistence.clear();

    _response.storeSuccess(
      key,
      _state.appUser,
      statusCode: 200,
      responseCode: 'GUEST_LOGIN',
    );
    _notify();
  }

  Future<void> signOut({String? callerKey}) async {
    final key = callerKey ?? _response.generateKey('signOut');

    try {
      _state.setLoading(true);
      _notify();

      await _persistence.clear();
      _state.reset();

      _response.storeSuccess(
        key,
        true,
        statusCode: 200,
        responseCode: 'SIGNOUT_SUCCESS',
      );

      _state.setLoading(false);
      _notify();

      debugPrint('User signed out successfully');
    } catch (e) {
      _response.storeFailure(
        key,
        e.toString(),
        statusCode: 500,
        errorCode: 'SIGNOUT_ERROR',
        message: 'Sign out failed',
      );
      _state.setLoading(false);
      _notify();
      rethrow;
    }
  }

  // ============ USER CRUD ============

  Future<int?> addAppUser(AppUser user, {String? callerKey}) async {
    final key = _response.generateKey('addUser', suffix: user.appUserName);
    try {
      final result = await _crud.addUser(user, callerKey: key);
      _notify();
      if (result != null && result > 0) {
        _response.storeSuccess(
          key,
          result,
          statusCode: 200,
          responseCode: 'CREATED',
        );
      }
      return result;
    } catch (e) {
      _response.storeFailure(
        key,
        e.toString(),
        errorCode: 'ADD_USER_ERROR',
        message: 'Failed to add user',
      );
      return null;
    }
  }

  Future<int?> updateAppUserImage(AppUser user, {String? callerKey}) async {
    final key = _response.generateKey(
      'updateImage',
      id: user.idAppUser?.toString(),
    );
    try {
      final result = await _crud.updateImage(user, callerKey: key);
      _notify();
      if (result != null && result > 0) {
        _response.storeSuccess(
          key,
          result,
          statusCode: 200,
          responseCode: 'IMAGE_UPDATED',
        );
      }
      return result;
    } catch (e) {
      _response.storeFailure(
        key,
        e.toString(),
        errorCode: 'UPDATE_IMAGE_ERROR',
        message: 'Failed to update user image',
      );
      return null;
    }
  }

  Future<int?> deleteAppUser(String id, {String? callerKey}) async {
    final key = _response.generateKey('deleteUser', id: id);
    try {
      final result = await _crud.deleteUser(id, callerKey: key);
      _notify();
      if (result != null && result > 0) {
        _response.storeSuccess(
          key,
          result,
          statusCode: 200,
          responseCode: 'DELETED',
        );
      }
      return result;
    } catch (e) {
      _response.storeFailure(
        key,
        e.toString(),
        errorCode: 'DELETE_USER_ERROR',
        message: 'Failed to delete user',
      );
      return null;
    }
  }

  // ============ UI STATE ============

  void setSelectedTabIndex(int index) {
    _state.setSelectedTab(index);
    _notify();
  }

  // ============ RESPONSE RETRIEVAL ============

  CallerResponse? getResponse(String key) => _response.getResponse(key);
  bool isSuccess(String key) => _response.isSuccess(key);
  dynamic getResponseData(String key) => _response.getData(key);
  int? getStatusCode(String key) => _response.getStatusCode(key);
  String? getResponseCode(String key) => _response.getResponseCode(key);
  String? getErrorMessage(String key) => _response.getErrorMessage(key);
  void clearResponse(String key) => _response.clearResponse(key);
  void clearAllResponses() => _response.clearAllResponses();

  // ============ RESET ============

  void reset() {
    _state.reset();
    _notify();
  }
}
