import 'package:flutter/material.dart';
import 'package:verdelia_core/app/AppUser.dart';
import 'package:verdelia_core/business/privileges/role_bit_mapper.dart';
import 'package:provider_personnel/components/privilege_ui.dart';

class PrivilegeItemWidget extends StatelessWidget {
  final PrivilegeItem privilege;
  final AppUser user;
  final bool isSelected;
  final bool isDisabled;
  final ValueChanged<bool> onChanged;

  const PrivilegeItemWidget({
    super.key,
    required this.privilege,
    required this.user,
    required this.isSelected,
    this.isDisabled = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final privilegeUI = PrivilegeUIManager.getPrivilege(privilege.id);
    final isAdminLocked = user.isAdmin && privilege.id == 'full_access';
    final isActuallyDisabled = isAdminLocked || isDisabled;

    return Opacity(
      opacity: isActuallyDisabled ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
                  .withOpacity(isActuallyDisabled ? 0.05 : 0.1)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                    .withOpacity(isActuallyDisabled ? 0.2 : 0.3)
                : colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              privilegeUI?.icon ?? Icons.check_rounded,
              size: 18,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
          title: Text(
            privilegeUI?.getTitle(context) ?? privilege.id,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isActuallyDisabled
                  ? colorScheme.onSurface.withOpacity(0.5)
                  : isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            privilegeUI?.getDescription(context) ?? '',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: isActuallyDisabled
                  ? colorScheme.onSurfaceVariant.withOpacity(0.4)
                  : isSelected
                      ? colorScheme.primary.withOpacity(0.7)
                      : colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: SizedBox(
            width: 36,
            child: Transform.scale(
              scale: 0.75,
              child: Switch.adaptive(
                value: isSelected,
                onChanged: isActuallyDisabled ? null : onChanged,
                activeColor: colorScheme.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          onTap: isActuallyDisabled ? null : () => onChanged(!isSelected),
          visualDensity: VisualDensity.compact,
          minVerticalPadding: 0,
        ),
      ),
    );
  }
}
