import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/app/AppUser.dart';
import 'package:provider_store/components/dashboard/dashboard_content.dart';
import 'package:provider/provider.dart';
import 'package:event/personnel_notifier.dart';
import 'package:event/supplier_change_notifier.dart';
import 'package:event/user_change_notifier.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupplierChangeNotifier>().fetchSuppliers(reset: true);
      context
          .read<PersonnelNotifier>()
          .loadPersonnel(supplierId: 0, includePending: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<AppUserNotifier, PersonnelNotifier,
        SupplierChangeNotifier>(
      builder: (context, userNotifier, personnelNotifier, supplierNotifier, _) {
        final currentUser = userNotifier.appUser;

        if (currentUser == null) {
          return _buildLoadingScreen(context);
        }

        return DashboardContent(
          currentUser: currentUser,
          personnelNotifier: personnelNotifier,
          supplierNotifier: supplierNotifier,
        );
      },
    );
  }

  Widget _buildLoadingScreen(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              localizations?.loading ?? 'Loading...',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
