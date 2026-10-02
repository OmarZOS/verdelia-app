import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verdelia_core/app/AppUser.dart';

class AuthPersistence {
  static const String _TOKEN_KEY = 'auth_token';
  static const String _REFRESH_TOKEN_KEY = 'auth_refresh_token';
  static const String _USER_DATA_KEY = 'user_data';
  static const String _AUTH_KEY = 'is_authenticated';
  static const String _EXPIRY_KEY = 'token_expiry';

  // ============ LOAD ============

  Future<Map<String, dynamic>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_TOKEN_KEY);
      final refreshToken = prefs.getString(_REFRESH_TOKEN_KEY);
      final userData = prefs.getString(_USER_DATA_KEY);
      final isAuthenticated = prefs.getBool(_AUTH_KEY) ?? false;
      final expiry = prefs.getString(_EXPIRY_KEY);

      return {
        'token': token,
        'refreshToken': refreshToken,
        'userData': userData,
        'isAuthenticated': isAuthenticated,
        'expiry': expiry,
      };
    } catch (e) {
      debugPrint('❌ Error loading auth data: $e');
      return {};
    }
  }

  // ============ SAVE ============

  Future<void> save({
    required String token,
    required String refreshToken,
    required String userData,
    required bool isAuthenticated,
    required String expiry,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_TOKEN_KEY, token);
      await prefs.setString(_REFRESH_TOKEN_KEY, refreshToken);
      await prefs.setString(_USER_DATA_KEY, userData);
      await prefs.setBool(_AUTH_KEY, isAuthenticated);
      await prefs.setString(_EXPIRY_KEY, expiry);
      debugPrint('✅ Auth data saved successfully');
    } catch (e) {
      debugPrint('❌ Error saving auth data: $e');
    }
  }

  // ============ CLEAR ============

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_TOKEN_KEY);
      await prefs.remove(_REFRESH_TOKEN_KEY);
      await prefs.remove(_USER_DATA_KEY);
      await prefs.remove(_AUTH_KEY);
      await prefs.remove(_EXPIRY_KEY);
      debugPrint('🗑️ Auth data cleared');
    } catch (e) {
      debugPrint('❌ Error clearing auth data: $e');
    }
  }

  // ============ USER DATA PARSING ============

  AppUser? parseUserData(String? userData) {
    if (userData == null || userData.isEmpty) return null;

    try {
      final json = jsonDecode(userData);

      // Try both formats
      try {
        return AppUser.fromPersistedJson(json);
      } catch (e) {
        debugPrint('⚠️ Failed to parse as persisted JSON: $e');
        try {
          return AppUser.fromJson(json);
        } catch (e2) {
          debugPrint('⚠️ Failed to parse as API JSON: $e2');
          return null;
        }
      }
    } catch (e) {
      debugPrint('❌ Error parsing user data: $e');
      return null;
    }
  }
}
