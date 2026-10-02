import 'package:verdelia_core/app/TraceableService.dart';

import '../AppUser.dart';

// AuthService.dart
abstract class AuthService extends TraceableService {
  // Sign up with email and password
  Future<dynamic> signUpWithData(Map<String, dynamic> data,
      {String? callerKey}) async {
    // UserCredential userCredential = await _firebaseAuth.createUserWithUsernameAndPassword(Username: Username, password: password);
    throw UnimplementedError();
  }

  // Sign in with Username and password
  Future<dynamic> signInWithUsernameAndPassword(
      String username, String password,
      {String? callerKey}) async {
    throw UnimplementedError();
  }

  // Sign in with Google
  Future<AppUser?> signInWithGoogle() async {
    throw UnimplementedError();
  }

  // Sign in with Facebook
  Future<AppUser?> signInWithFacebook() async {
    throw UnimplementedError();
  }

  Future<dynamic> refreshTokenNow(String refreshToken,
      {String? callerKey}) async {
    throw UnimplementedError();
  }

  // Sign out
  Future<void> signOut() async {
    throw UnimplementedError();
  }

  // // Sign in with Instagram
  // Future<AppUser?> signInWithInstagram() async {
  //   throw UnimplementedError();
  // }
}
