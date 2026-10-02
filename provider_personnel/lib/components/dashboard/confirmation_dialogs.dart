import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

class ConfirmationDialogs {
  static Future<bool?> showCancelInvitationDialog({
    required BuildContext context,
    required dynamic user,
    required VoidCallback onConfirm,
  }) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.cancelInvitationTitle),
        content: Text(localizations.cancelInvitationMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localizations.cancelText),
          ),
          ElevatedButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
            ),
            child: Text(localizations.cancelInvitationAction),
          ),
        ],
      ),
    );
  }

  static void showRemoveMemberDialog({
    required BuildContext context,
    required String userName,
    required String supplierName,
    required VoidCallback onConfirm,
  }) {
    final localizations = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.removeTeamMemberTitle),
        content:
            Text(localizations.removeTeamMemberMessage(userName, supplierName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancelText),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(localizations.removeAction),
          ),
        ],
      ),
    );
  }
}
