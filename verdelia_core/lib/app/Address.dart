import 'dart:convert';

class Address {
  int id_address;
  String address_street;
  String address_city;
  String address_postal_code;
  String address_country;
  String? address_state;
  String? address_building;
  String? address_floor;
  String? address_apartment;
  String? address_landmark;
  String? address_type;
  bool? is_default;
  DateTime? created_at;
  DateTime? updated_at;

  Address({
    this.id_address = 0,
    this.address_street = '',
    this.address_city = '',
    this.address_postal_code = '',
    this.address_country = '',
    this.address_state,
    this.address_building,
    this.address_floor,
    this.address_apartment,
    this.address_landmark,
    this.address_type,
    this.is_default = false,
    this.created_at,
    this.updated_at,
  });

  // Factory constructor from JSON
  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id_address: json['id_address'] as int? ?? 0,
      address_street: json['address_street'] as String? ?? '',
      address_city: json['address_city'] as String? ?? '',
      address_postal_code: json['address_postal_code'] as String? ?? '',
      address_country: json['address_country'] as String? ?? '',
      address_state: json['address_state'] as String?,
      address_building: json['address_building'] as String?,
      address_floor: json['address_floor'] as String?,
      address_apartment: json['address_apartment'] as String?,
      address_landmark: json['address_landmark'] as String?,
      address_type: json['address_type'] as String?,
      is_default: json['is_default'] as bool? ?? false,
      created_at: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updated_at: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  // Factory constructor from Location_API
  factory Address.fromLocationApi(Map<String, dynamic> apiData) {
    return Address(
      id_address: apiData['id_address'] as int? ?? 0,
      address_street: apiData['address_street'] as String? ?? '',
      address_city: apiData['address_city'] as String? ?? '',
      address_postal_code: apiData['address_postal_code'] as String? ?? '',
      address_country: apiData['address_country'] as String? ?? '',
    );
  }

  // Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id_address': id_address,
      'address_street': address_street,
      'address_city': address_city,
      'address_postal_code': address_postal_code,
      'address_country': address_country,
      if (address_state != null) 'address_state': address_state,
      if (address_building != null) 'address_building': address_building,
      if (address_floor != null) 'address_floor': address_floor,
      if (address_apartment != null) 'address_apartment': address_apartment,
      if (address_landmark != null) 'address_landmark': address_landmark,
      if (address_type != null) 'address_type': address_type,
      if (is_default != null) 'is_default': is_default,
      if (created_at != null) 'created_at': created_at!.toIso8601String(),
      if (updated_at != null) 'updated_at': updated_at!.toIso8601String(),
    };
  }

  // Convert to JSON string
  String toJsonString() {
    return json.encode(toJson());
  }

  // Clone method for immutability
  Address copyWith({
    int? id_address,
    String? address_street,
    String? address_city,
    String? address_postal_code,
    String? address_country,
    String? address_state,
    String? address_building,
    String? address_floor,
    String? address_apartment,
    String? address_landmark,
    String? address_type,
    bool? is_default,
    DateTime? created_at,
    DateTime? updated_at,
  }) {
    return Address(
      id_address: id_address ?? this.id_address,
      address_street: address_street ?? this.address_street,
      address_city: address_city ?? this.address_city,
      address_postal_code: address_postal_code ?? this.address_postal_code,
      address_country: address_country ?? this.address_country,
      address_state: address_state ?? this.address_state,
      address_building: address_building ?? this.address_building,
      address_floor: address_floor ?? this.address_floor,
      address_apartment: address_apartment ?? this.address_apartment,
      address_landmark: address_landmark ?? this.address_landmark,
      address_type: address_type ?? this.address_type,
      is_default: is_default ?? this.is_default,
      created_at: created_at ?? this.created_at,
      updated_at: updated_at ?? this.updated_at,
    );
  }

  // Validation methods
  bool get isValid =>
      address_street.isNotEmpty &&
      address_city.isNotEmpty &&
      address_country.isNotEmpty;

  bool get hasFullAddress =>
      address_street.isNotEmpty &&
      address_city.isNotEmpty &&
      address_postal_code.isNotEmpty &&
      address_country.isNotEmpty;

  List<String> validate() {
    final errors = <String>[];

    if (address_street.isEmpty) {
      errors.add('Street address is required');
    }

    if (address_city.isEmpty) {
      errors.add('City is required');
    }

    if (address_country.isEmpty) {
      errors.add('Country is required');
    }

    return errors;
  }

  // Format methods for display
  String get formattedSingleLine {
    final parts = <String>[];

    if (address_street.isNotEmpty) parts.add(address_street);
    if (address_city.isNotEmpty) parts.add(address_city);
    if (address_state?.isNotEmpty == true) parts.add(address_state!);
    if (address_postal_code.isNotEmpty) parts.add(address_postal_code);
    if (address_country.isNotEmpty) parts.add(address_country);

    return parts.join(', ');
  }

  String get formattedMultiLine {
    final lines = <String>[];

    if (address_street.isNotEmpty) lines.add(address_street);

    final cityLine = <String>[];
    if (address_city.isNotEmpty) cityLine.add(address_city);
    if (address_state?.isNotEmpty == true) cityLine.add(address_state!);
    if (address_postal_code.isNotEmpty) cityLine.add(address_postal_code);
    if (cityLine.isNotEmpty) lines.add(cityLine.join(' '));

    if (address_country.isNotEmpty) lines.add(address_country);

    return lines.join('\n');
  }

  String get formattedShort {
    if (address_city.isNotEmpty && address_country.isNotEmpty) {
      return '$address_city, $address_country';
    } else if (address_city.isNotEmpty) {
      return address_city;
    } else if (address_country.isNotEmpty) {
      return address_country;
    }
    return 'Address';
  }

  // Address type helpers
  static const List<String> addressTypes = [
    'home',
    'work',
    'business',
    'shipping',
    'billing',
    'other',
  ];

  static const Map<String, String> addressTypeLabels = {
    'home': 'Home',
    'work': 'Work',
    'business': 'Business',
    'shipping': 'Shipping Address',
    'billing': 'Billing Address',
    'other': 'Other',
  };

  String get typeLabel {
    return addressTypeLabels[address_type] ?? 'Address';
  }

  // Country helpers (you can expand this list)
  static const List<String> commonCountries = [
    'United States',
    'Canada',
    'United Kingdom',
    'France',
    'Germany',
    'Spain',
    'Italy',
    'Australia',
    'Japan',
    'China',
    'India',
    'Brazil',
    'Mexico',
    'United Arab Emirates',
    'Saudi Arabia',
    'Egypt',
    'Morocco',
    'Tunisia',
    'Algeria',
  ];

  // Check if address is empty
  bool get isEmpty =>
      id_address == 0 && address_street.isEmpty && address_city.isEmpty;

  // Check if address is complete for shipping
  bool get isCompleteForShipping =>
      address_street.isNotEmpty &&
      address_city.isNotEmpty &&
      address_postal_code.isNotEmpty &&
      address_country.isNotEmpty;

  // Get address for Google Maps
  String get googleMapsQuery {
    final params = <String>[];

    if (address_street.isNotEmpty) params.add(address_street);
    if (address_city.isNotEmpty) params.add(address_city);
    if (address_state?.isNotEmpty == true) params.add(address_state!);
    if (address_postal_code.isNotEmpty) params.add(address_postal_code);
    if (address_country.isNotEmpty) params.add(address_country);

    return params.join('+').replaceAll(' ', '+');
  }

  // Get address for Apple Maps
  String get appleMapsQuery {
    final params = <String>[];

    if (address_street.isNotEmpty) params.add(address_street);
    if (address_city.isNotEmpty) params.add(address_city);
    if (address_state?.isNotEmpty == true) params.add(address_state!);
    if (address_postal_code.isNotEmpty) params.add(address_postal_code);
    if (address_country.isNotEmpty) params.add(address_country);

    return params.join(', ');
  }

  // Generate a unique key for caching/identification
  String get cacheKey {
    return '${id_address}_${address_street}_${address_city}_${address_country}';
  }

  // Summary for display
  String get summary {
    if (address_street.isNotEmpty && address_city.isNotEmpty) {
      return '$address_street, $address_city';
    } else if (address_street.isNotEmpty) {
      return address_street;
    } else if (address_city.isNotEmpty) {
      return address_city;
    }
    return 'No address';
  }

  @override
  String toString() {
    return 'Address(id: $id_address, $formattedSingleLine)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Address &&
          runtimeType == other.runtimeType &&
          id_address == other.id_address &&
          address_street == other.address_street &&
          address_city == other.address_city &&
          address_postal_code == other.address_postal_code &&
          address_country == other.address_country;

  @override
  int get hashCode =>
      id_address.hashCode ^
      address_street.hashCode ^
      address_city.hashCode ^
      address_postal_code.hashCode ^
      address_country.hashCode;
}

// Extension for list operations
extension AddressListExtensions on List<Address> {
  List<Address> get defaultAddresses =>
      where((address) => address.is_default == true).toList();

  List<Address> get shippingAddresses =>
      where((address) => address.address_type == 'shipping').toList();

  List<Address> get billingAddresses =>
      where((address) => address.address_type == 'billing').toList();

  Address? get defaultAddress {
    final defaults = defaultAddresses;
    return defaults.isNotEmpty ? defaults.first : null;
  }

  Address? findById(int id) {
    try {
      return firstWhere((address) => address.id_address == id);
    } catch (e) {
      return null;
    }
  }

  List<Address> findByCity(String city) => where((address) =>
      address.address_city.toLowerCase().contains(city.toLowerCase())).toList();

  List<Address> findByCountry(String country) => where((address) =>
          address.address_country.toLowerCase().contains(country.toLowerCase()))
      .toList();
}

// Companion Location class (if you need it)
class Location {
  int id_location;
  double? location_latitude;
  double? location_longitude;
  String? location_name;
  int? location_address_id;
  Address? address;

  Location({
    this.id_location = 0,
    this.location_latitude,
    this.location_longitude,
    this.location_name,
    this.location_address_id,
    this.address,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id_location: json['id_location'] as int? ?? 0,
      location_latitude: (json['location_latitude'] as num?)?.toDouble(),
      location_longitude: (json['location_longitude'] as num?)?.toDouble(),
      location_name: json['location_name'] as String?,
      location_address_id: json['location_address_id'] as int?,
      address: json['address'] != null
          ? Address.fromJson(json['address'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_location': id_location,
      if (location_latitude != null) 'location_latitude': location_latitude,
      if (location_longitude != null) 'location_longitude': location_longitude,
      if (location_name != null) 'location_name': location_name,
      if (location_address_id != null)
        'location_address_id': location_address_id,
      if (address != null) 'address': address!.toJson(),
    };
  }

  bool get hasCoordinates =>
      location_latitude != null && location_longitude != null;

  String get coordinatesString {
    if (hasCoordinates) {
      return '${location_latitude!.toStringAsFixed(6)}, ${location_longitude!.toStringAsFixed(6)}';
    }
    return 'No coordinates';
  }
}
