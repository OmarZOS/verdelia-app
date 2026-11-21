import 'package:decimal/decimal.dart';
import 'package:flutter/widgets.dart';
import 'package:verdelia_core/business/finance/Order.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';

enum OrderGrouping {
  delivery,
  invoice,
  status;

  String label(AppLocalizations loc) {
    switch (this) {
      case OrderGrouping.delivery:
        return loc.deliveredTxt;
      case OrderGrouping.invoice:
        return loc.invoice;
      case OrderGrouping.status:
        return loc.order;
    }
  }

  IconData get icon {
    switch (this) {
      case OrderGrouping.delivery:
        return Icons.local_shipping_outlined;
      case OrderGrouping.invoice:
        return Icons.receipt_long_outlined;
      case OrderGrouping.status:
        return Icons.timeline_outlined;
    }
  }
}

class OrderGroup {
  final String key; // stable id (for animations / expansion state)
  final String label; // localized, shown in the header
  final IconData icon;
  final List<Order> orders;

  const OrderGroup({
    required this.key,
    required this.label,
    required this.icon,
    required this.orders,
  });

  Decimal get total => orders.fold(
        Decimal.zero,
        (sum, o) => sum + (o.invoice?.grandTotal ?? Decimal.zero),
      );

  int get count => orders.length;
}
