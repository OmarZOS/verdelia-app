// customer.dart
import 'dart:convert';

import 'package:verdelia_core/app/AppUser.dart';
import 'package:verdelia_core/app/Person.dart';

/// Unified Customer class that can represent either an AppUser or a Person
class Customer {
  final String customerType; // 'user', 'person', or 'unknown'
  final int customerId;
  final int? personId; // Only for person customers

  // Union type fields - only one will be non-null based on customerType
  final AppUser? _user;
  final Person? _person;

  // Derived properties
  String get id => '$customerType:$customerId';

  String get displayName {
    if (customerType == 'user') {
      if (_user?.personLastName?.isNotEmpty == true) {
        return '${_user?.personFirstName} ${_user?.personLastName}';
      }
      return _user?.appUserName ?? 'User #$customerId';
    }

    if (customerType == 'person') {
      return _person?.fullName ?? 'Person #$customerId';
    }

    return 'Customer #$customerId';
  }

  String? get email {
    return switch (customerType) {
      'user' => _user?.appUserName,
      'person' => _person?.person_details.person_email,
      _ => null,
    };
  }

  String? get phone {
    return switch (customerType) {
      'person' => _person?.person_details.person_phone,
      _ => null,
    };
  }

  String? get address {
    return switch (customerType) {
      'user' => _user?.addressStreet != null && _user!.addressStreet!.isNotEmpty
          ? '${_user!.addressStreet}, ${_user!.addressCity}, ${_user!.addressCountry}'
          : null,
      'person' => _person?.person_details.addressLine,
      _ => null,
    };
  }

  String? get avatarUrl {
    return switch (customerType) {
      'user' => _user?.appUserImageUrl,
      _ => null,
    };
  }

  String get typeDisplayName {
    return switch (customerType) {
      'user' => 'User Account',
      'person' => 'Person',
      _ => 'Unknown',
    };
  }

  DateTime? get createdAt {
    return switch (customerType) {
      'user' => null, // AppUser doesn't have createdAt field
      'person' => _person?.created_at,
      _ => null,
    };
  }

  bool get isUser => customerType == 'user';
  bool get isPerson => customerType == 'person';
  bool get hasAccount => customerType == 'user';

  // Constructor for creating a Customer from either AppUser or Person
  Customer._({
    required this.customerType,
    required this.customerId,
    this.personId,
    AppUser? user,
    Person? person,
  })  : _user = user,
        _person = person {
    // Validate that the correct type is provided
    if (customerType == 'user' && user == null) {
      throw ArgumentError('User must be provided for user customer type');
    }
    if (customerType == 'person' && person == null) {
      throw ArgumentError('Person must be provided for person customer type');
    }
  }

  // Factory constructor from AppUser
  factory Customer.fromUser(AppUser user) {
    return Customer._(
      customerType: 'user',
      customerId: user.idAppUser ?? 0,
      user: user,
    );
  }

  // Factory constructor from Person
  factory Customer.fromPerson(Person person) {
    return Customer._(
      customerType: 'person',
      customerId: person.id_person,
      personId: person.id_person,
      person: person,
    );
  }

  // Factory constructor for unknown customer (just ID and type)
  factory Customer.unknown({
    required String type,
    required int id,
    int? personId,
  }) {
    return Customer._(
      customerType: type,
      customerId: id,
      personId: personId,
    );
  }

  // Factory constructor from FinancialDocument
  factory Customer.fromFinancialDocument({
    required int customerId,
    required String customerType,
    int? personId,
    AppUser? user,
    Person? person,
  }) {
    if (customerType == 'user' && user != null) {
      return Customer.fromUser(user);
    } else if (customerType == 'person' && person != null) {
      return Customer.fromPerson(person);
    } else {
      return Customer.unknown(
        type: customerType,
        id: customerId,
        personId: personId,
      );
    }
  }

  // JSON serialization
  factory Customer.fromJson(Map<String, dynamic> json) {
    final type = json['customer_type'] as String? ?? 'unknown';
    final id = (json['customer_id'] as num?)?.toInt() ?? 0;
    final personId = (json['person_id'] as num?)?.toInt();

    if (type == 'user' && json['user'] != null) {
      return Customer.fromUser(
        AppUser.fromJson(json['user'] as Map<String, dynamic>),
      );
    } else if (type == 'person' && json['person'] != null) {
      return Customer.fromPerson(
        Person.fromJson(json['person'] as Map<String, dynamic>),
      );
    } else {
      return Customer.unknown(
        type: type,
        id: id,
        personId: personId,
      );
    }
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'customer_type': customerType,
      'customer_id': customerId,
      'person_id': personId,
    };

    if (customerType == 'user' && _user != null) {
      json['user'] = _user!.toJson();
    } else if (customerType == 'person' && _person != null) {
      json['person'] = _person!.toJson();
    }

    return json;
  }

  // Convert to FinancialDocument compatible data
  Map<String, dynamic> toFinancialDocumentData() {
    return {
      'customer_id': customerId,
      'customer_type': customerType,
      'customer_person_id': personId ?? 0,
    };
  }

  // Get the underlying object
  T? getObject<T>() {
    if (T == AppUser && customerType == 'user') {
      return _user as T?;
    } else if (T == Person && customerType == 'person') {
      return _person as T?;
    }
    return null;
  }

  // Check if customer matches search query
  bool matchesQuery(String query) {
    if (query.isEmpty) return true;

    final searchQuery = query.toLowerCase();

    return displayName.toLowerCase().contains(searchQuery) ||
        email?.toLowerCase().contains(searchQuery) == true ||
        phone?.contains(query) == true ||
        typeDisplayName.toLowerCase().contains(searchQuery);
  }

  // Copy with method
  Customer copyWith({
    String? customerType,
    int? customerId,
    int? personId,
    AppUser? user,
    Person? person,
  }) {
    return Customer._(
      customerType: customerType ?? this.customerType,
      customerId: customerId ?? this.customerId,
      personId: personId ?? this.personId,
      user: user ?? _user,
      person: person ?? _person,
    );
  }

  // Merge with another customer (useful for updating)
  Customer mergeWith(Customer other) {
    if (other.customerType != customerType || other.customerId != customerId) {
      return this; // Can't merge different customers
    }

    return copyWith(
      personId: other.personId ?? personId,
      user: other._user ?? _user,
      person: other._person ?? _person,
    );
  }

  // Check equality
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Customer &&
        other.customerType == customerType &&
        other.customerId == customerId &&
        other.personId == personId;
  }

  @override
  int get hashCode => Object.hash(customerType, customerId, personId);

  @override
  String toString() {
    return 'Customer(type: $customerType, id: $customerId, name: "$displayName")';
  }
}
