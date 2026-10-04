import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

class ConfirmationDialogs {
  /// Confirmation dialog for cancelling a pending invitation.
  ///
  /// Returns `true` when the user confirms, `false` or `null` when
  /// they back out. The caller decides what to do with the result —
  /// the dialog doesn't invoke [onConfirm] itself, so the await site
  /// can refresh state and show a snackbar after the modal closes.
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
      builder: (dialogContext) => AlertDialog(
        title: Text(localizations.cancelInvitationTitle),
        content: Text(localizations.cancelInvitationMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(localizations.cancelText),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
              onConfirm();
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

  /// Confirmation dialog for removing an active team member.
  ///
  /// Same shape as [showCancelInvitationDialog]. The result is
  /// informative — the caller can await it to know whether to show a
  /// success snackbar.
  static Future<bool?> showRemoveMemberDialog({
    required BuildContext context,
    required String userName,
    required String supplierName,
    required VoidCallback onConfirm,
  }) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(localizations.removeTeamMemberTitle),
        content: Text(
          localizations.removeTeamMemberMessage(userName, supplierName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(localizations.cancelText),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
              onConfirm();
            },
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.error,
            ),
            child: Text(localizations.removeAction),
          ),
        ],
      ),
    );
  }
}
