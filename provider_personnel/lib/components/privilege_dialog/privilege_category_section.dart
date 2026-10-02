import 'package:flutter/material.dart';
import 'package:verdelia_core/app/AppUser.dart';
import 'package:verdelia_core/business/privileges/role_bit_mapper.dart';
import 'package:provider_personnel/components/privilege_dialog/privilege_item_widget.dart';
import 'package:provider_personnel/components/privilege_ui.dart';

class PrivilegeCategorySection extends StatefulWidget {
  final String category;
  final List<PrivilegeItem> privileges;
  final AppUser user;
  final Map<String, bool> selectedPrivileges;
  final Function(String, bool) onPrivilegeChanged;
  final bool isFirst;

  const PrivilegeCategorySection({
    super.key,
    required this.category,
    required this.privileges,
    required this.user,
    required this.selectedPrivileges,
    required this.onPrivilegeChanged,
    this.isFirst = false,
  });

  @override
  State<PrivilegeCategorySection> createState() =>
      _PrivilegeCategorySectionState();
}

class _PrivilegeCategorySectionState extends State<PrivilegeCategorySection> {
  bool _isViewDisabled(String viewId) {
    final manageId = viewId.replaceFirst('_view', '_manage');

    // Check if a manage privilege exists
    final hasManage = widget.privileges.any((p) => p.id == manageId);
    if (!hasManage) {
      // If no manage privilege, view should never be disabled
      return false;
    }

    // Disable view only if manage is currently selected
    final isManageSelected = widget.selectedPrivileges[manageId] ?? false;
    return isManageSelected;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.isFirst) const SizedBox(height: 24),
        Text(
          PrivilegeUIManager.localizeCategory(context, widget.category),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        ...widget.privileges.map((privilege) {
          final isView = privilege.id.endsWith('_view');
          final isManage = privilege.id.endsWith('_manage');
          final isDisabled = isView ? _isViewDisabled(privilege.id) : false;

          return PrivilegeItemWidget(
            privilege: privilege,
            user: widget.user,
            isSelected: widget.selectedPrivileges[privilege.id] ?? false,
            isDisabled: isDisabled,
            onChanged: (value) {
              if (isDisabled && isView) return;

              widget.onPrivilegeChanged(privilege.id, value);

              // If enabling manage, automatically disable view
              if (value && isManage) {
                final viewId = privilege.id.replaceFirst('_manage', '_view');
                if (widget.privileges.any((p) => p.id == viewId)) {
                  widget.onPrivilegeChanged(viewId, true);
                }
              }
            },
          );
        }),
      ],
    );
  }
}
