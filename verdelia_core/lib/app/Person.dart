import 'dart:developer';

/// Canonical gender values for a person.
///
/// Serialization is lowercase (`'male'`, `'female'`, `'other'`,
/// `'unspecified'`) to match the backend enum. The API is tolerant of
/// mixed case on input; parsing normalizes.
enum Gender {
  male,
  female,
  other,
  unspecified;

  String get wireValue => name;

  String get label {
    switch (this) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.other:
        return 'Other';
      case Gender.unspecified:
        return 'Unspecified';
    }
  }

  String get icon {
    switch (this) {
      case Gender.male:
        return '♂';
      case Gender.female:
        return '♀';
      default:
        return '?';
    }
  }

  static Gender fromString(String? raw) {
    if (raw == null) return Gender.unspecified;
    final v = raw.trim().toLowerCase();
    if (v.isEmpty) return Gender.unspecified;

    switch (v) {
      case 'male':
      case 'm':
      case 'man':
      case 'homme':
        return Gender.male;
      case 'female':
      case 'f':
      case 'woman':
      case 'femme':
        return Gender.female;
      case 'other':
      case 'o':
      case 'autre':
        return Gender.other;
      case 'unspecified':
      case 'unknown':
      case 'n/a':
      case '-':
        return Gender.unspecified;
      default:
        return Gender.unspecified;
    }
  }

  bool get isKnown => this != Gender.unspecified;
}

/// Document type carried on `person_details.person_id_type`.
///
/// Mirrors the DB enum. Null when the backend hasn't recorded a
/// document type — distinct from the empty state at the type level.
enum PersonIdType {
  passport,
  nationalId,
  drivingLicense;

  /// Wire value as stored in the DB. The DB enum uses snake_case for
  /// `National_ID` and `driving_license` — parsing is tolerant of
  /// casing and separator variants.
  String get wireValue {
    switch (this) {
      case PersonIdType.passport:
        return 'Passport';
      case PersonIdType.nationalId:
        return 'National_ID';
      case PersonIdType.drivingLicense:
        return 'driving_license';
    }
  }

  static PersonIdType? fromWire(dynamic raw) {
    if (raw is! String) return null;
    final v =
        raw.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    switch (v) {
      case 'passport':
        return PersonIdType.passport;
      case 'national_id':
      case 'nationalid':
        return PersonIdType.nationalId;
      case 'driving_license':
      case 'drivinglicense':
      case 'driver_license':
        return PersonIdType.drivingLicense;
      default:
        return null;
    }
  }
}

/// Document kind carried on `person_details.person_details_ID_document`.
///
/// Distinct from [PersonIdType] — this is the actual document the user
/// uploaded for KYC, while `person_id_type` is the type recorded on
/// the identity. They often match but are stored separately.
enum PersonIdDocument {
  passport,
  id,
  drivingLicense;

  String get wireValue {
    switch (this) {
      case PersonIdDocument.passport:
        return 'passport';
      case PersonIdDocument.id:
        return 'ID';
      case PersonIdDocument.drivingLicense:
        return 'driving_license';
    }
  }

  static PersonIdDocument? fromWire(dynamic raw) {
    if (raw is! String) return null;
    final v =
        raw.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    switch (v) {
      case 'passport':
        return PersonIdDocument.passport;
      case 'id':
      case 'national_id':
        return PersonIdDocument.id;
      case 'driving_license':
      case 'driver_license':
        return PersonIdDocument.drivingLicense;
      default:
        return null;
    }
  }
}

// ==================== Person ====================

class Person {
  final int id_person;
  final int person_details_id;
  final String? person_blood_type;
  final int? person_location_id;
  final int? doctor_id;
  final PersonDetails person_details;
  final DateTime? created_at;
  final DateTime? updated_at;

  const Person({
    required this.id_person,
    required this.person_details_id,
    this.person_blood_type,
    this.person_location_id,
    this.doctor_id,
    required this.person_details,
    this.created_at,
    this.updated_at,
  });

  String get fullName =>
      '${person_details.person_first_name} ${person_details.person_last_name}'
          .trim();

  String? get firstName => person_details.person_first_name;
  String? get lastName => person_details.person_last_name;

  Gender get gender => person_details.person_gender;
  String get genderValue => person_details.person_gender.wireValue;

  String? get nationality => person_details.person_country_code;
  DateTime? get birthDate => person_details.person_birth_date;

  int? get age {
    if (person_details.person_birth_date == null) return null;
    final now = DateTime.now();
    int age = now.year - person_details.person_birth_date!.year;
    if (now.month < person_details.person_birth_date!.month ||
        (now.month == person_details.person_birth_date!.month &&
            now.day < person_details.person_birth_date!.day)) {
      age--;
    }
    return age;
  }

  bool get isAdult {
    final currentAge = age;
    return currentAge != null && currentAge >= 18;
  }

  // ==================== New convenience accessors ====================

  /// True when the person record carries a verified flag from the
  /// backend. Null (never verified) → false.
  bool get isVerified => person_details.verified_person_details == true;

  String? get phone => person_details.person_phone;
  String? get email => person_details.person_email;

  /// True when a national ID number is on file.
  bool get hasIdNumber =>
      (person_details.person_id_number ?? '').trim().isNotEmpty;

  /// True when a job title or job ref is on file.
  bool get hasJob =>
      (person_details.person_job_title ?? '').trim().isNotEmpty ||
      person_details.person_job_ref != null;

  factory Person.fromJson(Map<String, dynamic> json) {
    try {
      Map<String, dynamic> detailsJson;

      if (json['person_details'] is Map<String, dynamic>) {
        detailsJson = json['person_details'] as Map<String, dynamic>;
      } else {
        detailsJson = json;
      }

      String? bloodType = json['person_blood_type'] as String?;
      if (bloodType == null && detailsJson['person_blood_type'] != null) {
        bloodType = detailsJson['person_blood_type'] as String?;
      }

      int? locationId = (json['person_location_id'] as num?)?.toInt();
      if (locationId == null && detailsJson['person_location_id'] != null) {
        locationId = (detailsJson['person_location_id'] as num?)?.toInt();
      }

      int? doctorId = (json['doctor_id'] as num?)?.toInt();
      if (doctorId == null && detailsJson['doctor_id'] != null) {
        doctorId = (detailsJson['doctor_id'] as num?)?.toInt();
      }

      int detailsId = (json['person_details_id'] as num?)?.toInt() ?? 0;
      if (detailsId == 0 && detailsJson['person_details_id'] != null) {
        detailsId = (detailsJson['person_details_id'] as num?)?.toInt() ?? 0;
      }

      int idPerson = (json['id_person'] as num?)?.toInt() ?? 0;
      if (idPerson == 0 && detailsJson['id_person'] != null) {
        idPerson = (detailsJson['id_person'] as num?)?.toInt() ?? 0;
      }

      return Person(
        id_person: idPerson,
        person_details_id: detailsId,
        person_blood_type: bloodType,
        person_location_id: locationId,
        doctor_id: doctorId,
        person_details: PersonDetails.fromJson(detailsJson),
        created_at: _parseDate(json['created_at']) ??
            _parseDate(detailsJson['created_at']),
        updated_at: _parseDate(json['updated_at']) ??
            _parseDate(detailsJson['updated_at']),
      );
    } catch (e, stackTrace) {
      log('Error parsing Person from JSON: $e',
          name: 'Person', error: e, stackTrace: stackTrace);
      log('JSON: $json', name: 'Person');
      return Person.empty();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id_person': id_person,
      'person_details_id': person_details_id,
      'person_blood_type': person_blood_type,
      'person_location_id': person_location_id,
      if (doctor_id != null) 'doctor_id': doctor_id,
      'person_details': person_details.toJson(),
      if (created_at != null) 'created_at': created_at!.toIso8601String(),
      if (updated_at != null) 'updated_at': updated_at!.toIso8601String(),
    };
  }

  Person copyWith({
    int? id_person,
    int? person_details_id,
    String? person_blood_type,
    int? person_location_id,
    int? doctor_id,
    PersonDetails? person_details,
    DateTime? created_at,
    DateTime? updated_at,
  }) {
    return Person(
      id_person: id_person ?? this.id_person,
      person_details_id: person_details_id ?? this.person_details_id,
      person_blood_type: person_blood_type ?? this.person_blood_type,
      person_location_id: person_location_id ?? this.person_location_id,
      doctor_id: doctor_id ?? this.doctor_id,
      person_details: person_details ?? this.person_details,
      created_at: created_at ?? this.created_at,
      updated_at: updated_at ?? this.updated_at,
    );
  }

  factory Person.empty() {
    return Person(
      id_person: 0,
      person_details_id: 0,
      person_blood_type: null,
      person_location_id: null,
      doctor_id: null,
      person_details: PersonDetails.empty(),
      created_at: null,
      updated_at: null,
    );
  }

  bool get isEmpty => id_person == 0;
  bool get hasBasicInfo => person_details.hasName;

  String get displayName {
    if (hasBasicInfo) return fullName;
    return 'Unknown Person #$id_person';
  }

  String get initials {
    if (!hasBasicInfo) return '?';
    final firstInitial = person_details.person_first_name.isNotEmpty
        ? person_details.person_first_name[0]
        : '';
    final lastInitial = person_details.person_last_name.isNotEmpty
        ? person_details.person_last_name[0]
        : '';
    return (firstInitial + lastInitial).toUpperCase();
  }

  String get genderIcon => person_details.person_gender.icon;

  String? get formattedBirthDate {
    if (person_details.person_birth_date == null) return null;
    return '${person_details.person_birth_date!.day}/${person_details.person_birth_date!.month}/${person_details.person_birth_date!.year}';
  }

  @override
  String toString() {
    return 'Person(id_person: $id_person, name: "$fullName", '
        'gender: ${gender.wireValue}, nationality: $nationality)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Person && other.id_person == id_person;
  }

  @override
  int get hashCode => id_person.hashCode;
}

// ==================== PersonDetails ====================

class PersonDetails {
  final int id_person_details;
  final String person_last_name;
  final String person_first_name;
  final DateTime? person_birth_date;
  final Gender person_gender;
  final String person_country_code;

  // ---- Contact (existing) ----
  final String? person_email;
  final String? person_phone;

  // ---- Contact (new: person_languages) ----
  /// Comma-separated language codes as stored on the DB column
  /// (`String(100)`). Parse with [languageList] to get a typed list.
  final String? person_languages;

  // ---- Address (legacy flattened fields) ----
  final String? person_address;
  final String? person_city;
  final String? person_postal_code;
  final String? person_country;
  final String? person_notes;

  // ---- Identity (new) ----
  /// Identity document number. DB column: `person_id_number`.
  final String? person_id_number;

  /// Type of the identity document. DB enum on `person_id_type`.
  final PersonIdType? person_id_type;

  /// Expiry of the identity document.
  final DateTime? person_id_expiry;

  /// National number, distinct from the ID number.
  final String? person_national_number;

  /// Reference string for the national ID record.
  final String? person_national_ID_reference;

  /// Which physical document was uploaded for KYC.
  final PersonIdDocument? person_details_ID_document;

  // ---- Employment (new) ----
  final String? person_job_title;

  /// FK to `staff_role.id_staff_role`. Null when the person has no
  /// role assigned yet.
  final int? person_job_ref;

  // ---- Verification (new) ----
  /// Backend verification flag for the person record.
  /// True → verified, false → rejected/unverified, null → not run.
  final bool? verified_person_details;

  // ---- Timestamps ----
  final DateTime? created_at;
  final DateTime? updated_at;

  const PersonDetails({
    required this.id_person_details,
    required this.person_last_name,
    required this.person_first_name,
    this.person_birth_date,
    required this.person_gender,
    required this.person_country_code,
    this.person_email,
    this.person_phone,
    this.person_languages,
    this.person_address,
    this.person_city,
    this.person_postal_code,
    this.person_country,
    this.person_notes,
    this.person_id_number,
    this.person_id_type,
    this.person_id_expiry,
    this.person_national_number,
    this.person_national_ID_reference,
    this.person_details_ID_document,
    this.person_job_title,
    this.person_job_ref,
    this.verified_person_details,
    this.created_at,
    this.updated_at,
  });

  bool get hasName =>
      person_first_name.isNotEmpty || person_last_name.isNotEmpty;

  String get fullName => '$person_first_name $person_last_name'.trim();
  String? get person_nationality => person_country_code;

  // ==================== Convenience getters ====================

  /// True when the backend reports this person as verified.
  bool get isVerified => verified_person_details == true;

  /// True when the backend has reported a verification state at all
  /// (verified or rejected) — distinct from "not run".
  bool get hasVerificationStatus => verified_person_details != null;

  /// True when an identity document number is on file.
  bool get hasIdDocument =>
      (person_id_number ?? '').trim().isNotEmpty || person_id_type != null;

  /// True when the identity document is expired at the time of
  /// reading.
  bool get isIdExpired {
    final exp = person_id_expiry;
    if (exp == null) return false;
    return exp.isBefore(DateTime.now());
  }

  /// True when an identity document is on file and hasn't expired.
  bool get hasValidIdDocument => hasIdDocument && !isIdExpired;

  /// Days until the identity document expires. Null when no expiry is
  /// recorded. Negative values indicate an already-expired document.
  int? get idDaysRemaining {
    final exp = person_id_expiry;
    if (exp == null) return null;
    return exp.difference(DateTime.now()).inDays;
  }

  /// Split `person_languages` on commas into a trimmed list. Empty
  /// when the field is null or blank.
  List<String> get languageList {
    final raw = person_languages;
    if (raw == null) return const [];
    return raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
  }

  String? get formattedPhone {
    if (person_phone == null || person_phone!.isEmpty) return null;
    if (person_phone!.length == 10) {
      return '${person_phone!.substring(0, 4)}-${person_phone!.substring(4, 7)}-${person_phone!.substring(7)}';
    }
    return person_phone;
  }

  String? get addressLine {
    if (person_address == null &&
        person_city == null &&
        person_country == null) {
      return null;
    }
    final parts = <String>[];
    if (person_address != null) parts.add(person_address!);
    if (person_city != null) parts.add(person_city!);
    if (person_country != null) parts.add(person_country!);
    return parts.join(', ');
  }

  factory PersonDetails.fromJson(Map<String, dynamic> json) {
    return PersonDetails(
      id_person_details: (json['id_person_details'] as num?)?.toInt() ?? 0,
      person_last_name: json['person_last_name'] as String? ?? '',
      person_first_name: json['person_first_name'] as String? ?? '',
      person_birth_date: _parseDate(json['person_birth_date']),
      person_gender: Gender.fromString(json['person_gender'] as String?),
      person_country_code: json['person_country_code'] as String? ?? '',
      person_email: json['person_email'] as String?,
      person_phone: json['person_phone'] as String?,
      person_languages: json['person_languages'] as String?,
      person_address: json['person_address'] as String?,
      person_city: json['person_city'] as String?,
      person_postal_code: json['person_postal_code'] as String?,
      person_country: json['person_country'] as String?,
      person_notes: json['person_notes'] as String?,
      person_id_number: json['person_id_number'] as String?,
      person_id_type: PersonIdType.fromWire(json['person_id_type']),
      person_id_expiry: _parseDate(json['person_id_expiry']),
      person_national_number: json['person_national_number'] as String?,
      person_national_ID_reference:
          json['person_national_ID_reference'] as String?,
      person_details_ID_document:
          PersonIdDocument.fromWire(json['person_details_ID_document']),
      person_job_title: json['person_job_title'] as String?,
      person_job_ref: (json['person_job_ref'] as num?)?.toInt(),
      verified_person_details: _asBool(json['verified_person_details']),
      created_at: _parseDate(json['person_created_at']) ??
          _parseDate(json['created_at']),
      updated_at: _parseDate(json['person_updated_at']) ??
          _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_person_details': id_person_details,
      'person_last_name': person_last_name,
      'person_first_name': person_first_name,
      'person_birth_date': person_birth_date?.toIso8601String(),
      'person_gender': person_gender.wireValue,
      'person_country_code': person_country_code,
      'person_email': person_email,
      'person_phone': person_phone,
      'person_languages': person_languages,
      'person_address': person_address,
      'person_city': person_city,
      'person_postal_code': person_postal_code,
      'person_country': person_country,
      'person_notes': person_notes,
      'person_id_number': person_id_number,
      if (person_id_type != null) 'person_id_type': person_id_type!.wireValue,
      'person_id_expiry': person_id_expiry?.toIso8601String(),
      'person_national_number': person_national_number,
      'person_national_ID_reference': person_national_ID_reference,
      if (person_details_ID_document != null)
        'person_details_ID_document': person_details_ID_document!.wireValue,
      'person_job_title': person_job_title,
      if (person_job_ref != null) 'person_job_ref': person_job_ref,
      if (verified_person_details != null)
        'verified_person_details': verified_person_details! ? 1 : 0,
      if (created_at != null)
        'person_created_at': created_at!.toIso8601String(),
      if (updated_at != null)
        'person_updated_at': updated_at!.toIso8601String(),
    };
  }

  PersonDetails copyWith({
    int? id_person_details,
    String? person_last_name,
    String? person_first_name,
    DateTime? person_birth_date,
    Gender? person_gender,
    String? person_country_code,
    String? person_email,
    String? person_phone,
    String? person_languages,
    String? person_address,
    String? person_city,
    String? person_postal_code,
    String? person_country,
    String? person_notes,
    String? person_id_number,
    PersonIdType? person_id_type,
    DateTime? person_id_expiry,
    String? person_national_number,
    String? person_national_ID_reference,
    PersonIdDocument? person_details_ID_document,
    String? person_job_title,
    int? person_job_ref,
    bool? verified_person_details,
    DateTime? created_at,
    DateTime? updated_at,
  }) {
    return PersonDetails(
      id_person_details: id_person_details ?? this.id_person_details,
      person_last_name: person_last_name ?? this.person_last_name,
      person_first_name: person_first_name ?? this.person_first_name,
      person_birth_date: person_birth_date ?? this.person_birth_date,
      person_gender: person_gender ?? this.person_gender,
      person_country_code: person_country_code ?? this.person_country_code,
      person_email: person_email ?? this.person_email,
      person_phone: person_phone ?? this.person_phone,
      person_languages: person_languages ?? this.person_languages,
      person_address: person_address ?? this.person_address,
      person_city: person_city ?? this.person_city,
      person_postal_code: person_postal_code ?? this.person_postal_code,
      person_country: person_country ?? this.person_country,
      person_notes: person_notes ?? this.person_notes,
      person_id_number: person_id_number ?? this.person_id_number,
      person_id_type: person_id_type ?? this.person_id_type,
      person_id_expiry: person_id_expiry ?? this.person_id_expiry,
      person_national_number:
          person_national_number ?? this.person_national_number,
      person_national_ID_reference:
          person_national_ID_reference ?? this.person_national_ID_reference,
      person_details_ID_document:
          person_details_ID_document ?? this.person_details_ID_document,
      person_job_title: person_job_title ?? this.person_job_title,
      person_job_ref: person_job_ref ?? this.person_job_ref,
      verified_person_details:
          verified_person_details ?? this.verified_person_details,
      created_at: created_at ?? this.created_at,
      updated_at: updated_at ?? this.updated_at,
    );
  }

  factory PersonDetails.empty() {
    return const PersonDetails(
      id_person_details: 0,
      person_last_name: '',
      person_first_name: '',
      person_birth_date: null,
      person_gender: Gender.unspecified,
      person_country_code: '',
      person_email: null,
      person_phone: null,
      person_languages: null,
      person_address: null,
      person_city: null,
      person_postal_code: null,
      person_country: null,
      person_notes: null,
      person_id_number: null,
      person_id_type: null,
      person_id_expiry: null,
      person_national_number: null,
      person_national_ID_reference: null,
      person_details_ID_document: null,
      person_job_title: null,
      person_job_ref: null,
      verified_person_details: null,
      created_at: null,
      updated_at: null,
    );
  }

  @override
  String toString() {
    return 'PersonDetails(id_person_details: $id_person_details, '
        'name: "$fullName", gender: ${person_gender.wireValue}, '
        'email: $person_email, phone: $person_phone, '
        'verified: $verified_person_details)';
  }
}

extension PersonExtensions on Person {
  bool matchesQuery(String query) {
    if (query.isEmpty) return true;
    final searchQuery = query.toLowerCase();
    return fullName.toLowerCase().contains(searchQuery) ||
        person_details.person_email?.toLowerCase().contains(searchQuery) ==
            true ||
        person_details.person_phone?.contains(query) == true ||
        person_details.person_country_code
            .toLowerCase()
            .contains(searchQuery) ||
        person_details.person_gender.wireValue.contains(searchQuery) ||
        // New fields worth searching on.
        (person_details.person_id_number ?? '')
            .toLowerCase()
            .contains(searchQuery) ||
        (person_details.person_national_number ?? '')
            .toLowerCase()
            .contains(searchQuery) ||
        (person_details.person_job_title ?? '')
            .toLowerCase()
            .contains(searchQuery) ||
        person_details.languageList
            .any((l) => l.toLowerCase().contains(searchQuery));
  }
}

class PersonSearchResult {
  final Person person;
  final double score;
  const PersonSearchResult({required this.person, required this.score});
}

// ==================== Parse helpers ====================

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

/// Tolerant bool parse. The backend stores `verified_person_details`
/// as a TINYINT — `0`, `1`, or null. A string `"true"` / `"false"` is
/// also accepted for cases where the field passes through a JSON
/// round-trip.
bool? _asBool(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final lower = v.toLowerCase().trim();
    if (lower == 'true' || lower == '1' || lower == 'yes') return true;
    if (lower == 'false' || lower == '0' || lower == 'no') return false;
  }
  return null;
}
