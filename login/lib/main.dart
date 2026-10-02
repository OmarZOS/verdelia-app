import 'package:flutter/material.dart';
import 'package:verdelia_core/app/Services/AuthService.dart';
import 'package:verdelia_core/app/Services/UserService.dart';
import 'package:event/user_change_notifier.dart';
import 'package:login/screens/login_screen.dart';
import 'package:locator/locator.dart';
import 'package:provider/provider.dart';

import 'package:verdelia_core/mediation/StorageService.dart';

void main() {
  // AppLocator.registerSingletonService<AppUserService>(AppUserServiceImpl());
  // AppLocator.registerSingletonService<StorageService>(StorageServiceImpl());
  // AppLocator.registerSingletonService<AuthService>(AuthServiceImpl());

  runApp(
    ChangeNotifierProvider(
      create: (context) => AppUserNotifier(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppUserNotifier(),
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: LoginScreen(),
      ),
    );
  }
}
