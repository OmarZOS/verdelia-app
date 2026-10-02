import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/app/AppUser.dart';
import 'package:event/user_change_notifier.dart';
import 'package:provider/provider.dart';

bool isProductOwner(BuildContext context, int ownerId) {
  AppUser appUser =
      Provider.of<AppUserNotifier>(context, listen: false).appUser!;

  return appUser.idAppUser == ownerId || appUser.isAdmin;
}
