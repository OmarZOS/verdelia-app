// Notifications/RoleInvitation.dart
import 'package:verdelia_core/app/Notifications/NotificationContent.dart';

class RoleInvitation extends NotificationContent {
  final int? organizationId;
  final int? providerId;
  final int role;
  final int invitedBy;
  final int ruleId;
  final String status;

  RoleInvitation({
    this.organizationId,
    this.providerId,
    required this.role,
    required this.invitedBy,
    required this.ruleId,
    this.status = 'PENDING',
    required DateTime timestamp,
  }) : super(
          type: 'role_invitation',
          timestamp: timestamp,
          addedBy: invitedBy,
        );

  factory RoleInvitation.fromJson(Map<String, dynamic> json) {
    return RoleInvitation(
      organizationId: _parseInt(json['organization_id']),
      providerId: _parseInt(json['provider_id']),
      role: _parseInt(json['role']) ?? 0,
      invitedBy: _parseInt(json['invited_by']) ?? 0,
      ruleId: _parseInt(json['management_rule_id']) ??
          _parseInt(json['rule_id']) ??
          0,
      status: json['status'] as String? ?? 'PENDING',
      timestamp: json['invitation_date'] != null
          ? DateTime.parse(json['invitation_date'] as String)
          : DateTime.now(),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (organizationId != null) 'organization_id': organizationId,
      if (providerId != null) 'provider_id': providerId,
      'role': role,
      'invited_by': invitedBy,
      'rule_id': ruleId,
      'status': status,
      'invitation_date': timestamp.toIso8601String(),
    };
  }

  @override
  String get displayTitle {
    switch (status) {
      case 'ACCEPTED':
        return 'Invitation Accepted';
      case 'REJECTED':
        return 'Invitation Declined';
      default:
        return 'Role Invitation';
    }
  }

  @override
  String get displayMessage {
    final roleName = _getRoleName(role);
    final entityName = organizationId != null && organizationId! > 0
        ? 'Organization #$organizationId'
        : 'Supplier #$providerId';

    switch (status) {
      case 'ACCEPTED':
        return 'You have accepted the invitation to join $entityName as $roleName.';
      case 'REJECTED':
        return 'You have declined the invitation to join $entityName as $roleName.';
      default:
        return 'You have been invited to join $entityName as $roleName.';
    }
  }

  String _getRoleName(int roleCode) {
    switch (roleCode) {
      case 1:
        return 'Basic User';
      case 2:
        return 'Manager';
      case 3:
        return 'Admin';
      case 4:
        return 'Supervisor';
      case 5:
        return 'Viewer';
      case 6:
        return 'Contributor';
      default:
        return 'Team Member';
    }
  }

  @override
  String get actionText {
    if (status != 'PENDING') return 'View';
    if (organizationId != null && organizationId! > 0)
      return 'Join Organization';
    return 'Join Supplier';
  }

  @override
  bool get requiresAction => status == 'PENDING';

  bool get isPending => status == 'PENDING';
  bool get isAccepted => status == 'ACCEPTED';
  bool get isRejected => status == 'REJECTED';

  RoleInvitation markAsAccepted() {
    return RoleInvitation(
      organizationId: organizationId,
      providerId: providerId,
      role: role,
      invitedBy: invitedBy,
      ruleId: ruleId,
      status: 'ACCEPTED',
      timestamp: timestamp,
    );
  }

  RoleInvitation markAsRejected() {
    return RoleInvitation(
      organizationId: organizationId,
      providerId: providerId,
      role: role,
      invitedBy: invitedBy,
      ruleId: ruleId,
      status: 'REJECTED',
      timestamp: timestamp,
    );
  }

  @override
  String toString() {
    return 'RoleInvitation(ruleId: $ruleId, role: $role, status: $status)';
  }
}
