import 'dart:convert';
import 'dart:typed_data';

import 'package:verdelia_core/app/ManagementRule.dart';
import 'package:verdelia_core/app/Person.dart';
import 'package:verdelia_core/app/finance/Subscription.dart';

import 'Person.dart';

enum AppUserType {
  provider,
  customer,
  patient,
  guest,
}

/// Wallet snapshot, when the backend inlines it on a payload.
class Wallet {
  final int? idWallet;
  final String walletType;
  final String walletCurrency;
  final double walletBalance;
  final String walletStatus;
  final int walletVersion;

  const Wallet({
    this.idWallet,
    this.walletType = 'user',
    this.walletCurrency = 'DZD',
    this.walletBalance = 0.0,
    this.walletStatus = 'pending_verification',
    this.walletVersion = 0,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      idWallet: _asInt(json['id_wallet']),
      walletType: (json['wallet_type'] ?? 'user').toString(),
      walletCurrency: (json['wallet_currency'] ?? 'DZD').toString(),
      walletBalance: _asDouble(json['wallet_balance']) ?? 0.0,
      walletStatus:
          (json['wallet_status'] ?? 'pending_verification').toString(),
      walletVersion: _asInt(json['wallet_version']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        if (idWallet != null) 'id_wallet': idWallet,
        'wallet_type': walletType,
        'wallet_currency': walletCurrency,
        'wallet_balance': walletBalance,
        'wallet_status': walletStatus,
        'wallet_version': walletVersion,
      };

  bool get isActive => walletStatus == 'active';
  bool get isPendingVerification => walletStatus == 'pending_verification';
  bool get isSuspended => walletStatus == 'suspended';
  bool get isClosed => walletStatus == 'closed';
  bool get isInactive => walletStatus == 'inactive';
  bool get canTransact => isActive;
  bool get hasFunds => walletBalance > 0;

  @override
  String toString() => 'Wallet(id: $idWallet, type: $walletType, '
      'balance: $walletBalance $walletCurrency, status: $walletStatus)';
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

enum VerifiedAppUser {
  unverified,
  verified,
  unknown;

  static VerifiedAppUser? fromWire(dynamic raw) {
    if (raw == null) return null;
    if (raw is bool) {
      return raw ? VerifiedAppUser.verified : VerifiedAppUser.unverified;
    }
    if (raw is num) {
      if (raw == 1) return VerifiedAppUser.verified;
      if (raw == 0) return VerifiedAppUser.unverified;
      return VerifiedAppUser.unknown;
    }
    if (raw is String) {
      final lower = raw.toLowerCase().trim();
      if (lower == 'verified' || lower == 'true' || lower == '1') {
        return VerifiedAppUser.verified;
      }
      if (lower == 'unverified' || lower == 'false' || lower == '0') {
        return VerifiedAppUser.unverified;
      }
    }
    return VerifiedAppUser.unknown;
  }

  bool get isVerified => this == VerifiedAppUser.verified;
}

enum LoginOption {
  google,
  verdelia;

  static LoginOption? fromWire(dynamic raw) {
    if (raw is! String) return null;
    switch (raw.toLowerCase().trim()) {
      case 'google':
        return LoginOption.google;
      case 'verdelia':
        return LoginOption.verdelia;
      default:
        return null;
    }
  }

  String get wireValue {
    switch (this) {
      case LoginOption.google:
        return 'google';
      case LoginOption.verdelia:
        return 'verdelia';
    }
  }
}

class AppUser {
  // ── User fields ────────────────────────────────────────────────
  final int? idAppUser;
  final String? appUserName;
  final String? appUserPassword;
  final int? appUserPersonId;
  final String? appUserPreferences;
  final String? appUserEmail;
  final String? appUserImageUrl;
  final AppUserType? appUserType;

  /// **Wire name:** `app_user_subscription_id`. The old model read
  /// `app_user_subscription_ref`, which the API never emits — so
  /// [hasSubscription] was always false for real payloads.
  final int? appUserSubscriptionRef;

  /// **Wire name:** `app_user_wallet_id`.
  final int? appUserWalletId;

  final LoginOption? appUserLoginOption;
  final VerifiedAppUser? verifiedAppUser;

  /// Local quota mirror. Decremented by the workflow, refreshed on
  /// subscription changes. Not present in the user payload — the
  /// quota lives on the subscription row as `subscription_quota`.
  final int? userQuota;

  // ── Timestamps ────────────────────────────────────────────────
  final DateTime? appUserCreation;
  final DateTime? appUserLastUpdated;
  final DateTime? appUserLastActive;

  // ── Person fields ─────────────────────────────────────────────
  final int? idPerson;
  final int? personDetailsId;
  final int? idPersonDetails;
  final String? personFirstName;
  final String? personLastName;
  final String? personBirthDate;
  final Gender personGender;
  final String? personCountryCode;
  final String? bloodType;
  final String? personPhone;
  final String? personEmail;

  // ── Location fields ───────────────────────────────────────────
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

  // ── Nested snapshots ─────────────────────────────────────────
  /// **Wire name:** `app_user_subscription`. The old model read
  /// `subscription`, which the API never emits.
  final Subscription? subscription;

  /// **Wire name:** `app_user_wallet`.
  final Wallet? wallet;

  // ── Privileges ────────────────────────────────────────────────
  final List<ManagementRule>? privileges;

  // ── Derived getters ───────────────────────────────────────────
  bool get isAdmin => appUserType == AppUserType.provider;
  bool get hasSubscription => appUserSubscriptionRef != null;
  bool get hasActiveSubscription =>
      subscription != null && subscription!.isActive;
  bool get hasWallet => appUserWalletId != null;
  bool get hasInlinedWallet => wallet != null;
  double? get walletBalance => wallet?.walletBalance;
  bool get isWalletActive => wallet?.isActive ?? false;
  bool get isVerified => verifiedAppUser?.isVerified ?? false;
  int get quota => userQuota ?? subscription?.subscriptionQuota?.toInt() ?? 0;

  AppUser({
    this.idAppUser,
    this.appUserName,
    this.appUserPassword,
    this.appUserPersonId,
    this.appUserPreferences,
    this.appUserEmail,
    this.appUserImageUrl,
    this.appUserType,
    this.appUserSubscriptionRef,
    this.appUserWalletId,
    this.appUserLoginOption,
    this.verifiedAppUser,
    this.userQuota,
    this.appUserCreation,
    this.appUserLastUpdated,
    this.appUserLastActive,
    this.idPerson,
    this.personDetailsId,
    this.idPersonDetails,
    this.personFirstName,
    this.personLastName,
    this.personBirthDate,
    this.personGender = Gender.unspecified,
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
    this.subscription,
    this.wallet,
    this.privileges,
  });

  // ==================== fromJson ====================

  /// Parse the canonical user payload.
  ///
  /// Wire shape (abbreviated):
  /// ```json
  /// {
  ///   "id_app_user": 13,
  ///   "app_user_name": "...",
  ///   "app_user_person_id": 12,
  ///   "app_user_subscription_id": 26,          ← FK
  ///   "app_user_wallet_id": 21,                 ← FK
  ///   "app_user_preferences": "\"{...}\"",     ← double-encoded
  ///   "app_user_wallet": { ... },              ← inline snapshot
  ///   "app_user_subscription": { ... },        ← inline snapshot
  ///   "app_user_person": {
  ///     "id_person": 12,
  ///     "person_blood_type": null,
  ///     "person_details": {
  ///       "id_person_details": 12,
  ///       "person_first_name": "Amina",
  ///       "person_gender": "Female",
  ///       ...
  ///     },
  ///     "person_location": {
  ///       "id_location": 12,
  ///       "position_wkt": "POINT(-2.7 36.3)",   ← negative lng
  ///       "location_address": { ... }
  ///     }
  ///   }
  /// }
  /// ```
  factory AppUser.fromJson(Map<String, dynamic> json) {
    final appUserPerson =
        json['app_user_person'] as Map<String, dynamic>? ?? {};
    final personDetails =
        appUserPerson['person_details'] as Map<String, dynamic>? ?? {};
    final personLocation =
        appUserPerson['person_location'] as Map<String, dynamic>? ?? {};
    final locationAddress =
        personLocation['location_address'] as Map<String, dynamic>? ?? {};

    final coords = _parseWkt(personLocation['position_wkt']?.toString());

    AppUserType? userType;
    final userTypeStr = json['app_user_type'];
    if (userTypeStr is String) {
      userType = AppUserTypeExtension.fromString(userTypeStr);
    }

    Subscription? subscription;
    final subJson = json['app_user_subscription'];
    if (subJson is Map) {
      subscription = Subscription.fromJson(
        Map<String, dynamic>.from(subJson),
      );
    }

    Wallet? wallet;
    final walletJson = json['app_user_wallet'];
    if (walletJson is Map) {
      wallet = Wallet.fromJson(Map<String, dynamic>.from(walletJson));
    }

    return AppUser(
      idAppUser: _asInt(json['id_app_user']),
      appUserName: json['app_user_name'],
      appUserPassword: json['app_user_password'],
      appUserPersonId: _asInt(json['app_user_person_id']),
      appUserPreferences: _normalizePreferences(json['app_user_preferences']),
      appUserEmail: json['app_user_email'],
      appUserImageUrl: json['app_user_image_url'],
      appUserType: userType,
      appUserSubscriptionRef: _asInt(
        json['app_user_subscription_id'] ?? json['app_user_subscription_ref'],
      ),
      appUserWalletId: _asInt(json['app_user_wallet_id']),
      appUserLoginOption: LoginOption.fromWire(json['app_user_login_option']),
      verifiedAppUser: VerifiedAppUser.fromWire(json['verified_app_user']),
      userQuota: _asInt(json['user_quota']),
      appUserCreation: _parseDate(json['app_user_creation']),
      appUserLastUpdated: _parseDate(json['app_user_last_updated']),
      appUserLastActive: _parseDate(json['app_user_last_active']),
      idPerson: _asInt(appUserPerson['id_person']),
      personDetailsId: _asInt(
        appUserPerson['person_details_id'] ??
            personDetails['id_person_details'],
      ),
      idPersonDetails: _asInt(personDetails['id_person_details']),
      personFirstName: personDetails['person_first_name'],
      personLastName: personDetails['person_last_name'],
      personBirthDate: personDetails['person_birth_date'],
      personGender: Gender.fromString(
        (personDetails['person_gender'] as String?)?.toLowerCase(),
      ),
      personCountryCode: personDetails['person_country_code'],
      bloodType: appUserPerson['person_blood_type'],
      personPhone: personDetails['person_phone'],
      personEmail: personDetails['person_email'],
      idLocation: _asInt(personLocation['id_location']),
      locationLatitude: coords?.$2,
      locationLongitude: coords?.$1,
      locationName: personLocation['location_name'],
      locationAddressId: _asInt(personLocation['location_address_id']),
      idAddress: _asInt(locationAddress['id_address']),
      addressStreet: locationAddress['address_street'],
      addressCity: locationAddress['address_city'],
      addressPostalCode: locationAddress['address_postal_code'],
      addressCountry: locationAddress['address_country'],
      subscription: subscription,
      wallet: wallet,
      privileges: null,
    );
  }

  static String _buildFullName(String? firstName, String? lastName) {
    final first = firstName ?? '';
    final last = lastName ?? '';
    if (first.isEmpty && last.isEmpty) return 'Unknown';
    if (first.isEmpty) return last;
    if (last.isEmpty) return first;
    return '$first $last';
  }

  factory AppUser.fromPerson(Person person) {
    return AppUser(
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
      privileges: null,
    );
  }

  factory AppUser.fromPersonSearchJson(Map<String, dynamic> json) {
    final personDetails = json['person_details'] as Map<String, dynamic>? ?? {};

    return AppUser(
      idAppUser: _asInt(json['id_person']),
      appUserName: _buildFullName(
        personDetails['person_first_name'],
        personDetails['person_last_name'],
      ),
      appUserPassword: '',
      appUserPersonId: _asInt(json['id_person']),
      appUserPreferences: '',
      appUserEmail:
          personDetails['person_phone'] ?? personDetails['person_email'] ?? '',
      appUserImageUrl: '',
      appUserType: AppUserType.guest,
      idPerson: _asInt(json['id_person']),
      personDetailsId: _asInt(json['person_details_id']),
      idPersonDetails: _asInt(personDetails['id_person_details']),
      personFirstName: personDetails['person_first_name'],
      personLastName: personDetails['person_last_name'],
      personBirthDate: personDetails['person_birth_date'],
      personGender: Gender.fromString(
        (personDetails['person_gender'] as String?)?.toLowerCase(),
      ),
      personCountryCode: personDetails['person_country_code'],
      bloodType: json['person_blood_type'],
      personPhone: personDetails['person_phone'],
      personEmail: personDetails['person_email'],
      privileges: null,
    );
  }

  factory AppUser.fromPersistedJson(Map<String, dynamic> json) {
    final userData = json['user'] as Map<String, dynamic>? ?? {};
    final personData = json['person_record'] as Map<String, dynamic>? ?? {};
    final locationData = json['location_record'] as Map<String, dynamic>? ?? {};

    AppUserType? userType;
    final userTypeStr = userData['app_user_type'];
    if (userTypeStr is String) {
      userType = AppUserTypeExtension.fromString(userTypeStr);
    }

    // Persisted shape uses `subscription` and `app_user_wallet`,
    // matching what toJson emits below.
    Subscription? subscription;
    final subJson =
        userData['subscription'] ?? userData['app_user_subscription'];
    if (subJson is Map) {
      subscription = Subscription.fromJson(
        Map<String, dynamic>.from(subJson),
      );
    }

    Wallet? wallet;
    final walletJson = userData['app_user_wallet'] ?? userData['wallet'];
    if (walletJson is Map) {
      wallet = Wallet.fromJson(Map<String, dynamic>.from(walletJson));
    }

    return AppUser(
      idAppUser: _asInt(userData['id_app_user']),
      appUserName: userData['app_user_name'],
      appUserPassword: userData['app_user_password'],
      appUserPersonId: _asInt(userData['app_user_person_id']),
      appUserPreferences:
          _normalizePreferences(userData['app_user_preferences']),
      appUserEmail: userData['app_user_email'],
      appUserImageUrl: userData['app_user_image_url'],
      appUserType: userType,
      appUserSubscriptionRef: _asInt(
        userData['app_user_subscription_id'] ??
            userData['app_user_subscription_ref'],
      ),
      appUserWalletId: _asInt(userData['app_user_wallet_id']),
      appUserLoginOption:
          LoginOption.fromWire(userData['app_user_login_option']),
      verifiedAppUser: VerifiedAppUser.fromWire(userData['verified_app_user']),
      userQuota: _asInt(userData['user_quota']),
      appUserCreation: _parseDate(userData['app_user_creation']),
      appUserLastUpdated: _parseDate(userData['app_user_last_updated']),
      appUserLastActive: _parseDate(userData['app_user_last_active']),
      idPerson: _asInt(personData['id_person']),
      personDetailsId: _asInt(
        personData['person_details_id'] ?? personData['id_person_details'],
      ),
      idPersonDetails: _asInt(personData['id_person_details']),
      personFirstName: personData['person_first_name'],
      personLastName: personData['person_last_name'],
      personBirthDate: personData['person_birth_date'],
      personGender: Gender.fromString(
        (personData['person_gender'] as String?)?.toLowerCase(),
      ),
      personCountryCode: personData['person_country_code'],
      bloodType: personData['blood_type'],
      personPhone: personData['person_phone'],
      personEmail: personData['person_email'],
      idLocation: _asInt(locationData['id_location']),
      locationLatitude: _asDouble(locationData['location_latitude']),
      locationLongitude: _asDouble(locationData['location_longitude']),
      locationName: locationData['location_name'],
      locationAddressId: _asInt(locationData['location_address_id']),
      idAddress: _asInt(locationData['id_address']),
      addressStreet: locationData['address_street'],
      addressCity: locationData['address_city'],
      addressPostalCode: locationData['address_postal_code'],
      addressCountry: locationData['address_country'],
      subscription: subscription,
      wallet: wallet,
      privileges: null,
    );
  }

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
      appUserPersonId: _asInt(userData?['app_user_person_id']),
      appUserPreferences: userData?['app_user_preferences'] ?? "",
      appUserEmail: email,
      appUserImageUrl: appUserImageUrl,
      appUserType: appUserType,
      appUserLoginOption: LoginOption.google,
      personFirstName: personFirstName,
      personLastName: personLastName,
      personGender: Gender.unspecified,
    );
  }

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
      personGender: Gender.unspecified,
    );
  }

  // ==================== toJson ====================

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
        // Emit the wire name the server reads.
        if (appUserSubscriptionRef != null)
          "app_user_subscription_id": appUserSubscriptionRef,
        if (appUserWalletId != null) "app_user_wallet_id": appUserWalletId,
        if (appUserLoginOption != null)
          "app_user_login_option": appUserLoginOption!.wireValue,
        if (verifiedAppUser != null)
          "verified_app_user": verifiedAppUser!.isVerified ? 1 : 0,
        if (userQuota != null) "user_quota": userQuota,
        if (appUserCreation != null)
          "app_user_creation": appUserCreation!.toIso8601String(),
        if (appUserLastUpdated != null)
          "app_user_last_updated": appUserLastUpdated!.toIso8601String(),
        if (appUserLastActive != null)
          "app_user_last_active": appUserLastActive!.toIso8601String(),
        if (subscription != null)
          "app_user_subscription": subscription!.toJson(),
        if (wallet != null) "app_user_wallet": wallet!.toJson(),
      },
      "person_record": {
        "id_person": idPerson,
        "person_details_id": personDetailsId,
        "id_person_details": idPersonDetails,
        "person_first_name": personFirstName,
        "person_last_name": personLastName,
        "person_birth_date": personBirthDate,
        "person_gender": personGender.wireValue,
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

  // ==================== copyWith ====================

  AppUser copyWith({
    int? idAppUser,
    String? appUserName,
    String? appUserPassword,
    int? appUserPersonId,
    String? appUserPreferences,
    String? appUserEmail,
    String? appUserImageUrl,
    AppUserType? appUserType,
    int? appUserSubscriptionRef,
    int? appUserWalletId,
    LoginOption? appUserLoginOption,
    VerifiedAppUser? verifiedAppUser,
    int? userQuota,
    DateTime? appUserCreation,
    DateTime? appUserLastUpdated,
    DateTime? appUserLastActive,
    int? idPerson,
    int? personDetailsId,
    int? idPersonDetails,
    String? personFirstName,
    String? personLastName,
    String? personBirthDate,
    Gender? personGender,
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
    Subscription? subscription,
    Wallet? wallet,
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
      appUserSubscriptionRef:
          appUserSubscriptionRef ?? this.appUserSubscriptionRef,
      appUserWalletId: appUserWalletId ?? this.appUserWalletId,
      appUserLoginOption: appUserLoginOption ?? this.appUserLoginOption,
      verifiedAppUser: verifiedAppUser ?? this.verifiedAppUser,
      userQuota: userQuota ?? this.userQuota,
      appUserCreation: appUserCreation ?? this.appUserCreation,
      appUserLastUpdated: appUserLastUpdated ?? this.appUserLastUpdated,
      appUserLastActive: appUserLastActive ?? this.appUserLastActive,
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
      subscription: subscription ?? this.subscription,
      wallet: wallet ?? this.wallet,
      privileges: privileges ?? this.privileges,
    );
  }

  // ==================== List helpers ====================

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

  // ==================== Display helpers ====================

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
    return 'AppUser(id: $idAppUser, name: $displayName, '
        'type: ${appUserType?.value}, gender: ${personGender.wireValue}, '
        'quota: $userQuota, subscription: $appUserSubscriptionRef, '
        'wallet: $appUserWalletId)';
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

// ==================== Shared parse helpers ====================

/// Parse a WKT `POINT(lng lat)`. Returns `(longitude, latitude)`.
///
/// FIX: the previous inline regex was `POINT\(([0-9.]+)\s+([0-9.]+)\)`,
/// which rejects **negative** coordinates. Every real payload has a
/// negative longitude (Algeria is west of the prime meridian), so the
/// old code silently produced `(0.0, 0.0)` for every user. The
/// corrected pattern accepts an optional leading `-`.
(double, double)? _parseWkt(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final match = RegExp(
    r'POINT\s*\(\s*([-+]?\d+(?:\.\d+)?)\s+([-+]?\d+(?:\.\d+)?)\s*\)',
    caseSensitive: false,
  ).firstMatch(raw.trim());
  if (match == null) return null;
  final lng = double.tryParse(match.group(1)!);
  final lat = double.tryParse(match.group(2)!);
  if (lng == null || lat == null) return null;
  return (lng, lat);
}

/// Preferences arrive as a **double-encoded** JSON string in the
/// sample payload:
///
///   `"\"{\\\"theme\\\": \\\"dark\\\", ...}\""`
///
/// That is: a JSON string containing a JSON string. Decoding once
/// yields `"{...}"`; decoding again yields the actual map. The old
/// code stored the raw string and callers had to decode twice. This
/// helper decodes as many layers as exist and returns a **flat JSON
/// string** — a single decode for the caller.
String? _normalizePreferences(dynamic raw) {
  if (raw == null) return null;
  if (raw is! String) return raw.toString();
  var current = raw;
  for (var i = 0; i < 3; i++) {
    try {
      final decoded = jsonDecode(current);
      if (decoded is String) {
        current = decoded;
        continue;
      }
      if (decoded is Map) {
        return jsonEncode(decoded);
      }
      return current;
    } catch (_) {
      return current;
    }
  }
  return current;
}

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is int) {
    final ms = v > 1000000000000 ? v : v * 1000;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }
  if (v is String) {
    if (v.isEmpty) return null;
    try {
      return DateTime.parse(v);
    } catch (_) {
      return null;
    }
  }
  return null;
}
