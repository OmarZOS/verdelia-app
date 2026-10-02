import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/app/ManagementRule.dart';
import 'package:verdelia_core/business/finance/Order.dart';
import 'package:verdelia_core/business/Supplier.dart';
import 'package:verdelia_core/business/privileges/Privileges.dart';
import 'package:provider_store/components/orders/details/customer_details_card.dart';
import 'package:provider_store/components/orders/details/detail_row.dart';
import 'package:provider_store/components/orders/details/order_items.dart';
import 'package:ui/components/order/order_ui_manager.dart';
import 'package:event/order_change_notifier.dart';
import 'package:provider/provider.dart';
import 'package:event/cart_change_notifier.dart';
import 'package:event/personnel_notifier.dart';
import 'package:badges/badges.dart' as badges;

class CustomerDetailsCard extends StatelessWidget {
  final Order order;

  const CustomerDetailsCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'Customer Details',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DetailRow(
            label: 'Customer ID',
            value: '#${order.orderingUserId}',
            icon: Icons.person_rounded,
            color: Colors.blue,
          ),
          const SizedBox(height: 8),
          Text(
            'Additional customer information would appear here...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
