import 'package:flutter/material.dart';
import 'package:verdelia_core/business/services/SupplierService.dart';
import 'package:verdelia_core/mediation/StorageService.dart';
import 'package:event/supplier_change_notifier.dart';
import 'package:provider_geo/screens/suppliers_map_screen.dart';

import 'package:locator/locator.dart';
import 'package:provider/provider.dart';

void setupLocator() {
  // Register your services or dependencies here
  // For example:
  // AppLocator.registerSingletonService<StorageService>(StorageServiceImpl());
  // AppLocator.registerSingletonService<SupplierService>(
  //     SupplierServiceImpl());
}

void main() {
  setupLocator();
  runApp(
    ChangeNotifierProvider(
      create: (context) => SupplierChangeNotifier(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'GeoJSON Map',
      home: Scaffold(
        body: SuppliersMapScreen(),
      ),
    );
  }
}
