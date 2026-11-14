// customer.dart
import 'dart:convert';

import 'package:verdelia_core/app/AppUser.dart';
import 'package:verdelia_core/app/Person.dart';

/// Unified Customer class that can represent either an AppUser or a Person
class Customer {
  final String customerType; // 'user', 'person', or 'unknown'
  final int customerId;
  final int? personId;

  final AppUser? _user;
  final Person? _person;

  String get id => '$customerType:$customerId';

  String get displayName {
    if (customerType == 'user') {
      final first = _user?.personFirstName;
      final last = _user?.personLastName;
      if ((last?.isNotEmpty ?? false) || (first?.isNotEmpty ?? false)) {
        return '${first ?? ''} ${last ?? ''}'.trim();
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
      'user' => _user?.appUserEmail,
      'person' => _person?.person_details.person_email,
      _ => null,
    };
  }

  String? get phone {
    return switch (customerType) {
      'user' => _user?.personPhone,
      'person' => _person?.person_details.person_phone,
      _ => null,
    };
  }

  String? get address {
    return switch (customerType) {
      'user' =>
        (_user?.addressStreet != null && _user!.addressStreet!.isNotEmpty)
            ? [
                _user!.addressStreet,
                _user!.addressCity,
                _user!.addressCountry,
              ].where((p) => p != null && p.isNotEmpty).join(', ')
            : null,
      'person' => _person?.person_details.addressLine,
      _ => null,
    };
  }

  String? get avatarUrl {
    return switch (customerType) {
      'user' => _user?.appUserImageUrl,
      'person' => null,
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
      'user' => _user?.appUserCreation,
      'person' => _person?.created_at,
      _ => null,
    };
  }

  bool get isUser => customerType == 'user';
  bool get isPerson => customerType == 'person';
  bool get hasAccount => customerType == 'user';

  Customer._({
    required this.customerType,
    required this.customerId,
    this.personId,
    AppUser? user,
    Person? person,
  })  : _user = user,
        _person = person {
    if (customerType == 'user' && user == null) {
      throw ArgumentError('User must be provided for user customer type');
    }
    if (customerType == 'person' && person == null) {
      throw ArgumentError('Person must be provided for person customer type');
    }
  }

  factory Customer.fromUser(AppUser user) {
    return Customer._(
      customerType: 'user',
      customerId: user.idAppUser ?? 0,
      personId: user.idPerson,
      user: user,
    );
  }

  factory Customer.fromPerson(Person person) {
    return Customer._(
      customerType: 'person',
      customerId: person.id_person,
      personId: person.id_person,
      person: person,
    );
  }

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

  /// Parse a customer from the wire payload.
  ///
  /// The user half is nested under `app_user` (the same key the read
  /// endpoint uses for inline user snapshots). The person half is
  /// nested under `app_user_person` or `person`. Tolerate both.
  factory Customer.fromJson(Map<String, dynamic> json) {
    final type = (json['customer_type'] as String?) ?? 'unknown';
    final id = (json['customer_id'] as num?)?.toInt() ?? 0;
    final personId = (json['person_id'] as num?)?.toInt();

    final rawUser = json['app_user'] ?? json['user'];
    if (type == 'user' && rawUser is Map) {
      try {
        return Customer.fromUser(
          AppUser.fromJson(Map<String, dynamic>.from(rawUser)),
        );
      } catch (_) {
        // Fall through to unknown.
      }
    }

    final rawPerson = json['app_user_person'] ?? json['person'];
    if (type == 'person' && rawPerson is Map) {
      try {
        return Customer.fromPerson(
          Person.fromJson(Map<String, dynamic>.from(rawPerson)),
        );
      } catch (_) {
        // Fall through to unknown.
      }
    }

    return Customer.unknown(
      type: type,
      id: id,
      personId: personId,
    );
  }

  /// Serialises the customer for **local persistence**.
  ///
  /// Round-trips with [Customer.fromJson]. Uses the read-side key
  /// names (`app_user` / `app_user_person`).
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'customer_type': customerType,
      'customer_id': customerId,
      'person_id': personId,
    };

    if (customerType == 'user' && _user != null) {
      json['app_user'] = _user!.toJson();
    } else if (customerType == 'person' && _person != null) {
      json['app_user_person'] = _person!.toJson();
    }

    return json;
  }

  Map<String, dynamic> toFinancialDocumentData() {
    return {
      'customer_id': customerId,
      'customer_type': customerType,
      'customer_person_id': personId ?? 0,
    };
  }

  T? getObject<T>() {
    if (T == AppUser && customerType == 'user') {
      return _user as T?;
    } else if (T == Person && customerType == 'person') {
      return _person as T?;
    }
    return null;
  }

  bool matchesQuery(String query) {
    if (query.isEmpty) return true;
    final searchQuery = query.toLowerCase();
    return displayName.toLowerCase().contains(searchQuery) ||
        email?.toLowerCase().contains(searchQuery) == true ||
        phone?.contains(query) == true ||
        typeDisplayName.toLowerCase().contains(searchQuery);
  }

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

  Customer mergeWith(Customer other) {
    if (other.customerType != customerType || other.customerId != customerId) {
      return this;
    }
    return copyWith(
      personId: other.personId ?? personId,
      user: other._user ?? _user,
      person: other._person ?? _person,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Customer &&
        other.customerType == customerType &&
        other.customerId == customerId;
  }

  @override
  int get hashCode => Object.hash(customerType, customerId);

  @override
  String toString() {
    return 'Customer(type: $customerType, id: $customerId, name: "$displayName")';
  }
}
