// notification_item.dart (fixed version)

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:app_constants/app_constants.dart';
import 'package:verdelia_core/app/AppUser.dart';
// import 'package:verdelia_core/app/ManagementRule.dart';
import 'package:verdelia_core/app/Notifications/VerdeliaNotification.dart';
import 'package:verdelia_core/app/Notifications/Notifications/RoleInvitation.dart';
import 'package:verdelia_core/business/privileges/role_bit_mapper.dart';
import 'package:event/personnel_notifier.dart';
import 'package:event/supplier_change_notifier.dart';
import 'package:event/user_change_notifier.dart';
import 'package:tabbed_home/screens/components/NotificationAction.dart';
import 'package:provider_personnel/components/privilege_ui.dart';
import 'package:provider/provider.dart';

class NotificationItem extends StatelessWidget {
  static const _animationDuration = Duration(milliseconds: 300);
  static const _containerAnimationDuration = Duration(milliseconds: 400);
  static const _borderRadius = 24.0;
  static const _compactPadding = EdgeInsets.all(16);
  static const _regularPadding = EdgeInsets.all(20);
  static const _margin = EdgeInsets.symmetric(vertical: 6, horizontal: 0);

  final VerdeliaNotification notification;
  final VoidCallback? onMarkAsRead;
  final VoidCallback? onDismiss;
  final Function(NotificationAction)? onAction;
  final bool isCompact;

  const NotificationItem({
    super.key,
    required this.notification,
    this.onMarkAsRead,
    this.onDismiss,
    this.onAction,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedSize(
      duration: _animationDuration,
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(_borderRadius),
          onTap: () => _handleTap(context),
          onLongPress: _handleLongPress,
          splashColor: colorScheme.primary.withOpacity(0.15),
          highlightColor: colorScheme.primary.withOpacity(0.08),
          child: AnimatedContainer(
            duration: _containerAnimationDuration,
            curve: Curves.fastEaseInToSlowEaseOut,
            padding: isCompact ? _compactPadding : _regularPadding,
            margin: _margin,
            decoration: BoxDecoration(
              gradient: _getBackgroundGradient(context),
              borderRadius: BorderRadius.circular(_borderRadius),
              border: Border.all(
                color: notification.isRead
                    ? colorScheme.outline.withOpacity(0.08)
                    : colorScheme.primary.withOpacity(0.2),
                width: notification.isRead ? 1 : 1.2,
              ),
              boxShadow: _getBoxShadows(colorScheme),
            ),
            child: _buildContent(context),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        if (!isCompact) ...[
          const SizedBox(height: 16),
          _buildMessage(context),
          const SizedBox(height: 16),
        ],
        _buildFooter(context),
      ],
    );
  }

  List<BoxShadow> _getBoxShadows(ColorScheme colorScheme) {
    return [
      if (!notification.isRead)
        BoxShadow(
          color: colorScheme.primary.withOpacity(0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
          spreadRadius: 0.5,
        ),
      BoxShadow(
        color: colorScheme.onSurface.withOpacity(0.02),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];
  }

  void _handleTap(BuildContext context) {
    HapticFeedback.lightImpact();

    if (!notification.isRead) {
      onMarkAsRead?.call();
    }

    // Use Future.microtask to handle async operations after build
    Future.microtask(() async {
      final defaultAction = await _getDefaultAction(context);
      if (defaultAction != null) {
        onAction?.call(defaultAction);
      }
    });
  }

  void _handleLongPress() {
    HapticFeedback.mediumImpact();
  }

  Widget _buildHeader(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getUserImageUrl(context),
      builder: (context, snapshot) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNotificationIcon(context, snapshot.data),
            const SizedBox(width: 16),
            Expanded(
              child: _buildHeaderContent(context),
            ),
            if (onDismiss != null) _buildDismissButton(context),
          ],
        );
      },
    );
  }

  Widget _buildHeaderContent(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                _getNotificationTitle(localizations),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!notification.isRead) _buildUnreadIndicator(context),
          ],
        ),
        _buildSubtitle(context, localizations),
      ],
    );
  }

  Widget _buildSubtitle(BuildContext context, AppLocalizations localizations) {
    return FutureBuilder<String?>(
      future: _getNotificationSubtitle(context, localizations),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              snapshot.data!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildNotificationIcon(BuildContext context, String? userImageUrl) {
    final isRoleInvitation = notification.content?.type == 'role_invitation' ||
        notification.notificationCode == 'ROLE_INVITATION' ||
        notification.notificationCode == 'role_invitation';

    if (isRoleInvitation && userImageUrl != null && userImageUrl.isNotEmpty) {
      return _buildUserAvatar(context, userImageUrl);
    }

    return _buildIconWidget(context, _getNotificationIcon());
  }

  Widget _buildUserAvatar(BuildContext context, String imageUrl) {
    final theme = Theme.of(context);
    final size = isCompact ? 36.0 : 44.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildAvatarPlaceholder(theme, Icons.person);
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildAvatarPlaceholder(theme, Icons.error_outline);
          },
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(ThemeData theme, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: theme.colorScheme.onSurfaceVariant,
        size: 20,
      ),
    );
  }

  Widget _buildIconWidget(BuildContext context, IconData icon) {
    final size = isCompact ? 36.0 : 44.0;
    final iconSize = isCompact ? 18.0 : 22.0;

    return AnimatedContainer(
      duration: _animationDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getNotificationColor(context),
        borderRadius: BorderRadius.circular(14),
        gradient: _getNotificationGradient(context),
        boxShadow: [
          BoxShadow(
            color: _getNotificationColor(context).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Theme.of(context).colorScheme.onPrimary,
        size: iconSize,
      ),
    );
  }

  Future<String?> _getUserImageUrl(BuildContext context) async {
    final isRoleInvitation = notification.content?.type == 'role_invitation' ||
        notification.notificationCode == 'ROLE_INVITATION' ||
        notification.notificationCode == 'role_invitation';

    if (!isRoleInvitation) {
      return null;
    }

    final addedBy = notification.content?.addedBy?.toString();
    if (addedBy == null || addedBy.isEmpty) {
      return null;
    }

    try {
      final notifier = context.read<AppUserNotifier>();
      final appUser = await notifier.fetchUserPassively(addedBy);
      return appUser?.appUserImageUrl;
    } catch (error) {
      debugPrint('Error fetching user image: $error');
      return null;
    }
  }

  IconData _getNotificationIcon() {
    final code = notification.notificationCode.toLowerCase();

    switch (code) {
      case 'order_status':
      case 'order_received':
        return Icons.shopping_bag_rounded;
      case 'role_invitation':
        return Icons.people_alt_rounded;
      case 'product_updated':
        return Icons.inventory_2_rounded;
      case 'system_alert':
        return Icons.warning_rounded;
      case 'stock_alert':
        return Icons.inventory_rounded;
      case 'reminder':
        return Icons.alarm_rounded;
      case 'promotion':
        return Icons.local_offer_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Widget _buildMessage(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return FutureBuilder<String>(
      future: _getNotificationMessage(context, localizations),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Text(
            snapshot.data!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.9),
              height: 1.5,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.1,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Get the timestamp safely
    final timestamp = notification.content?.timestamp ??
        notification.notificationCreatedAt ??
        DateTime.now();

    return Row(
      children: [
        AnimatedOpacity(
          duration: _animationDuration,
          opacity: 0.8,
          child: Text(
            _formatTimeAgo(timestamp, localizations),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
        const Spacer(),
        Consumer<PersonnelNotifier>(
          builder: (context, personnel, _) {
            return _buildActions(context, localizations);
          },
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, AppLocalizations localizations) {
    return FutureBuilder<List<NotificationAction>>(
      future: _getAvailableActions(context, localizations),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final actions = snapshot.data ?? [];
        if (actions.isEmpty) return const SizedBox.shrink();

        return AnimatedSwitcher(
          duration: _animationDuration,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: actions
                .map((action) => _buildActionButton(context, action))
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildActionButton(BuildContext context, NotificationAction action) {
    final theme = Theme.of(context);

    return FilledButton.tonal(
      onPressed: () => _handleActionPress(context, action),
      style: FilledButton.styleFrom(
        backgroundColor: _getActionColor(context, action.type),
        foregroundColor: _getActionTextColor(context, action.type),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
        textStyle: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          letterSpacing: -0.1,
        ),
      ),
      child: _buildActionContent(action),
    );
  }

  Widget _buildActionContent(NotificationAction action) {
    final icon = _getActionIcon(action.type);
    if (icon == null) {
      return Text(action.label);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 6),
        Text(action.label),
      ],
    );
  }

  void _handleActionPress(BuildContext context, NotificationAction action) {
    HapticFeedback.selectionClick();

    // Handle role invitation accept/reject actions directly with PersonnelNotifier
    if (action.type == ActionType.accept || action.type == ActionType.reject) {
      final metadata = action.metadata;
      if (metadata != null && metadata['rule_id'] != null) {
        final ruleId = metadata['rule_id'] as int;
        final answer =
            action.type == ActionType.accept ? 0 : 1; // 0 = accept, 1 = reject

        // Call PersonnelNotifier to handle the invitation
        context
            .read<PersonnelNotifier>()
            .answerInvitation(
              ruleId: ruleId,
              answer: answer,
            )
            .then((success) {
          if (success) {
            // Mark notification as read
            onMarkAsRead?.call();

            // Trigger action callback
            onAction?.call(action);

            // Show feedback
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  action.type == ActionType.accept
                      ? 'Invitation accepted'
                      : 'Invitation declined',
                ),
                backgroundColor: action.type == ActionType.accept
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        });
        return;
      }
    }

    // For other actions, use the NotificationActionHandler
    // NotificationActionHandler.handle(context, action);

    // Mark as read after action
    if (!notification.isRead) {
      onMarkAsRead?.call();
    }
  }

  Widget _buildUnreadIndicator(BuildContext context) {
    return AnimatedContainer(
      duration: _animationDuration,
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primaryContainer,
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  Widget _buildDismissButton(BuildContext context) {
    final theme = Theme.of(context);

    return IconButton(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.close_rounded,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
        ),
      ),
      onPressed: () {
        HapticFeedback.lightImpact();
        onDismiss?.call();
      },
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      splashRadius: 20,
    );
  }

  // Content helper methods
  Color _getNotificationColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final code = notification.notificationCode.toLowerCase();

    switch (code) {
      case 'order_status':
      case 'order_received':
        return colorScheme.primary;
      case 'role_invitation':
        return colorScheme.secondary;
      case 'product_updated':
        return colorScheme.tertiary;
      case 'system_alert':
        return colorScheme.error;
      case 'stock_alert':
        return Colors.orange;
      default:
        return colorScheme.surface;
    }
  }

  Gradient _getBackgroundGradient(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (notification.isRead) {
      return LinearGradient(
        colors: [
          colorScheme.surfaceVariant.withOpacity(0.3),
          colorScheme.surface.withOpacity(0.1),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      return LinearGradient(
        colors: [
          colorScheme.primaryContainer.withOpacity(0.15),
          colorScheme.surfaceVariant.withOpacity(0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }

  Gradient _getNotificationGradient(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final code = notification.notificationCode.toLowerCase();

    switch (code) {
      case 'order_status':
      case 'order_received':
        return LinearGradient(
          colors: [colorScheme.primary, colorScheme.primaryContainer],
        );
      case 'role_invitation':
        return LinearGradient(
          colors: [colorScheme.secondary, colorScheme.secondaryContainer],
        );
      case 'product_updated':
        return LinearGradient(
          colors: [colorScheme.tertiary, colorScheme.tertiaryContainer],
        );
      default:
        return LinearGradient(
          colors: [colorScheme.surfaceVariant, colorScheme.outline],
        );
    }
  }

  String _getNotificationTitle(AppLocalizations localizations) {
    final code = notification.notificationCode.toLowerCase();

    switch (code) {
      case 'order_status':
      case 'order_received':
        return localizations.notificationOrderReceivedTitle;
      case 'role_invitation':
        return localizations.notificationRoleInvitationTitle;
      case 'product_updated':
        return localizations.notificationProductUpdatedTitle;
      case 'system_alert':
        return 'System Alert';
      case 'stock_alert':
        return 'Stock Alert';
      case 'reminder':
        return 'Reminder';
      case 'promotion':
        return 'Special Offer';
      default:
        return notification.content?.displayTitle ??
            localizations.notificationDefaultTitle;
    }
  }

  Future<String?> _getNotificationSubtitle(
    BuildContext context,
    AppLocalizations localizations,
  ) async {
    if (notification.content is RoleInvitation) {
      final invitation = notification.content as RoleInvitation;
      if ((invitation.providerId ?? 0) > 0) {
        final supplier = await context
            .read<SupplierChangeNotifier>()
            .getSupplierById(invitation.providerId ?? 0);
        return '${supplier?.providerOrganisationName} • ${supplier?.providerName}';
      }
      if ((invitation.organizationId ?? 0) > 0) {
        final org = await context
            .read<SupplierChangeNotifier>()
            .getOrganisationById((invitation.organizationId ?? 0));
        return org?.provider_organisation_name;
      }
    }

    switch (notification.notificationCode.toLowerCase()) {
      case 'order_status':
        return localizations.notificationOrderReceivedSubtitle;
      case 'product_updated':
        return localizations.notificationProductUpdatedSubtitle;
      default:
        return null;
    }
  }

  Future<String> _getNotificationMessage(
    BuildContext context,
    AppLocalizations localizations,
  ) async {
    final code = notification.notificationCode.toLowerCase();

    switch (code) {
      case 'order_status':
      case 'order_received':
        return localizations.notificationOrderReceivedMessage;

      case 'role_invitation':
        if (notification.content is RoleInvitation) {
          final invitation = notification.content as RoleInvitation;

          final appUser = await _fetchUserResponsible(context);
          final userName = appUser != null
              ? "${appUser.personFirstName} ${appUser.personLastName}".trim()
              : localizations.no_username ?? "Someone";

          final highestRole = PrivilegeUIManager.getHighestRole(
            invitation.role,
            context: context,
          );

          if (highestRole != null && highestRole.isNotEmpty) {
            return localizations.notificationRoleInvitationMessage(
                userName, highestRole);
          }

          return localizations.notificationRoleInvitationDefaultMessage;
        }
        return localizations.notificationRoleInvitationDefaultMessage;

      case 'product_updated':
        return localizations.notificationProductUpdatedMessage;

      case 'system_alert':
        return notification.content?.displayMessage ??
            'System maintenance or update notification';

      case 'stock_alert':
        return notification.content?.displayMessage ??
            'Product stock is running low';

      default:
        return notification.content?.displayMessage ??
            localizations.notificationDefaultMessage;
    }
  }

  String _formatTimeAgo(DateTime date, AppLocalizations localizations) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return localizations.timeJustNow;
    if (difference.inMinutes < 60)
      return localizations.timeMinutesAgo(difference.inMinutes);
    if (difference.inHours < 24)
      return localizations.timeHoursAgo(difference.inHours);
    if (difference.inDays < 7)
      return localizations.timeDaysAgo(difference.inDays);
    if (difference.inDays < 30)
      return localizations.timeWeeksAgo((difference.inDays / 7).floor());

    return localizations.timeDate(date.day, date.month, date.year);
  }

  Future<List<NotificationAction>> _getAvailableActions(
    BuildContext context,
    AppLocalizations localizations,
  ) async {
    final code = notification.notificationCode.toLowerCase();

    switch (code) {
      case 'order_status':
      case 'order_received':
        return [
          NotificationAction(
            type: ActionType.view,
            label: localizations.actionTrackOrder,
            notificationId: notification.idNotification,
          ),
        ];

      case 'role_invitation':
        return await _buildRoleInvitationActions(context, localizations);

      case 'product_updated':
        return [
          NotificationAction(
            type: ActionType.view,
            label: localizations.actionSeeChanges,
            notificationId: notification.idNotification,
          ),
          NotificationAction(
            type: ActionType.download,
            label: localizations.actionUpdateNow,
            notificationId: notification.idNotification,
          ),
        ];

      default:
        return [
          NotificationAction(
            type: ActionType.view,
            label: localizations.actionViewDetails,
            notificationId: notification.idNotification,
          ),
        ];
    }
  }

  Future<List<NotificationAction>> _buildRoleInvitationActions(
    BuildContext context,
    AppLocalizations localizations,
  ) async {
    final invitation = notification.content as RoleInvitation?;
    if (invitation == null) return [];

    try {
      // Get rules for the user who sent the invitation
      final privileges = context.read<PersonnelNotifier>().getRulesForUser(
            invitation.addedBy,
            supplierId: invitation.providerId ?? 0,
          );

      // Find the specific rule
      final targetedRule = privileges
          ?.where((item) => item.idManagementRule == invitation.ruleId)
          .firstOrNull;

      final ruleStatus = targetedRule?.managementRuleStatus?.toUpperCase() ??
          RuleStates.pending;
      final isPending = ruleStatus == RuleStates.pending;
      final isActive = ruleStatus == RuleStates.active;

      final actions = <NotificationAction>[];

      // Ensure all IDs are properly converted to int
      final ruleId = invitation.ruleId ?? 0;
      final orgId = invitation.organizationId ?? 0;
      final providerId = invitation.providerId ?? 0;
      final role = invitation.role ?? 0;

      if (isPending) {
        actions.addAll([
          NotificationAction(
            type: ActionType.accept,
            label: localizations.actionAccept,
            notificationId: notification.idNotification,
            metadata: {
              'rule_id': ruleId, // This is int
              'organization_id': orgId, // This is int
              'provider_id': providerId, // This is int
              'role': role, // This is int
            },
          ),
          NotificationAction(
            type: ActionType.reject,
            label: localizations.actionDecline,
            notificationId: notification.idNotification,
            metadata: {
              'rule_id': ruleId, // This is int
              'organization_id': orgId, // This is int
              'provider_id': providerId, // This is int
            },
          ),
        ]);
      }

      if (isActive) {
        actions.add(NotificationAction(
          type: ActionType.view,
          label: localizations.actionViewTeam,
          notificationId: notification.idNotification,
          metadata: {
            'organization_id': orgId, // This is int
            'provider_id': providerId, // This is int
            'supplier_name': '',
          },
        ));
      }

      return actions;
    } catch (e) {
      debugPrint('Error building role invitation actions: $e');
      return [];
    }
  }

  Future<AppUser?> _fetchUserResponsible(BuildContext context) async {
    final addedBy = notification.content?.addedBy;
    if (addedBy == null || addedBy == 0) return null;

    try {
      final userNotifier = context.read<AppUserNotifier>();
      return await userNotifier.fetchUserPassively(addedBy.toString());
    } catch (e) {
      debugPrint('Error fetching user: $e');
      return null;
    }
  }

  Future<NotificationAction?> _getDefaultAction(BuildContext context) async {
    final localizations = AppLocalizations.of(context);
    final actions = await _getAvailableActions(context, localizations!);
    return actions.isNotEmpty ? actions.first : null;
  }

  Color _getActionColor(BuildContext context, ActionType type) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (type) {
      case ActionType.accept:
        return colorScheme.primary;
      case ActionType.reject:
        return colorScheme.error;
      case ActionType.download:
        return colorScheme.secondary;
      case ActionType.view:
        return colorScheme.tertiary;
      default:
        return colorScheme.surfaceVariant;
    }
  }

  Color _getActionTextColor(BuildContext context, ActionType type) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (type) {
      case ActionType.accept:
      case ActionType.reject:
      case ActionType.download:
      case ActionType.view:
        return colorScheme.onPrimary;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  IconData? _getActionIcon(ActionType type) {
    switch (type) {
      case ActionType.accept:
        return Icons.check_rounded;
      case ActionType.reject:
        return Icons.close_rounded;
      case ActionType.download:
        return Icons.download_rounded;
      case ActionType.view:
        return Icons.visibility_rounded;
      default:
        return null;
    }
  }
}
