// components/resource_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:verdelia_core/business/finance/ProvidedService.dart';
import 'package:provider_store/components/service/form/ProductSelectorDialog.dart';
import 'package:provider/provider.dart';
import 'package:event/product_change_notifier.dart';

class ResourceRequirementDialog extends StatefulWidget {
  final ServiceResourceRequirement? existing;
  final int? index;
  final int providerId;
  final int serviceId;
  final Function(ServiceResourceRequirement, bool, int?) onSave;

  const ResourceRequirementDialog({
    super.key,
    this.existing,
    this.index,
    required this.providerId,
    required this.serviceId,
    required this.onSave,
  });

  @override
  State<ResourceRequirementDialog> createState() =>
      _ResourceRequirementDialogState();
}

class _ResourceRequirementDialogState extends State<ResourceRequirementDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _costPerUnitController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isConsumable = false;
  int? _productRef;
  String? _selectedProductName;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    final existing = widget.existing;
    if (existing != null) {
      _nameController.text = existing.name;
      _typeController.text = existing.type;
      _quantityController.text = existing.quantity.toString();
      _costPerUnitController.text = existing.costPerUnit.toStringAsFixed(2);
      _notesController.text = existing.notes ?? '';
      _isConsumable = existing.isConsumable;
      _productRef = existing.productRef;

      if (_productRef != null && _productRef! > 0) {
        try {
          final productNotifier =
              Provider.of<ProductNotifier>(context, listen: false);
          final product = productNotifier.getProductByIdSync(_productRef!);
          _selectedProductName = product?.product_name;
        } catch (e) {}
      }
    } else {
      _quantityController.text = '1';
      _costPerUnitController.text = '0.00';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _quantityController.dispose();
    _costPerUnitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateTotalCost() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AlertDialog(
      title: Text(
        widget.existing != null
            ? 'Edit Resource Requirement'
            : 'Add Resource Requirement',
        style: theme.textTheme.titleLarge,
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'Resource Name',
                hint: 'e.g., Equipment, Materials',
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Please enter a resource name' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _typeController,
                label: 'Resource Type',
                hint: 'e.g., Equipment, Consumable',
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Please enter a resource type' : null,
              ),
              const SizedBox(height: 12),
              _buildProductSelector(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _quantityController,
                      label: 'Quantity',
                      hint: 'Number of units',
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d*$')),
                      ],
                      onChanged: (_) => _updateTotalCost(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter quantity';
                        }
                        final qty = double.tryParse(value);
                        if (qty == null || qty < 0) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _costPerUnitController,
                      label: 'Cost Per Unit',
                      hint: 'Cost per unit',
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d*$')),
                      ],
                      prefixText: 'DZD ',
                      onChanged: (_) => _updateTotalCost(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter cost per unit';
                        }
                        final cost = double.tryParse(value);
                        if (cost == null || cost < 0) {
                          return 'Please enter a valid cost';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                title: const Text('Is Consumable'),
                value: _isConsumable,
                onChanged: (value) =>
                    setState(() => _isConsumable = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _notesController,
                label: 'Notes (Optional)',
                hint: 'Any additional notes',
                maxLines: 2,
              ),
              if (_quantityController.text.isNotEmpty &&
                  _costPerUnitController.text.isNotEmpty) ...[
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Cost:',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'DZD ${_calculateTotalCost().toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
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
            if (_formKey.currentState!.validate()) {
              final requirement = ServiceResourceRequirement(
                id: widget.existing?.id ?? 0,
                name: _nameController.text,
                type: _typeController.text,
                quantity: double.parse(_quantityController.text),
                isConsumable: _isConsumable,
                productRef: _productRef,
                serviceId: widget.serviceId,
                costPerUnit: double.parse(_costPerUnitController.text),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? prefixText,
    int? maxLines = 1,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        prefixText: prefixText,
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      validator: validator,
      onChanged: onChanged,
    );
  }

  Widget _buildProductSelector() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return InkWell(
      onTap: () async {
        final selectedProduct = await ProductSelectorDialog.show(
          context,
          supplierId: widget.providerId > 0 ? widget.providerId : null,
          selectedProductId: _productRef,
        );

        if (selectedProduct != null && context.mounted) {
          setState(() {
            _productRef = selectedProduct.id_product;
            _selectedProductName = selectedProduct.product_name;
            if (_nameController.text.isEmpty) {
              _nameController.text = selectedProduct.product_name ?? '';
            }
            if (_costPerUnitController.text.isEmpty ||
                _costPerUnitController.text == '0.00') {
              _costPerUnitController.text =
                  (selectedProduct.product_price ?? 0).toStringAsFixed(2);
            }
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: colors.outline.withOpacity(0.2),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.inventory_2_outlined, color: colors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Product Reference',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    _selectedProductName ??
                        (_productRef != null && _productRef! > 0
                            ? 'Product ID: $_productRef'
                            : 'Select a product (optional)'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _selectedProductName != null
                          ? colors.onSurface
                          : colors.onSurfaceVariant.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  double _calculateTotalCost() {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final costPerUnit = double.tryParse(_costPerUnitController.text) ?? 0;
    return quantity * costPerUnit;
  }
}
