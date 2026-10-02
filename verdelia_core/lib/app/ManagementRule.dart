import 'package:verdelia_core/app/AppUser.dart';
import 'package:verdelia_core/business/Supplier.dart';

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
    return ManagementRule(
      idManagementRule: _parseInt(json['id_management_rule']),
      ruleRefOrg: _parseIntNullable(json['rule_ref_org']),
      ruleRefProvider: _parseIntNullable(json['rule_ref_provider']),
      ruleRefUser: _parseIntNullable(json['rule_ref_user']),
      managementRuleCode: _parseInt(json['management_rule_code']),
      managementRuleStatus: json['management_rule_status']?.toString(),
      managementRuleExpiry: json['management_rule_expiry']?.toString(),
      createdAt: json['created_at'] != null
          ? _parseDateTime(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? _parseDateTime(json['updated_at'])
          : null,
      providerOrganisation: json['provider_organisation'] != null
          ? ProviderOrganisation.fromJson(json['provider_organisation'])
          : null,
      productProvider: json['product_provider'] != null
          ? Supplier.fromJson(json['product_provider'])
          : null,
      appUser:
          json['app_user'] != null ? AppUser.fromJson(json['app_user']) : null,
      roleInvitations: json['role_invitation'] != null
          ? (json['role_invitation'] as List)
              .map((item) => RoleInvitation.fromJson(item))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_management_rule': idManagementRule,
      'rule_ref_org': ruleRefOrg,
      'rule_ref_provider': ruleRefProvider,
      'rule_ref_user': ruleRefUser,
      'management_rule_code': managementRuleCode,
      'management_rule_status': managementRuleStatus,
      'management_rule_expiry': managementRuleExpiry,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'provider_organisation': providerOrganisation?.toJson(),
      'product_provider': productProvider?.toJson(),
      'app_user': appUser?.toJson(),
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
    return roleInvitations?.firstWhere(
      (inv) => inv.isPending,
      orElse: () => null as RoleInvitation,
    );
  }

  RoleInvitation? get acceptedInvitation {
    return roleInvitations?.firstWhere(
      (inv) => inv.isAccepted,
      orElse: () => null as RoleInvitation,
    );
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
      } catch (e) {
        return null;
      }
    }
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
        'status: $managementRuleStatus, provider: ${productProvider?.providerName}, '
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
    return ProviderOrganisation(
      idproviderOrganisation: _parseInt(json['idprovider_organisation']),
      providerOrganisationName: json['provider_organisation_name']?.toString(),
      providerOrganisationDesc: json['provider_organisation_desc']?.toString(),
      providerOrganisationIconUrl:
          json['provider_organisation_icon_url']?.toString(),
      appUserId: _parseIntNullable(json['app_user_id']),
      providerOrganisationWalletId:
          _parseIntNullable(json['provider_organisation_wallet_id']),
      providerOrganisationNaming:
          _parseIntNullable(json['provider_organisation_naming']),
      verifiedOrganisation: json['verified_organisation'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idprovider_organisation': idproviderOrganisation,
      'provider_organisation_name': providerOrganisationName,
      'provider_organisation_desc': providerOrganisationDesc,
      'provider_organisation_icon_url': providerOrganisationIconUrl,
      'app_user_id': appUserId,
      'provider_organisation_wallet_id': providerOrganisationWalletId,
      'provider_organisation_naming': providerOrganisationNaming,
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
// Product Provider Model
// ============================================================================

class ProductProvider {
  final int idProductProvider;
  final int productProviderTypeId;
  final int productProviderLocationId;
  final int productProviderOrgId;
  final int productProviderDetailsId;
  final int productProviderOwner;
  final int? productProviderWalletId;
  final bool? verifiedProvider;
  final ProductProviderDetails productProviderDetails;

  ProductProvider({
    required this.idProductProvider,
    required this.productProviderTypeId,
    required this.productProviderLocationId,
    required this.productProviderOrgId,
    required this.productProviderDetailsId,
    required this.productProviderOwner,
    this.productProviderWalletId,
    this.verifiedProvider,
    required this.productProviderDetails,
  });

  factory ProductProvider.fromJson(Map<String, dynamic> json) {
    return ProductProvider(
      idProductProvider: _parseInt(json['id_product_provider']),
      productProviderTypeId: _parseInt(json['product_provider_type_id']),
      productProviderLocationId:
          _parseInt(json['product_provider_location_id']),
      productProviderOrgId: _parseInt(json['product_provider_org_id']),
      productProviderDetailsId: _parseInt(json['product_provider_details_id']),
      productProviderOwner: _parseInt(json['product_provider_owner']),
      productProviderWalletId:
          _parseIntNullable(json['product_provider_wallet_id']),
      verifiedProvider: json['verified_provider'] as bool?,
      productProviderDetails: ProductProviderDetails.fromJson(
        json['product_provider_details'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_product_provider': idProductProvider,
      'product_provider_type_id': productProviderTypeId,
      'product_provider_location_id': productProviderLocationId,
      'product_provider_org_id': productProviderOrgId,
      'product_provider_details_id': productProviderDetailsId,
      'product_provider_owner': productProviderOwner,
      'product_provider_wallet_id': productProviderWalletId,
      'verified_provider': verifiedProvider,
      'product_provider_details': productProviderDetails.toJson(),
    };
  }

  String get displayName =>
      productProviderDetails.providerName ?? 'Provider #$idProductProvider';

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
// Product Provider Details
// ============================================================================

class ProductProviderDetails {
  final int idproviderDetailsId;
  final String? providerName;
  final String? providerContactInfo;

  ProductProviderDetails({
    required this.idproviderDetailsId,
    this.providerName,
    this.providerContactInfo,
  });

  factory ProductProviderDetails.fromJson(Map<String, dynamic> json) {
    return ProductProviderDetails(
      idproviderDetailsId: _parseInt(json['idprovider_details_id']),
      providerName: json['provider_name']?.toString(),
      providerContactInfo: json['provider_contact_info']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idprovider_details_id': idproviderDetailsId,
      'provider_name': providerName,
      'provider_contact_info': providerContactInfo,
    };
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
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
