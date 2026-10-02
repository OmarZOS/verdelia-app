import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:verdelia_core/app/AppUser.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:provider_personnel/components/privilege_ui.dart';

class SupplierUserCard extends StatelessWidget {
  final AppUser user;
  final int supplierId;
  final int ruleCode;
  final bool isPending;
  final VoidCallback onManagePrivileges;
  final VoidCallback onRemove;
  final VoidCallback? onCancelInvite;
  final bool isCompact;
  final bool showActions;

  const SupplierUserCard({
    super.key,
    required this.user,
    required this.ruleCode,
    required this.supplierId,
    this.isPending = false,
    required this.onManagePrivileges,
    required this.onRemove,
    this.onCancelInvite,
    this.isCompact = false,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final localizations = AppLocalizations.of(context)!;

    final privilegeIds = _getOptimizedPrivilegeIds();
    final hasPrivileges = privilegeIds.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPending
              ? colorScheme.tertiary.withOpacity(0.2)
              : colorScheme.outline.withOpacity(0.08),
          width: isPending ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isPending
                ? colorScheme.tertiary.withOpacity(0.05)
                : colorScheme.shadow.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.all(isCompact ? 16 : 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(context),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildUserName(context, localizations),
                                if (user.appUserName?.isNotEmpty == true &&
                                    !isCompact)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: _buildUserEmail(context),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildUserRole(context, colorScheme, textTheme),
                        ],
                      ),
                      if (hasPrivileges) ...[
                        const SizedBox(height: 12),
                        _buildPrivilegeTags(context, privilegeIds),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: isCompact ? 48 : 60,
          height: isCompact ? 48 : 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withOpacity(0.3),
                colorScheme.tertiary.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: _buildAvatarImage(colorScheme),
        ),
        if (isPending)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: isCompact ? 16 : 20,
              height: isCompact ? 16 : 20,
              decoration: BoxDecoration(
                color: colorScheme.tertiary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.surface,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.access_time,
                size: 10,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatarImage(ColorScheme colorScheme) {
    final imageUrl = user.appUserImageUrl;

    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildFallbackAvatar(colorScheme);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          log('Failed to load avatar: $error');
          return _buildFallbackAvatar(colorScheme);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
              color: colorScheme.primary,
            ),
          );
        },
      ),
    );
  }

  Widget _buildFallbackAvatar(ColorScheme colorScheme) {
    return Center(
      child: Text(
        _getUserInitials(),
        style: TextStyle(
          fontSize: isCompact ? 16 : 20,
          fontWeight: FontWeight.w700,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  Widget _buildUserName(BuildContext context, AppLocalizations localizations) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            '${user.personFirstName ?? ''} ${user.personLastName ?? ''}'.trim(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isPending && isCompact)
          Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: colorScheme.secondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              localizations.pendingTxt,
              style: TextStyle(
                color: colorScheme.onSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUserEmail(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(
          Icons.alternate_email_rounded,
          size: 14,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            user.appUserName!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildUserRole(
      BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    final privilegeIds = _getOptimizedPrivilegeIds();
    final roleColor = privilegeIds.isNotEmpty
        ? _getRuleColor(privilegeIds.first, colorScheme)
        : colorScheme.onSurfaceVariant;
    final roleIcon = privilegeIds.isNotEmpty
        ? _getRuleIcon(privilegeIds.first)
        : Icons.work_outline_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: roleColor.withOpacity(0.08), // More subtle background
        borderRadius: BorderRadius.circular(8), // Smaller radius for tag
        border: Border.all(
          color: roleColor.withOpacity(0.15), // More subtle border
          width: 0.5, // Thinner border
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            roleIcon,
            size: isCompact ? 12 : 14, // Slightly smaller
            color: roleColor.withOpacity(0.8), // Slightly muted
          ),
          const SizedBox(width: 4), // Less spacing
          Text(
            _getRoleText(context),
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w500, // Lighter weight
              color: roleColor.withOpacity(0.9), // Slightly muted
              fontSize: isCompact ? 11 : 12, // Smaller text
              letterSpacing: -0.2, // Tighter letter spacing for tags
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivilegeTags(BuildContext context, List<String> privilegeIds) {
    final displayCount = isCompact ? 2 : 3;
    final displayedIds = privilegeIds.take(displayCount).toList();

    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: displayedIds.map((privilegeId) {
              final privilege = PrivilegeUIManager.getPrivilege(privilegeId);
              if (privilege == null) return const SizedBox.shrink();

              final (backgroundColor, textColor) =
                  _getPrivilegeColors(privilegeId, context);

              return Tooltip(
                message: privilege.getTitle(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: textColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    privilege.icon,
                    size: isCompact ? 10 : 12,
                    color: textColor,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        if (showActions && isPending) //&& onCancelInvite != null
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onCancelInvite,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .tertiary
                          .withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cancel_rounded,
                        size: 16,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context)!.actionCancelInvite,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (showActions && !isPending)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: isPending ? onCancelInvite : onManagePrivileges,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isPending
                        ? Theme.of(context)
                            .colorScheme
                            .tertiary
                            .withOpacity(0.1)
                        : Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPending
                          ? Theme.of(context)
                              .colorScheme
                              .tertiary
                              .withOpacity(0.3)
                          : Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPending
                            ? Icons.cancel_rounded
                            : Icons.admin_panel_settings_rounded,
                        size: 16,
                        color: isPending
                            ? Theme.of(context).colorScheme.tertiary
                            : Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isPending
                            ? AppLocalizations.of(context)!.actionCancelInvite
                            : AppLocalizations.of(context)!
                                .actionManagePermissions,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isPending
                              ? Theme.of(context).colorScheme.tertiary
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
      ],
    );
  }

  // ==================== HELPER METHODS ====================

  String _getUserInitials() {
    final firstName = user.personFirstName?.trim() ?? '';
    final lastName = user.personLastName?.trim() ?? '';

    if (firstName.isEmpty && lastName.isEmpty) {
      return user.appUserName?.isNotEmpty == true
          ? user.appUserName!.substring(0, 1).toUpperCase()
          : '?';
    }

    final firstInitial = firstName.isNotEmpty ? firstName[0] : '';
    final lastInitial = lastName.isNotEmpty ? lastName[0] : '';

    return '$firstInitial$lastInitial'.toUpperCase();
  }

  String _getRoleText(BuildContext context) {
    final privilegeIds = _getOptimizedPrivilegeIds();
    if (privilegeIds.isNotEmpty) {
      final privilege = PrivilegeUIManager.getPrivilege(privilegeIds.first);
      if (privilege != null) {
        return privilege.roleName(context);
      }
    }
    return '';
  }

  List<String> _getOptimizedPrivilegeIds() {
    try {
      if (ruleCode > 0) {
        // final privilegeIds = RoleBitMapper.numberToPrivilegeIds(ruleCode);
        return PrivilegeUIManager.getOptimizedPrivilegeIds(ruleCode);
      }
    } catch (e) {
      log('Error getting privilege IDs: $e');
    }
    return [];
  }

  IconData _getRuleIcon(String privilegeId) {
    final id = privilegeId.toLowerCase();
    if (id.contains('inventory')) return Icons.inventory_2_rounded;
    if (id.contains('orders')) return Icons.shopping_cart_rounded;
    if (id.contains('personnel')) return Icons.people_alt_rounded;
    if (id.contains('admin')) return Icons.security_rounded;
    if (id.contains('manager')) return Icons.manage_accounts_rounded;
    return Icons.work_outline_rounded;
  }

  Color _getRuleColor(String privilegeId, ColorScheme colorScheme) {
    final id = privilegeId.toLowerCase();
    if (id.contains('inventory')) return colorScheme.primary;
    if (id.contains('orders')) return colorScheme.tertiary;
    if (id.contains('personnel')) return colorScheme.tertiary;
    return colorScheme.onSurfaceVariant;
  }

  (Color, Color) _getPrivilegeColors(
    String privilegeId,
    BuildContext context,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final privilegeIdLower = privilegeId.toLowerCase();

    if (privilegeIdLower.contains('inventory')) {
      return (
        colorScheme.primaryContainer,
        colorScheme.onPrimaryContainer,
      );
    } else if (privilegeIdLower.contains('orders')) {
      return (
        colorScheme.tertiaryContainer,
        colorScheme.onTertiaryContainer,
      );
    } else if (privilegeIdLower.contains('personnel')) {
      return (
        colorScheme.tertiary.withOpacity(0.5),
        colorScheme.onTertiaryContainer,
      );
    }

    return (
      colorScheme.surfaceVariant,
      colorScheme.onSurfaceVariant,
    );
  }
}

// Add this near your main app initialization
// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
