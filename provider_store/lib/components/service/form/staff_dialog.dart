// components/staff_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:verdelia_core/business/finance/ProvidedService.dart';

class StaffRequirementDialog extends StatefulWidget {
  final ServiceStaffRequirement? existing;
  final int? index;
  final int serviceId;
  final List<StaffRole> staffRoles;
  final bool isLoadingRoles;
  final Function(ServiceStaffRequirement, bool, int?) onSave;

  const StaffRequirementDialog({
    super.key,
    this.existing,
    this.index,
    required this.serviceId,
    required this.staffRoles,
    required this.isLoadingRoles,
    required this.onSave,
  });

  @override
  State<StaffRequirementDialog> createState() => _StaffRequirementDialogState();
}

class _StaffRequirementDialogState extends State<StaffRequirementDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _minCountController = TextEditingController();
  final TextEditingController _maxCountController = TextEditingController();
  final TextEditingController _allocatedHoursController =
      TextEditingController();
  final TextEditingController _hourlyRateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  int? _selectedRoleId;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    final existing = widget.existing;
    if (existing != null) {
      _selectedRoleId = existing.role;
      _minCountController.text = existing.minCount.toString();
      _maxCountController.text = existing.maxCount.toString();
      _allocatedHoursController.text = existing.allocatedHours.toString();
      _hourlyRateController.text = existing.hourlyRate.toStringAsFixed(2);
      _notesController.text = existing.notes ?? '';
    } else {
      _minCountController.text = '1';
      _maxCountController.text = '1';
      _allocatedHoursController.text = '1.0';
      _hourlyRateController.text = '0.00';
    }
  }

  @override
  void dispose() {
    _minCountController.dispose();
    _maxCountController.dispose();
    _allocatedHoursController.dispose();
    _hourlyRateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double _calculateCost(int count, double hours, double rate) {
    return hours * rate * count;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AlertDialog(
      title: Text(
        widget.existing != null
            ? 'Edit Staff Requirement'
            : 'Add Staff Requirement',
        style: theme.textTheme.titleLarge,
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Role Dropdown
              DropdownButtonFormField<int>(
                value:
                    widget.staffRoles.any((role) => role.id == _selectedRoleId)
                        ? _selectedRoleId
                        : null,
                decoration: InputDecoration(
                  labelText: 'Role',
                  border: const OutlineInputBorder(),
                  helperText: widget.isLoadingRoles ? 'Loading roles...' : null,
                ),
                items: widget.staffRoles
                    .map((role) => DropdownMenuItem<int>(
                          value: role.id,
                          child: Text(role.name),
                        ))
                    .toList(),
                validator: (value) => value == null ? 'Select a role' : null,
                onChanged: (value) => setState(() => _selectedRoleId = value),
              ),
              const SizedBox(height: 12),

              // Min/Max Count
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minCountController,
                      decoration: const InputDecoration(
                        labelText: 'Min Staff',
                        hintText: 'Minimum',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final count = int.tryParse(value);
                        if (count == null || count < 0) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _maxCountController,
                      decoration: const InputDecoration(
                        labelText: 'Max Staff',
                        hintText: 'Maximum',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final count = int.tryParse(value);
                        if (count == null || count < 0) {
                          return 'Invalid';
                        }
                        final min = int.tryParse(_minCountController.text) ?? 0;
                        if (count < min) {
                          return 'Max >= Min';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Allocated Hours
              TextFormField(
                controller: _allocatedHoursController,
                decoration: const InputDecoration(
                  labelText: 'Allocated Hours',
                  hintText: 'Hours per staff member',
                  border: OutlineInputBorder(),
                  suffixText: 'h',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*$')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter hours';
                  }
                  final hours = double.tryParse(value);
                  if (hours == null || hours < 0) {
                    return 'Invalid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Hourly Rate
              TextFormField(
                controller: _hourlyRateController,
                decoration: const InputDecoration(
                  labelText: 'Hourly Rate',
                  hintText: 'Rate per hour',
                  border: OutlineInputBorder(),
                  prefixText: 'DZD ',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*$')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter rate';
                  }
                  final rate = double.tryParse(value);
                  if (rate == null || rate < 0) {
                    return 'Invalid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Any additional notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),

              // Cost Preview
              if (_minCountController.text.isNotEmpty &&
                  _maxCountController.text.isNotEmpty &&
                  _allocatedHoursController.text.isNotEmpty &&
                  _hourlyRateController.text.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildCostRow(
                        context,
                        label: 'Min Cost:',
                        value: _calculateCost(
                          int.tryParse(_minCountController.text) ?? 0,
                          double.tryParse(_allocatedHoursController.text) ?? 0,
                          double.tryParse(_hourlyRateController.text) ?? 0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildCostRow(
                        context,
                        label: 'Max Cost:',
                        value: _calculateCost(
                          int.tryParse(_maxCountController.text) ?? 0,
                          double.tryParse(_allocatedHoursController.text) ?? 0,
                          double.tryParse(_hourlyRateController.text) ?? 0,
                        ),
                      ),
                      const Divider(),
                      _buildCostRow(
                        context,
                        label: 'Average Cost:',
                        value: _calculateCost(
                          ((int.tryParse(_minCountController.text) ?? 0) +
                                  (int.tryParse(_maxCountController.text) ??
                                      0)) ~/
                              2,
                          double.tryParse(_allocatedHoursController.text) ?? 0,
                          double.tryParse(_hourlyRateController.text) ?? 0,
                        ),
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate() && _selectedRoleId != null) {
              final requirement = ServiceStaffRequirement(
                id: widget.existing?.id ?? 0,
                serviceId: widget.serviceId,
                minCount: int.parse(_minCountController.text),
                maxCount: int.parse(_maxCountController.text),
                role: _selectedRoleId!,
                allocatedHours: double.parse(_allocatedHoursController.text),
                hourlyRate: double.parse(_hourlyRateController.text),
                notes: _notesController.text.isNotEmpty
                    ? _notesController.text
                    : null,
                createdAt: widget.existing?.createdAt ?? DateTime.now(),
                updatedAt: DateTime.now(),
              );

              widget.onSave(requirement, widget.existing != null, widget.index);
              Navigator.pop(context);
            }
          },
          child: Text(widget.existing != null ? 'Update' : 'Add'),
        ),
      ],
    );
  }

  Widget _buildCostRow(
    BuildContext context, {
    required String label,
    required double value,
    bool isBold = false,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          'DZD ${value.toStringAsFixed(2)}',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? colors.primary : null,
          ),
        ),
      ],
    );
  }
}
