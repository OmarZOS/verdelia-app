import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:convert';

class GoogleLoginManager {
  static AppLinks? _appLinks;
  static StreamSubscription<Uri>? _linkSubscription;
  static Completer<Map<String, dynamic>>? _loginCompleter;

  static Future<Map<String, dynamic>?> loginWithGoogle({
    required BuildContext context,
  }) async {
    const loginUrl = 'https://verdelia.com/api/login/google';

    // Initialize if not already done
    if (_appLinks == null) {
      initialize();
    }

    // Initialize deep link listening
    await _initDeepLinks();

    try {
      final launched = await launchUrl(
        Uri.parse(loginUrl),
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception('Could not launch browser');
      }

      // Wait for the deep link callback with a timeout
      _loginCompleter = Completer<Map<String, dynamic>>();

      return await _loginCompleter!.future.timeout(
        const Duration(seconds: 120),
        onTimeout: () {
          throw TimeoutException('Login timed out');
        },
      );
    } catch (e) {
      _cancelDeepLinkListener();
      rethrow;
    }
  }

  static Future<void> _initDeepLinks() async {
    try {
      // Cancel any existing subscription
      _cancelDeepLinkListener();

      // Listen for incoming links
      _linkSubscription = _appLinks!.uriLinkStream.listen(
        (Uri uri) {
          print('🔗 Deep link received: $uri');
          _handleIncomingLink(uri);
        },
        onError: (err) {
          print('❌ Deep link error: $err');
          _completeWithError('Deep link error: $err');
        },
      );

      // Check if app was started by a deep link
      final initialUri = await _appLinks!.getInitialLink();
      if (initialUri != null) {
        print('🚀 Initial deep link: $initialUri');
        _handleIncomingLink(initialUri);
      }
    } catch (e) {
      print('❌ Failed to initialize deep links: $e');
      _completeWithError('Failed to initialize deep links: $e');
    }
  }

  static void _handleIncomingLink(Uri uri) {
    print('📥 Processing URI: ${uri.toString()}');
    print('   Scheme: ${uri.scheme}');
    print('   Host: ${uri.host}');
    print('   Path: ${uri.path}');
    print('   Query params: ${uri.queryParameters}');

    // Check if this is our callback URL
    if (_isCallbackUrl(uri)) {
      _handleCallback(uri);
    } else {
      print('⚠️ URI does not match callback pattern');
    }
  }

  static bool _isCallbackUrl(Uri uri) {
    // TODO: Replace 'yourapp' with your actual app scheme
    final isMatch = uri.scheme == 'verdelia' &&
        uri.host == 'auth' &&
        uri.path == '/callback';

    print('🔍 Callback URL match: $isMatch');
    return isMatch;
  }

  static void _handleCallback(Uri uri) {
    try {
      print('✅ Processing callback: ${uri.queryParameters}');

      Map<String, dynamic> result = {};

      if (uri.queryParameters.containsKey('data')) {
        final encodedData = uri.queryParameters['data']!;
        print('📦 Encoded data: $encodedData');

        final decodedData = Uri.decodeComponent(encodedData);
        print('📖 Decoded data: $decodedData');

        final data = jsonDecode(decodedData);
        result = Map<String, dynamic>.from(data);

        print('✨ Final result: $result');
      } else if (uri.queryParameters.containsKey('error')) {
        throw Exception(uri.queryParameters['error']!);
      } else {
        // Include all query parameters in the result
        result = uri.queryParameters.map((key, value) => MapEntry(key, value));
        print('📋 Using query params as result: $result');
      }

      _completeWithSuccess(result);
    } catch (e) {
      print('❌ Failed to process callback: $e');
      _completeWithError('Failed to process login: $e');
    }
  }

  static void _completeWithSuccess(Map<String, dynamic> data) {
    if (_loginCompleter != null && !_loginCompleter!.isCompleted) {
      _loginCompleter!.complete(data);
      print('✅ Login completed successfully');
    }
    _cancelDeepLinkListener();
  }

  static void _completeWithError(String error) {
    if (_loginCompleter != null && !_loginCompleter!.isCompleted) {
      _loginCompleter!.completeError(error);
      print('❌ Login completed with error: $error');
    }
    _cancelDeepLinkListener();
  }

  static void _cancelDeepLinkListener() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
  }

  // Call this when your app starts (in main.dart or app initialization)
  static void initialize() {
    _cancelDeepLinkListener();
    _appLinks = AppLinks();
    print('🎯 GoogleLoginManager initialized');
  }

  // Call this when your widget disposes
  static void dispose() {
    _cancelDeepLinkListener();
    if (_loginCompleter != null && !_loginCompleter!.isCompleted) {
      _loginCompleter!.completeError('Cancelled');
    }
  }
}
// ```

// ## Backend Requirements:

// Your backend needs to redirect to this URL after successful Google login:
// ```
// yourapp://auth/callback?data=ENCODED_JSON_DATA
