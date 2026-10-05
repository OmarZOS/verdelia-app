import 'package:flutter/material.dart';
import 'package:verdelia_core/app/AppUser.dart';
import 'package:provider_personnel/components/supplier_user_card.dart';
import 'package:event/personnel_notifier.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class PendingTabContent extends StatelessWidget {
  final int supplierId;
  final String supplierName;
  final RefreshCallback onRefresh;
  final Function onShowPrivilegeDialog;
  final Function onShowRemoveDialog;
  final Function onCancelInvitation;
  final VoidCallback onShowAddOptions;
  final bool canManage;

  /// Called when the user taps a tile's body (anywhere except the
  /// trailing action buttons). The parent routes to the visited
  /// profile. When null, tiles are not tappable.
  final void Function(AppUser user)? onProfileTap;

  const PendingTabContent({
    super.key,
    required this.supplierId,
    required this.supplierName,
    required this.onRefresh,
    required this.onShowPrivilegeDialog,
    required this.onShowRemoveDialog,
    required this.onCancelInvitation,
    required this.onShowAddOptions,
    this.canManage = true,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PersonnelNotifier>(
      builder: (context, notifier, _) {
        final allUsers = notifier.getPersonnelForSupplier(
          supplierId,
          includePending: true,
        );

        final pendingUsers = allUsers.where((user) {
          final userId = user.idAppUser ?? 0;
          return notifier.hasPendingRulesForSupplier(userId, supplierId);
        }).toList();

        if (notifier.isLoading && pendingUsers.isEmpty) {
          return const _LoadingShimmer();
        }

        if (pendingUsers.isEmpty) {
          return _EmptyState(
            onShowAddOptions: onShowAddOptions,
            canManage: canManage,
          );
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pendingUsers.length,
            itemBuilder: (context, index) {
              final user = pendingUsers[index];
              final pendingRule = notifier
                  .getPendingRulesForUser(
                    user.idAppUser ?? 0,
                    supplierId: supplierId,
                  )
                  .firstOrNull;

              return SupplierUserCard(
                user: user,
                supplierId: supplierId,
                ruleCode: pendingRule?.managementRuleCode ?? 0,
                isPending: true,
                onManagePrivileges: () => onShowPrivilegeDialog(
                  user,
                  true,
                  pendingRule?.idManagementRule,
                ),
                onRemove: () =>
                    onShowRemoveDialog(pendingRule?.idManagementRule, user),
                onCancelInvite: canManage
                    ? () => onCancelInvitation(
                          user,
                          pendingRule?.idManagementRule,
                        )
                    : null,
                showActions: canManage,
                onTap: onProfileTap == null ? null : () => onProfileTap!(user),
              );
            },
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Empty state
// ══════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final VoidCallback onShowAddOptions;
  final bool canManage;

  const _EmptyState({
    required this.onShowAddOptions,
    required this.canManage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.access_time,
              size: 80,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n?.noPendingInvitations ?? 'No Pending Invitations',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              l10n?.noPendingInvitationsMessage ??
                  'All invitations have been accepted or no pending invites exist.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: canManage ? onShowAddOptions : null,
              icon: const Icon(Icons.person_add),
              label: Text(l10n?.inviteNewMember ?? 'Invite New Member'),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Loading shimmer
// ══════════════════════════════════════════════════════════════════

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: cs.surfaceVariant,
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 16,
                      color: cs.surfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 80,
                      height: 14,
                      color: cs.surfaceVariant,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
