import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:event/user_change_notifier.dart';
import 'package:event/preferenceChangeNotifier.dart';
import 'package:provider/provider.dart';
import 'package:app_constants/app_constants.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class RegistrationForm extends StatefulWidget {
  const RegistrationForm({super.key});

  @override
  _RegistrationFormState createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();

  String? appUserName = "";
  String? appUserPassword = "";
  int? appUserTypeId = 0;
  String? personFirstName = "";
  String? personLastName = "";
  String? personGender = "";
  String? personNationality = "";
  int? bloodTypeId = 0;
  double? locationLatitude = 0;
  double? locationLongitude = 0;
  String? locationName = "";
  String? addressStreet = "";
  String? addressCity = "";
  String? addressPostalCode = "";
  String? addressCountry = "";

  bool agreedToTerms = false;
  bool agreedToPrivacy = false;

  final TextEditingController _birthDateController = TextEditingController();
  DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      // appBar: AppBar(
      //   title: Text(AppLocalizations.of(context)!.registerationFormText),
      //   centerTitle: true,
      //   elevation: 0,
      // ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Credentials Section
              const SizedBox(height: AppConstants.kDefaultPaddin),
              _buildSectionHeader(
                  context, AppLocalizations.of(context)!.userCredentialsText),
              _buildTextField(
                context,
                label: AppLocalizations.of(context)!.usernameText,
                onSaved: (value) => appUserName = value,
                validator: (value) => value?.isEmpty ?? true
                    ? AppLocalizations.of(context)!.pleaseInputusernameMsg
                    : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                context,
                label: AppLocalizations.of(context)!.passwordText,
                obscureText: true,
                onSaved: (value) => appUserPassword = value,
                validator: (value) => value?.isEmpty ?? true
                    ? AppLocalizations.of(context)!.pleaseInputpasswordMsg
                    : null,
              ),
              const SizedBox(height: 16),
              _buildDropdown<int>(
                context,
                label: AppLocalizations.of(context)!.userTypeText,
                items: [
                  {
                    'value': 1,
                    'label': AppLocalizations.of(context)!.clientText
                  },
                  {
                    'value': 3,
                    'label': AppLocalizations.of(context)!.cookingChefText
                  },
                  {
                    'value': 4,
                    'label': AppLocalizations.of(context)!.supplierText
                  }
                ],
                onChanged: (value) => appUserTypeId = value,
                validator: (value) => value == null
                    ? AppLocalizations.of(context)!.pleaseInputUserTypeMsg
                    : null,
              ),
              const SizedBox(height: 24),

              // Personal Information Section
              _buildSectionHeader(context,
                  AppLocalizations.of(context)!.registrationConditionsText),

              _buildLegalAgreement(context),

              // const SizedBox(height: 32),
              // Submit Button
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
                    borderRadius: BorderRadius.circular(12), // Rounded corners
                  ),
                ),
                onPressed: _submitForm,
                child: Text(
                  AppLocalizations.of(context)!.registerText,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildLegalAgreement(BuildContext context) {
    final theme = Theme.of(context);

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Terms of Use Agreement
            _buildAgreementTile(
              context,
              title: AppLocalizations.of(context)!.termsOfUse,
              url: 'https://verdelia.com/terms/terms_of_use_',
              content: AppLocalizations.of(context)!.termsAgreementText,
              value: agreedToTerms,
              onChanged: (value) => setState(() => agreedToTerms = value!),
            ),

            const SizedBox(height: 16),

            // Privacy Policy Agreement
            _buildAgreementTile(
              context,
              title: AppLocalizations.of(context)!.privacyPolicy,
              content: AppLocalizations.of(context)!.privacyAgreementText,
              url: 'https://verdelia.com/policy/privacy_policy_',
              value: agreedToPrivacy,
              onChanged: (value) => setState(() => agreedToPrivacy = value!),
            ),

            const SizedBox(height: 24),

            // Validation Error (if both not checked)
            if (!agreedToTerms || !agreedToPrivacy)
              Column(
                children: [
                  Text(
                    AppLocalizations.of(context)!.acceptAllTermsError,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              )
          ],
        );
      },
    );
  }

  Widget _buildAgreementTile(
    BuildContext context, {
    required String title,
    required String url,
    required String content,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox
          Transform.translate(
            offset: const Offset(0, -6), // Align with first line of text
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              side: BorderSide(
                color: theme.colorScheme.outline,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Clickable text
          Expanded(
            child: GestureDetector(
              onTap: () => openDocFromUrl(context, url),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  // Content preview
                  Text(
                    content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),

                  // "Read full document" link
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      AppLocalizations.of(context)!.readFullDocument,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> openDocFromUrl(BuildContext context, String url) async {
    String languageCode = Provider.of<LocaleProvider>(context, listen: false)
            .locale
            ?.languageCode ??
        "ar";

    final Uri final_url = Uri.parse('$url$languageCode.html');

    if (!await launchUrl(final_url, mode: LaunchMode.externalApplication)) {
      // throw Exception('Could not launch $url');
    }
  }

  Widget _buildTextField(
    BuildContext context, {
    required String label,
    TextEditingController? controller,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
    void Function()? onTap,
    bool readOnly = false,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        filled: true,
        suffixIcon: suffixIcon,
      ),
      validator: validator,
      onSaved: onSaved,
      onTap: onTap,
      readOnly: readOnly,
      obscureText: obscureText,
    );
  }

  Widget _buildDropdown<T>(
    BuildContext context, {
    required String label,
    required List<Map<String, dynamic>> items,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
    T? value,
  }) {
    return DropdownButtonFormField<T>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        filled: true,
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item['value'],
          child: Text(item['label']),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      value: value,
      isExpanded: true,
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate() && agreedToTerms && agreedToPrivacy) {
      _formKey.currentState!.save();

      var payload = {
        "user": {
          "id_app_user": 0,
          "app_user_person_id": 0,
          "app_user_name": appUserName ?? "",
          "app_user_password": appUserPassword ?? "",
          "app_user_type_id": appUserTypeId ?? 1,
          "app_user_preferences": "",
          "app_user_image": ""
        },
        "person": {
          "id_person": 0,
          "person_details_id": 0,
          "id_person_details": 0,
          "person_first_name": personFirstName ?? "",
          "person_last_name": personLastName ?? "",
          "person_birth_date": _birthDateController.text.isNotEmpty
              ? _birthDateController.text
              : "2000-01-01",
          "person_gender": personGender ?? "",
          "person_nationality": personNationality ?? "Unknown",
          "id_blood_type": bloodTypeId ?? 0
        },
        "location": {
          "id_location": 0,
          "id_address": 0,
          "location_address_id": 0,
          // "location_latitude": locationLatitude ?? 0.0,
          // "location_longitude": locationLongitude ?? 0.0,
          // "location_name": locationName ?? "",
          // "address_street": addressStreet ?? "",
          // "address_city": addressCity ?? "",
          // "address_postal_code": addressPostalCode ?? "00000",
          // "address_country": addressCountry ?? "Unknown"
        }
      };

      log(payload.toString());

      try {
        dynamic data =
            await Provider.of<AppUserNotifier>(context, listen: false)
                .signUpWithData(payload);

        if (data != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data.toString())),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.green,
              content: Text(AppLocalizations.of(context)!.loginSuccessfullMsg),
            ),
          );
        }

        Navigator.of(context).pop();
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(error.toString()),
          ),
        );
      }
    }
  }
}
