import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/app/ManagementRule.dart';
import 'package:verdelia_core/business/finance/Order.dart';
import 'package:verdelia_core/business/Supplier.dart';
import 'package:verdelia_core/business/privileges/Privileges.dart';
import 'package:provider_store/components/orders/details/order_details_screen.dart';
import 'package:ui/components/order/order_ui_manager.dart';
import 'package:event/order_change_notifier.dart';
import 'package:provider/provider.dart';
import 'package:event/cart_change_notifier.dart';
import 'package:event/personnel_notifier.dart';
import 'package:badges/badges.dart' as badges;

import '../components/selling_point/selling_point_supplier.dart';

class SupplierOrdersScreen extends StatelessWidget {
  final PrivilegeLevel privilegeLevel;
  final int userId;
  final List<int> accessibleSuppliers;
  final PersonnelNotifier personnelNotifier;

  const SupplierOrdersScreen({
    super.key,
    required this.privilegeLevel,
    required this.userId,
    required this.accessibleSuppliers,
    required this.personnelNotifier,
  });

  bool get canManage => privilegeLevel == PrivilegeLevel.manage;
  bool get canView => privilegeLevel == PrivilegeLevel.view;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: context.read<CartChangeNotifier>()),
        ChangeNotifierProvider.value(
            value: context.read<OrderChangeNotifier>()),
      ],
      child: Consumer<OrderChangeNotifier>(
        builder: (context, orderNotifier, _) {
          return OrdersScreenContent(
            privilegeLevel: privilegeLevel,
            userId: userId,
            accessibleSuppliers: accessibleSuppliers,
            personnelNotifier: personnelNotifier,
            canManage: canManage,
            canView: canView,
          );
        },
      ),
    );
  }
}

class OrdersScreenContent extends StatefulWidget {
  final PrivilegeLevel privilegeLevel;
  final int userId;
  final List<int> accessibleSuppliers;
  final PersonnelNotifier personnelNotifier;
  final bool canManage;
  final bool canView;

  const OrdersScreenContent({
    required this.privilegeLevel,
    required this.userId,
    required this.accessibleSuppliers,
    required this.personnelNotifier,
    required this.canManage,
    required this.canView,
  });

  @override
  State<OrdersScreenContent> createState() => OrdersScreenContentState();
}

class OrdersScreenContentState extends State<OrdersScreenContent>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late OrderUIManager uiManager;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    uiManager = OrderUIManager(
      privilegeLevel: widget.privilegeLevel,
      userId: widget.userId,
      accessibleSuppliers: widget.accessibleSuppliers,
      personnelNotifier: widget.personnelNotifier,
      vsync: this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    uiManager.initialize(context);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      uiManager.refreshOrders(context);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    uiManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suppliers = uiManager.getAccessibleSuppliers();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: NestedScrollView(
        controller: uiManager.scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 140,
              collapsedHeight: kToolbarHeight,
              floating: true,
              pinned: true,
              snap: true,
              backgroundColor: theme.colorScheme.surface,
              surfaceTintColor: theme.colorScheme.surfaceTint,
              elevation: innerBoxIsScrolled ? 4 : 0,
              title: AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: uiManager.showSearchBar
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: Row(
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      uiManager.appBarTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    if (suppliers.length > 1)
                      uiManager.buildSupplierBadge(suppliers.length, theme),
                  ],
                ),
                secondChild: Container(
                  height: kToolbarHeight,
                  child: Row(
                    children: [
                      Expanded(
                        child: SearchBar(
                          controller: uiManager.searchController,
                          focusNode: uiManager.searchFocusNode,
                          onClear: uiManager.toggleSearchBar,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                if (!uiManager.showSearchBar)
                  IconButton(
                    icon: badges.Badge(
                      showBadge: uiManager.selectedFilter != 'all',
                      badgeStyle: badges.BadgeStyle(
                        badgeColor: theme.colorScheme.error,
                      ),
                      child: Icon(
                        Icons.filter_alt_outlined,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    onPressed: uiManager.toggleFilters,
                  ),
                IconButton(
                  icon: Icon(
                    uiManager.showSearchBar ? Icons.close : Icons.search,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: uiManager.toggleSearchBar,
                ),
                const SizedBox(width: 4),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(100),
                child: Column(
                  children: [
                    if (uiManager.showFilters)
                      uiManager.buildFilterChips(context),
                    SupplierSelector(
                      // uiManager: uiManager,
                      // suppliers: suppliers,
                      onSupplierChanged: (supplierId) {
                        setState(() {
                          uiManager.selectSupplier(supplierId, context);
                        });
                      },
                      accessibleSuppliers: suppliers,
                    ),
                    SizedBox(
                      height: 8,
                    ),
                    TabBar(
                      controller: uiManager.tabController,
                      isScrollable: true,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                      dividerColor: Colors.transparent,
                      tabs: uiManager.tabConfigs.map((config) {
                        return uiManager.buildTab(
                          config['label'] as String,
                          config['icon'] as IconData,
                          config['color'] as Color,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: RefreshIndicator.adaptive(
          onRefresh: () async => uiManager.refreshOrders(context),
          child: TabBarView(
            controller: uiManager.tabController,
            children: [
              OrderListView(
                uiManager: uiManager,
                status: null,
                tabIndex: 0,
              ),
              OrderListView(
                uiManager: uiManager,
                status: 'pending',
                tabIndex: 1,
              ),
              OrderListView(
                uiManager: uiManager,
                status: 'processing',
                tabIndex: 2,
              ),
              OrderListView(
                uiManager: uiManager,
                status: 'completed',
                tabIndex: 3,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: uiManager.fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: () => showNewOrderSheet(),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: const Icon(Icons.add),
          label: Text(uiManager.localizations.createNew),
        ),
      ),
    );
  }

  void showNewOrderSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NewOrderSheet(),
    );
  }
}

class SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onClear;

  const SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.search,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              Icons.clear,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            onPressed: onClear,
          ),
          hintText: 'Search orders...',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        style: theme.textTheme.bodyMedium,
      ),
    );
  }
}

// class SupplierSelector extends StatelessWidget {
//   final OrderUIManager uiManager;
//   final List<ProductProvider> suppliers;
//   final Function(int?) onSupplierChanged;

//   const SupplierSelector({
//     required this.uiManager,
//     required this.suppliers,
//     required this.onSupplierChanged,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     if (!uiManager.canView && !uiManager.canManage) {
//       return buildNoPermissionCard(theme);
//     }

//     if (suppliers.isEmpty) {
//       return buildNoSuppliersCard(theme);
//     }

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.only(left: 4, bottom: 8),
//             child: Text(
//               'Selected Supplier',
//               style: theme.textTheme.labelSmall?.copyWith(
//                 color: theme.colorScheme.onSurfaceVariant,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//           Container(
//             decoration: BoxDecoration(
//               color: theme.colorScheme.surfaceVariant,
//               borderRadius: BorderRadius.circular(16),
//               border: Border.all(
//                 color: theme.colorScheme.outline.withOpacity(0.2),
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: theme.colorScheme.shadow.withOpacity(0.1),
//                   blurRadius: 8,
//                   offset: const Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: DropdownButton<int?>(
//                 isExpanded: true,
//                 value: uiManager.selectedSupplierId,
//                 underline: const SizedBox(),
//                 borderRadius: BorderRadius.circular(12),
//                 padding: const EdgeInsets.symmetric(vertical: 12),
//                 dropdownColor: theme.colorScheme.surface,
//                 icon: Icon(
//                   Icons.arrow_drop_down,
//                   color: theme.colorScheme.primary,
//                   size: 24,
//                 ),
//                 hint: Text(
//                   uiManager.localizations.selectSupplier,
//                   style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
//                 ),
//                 items: suppliers.map((supplier) {
//                   return DropdownMenuItem<int?>(
//                     value: supplier.id_product_provider,
//                     child: Row(
//                       children: [
//                         Container(
//                           width: 32,
//                           height: 32,
//                           decoration: BoxDecoration(
//                             color: theme.colorScheme.primary.withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: Icon(
//                             Icons.storefront,
//                             size: 16,
//                             color: theme.colorScheme.primary,
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 supplier.product_provider_details.provider_name,
//                                 style: theme.textTheme.bodyMedium?.copyWith(
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 }).toList(),
//                 onChanged: onSupplierChanged,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget buildNoPermissionCard(ThemeData theme) {
//     return Container(
//       margin: const EdgeInsets.all(16),
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: theme.colorScheme.errorContainer.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: theme.colorScheme.errorContainer,
//           width: 1.5,
//         ),
//       ),
//       child: Column(
//         children: [
//           Icon(
//             Icons.lock_outline,
//             size: 48,
//             color: theme.colorScheme.error,
//           ),
//           const SizedBox(height: 12),
//           Text(
//             uiManager.localizations.noOrderManagementPrivileges,
//             style: theme.textTheme.titleMedium?.copyWith(
//               color: theme.colorScheme.error,
//               fontWeight: FontWeight.w600,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Contact your administrator to request access',
//             style: theme.textTheme.bodyMedium?.copyWith(
//               color: theme.colorScheme.onSurfaceVariant,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget buildNoSuppliersCard(ThemeData theme) {
//     return Container(
//       margin: const EdgeInsets.all(16),
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: theme.colorScheme.surfaceVariant,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: theme.colorScheme.outline.withOpacity(0.3),
//           width: 1.5,
//         ),
//       ),
//       child: Column(
//         children: [
//           Icon(
//             Icons.storefront_outlined,
//             size: 48,
//             color: theme.colorScheme.onSurfaceVariant,
//           ),
//           const SizedBox(height: 12),
//           Text(
//             'No Accessible Suppliers',
//             style: theme.textTheme.titleMedium?.copyWith(
//               color: theme.colorScheme.onSurface,
//               fontWeight: FontWeight.w600,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'You don\'t have access to any suppliers for order management.',
//             style: theme.textTheme.bodyMedium?.copyWith(
//               color: theme.colorScheme.onSurfaceVariant,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }
// }

class OrderListView extends StatefulWidget {
  final OrderUIManager uiManager;
  final String? status;
  final int tabIndex;

  const OrderListView({
    required this.uiManager,
    this.status,
    required this.tabIndex,
  });

  @override
  State<OrderListView> createState() => OrderListViewState();
}

class OrderListViewState extends State<OrderListView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final orderNotifier = context.watch<OrderChangeNotifier>();

    if (orderNotifier.isLoading) {
      return buildLoadingShimmer();
    }

    List<Order> orders = widget.uiManager.filterOrders(
      orderNotifier.orders,
      widget.status,
    );

    if (orders.isEmpty) {
      return EmptyState(
        uiManager: widget.uiManager,
        status: widget.status,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return OrderCard(
          uiManager: widget.uiManager,
          order: orders[index],
          index: index,
        );
      },
    );
  }

  Widget buildLoadingShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          height: 120,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }
}

class OrderCard extends StatelessWidget {
  final OrderUIManager uiManager;
  final Order order;
  final int index;

  const OrderCard({
    required this.uiManager,
    required this.order,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = uiManager.getStatusColor(order.status, theme);
    final statusIcon = uiManager.getStatusIcon(order.status);
    final isOverdue = uiManager.isOrderOverdue(order);

    return GestureDetector(
      onTap: () => showOrderDetail(context),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isOverdue
                ? Colors.red.withOpacity(0.3)
                : theme.colorScheme.outline.withOpacity(0.1),
            width: isOverdue ? 1.5 : 1,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: isOverdue
                ? LinearGradient(
                    colors: [
                      Colors.red.withOpacity(0.03),
                      Colors.red.withOpacity(0.01),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Indicator
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: statusColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Order Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Order #${order.idPlacedOrder}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          if (isOverdue)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    size: 14,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Overdue',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Order Info Row
                      Row(
                        children: [
                          InfoChip(
                            icon: Icons.attach_money_rounded,
                            text: uiManager.localizations
                                .price(order.totalPrice.toStringAsFixed(2)),
                            color: Colors.green,
                          ),
                          const SizedBox(width: 12),
                          InfoChip(
                            icon: Icons.shopping_bag_rounded,
                            text: '${order.itemCount} items',
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 12),
                          InfoChip(
                            icon: Icons.person_outline_rounded,
                            text: 'Customer #${order.orderingUserId}',
                            color: Colors.purple,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Status and Actions
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  statusIcon,
                                  size: 14,
                                  color: statusColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  order.status.toUpperCase(),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            uiManager
                                .formatOrderDate(order.placedOrderCreation),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void showOrderDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(
          // uiManager: uiManager,
          order: order,
        ),
      ),
    );
  }
}

class InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const InfoChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final OrderUIManager uiManager;
  final String? status;

  const EmptyState({
    required this.uiManager,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = uiManager.getStatusIcon(status ?? 'all');
    final message = uiManager.getEmptyMessage(status);
    final subMessage = uiManager.getEmptySubMessage();
    final color = uiManager.getStatusColor(status ?? 'all', theme);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.15),
                    color.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                icon,
                size: 60,
                color: color,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              message,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subMessage,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (uiManager.searchController.text.isNotEmpty)
              FilledButton.icon(
                onPressed: uiManager.toggleSearchBar,
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear Search'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class NewOrderSheet extends StatelessWidget {
  const NewOrderSheet();

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

// Helper Functions
