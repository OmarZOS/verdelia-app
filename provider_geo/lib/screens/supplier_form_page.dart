import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:app_constants/app_constants.dart';
import 'package:verdelia_core/app/VerdeliaException.dart';
import 'package:verdelia_core/app/VerdeliaImage.dart';
import 'package:verdelia_core/business/Organisation.dart';
import 'package:verdelia_core/business/Supplier.dart';
import 'package:event/supplier_change_notifier.dart';
import 'package:event/user_change_notifier.dart';
import 'package:ui/components/ImagePickerSection.dart';
import 'package:ui/components/category_picker.dart';
import 'package:ui/components/map_picker.dart';
import 'package:ui/components/organisation_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class SupplierFormScreen extends StatefulWidget {
  const SupplierFormScreen({super.key});

  @override
  _SupplierFormScreenState createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends State<SupplierFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  // Form state variables
  int? _idprovider_details_id;
  int? _id_product_provider;
  int? _product_provider_details_id;
  String? _provider_name;
  String? _provider_contact_info = "";
  int? _product_provider_type_id;
  double? _location_latitude;
  double? _location_longitude;
  String? _location_name;
  int? _id_provider_organisation;
  String? _provider_organisation_desc;
  String? _provider_organisation_name;
  String? _supplierImageUrl;
  int? _supplierImageId;
  LatLng? _position;
  int? _id_location;
  late SupplierChangeNotifier _notifier;
  bool _initialized = false;
  bool _isLoading = false;

  // Track if operation is in progress
  bool _isSubmitting = false;

  // Dynamic contact fields
  final List<TextEditingController> _contactControllers = [];
  final List<FocusNode> _contactFocusNodes = [];

  final TextEditingController _organizationController = TextEditingController();
  late List<Organisation> organizations;
  List<Organisation> filteredOrganizations = [];
  Organisation? selectedOrganization;
  bool isCustomOrganization = false;

  int _location_address_id = 0;
  String _address_street = "";
  String _address_city = "";
  String _address_postal_code = "";
  String _address_country = "";
  bool updatePage = false;

  VerdeliaImage? supplier_image;

  final List<String> _contactTypes = [
    'instagram',
    'facebook',
    'email',
    'phone',
    'website',
    'tiktok',
    'whatsapp',
    'other',
  ];

  List<String> _selectedContactTypes = [];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    _notifier = Provider.of<SupplierChangeNotifier>(context, listen: false);

    setState(() => _isLoading = true);

    // Load organisations if empty
    if (_notifier.organisations.isEmpty) {
      await _notifier.fetchOrganisations(reset: true);
    }

    organizations = List.from(_notifier.organisations);
    filteredOrganizations = organizations;

    setState(() => _isLoading = false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      final Supplier? supplier = args?["supplier"];
      if (supplier != null) {
        updatePage = true;
        _idprovider_details_id = supplier.idProviderDetails;
        _id_product_provider = supplier.idProductProvider;
        _id_provider_organisation = supplier.idProviderOrganisation;
        _provider_organisation_desc = supplier.providerOrganisationDesc;
        _provider_organisation_name = supplier.providerOrganisationName;
        _product_provider_details_id = supplier.idProviderDetails;
        _provider_name = supplier.providerName;
        _provider_contact_info = supplier.providerContactInfo;
        _product_provider_type_id = supplier.productProviderTypeId;
        _location_latitude = supplier.locationLatitude;
        _location_longitude = supplier.locationLongitude;
        _location_name = supplier.locationName;
        _supplierImageUrl = supplier.supplierImageUrl;
        _supplierImageId = supplier.supplierImageId;
        _id_location = supplier.idLocation;
        _position = supplier.locationLatitude != null &&
                supplier.locationLongitude != null
            ? LatLng(supplier.locationLatitude!, supplier.locationLongitude!)
            : null;

        _location_address_id = supplier.locationAddressId ?? 0;
        _address_street = supplier.addressStreet ?? "";
        _address_city = supplier.addressCity ?? "";
        _address_postal_code = supplier.addressPostalCode ?? "";
        _address_country = supplier.addressCountry ?? "";

        // Find and set selected organization
        if (_id_provider_organisation != null &&
            _id_provider_organisation! > 0) {
          selectedOrganization = organizations.firstWhere(
            (org) => org.id_provider_organisation == _id_provider_organisation,
            orElse: () => Organisation(
              id_provider_organisation: 0,
              provider_organisation_name: _provider_organisation_name ?? '',
              provider_organisation_desc: _provider_organisation_desc ?? '',
            ),
          );
        }
      }

      // Parse contact info
      if (_provider_contact_info != null &&
          _provider_contact_info!.isNotEmpty) {
        final pattern = RegExp(r'([A-Za-z]+):\s*([^,]+)(?:,\s*|$)');
        final matches = pattern.allMatches(_provider_contact_info!);

        for (final match in matches) {
          if (match.groupCount >= 2) {
            final type = match.group(1)?.trim() ?? '';
            final value = match.group(2)?.trim() ?? '';

            final checkedType = _getTypeText(type);

            _contactControllers.add(TextEditingController(text: value));
            _selectedContactTypes.add(checkedType);
            _contactFocusNodes.add(FocusNode());
          }
        }
      }

      if (_contactControllers.isEmpty) {
        _contactControllers.add(TextEditingController());
        _selectedContactTypes.add(_contactTypes.first);
        _contactFocusNodes.add(FocusNode());
      }

      _initialized = true;
    }
  }

  @override
  void dispose() {
    for (var controller in _contactControllers) {
      controller.dispose();
    }
    for (var node in _contactFocusNodes) {
      node.dispose();
    }
    _organizationController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _filterOrganizations() {
    final query = _organizationController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredOrganizations = organizations;
        isCustomOrganization = false;
      } else {
        filteredOrganizations = organizations
            .where((org) =>
                org.provider_organisation_name.toLowerCase().contains(query))
            .toList();

        isCustomOrganization = filteredOrganizations.isEmpty ||
            !filteredOrganizations.any((org) =>
                org.provider_organisation_name.toLowerCase() ==
                query.toLowerCase());
      }
    });
  }

  void _selectOrganization(Organisation org) {
    setState(() {
      selectedOrganization = org;
      _id_provider_organisation = org.id_provider_organisation;
      _provider_organisation_name = org.provider_organisation_name;
      _provider_organisation_desc = org.provider_organisation_desc;
      _organizationController.text = org.provider_organisation_name;
      isCustomOrganization = false;
    });
    FocusScope.of(context).unfocus();
  }

  void _addContactField() {
    final controller = TextEditingController();
    final focusNode = FocusNode();

    setState(() {
      _contactControllers.add(controller);
      _contactFocusNodes.add(focusNode);
      _selectedContactTypes.add(_contactTypes.first);
    });
  }

  void _removeContactField(int index) {
    setState(() {
      _contactControllers.removeAt(index);
      _selectedContactTypes.removeAt(index);
      _contactFocusNodes.removeAt(index).dispose();
    });
  }

  void _onCategoryChanged(int identifier) {
    setState(() {
      _product_provider_type_id = identifier;
    });
  }

  Future<void> _submitForm() async {
    if (_isSubmitting) return;

    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    setState(() => _isSubmitting = true);

    try {
      // Concatenate contact info fields
      _provider_contact_info = _contactControllers
          .asMap()
          .entries
          .where((entry) => entry.value.text.isNotEmpty)
          .map((entry) =>
              '${_selectedContactTypes[entry.key]}:${entry.value.text}')
          .join(',');

      // Create or update organisation if custom
      if (isCustomOrganization && _organizationController.text.isNotEmpty) {
        final newOrg = Organisation(
          id_provider_organisation: 0,
          provider_organisation_name: _organizationController.text,
          provider_organisation_desc: '',
        );

        final created = await _notifier.createOrganisation(newOrg,
            Provider.of<AppUserNotifier>(context, listen: false).token ?? "");
        if (created != null) {
          _id_provider_organisation = created.id_provider_organisation;
          _provider_organisation_name = created.provider_organisation_name;
          _provider_organisation_desc = created.provider_organisation_desc;
        }
      }

      Supplier supplier = Supplier(
        idLocation: _id_location ?? 0,
        idProviderDetails: _idprovider_details_id ?? 0,
        idProductProvider: _id_product_provider ?? 0,
        idProviderOrganisation: _id_provider_organisation ?? 0,
        providerOrganisationName: _provider_organisation_name ?? "",
        providerOrganisationDesc: _provider_organisation_desc ?? "",
        productProviderDetailsId: _product_provider_details_id ?? 0,
        productProviderTypeId: _product_provider_type_id ?? 1,
        providerName: _provider_name ?? "",
        providerContactInfo: _provider_contact_info ?? "",
        locationLatitude: _location_latitude ?? 0.0,
        locationLongitude: _location_longitude ?? 0.0,
        locationName: _location_name ?? "",
        productProviderOwnerId:
            Provider.of<AppUserNotifier>(context, listen: false)
                    .appUser!
                    .idAppUser ??
                0,
        supplierImageUrl: _supplierImageUrl,
        supplierImageId: _supplierImageId,
        locationAddressId: _location_address_id,
        addressStreet: _address_street,
        addressCity: _address_city,
        addressPostalCode: _address_postal_code,
        addressCountry: _address_country,
      );

      if (supplier_image != null) {
        supplier = supplier.copyWith(supplierImage: supplier_image);
      }

      // Execute the operation using the notifier
      final result = await _notifier.createOrUpdateSupplier(supplier,
          Provider.of<AppUserNotifier>(context, listen: false).token ?? "s");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.putSuccess),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate back on success
        Navigator.pop(context);
      }
    } on VerdeliaException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(e.message ?? AppLocalizations.of(context)!.putFailure),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(updatePage
            ? localizations.supplierText
            : localizations.addSupplierTxt),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_id_product_provider != null &&
                        _id_product_provider != 0)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(localizations.providerImage),
                          ImagePickerSection(
                            initialImageUrl: (_supplierImageUrl ?? ""),
                            entityType: 'supplier',
                            ownerId: '$_id_provider_organisation',
                            entityId: '$_id_product_provider',
                            onImageUploaded: (newImage) {
                              setState(() {
                                supplier_image = newImage;
                                _supplierImageId = 0;
                              });
                            },
                          ),
                        ],
                      ),
                    _buildSectionHeader(localizations.basicInformation),
                    _buildTextField(context,
                        label: localizations.supplierNameMsg,
                        icon: Icons.business,
                        onSaved: (value) => _provider_name = value,
                        validator: (value) => value?.isEmpty ?? true
                            ? localizations.addBusinessNameMsg
                            : null,
                        initialValue: _provider_name),
                    const SizedBox(height: 6),
                    _buildTextField(context,
                        label: localizations.streetText,
                        icon: Icons.location_on,
                        onSaved: (value) => _address_street = value ?? "",
                        validator: (value) => value?.isEmpty ?? true
                            ? localizations.streetText
                            : null,
                        initialValue: _address_street),
                    const SizedBox(height: 6),
                    _buildTextField(context,
                        label: localizations.cityText,
                        icon: Icons.location_city,
                        onSaved: (value) => _address_city = value ?? "",
                        validator: (value) => value?.isEmpty ?? true
                            ? localizations.cityText
                            : null,
                        initialValue: _address_city),
                    const SizedBox(height: 6),
                    _buildTextField(context,
                        label: localizations.postalCodeText,
                        icon: Icons.local_post_office,
                        onSaved: (value) => _address_postal_code = value ?? "",
                        validator: (value) => value?.isEmpty ?? true
                            ? localizations.postalCodeText
                            : null,
                        initialValue: _address_postal_code),
                    const SizedBox(height: 6),
                    _buildTextField(context,
                        label: localizations.countryText,
                        icon: Icons.flag,
                        onSaved: (value) => _address_country = value ?? "",
                        validator: (value) => value?.isEmpty ?? true
                            ? localizations.countryText
                            : null,
                        initialValue: _address_country),
                    const SizedBox(height: 16),
                    OrganisationPicker(
                      initialValue: _id_provider_organisation,
                      onOrganisationSelected: (value) {
                        setState(() {
                          _id_provider_organisation =
                              value.id_provider_organisation;
                          _provider_organisation_name =
                              value.provider_organisation_name;
                          _provider_organisation_desc =
                              value.provider_organisation_desc;
                          selectedOrganization = value;
                        });
                      },
                      hintText: localizations.selectOrganisationHintText,
                    ),
                    const SizedBox(height: 16),
                    _buildCategoryPicker(context),
                    const SizedBox(height: 16),
                    _buildSectionHeader(localizations.locationInformation),
                    _buildTextField(context,
                        label: localizations.locationNameText,
                        icon: Icons.place,
                        onSaved: (value) => _location_name = value,
                        validator: (value) => value?.isEmpty ?? true
                            ? localizations.pleaseInputLocationNameMsg
                            : null,
                        initialValue: _location_name),
                    const SizedBox(height: 16),
                    _buildLocationPicker(context),
                    const SizedBox(height: 24),
                    _buildSectionHeader(localizations.contactInformation),
                    ..._buildContactFields(context),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              localizations.saveSupplier,
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCategoryPicker(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final categories = localizations.providerCategoryTextList.split(",");

    if (categories.isEmpty) {
      return Text(
        localizations.categoriesNotFoundTxt,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      );
    }

    return CategoryPicker(
      categories: categories.toList(),
      onCategoryChanged: _onCategoryChanged,
      pathFunction: (int id) => "assets/icons/${id}.svg",
      category_id: _product_provider_type_id ?? 1,
      package: 'provider_geo',
    );
  }

  Widget _buildLocationPicker(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final hasLocation = _position != null;

    return GestureDetector(
      onTap: () async {
        final position = await showLocationInputDialog(context);
        if (position != null && mounted) {
          setState(() {
            _position = position;
            _location_latitude = position.latitude;
            _location_longitude = position.longitude;
          });
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasLocation
                ? theme.colorScheme.primary.withOpacity(0.2)
                : theme.colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: hasLocation
                    ? theme.colorScheme.primary.withOpacity(0.1)
                    : theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.location_on,
                color: hasLocation
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.5),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.insertCoordinatesMsg,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasLocation
                        ? '${_position!.latitude.toStringAsFixed(4)}, ${_position!.longitude.toStringAsFixed(4)}'
                        : loc.insertCoordinatesMsg,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: hasLocation
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  if (hasLocation && _location_name != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _location_name!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
            if (hasLocation)
              IconButton(
                icon: Icon(Icons.edit, size: 20),
                color: theme.colorScheme.secondary,
                onPressed: () async {
                  final newPosition = await showLocationInputDialog(context);
                  if (newPosition != null && mounted) {
                    setState(() {
                      _position = newPosition;
                      _location_latitude = newPosition.latitude;
                      _location_longitude = newPosition.longitude;
                    });
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildContactFields(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return _contactControllers.asMap().entries.map((entry) {
      final index = entry.key;
      final controller = entry.value;
      final focusNode = _contactFocusNodes[index];
      final selectedType = _selectedContactTypes[index];
      final isLastField = index == _contactControllers.length - 1;

      return Padding(
        padding: EdgeInsets.only(bottom: isLastField ? 24 : 16),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: Tooltip(
                        message: selectedType,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: theme.colorScheme.surfaceVariant
                                .withOpacity(0.3),
                          ),
                          child: Center(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: selectedType,
                                onChanged: (newValue) => setState(() {
                                  _selectedContactTypes[index] = newValue!;
                                  if (controller.text.isEmpty) {
                                    FocusScope.of(context)
                                        .requestFocus(focusNode);
                                  }
                                }),
                                items: _contactTypes.map((type) {
                                  return DropdownMenuItem<String>(
                                    value: type,
                                    child: Tooltip(
                                      message: type,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                        child: Icon(getContactIcon(type),
                                            size: 24),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                selectedItemBuilder: (context) {
                                  return _contactTypes.map((type) {
                                    return Center(
                                      child:
                                          Icon(getContactIcon(type), size: 24),
                                    );
                                  }).toList();
                                },
                                icon:
                                    const Icon(Icons.arrow_drop_down, size: 20),
                                borderRadius: BorderRadius.circular(12),
                                dropdownColor: theme.colorScheme.surface,
                                elevation: 4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                          hintText: _getContactHint(selectedType),
                          hintStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                          suffixIcon: _contactControllers.length > 1
                              ? IconButton(
                                  icon: Icon(Icons.remove_circle,
                                      color: theme.colorScheme.error),
                                  onPressed: () => _removeContactField(index),
                                )
                              : null,
                        ),
                        style: theme.textTheme.bodyMedium,
                        validator: (value) =>
                            value == "" ? loc.pleaseInputContactInfoMsg : null,
                        textInputAction: isLastField
                            ? TextInputAction.done
                            : TextInputAction.next,
                        keyboardType: _getKeyboardType(selectedType),
                        onEditingComplete: () {
                          if (isLastField) {
                            focusNode.unfocus();
                          } else {
                            FocusScope.of(context)
                                .requestFocus(_contactFocusNodes[index + 1]);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (isLastField)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonal(
                      onPressed: _addContactField,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: theme.colorScheme.surfaceVariant,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add,
                              size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(loc.addContactInfoMsg,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }).toList();
  }

  TextInputType _getKeyboardType(String contactType) {
    final type = contactType.toLowerCase();
    if (type.contains('phone')) {
      return TextInputType.phone;
    } else if (type.contains('email')) {
      return TextInputType.emailAddress;
    } else if (type.contains('website') || type.contains('url')) {
      return TextInputType.url;
    }
    return TextInputType.text;
  }

  String _getContactHint(String contactType) {
    switch (contactType.toLowerCase()) {
      case 'phone':
        return 'Enter phone number';
      case 'email':
        return 'Enter email address';
      case 'website':
        return 'Enter website URL';
      case 'whatsapp':
        return 'Enter WhatsApp number';
      case 'instagram':
        return 'Enter Instagram username';
      case 'facebook':
        return 'Enter Facebook page';
      case 'tiktok':
        return 'Enter TikTok username';
      default:
        return 'Enter contact information';
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  String _getTypeText(String type) {
    final lowercaseType = type.toLowerCase();
    final contactTypes = _contactTypes.where((t) => t == lowercaseType);
    return contactTypes.isEmpty ? _contactTypes.last : contactTypes.first;
  }

  IconData getContactIcon(String type) {
    final lowercaseType = type.toLowerCase();

    if (lowercaseType.contains('facebook')) return FontAwesomeIcons.facebook;
    if (lowercaseType.contains('phone')) return FontAwesomeIcons.phone;
    if (lowercaseType.contains('website')) return FontAwesomeIcons.globe;
    if (lowercaseType.contains('instagram')) return FontAwesomeIcons.instagram;
    if (lowercaseType.contains('email')) return FontAwesomeIcons.envelope;
    if (lowercaseType.contains('whatsapp')) return FontAwesomeIcons.whatsapp;
    if (lowercaseType.contains('tiktok')) return FontAwesomeIcons.tiktok;

    return FontAwesomeIcons.addressCard;
  }

  Widget _buildTextField(
    BuildContext context, {
    required String label,
    IconData? icon,
    String? Function(String?)? validator,
    String? initialValue,
    void Function(String?)? onSaved,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: validator,
      onSaved: onSaved,
      initialValue: initialValue,
    );
  }
}
