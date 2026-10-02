// components/role_dropdown.dart
import 'package:flutter/material.dart';
import 'package:verdelia_core/business/finance/ProvidedService.dart';

class RoleDropdown extends StatelessWidget {
  final List<StaffRole> roles;
  final int? selectedRoleId;
  final bool isLoading;
  final void Function(int?) onChanged;
  final String label;
  final bool isRequired;

  const RoleDropdown({
    super.key,
    required this.roles,
    required this.selectedRoleId,
    required this.isLoading,
    required this.onChanged,
    this.label = 'Role',
    this.isRequired = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Row(
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colors.onSurface,
                ),
              ),
              if (isRequired)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    '*',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.error,
                    ),
                  ),
                ),
              if (isLoading)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: DropdownButtonFormField<int>(
            value: roles.any((role) => role.id == selectedRoleId)
                ? selectedRoleId
                : null,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
            ),
            hint: Text(
              isLoading ? 'Loading roles...' : 'Select a role',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant.withOpacity(0.6),
              ),
            ),
            items: roles
                .map((role) => DropdownMenuItem<int>(
                      value: role.id,
                      child: Row(
                        children: [
                          // Optional: Show role icon if available
                          if (role.iconUrl != null) ...[
                            Image.network(
                              role.iconUrl!,
                              width: 24,
                              height: 24,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              role.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
            validator: (value) {
              if (isRequired && (value == null || value == 0)) {
                return 'Please select a role';
              }
              return null;
            },
            onChanged: onChanged,
            disabledHint: isLoading
                ? Text(
                    'Loading roles...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant.withOpacity(0.6),
                    ),
                  )
                : null,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface,
            ),
            icon: Icon(
              Icons.arrow_drop_down,
              color: colors.onSurfaceVariant,
            ),
            dropdownColor: colors.surface,
            isExpanded: true,
          ),
        ),
        if (selectedRoleId != null && selectedRoleId! > 0) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: colors.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _getRoleDescription(selectedRoleId!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _getRoleDescription(int roleId) {
    // You can customize this based on your role data
    // For now, returns a generic description
    final role = roles.firstWhere(
      (r) => r.id == roleId,
      orElse: () => StaffRole(
        id: roleId,
        categoryId: 0,
        name: 'Unknown Role',
        iconUrl: null,
        description: null,
      ),
    );
    return role.description ?? 'Required staff role for this service';
  }
}
