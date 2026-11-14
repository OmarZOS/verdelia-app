import 'package:verdelia_core/app/AppUser.dart';
import 'package:verdelia_core/business/Supplier.dart';

/// A single membership rule that ties a user to a provider inside an
/// organisation.
///
/// ## Wire shape (abbreviated)
///
/// ```json
/// {
///   "id_management_rule": 2,
///   "rule_org_id": 116,
///   "rule_provider_id": 2,
///   "rule_user_id": 3,
///   "management_rule_status": "PENDING",
///   "management_rule_code": 27,
///   "management_rule_expiry": "2026-12-23T15:56:36",
///   "rule_org":      { ... provider_organisation fields ... },
///   "rule_provider": { ... product provider fields ... },
///   "rule_user":     { ... app_user fields ... }
/// }
/// ```
///
/// ## Corrections over the previous model
///
/// * **FK names.** The wire uses `rule_org_id`, `rule_provider_id`,
///   and `rule_user_id` — not `rule_ref_*`. Every FK was null before.
/// * **Nested relationship names.** The wire uses `rule_org`,
///   `rule_provider`, and `rule_user` — not
///   `provider_organisation`, `product_provider`, `app_user`. Every
///   nested object was null before.
/// * **Provider parser.** The `rule_provider` payload matches the same
///   shape `Supplier.fromJson` already handles (`provider_name`,
///   `provider_contact_info` under `product_provider_details`,
///   `provider_organisation_*` under `product_provider_org`). The
///   local `ProductProvider` model that used to live here read
///   `product_provider_owner` — a field the payload never emits — and
///   is now removed in favour of `Supplier`.
/// * **Organisation id.** `ProviderOrganisation.fromJson` was reading
///   `idprovider_organisation`, but the payload emits
///   `id_provider_organisation`. Fixed.
/// * **Organisation desc.** The payload emits
///   `provider_organisation_description`, not `_desc`. Fixed.
class ManagementRule {
  final int idManagementRule;
  final int? ruleRefOrg;
  final int? ruleRefProvider;
  final int? ruleRefUser;
  final int managementRuleCode;
  final String? managementRuleStatus;
  final String? managementRuleExpiry;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Relationships
  final ProviderOrganisation? providerOrganisation;
  final Supplier? productProvider;
  final AppUser? appUser;
  final List<RoleInvitation>? roleInvitations;

  ManagementRule({
    required this.idManagementRule,
    this.ruleRefOrg,
    this.ruleRefProvider,
    this.ruleRefUser,
    required this.managementRuleCode,
    this.managementRuleStatus,
    this.managementRuleExpiry,
    this.createdAt,
    this.updatedAt,
    this.providerOrganisation,
    this.productProvider,
    this.appUser,
    this.roleInvitations,
  });

  factory ManagementRule.empty() {
    return ManagementRule(
      idManagementRule: 0,
      ruleRefOrg: null,
      ruleRefProvider: null,
      ruleRefUser: null,
      managementRuleCode: 0,
      managementRuleStatus: null,
      managementRuleExpiry: null,
      createdAt: null,
      updatedAt: null,
      providerOrganisation: null,
      productProvider: null,
      appUser: null,
      roleInvitations: null,
    );
  }

  factory ManagementRule.fromJson(Map<String, dynamic> json) {
    // The wire uses `rule_org` / `rule_provider` / `rule_user`.
    // Accept the old names too so persisted payloads survive.
    final orgJson = _asMapOrNull(
      json['rule_org'] ?? json['provider_organisation'],
    );
    final providerJson = _asMapOrNull(
      json['rule_provider'] ?? json['product_provider'],
    );
    final userJson = _asMapOrNull(
      json['rule_user'] ?? json['app_user'],
    );

    final invitationsRaw = json['role_invitation'] ??
        json['role_invitations'] ??
        json['invitations'];

    return ManagementRule(
      idManagementRule: _parseInt(json['id_management_rule']),
      // FK names on the wire are `rule_org_id`, `rule_provider_id`,
      // `rule_user_id` — not `rule_ref_*`.
      ruleRefOrg: _parseIntNullable(
        json['rule_org_id'] ?? json['rule_ref_org'],
      ),
      ruleRefProvider: _parseIntNullable(
        json['rule_provider_id'] ?? json['rule_ref_provider'],
      ),
      ruleRefUser: _parseIntNullable(
        json['rule_user_id'] ?? json['rule_ref_user'],
      ),
      managementRuleCode: _parseInt(json['management_rule_code']),
      managementRuleStatus: json['management_rule_status']?.toString(),
      managementRuleExpiry: json['management_rule_expiry']?.toString(),
      createdAt: json['created_at'] != null
          ? _parseDateTime(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? _parseDateTime(json['updated_at'])
          : null,
      providerOrganisation:
          orgJson != null ? ProviderOrganisation.fromJson(orgJson) : null,
      // `rule_provider` uses the same nested shape `Supplier` already
      // parses. Reusing it removes the local `ProductProvider` model
      // (which read a `product_provider_owner` that the API never
      // emits).
      productProvider:
          providerJson != null ? Supplier.fromJson(providerJson) : null,
      appUser: userJson != null ? AppUser.fromJson(userJson) : null,
      roleInvitations: invitationsRaw is List
          ? invitationsRaw
              .whereType<Map>()
              .map((item) =>
                  RoleInvitation.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_management_rule': idManagementRule,
      // Emit the wire names the server reads on round-trip.
      'rule_org_id': ruleRefOrg,
      'rule_provider_id': ruleRefProvider,
      'rule_user_id': ruleRefUser,
      'management_rule_code': managementRuleCode,
      'management_rule_status': managementRuleStatus,
      'management_rule_expiry': managementRuleExpiry,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'rule_org': providerOrganisation?.toJson(),
      'rule_provider': productProvider?.toJson(),
      'rule_user': appUser?.toJson(),
      'role_invitation': roleInvitations?.map((r) => r.toJson()).toList(),
    };
  }

  // Helper getters
  bool get isActive => managementRuleStatus?.toUpperCase() == 'ACTIVE';
  bool get isPending => managementRuleStatus?.toUpperCase() == 'PENDING';
  bool get isRejected => managementRuleStatus?.toUpperCase() == 'REJECTED';
  bool get isExpired => managementRuleStatus?.toUpperCase() == 'EXPIRED';

  bool get hasPendingInvitation {
    return roleInvitations?.any((inv) => inv.isPending) ?? false;
  }

  bool get hasAcceptedInvitation {
    return roleInvitations?.any((inv) => inv.isAccepted) ?? false;
  }

  RoleInvitation? get pendingInvitation {
    if (roleInvitations == null) return null;
    for (final inv in roleInvitations!) {
      if (inv.isPending) return inv;
    }
    return null;
  }

  RoleInvitation? get acceptedInvitation {
    if (roleInvitations == null) return null;
    for (final inv in roleInvitations!) {
      if (inv.isAccepted) return inv;
    }
    return null;
  }

  String get displayStatus {
    switch (managementRuleStatus?.toUpperCase()) {
      case 'PENDING':
        return 'Pending';
      case 'ACTIVE':
        return 'Active';
      case 'REJECTED':
        return 'Rejected';
      case 'EXPIRED':
        return 'Expired';
      default:
        return managementRuleStatus ?? 'Unknown';
    }
  }

  String get displayName {
    final providerName = productProvider?.providerName;
    final orgName = providerOrganisation?.providerOrganisationName;
    if (providerName != null && providerName.isNotEmpty) {
      return providerName;
    }
    if (orgName != null && orgName.isNotEmpty) {
      return orgName;
    }
    return 'Provider #$ruleRefProvider';
  }

  String get organisationName {
    return providerOrganisation?.providerOrganisationName ??
        'Unknown Organisation';
  }

  String get providerName {
    return productProvider?.providerName ?? 'Unknown Provider';
  }

  DateTime? get expiryDate {
    if (managementRuleExpiry != null) {
      return DateTime.tryParse(managementRuleExpiry!);
    }
    return null;
  }

  bool get isExpiredDate {
    final expiry = expiryDate;
    if (expiry == null) return false;
    return DateTime.now().isAfter(expiry);
  }

  // Static helpers
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  static int? _parseIntNullable(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static Map<String, dynamic>? _asMapOrNull(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  // Copy methods
  ManagementRule copyWith({
    int? idManagementRule,
    int? ruleRefOrg,
    int? ruleRefProvider,
    int? ruleRefUser,
    int? managementRuleCode,
    String? managementRuleStatus,
    String? managementRuleExpiry,
    DateTime? createdAt,
    DateTime? updatedAt,
    ProviderOrganisation? providerOrganisation,
    Supplier? productProvider,
    AppUser? appUser,
    List<RoleInvitation>? roleInvitations,
  }) {
    return ManagementRule(
      idManagementRule: idManagementRule ?? this.idManagementRule,
      ruleRefOrg: ruleRefOrg ?? this.ruleRefOrg,
      ruleRefProvider: ruleRefProvider ?? this.ruleRefProvider,
      ruleRefUser: ruleRefUser ?? this.ruleRefUser,
      managementRuleCode: managementRuleCode ?? this.managementRuleCode,
      managementRuleStatus: managementRuleStatus ?? this.managementRuleStatus,
      managementRuleExpiry: managementRuleExpiry ?? this.managementRuleExpiry,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      providerOrganisation: providerOrganisation ?? this.providerOrganisation,
      productProvider: productProvider ?? this.productProvider,
      appUser: appUser ?? this.appUser,
      roleInvitations: roleInvitations ?? this.roleInvitations,
    );
  }

  ManagementRule copyAsAccepted() {
    return copyWith(
      managementRuleStatus: 'ACTIVE',
      updatedAt: DateTime.now(),
    );
  }

  ManagementRule copyAsRejected() {
    return copyWith(
      managementRuleStatus: 'REJECTED',
      updatedAt: DateTime.now(),
    );
  }

  ManagementRule copyAsPending() {
    return copyWith(
      managementRuleStatus: 'PENDING',
      updatedAt: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ManagementRule &&
        other.idManagementRule == idManagementRule;
  }

  @override
  int get hashCode => idManagementRule.hashCode;

  @override
  String toString() {
    return 'ManagementRule(id: $idManagementRule, code: $managementRuleCode, '
        'status: $managementRuleStatus, '
        'provider: ${productProvider?.providerName}, '
        'user: ${appUser?.appUserName})';
  }
}

// ============================================================================
// RoleInvitation Model
// ============================================================================

class RoleInvitation {
  final int idRoleInvitation;
  final int? notificationId;
  final int? ruleId;
  final int? providerId;
  final int? appUserId;
  final int? organisationId;
  final String? invitationStatus;
  final String? invitationExpiry;

  RoleInvitation({
    required this.idRoleInvitation,
    this.notificationId,
    this.ruleId,
    this.providerId,
    this.appUserId,
    this.organisationId,
    this.invitationStatus,
    this.invitationExpiry,
  });

  factory RoleInvitation.fromJson(Map<String, dynamic> json) {
    return RoleInvitation(
      idRoleInvitation: _parseInt(json['id_role_invitation']),
      notificationId: _parseIntNullable(json['notification_id']),
      ruleId: _parseIntNullable(json['rule_id']),
      providerId: _parseIntNullable(json['provider_id']),
      appUserId: _parseIntNullable(json['app_user_id']),
      organisationId: _parseIntNullable(json['organisation_id']),
      invitationStatus: json['invitation_status']?.toString(),
      invitationExpiry: json['invitation_expiry']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_role_invitation': idRoleInvitation,
      'notification_id': notificationId,
      'rule_id': ruleId,
      'provider_id': providerId,
      'app_user_id': appUserId,
      'organisation_id': organisationId,
      'invitation_status': invitationStatus,
      'invitation_expiry': invitationExpiry,
    };
  }

  bool get isPending => invitationStatus?.toUpperCase() == 'PENDING';
  bool get isAccepted => invitationStatus?.toUpperCase() == 'ACCEPTED';
  bool get isRejected => invitationStatus?.toUpperCase() == 'REJECTED';

  String get displayStatus {
    switch (invitationStatus?.toUpperCase()) {
      case 'PENDING':
        return 'Pending';
      case 'ACCEPTED':
        return 'Accepted';
      case 'REJECTED':
        return 'Rejected';
      default:
        return invitationStatus ?? 'Unknown';
    }
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int? _parseIntNullable(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  @override
  String toString() {
    return 'RoleInvitation(id: $idRoleInvitation, status: $invitationStatus, '
        'rule: $ruleId, user: $appUserId)';
  }
}

// ============================================================================
// Provider Organisation Model
// ============================================================================

class ProviderOrganisation {
  final int idproviderOrganisation;
  final String? providerOrganisationName;
  final String? providerOrganisationDesc;
  final String? providerOrganisationIconUrl;
  final int? appUserId;
  final int? providerOrganisationWalletId;
  final int? providerOrganisationNaming;
  final bool? verifiedOrganisation;

  ProviderOrganisation({
    required this.idproviderOrganisation,
    this.providerOrganisationName,
    this.providerOrganisationDesc,
    this.providerOrganisationIconUrl,
    this.appUserId,
    this.providerOrganisationWalletId,
    this.providerOrganisationNaming,
    this.verifiedOrganisation,
  });

  factory ProviderOrganisation.fromJson(Map<String, dynamic> json) {
    // FIX: wire names are `id_provider_organisation`,
    // `provider_organisation_description`, `user_id`, and `naming_id`.
    // The previous model read `idprovider_organisation`,
    // `provider_organisation_desc`, and `app_user_id` — none of which
    // the API emits.
    return ProviderOrganisation(
      idproviderOrganisation: _parseInt(
        json['id_provider_organisation'] ?? json['idprovider_organisation'],
      ),
      providerOrganisationName: json['provider_organisation_name']?.toString(),
      providerOrganisationDesc: (json['provider_organisation_description'] ??
              json['provider_organisation_desc'])
          ?.toString(),
      providerOrganisationIconUrl:
          json['provider_organisation_icon_url']?.toString(),
      appUserId: _parseIntNullable(json['user_id'] ?? json['app_user_id']),
      providerOrganisationWalletId:
          _parseIntNullable(json['provider_organisation_wallet_id']),
      providerOrganisationNaming: _parseIntNullable(
          json['naming_id'] ?? json['provider_organisation_naming']),
      verifiedOrganisation: json['verified_organisation'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_provider_organisation': idproviderOrganisation,
      'provider_organisation_name': providerOrganisationName,
      'provider_organisation_description': providerOrganisationDesc,
      'provider_organisation_icon_url': providerOrganisationIconUrl,
      'user_id': appUserId,
      'provider_organisation_wallet_id': providerOrganisationWalletId,
      'naming_id': providerOrganisationNaming,
      'verified_organisation': verifiedOrganisation,
    };
  }

  String get displayName => providerOrganisationName ?? 'Unknown Organisation';

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int? _parseIntNullable(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}

// ============================================================================
// Management Rule Data (Helper class for grouped rules)
// ============================================================================

class ManagementRuleData {
  final List<ManagementRule> all;
  final List<ManagementRule> active;
  final List<ManagementRule> pending;
  final List<ManagementRule> rejected;
  final List<ManagementRule> expired;
  final ManagementRule? activeForSupplier;
  final ManagementRule? pendingForSupplier;

  ManagementRuleData({
    required this.all,
    required this.active,
    required this.pending,
    required this.rejected,
    required this.expired,
    this.activeForSupplier,
    this.pendingForSupplier,
  });

  factory ManagementRuleData.fromList(List<ManagementRule> rules) {
    final active = rules.where((r) => r.isActive).toList();
    final pending = rules.where((r) => r.isPending).toList();
    final rejected = rules.where((r) => r.isRejected).toList();
    final expired = rules.where((r) => r.isExpired).toList();

    return ManagementRuleData(
      all: rules,
      active: active,
      pending: pending,
      rejected: rejected,
      expired: expired,
      activeForSupplier: active.isNotEmpty ? active.first : null,
      pendingForSupplier: pending.isNotEmpty ? pending.first : null,
    );
  }

  factory ManagementRuleData.empty() {
    return ManagementRuleData(
      all: [],
      active: [],
      pending: [],
      rejected: [],
      expired: [],
      activeForSupplier: null,
      pendingForSupplier: null,
    );
  }

  ManagementRuleData copyWith({
    List<ManagementRule>? all,
    List<ManagementRule>? active,
    List<ManagementRule>? pending,
    List<ManagementRule>? rejected,
    List<ManagementRule>? expired,
    ManagementRule? activeForSupplier,
    ManagementRule? pendingForSupplier,
  }) {
    return ManagementRuleData(
      all: all ?? this.all,
      active: active ?? this.active,
      pending: pending ?? this.pending,
      rejected: rejected ?? this.rejected,
      expired: expired ?? this.expired,
      activeForSupplier: activeForSupplier ?? this.activeForSupplier,
      pendingForSupplier: pendingForSupplier ?? this.pendingForSupplier,
    );
  }

  int get totalCount => all.length;
  int get activeCount => active.length;
  int get pendingCount => pending.length;
  int get rejectedCount => rejected.length;
  int get expiredCount => expired.length;
}
