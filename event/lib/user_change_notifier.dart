import 'dart:async';
import 'dart:convert';

import 'package:app_constants/app_constants.dart';
import 'package:event/components/plan_cache.dart';
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
import 'package:verdelia_core/app/finance/Plan.dart';
import 'package:verdelia_core/app/finance/Subscription.dart';
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
  late final PlanCache _planCache;

  // Subscription state — kept here rather than in AuthState because
  // it's fetched lazily and can be null even for authenticated users.
  List<Plan> _plans = const [];
  Subscription? _subscription;
  bool _isFetchingPlans = false;
  bool _isFetchingSubscription = false;
  bool _isSubscriptionActive = false;

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
    _planCache = PlanCache();
  }

  Plan? planById(int? planId) {
    if (planId == null || planId <= 0) return null;
    for (final p in _plans) {
      if (p.idPlan == planId) return p;
    }
    return null;
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

  /// Cached plan catalogue. Empty until [fetchPlans] or [fetchPlan]
  /// populates it.
  List<Plan> get plans => List.unmodifiable(_plans);
  bool get isFetchingPlans => _isFetchingPlans;

  /// Current user's subscription, if fetched. Null is a valid state —
  /// the user may be on the free tier.
  Subscription? get subscription => _subscription;
  bool get isFetchingSubscription => _isFetchingSubscription;

  /// Boolean status from the lightweight endpoint. Defaults to false
  /// until refreshed.
  bool get isSubscriptionActive => _isSubscriptionActive;

  /// True when the user has a subscription ref on the user row but the
  /// full snapshot hasn't been fetched yet.
  bool get hasPendingSubscriptionFetch =>
      _state.appUser?.hasSubscription == true && _subscription == null;

  // ============ FORCED SIGN-OUT ============

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
    _resetSubscriptionState();

    _response.storeFailure(
      callerKey,
      reason,
      statusCode: 401,
      errorCode: 'REFRESH_FAILED',
      message: 'Session expired — please sign in again',
    );

    _notify();
  }

  void _resetSubscriptionState() {
    _subscription = null;
    _isSubscriptionActive = false;
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

      if (token != null) _state.token = token;
      if (refreshToken != null) _state.refreshToken = refreshToken;

      if (expiry != null && expiry.isNotEmpty) {
        _state.tokenExpiry = DateTime.tryParse(expiry);
      }

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

      if (_state.appUser != null) {
        _response.storeSuccess(
          key,
          _state.appUser,
          statusCode: 200,
          responseCode: 'AUTH_RESTORED',
        );
        debugPrint('✅ Auth state restored: ${_state.appUser?.appUserName}');

        // Kick off a passive subscription status check so the UI
        // knows whether to show premium features without waiting on a
        // full subscription fetch.
        unawaited(_refreshSubscriptionStatusInBackground());
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
      _resetSubscriptionState();
      _notify();
    }
  }

  /// Fire-and-forget status check after auth restore. Never throws,
  /// never blocks init. If it fails, the UI stays with `false` and
  /// the next explicit check fixes it.
  Future<void> _refreshSubscriptionStatusInBackground() async {
    final userId = _state.appUser?.idAppUser;
    if (userId == null || userId <= 0) return;
    try {
      await fetchSubscriptionStatus(userId.toString());
    } catch (_) {
      // Swallowed — status is advisory at this point.
    }
  }

  // ============ TOKEN MANAGEMENT ============

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

  Future<bool> ensureValidToken({String? callerKey}) async {
    final key = callerKey ?? _response.generateKey('ensureValidToken');

    final ok = await _token.ensureValid(callerKey: key);

    if (ok) {
      _notify();
      return true;
    }

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

        // Reset subscription state on new login — the previous user's
        // subscription isn't relevant.
        _resetSubscriptionState();

        _state.setLoading(false);
        _notify();

        // Populate the subscription status for the freshly signed-in
        // user.
        unawaited(_refreshSubscriptionStatusInBackground());

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

      _resetSubscriptionState();

      _state.setLoading(false);
      _notify();

      unawaited(_refreshSubscriptionStatusInBackground());

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
      _resetSubscriptionState();
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

        _resetSubscriptionState();

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

      if (_state.appUser?.idAppUser != null) {
        unawaited(_refreshSubscriptionStatusInBackground());
      }

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

    _resetSubscriptionState();

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
      _resetSubscriptionState();

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

  // ============ PLANS ============

  /// Fetch the plan catalogue, optionally filtered.
  ///
  /// Uses the cache when [forceRefresh] is false and the same filter
  /// tuple is already populated. The cache lives on the notifier so
  /// every screen showing pricing hits the same instance.
  Future<List<Plan>> fetchPlans({
    String? planType,
    String? billingCycle,
    bool forceRefresh = false,
    String? callerKey,
  }) async {
    final key = callerKey ??
        _response.generateKey(
          'fetchPlans',
          suffix: '${planType ?? "_"}_${billingCycle ?? "_"}',
        );

    if (!forceRefresh) {
      final cached = _planCache.getList(
        planType: planType,
        billingCycle: billingCycle,
      );
      if (cached != null && cached.isNotEmpty) {
        _plans = cached;
        _response.storeSuccess(
          key,
          cached,
          statusCode: 200,
          responseCode: 'CACHED',
        );
        return cached;
      }
    }

    if (_isFetchingPlans) {
      // Coalesce concurrent callers onto the current list.
      return _plans;
    }

    try {
      _isFetchingPlans = true;
      _notify();

      final result = await _userService.getPlans(
        planType: planType,
        billingCycle: billingCycle,
        callerKey: key,
      );

      if (result == null) {
        _response.storeFailure(
          key,
          null,
          statusCode: 500,
          errorCode: 'FETCH_PLANS_FAILED',
          message: 'Failed to fetch plans',
        );
        return _plans;
      }

      _plans = result;
      _planCache.cacheList(
        result,
        planType: planType,
        billingCycle: billingCycle,
      );

      _response.storeSuccess(key, result, statusCode: 200);
      return result;
    } catch (e) {
      _response.storeFailure(
        key,
        e.toString(),
        errorCode: 'FETCH_PLANS_ERROR',
        message: 'Failed to fetch plans',
      );
      return _plans;
    } finally {
      _isFetchingPlans = false;
      _notify();
    }
  }

  /// Fetch a single plan by id. Returns the cached plan when present
  /// unless [forceRefresh] is set.
  Future<Plan?> fetchPlan(
    int planId, {
    bool forceRefresh = false,
    String? callerKey,
  }) async {
    final key = callerKey ?? _response.generateKey('fetchPlan', id: '$planId');

    if (!forceRefresh) {
      final cached = _planCache.getPlan(planId);
      if (cached != null) {
        _response.storeSuccess(
          key,
          cached,
          statusCode: 200,
          responseCode: 'CACHED',
        );
        return cached;
      }
    }

    try {
      final plan = await _userService.getPlan(planId, callerKey: key);
      if (plan == null) {
        _response.storeFailure(
          key,
          null,
          statusCode: 404,
          errorCode: 'PLAN_NOT_FOUND',
        );
        return null;
      }
      _planCache.cachePlan(plan);
      _response.storeSuccess(key, plan, statusCode: 200);
      return plan;
    } catch (e) {
      _response.storeFailure(
        key,
        e.toString(),
        errorCode: 'FETCH_PLAN_ERROR',
        message: 'Failed to fetch plan',
      );
      return null;
    }
  }

  /// Clear the plan cache. Call this after a price change is observed
  /// on the backend, or when the user pulls to refresh the pricing
  /// screen.
  void refreshPlanCache() {
    _planCache.clear();
    _plans = const [];
    _notify();
  }

  /// Toggle the plan cache on and off. Off disables reads and clears
  /// what's stored — useful in tests and debug builds.
  void enablePlanCaching(bool enable) {
    _planCache.enable(enable);
    _notify();
  }

  // ============ SUBSCRIPTION ============

  /// Fetch the current user's subscription.
  ///
  /// Returns null when the user has no subscription on file — a normal
  /// free-tier state. Callers branch on null rather than catching.
  Future<Subscription?> fetchSubscription({
    int? userId,
    bool forceRefresh = false,
    String? callerKey,
  }) async {
    final targetUserId = userId ?? _state.appUser?.idAppUser;
    if (targetUserId == null || targetUserId <= 0) {
      return null;
    }

    final key = callerKey ??
        _response.generateKey('fetchSubscription', id: '$targetUserId');

    if (!forceRefresh && _subscription != null) {
      _response.storeSuccess(
        key,
        _subscription,
        statusCode: 200,
        responseCode: 'CACHED',
      );
      return _subscription;
    }

    if (_isFetchingSubscription) {
      return _subscription;
    }

    try {
      _isFetchingSubscription = true;
      _notify();

      final result = await _userService.getSubscription(
        targetUserId,
        callerKey: key,
      );

      _subscription = result;
      _isSubscriptionActive = result?.isActive ?? false;

      if (result != null) {
        _response.storeSuccess(key, result, statusCode: 200);
      } else {
        _response.storeSuccess(
          key,
          null,
          statusCode: 200,
          responseCode: 'NO_SUBSCRIPTION',
        );
      }
      return result;
    } catch (e) {
      _response.storeFailure(
        key,
        e.toString(),
        errorCode: 'FETCH_SUBSCRIPTION_ERROR',
        message: 'Failed to fetch subscription',
      );
      return _subscription;
    } finally {
      _isFetchingSubscription = false;
      _notify();
    }
  }

  /// Check just the boolean status. Cheaper than [fetchSubscription]
  /// — no full payload, only the active flag.
  Future<bool> fetchSubscriptionStatus(
    String userId, {
    String? callerKey,
  }) async {
    final key = callerKey ??
        _response.generateKey('fetchSubscriptionStatus', id: userId);

    final id = int.tryParse(userId);
    if (id == null || id <= 0) return false;

    try {
      final active =
          await _userService.isSubscriptionActive(id, callerKey: key);
      _isSubscriptionActive = active;
      _response.storeSuccess(key, active, statusCode: 200);
      _notify();
      return active;
    } catch (e) {
      _response.storeFailure(
        key,
        e.toString(),
        errorCode: 'SUBSCRIPTION_STATUS_ERROR',
        message: 'Failed to check subscription status',
      );
      return false;
    }
  }

  /// Purchase a paid subscription. On success, refreshes the user and
  /// the subscription state so the UI reflects the new plan
  /// immediately.
  Future<SubscriptionPurchaseResult?> initiateSubscription({
    required int planId,
    required String paymentMethod,
    String? notes,
    String? callerKey,
  }) async {
    final userId = _state.appUser?.idAppUser;
    if (userId == null || userId <= 0) return null;

    final key = callerKey ??
        _response.generateKey('initiateSubscription',
            id: '$userId', suffix: 'plan_$planId');

    try {
      _state.setLoading(true);
      _notify();

      final result = await _userService.initiateSubscription(
        userId: userId,
        planId: planId,
        paymentMethod: paymentMethod,
        notes: notes,
        callerKey: key,
      );

      if (result == null) {
        _response.storeFailure(
          key,
          null,
          statusCode: 500,
          errorCode: 'SUBSCRIPTION_INITIATE_FAILED',
          message: 'Failed to purchase subscription',
        );
        return null;
      }

      _subscription = result.subscription;
      _isSubscriptionActive = result.subscription.isActive;

      // Refresh the user row so the FK and quota are up to date.
      await _user.fetch(userId.toString(), callerKey: key);

      _response.storeSuccess(key, result, statusCode: 201);
      debugPrint(
        '✅ Subscription purchased: user=$userId plan=$planId '
        'sub=${result.subscription.idSubscription}',
      );
      return result;
    } catch (e) {
      _response.storeFailure(
        key,
        e.toString(),
        errorCode: 'SUBSCRIPTION_INITIATE_ERROR',
        message: 'Failed to purchase subscription',
      );
      return null;
    } finally {
      _state.setLoading(false);
      _notify();
    }
  }

  /// Attach a zero-priced plan. Used for the default free tier and
  /// for comped plans.
  Future<Subscription?> linkFreePlan({
    required int planId,
    String? callerKey,
  }) async {
    final userId = _state.appUser?.idAppUser;
    if (userId == null || userId <= 0) return null;

    final key = callerKey ??
        _response.generateKey('linkFreePlan',
            id: '$userId', suffix: 'plan_$planId');

    try {
      _state.setLoading(true);
      _notify();

      final result = await _userService.linkFreePlan(
        userId: userId,
        planId: planId,
        callerKey: key,
      );

      if (result == null) {
        _response.storeFailure(
          key,
          null,
          statusCode: 400,
          errorCode: 'LINK_FREE_PLAN_FAILED',
          message: 'Plan is not free',
        );
        return null;
      }

      _subscription = result;
      _isSubscriptionActive = result.isActive;

      await _user.fetch(userId.toString(), callerKey: key);

      _response.storeSuccess(key, result, statusCode: 201);
      return result;
    } catch (e) {
      _response.storeFailure(
        key,
        e.toString(),
        errorCode: 'LINK_FREE_PLAN_ERROR',
        message: 'Failed to link free plan',
      );
      return null;
    } finally {
      _state.setLoading(false);
      _notify();
    }
  }

  /// Cancel the current user's subscription, optionally refunding.
  Future<AppUser?> cancelSubscription({
    int? refundPaymentId,
    String? callerKey,
  }) async {
    final userId = _state.appUser?.idAppUser;
    if (userId == null || userId <= 0) return null;

    final key =
        callerKey ?? _response.generateKey('cancelSubscription', id: '$userId');

    try {
      _state.setLoading(true);
      _notify();

      final result = await _userService.cancelSubscription(
        userId: userId,
        refundPaymentId: refundPaymentId,
        callerKey: key,
      );

      if (result == null) {
        _response.storeFailure(
          key,
          null,
          statusCode: 404,
          errorCode: 'NO_SUBSCRIPTION',
          message: 'No subscription to cancel',
        );
        return null;
      }

      _state.setUser(result);
      _resetSubscriptionState();

      _response.storeSuccess(key, result, statusCode: 200);
      return result;
    } catch (e) {
      _response.storeFailure(
        key,
        e.toString(),
        errorCode: 'CANCEL_SUBSCRIPTION_ERROR',
        message: 'Failed to cancel subscription',
      );
      return null;
    } finally {
      _state.setLoading(false);
      _notify();
    }
  }

  /// Clear the cached subscription. Call after a login switch, or when
  /// you know the backend state has changed out of band.
  void invalidateSubscription() {
    _resetSubscriptionState();
    _notify();
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

  // ============ CACHE STATS ============

  Map<String, int> getCacheStats() {
    return {
      'planListCache': _planCache.listCacheSize,
      'planCache': _planCache.planCacheSize,
    };
  }

  // ============ RESET ============

  void reset() {
    _state.reset();
    _planCache.clear();
    _plans = const [];
    _resetSubscriptionState();
    _notify();
  }
}
