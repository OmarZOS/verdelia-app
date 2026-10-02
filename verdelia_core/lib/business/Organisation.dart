// lib/business/Organisation.dart

import 'NamingContribution.dart';

class Organisation {
  final int id_provider_organisation;
  final String provider_organisation_name;
  final String provider_organisation_desc;

  /// Trilingual name block, when the backend includes it.
  ///
  /// Null for organisations created before the naming layer, or when
  /// the response shape omits the nested `naming_contribution` object.
  /// When present, `nameFor(lang)` resolves to the contribution's
  /// translation; otherwise it falls back to the flat
  /// `provider_organisation_name`.
  final NamingContribution? naming;

  Organisation({
    required this.id_provider_organisation,
    required this.provider_organisation_name,
    required this.provider_organisation_desc,
    this.naming,
  });

  factory Organisation.empty() => Organisation(
        id_provider_organisation: 0,
        provider_organisation_name: "",
        provider_organisation_desc: "",
        naming: null,
      );

  factory Organisation.fromJson(Map<String, dynamic> json) {
    // Parse the naming block when the backend sends one. The response
    // shape nests it under `naming_contribution` inside
    // `product_provider_org` when read via the supplier endpoint, and
    // at the top level when read directly. Accept both.
    final namingJson = json['naming_contribution'];
    final naming =
        namingJson == null ? null : NamingContribution.fromJson(namingJson);

    return Organisation(
      id_provider_organisation: json['idprovider_organisation'] ?? 0,
      provider_organisation_name: json["provider_organisation_name"] ?? "",
      provider_organisation_desc: json["provider_organisation_desc"] ?? "",
      naming: naming,
    );
  }

  /// Return the organisation's name in [lang], falling back to English
  /// and then to the flat field. Returns an empty string when nothing
  /// is set.
  String nameFor(String lang) {
    final resolved = naming?.nameFor(lang) ?? '';
    if (resolved.isNotEmpty) return resolved;
    return provider_organisation_name;
  }

  Map<String, dynamic> toJson() {
    return {
      "organisation": {
        'id_provider_organisation': id_provider_organisation,
        'provider_organisation_desc': provider_organisation_desc,
        'provider_organisation_name': provider_organisation_name,
        // Echo the naming block back when it was present so a save
        // doesn't strip translations the caller didn't touch.
        if (naming != null) 'naming': naming!.toJson(),
      }
    };
  }
}
