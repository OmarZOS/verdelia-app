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

// lib/business/finance/Wallet.dart

/// Wallet snapshot, when the backend inlines it on a payload.
///
/// The `app_user` row carries `app_user_wallet_id` as an FK; when the
/// API joins through it, this object is populated. Null when the wallet
/// wasn't inlined — the FK being set doesn't imply the snapshot is
/// present.
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

  // ==================== Status helpers ====================

  bool get isActive => walletStatus == 'active';
  bool get isPendingVerification => walletStatus == 'pending_verification';
  bool get isSuspended => walletStatus == 'suspended';
  bool get isClosed => walletStatus == 'closed';
  bool get isInactive => walletStatus == 'inactive';

  /// True when the wallet can transact — active and not closed.
  bool get canTransact => isActive;

  /// True when the wallet has a positive balance. Display purposes.
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

/// Whether the user's account has been verified by the backend.
///
/// The DB column is a TINYINT (`0`, `1`, or null). Null means the
/// verification flow hasn't been run — distinct from an explicit
/// "unverified" state for UI purposes, so it's modelled as a nullable
/// enum rather than a bool.
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

/// The authentication method the user signed up with.
///
/// Mirrors the DB enum on `app_user.app_user_login_option`. Null when
/// the account was created before the field existed.
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

/// Subscription snapshot, when the backend inlines it on the user
/// payload.
///
/// The `app_user` row carries `app_user_subscription_ref` as an FK;
/// when the API joins through it, this object is populated. Null when
/// the user has no subscription.

class AppUser {
  // ==================== User fields ====================

  final int? idAppUser;
  final String? appUserName;
  final String? appUserPassword;
  final int? appUserPersonId;
  final String? appUserPreferences;
  final String? appUserEmail;
  final String? appUserImageUrl;
  final AppUserType? appUserType;

  /// FK to the user's current subscription. Null for free-tier users.
  final int? appUserSubscriptionRef;

  /// FK to the user's wallet. Null until a wallet has been provisioned.
  final int? appUserWalletId;

  /// How the user authenticates. Null for accounts created before the
  /// field existed.
  final LoginOption? appUserLoginOption;

  /// Verification state. Null when the backend hasn't run the
  /// verification flow yet.
  final VerifiedAppUser? verifiedAppUser;

  /// Local quota mirror. Decremented by the workflow, refreshed on
  /// subscription changes.
  final int? userQuota;

  // ==================== Timestamps ====================

  final DateTime? appUserCreation;
  final DateTime? appUserLastUpdated;
  final DateTime? appUserLastActive;

  // ==================== Person fields ====================

  final int? idPerson;
  final int? personDetailsId;
  final int? idPersonDetails;
  final String? personFirstName;
  final String? personLastName;
  final String? personBirthDate;

  /// Typed gender. Serialized as lowercase via [Gender.wireValue].
  /// Defaults to [Gender.unspecified] when the payload didn't carry a
  /// value.
  final Gender personGender;

  final String? personCountryCode;
  final String? bloodType;
  final String? personPhone;
  final String? personEmail;

  // ==================== Location fields ====================

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

  // ==================== Nested snapshots ====================

  /// Inlined subscription, when the API joins through
  /// `app_user_subscription_ref`. Null otherwise.
  final Subscription? subscription;

  /// Inlined wallet, when the API joins through `app_user_wallet_id`.
  /// Null otherwise — check the FK on [appUserWalletId] to know
  /// whether a wallet exists at all.
  final Wallet? wallet;

  // ==================== Privileges ====================

  final List<ManagementRule>? privileges;

  // ==================== Derived getters ====================

  bool get isAdmin => appUserType == AppUserType.provider;

  /// True when the user has a subscription ref on the user row.
  bool get hasSubscription => appUserSubscriptionRef != null;

  /// True when the subscription is present *and* not expired.
  /// Returns false when the nested snapshot wasn't inlined, even if
  /// `appUserSubscriptionRef` is set — call the subscription endpoint
  /// to check status in that case.
  bool get hasActiveSubscription =>
      subscription != null && subscription!.isActive;

  /// True when the user has a wallet FK on the user row.
  bool get hasWallet => appUserWalletId != null;

  /// True when the wallet snapshot was inlined in this payload. False
  /// when the API didn't join through — fetch it from the wallet
  /// endpoint in that case.
  bool get hasInlinedWallet => wallet != null;

  /// Current wallet balance, or null when the snapshot wasn't inlined.
  /// Zero when the snapshot is present but the balance is genuinely 0.
  double? get walletBalance => wallet?.walletBalance;

  /// Whether the wallet can transact. False when there's no wallet or
  /// the snapshot wasn't inlined.
  bool get isWalletActive => wallet?.isActive ?? false;

  bool get isVerified => verifiedAppUser?.isVerified ?? false;

  int get quota => userQuota ?? 0;

  // ==================== Constructor ====================

  AppUser({
    // User
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
    // Timestamps
    this.appUserCreation,
    this.appUserLastUpdated,
    this.appUserLastActive,
    // Person
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
    // Location
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
    // Nested
    this.subscription,
    this.wallet,
    // Privileges
    this.privileges,
  });

  // ==================== FACTORY METHODS ====================

  /// Main fromJson - handles full AppUser structure
  factory AppUser.fromJson(Map<String, dynamic> json) {
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

    // Nested subscription, when present.
    Subscription? subscription;
    final subJson = json['subscription'];
    if (subJson is Map) {
      subscription = Subscription.fromJson(
        Map<String, dynamic>.from(subJson),
      );
    }

    // Nested wallet, when present. The API nests it under
    // `app_user_wallet`, not `wallet`.
    Wallet? wallet;
    final walletJson = json['app_user_wallet'];
    if (walletJson is Map) {
      wallet = Wallet.fromJson(Map<String, dynamic>.from(walletJson));
    }

    return AppUser(
      // User fields
      idAppUser: _asInt(json['id_app_user']),
      appUserName: json['app_user_name'],
      appUserPassword: json['app_user_password'],
      appUserPersonId: _asInt(json['app_user_person_id']),
      appUserPreferences: json['app_user_preferences'],
      appUserEmail: json['app_user_email'],
      appUserImageUrl: json['app_user_image_url'],
      appUserType: userType,
      appUserSubscriptionRef: _asInt(json['app_user_subscription_ref']),
      appUserWalletId: _asInt(json['app_user_wallet_id']),
      appUserLoginOption: LoginOption.fromWire(json['app_user_login_option']),
      verifiedAppUser: VerifiedAppUser.fromWire(json['verified_app_user']),
      userQuota: _asInt(json['user_quota']),

      // Timestamps
      appUserCreation: _parseDate(json['app_user_creation']),
      appUserLastUpdated: _parseDate(json['app_user_last_updated']),
      appUserLastActive: _parseDate(json['app_user_last_active']),

      // Person fields
      idPerson: _asInt(appUserPerson['id_person']),
      personDetailsId: _asInt(appUserPerson['person_details_id']),
      idPersonDetails: _asInt(personDetails['id_person_details']),
      personFirstName: personDetails['person_first_name'],
      personLastName: personDetails['person_last_name'],
      personBirthDate: personDetails['person_birth_date'],
      personGender:
          Gender.fromString(personDetails['person_gender'] as String?),
      personCountryCode: personDetails['person_country_code'],
      bloodType: appUserPerson['person_blood_type'],
      personPhone: personDetails['person_phone'],
      personEmail: personDetails['person_email'],

      // Location fields
      idLocation: _asInt(personLocation['id_location']),
      locationLatitude: lat,
      locationLongitude: lng,
      locationName: personLocation['location_name'],
      locationAddressId: _asInt(personLocation['location_address_id']),
      idAddress: _asInt(locationAddress['id_address']),
      addressStreet: locationAddress['address_street'],
      addressCity: locationAddress['address_city'],
      addressPostalCode: locationAddress['address_postal_code'],
      addressCountry: locationAddress['address_country'],

      // Nested
      subscription: subscription,
      wallet: wallet,

      privileges: null,
    );
  }

  /// Parse from Person object (search endpoint result)
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

  /// Parse from search endpoint JSON (Person structure with nested person_details)
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
      personGender:
          Gender.fromString(personDetails['person_gender'] as String?),
      personCountryCode: personDetails['person_country_code'],
      bloodType: json['person_blood_type'],
      personPhone: personDetails['person_phone'],
      personEmail: personDetails['person_email'],
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

    Subscription? subscription;
    final subJson = userData['subscription'];
    if (subJson is Map) {
      subscription = Subscription.fromJson(
        Map<String, dynamic>.from(subJson),
      );
    }

    Wallet? wallet;
    final walletJson = userData['app_user_wallet'];
    if (walletJson is Map) {
      wallet = Wallet.fromJson(Map<String, dynamic>.from(walletJson));
    }

    return AppUser(
      idAppUser: _asInt(userData['id_app_user']),
      appUserName: userData['app_user_name'],
      appUserPassword: userData['app_user_password'],
      appUserPersonId: _asInt(userData['app_user_person_id']),
      appUserPreferences: userData['app_user_preferences'],
      appUserEmail: userData['app_user_email'],
      appUserImageUrl: userData['app_user_image_url'],
      appUserType: userType,
      appUserSubscriptionRef: _asInt(userData['app_user_subscription_ref']),
      appUserWalletId: _asInt(userData['app_user_wallet_id']),
      appUserLoginOption:
          LoginOption.fromWire(userData['app_user_login_option']),
      verifiedAppUser: VerifiedAppUser.fromWire(userData['verified_app_user']),
      userQuota: _asInt(userData['user_quota']),
      appUserCreation: _parseDate(userData['app_user_creation']),
      appUserLastUpdated: _parseDate(userData['app_user_last_updated']),
      appUserLastActive: _parseDate(userData['app_user_last_active']),
      idPerson: _asInt(personData['id_person']),
      personDetailsId: _asInt(personData['person_details_id']),
      idPersonDetails: _asInt(personData['id_person_details']),
      personFirstName: personData['person_first_name'],
      personLastName: personData['person_last_name'],
      personBirthDate: personData['person_birth_date'],
      personGender: Gender.fromString(personData['person_gender'] as String?),
      personCountryCode: personData['person_country_code'],
      bloodType: personData['blood_type'],
      personPhone: personData['person_phone'],
      personEmail: personData['person_email'],
      idLocation: _asInt(locationData['id_location']),
      locationLatitude: locationData['location_latitude']?.toDouble(),
      locationLongitude: locationData['location_longitude']?.toDouble(),
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
      personGender: Gender.unspecified,
    );
  }

  // ==================== HELPER METHODS ====================

  static String _buildFullName(String? firstName, String? lastName) {
    final first = firstName ?? '';
    final last = lastName ?? '';
    if (first.isEmpty && last.isEmpty) return 'Unknown';
    if (first.isEmpty) return last;
    if (last.isEmpty) return first;
    return '$first $last';
  }

  // ==================== TO JSON METHODS ====================

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
        // New fields
        if (appUserSubscriptionRef != null)
          "app_user_subscription_ref": appUserSubscriptionRef,
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
        if (subscription != null) "subscription": subscription!.toJson(),
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

  // ==================== COPY WITH ====================

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

  // ==================== LIST HELPERS ====================

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

  // ==================== DISPLAY HELPERS ====================

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

// ==================== Parse helpers ====================

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
