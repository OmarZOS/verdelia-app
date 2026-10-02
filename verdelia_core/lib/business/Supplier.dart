// lib/business/Supplier.dart

import 'package:verdelia_core/app/VerdeliaImage.dart';
import 'package:verdelia_core/business/NamingContribution.dart';
import 'package:verdelia_core/business/iProduct.dart' show NamingContribution;

class Supplier {
  final int idProviderDetails;
  final int idProductProvider;
  final int productProviderDetailsId;
  final int productProviderOwnerId;
  final int locationAddressId;
  final int idLocation;
  final String providerName;
  final String providerContactInfo;
  final int productProviderTypeId;
  final String addressStreet;
  final String addressCity;
  final String addressPostalCode;
  final String addressCountry;

  final int idProviderOrganisation;
  final String providerOrganisationName;
  final String providerOrganisationDesc;

  final double locationLatitude;
  final double locationLongitude;
  final String? locationName;
  final String? supplierImageUrl;
  final int? supplierImageId;

  final VerdeliaImage? supplierImage;

  /// Trilingual provider name from
  /// `product_provider_details.naming_contribution`. Null when the
  /// backend didn't include it (older rows, or a flattened search
  /// projection).
  ///
  /// The FK lives on the details row in the schema, not on the
  /// provider — that's why this is parsed from
  /// `product_provider_details` and not from the top level.
  final NamingContribution? naming;

  /// Trilingual organisation name from
  /// `product_provider_org.naming_contribution`. Null when the org
  /// block is missing or carries no naming.
  final NamingContribution? organisationNaming;

  Supplier({
    required this.idProviderDetails,
    required this.idProductProvider,
    required this.productProviderDetailsId,
    required this.providerName,
    required this.providerContactInfo,
    required this.locationLatitude,
    required this.locationLongitude,
    required this.locationName,
    required this.idLocation,
    required this.productProviderOwnerId,
    required this.productProviderTypeId,
    this.supplierImageUrl,
    this.supplierImageId,
    required this.idProviderOrganisation,
    required this.providerOrganisationName,
    required this.providerOrganisationDesc,
    required this.locationAddressId,
    required this.addressStreet,
    required this.addressCity,
    required this.addressPostalCode,
    required this.addressCountry,
    this.supplierImage,
    this.naming,
    this.organisationNaming,
  });

  factory Supplier.empty() => Supplier(
        idProviderDetails: 0,
        idProductProvider: 0,
        productProviderDetailsId: 0,
        productProviderOwnerId: 0,
        productProviderTypeId: 0,
        supplierImageId: null,
        locationAddressId: 0,
        idLocation: 0,
        idProviderOrganisation: 0,
        providerName: "",
        providerContactInfo: "",
        locationLatitude: 0.0,
        locationLongitude: 0.0,
        locationName: "",
        supplierImageUrl: null,
        providerOrganisationName: "",
        providerOrganisationDesc: "",
        addressStreet: "",
        addressCity: "",
        addressPostalCode: "",
        addressCountry: "",
        naming: null,
        organisationNaming: null,
      );

  Supplier copyWith({
    int? idProviderDetails,
    int? idProductProvider,
    int? productProviderDetailsId,
    int? productProviderOwnerId,
    int? locationAddressId,
    int? idLocation,
    String? providerName,
    String? providerContactInfo,
    int? productProviderTypeId,
    String? addressStreet,
    String? addressCity,
    String? addressPostalCode,
    String? addressCountry,
    int? idProviderOrganisation,
    String? providerOrganisationName,
    String? providerOrganisationDesc,
    double? locationLatitude,
    double? locationLongitude,
    String? locationName,
    String? supplierImageUrl,
    int? supplierImageId,
    VerdeliaImage? supplierImage,
    NamingContribution? naming,
    NamingContribution? organisationNaming,
  }) {
    return Supplier(
      idProviderDetails: idProviderDetails ?? this.idProviderDetails,
      idProductProvider: idProductProvider ?? this.idProductProvider,
      productProviderDetailsId:
          productProviderDetailsId ?? this.productProviderDetailsId,
      providerName: providerName ?? this.providerName,
      providerContactInfo: providerContactInfo ?? this.providerContactInfo,
      locationLatitude: locationLatitude ?? this.locationLatitude,
      locationLongitude: locationLongitude ?? this.locationLongitude,
      locationName: locationName ?? this.locationName,
      idLocation: idLocation ?? this.idLocation,
      productProviderOwnerId:
          productProviderOwnerId ?? this.productProviderOwnerId,
      productProviderTypeId:
          productProviderTypeId ?? this.productProviderTypeId,
      supplierImageUrl: supplierImageUrl ?? this.supplierImageUrl,
      supplierImageId: supplierImageId ?? this.supplierImageId,
      idProviderOrganisation:
          idProviderOrganisation ?? this.idProviderOrganisation,
      providerOrganisationName:
          providerOrganisationName ?? this.providerOrganisationName,
      providerOrganisationDesc:
          providerOrganisationDesc ?? this.providerOrganisationDesc,
      locationAddressId: locationAddressId ?? this.locationAddressId,
      addressStreet: addressStreet ?? this.addressStreet,
      addressCity: addressCity ?? this.addressCity,
      addressPostalCode: addressPostalCode ?? this.addressPostalCode,
      addressCountry: addressCountry ?? this.addressCountry,
      supplierImage: supplierImage ?? this.supplierImage,
      naming: naming ?? this.naming,
      organisationNaming: organisationNaming ?? this.organisationNaming,
    );
  }

  factory Supplier.fromJson(Map<String, dynamic> json) {
    try {
      // Parse coordinates with safety
      double longitude = 0.0;
      double latitude = 0.0;
      String? imageUrl;
      int? imageId;

      // Safely parse WKT coordinates
      final locationData = json["product_provider_location"];
      if (locationData != null && locationData is Map<String, dynamic>) {
        final wkt = locationData["position_wkt"];
        if (wkt != null && wkt is String) {
          final cleaned =
              wkt.replaceAll("POINT(", "").replaceAll(")", "").trim();
          final coords = cleaned.split(RegExp(r'\s+'));
          if (coords.length == 2) {
            longitude = double.tryParse(coords[0]) ?? 0.0;
            latitude = double.tryParse(coords[1]) ?? 0.0;
          }
        }
      }

      // Safely parse image
      final providerImages = json['provider_image'];
      if (providerImages != null && providerImages is List) {
        for (final image in providerImages) {
          if (image is Map<String, dynamic>) {
            final id = image["id_provider_image"];
            final url = image["provider_image_url"];
            if (id != null && url != null && url is String) {
              imageId = id is int ? id : int.tryParse(id.toString());
              imageUrl = url;
              break; // Use the first image
            }
          }
        }
      }

      // Safely parse organisation + its naming contribution
      String organisationName = "";
      String organisationDesc = "";
      NamingContribution? organisationNaming;
      final orgData = json['product_provider_org'];
      if (orgData != null && orgData is Map<String, dynamic>) {
        organisationName =
            (orgData["provider_organisation_name"] ?? "").toString();
        organisationDesc =
            (orgData["provider_organisation_desc"] ?? "").toString();

        final orgNamingJson = orgData['naming_contribution'];
        if (orgNamingJson != null) {
          organisationNaming = NamingContribution.fromJson(orgNamingJson);
        }
      }

      // Safely parse details + its naming contribution.
      // The naming FK lives on the details row, not the provider row.
      final detailsData = json['product_provider_details'];
      String providerName = "";
      String providerContactInfo = "";
      NamingContribution? providerNaming;
      if (detailsData != null && detailsData is Map<String, dynamic>) {
        providerName = (detailsData["provider_name"] ?? "").toString();
        providerContactInfo =
            (detailsData["provider_contact_info"] ?? "").toString();

        final detailsNamingJson = detailsData['naming_contribution'];
        if (detailsNamingJson != null) {
          providerNaming = NamingContribution.fromJson(detailsNamingJson);
        }
      }

      // Safely parse address from location
      int locationAddressId = 0;
      String addressStreet = "";
      String addressCity = "";
      String addressPostalCode = "";
      String addressCountry = "";

      if (locationData != null && locationData is Map<String, dynamic>) {
        final addressData = locationData["location_address"];
        if (addressData != null && addressData is Map<String, dynamic>) {
          locationAddressId = _parseInt(addressData["id_address"]);
          addressStreet = (addressData["address_street"] ?? "").toString();
          addressCity = (addressData["address_city"] ?? "").toString();
          addressPostalCode =
              (addressData["address_postal_code"] ?? "").toString();
          addressCountry = (addressData["address_country"] ?? "").toString();
        }
      }

      // Safely parse location name
      final locationName =
          locationData != null && locationData is Map<String, dynamic>
              ? (locationData['location_name'] ?? "").toString()
              : "";

      return Supplier(
        idProviderDetails: _parseInt(json['product_provider_details_id']),
        idProductProvider: _parseInt(json['id_product_provider']),
        idProviderOrganisation: _parseInt(json['product_provider_org_id']),
        providerOrganisationName: organisationName,
        providerOrganisationDesc: organisationDesc,
        productProviderDetailsId:
            _parseInt(json['product_provider_details_id']),
        providerName: providerName,
        providerContactInfo: providerContactInfo,
        productProviderOwnerId: _parseInt(json['product_provider_owner']),
        locationLatitude: latitude,
        locationLongitude: longitude,
        productProviderTypeId: _parseInt(json['product_provider_type_id']),
        locationAddressId: locationAddressId,
        addressStreet: addressStreet,
        addressCity: addressCity,
        addressPostalCode: addressPostalCode,
        addressCountry: addressCountry,
        locationName: locationName.isNotEmpty ? locationName : null,
        idLocation: _parseInt(json["product_provider_location_id"]),
        supplierImageUrl: imageUrl,
        supplierImageId: imageId,
        naming: providerNaming,
        organisationNaming: organisationNaming,
      );
    } catch (e, stackTrace) {
      // log("Error parsing Supplier: $e\n$stackTrace");
      return Supplier.empty();
    }
  }

  factory Supplier.fromSearchJson(Map<String, dynamic> json) {
    try {
      Map<String, dynamic> provider = {};
      Map<String, dynamic> org = {};
      Map<String, dynamic> loc = {};
      Map<String, dynamic> addr = {};

      // Determine data structure
      if (json['product_provider'] is List &&
          (json['product_provider'] as List).isNotEmpty) {
        final providerList = json['product_provider'] as List;
        provider = providerList.first is Map<String, dynamic>
            ? providerList.first as Map<String, dynamic>
            : {};
      } else if (json['product_provider'] is Map<String, dynamic>) {
        provider = json['product_provider'] as Map<String, dynamic>;
      } else {
        // Use flat structure
        provider = json;
      }

      // Parse organisation
      if (provider['product_provider_org'] is Map<String, dynamic>) {
        org = provider['product_provider_org'] as Map<String, dynamic>;
      } else if (json['product_provider_org'] is Map<String, dynamic>) {
        org = json['product_provider_org'] as Map<String, dynamic>;
      }

      // Parse location
      if (provider['product_provider_location'] is Map<String, dynamic>) {
        loc = provider['product_provider_location'] as Map<String, dynamic>;
      } else {
        // Use flat location fields
        loc = {
          "id_location": json['id_location'],
          "position_wkt": json['position_wkt'],
          "location_name": json['location_name'],
        };
      }

      // Parse address
      if (loc['location_address'] is Map<String, dynamic>) {
        addr = loc['location_address'] as Map<String, dynamic>;
      } else {
        // Use flat address fields
        addr = {
          "id_address": json['id_address'],
          "address_street": json['address_street'],
          "address_city": json['address_city'],
          "address_postal_code": json['address_postal_code'],
          "address_country": json['address_country'],
        };
      }

      // Parse coordinates
      double? latitude;
      double? longitude;
      final wkt = loc['position_wkt'] ?? json['position_wkt'];
      if (wkt != null && wkt is String) {
        final match =
            RegExp(r'POINT\(([-\d.]+)\s+([-\d.]+)\)').firstMatch(wkt.trim());
        if (match != null) {
          longitude = double.tryParse(match.group(1)!);
          latitude = double.tryParse(match.group(2)!);
        }
      }

      // Resolve the details map — it may be nested under the provider
      // or flattened onto the top-level search row.
      final Map<String, dynamic> detailsMap =
          (provider['product_provider_details'] is Map<String, dynamic>)
              ? provider['product_provider_details'] as Map<String, dynamic>
              : (json['product_provider_details'] is Map<String, dynamic>)
                  ? json['product_provider_details'] as Map<String, dynamic>
                  : json;

      // Get provider name from multiple possible sources
      String providerName = _getString(
        json['provider_name'] ??
            provider['provider_name'] ??
            detailsMap['provider_name'],
      );

      if (providerName.isEmpty) {
        providerName = 'Unknown Supplier';
      }

      // Provider naming — on the details map in every shape.
      NamingContribution? providerNaming;
      final detailsNamingJson = detailsMap['naming_contribution'];
      if (detailsNamingJson != null) {
        providerNaming = NamingContribution.fromJson(detailsNamingJson);
      }

      // Organisation naming — may be nested under the org map or
      // flattened at the top level.
      NamingContribution? organisationNaming;
      final orgNamingJson = org['naming_contribution'] ??
          (json['product_provider_org'] is Map<String, dynamic>
              ? (json['product_provider_org']
                  as Map<String, dynamic>)['naming_contribution']
              : null);
      if (orgNamingJson != null) {
        organisationNaming = NamingContribution.fromJson(orgNamingJson);
      }

      return Supplier(
        idProviderDetails: _parseInt(
          json['idprovider_details_id'] ?? provider['idprovider_details_id'],
        ),
        idProductProvider: _parseInt(
          provider['id_product_provider'] ?? json['id_product_provider'],
        ),
        idProviderOrganisation: _parseInt(
          org['idprovider_organisation'] ?? json['idprovider_organisation'],
        ),
        providerOrganisationName: _getString(
          org['provider_organisation_name'] ??
              json['provider_organisation_name'],
        ),
        providerOrganisationDesc: _getString(org['provider_organisation_desc']),
        productProviderDetailsId:
            _parseInt(provider['product_provider_details_id']),
        providerName: providerName,
        providerContactInfo: _getString(
          json['provider_contact_info'] ??
              provider['provider_contact_info'] ??
              detailsMap['provider_contact_info'],
        ),
        productProviderOwnerId: _parseInt(json['product_provider_owner']),
        locationLatitude: latitude ?? 0.0,
        locationLongitude: longitude ?? 0.0,
        productProviderTypeId: _parseInt(
          provider['product_provider_type_id'] ??
              json['product_provider_type_id'],
        ),
        locationAddressId: _parseInt(addr['id_address']),
        addressStreet: _getString(addr['address_street']),
        addressCity: _getString(addr['address_city']),
        addressPostalCode: _getString(addr['address_postal_code']),
        addressCountry: _getString(addr['address_country']),
        locationName: _getString(loc['location_name']),
        idLocation: _parseInt(loc['id_location']),
        supplierImageUrl: _getString(json['supplier_image_url']),
        supplierImageId: _parseInt(json['supplier_image_id']),
        naming: providerNaming,
        organisationNaming: organisationNaming,
      );
    } catch (e, stackTrace) {
      // log("Error parsing Supplier from search: $e\n$stackTrace");
      return Supplier.empty();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      "provider": {
        'id_product_provider': idProductProvider,
        "id_provider_owner": productProviderOwnerId,
        "idprovider_details_id": productProviderDetailsId,
        'id_product_provider_type': productProviderTypeId,
        'id_provider_organisation': idProviderOrganisation,
        'provider_organisation_desc': providerOrganisationDesc,
        'provider_organisation_name': providerOrganisationName,
        "product_provider_type_desc": "string",
        'provider_name': providerName,
        'provider_contact_info': providerContactInfo,
        // Echo the provider naming block when present so a save doesn't
        // strip translations the caller didn't touch.
        if (naming != null) 'naming': naming!.toJson(),
      },
      "image": {
        "id_provider_image": supplierImageId ?? 0,
        "provider_image_url": supplierImageUrl,
        "provider_ref_id": idProductProvider,
      },
      "location": {
        'id_location': idLocation,
        'location_latitude': locationLatitude,
        'location_longitude': locationLongitude,
        'location_name': locationName ?? "",
        "location_address_id": locationAddressId,
        'id_address': locationAddressId,
        "address_street": addressStreet,
        "address_city": addressCity,
        "address_postal_code": addressPostalCode,
        "address_country": addressCountry,
      },
    };
  }

  // ==================== Naming accessors ====================

  /// Return the provider's name in [lang]. Prefers the trilingual
  /// naming contribution; falls back to the flat `providerName`.
  String nameFor(String lang) {
    final resolved = naming?.nameFor(lang) ?? '';
    if (resolved.isNotEmpty) return resolved;
    return providerName;
  }

  /// Return the organisation's name in [lang]. Same fallback rule.
  String organisationNameFor(String lang) {
    final resolved = organisationNaming?.nameFor(lang) ?? '';
    if (resolved.isNotEmpty) return resolved;
    return providerOrganisationName;
  }

  bool get hasLocation => locationLatitude != 0.0 && locationLongitude != 0.0;

  bool get hasAddress => addressStreet.isNotEmpty || addressCity.isNotEmpty;

  String get fullAddress {
    final parts = [
      addressStreet,
      addressCity,
      addressPostalCode,
      addressCountry
    ].where((part) => part.isNotEmpty).toList();
    return parts.join(', ');
  }

  /// English-preferring display name. Kept for backward compatibility
  /// with callers that don't care about the locale-aware path.
  String get displayName {
    if (organisationNaming?.en.isNotEmpty == true) {
      return organisationNaming!.en;
    }
    if (providerOrganisationName.isNotEmpty) {
      return providerOrganisationName;
    }
    if (naming?.en.isNotEmpty == true) {
      return naming!.en;
    }
    return providerName;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Supplier &&
          runtimeType == other.runtimeType &&
          idProductProvider == other.idProductProvider;

  @override
  int get hashCode => idProductProvider;

  @override
  String toString() {
    return 'Supplier(id: $idProductProvider, name: $providerName, location: $hasLocation)';
  }

  // ==================== Helpers ====================

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is num) return value.toInt();
    return 0;
  }

  static String _getString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    return value.toString().trim();
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    if (value is num) return value.toDouble();
    return 0.0;
  }
}

class SupplierCategory {
  final int productProviderTypeId;
  final String productCategoryDesc;

  SupplierCategory({
    required this.productProviderTypeId,
    required this.productCategoryDesc,
  });

  factory SupplierCategory.fromJson(Map<String, dynamic> json) {
    try {
      return SupplierCategory(
        productProviderTypeId:
            Supplier._parseInt(json['id_product_provider_type']),
        productCategoryDesc:
            Supplier._getString(json['product_provider_type_desc']),
      );
    } catch (e) {
      return SupplierCategory(
        productProviderTypeId: 0,
        productCategoryDesc: "Unknown",
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id_product_provider_type': productProviderTypeId,
      'product_provider_type_desc': productCategoryDesc,
    };
  }
}
