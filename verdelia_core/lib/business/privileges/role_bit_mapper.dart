import 'dart:developer';

class PrivilegeItem {
  final String id;
  final String category;
  final int bitPosition;

  const PrivilegeItem({
    required this.id,
    required this.category,
    required this.bitPosition,
  });

  int get bitValue => 1 << bitPosition;
}

class PrivilegeManager {
  static final List<PrivilegeItem> allPrivileges = [
    const PrivilegeItem(
      id: 'personnel_view',
      category: 'personnel_management',
      bitPosition: 0,
    ),
    const PrivilegeItem(
      id: 'personnel_manage',
      category: 'personnel_management',
      bitPosition: 1,
    ),
    const PrivilegeItem(
      id: 'inventory_view',
      category: 'inventory_management',
      bitPosition: 2,
    ),
    const PrivilegeItem(
      id: 'inventory_manage',
      category: 'inventory_management',
      bitPosition: 3,
    ),
    const PrivilegeItem(
      id: 'services_view',
      category: 'services_management',
      bitPosition: 4,
    ),
    const PrivilegeItem(
      id: 'services_manage',
      category: 'services_management',
      bitPosition: 5,
    ),
    const PrivilegeItem(
      id: 'pos_view',
      category: 'pos_management',
      bitPosition: 6,
    ),
    const PrivilegeItem(
      id: 'pos_manage',
      category: 'pos_management',
      bitPosition: 7,
    ),
    const PrivilegeItem(
      id: 'orders_view',
      category: 'order_management',
      bitPosition: 8,
    ),
    const PrivilegeItem(
      id: 'orders_manage',
      category: 'order_management',
      bitPosition: 9,
    ),
    const PrivilegeItem(
      id: 'operations_view',
      category: 'operation_management',
      bitPosition: 10,
    ),
    const PrivilegeItem(
      id: 'operations_manage',
      category: 'operation_management',
      bitPosition: 11,
    ),
    const PrivilegeItem(
      id: 'finance_view',
      category: 'finance_management',
      bitPosition: 12,
    ),
    const PrivilegeItem(
      id: 'finance_manage',
      category: 'finance_management',
      bitPosition: 13,
    ),
  ];

  // Get privilege by ID
  static PrivilegeItem? getPrivilege(String id) {
    return allPrivileges.firstWhere((privilege) => privilege.id == id);
  }

  // Get privilege by bit position
  static PrivilegeItem? getPrivilegeByBitPosition(int position) {
    return allPrivileges
        .firstWhere((privilege) => privilege.bitPosition == position);
  }
}

class RoleBitMapper {
  /// Convert a list of privilege IDs to a bitmask number
  static int privilegesToNumber(List<String> privilegeIds) {
    int bitmask = 0;

    for (final privilegeId in privilegeIds) {
      final privilege = PrivilegeManager.getPrivilege(privilegeId);
      if (privilege != null) {
        bitmask |= privilege.bitValue;
      }
    }

    return bitmask;
  }

  /// Convert a list of PrivilegeItems to a bitmask number
  static int privilegeItemsToNumber(List<PrivilegeItem> privileges) {
    int bitmask = 0;

    for (final privilege in privileges) {
      bitmask |= privilege.bitValue;
    }

    return bitmask;
  }

  /// Get active privilege IDs from a bitmask number
  static List<String> numberToPrivilegeIds(int bitmask) {
    final activePrivileges = <String>[];

    for (final privilege in PrivilegeManager.allPrivileges) {
      if (_isBitSet(bitmask, privilege.bitPosition)) {
        activePrivileges.add(privilege.id);
      }
    }

    return activePrivileges;
  }

  /// Get active PrivilegeItems from a bitmask number
  static List<PrivilegeItem> numberToPrivilegeItems(int bitmask) {
    final activePrivileges = <PrivilegeItem>[];

    for (final privilege in PrivilegeManager.allPrivileges) {
      if (_isBitSet(bitmask, privilege.bitPosition)) {
        activePrivileges.add(privilege);
      }
    }

    return activePrivileges;
  }

  /// Check if a specific privilege is active in the bitmask
  static bool hasPrivilege(int bitmask, String privilegeId) {
    final privilege = PrivilegeManager.getPrivilege(privilegeId);

    log("Checking for ${privilegeId}");
    if (privilege == null) return false;

    return _isBitSet(bitmask, privilege.bitPosition);
  }

  /// Add a privilege to an existing bitmask
  static int addPrivilege(int bitmask, String privilegeId) {
    final privilege = PrivilegeManager.getPrivilege(privilegeId);
    if (privilege != null) {
      return bitmask | privilege.bitValue;
    }
    return bitmask;
  }

  /// Remove a privilege from an existing bitmask
  static int removePrivilege(int bitmask, String privilegeId) {
    final privilege = PrivilegeManager.getPrivilege(privilegeId);
    if (privilege != null) {
      return bitmask & ~privilege.bitValue;
    }
    return bitmask;
  }

  /// Helper method to check if a specific bit is set
  static bool _isBitSet(int number, int bitPosition) {
    return (number & (1 << bitPosition)) != 0;
  }
}
