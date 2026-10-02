import 'package:flutter/material.dart';
import 'package:verdelia_core/app/AppUser.dart';
import 'package:verdelia_core/business/privileges/role_bit_mapper.dart';
import 'package:provider_personnel/components/privilege_dialog/privilege_dialog_content.dart';
import 'package:provider_personnel/components/privilege_dialog/privilege_dialog_header.dart';

class PrivilegeDialog extends StatefulWidget {
  final AppUser user;
  final String supplierName;
  final int? initialPrivileges;

  const PrivilegeDialog({
    super.key,
    required this.user,
    required this.supplierName,
    this.initialPrivileges,
  });

  @override
  State<PrivilegeDialog> createState() => _PrivilegeDialogState();
}

class _PrivilegeDialogState extends State<PrivilegeDialog> {
  final Map<String, bool> _selectedPrivileges = {};

  @override
  void initState() {
    super.initState();
    _initializePrivileges();
  }

  void _initializePrivileges() {
    if (widget.initialPrivileges != null) {
      final initialPrivilegeIds =
          RoleBitMapper.numberToPrivilegeIds(widget.initialPrivileges!);
      for (var privilege in PrivilegeManager.allPrivileges) {
        _selectedPrivileges[privilege.id] =
            initialPrivilegeIds.contains(privilege.id);
      }
    } else if (widget.user.isAdmin) {
      for (var privilege in PrivilegeManager.allPrivileges) {
        _selectedPrivileges[privilege.id] = true;
      }
    } else {
      _selectedPrivileges.addAll({
        'inventory_view': false,
        'orders_view': false,
        'personnel_view': false,
        'inventory_manage': false,
        'orders_manage': false,
        'personnel_manage': false,
      });
      _selectedPrivileges['inventory_view'] = true;
      _selectedPrivileges['orders_view'] = true;
      _selectedPrivileges['personnel_view'] = true;
    }
  }

  int _savePrivileges() {
    final selectedPrivilegeIds = _selectedPrivileges.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    return RoleBitMapper.privilegesToNumber(selectedPrivilegeIds);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrivilegeDialogHeader(
              supplierName: widget.supplierName,
              user: widget.user,
              onClose: () => Navigator.pop(context),
            ),
            Expanded(
              child: PrivilegeDialogContent(
                user: widget.user,
                selectedPrivileges: _selectedPrivileges,
                onPrivilegeChanged: (String id, bool value) {
                  setState(() => _selectedPrivileges[id] = value);
                },
              ),
            ),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: colorScheme.outline),
              ),
              child: Text('Cancel',
                  style: TextStyle(color: colorScheme.onSurface)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _savePrivileges()),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Save Permissions',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
