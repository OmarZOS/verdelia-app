import 'package:event/user_change_notifier.dart';
import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/app/ManagementRule.dart';
import 'package:verdelia_core/business/privileges/role_bit_mapper.dart';
import 'package:event/personnel_notifier.dart';
import 'package:provider_personnel/components/privilege_ui.dart';
import 'package:provider/provider.dart';

class PendingInvitationsDialog extends StatelessWidget {
  final List<ManagementRule> pendingRules;
  final PersonnelNotifier personnelNotifier;

  const PendingInvitationsDialog({
    required this.pendingRules,
    required this.personnelNotifier,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(
        localizations?.pendingInvitations ?? 'Pending Invitations',
        style: theme.textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: pendingRules.length,
          itemBuilder: (context, index) {
            final rule = pendingRules[index];
            return PendingInvitationItem(
              rule: rule,
              personnelNotifier: personnelNotifier,
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            localizations?.close ?? 'Close',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: colorScheme.surface,
    );
  }
}

class PendingInvitationItem extends StatelessWidget {
  final ManagementRule rule;
  final PersonnelNotifier personnelNotifier;

  const PendingInvitationItem({
    required this.rule,
    required this.personnelNotifier,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);
    final supplierName = rule.productProvider?.providerName ??
        localizations?.unknownBusiness ??
        'Unknown Business';
    // final privilegeIds = RoleBitMapper.numberToPrivilegeIds(
    //   rule.management_rule_code ?? 0,
    // );
    final accessSummary = PrivilegeUIManager.getAccessLevelSummary(
      rule.managementRuleCode,
      context: context,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: colorScheme.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.business,
            size: 20,
            color: colorScheme.primary,
          ),
        ),
        title: Text(
          supplierName,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          '${localizations?.role ?? 'Role'}: $accessSummary',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.check, color: colorScheme.primary),
              onPressed: () => _answerInvitation(context, true),
              tooltip: localizations?.accept ?? 'Accept',
            ),
            IconButton(
              icon: Icon(Icons.close, color: colorScheme.error),
              onPressed: () => _answerInvitation(context, false),
              tooltip: localizations?.decline ?? 'Decline',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _answerInvitation(BuildContext context, bool accept) async {
    final success = await personnelNotifier.answerInvitation(
      ruleId: rule.idManagementRule ?? 0,
      answer: accept ? 0 : 1,
      token: Provider.of<AppUserNotifier>(context, listen: false).token ?? '',
    );

    if (success && context.mounted) {
      Navigator.pop(context);
      final colorScheme = Theme.of(context).colorScheme;
      final localizations = AppLocalizations.of(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accept
                ? localizations?.invitationAccepted ?? 'Invitation accepted!'
                : localizations?.invitationDeclined ?? 'Invitation declined.',
            style: TextStyle(color: colorScheme.onPrimary),
          ),
          backgroundColor: accept ? colorScheme.primary : colorScheme.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}
