import 'dart:convert';
import 'dart:typed_data';

import 'package:verdelia_core/app/ManagementRule.dart';
import 'package:verdelia_core/app/Person.dart';

enum AppUserType {
  provider,
  customer,
  patient,
  guest,
}

extension AppUserTypeExtension on AppUserType {
  String get value {
    switch (this) {
      case AppUserType.provider:
        return 'provider';
      case AppUserType.customer:
        return 'customer';
      case AppUserType.patient:
        return 'patient';
      case AppUserType.guest:
        return 'guest';
    }
  }

  static AppUserType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'provider':
        return AppUserType.provider;
      case 'customer':
        return AppUserType.customer;
      case 'patient':
        return AppUserType.patient;
      default:
        return AppUserType.guest;
    }
  }
}

class AppUser {
  // User fields (matches AppUser_API)
  final int? idAppUser;
  final String? appUserName;
  final String? appUserPassword;
  final int? appUserPersonId;
  final String? appUserPreferences;
  final String? appUserEmail;
  final String? appUserImageUrl;
  final AppUserType? appUserType;

  // Person fields (matches Person_API)
  final int? idPerson;
  final int? personDetailsId;
  final int? idPersonDetails;
  final String? personFirstName;
  final String? personLastName;
  final String? personBirthDate;
  final String? personGender;
  final String? personCountryCode;
  final String? bloodType;
  final String? personPhone;
  final String? personEmail;

  // Location fields (matches Location_API)
  final int? idLocation;
  final double? locationLatitude;
  final double? locationLongitude;
  final String? locationName;
  final int? locationAddressId;
  final int? idAddress;
  final String? addressStreet;
  final String? addressCity;
  final String? addressPostalCode;
  final String? addressCountry;

  final List<ManagementRule>? privileges;

  bool get isAdmin => appUserType == AppUserType.provider;

  AppUser({
    this.idAppUser,
    this.appUserName,
    this.appUserPassword,
    this.appUserPersonId,
    this.appUserPreferences,
    this.appUserEmail,
    this.appUserImageUrl,
    this.appUserType,
    this.idPerson,
    this.personDetailsId,
    this.idPersonDetails,
    this.personFirstName,
    this.personLastName,
    this.personBirthDate,
    this.personGender,
    this.personCountryCode,
    this.bloodType,
    this.personPhone,
    this.personEmail,
    this.idLocation,
    this.locationLatitude,
    this.locationLongitude,
    this.locationName,
    this.locationAddressId,
    this.idAddress,
    this.addressStreet,
    this.addressCity,
    this.addressPostalCode,
    this.addressCountry,
    this.privileges,
  });

  // ============ FACTORY METHODS ============

  /// Main fromJson - handles full AppUser structure
  factory AppUser.fromJson(Map<String, dynamic> json) {
    // Parse user data
    final appUserPerson =
        json['app_user_person'] as Map<String, dynamic>? ?? {};
    final personDetails =
        appUserPerson['person_details'] as Map<String, dynamic>? ?? {};
    final personLocation =
        appUserPerson['person_location'] as Map<String, dynamic>? ?? {};
    final locationAddress =
        personLocation['location_address'] as Map<String, dynamic>? ?? {};

    // Parse location coordinates from position_wkt (POINT(lng lat))
    double lat = 0.0, lng = 0.0;
    final positionWkt = personLocation['position_wkt']?.toString() ?? '';
    if (positionWkt.isNotEmpty) {
      final match =
          RegExp(r'POINT\(([0-9.]+)\s+([0-9.]+)\)').firstMatch(positionWkt);
      if (match != null) {
        lng = double.tryParse(match.group(1) ?? '0') ?? 0.0;
        lat = double.tryParse(match.group(2) ?? '0') ?? 0.0;
      }
    }

    // Get user type
    AppUserType? userType;
    final userTypeStr = json['app_user_type'];
    if (userTypeStr != null && userTypeStr is String) {
      userType = AppUserTypeExtension.fromString(userTypeStr);
    }

    return AppUser(
      // User fields
      idAppUser: json['id_app_user'],
      appUserName: json['app_user_name'],
      appUserPassword: json['app_user_password'],
      appUserPersonId: json['app_user_person_id'],
      appUserPreferences: json['app_user_preferences'],
      appUserEmail: json['app_user_email'],
      appUserImageUrl: json['app_user_image_url'],
      appUserType: userType,

      // Person fields
      idPerson: appUserPerson['id_person'],
      personDetailsId: appUserPerson['person_details_id'],
      idPersonDetails: personDetails['id_person_details'],
      personFirstName: personDetails['person_first_name'],
      personLastName: personDetails['person_last_name'],
      personBirthDate: personDetails['person_birth_date'],
      personGender: personDetails['person_gender'],
      personCountryCode: personDetails['person_country_code'],
      bloodType: appUserPerson['person_blood_type'],
      personPhone: personDetails['person_phone'],
      personEmail: personDetails['person_email'],

      // Location fields
      idLocation: personLocation['id_location'],
      locationLatitude: lat,
      locationLongitude: lng,
      locationName: personLocation['location_name'],
      locationAddressId: personLocation['location_address_id'],
      idAddress: locationAddress['id_address'],
      addressStreet: locationAddress['address_street'],
      addressCity: locationAddress['address_city'],
      addressPostalCode: locationAddress['address_postal_code'],
      addressCountry: locationAddress['address_country'],

      privileges: null,
    );
  }

  /// Parse from Person object (search endpoint result)
  factory AppUser.fromPerson(Person person) {
    return AppUser(
      // User fields (use person data as user)
      idAppUser: person.id_person,
      appUserName: person.fullName,
      appUserPassword: '',
      appUserPersonId: person.id_person,
      appUserPreferences: '',
      appUserEmail: person.person_details.person_email ??
          person.person_details.person_phone ??
          '',
      appUserImageUrl: '',
      appUserType: AppUserType.guest,

      // Person fields
      idPerson: person.id_person,
      personDetailsId: person.person_details_id,
      idPersonDetails: person.person_details.id_person_details,
      personFirstName: person.person_details.person_first_name,
      personLastName: person.person_details.person_last_name,
      personBirthDate:
          person.person_details.person_birth_date?.toIso8601String(),
      personGender: person.person_details.person_gender,
      personCountryCode: person.person_details.person_country_code,
      bloodType: person.person_blood_type,
      personPhone: person.person_details.person_phone,
      personEmail: person.person_details.person_email,

      // Location fields (not available in search result)
      idLocation: null,
      locationLatitude: null,
      locationLongitude: null,
      locationName: null,
      locationAddressId: null,
      idAddress: null,
      addressStreet: null,
      addressCity: null,
      addressPostalCode: null,
      addressCountry: null,

      privileges: null,
    );
  }

  /// Parse from search endpoint JSON (Person structure with nested person_details)
  factory AppUser.fromPersonSearchJson(Map<String, dynamic> json) {
    final personDetails = json['person_details'] as Map<String, dynamic>? ?? {};

    return AppUser(
      // User fields (use person data as user)
      idAppUser: json['id_person'],
      appUserName: _buildFullName(
        personDetails['person_first_name'],
        personDetails['person_last_name'],
      ),
      appUserPassword: '',
      appUserPersonId: json['id_person'],
      appUserPreferences: '',
      appUserEmail:
          personDetails['person_phone'] ?? personDetails['person_email'] ?? '',
      appUserImageUrl: '',
      appUserType: AppUserType.guest,

      // Person fields
      idPerson: json['id_person'],
      personDetailsId: json['person_details_id'],
      idPersonDetails: personDetails['id_person_details'],
      personFirstName: personDetails['person_first_name'],
      personLastName: personDetails['person_last_name'],
      personBirthDate: personDetails['person_birth_date'],
      personGender: personDetails['person_gender'],
      personCountryCode: personDetails['person_country_code'],
      bloodType: json['person_blood_type'],
      personPhone: personDetails['person_phone'],
      personEmail: personDetails['person_email'],

      // Location fields (not available in search result)
      idLocation: null,
      locationLatitude: null,
      locationLongitude: null,
      locationName: null,
      locationAddressId: null,
      idAddress: null,
      addressStreet: null,
      addressCity: null,
      addressPostalCode: null,
      addressCountry: null,

      privileges: null,
    );
  }

  /// Parse from persisted JSON
  factory AppUser.fromPersistedJson(Map<String, dynamic> json) {
    final userData = json['user'] as Map<String, dynamic>? ?? {};
    final personData = json['person_record'] as Map<String, dynamic>? ?? {};
    final locationData = json['location_record'] as Map<String, dynamic>? ?? {};

    AppUserType? userType;
    final userTypeStr = userData['app_user_type'];
    if (userTypeStr != null && userTypeStr is String) {
      userType = AppUserTypeExtension.fromString(userTypeStr);
    }

    return AppUser(
      // User fields
      idAppUser: userData['id_app_user'],
      appUserName: userData['app_user_name'],
      appUserPassword: userData['app_user_password'],
      appUserPersonId: userData['app_user_person_id'],
      appUserPreferences: userData['app_user_preferences'],
      appUserEmail: userData['app_user_email'],
      appUserImageUrl: userData['app_user_image_url'],
      appUserType: userType,

      // Person fields
      idPerson: personData['id_person'],
      personDetailsId: personData['person_details_id'],
      idPersonDetails: personData['id_person_details'],
      personFirstName: personData['person_first_name'],
      personLastName: personData['person_last_name'],
      personBirthDate: personData['person_birth_date'],
      personGender: personData['person_gender'],
      personCountryCode: personData['person_country_code'],
      bloodType: personData['blood_type'],
      personPhone: personData['person_phone'],
      personEmail: personData['person_email'],

      // Location fields
      idLocation: locationData['id_location'],
      locationLatitude: locationData['location_latitude']?.toDouble(),
      locationLongitude: locationData['location_longitude']?.toDouble(),
      locationName: locationData['location_name'],
      locationAddressId: locationData['location_address_id'],
      idAddress: locationData['id_address'],
      addressStreet: locationData['address_street'],
      addressCity: locationData['address_city'],
      addressPostalCode: locationData['address_postal_code'],
      addressCountry: locationData['address_country'],

      privileges: null,
    );
  }

  /// Parse from Google JSON
  factory AppUser.fromGoogleJson(Map<String, dynamic> json) {
    final userData = json['user'];
    final tokenData = json['token'];
    final userInfo = tokenData?['userinfo'] ?? {};

    final idAppUser = userData?['id_app_user'] ?? 0;
    final appUserName = userData?['app_user_name'] ?? userInfo['email'] ?? "";
    final appUserImageUrl =
        userData?['app_user_image_url'] ?? userInfo['picture'] ?? "";
    final appUserType = AppUserTypeExtension.fromString(
        userData?['app_user_type'] ?? 'customer');
    final givenName = userInfo['given_name'] ?? "";
    final familyName = userInfo['family_name'] ?? "";
    final fullName = userInfo['name'] ?? "$givenName $familyName".trim();
    final email = userInfo['email'] ?? appUserName;

    String personFirstName = givenName;
    String personLastName = familyName;

    if (personFirstName.isEmpty &&
        personLastName.isEmpty &&
        fullName.isNotEmpty) {
      final nameParts = fullName.split(' ');
      personFirstName = nameParts.first;
      personLastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    }

    return AppUser(
      idAppUser: idAppUser,
      appUserName: appUserName,
      appUserPassword: "",
      appUserPersonId: userData?['app_user_person_id'] ?? 0,
      appUserPreferences: userData?['app_user_preferences'] ?? "",
      appUserEmail: email,
      appUserImageUrl: appUserImageUrl,
      appUserType: appUserType,
      personFirstName: personFirstName,
      personLastName: personLastName,
    );
  }

  /// Create empty user
  factory AppUser.empty() {
    return AppUser(
      idAppUser: 0,
      appUserName: '',
      appUserPassword: '',
      appUserPersonId: 0,
      appUserPreferences: '',
      appUserEmail: '',
      appUserImageUrl: '',
      appUserType: AppUserType.guest,
    );
  }

  // ============ HELPER METHODS ============

  static String _buildFullName(String? firstName, String? lastName) {
    final first = firstName ?? '';
    final last = lastName ?? '';
    if (first.isEmpty && last.isEmpty) return 'Unknown';
    if (first.isEmpty) return last;
    if (last.isEmpty) return first;
    return '$first $last';
  }

  // ============ TO JSON METHODS ============

  Map<String, dynamic> toJson() {
    return {
      "user": {
        "id_app_user": idAppUser,
        "app_user_name": appUserName,
        "app_user_password": appUserPassword,
        "app_user_person_id": appUserPersonId,
        "app_user_preferences": appUserPreferences,
        "app_user_email": appUserEmail,
        "app_user_image_url": appUserImageUrl,
        "app_user_type": appUserType?.value,
      },
      "person_record": {
        "id_person": idPerson,
        "person_details_id": personDetailsId,
        "id_person_details": idPersonDetails,
        "person_first_name": personFirstName,
        "person_last_name": personLastName,
        "person_birth_date": personBirthDate,
        "person_gender": personGender,
        "person_country_code": personCountryCode,
        "blood_type": bloodType,
        "person_phone": personPhone,
        "person_email": personEmail,
      },
      "location_record": {
        "id_location": idLocation,
        "location_latitude": locationLatitude,
        "location_longitude": locationLongitude,
        "location_name": locationName,
        "location_address_id": locationAddressId,
        "id_address": idAddress,
        "address_street": addressStreet,
        "address_city": addressCity,
        "address_postal_code": addressPostalCode,
        "address_country": addressCountry,
      }
    };
  }

  Map<String, dynamic> toApiJson() {
    return {
      "id_app_user": idAppUser,
      "app_user_name": appUserName,
      "app_user_password": appUserPassword,
      "app_user_person_id": appUserPersonId,
      "app_user_preferences": appUserPreferences,
      "app_user_email": appUserEmail,
      "app_user_image_url": appUserImageUrl,
      "app_user_type": appUserType?.value,
    };
  }

  // ============ COPY WITH ============

  AppUser copyWith({
    int? idAppUser,
    String? appUserName,
    String? appUserPassword,
    int? appUserPersonId,
    String? appUserPreferences,
    String? appUserEmail,
    String? appUserImageUrl,
    AppUserType? appUserType,
    int? idPerson,
    int? personDetailsId,
    int? idPersonDetails,
    String? personFirstName,
    String? personLastName,
    String? personBirthDate,
    String? personGender,
    String? personCountryCode,
    String? bloodType,
    String? personPhone,
    String? personEmail,
    int? idLocation,
    double? locationLatitude,
    double? locationLongitude,
    String? locationName,
    int? locationAddressId,
    int? idAddress,
    String? addressStreet,
    String? addressCity,
    String? addressPostalCode,
    String? addressCountry,
    List<ManagementRule>? privileges,
  }) {
    return AppUser(
      idAppUser: idAppUser ?? this.idAppUser,
      appUserName: appUserName ?? this.appUserName,
      appUserPassword: appUserPassword ?? this.appUserPassword,
      appUserPersonId: appUserPersonId ?? this.appUserPersonId,
      appUserPreferences: appUserPreferences ?? this.appUserPreferences,
      appUserEmail: appUserEmail ?? this.appUserEmail,
      appUserImageUrl: appUserImageUrl ?? this.appUserImageUrl,
      appUserType: appUserType ?? this.appUserType,
      idPerson: idPerson ?? this.idPerson,
      personDetailsId: personDetailsId ?? this.personDetailsId,
      idPersonDetails: idPersonDetails ?? this.idPersonDetails,
      personFirstName: personFirstName ?? this.personFirstName,
      personLastName: personLastName ?? this.personLastName,
      personBirthDate: personBirthDate ?? this.personBirthDate,
      personGender: personGender ?? this.personGender,
      personCountryCode: personCountryCode ?? this.personCountryCode,
      bloodType: bloodType ?? this.bloodType,
      personPhone: personPhone ?? this.personPhone,
      personEmail: personEmail ?? this.personEmail,
      idLocation: idLocation ?? this.idLocation,
      locationLatitude: locationLatitude ?? this.locationLatitude,
      locationLongitude: locationLongitude ?? this.locationLongitude,
      locationName: locationName ?? this.locationName,
      locationAddressId: locationAddressId ?? this.locationAddressId,
      idAddress: idAddress ?? this.idAddress,
      addressStreet: addressStreet ?? this.addressStreet,
      addressCity: addressCity ?? this.addressCity,
      addressPostalCode: addressPostalCode ?? this.addressPostalCode,
      addressCountry: addressCountry ?? this.addressCountry,
      privileges: privileges ?? this.privileges,
    );
  }

  // ============ LIST HELPERS ============

  static List<AppUser> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((json) => AppUser.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static List<AppUser> fromPersonSearchJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((json) =>
            AppUser.fromPersonSearchJson(json as Map<String, dynamic>))
        .toList();
  }

  static List<AppUser> fromPersonList(List<Person> people) {
    return people.map((person) => AppUser.fromPerson(person)).toList();
  }

  // ============ DISPLAY HELPERS ============

  String get displayName {
    if (appUserName != null && appUserName!.isNotEmpty) {
      return appUserName!;
    }
    return _buildFullName(personFirstName, personLastName);
  }

  String get shortName {
    final name = displayName;
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  bool get hasPersonData {
    return idPerson != null && idPerson! > 0;
  }

  bool get hasUserData {
    return idAppUser != null && idAppUser! > 0;
  }

  bool get isValid => hasUserData || hasPersonData;

  @override
  String toString() {
    return 'AppUser(id: $idAppUser, name: $displayName, type: ${appUserType?.value})';
  }
}

class AppUserCategory {
  final int idAppUserType;
  final String appUserTypeDesc;

  AppUserCategory({
    required this.idAppUserType,
    required this.appUserTypeDesc,
  });

  factory AppUserCategory.fromJson(Map<String, dynamic> json) {
    return AppUserCategory(
      idAppUserType: json['id_app_user_type'] ?? 0,
      appUserTypeDesc: json['app_user_type_desc'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_app_user_type': idAppUserType,
      'app_user_type_desc': appUserTypeDesc,
    };
  }
}
