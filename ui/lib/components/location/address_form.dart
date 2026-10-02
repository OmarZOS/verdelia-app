import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/app/Address.dart';
import 'package:verdelia_core/app/AppUser.dart';

class AddressForm extends StatefulWidget {
  final Address? initialAddress;
  final AppUser? user;
  final ValueChanged<Address>? onAddressChanged;
  final bool showQuickFillButton;
  final bool showAddressType;

  const AddressForm({
    super.key,
    this.initialAddress,
    this.user,
    this.onAddressChanged,
    this.showQuickFillButton = true,
    this.showAddressType = true,
  });

  @override
  State<AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<AddressForm> {
  final _formKey = GlobalKey<FormState>();
  late Address _address;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _address = widget.initialAddress ?? Address();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with quick fill button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    loc?.deliveryAddress ?? 'Delivery Address',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              if (widget.showQuickFillButton && widget.user != null)
                _buildQuickFillButton(context),
            ],
          ),
          const SizedBox(height: 16),

          // Address Type (if enabled)
          if (widget.showAddressType) ...[
            _buildAddressTypeField(context),
            const SizedBox(height: 16),
          ],

          // Street Address
          _buildTextField(
            context,
            label: loc?.streetAddress ?? 'Street Address',
            hint: loc?.enterStreetAddress ?? 'Enter street address',
            initialValue: _address.address_street,
            onChanged: (value) {
              setState(() {
                _address = _address.copyWith(address_street: value);
              });
              _validateAndNotify();
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return loc?.streetAddressRequired ??
                    'Street address is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // City
          _buildTextField(
            context,
            label: loc?.city ?? 'City',
            hint: loc?.enterCity ?? 'Enter city',
            initialValue: _address.address_city,
            onChanged: (value) {
              setState(() {
                _address = _address.copyWith(address_city: value);
              });
              _validateAndNotify();
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return loc?.cityRequired ?? 'City is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              // Postal Code
              Expanded(
                child: _buildTextField(
                  context,
                  label: loc?.postalCode ?? 'Postal Code',
                  hint: loc?.enterPostalCode ?? 'Enter postal code',
                  initialValue: _address.address_postal_code,
                  onChanged: (value) {
                    setState(() {
                      _address = _address.copyWith(address_postal_code: value);
                    });
                    _validateAndNotify();
                  },
                ),
              ),
              const SizedBox(width: 12),

              // State/Province
              Expanded(
                child: _buildTextField(
                  context,
                  label: loc?.stateProvince ?? 'State/Province',
                  hint: loc?.enterState ?? 'Enter state/province',
                  initialValue: _address.address_state,
                  onChanged: (value) {
                    setState(() {
                      _address = _address.copyWith(address_state: value);
                    });
                    _validateAndNotify();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Country
          _buildCountryDropdown(context),
          const SizedBox(height: 16),

          // Additional Address Details
          _buildAdditionalDetailsSection(context),
          const SizedBox(height: 20),

          // Validation Status
          if (!_isValid && _address.address_street.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.error.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    size: 16,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      loc?.addressIncomplete ??
                          'Please fill in all required fields',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Preview
          if (_isValid) ...[
            const SizedBox(height: 16),
            _buildAddressPreview(context),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickFillButton(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return OutlinedButton.icon(
      onPressed: _fillFromUser,
      icon: const Icon(Icons.auto_fix_high, size: 16),
      label: Text(loc?.quickFill ?? 'Quick Fill'),
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.colorScheme.primary,
        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildAddressTypeField(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: loc?.addressType ?? 'Address Type',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      value: _address.address_type,
      items: Address.addressTypes.map((type) {
        return DropdownMenuItem<String>(
          value: type,
          child: Text(
            Address.addressTypeLabels[type] ?? type,
            style: theme.textTheme.bodyMedium,
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _address = _address.copyWith(address_type: value);
        });
        _validateAndNotify();
      },
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required String label,
    required String hint,
    String? initialValue,
    ValueChanged<String>? onChanged,
    FormFieldValidator<String>? validator,
  }) {
    final theme = Theme.of(context);

    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildCountryDropdown(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: loc?.country ?? 'Country',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      value:
          _address.address_country.isNotEmpty ? _address.address_country : null,
      items: [
        const DropdownMenuItem<String>(
          value: '',
          child: Text('Select a country'),
        ),
        ...Address.commonCountries.map((country) {
          return DropdownMenuItem<String>(
            value: country,
            child: Text(country),
          );
        }),
      ],
      onChanged: (value) {
        if (value != null && value.isNotEmpty) {
          setState(() {
            _address = _address.copyWith(address_country: value);
          });
          _validateAndNotify();
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return loc?.countryRequired ?? 'Country is required';
        }
        return null;
      },
    );
  }

  Widget _buildAdditionalDetailsSection(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      title: Row(
        children: [
          Icon(
            Icons.more_horiz,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            loc?.additionalDetails ?? 'Additional Details',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      children: [
        const SizedBox(height: 12),

        // Building/Apartment
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                context,
                label: loc?.building ?? 'Building',
                hint: loc?.enterBuilding ?? 'Building name/number',
                initialValue: _address.address_building,
                onChanged: (value) {
                  setState(() {
                    _address = _address.copyWith(address_building: value);
                  });
                  _validateAndNotify();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                context,
                label: loc?.apartment ?? 'Apartment',
                hint: loc?.enterApartment ?? 'Apartment/Unit number',
                initialValue: _address.address_apartment,
                onChanged: (value) {
                  setState(() {
                    _address = _address.copyWith(address_apartment: value);
                  });
                  _validateAndNotify();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Floor
        _buildTextField(
          context,
          label: loc?.floor ?? 'Floor',
          hint: loc?.enterFloor ?? 'Floor number',
          initialValue: _address.address_floor,
          onChanged: (value) {
            setState(() {
              _address = _address.copyWith(address_floor: value);
            });
            _validateAndNotify();
          },
        ),
        const SizedBox(height: 12),

        // Landmark
        _buildTextField(
          context,
          label: loc?.landmark ?? 'Landmark',
          hint: loc?.enterLandmark ?? 'Nearby landmark',
          initialValue: _address.address_landmark,
          onChanged: (value) {
            setState(() {
              _address = _address.copyWith(address_landmark: value);
            });
            _validateAndNotify();
          },
        ),
      ],
    );
  }

  Widget _buildAddressPreview(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                loc?.addressComplete ?? 'Address Complete',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _address.formattedMultiLine,
            style: theme.textTheme.bodyMedium,
          ),
          if (_address.address_type != null) ...[
            const SizedBox(height: 8),
            Chip(
              label: Text(_address.typeLabel),
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              labelStyle: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 12,
              ),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }

  void _fillFromUser() {
    if (widget.user == null) return;

    final user = widget.user!;
    final address = Address(
      address_street: user.addressStreet ?? "",
      address_city: user.addressCity ?? "",
      address_postal_code: user.addressPostalCode ?? "",
      address_country: user.addressCountry ?? "",
      address_type: 'shipping',
    );

    setState(() {
      _address = address;
    });

    _validateAndNotify();

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)?.addressFilled ??
              'Address filled from user information',
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _validateAndNotify() {
    final isValid = _formKey.currentState?.validate() ?? false;
    setState(() {
      _isValid = isValid;
    });

    if (isValid) {
      widget.onAddressChanged?.call(_address);
    }
  }

  // Public method to get the current address
  Address getAddress() {
    return _address;
  }

  // Public method to validate the form
  bool validate() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (isValid) {
      _formKey.currentState?.save();
    }
    return isValid;
  }
}
