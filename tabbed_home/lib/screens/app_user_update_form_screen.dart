import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:app_constants/app_constants.dart';
import 'package:app_constants/app_response_codes.dart';
import 'package:verdelia_core/app/AppUser.dart';
import 'package:verdelia_core/app/VerdeliaException.dart';
import 'package:verdelia_core/app/VerdeliaImage.dart';
import 'package:verdelia_core/app/Services/UserService.dart';
import 'package:event/user_change_notifier.dart';
import 'package:ui/Services/ResponseHandler.dart';
import 'package:ui/components/map_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:locator/locator.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class AppUserEditFormScreen extends StatefulWidget {
  // final AppUser? appUser;

  const AppUserEditFormScreen({super.key});

  @override
  State<AppUserEditFormScreen> createState() => _AppUserEditFormScreenState();
}

class _AppUserEditFormScreenState extends State<AppUserEditFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late AppUser _editedUser;

  bool _initialized = false; // to prevent re-initialization

  File? _editedImage;
  bool _isLoading = false;
  bool _imageChanged = false;

  @override
  void initState() {
    super.initState();
    // _editedUser = widget.appUser!.copyWith(); // Deep copy
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
      );

      if (pickedFile != null) {
        setState(() {
          _imageChanged = true;
          _editedImage = File(pickedFile.path);
        });
      }
    } on PlatformException catch (e) {
      ResponseHandler.handleResponse(
        context: context,
        statusCode: 500,
        responseCode: AppResponseCodes.put_success,
        finalMessage: AppLocalizations.of(context)!.putSuccess,
      );
      // _showErrorSnackbar('Failed to pick image: ${e.message}');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      final AppUser? user = args?["user"];
      _editedUser = user ?? AppUser.empty();
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    // Copy editedUser now (because we modify it asynchronously later)
    var localUser = _editedUser;

    // Run tasks in background
    unawaited(Future(() async {
      try {
        if (_imageChanged && _editedImage != null) {
          VerdeliaImage image = AppLocator.get<VerdeliaImage>();
          image.setupImage(
            filepath: _editedImage!.path,
            filename: _editedImage!.path.split("/").last,
            entityType: 'user',
            ownerId: '${_editedUser.idAppUser}',
            entityId: '${_editedUser.idAppUser}',
          );
          final imageUrl = await image.uploadImage();

          localUser = localUser.copyWith(appUserImageUrl: imageUrl);
        }

        await Provider.of<AppUserNotifier>(context, listen: false)
            .updateAppUser(localUser);

        if (mounted) {
          ResponseHandler.handleResponse(
              context: context,
              statusCode: 200,
              responseCode: "PUT_SUCCESS",
              finalMessage: AppLocalizations.of(context)!.putSuccess);
          Navigator.pop(context, localUser);
        }
      } on VerdeliaException catch (e) {
        // _showErrorSnackbar(AppLocalizations.of(context)!.putFailure);
        ResponseHandler.handleResponse(
            context: context,
            statusCode: 200,
            responseCode: e.message,
            finalMessage: AppLocalizations.of(context)!.putSuccess);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }));
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.personalInformation),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildProfilePictureSection(theme, loc),
                    const SizedBox(height: 24),
                    _buildSectionHeader(loc.accountInformation, theme),
                    _buildTextFormField(
                      label: loc.username,
                      initialValue: _editedUser.appUserName,
                      enabled: false,
                      onSaved: (v) =>
                          _editedUser = _editedUser.copyWith(appUserName: v),
                    ),
                    _buildSectionHeader(loc.personalInformation, theme),
                    _buildTextFormField(
                      label: loc.firstName,
                      initialValue: _editedUser.personFirstName,
                      onSaved: (v) => _editedUser =
                          _editedUser.copyWith(personFirstName: v),
                    ),
                    _buildTextFormField(
                      label: loc.lastName,
                      initialValue: _editedUser.personLastName,
                      onSaved: (v) =>
                          _editedUser = _editedUser.copyWith(personLastName: v),
                    ),
                    _buildTextFormField(
                      label: loc.birthdayText,
                      initialValue: _editedUser.personBirthDate,
                      onSaved: (v) => _editedUser =
                          _editedUser.copyWith(personBirthDate: v),
                    ),
                    _buildTextFormField(
                      label: loc.genderText,
                      initialValue: _editedUser.personGender,
                      onSaved: (v) =>
                          _editedUser = _editedUser.copyWith(personGender: v),
                    ),
                    _buildSectionHeader(loc.locationInfoText, theme),
                    // _buildLocationPicker(context),
                    // const SizedBox(
                    //   height: 16,
                    // ),
                    _buildTextFormField(
                      label: loc.locationNameText,
                      initialValue: _editedUser.locationName,
                      onSaved: (v) =>
                          _editedUser = _editedUser.copyWith(locationName: v),
                    ),
                    _buildTextFormField(
                      label: loc.streetText,
                      initialValue: _editedUser.addressStreet,
                      onSaved: (v) =>
                          _editedUser = _editedUser.copyWith(addressStreet: v),
                    ),
                    _buildTextFormField(
                      label: loc.postalCodeText,
                      initialValue: _editedUser.addressPostalCode,
                      onSaved: (v) => _editedUser =
                          _editedUser.copyWith(addressPostalCode: v),
                    ),
                    _buildTextFormField(
                      label: loc.cityText,
                      initialValue: _editedUser.addressCity,
                      onSaved: (v) =>
                          _editedUser = _editedUser.copyWith(addressCity: v),
                    ),
                    _buildTextFormField(
                      label: loc.countryText,
                      initialValue: _editedUser.addressCountry,
                      onSaved: (v) =>
                          _editedUser = _editedUser.copyWith(addressCountry: v),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primary, // Button background color
                        foregroundColor: Theme.of(context)
                            .colorScheme
                            .onPrimary, // Text & icon color
                        padding: EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12), // optional
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12), // Rounded corners
                        ),
                      ),
                      onPressed: _submitForm,
                      child: Text(loc.saveChanges),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLocationPicker(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final hasLocation = (_editedUser.locationLatitude != 0.0 &&
        _editedUser.locationLongitude != 0.0);

    return GestureDetector(
      onTap: () async {
        final position = await showLocationInputDialog(context);
        if (position != null && mounted) {
          // _position = position;
          _editedUser = _editedUser.copyWith(
              locationLatitude: position.latitude,
              locationLongitude: position.longitude);
          // setState(() {
          // });
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
                        ? '${_editedUser.locationLatitude?.toStringAsFixed(4)}, ${_editedUser.locationLongitude?.toStringAsFixed(4)}'
                        : loc.insertCoordinatesMsg,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: hasLocation
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  if (hasLocation && _editedUser.locationName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _editedUser.locationName ?? "",
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
                      _editedUser = _editedUser.copyWith(
                          locationLatitude: newPosition.latitude,
                          locationLongitude: newPosition.longitude);
                    });
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePictureSection(ThemeData theme, AppLocalizations loc) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: MediaQuery.of(context).size.width * 0.25,
              backgroundImage:
                  _editedImage != null ? FileImage(_editedImage!) : null,
              child: _editedImage == null
                  ? CircleAvatar(
                      radius: MediaQuery.of(context).size.width * 0.5,
                      backgroundColor: theme.colorScheme.surfaceVariant,
                      child: _editedUser.appUserImageUrl != null
                          ? ClipOval(
                              child: Image.network(
                                _editedUser.appUserImageUrl!,
                                width: MediaQuery.of(context).size.width * 0.5,
                                height: MediaQuery.of(context).size.width * 0.5,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 100,
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: Icon(Icons.person,
                                          size: 60, color: Colors.white),
                                    ),
                                  );
                                },
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: 50,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                    )
                  : null,
            ),
            FloatingActionButton.small(
              onPressed: _pickImage,
              child: const Icon(Icons.camera_alt),
            ),
          ],
        ),
        if (_imageChanged)
          Column(
            children: [
              const SizedBox(height: AppConstants.kDefaultPaddin),
              TextButton(
                onPressed: () => setState(() {
                  _imageChanged = false;
                  _editedImage = null;
                }),
                child: Text(
                  loc.removePhoto,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required String label,
    required String? initialValue,
    required void Function(String?) onSaved,
    int maxLength = 300,
    bool enabled = true, // <-- default value: disabled
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          counterText: '',
        ),
        enabled: enabled, // <-- control editing here
        maxLength: maxLength,
        validator: (value) {
          if ((value?.isEmpty ?? true) && enabled) {
            return AppLocalizations.of(context)!.fieldRequired;
          }
          return null;
        },
        onSaved: onSaved,
      ),
    );
  }
}
