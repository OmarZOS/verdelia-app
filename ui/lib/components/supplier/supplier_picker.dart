import 'package:app_constants/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:app_constants/app_constants.dart';
import 'package:verdelia_core/business/Supplier.dart';

class SupplierPicker extends StatefulWidget {
  final ValueChanged<Supplier> onSupplierChanged;
  final List<Supplier> suppliers;
  final Supplier? initialSelection;

  const SupplierPicker({
    Key? key,
    required this.onSupplierChanged,
    required this.suppliers,
    this.initialSelection,
  }) : super(key: key);

  @override
  _SupplierPickerState createState() => _SupplierPickerState();
}

class _SupplierPickerState extends State<SupplierPicker> {
  late Supplier? _selectedSupplier;

  @override
  void initState() {
    super.initState();
    _selectedSupplier = widget.initialSelection;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.dividerColor,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showSupplierPicker(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: _selectedSupplier != null
                    ? SvgPicture.asset(
                        'assets/icons/${_selectedSupplier!.productProviderTypeId}.svg',
                        color: theme.colorScheme.primary,
                        width: 16,
                        height: 16,
                        package: "provider_geo",
                      )
                    : Icon(
                        Icons.store,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.supplierText,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedSupplier?.providerName ?? loc.addSupplierTxt,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: _selectedSupplier != null
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSupplierPicker(BuildContext context) async {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    if (widget.suppliers.isEmpty) {
      Navigator.pushNamed(context, AppRoutes.providerCreate);
      return;
    }

    final selectedSupplier = await showModalBottomSheet<Supplier>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SupplierSelectionSheet(
        suppliers: widget.suppliers,
        initialSelection: _selectedSupplier,
      ),
    );

    if (selectedSupplier != null) {
      setState(() {
        _selectedSupplier = selectedSupplier;
      });
      widget.onSupplierChanged(selectedSupplier);
    }
  }
}

class SupplierSelectionSheet extends StatelessWidget {
  final List<Supplier> suppliers;
  final Supplier? initialSelection;

  const SupplierSelectionSheet({
    Key? key,
    required this.suppliers,
    this.initialSelection,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc.addSupplierTxt,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: loc.searchSuppliersText,
                prefixIcon: Icon(Icons.search,
                    color: theme.colorScheme.onSurface.withOpacity(0.6)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) {
                // Implement search functionality
              },
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8),
              itemCount: suppliers.length,
              itemBuilder: (context, index) {
                final supplier = suppliers[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    child: SvgPicture.asset(
                      'assets/icons/${supplier.productProviderTypeId}.svg',
                      color: theme.colorScheme.primary,
                      width: 20,
                      height: 20,
                      package: "provider_geo",
                    ),
                  ),
                  title: Text(supplier.providerName),
                  subtitle: Text(supplier.locationName ?? ''),
                  trailing: supplier == initialSelection
                      ? Icon(Icons.check_circle,
                          color: theme.colorScheme.primary)
                      : null,
                  onTap: () => Navigator.pop(context, supplier),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
