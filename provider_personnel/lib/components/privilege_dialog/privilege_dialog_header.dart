import 'package:flutter/material.dart';
import 'package:verdelia_core/app/AppUser.dart';

class PrivilegeDialogHeader extends StatelessWidget {
  final String supplierName;
  final AppUser user;
  final VoidCallback onClose;

  const PrivilegeDialogHeader({
    super.key,
    required this.supplierName,
    required this.user,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Manage Permissions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: Icon(Icons.close_rounded,
                    size: 24, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildUserInfo(context),
        ],
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: colorScheme.primaryContainer.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          _buildUserAvatar(colorScheme),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user.personFirstName} ${user.personLastName}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  user.appUserName ?? 'No username',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  supplierName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(ColorScheme colorScheme) {
    final hasImage =
        user.appUserImageUrl != null && user.appUserImageUrl!.isNotEmpty;

    return Container(
      width: 50,
      height: 50,
      // decoration: BoxDecoration(
      //   borderRadius: BorderRadius.circular(25),
      //   image: hasImage
      //       ? DecorationImage(
      //           image: NetworkImage(user.appUserImageUrl!),
      //           fit: BoxFit.cover,
      //         )
      //       : null,
      //   color: !hasImage ? colorScheme.primary.withOpacity(0.1) : null,
      // ),
      // child: !hasImage
      //     ? Icon(Icons.person_rounded, color: colorScheme.primary, size: 24)
      //     : null,
    );
  }
}
