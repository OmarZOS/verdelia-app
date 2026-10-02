class Privileges {
  // Each privilege is represented by a bit
  static const int orderEdit = 1 << 0; // 0000000001 = 1
  static const int productCRUD = 1 << 1; // 0000000010 = 2
  static const int supplierEdit = 1 << 2; // 0000000100 = 4
  static const int orgEdit = 1 << 3; // 0000001000 = 8

  /// Combine multiple privileges
  static int combine(List<int> privileges) {
    return privileges.fold(0, (acc, p) => acc | p);
  }

  /// Check if a privilege exists
  static bool hasPrivilege(int userMask, int privilege) {
    return (userMask & privilege) == privilege;
  }
}

enum DashboardScreenType {
  suppliersPersonnel,
  inventory,
  services,
  pos,
  orders,
  operations,
  finance,
}

enum PrivilegeLevel {
  none,
  view,
  manage,
}
