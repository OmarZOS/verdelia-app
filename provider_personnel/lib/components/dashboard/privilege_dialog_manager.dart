import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/app/AppUser.dart';
import 'package:event/personnel_notifier.dart';
import 'package:provider_personnel/components/privilege_dialog/privilege_dialog.dart';

class PrivilegeDialogManager {
  static Future<void> showPrivilegeDialog({
    required BuildContext context,
    required AppUser user,
    required bool isPending,
    required int ruleId,
    required int supplierId,
    required String supplierName,
    required PersonnelNotifier personnelNotifier,
    required int orgId,
    required VoidCallback onRefresh,
  }) async {
    int? existingPrivileges;

    if (!isPending) {
      // First ensure data is loaded
      await personnelNotifier.loadPersonnel(
        userId: user.idAppUser ?? 0,
        supplierId: supplierId,
      );

      // Then get the rule synchronously from cache
      final rule = personnelNotifier.getRuleForUser(
        userId: user.idAppUser ?? 0,
        ruleId: ruleId,
        supplierId: supplierId,
      );

      if (rule != null) {
        existingPrivileges = rule.managementRuleCode;
      }
    }

    if (!context.mounted) return;

    final privilegesBitmask = await showDialog<int>(
      context: context,
      builder: (context) => PrivilegeDialog(
        user: user,
        supplierName: supplierName,
        initialPrivileges: existingPrivileges,
      ),
    );

    if (privilegesBitmask != null && context.mounted && !isPending) {
      await _modifyUserPrivileges(
        context: context,
        user: user,
        privileges: privilegesBitmask,
        ruleId: ruleId,
        personnelNotifier: personnelNotifier,
        supplierId: supplierId,
        orgId: orgId,
        onRefresh: onRefresh,
      );
    }
  }

  static Future<void> _modifyUserPrivileges({
    required BuildContext context,
    required AppUser user,
    required int privileges,
    required int ruleId,
    required PersonnelNotifier personnelNotifier,
    required int supplierId,
    required int orgId,
    required VoidCallback onRefresh,
  }) async {
    try {
      // Ensure data is loaded
      await personnelNotifier.loadPersonnel(
        userId: user.idAppUser ?? 0,
        supplierId: supplierId,
      );

      // Get the rule from cache
      final rule = personnelNotifier.getRuleForUser(
        userId: user.idAppUser ?? 0,
        ruleId: ruleId,
        supplierId: supplierId,
      );

      if (rule == null) {
        debugPrint('Rule not found for user ${user.idAppUser}');
        return;
      }

      final success = await personnelNotifier.updateTeamMemberPrivileges(
        ruleId: rule.idManagementRule ?? 0,
        userId: user.idAppUser ?? 0,
        supplierId: supplierId,
        orgId: orgId,
        privilege: privileges,
      );

      if (context.mounted) {
        final localizations = AppLocalizations.of(context)!;
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? localizations
                      .privilegesUpdatedMessage(user.personFirstName ?? "")
                  : localizations.privilegesUpdateFailedMessage,
            ),
            backgroundColor: success ? colorScheme.tertiary : colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        onRefresh();
      }
    } catch (e) {
      debugPrint('Error modifying user privileges: $e');

      if (context.mounted) {
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.privilegesUpdateFailedMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }
}
