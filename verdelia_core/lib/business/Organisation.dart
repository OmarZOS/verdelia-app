// lib/business/Organisation.dart

import 'NamingContribution.dart';

/// A provider organisation.
///
/// ## Read shape (from `provider_organisation` or a nested
/// `product_provider_org` block):
///
/// ```json
/// {
///   "id_provider_organisation": 118,
///   "provider_organisation_name": "VitalCare 093d",
///   "provider_organisation_description": "Leading healthcare...",
///   "provider_organisation_icon_url": null,
///   "provider_organisation_wallet_id": null,
///   "user_id": 5,
///   "verified_organisation": null,
///   "naming": { ...NamingContribution... }
/// }
/// ```
///
/// Note the read-side names: `id_provider_organisation` (with
/// underscore), `provider_organisation_description` (full word),
/// `user_id`, and `naming` (not `naming_contribution`).
///
/// ## Write shape (`ProviderOrganisation_API`)
///
/// The API model uses **different** field names for the same data:
/// `provider_organisation_desc` (abbreviated), `app_user_id` (not
/// `user_id`), and `naming` (same). See [toApiJson].
class Organisation {
  final int id_provider_organisation;
  final String provider_organisation_name;
  final String provider_organisation_desc;

  /// Icon URL, when the payload carries one. Null when the org has
  /// no image or the payload didn't include the field.
  final String? provider_organisation_icon_url;

  /// FK to the org's wallet, when one has been provisioned.
  final int? provider_organisation_wallet_id;

  /// FK to the owning `app_user` row. Null for system-seeded orgs.
  final int? user_id;

  /// Verification flag from the backend.
  final bool? verified_organisation;

  /// Trilingual name block. Populates from the payload's `naming`
  /// field.
  final NamingContribution? naming;

  Organisation({
    required this.id_provider_organisation,
    required this.provider_organisation_name,
    required this.provider_organisation_desc,
    this.provider_organisation_icon_url,
    this.provider_organisation_wallet_id,
    this.user_id,
    this.verified_organisation,
    this.naming,
  });

  factory Organisation.empty() => Organisation(
        id_provider_organisation: 0,
        provider_organisation_name: "",
        provider_organisation_desc: "",
        naming: null,
      );

  /// Parse an organisation from **either** the read shape (with
  /// `provider_organisation_description`, `user_id`, `naming`) or
  /// the write shape (with `provider_organisation_desc`,
  /// `app_user_id`, `naming`). The read shape wins when both are
  /// present.
  factory Organisation.fromJson(Map<String, dynamic> json) {
    // Naming block: read-side uses `naming`; some legacy payloads
    // use `naming_contribution`. Both are the same shape.
    NamingContribution? naming;
    final rawNaming = json['naming'] ?? json['naming_contribution'];
    if (rawNaming is Map) {
      try {
        naming = NamingContribution.fromJson(
          Map<String, dynamic>.from(rawNaming),
        );
      } catch (_) {
        naming = null;
      }
    }

    // ID: read-side is `id_provider_organisation` with underscores;
    // the ORM column on `provider_details` (different table) uses
    // `idprovider_organisation` — accept it as a legacy fallback but
    // prefer the underscored form.
    int readInt(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value is int) return value;
        if (value is num) return value.toInt();
        if (value is String) {
          final parsed = int.tryParse(value);
          if (parsed != null) return parsed;
        }
      }
      return 0;
    }

    int? readIntOrNull(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value is int) return value;
        if (value is num) return value.toInt();
        if (value is String && value.isNotEmpty) {
          return int.tryParse(value);
        }
      }
      return null;
    }

    bool? readBoolOrNull(dynamic value) {
      if (value == null) return null;
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final lower = value.toLowerCase().trim();
        if (lower == 'true' || lower == '1') return true;
        if (lower == 'false' || lower == '0') return false;
      }
      return null;
    }

    return Organisation(
      id_provider_organisation: readInt(const [
        'id_provider_organisation',
        'idprovider_organisation',
        'id',
      ]),
      provider_organisation_name:
          (json['provider_organisation_name'] as String?) ?? "",
      provider_organisation_desc: (json['provider_organisation_description'] ??
          json['provider_organisation_desc'] ??
          '') as String,
      provider_organisation_icon_url:
          (json['provider_organisation_icon_url'] as String?)?.isEmpty == true
              ? null
              : json['provider_organisation_icon_url'] as String?,
      provider_organisation_wallet_id: readIntOrNull(
        const ['provider_organisation_wallet_id'],
      ),
      user_id: readIntOrNull(const ['user_id', 'app_user_id']),
      verified_organisation: readBoolOrNull(json['verified_organisation']),
      naming: naming,
    );
  }

  /// The organisation's name in [lang], falling back to English, then
  /// to the flat field.
  String nameFor(String lang) {
    final resolved = naming?.nameFor(lang) ?? '';
    if (resolved.isNotEmpty) return resolved;
    return provider_organisation_name;
  }

  /// Icon URL preferring the naming block, falling back to the flat
  /// top-level icon.
  String? get resolvedIconUrl {
    final fromNaming = naming?.iconUrl;
    if (fromNaming != null && fromNaming.isNotEmpty) return fromNaming;
    return provider_organisation_icon_url;
  }

  /// Serialises the organisation for **local persistence**. Round-trips
  /// with [Organisation.fromJson] because both sides use the read-side
  /// field names.
  ///
  /// Do **not** send this to the API — the write contract is
  /// [toApiJson] (as the `organisation` key of the create/update
  /// body). See `Body_create_organisation_api_v1_organisations_post`.
  Map<String, dynamic> toJson() {
    return {
      'id_provider_organisation': id_provider_organisation,
      'provider_organisation_name': provider_organisation_name,
      'provider_organisation_description': provider_organisation_desc,
      if (provider_organisation_icon_url != null)
        'provider_organisation_icon_url': provider_organisation_icon_url,
      if (provider_organisation_wallet_id != null)
        'provider_organisation_wallet_id': provider_organisation_wallet_id,
      if (user_id != null) 'user_id': user_id,
      if (verified_organisation != null)
        'verified_organisation': verified_organisation,
      if (naming != null) 'naming': naming!.toJson(),
    };
  }

  /// The `ProviderOrganisation_API` field subset.
  ///
  /// The write model uses **different** field names than the read
  /// payload:
  ///
  /// | Read payload                         | Write model                       |
  /// |--------------------------------------|-----------------------------------|
  /// | `provider_organisation_description`  | `provider_organisation_desc`      |
  /// | `user_id`                            | `app_user_id`                     |
  /// | `naming`                             | `naming` (same)                   |
  ///
  /// Server-owned columns (`id_provider_organisation`, wallet FK,
  /// verification flag, timestamps) are not sent.
  Map<String, dynamic> toApiJson() {
    return {
      if (id_provider_organisation > 0)
        'id_provider_organisation': id_provider_organisation,
      'provider_organisation_name': provider_organisation_name,
      'provider_organisation_desc': provider_organisation_desc,
      if (user_id != null) 'app_user_id': user_id,
      if (naming != null) 'naming': naming!.toJson(),
    };
  }

  /// Full body for `POST /api/v1/organisations`.
  ///
  /// Wraps [toApiJson] under the `organisation` key that the router
  /// expects (`Body_create_organisation_api_v1_organisations_post`).
  Map<String, dynamic> toCreateJson({
    Map<String, dynamic>? orgImage,
  }) {
    return {
      'organisation': toApiJson(),
      if (orgImage != null) 'org_image': orgImage,
    };
  }

  Organisation copyWith({
    int? id_provider_organisation,
    String? provider_organisation_name,
    String? provider_organisation_desc,
    String? provider_organisation_icon_url,
    int? provider_organisation_wallet_id,
    int? user_id,
    bool? verified_organisation,
    NamingContribution? naming,
  }) {
    return Organisation(
      id_provider_organisation:
          id_provider_organisation ?? this.id_provider_organisation,
      provider_organisation_name:
          provider_organisation_name ?? this.provider_organisation_name,
      provider_organisation_desc:
          provider_organisation_desc ?? this.provider_organisation_desc,
      provider_organisation_icon_url:
          provider_organisation_icon_url ?? this.provider_organisation_icon_url,
      provider_organisation_wallet_id: provider_organisation_wallet_id ??
          this.provider_organisation_wallet_id,
      user_id: user_id ?? this.user_id,
      verified_organisation:
          verified_organisation ?? this.verified_organisation,
      naming: naming ?? this.naming,
    );
  }

  @override
  String toString() {
    return 'Organisation(id: $id_provider_organisation, '
        'name: "$provider_organisation_name", '
        'naming: ${naming != null})';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Organisation &&
          runtimeType == other.runtimeType &&
          id_provider_organisation == other.id_provider_organisation;

  @override
  int get hashCode => id_provider_organisation.hashCode;
}
