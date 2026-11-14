// lib/business/Supplier.dart

import 'dart:developer' as developer;

import '../app/VerdeliaImage.dart';
import 'NamingContribution.dart';

/// A supplier (a.k.a. product provider) as returned by the API.
///
/// ## Read shape (nested graph from `product_provider`)
///
/// ```json
/// {
///   "id_product_provider": 6,
///   "product_provider_type_id": 6,
///   "product_provider_details_id": 6,
///   "product_provider_wallet_id": 37,
///   "product_provider_location_id": 28,
///   "product_provider_org_id": 118,
///   "product_provider_details": {
///     "provider_name": "MediLab Services 3430",
///     "provider_contact_info": "{...}",
///     "naming_contribution": { ... }
///   },
///   "provider_image": [],
///   "product_provider_location": {
///     "id_location": 28,
///     "position_wkt": "POINT(lng lat)",
///     "location_name": "Office",
///     "location_postal_code": null
///   },
///   "product_provider_org": {
///     "id_provider_organisation": 118,
///     "provider_organisation_name": "VitalCare 093d",
///     "provider_organisation_description": "Leading ...",
///     "user_id": 5,
///     "naming": null
///   },
///   "product_provider_type": {
///     "id_product_provider_type": 6,
///     "product_provider_type_name": "food.dining.juice_bar"
///   }
/// }
/// ```
///
/// ## Write shape (`Body_create_supplier_api_v1_suppliers_post`)
///
/// ```json
/// {
///   "provider": { ...ProductProvider_API... },
///   "location": { ...Location_API... },
///   "image":    { ...ProviderImage_API... }  (optional)
/// }
/// ```
///
/// The `provider` sub-object uses the API field names — most
/// importantly `provider_organisation_desc` (not `_description`) and
/// `id_provider_owner` (not `user_id`).
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
  final String supplierTypeName;
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
  final NamingContribution? naming;
  final NamingContribution? organisationNaming;
  final NamingContribution? supplierTypeNaming;

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
    this.supplierTypeName = '',
    this.supplierTypeNaming,
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
        providerName: '',
        providerContactInfo: '',
        locationLatitude: 0.0,
        locationLongitude: 0.0,
        locationName: '',
        supplierImageUrl: null,
        providerOrganisationName: '',
        providerOrganisationDesc: '',
        addressStreet: '',
        addressCity: '',
        addressPostalCode: '',
        addressCountry: '',
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
    String? supplierTypeName,
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
    NamingContribution? supplierTypeNaming,
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
      supplierTypeName: supplierTypeName ?? this.supplierTypeName,
      supplierTypeNaming: supplierTypeNaming ?? this.supplierTypeNaming,
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
      final locationData = _asMap(json['product_provider_location']);
      final detailsData = _asMap(json['product_provider_details']);
      final orgData = _asMap(json['product_provider_org']);
      final typeData = _asMap(json['product_provider_type']);
      final addressData = _asMap(locationData?['location_address']);

      final coords = _parseWkt(locationData?['position_wkt']);
      final image = _parseFirstImage(json['provider_image']);

      final ownerId = _parseIntOrNull(
        json['product_provider_owner'] ?? orgData?['user_id'],
      );

      return Supplier(
        idProviderDetails: _parseInt(json['product_provider_details_id']),
        idProductProvider: _parseInt(json['id_product_provider']),
        productProviderDetailsId:
            _parseInt(json['product_provider_details_id']),
        providerName: _getString(detailsData?['provider_name']),
        providerContactInfo: _getString(detailsData?['provider_contact_info']),
        productProviderOwnerId: ownerId ?? 0,
        productProviderTypeId: _parseInt(json['product_provider_type_id']),
        supplierTypeName: _getString(typeData?['product_provider_type_name']),
        supplierTypeNaming: _parseNaming(typeData?['naming_contribution']),
        locationLatitude: coords?.$2 ?? 0.0,
        locationLongitude: coords?.$1 ?? 0.0,
        locationName: _getStringOrNull(locationData?['location_name']),
        idLocation: _parseInt(json['product_provider_location_id']),
        idProviderOrganisation: _parseInt(json['product_provider_org_id']),
        providerOrganisationName:
            _getString(orgData?['provider_organisation_name']),
        providerOrganisationDesc: _getString(
          orgData?['provider_organisation_description'] ??
              orgData?['provider_organisation_desc'],
        ),
        locationAddressId: _parseInt(addressData?['id_address']),
        addressStreet: _getString(addressData?['address_street']),
        addressCity: _getString(addressData?['address_city']),
        addressPostalCode: _firstNonEmpty([
          addressData?['address_postal_code'],
          locationData?['location_postal_code'],
        ]),
        addressCountry: _getString(addressData?['address_country']),
        supplierImageUrl: image?.$2,
        supplierImageId: image?.$1,
        naming: _parseNaming(detailsData?['naming_contribution']),
        organisationNaming: _parseNaming(
          orgData?['naming'] ?? orgData?['naming_contribution'],
        ),
      );
    } catch (e, st) {
      _logParseError('Supplier.fromJson', e, st);
      return Supplier.empty();
    }
  }

  factory Supplier.fromSearchJson(Map<String, dynamic> json) {
    try {
      final provider = _resolveProviderMap(json);
      final org = _resolveOrgMap(json, provider);
      final loc = _resolveLocationMap(json, provider);
      final addr = _resolveAddressMap(json, loc);
      final typeData = _resolveTypeMap(json, provider);

      final coords = _parseWkt(loc['position_wkt'] ?? json['position_wkt']);

      final detailsMap = _resolveDetailsMap(json, provider);

      final providerName = _firstNonEmpty([
        json['provider_name'],
        provider['provider_name'],
        detailsMap['provider_name'],
      ], fallback: 'Unknown Supplier');

      final ownerId = _parseIntOrNull(
        provider['product_provider_owner'] ??
            json['product_provider_owner'] ??
            org['user_id'],
      );

      return Supplier(
        idProviderDetails: _parseInt(
          json['idprovider_details_id'] ?? provider['idprovider_details_id'],
        ),
        idProductProvider: _parseInt(
          provider['id_product_provider'] ?? json['id_product_provider'],
        ),
        productProviderDetailsId:
            _parseInt(provider['product_provider_details_id']),
        providerName: providerName,
        providerContactInfo: _firstNonEmpty([
          json['provider_contact_info'],
          provider['provider_contact_info'],
          detailsMap['provider_contact_info'],
        ]),
        productProviderOwnerId: ownerId ?? 0,
        productProviderTypeId: _parseInt(
          provider['product_provider_type_id'] ??
              json['product_provider_type_id'],
        ),
        supplierTypeName: _getString(
          typeData['product_provider_type_name'] ??
              json['product_provider_type_name'],
        ),
        supplierTypeNaming: _parseNaming(typeData['naming_contribution']),
        locationLatitude: coords?.$2 ?? 0.0,
        locationLongitude: coords?.$1 ?? 0.0,
        locationName: _getStringOrNull(loc['location_name']),
        idLocation: _parseInt(loc['id_location']),
        idProviderOrganisation: _parseInt(
          org['idprovider_organisation'] ??
              org['id_provider_organisation'] ??
              json['idprovider_organisation'],
        ),
        providerOrganisationName: _getString(
          org['provider_organisation_name'] ??
              json['provider_organisation_name'],
        ),
        providerOrganisationDesc: _firstNonEmpty([
          org['provider_organisation_description'],
          org['provider_organisation_desc'],
          json['provider_organisation_description'],
          json['provider_organisation_desc'],
        ]),
        locationAddressId: _parseInt(addr['id_address']),
        addressStreet: _getString(addr['address_street']),
        addressCity: _getString(addr['address_city']),
        addressPostalCode: _firstNonEmpty([
          addr['address_postal_code'],
          loc['location_postal_code'],
          json['location_postal_code'],
        ]),
        addressCountry: _getString(addr['address_country']),
        supplierImageUrl: _getStringOrNull(json['supplier_image_url']),
        supplierImageId: _parseIntOrNull(json['supplier_image_id']),
        naming: _parseNaming(detailsMap['naming_contribution']),
        organisationNaming: _parseNaming(
          org['naming'] ??
              org['naming_contribution'] ??
              _asMap(json['product_provider_org'])?['naming_contribution'],
        ),
      );
    } catch (e, st) {
      _logParseError('Supplier.fromSearchJson', e, st);
      return Supplier.empty();
    }
  }

  /// Serialises the supplier for **local persistence**.
  ///
  /// Round-trips with [Supplier.fromJson] because both sides use the
  /// read-side field names (`product_provider_*`, `_description`,
  /// `user_id`). Do **not** send this to the API — the write contract
  /// is [toCreateJson].
  Map<String, dynamic> toJson() {
    return {
      'id_product_provider': idProductProvider,
      'product_provider_details_id': productProviderDetailsId,
      'product_provider_type_id': productProviderTypeId,
      'product_provider_org_id': idProviderOrganisation,
      'product_provider_location_id': idLocation,
      'product_provider_owner': productProviderOwnerId,
      'product_provider_details': {
        'idprovider_details_id': idProviderDetails,
        'provider_name': providerName,
        'provider_contact_info': providerContactInfo,
        if (naming != null) 'naming_contribution': naming!.toJson(),
      },
      'product_provider_location': {
        'id_location': idLocation,
        if (locationLatitude != 0.0 && locationLongitude != 0.0)
          'position_wkt': 'POINT($locationLongitude $locationLatitude)',
        'location_name': locationName,
        'location_postal_code': addressPostalCode,
        'location_address': {
          'id_address': locationAddressId,
          'address_street': addressStreet,
          'address_city': addressCity,
          'address_postal_code': addressPostalCode,
          'address_country': addressCountry,
        },
      },
      'product_provider_org': {
        'id_provider_organisation': idProviderOrganisation,
        'provider_organisation_name': providerOrganisationName,
        'provider_organisation_description': providerOrganisationDesc,
        'user_id': productProviderOwnerId,
        if (organisationNaming != null) 'naming': organisationNaming!.toJson(),
      },
      'product_provider_type': {
        'id_product_provider_type': productProviderTypeId,
        'product_provider_type_name': supplierTypeName,
        if (supplierTypeNaming != null)
          'naming_contribution': supplierTypeNaming!.toJson(),
      },
      if (supplierImageId != null || supplierImageUrl != null)
        'provider_image': [
          {
            'id_provider_image': supplierImageId ?? 0,
            'provider_image_url': supplierImageUrl ?? '',
            'provider_ref_id': idProductProvider,
          }
        ],
    };
  }

  /// The `ProductProvider_API` field subset.
  ///
  /// The write model uses `provider_organisation_desc` (abbreviated)
  /// and `id_provider_owner` (not `user_id`).
  Map<String, dynamic> toProviderApiJson() {
    return {
      'id_product_provider': idProductProvider,
      'id_provider_owner': productProviderOwnerId,
      'idprovider_details_id': productProviderDetailsId,
      'id_product_provider_type': productProviderTypeId,
      'id_provider_organisation': idProviderOrganisation,
      'product_provider_type_desc': supplierTypeName,
      'provider_organisation_name': providerOrganisationName,
      'provider_organisation_desc': providerOrganisationDesc,
      'provider_name': providerName,
      'provider_contact_info': providerContactInfo,
      if (naming != null) 'naming': naming!.toJson(),
    };
  }

  /// The `Location_API` body for the `location` sibling.
  Map<String, dynamic> toLocationApiJson() {
    return {
      'id_location': idLocation,
      if (locationLatitude != 0.0 && locationLongitude != 0.0)
        'location_latitude': locationLatitude,
      if (locationLatitude != 0.0 && locationLongitude != 0.0)
        'location_longitude': locationLongitude,
      'location_name': locationName ?? '',
      'location_address_id': locationAddressId,
      'id_address': locationAddressId,
      'address_street': addressStreet,
      'address_city': addressCity,
      'address_postal_code': addressPostalCode,
      'address_country': addressCountry,
    };
  }

  /// The `ProviderImage_API` body for the `image` sibling, or null
  /// when there is no image to send.
  Map<String, dynamic>? toImageApiJson() {
    if (supplierImageId == null &&
        (supplierImageUrl == null || supplierImageUrl!.isEmpty)) {
      return null;
    }
    return {
      'id_provider_image': supplierImageId ?? 0,
      'provider_image_url': supplierImageUrl ?? '',
      'provider_ref_id': idProductProvider,
    };
  }

  /// Body for `POST /api/v1/suppliers` and `PUT /api/v1/suppliers/{id}`.
  ///
  /// Shape (`Body_create_supplier_api_v1_suppliers_post`):
  ///
  /// ```json
  /// {
  ///   "provider": { ...ProductProvider_API... },
  ///   "location": { ...Location_API... },
  ///   "image":    { ...ProviderImage_API... }  (optional)
  /// }
  /// ```
  Map<String, dynamic> toCreateJson() {
    final image = toImageApiJson();
    return {
      'provider': toProviderApiJson(),
      'location': toLocationApiJson(),
      if (image != null) 'image': image,
    };
  }

  String nameFor(String lang) {
    final resolved = naming?.nameFor(lang) ?? '';
    if (resolved.isNotEmpty) return resolved;
    return providerName;
  }

  String organisationNameFor(String lang) {
    final resolved = organisationNaming?.nameFor(lang) ?? '';
    if (resolved.isNotEmpty) return resolved;
    return providerOrganisationName;
  }

  String supplierTypeNameFor(String lang) {
    final resolved = supplierTypeNaming?.nameFor(lang) ?? '';
    if (resolved.isNotEmpty) return resolved;
    return supplierTypeName;
  }

  bool get hasLocation => locationLatitude != 0.0 && locationLongitude != 0.0;
  bool get hasAddress => addressStreet.isNotEmpty || addressCity.isNotEmpty;

  String get fullAddress {
    final parts = [
      addressStreet,
      addressCity,
      addressPostalCode,
      addressCountry,
    ].where((part) => part.isNotEmpty).toList();
    return parts.join(', ');
  }

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
  String toString() => 'Supplier(id: $idProductProvider, '
      'name: $providerName, hasLocation: $hasLocation)';

  static Map<String, dynamic> _resolveProviderMap(Map<String, dynamic> json) {
    final raw = json['product_provider'];
    if (raw is List && raw.isNotEmpty) {
      final first = raw.first;
      if (first is Map<String, dynamic>) return first;
    }
    if (raw is Map<String, dynamic>) return raw;
    return json;
  }

  static Map<String, dynamic> _resolveOrgMap(
    Map<String, dynamic> json,
    Map<String, dynamic> provider,
  ) {
    final fromProvider = _asMap(provider['product_provider_org']);
    if (fromProvider != null) return fromProvider;
    final fromJson = _asMap(json['product_provider_org']);
    if (fromJson != null) return fromJson;
    return const {};
  }

  static Map<String, dynamic> _resolveLocationMap(
    Map<String, dynamic> json,
    Map<String, dynamic> provider,
  ) {
    final nested = _asMap(provider['product_provider_location']);
    if (nested != null) return nested;
    return {
      'id_location': json['id_location'],
      'position_wkt': json['position_wkt'],
      'location_name': json['location_name'],
      'location_postal_code': json['location_postal_code'],
    };
  }

  static Map<String, dynamic> _resolveAddressMap(
    Map<String, dynamic> json,
    Map<String, dynamic> loc,
  ) {
    final nested = _asMap(loc['location_address']);
    if (nested != null) return nested;
    return {
      'id_address': json['id_address'],
      'address_street': json['address_street'],
      'address_city': json['address_city'],
      'address_postal_code': json['address_postal_code'],
      'address_country': json['address_country'],
    };
  }

  static Map<String, dynamic> _resolveDetailsMap(
    Map<String, dynamic> json,
    Map<String, dynamic> provider,
  ) {
    final fromProvider = _asMap(provider['product_provider_details']);
    if (fromProvider != null) return fromProvider;
    final fromJson = _asMap(json['product_provider_details']);
    if (fromJson != null) return fromJson;
    return json;
  }

  static Map<String, dynamic> _resolveTypeMap(
    Map<String, dynamic> json,
    Map<String, dynamic> provider,
  ) {
    final fromProvider = _asMap(provider['product_provider_type']);
    if (fromProvider != null) return fromProvider;
    final fromJson = _asMap(json['product_provider_type']);
    if (fromJson != null) return fromJson;
    return const {};
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static NamingContribution? _parseNaming(dynamic value) {
    final map = _asMap(value);
    if (map == null) return null;
    return NamingContribution.fromJson(map);
  }

  static (double, double)? _parseWkt(dynamic value) {
    if (value is! String) return null;
    final match =
        RegExp(r'POINT\s*\(\s*([-\d.]+)\s+([-\d.]+)\s*\)', caseSensitive: false)
            .firstMatch(value.trim());
    if (match == null) return null;
    final lng = double.tryParse(match.group(1)!);
    final lat = double.tryParse(match.group(2)!);
    if (lng == null || lat == null) return null;
    return (lng, lat);
  }

  static (int, String)? _parseFirstImage(dynamic images) {
    if (images is! List) return null;
    for (final image in images) {
      final map = _asMap(image);
      if (map == null) continue;
      final id = _parseIntOrNull(map['id_provider_image']);
      final url = _getStringOrNull(map['provider_image_url']);
      if (id != null && url != null && url.isNotEmpty) return (id, url);
    }
    return null;
  }

  static String _firstNonEmpty(
    List<dynamic> candidates, {
    String fallback = '',
  }) {
    for (final candidate in candidates) {
      final value = _getString(candidate);
      if (value.isNotEmpty) return value;
    }
    return fallback;
  }

  static int _parseInt(dynamic value) => _parseIntOrNull(value) ?? 0;

  static int? _parseIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static String _getString(dynamic value) => _getStringOrNull(value) ?? '';

  static String? _getStringOrNull(dynamic value) {
    if (value == null) return null;
    final trimmed = value is String ? value.trim() : value.toString().trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static void _logParseError(
    String where,
    Object error,
    StackTrace stackTrace,
  ) {
    assert(() {
      developer.log(
        'Error in $where: $error\n$stackTrace',
        name: 'Supplier',
      );
      return true;
    }());
  }
}

// ============================================================================
// SupplierCategory
// ============================================================================

class SupplierCategory {
  final int productProviderTypeId;
  final String productCategoryDesc;
  final String? iconUrl;
  final NamingContribution? naming;

  SupplierCategory({
    required this.productProviderTypeId,
    required this.productCategoryDesc,
    this.iconUrl,
    this.naming,
  });

  factory SupplierCategory.empty() => SupplierCategory(
        productProviderTypeId: 0,
        productCategoryDesc: '',
        iconUrl: null,
        naming: null,
      );

  SupplierCategory copyWith({
    int? productProviderTypeId,
    String? productCategoryDesc,
    String? iconUrl,
    NamingContribution? naming,
  }) {
    return SupplierCategory(
      productProviderTypeId:
          productProviderTypeId ?? this.productProviderTypeId,
      productCategoryDesc: productCategoryDesc ?? this.productCategoryDesc,
      iconUrl: iconUrl ?? this.iconUrl,
      naming: naming ?? this.naming,
    );
  }

  factory SupplierCategory.fromJson(Map<String, dynamic> json) {
    try {
      final id = Supplier._parseInt(
        json['id_product_provider_type'] ?? json['product_provider_type_id'],
      );
      final flatName = Supplier._getString(
        json['product_provider_type_name'] ??
            json['product_provider_type_desc'],
      );
      final icon = Supplier._getStringOrNull(
        json['product_provider_type_icon_url'],
      );

      return SupplierCategory(
        productProviderTypeId: id,
        productCategoryDesc: flatName,
        iconUrl: icon,
        naming: Supplier._parseNaming(
          json['naming_contribution'] ?? json['naming'],
        ),
      );
    } catch (_) {
      return SupplierCategory.empty();
    }
  }

  static List<SupplierCategory> listFromJson(dynamic json) {
    if (json is! List) return const [];
    return json
        .whereType<Map>()
        .map((e) => SupplierCategory.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  /// Serialises the category for **local persistence**. Round-trips
  /// with [SupplierCategory.fromJson]. Do not send to the API.
  Map<String, dynamic> toJson() {
    return {
      'id_product_provider_type': productProviderTypeId,
      'product_provider_type_name': productCategoryDesc,
      if (iconUrl != null) 'product_provider_type_icon_url': iconUrl,
      if (naming != null) 'naming_contribution': naming!.toJson(),
    };
  }

  String nameFor(String lang) {
    final resolved = naming?.nameFor(lang) ?? '';
    if (resolved.isNotEmpty) return resolved;
    return productCategoryDesc;
  }

  String? get resolvedIconUrl {
    final fromNaming = naming?.iconUrl;
    if (fromNaming != null && fromNaming.isNotEmpty) return fromNaming;
    return iconUrl;
  }

  String get displayName {
    if (naming?.en.isNotEmpty == true) return naming!.en;
    return productCategoryDesc;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SupplierCategory &&
          runtimeType == other.runtimeType &&
          productProviderTypeId == other.productProviderTypeId;

  @override
  int get hashCode => productProviderTypeId;

  @override
  String toString() => 'SupplierCategory(id: $productProviderTypeId, '
      'name: $productCategoryDesc, naming: ${naming != null})';
}
