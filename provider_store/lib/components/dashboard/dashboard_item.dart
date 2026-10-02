import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/business/privileges/Privileges.dart';
import 'package:event/extensions/personnel_access_manager.dart';

class DashboardItem {
  final DashboardScreenType type;
  final IconData icon;
  final String label;
  final int index;
  final PrivilegeLevel? privilegeLevel;

  DashboardItem({
    required this.type,
    required this.icon,
    required this.label,
    required this.index,
    this.privilegeLevel,
    required SupplierAccessType supplierAccessType,
  });

  bool get showFloatingAction => type != DashboardScreenType.suppliersPersonnel;

  IconData get floatingActionIcon {
    switch (type) {
      case DashboardScreenType.inventory:
        return Icons.add_box_rounded;
      case DashboardScreenType.operations:
        return Icons.business_center_sharp;
      case DashboardScreenType.pos:
        return Icons.shopping_cart;
      case DashboardScreenType.finance:
        return Icons.receipt_long;
      case DashboardScreenType.services:
        return Icons.add_circle_outline;
      default:
        return Icons.add;
    }
  }

  String floatingActionTooltip(AppLocalizations? localizations) {
    switch (type) {
      case DashboardScreenType.inventory:
        return localizations?.addProduct ?? 'Add Product';
      case DashboardScreenType.operations:
        return localizations?.createNewOrder ?? 'Create Order';
      case DashboardScreenType.pos:
        return localizations?.openCart ?? 'Open Cart';
      case DashboardScreenType.finance:
        return localizations?.createNewInvoice ?? 'Create Invoice';
      case DashboardScreenType.services:
        return localizations?.addService ?? 'Add Service';
      default:
        return localizations?.add ?? 'Add';
    }
  }
}
