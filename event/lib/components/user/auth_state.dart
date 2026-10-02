import 'package:verdelia_core/app/AppUser.dart';

class AuthState {
  AppUser? appUser;
  String? token;
  String? refreshToken;
  int? expiresIn;
  DateTime? tokenExpiry;
  bool isAuthenticated = false;
  bool isLoading = false;
  bool isRefreshing = false;
  int selectedTabIndex = 0;
  final Map<int, AppUser> userCache = {};

  // ============ GETTERS ============

  bool get hasValidToken {
    if (token == null || tokenExpiry == null) return false;
    return DateTime.now()
        .add(const Duration(minutes: 1))
        .isBefore(tokenExpiry!);
  }

  bool get needsTokenRefresh {
    if (token == null || tokenExpiry == null || refreshToken == null)
      return false;
    return DateTime.now()
        .add(const Duration(minutes: 10))
        .isAfter(tokenExpiry!);
  }

  bool get isCookingRecipe =>
      (appUser?.appUserType ?? "customer") == "cooking_recipe_catalog";

  // ============ SETTERS ============

  void setLoading(bool loading) {
    isLoading = loading;
  }

  void setRefreshing(bool refreshing) {
    isRefreshing = refreshing;
  }

  void setTokens(String accessToken, String refreshToken, int expiresIn) {
    token = accessToken;
    this.refreshToken = refreshToken;
    this.expiresIn = expiresIn;
    tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
    isAuthenticated = true;
  }

  void clearTokens() {
    token = null;
    refreshToken = null;
    expiresIn = null;
    tokenExpiry = null;
    isAuthenticated = false;
  }

  void setUser(AppUser user) {
    appUser = user;
    isAuthenticated = true;
  }

  void clearUser() {
    appUser = null;
    isAuthenticated = false;
  }

  void setSelectedTab(int index) {
    selectedTabIndex = index;
  }

  // ============ USER CACHE ============

  void cacheUser(AppUser user) {
    if (user.idAppUser != null && user.idAppUser != 0) {
      userCache[user.idAppUser!] = user;
    }
  }

  AppUser? getCachedUser(int id) => userCache[id];

  void clearUserCache() {
    userCache.clear();
  }

  // ============ RESET ============

  void reset() {
    appUser = null;
    token = null;
    refreshToken = null;
    expiresIn = null;
    tokenExpiry = null;
    isAuthenticated = false;
    isLoading = false;
    isRefreshing = false;
    selectedTabIndex = 0;
    userCache.clear();
  }
}
