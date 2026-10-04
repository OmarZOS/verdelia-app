import 'dart:io';

import 'package:app_constants/app_constants.dart';
import 'package:app_constants/app_response_codes.dart';
import 'package:event/preferenceChangeNotifier.dart';
import 'package:event/user_change_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:locator/locator.dart';
import 'package:provider/provider.dart';
import 'package:ui/Services/ResponseHandler.dart';
import 'package:ui/components/gender/gender_widgets.dart';
import 'package:ui/components/map_picker.dart';
import 'package:verdelia_core/app/AppUser.dart';
import 'package:verdelia_core/app/Person.dart';
import 'package:verdelia_core/app/VerdeliaException.dart';
import 'package:verdelia_core/app/VerdeliaImage.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

class AppUserEditFormScreen extends StatefulWidget {
  const AppUserEditFormScreen({super.key});

  @override
  State<AppUserEditFormScreen> createState() => _AppUserEditFormScreenState();
}

class _AppUserEditFormScreenState extends State<AppUserEditFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late AppUser _editedUser;

  /// Pending gender selection. The dropdown emits on change, so it's
  /// kept in form state and folded into the model on submit.
  Gender? _editedGender;

  /// Pending birthday. `person_birth_date` is a String on the model
  /// (Date column on the backend), so the picker's DateTime is
  /// formatted to `YYYY-MM-DD` before being written back.
  DateTime? _editedBirthDate;

  bool _initialized = false;

  File? _editedImage;
  bool _isLoading = false;
  bool _imageChanged = false;

  // ==================== Lifecycle ====================

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      final AppUser? user = args?['user'];
      _editedUser = user ?? AppUser.empty();
      _editedGender = _editedUser.personGender;
      _editedBirthDate = _parseBirthDate(_editedUser.personBirthDate);
      _initialized = true;
    }
  }

  // ==================== Image ====================

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
    } on PlatformException {
      if (!mounted) return;
      ResponseHandler.handleResponse(
        context: context,
        statusCode: 500,
        responseCode: AppResponseCodes.put_success,
        finalMessage: AppLocalizations.of(context)!.putSuccess,
      );
    }
  }

  // ==================== Submit ====================

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    // Fold the values not managed by TextFormField back into the model.
    _editedUser = _editedUser.copyWith(
      personGender: _editedGender ?? Gender.unspecified,
      personBirthDate:
          _editedBirthDate != null ? _formatBirthDate(_editedBirthDate!) : null,
    );

    setState(() => _isLoading = true);

    try {
      var updatedUser = _editedUser;

      if (_imageChanged && _editedImage != null) {
        final image = AppLocator.get<VerdeliaImage>();
        image.setupImage(
          filepath: _editedImage!.path,
          filename: _editedImage!.path.split('/').last,
          entityType: 'user',
          ownerId: '${updatedUser.idAppUser}',
          entityId: '${updatedUser.idAppUser}',
        );
        final imageUrl = await image.uploadImage();
        if (imageUrl is! String || imageUrl.trim().isEmpty) {
          throw StateError('Image upload did not return an image URL.');
        }
        updatedUser = updatedUser.copyWith(appUserImageUrl: imageUrl);
      }

      await context.read<AppUserNotifier>().updateAppUser(updatedUser);

      if (!mounted) return;
      _editedUser = updatedUser;
      ResponseHandler.handleResponse(
        context: context,
        statusCode: 200,
        responseCode: 'PUT_SUCCESS',
        finalMessage: AppLocalizations.of(context)!.putSuccess,
      );
      Navigator.pop(context, updatedUser);
    } on VerdeliaException catch (e) {
      if (mounted) _showErrorSnackbar(e.message);
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar(AppLocalizations.of(context)!.putFailure);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  // ==================== Build ====================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(loc.personalInformation)),
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

                    // ─── Account ──────────────────────────────────
                    _buildSectionHeader(loc.accountInformation, theme),
                    _buildTextFormField(
                      label: loc.username,
                      initialValue: _editedUser.appUserName,
                      enabled: false,
                      onSaved: (v) =>
                          _editedUser = _editedUser.copyWith(appUserName: v),
                    ),
                    _buildTextFormField(
                      label: loc.emailText,
                      initialValue: _editedUser.appUserEmail,
                      keyboardType: TextInputType.emailAddress,
                      onSaved: (v) =>
                          _editedUser = _editedUser.copyWith(appUserEmail: v),
                      validator: _validateEmail,
                    ),

                    // ─── Personal information ─────────────────────
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
                    _buildDateField(
                      label: loc.birthdayText,
                      value: _editedBirthDate,
                      firstDate: DateTime(1900, 1, 1),
                      lastDate: DateTime.now(),
                      onChanged: (picked) {
                        setState(() => _editedBirthDate = picked);
                      },
                    ),
                    _buildTextFormField(
                      label: loc.phoneText,
                      initialValue: _editedUser.personPhone,
                      keyboardType: TextInputType.phone,
                      onSaved: (v) =>
                          _editedUser = _editedUser.copyWith(personPhone: v),
                    ),
                    _buildGenderField(loc),

                    // ─── Location ─────────────────────────────────
                    _buildSectionHeader(loc.locationInfoText, theme),
                    _buildTextFormField(
                      label: loc.locationNameText,
                      initialValue: _editedUser.locationName,
                      onSaved: (v) =>
                          _editedUser = _editedUser.copyWith(locationName: v),
                    ),
                    _buildLocationPicker(context),
                    const SizedBox(height: 16),
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
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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

  // ==================== Validators ====================

  /// Empty is allowed — the field is optional. Only a non-empty value
  /// gets the shape check.
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final email = value.trim();
    final atIndex = email.indexOf('@');
    if (atIndex <= 0 || atIndex == email.length - 1) {
      return AppLocalizations.of(context)!.invalidEmail;
    }
    if (!email.substring(atIndex + 1).contains('.')) {
      return AppLocalizations.of(context)!.invalidEmail;
    }
    return null;
  }

  // ==================== Gender ====================

  Widget _buildGenderField(AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GenderDropdownField(
        value: _editedGender,
        labelText: loc.genderText,
        allowUnspecified: true,
        onChanged: (value) {
          setState(() => _editedGender = value);
        },
      ),
    );
  }

  // ==================== Date ====================

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required DateTime firstDate,
    required DateTime lastDate,
    required ValueChanged<DateTime?> onChanged,
  }) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final locale =
        context.read<LocaleProvider>().locale?.toLanguageTag() ?? 'en';
    final hasValue = value != null;

    final display = hasValue ? DateFormat.yMd(locale).format(value) : loc.date;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime(2000, 1, 1),
            firstDate: firstDate,
            lastDate: lastDate,
            initialDatePickerMode: DatePickerMode.year,
            helpText: label,
            cancelText: loc.cancelButton,
            confirmText: loc.saveChanges,
            builder: (context, child) {
              return Localizations.override(
                context: context,
                locale: Localizations.localeOf(context),
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
          if (picked != null) onChanged(picked);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            suffixIcon: Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: hasValue
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          child: Text(
            display,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: hasValue
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
              fontStyle: hasValue ? FontStyle.normal : FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }

  // ==================== Location ====================

  Widget _buildLocationPicker(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final hasLocation = (_editedUser.locationLatitude != 0.0 &&
        _editedUser.locationLongitude != 0.0);

    return GestureDetector(
      onTap: () async {
        final position = await showLocationInputDialog(context);
        if (position != null && mounted) {
          setState(() {
            _editedUser = _editedUser.copyWith(
              locationLatitude: position.latitude,
              locationLongitude: position.longitude,
            );
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
                        ? '${_editedUser.locationLatitude?.toStringAsFixed(4)}, '
                            '${_editedUser.locationLongitude?.toStringAsFixed(4)}'
                        : loc.insertCoordinatesMsg,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: hasLocation
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            if (hasLocation)
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                color: theme.colorScheme.secondary,
                onPressed: () async {
                  final newPosition = await showLocationInputDialog(context);
                  if (newPosition != null && mounted) {
                    setState(() {
                      _editedUser = _editedUser.copyWith(
                        locationLatitude: newPosition.latitude,
                        locationLongitude: newPosition.longitude,
                      );
                    });
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  // ==================== Profile picture ====================

  Widget _buildProfilePictureSection(ThemeData theme, AppLocalizations loc) {
    // Single radius used for both the outer ring and the inner fill so
    // the network image fills the visible circle without overflow.
    final radius = MediaQuery.of(context).size.width * 0.25;
    final diameter = radius * 2;

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.tertiary,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: radius,
                backgroundColor: theme.colorScheme.surfaceVariant,
                backgroundImage:
                    _editedImage != null ? FileImage(_editedImage!) : null,
                child: _editedImage == null &&
                        (_editedUser.appUserImageUrl ?? '').isEmpty
                    ? Icon(
                        Icons.person,
                        size: diameter * 0.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      )
                    : _editedImage == null
                        ? ClipOval(
                            child: Image.network(
                              _editedUser.appUserImageUrl!,
                              width: diameter,
                              height: diameter,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.person,
                                size: diameter * 0.5,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        : null,
              ),
            ),
            FloatingActionButton.small(
              heroTag: 'edit_profile_picture',
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
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  // ==================== Building blocks ====================

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
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
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
        enabled: enabled,
        maxLength: maxLength,
        keyboardType: keyboardType,
        validator: validator ??
            (value) {
              if ((value?.isEmpty ?? true) && enabled) {
                return AppLocalizations.of(context)!.fieldRequired;
              }
              return null;
            },
        onSaved: onSaved,
      ),
    );
  }

  // ==================== Birth date helpers ====================

  DateTime? _parseBirthDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      return DateTime.parse(raw.trim());
    } catch (_) {
      return null;
    }
  }

  /// Format for the backend. `YYYY-MM-DD` matches the Date column type
  /// on `person_details` — no time component, no timezone ambiguity.
  String _formatBirthDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
