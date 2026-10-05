import 'package:flutter/material.dart';
import 'package:verdelia_core/app/ManagementRule.dart';
import 'package:provider_personnel/components/supplier_user_card.dart';
import 'package:event/personnel_notifier.dart';
import 'package:verdelia_core/app/AppUser.dart';
import 'package:provider/provider.dart';

class PersonnelTabContent extends StatelessWidget {
  final int supplierId;
  final bool includePending;
  final RefreshCallback onRefresh;
  final Function onShowPrivilegeDialog;
  final Function onShowRemoveDialog;
  final Function onCancelInvitation;
  final bool canManage;

  /// Called when the user taps a tile's body (anywhere except the
  /// trailing action buttons). The parent routes to the visited
  /// profile. When null, tiles are not tappable.
  final void Function(AppUser user)? onProfileTap;

  const PersonnelTabContent({
    super.key,
    required this.supplierId,
    required this.includePending,
    required this.onRefresh,
    required this.onShowPrivilegeDialog,
    required this.onShowRemoveDialog,
    required this.onCancelInvitation,
    this.canManage = true,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PersonnelNotifier>(
      builder: (context, notifier, _) {
        final users = notifier.getPersonnelForSupplier(
          supplierId,
          includePending: includePending,
        );

        final filteredUsers = includePending
            ? users
            : users.where((user) {
                final userId = user.idAppUser ?? 0;
                return !notifier.hasPendingRulesForSupplier(userId, supplierId);
              }).toList();

        if (notifier.isLoading && filteredUsers.isEmpty) {
          return const _LoadingShimmer();
        }

        if (filteredUsers.isEmpty) {
          return _EmptyState(includePending: includePending);
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              final user = filteredUsers[index];
              final isPending = notifier.hasPendingRulesForSupplier(
                user.idAppUser ?? 0,
                supplierId,
              );

              ManagementRule? rule;
              if (isPending) {
                rule = notifier
                    .getPendingRulesForUser(
                      user.idAppUser ?? 0,
                      supplierId: supplierId,
                    )
                    .firstOrNull;
              } else {
                rule = notifier
                    .getRulesForUser(
                      user.idAppUser ?? 0,
                      supplierId: supplierId,
                    )
                    .firstOrNull;
              }

              return SupplierUserCard(
                user: user,
                supplierId: supplierId,
                isPending: isPending,
                ruleCode: rule?.managementRuleCode ?? 0,
                onManagePrivileges: () => onShowPrivilegeDialog(
                    user, isPending, rule?.idManagementRule),
                onRemove: () =>
                    onShowRemoveDialog(rule?.idManagementRule, user),
                onCancelInvite: isPending
                    ? canManage
                        ? () => onCancelInvitation(user, rule?.idManagementRule)
                        : null
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
  final bool includePending;

  const _EmptyState({required this.includePending});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              includePending ? Icons.people_outline : Icons.check_circle,
              size: 80,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              includePending ? 'No Team Members' : 'No Active Members',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
