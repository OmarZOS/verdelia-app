import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/business/privileges/role_bit_mapper.dart';

class PrivilegeUI {
  final String id;
  final IconData icon;
  final String Function(BuildContext) title;
  final String Function(BuildContext) description;
  final String Function(BuildContext) roleName;
  final String category;

  const PrivilegeUI({
    required this.id,
    required this.icon,
    required this.title,
    required this.description,
    required this.roleName,
    required this.category,
  });

  String getTitle(BuildContext context) => title(context);
  String getRoleName(BuildContext context) => roleName(context);
  String getDescription(BuildContext context) => description(context);
}

class PrivilegeUIManager {
  // Map all privileges from PrivilegeManager to UI representation
  static final List<PrivilegeUI> allPrivileges = [
    // Personnel Management
    PrivilegeUI(
      id: 'personnel_view',
      icon: Icons.people_outline,
      title: (context) => AppLocalizations.of(context)!.personnel_view_title,
      description: (context) =>
          AppLocalizations.of(context)!.personnel_view_description,
      roleName: (context) => AppLocalizations.of(context)!.roleSupervisor,
      category: 'personnel_management',
    ),
    PrivilegeUI(
      id: 'personnel_manage',
      icon: Icons.manage_accounts,
      title: (context) => AppLocalizations.of(context)!.personnel_manage_title,
      description: (context) =>
          AppLocalizations.of(context)!.personnel_manage_description,
      roleName: (context) => AppLocalizations.of(context)!.roleAdmin,
      category: 'personnel_management',
    ),
    // Inventory Management
    PrivilegeUI(
      id: 'inventory_view',
      icon: Icons.inventory_2_outlined,
      title: (context) => AppLocalizations.of(context)!.inventory_view_title,
      description: (context) =>
          AppLocalizations.of(context)!.inventory_view_description,
      roleName: (context) => AppLocalizations.of(context)!.roleStaff,
      category: 'inventory_management',
    ),
    PrivilegeUI(
      id: 'inventory_manage',
      icon: Icons.inventory,
      title: (context) => AppLocalizations.of(context)!.inventory_manage_title,
      description: (context) =>
          AppLocalizations.of(context)!.inventory_manage_description,
      roleName: (context) => AppLocalizations.of(context)!.roleManager,
      category: 'inventory_management',
    ),
    // Services Management
    PrivilegeUI(
      id: 'services_view',
      icon: Icons.room_service_outlined,
      title: (context) => AppLocalizations.of(context)!.services_view_title,
      description: (context) =>
          AppLocalizations.of(context)!.services_view_description,
      roleName: (context) => AppLocalizations.of(context)!.roleStaff,
      category: 'services_management',
    ),
    PrivilegeUI(
      id: 'services_manage',
      icon: Icons.room_service,
      title: (context) => AppLocalizations.of(context)!.services_manage_title,
      description: (context) =>
          AppLocalizations.of(context)!.services_manage_description,
      roleName: (context) => AppLocalizations.of(context)!.roleManager,
      category: 'services_management',
    ),
    // POS Management
    PrivilegeUI(
      id: 'pos_view',
      icon: Icons.point_of_sale_outlined,
      title: (context) => AppLocalizations.of(context)!.pos_view_title,
      description: (context) =>
          AppLocalizations.of(context)!.pos_view_description,
      roleName: (context) => AppLocalizations.of(context)!.roleStaff,
      category: 'pos_management',
    ),
    PrivilegeUI(
      id: 'pos_manage',
      icon: Icons.point_of_sale,
      title: (context) => AppLocalizations.of(context)!.pos_manage_title,
      description: (context) =>
          AppLocalizations.of(context)!.pos_manage_description,
      roleName: (context) => AppLocalizations.of(context)!.roleManager,
      category: 'pos_management',
    ),
    // Order Management
    PrivilegeUI(
      id: 'orders_view',
      icon: Icons.shopping_cart_outlined,
      title: (context) => AppLocalizations.of(context)!.orders_view_title,
      description: (context) =>
          AppLocalizations.of(context)!.orders_view_description,
      roleName: (context) => AppLocalizations.of(context)!.roleViewer,
      category: 'order_management',
    ),
    PrivilegeUI(
      id: 'orders_manage',
      icon: Icons.receipt_long,
      title: (context) => AppLocalizations.of(context)!.orders_manage_title,
      description: (context) =>
          AppLocalizations.of(context)!.orders_manage_description,
      roleName: (context) => AppLocalizations.of(context)!.roleManager,
      category: 'order_management',
    ),
    // Operations Management
    PrivilegeUI(
      id: 'operations_view',
      icon: Icons.settings_outlined,
      title: (context) => AppLocalizations.of(context)!.operations_view_title,
      description: (context) =>
          AppLocalizations.of(context)!.operations_view_description,
      roleName: (context) => AppLocalizations.of(context)!.roleSupervisor,
      category: 'operation_management',
    ),
    PrivilegeUI(
      id: 'operations_manage',
      icon: Icons.settings,
      title: (context) => AppLocalizations.of(context)!.operations_manage_title,
      description: (context) =>
          AppLocalizations.of(context)!.operations_manage_description,
      roleName: (context) => AppLocalizations.of(context)!.roleAdmin,
      category: 'operation_management',
    ),
    // Finance Management
    PrivilegeUI(
      id: 'finance_view',
      icon: Icons.attach_money_outlined,
      title: (context) => AppLocalizations.of(context)!.finance_view_title,
      description: (context) =>
          AppLocalizations.of(context)!.finance_view_description,
      roleName: (context) => AppLocalizations.of(context)!.roleSupervisor,
      category: 'finance_management',
    ),
    PrivilegeUI(
      id: 'finance_manage',
      icon: Icons.attach_money,
      title: (context) => AppLocalizations.of(context)!.finance_manage_title,
      description: (context) =>
          AppLocalizations.of(context)!.finance_manage_description,
      roleName: (context) => AppLocalizations.of(context)!.roleAdmin,
      category: 'finance_management',
    ),
  ];

  // Get privilege by ID
  static PrivilegeUI? getPrivilege(String id) {
    try {
      return allPrivileges.firstWhere((privilege) => privilege.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get privileges from bitmask
  static List<PrivilegeUI> getPrivilegesFromBitmask(int bitmask) {
    final privilegeIds = RoleBitMapper.numberToPrivilegeIds(bitmask);
    return privilegeIds
        .map((id) => getPrivilege(id))
        .whereType<PrivilegeUI>()
        .toList();
  }

  // Get privilege UI by category (grouped)
  static Map<String, List<PrivilegeUI>> getPrivilegesByCategory(int bitmask) {
    final privileges = getPrivilegesFromBitmask(bitmask);
    final categories = <String, List<PrivilegeUI>>{};

    for (final privilege in privileges) {
      if (!categories.containsKey(privilege.category)) {
        categories[privilege.category] = [];
      }
      categories[privilege.category]!.add(privilege);
    }

    return categories;
  }

  // Get all categories
  static List<String> getAllCategories() {
    return allPrivileges.map((e) => e.category).toSet().toList();
  }

  // Localize category name
  static String localizeCategory(BuildContext context, String categoryId) {
    final l = AppLocalizations.of(context)!;

    switch (categoryId) {
      case 'personnel_management':
        return l.category_personnel;
      case 'inventory_management':
        return l.category_inventory;
      case 'services_management':
        return l.category_services;
      case 'pos_management':
        return l.category_pos;
      case 'order_management':
        return l.category_orders;
      case 'operation_management':
        return l.category_operations;
      case 'finance_management':
        return l.category_finance;
      default:
        return categoryId.replaceAll('_', ' ').capitalize();
    }
  }

  // Optimize privileges - remove view privileges if manage exists
  static List<String> getOptimizedPrivilegeIds(int bitmask) {
    final allIds = RoleBitMapper.numberToPrivilegeIds(bitmask);
    final optimized = List<String>.from(allIds);

    // Define view-manage pairs
    const viewManagePairs = [
      ['personnel_view', 'personnel_manage'],
      ['inventory_view', 'inventory_manage'],
      ['services_view', 'services_manage'],
      ['pos_view', 'pos_manage'],
      ['orders_view', 'orders_manage'],
      ['operations_view', 'operations_manage'],
      ['finance_view', 'finance_manage'],
    ];

    for (final pair in viewManagePairs) {
      final viewId = pair[0];
      final manageId = pair[1];

      if (optimized.contains(manageId) && optimized.contains(viewId)) {
        optimized.remove(viewId);
      }
    }

    return optimized;
  }

  // Get optimized privileges from bitmask
  static List<PrivilegeUI> getOptimizedPrivileges(int bitmask) {
    final optimizedIds = getOptimizedPrivilegeIds(bitmask);
    return optimizedIds
        .map((id) => getPrivilege(id))
        .whereType<PrivilegeUI>()
        .toList();
  }

  // Get access level summary from bitmask
  static String getAccessLevelSummary(
    int bitmask, {
    required BuildContext context,
  }) {
    final optimized = getOptimizedPrivilegeIds(bitmask);

    if (optimized.isEmpty) {
      return AppLocalizations.of(context)!.roleNoPrivileges;
    }

    // Check for Admin (has all manage privileges)
    final allManageIds = allPrivileges
        .where((p) => p.id.endsWith('_manage'))
        .map((p) => p.id)
        .toList();

    final hasAllManage = allManageIds.every((id) => optimized.contains(id));
    if (hasAllManage) {
      return AppLocalizations.of(context)!.roleAdmin;
    }

    // Check for Manager (has at least one manage privilege)
    final hasManageAccess = optimized.any((id) => id.endsWith('_manage'));
    if (hasManageAccess) {
      return AppLocalizations.of(context)!.roleManager;
    }

    // Check for Supervisor (has sensitive view privileges)
    final sensitiveViewIds = [
      'personnel_view',
      'operations_view',
      'finance_view'
    ];
    final hasSensitiveView =
        optimized.any((id) => sensitiveViewIds.contains(id));
    if (hasSensitiveView) {
      return AppLocalizations.of(context)!.roleSupervisor;
    }

    // Check for Viewer (has view privileges only)
    final hasViewAccess = optimized.any((id) => id.endsWith('_view'));
    if (hasViewAccess) {
      return AppLocalizations.of(context)!.roleViewer;
    }

    return AppLocalizations.of(context)!.roleStaff;
  }

  // Get highest role from bitmask
  static String? getHighestRole(
    int bitmask, {
    required BuildContext context,
  }) {
    final optimized = getOptimizedPrivilegeIds(bitmask);

    if (optimized.isEmpty) return null;

    // Define role hierarchy with associated privileges
    const roleHierarchy = [
      {
        'role': 'roleAdmin',
        'privileges': [
          'personnel_manage',
          'operations_manage',
          'finance_manage'
        ]
      },
      {
        'role': 'roleManager',
        'privileges': [
          'inventory_manage',
          'services_manage',
          'pos_manage',
          'orders_manage'
        ]
      },
      {
        'role': 'roleSupervisor',
        'privileges': ['personnel_view', 'operations_view', 'finance_view']
      },
      {
        'role': 'roleViewer',
        'privileges': ['orders_view']
      },
      {
        'role': 'roleStaff',
        'privileges': ['inventory_view', 'services_view', 'pos_view']
      },
    ];

    // Find the highest role based on privileges
    for (final roleData in roleHierarchy) {
      final rolePrivileges = roleData['privileges']! as List<String>;
      if (optimized.any((id) => rolePrivileges.contains(id))) {
        final l = AppLocalizations.of(context)!;
        switch (roleData['role']) {
          case 'roleAdmin':
            return l.roleAdmin;
          case 'roleManager':
            return l.roleManager;
          case 'roleSupervisor':
            return l.roleSupervisor;
          case 'roleViewer':
            return l.roleViewer;
          case 'roleStaff':
            return l.roleStaff;
        }
      }
    }

    return AppLocalizations.of(context)!.roleStaff;
  }

  // Get icons for optimized privileges
  static List<IconData> getOptimizedIcons(int bitmask) {
    final optimized = getOptimizedPrivileges(bitmask);
    return optimized.map((privilege) => privilege.icon).toList();
  }

  // // Get role color based on privilege level
  // static Color getRoleColor(BuildContext context, int bitmask) {
  //   final theme = Theme.of(context);
  //   final summary = getAccessLevelSummary(bitmask, context: context);
  //   final loc = AppLocalizations.of(context)!;

  //   switch (summary) {
  //     case 'Admin':
  //     case loc.roleAdmin:
  //       return Colors.red;
  //     case 'Manager':
  //     case loc.roleManager:
  //       return Colors.orange;
  //     case 'Supervisor':
  //     case loc.roleSupervisor:
  //       return Colors.blue;
  //     case 'Viewer':
  //     case loc.roleViewer:
  //       return Colors.green;
  //     case 'Staff':
  //     case loc.roleStaff:
  //       return theme.colorScheme.primary;
  //     default:
  //       return theme.colorScheme.outline;
  //   }
  // }

  // Calculate permission score (0-100) based on privileges
  static double getPermissionScore(int bitmask) {
    final activeCount = RoleBitMapper.numberToPrivilegeIds(bitmask).length;
    final totalCount = PrivilegeManager.allPrivileges.length;
    return (activeCount / totalCount) * 100;
  }

  // Check if a category has any privileges in bitmask
  static bool hasCategoryPrivileges(int bitmask, String category) {
    final privileges = getPrivilegesFromBitmask(bitmask);
    return privileges.any((p) => p.category == category);
  }

  // Get category icon
  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'personnel_management':
        return Icons.people;
      case 'inventory_management':
        return Icons.inventory_2;
      case 'services_management':
        return Icons.room_service;
      case 'pos_management':
        return Icons.point_of_sale;
      case 'order_management':
        return Icons.shopping_cart;
      case 'operation_management':
        return Icons.settings;
      case 'finance_management':
        return Icons.attach_money;
      default:
        return Icons.category;
    }
  }
}

// Helper extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
