import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/app/ManagementRule.dart';
import 'package:verdelia_core/business/finance/Order.dart';
import 'package:verdelia_core/business/Supplier.dart';
import 'package:verdelia_core/business/privileges/Privileges.dart';
import 'package:event/order_change_notifier.dart';
import 'package:provider/provider.dart';
import 'package:event/cart_change_notifier.dart';
import 'package:event/personnel_notifier.dart';

class OrderUIManager {
  // State Management
  late TabController tabController;
  late AnimationController fabAnimationController;
  late Animation<double> fabAnimation;
  bool showSearchBar = false;
  bool showFilters = false;
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  final ScrollController scrollController = ScrollController();
  String selectedFilter = 'all';
  int? selectedSupplierId;

  // Screen Configuration
  final PrivilegeLevel privilegeLevel;
  final int userId;
  final List<int> accessibleSuppliers;
  final PersonnelNotifier personnelNotifier;

  // Localized texts
  late AppLocalizations localizations;

  // Computed properties
  bool get canManage => privilegeLevel == PrivilegeLevel.manage;
  bool get canView => privilegeLevel == PrivilegeLevel.view;

  OrderUIManager({
    required this.privilegeLevel,
    required this.userId,
    required this.accessibleSuppliers,
    required this.personnelNotifier,
    required TickerProvider vsync,
  }) {
    tabController = TabController(length: 4, vsync: vsync);
    fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: vsync,
    );
    fabAnimation = CurvedAnimation(
      parent: fabAnimationController,
      curve: Curves.easeInOut,
    );
  }

  // Initialization
  void initialize(BuildContext context) {
    localizations = AppLocalizations.of(context)!;
    _setupScrollListener();
    _initializeSupplier(context);
  }

  void _setupScrollListener() {
    scrollController.addListener(() {
      if (scrollController.offset > 100 &&
          !fabAnimationController.isAnimating) {
        fabAnimationController.forward();
      } else if (scrollController.offset <= 100 &&
          !fabAnimationController.isAnimating) {
        fabAnimationController.reverse();
      }
    });
  }

  void _initializeSupplier(BuildContext context) {
    final userRules = personnelNotifier.getRulesForUser(userId);

    for (final rule in userRules) {
      if (!rule.isActive) continue;

      final ruleCode = rule.managementRuleCode ?? 0;
      final hasPrivilege = canManage
          ? _checkPrivilege(ruleCode, 'orders_manage')
          : _checkPrivilege(ruleCode, 'orders_view');

      if (hasPrivilege) {
        final supplierId = rule.productProvider?.idProductProvider;
        if (supplierId != null) {
          selectedSupplierId = supplierId;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<OrderChangeNotifier>().fetchOrders(
                  appUserId: supplierId,
                  reset: true,
                );
          });
          break;
        }
      }
    }
  }

  bool _checkPrivilege(int ruleCode, String privilegeId) {
    return true; // TODO: Implement actual privilege check
  }

  // Supplier Management
  void selectSupplier(int? supplierId, BuildContext context) {
    if (selectedSupplierId != supplierId) {
      selectedSupplierId = supplierId;

      if (supplierId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<OrderChangeNotifier>().fetchOrders(
                appUserId: supplierId,
                reset: true,
              );
        });
      }
    }
  }

  List<ProductProvider> getAccessibleSuppliers() {
    final userRules = personnelNotifier.getRulesForUser(userId);
    final suppliers = <ProductProvider>[];
    final supplierIds = <int>{};

    for (final rule in userRules) {
      if (!rule.isActive) continue;

      final ruleCode = rule.managementRuleCode ?? 0;
      final hasPrivilege = canManage
          ? _checkPrivilege(ruleCode, 'orders_manage')
          : _checkPrivilege(ruleCode, 'orders_view');

      if (hasPrivilege) {
        final supplier = rule.productProvider;
        if (supplier != null &&
            !supplierIds.contains(supplier.idProductProvider)) {
          supplierIds.add(supplier.idProductProvider);
          suppliers.add(supplier);
        }
      }
    }

    return suppliers;
  }

  // Search & Filter Management
  void toggleSearchBar() {
    showSearchBar = !showSearchBar;
    if (showSearchBar) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => searchFocusNode.requestFocus());
    } else {
      searchController.clear();
      searchFocusNode.unfocus();
    }
  }

  void toggleFilters() {
    showFilters = !showFilters;
  }

  void applyFilter(String filter) {
    selectedFilter = filter;
    showFilters = false;
  }

  List<String> get filterOptions =>
      ['all', 'today', 'week', 'month', 'overdue', 'urgent'];

  // Order Data Management
  void refreshOrders(BuildContext context) {
    if (selectedSupplierId != null) {
      context.read<OrderChangeNotifier>().fetchOrders(
            appUserId: selectedSupplierId!,
            reset: true,
          );
    }
  }

  List<Order> filterOrders(List<Order> orders, String? status) {
    List<Order> filtered = orders;

    // Apply status filter
    if (status != null) {
      filtered = filtered.where((order) {
        return order.status.toLowerCase() == status.toLowerCase();
      }).toList();
    }

    // Apply search filter
    if (searchController.text.isNotEmpty) {
      filtered = filtered.where((order) {
        final query = searchController.text.toLowerCase();
        return order.idPlacedOrder.toString().contains(query) ||
            order.totalPrice.toString().contains(query) ||
            order.status.toLowerCase().contains(query);
      }).toList();
    }

    // Apply time filter
    filtered = _applyTimeFilter(filtered);

    return filtered;
  }

  List<Order> _applyTimeFilter(List<Order> orders) {
    final now = DateTime.now();
    switch (selectedFilter) {
      case 'today':
        return orders.where((order) {
          return order.placedOrderCreation.day == now.day &&
              order.placedOrderCreation.month == now.month &&
              order.placedOrderCreation.year == now.year;
        }).toList();
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return orders.where((order) {
          return order.placedOrderCreation.isAfter(weekAgo);
        }).toList();
      case 'month':
        final monthAgo = now.subtract(const Duration(days: 30));
        return orders.where((order) {
          return order.placedOrderCreation.isAfter(monthAgo);
        }).toList();
      case 'overdue':
        return orders.where((order) {
          return order.status == 'pending' &&
              order.placedOrderCreation
                  .isBefore(now.subtract(const Duration(days: 3)));
        }).toList();
      case 'urgent':
        return orders.where((order) {
          return order.status == 'pending' &&
              order.placedOrderCreation
                  .isBefore(now.subtract(const Duration(days: 1)));
        }).toList();
      default:
        return orders;
    }
  }

  // UI Text Methods
  String get appBarTitle => localizations.ordersText;

  List<Map<String, dynamic>> get tabConfigs => [
        {
          'label': 'All',
          'icon': Icons.all_inclusive,
          'color': Colors.blue,
        },
        {
          'label': localizations.pendingTxt,
          'icon': Icons.access_time,
          'color': Colors.orange,
        },
        {
          'label': localizations.processingTxt,
          'icon': Icons.local_shipping,
          'color': Colors.blue,
        },
        {
          'label': localizations.completedTxt,
          'icon': Icons.check_circle,
          'color': Colors.green,
        },
      ];

  String getEmptyMessage(String? status) {
    if (searchController.text.isNotEmpty) {
      return 'No results for "${searchController.text}"';
    }

    if (selectedFilter != 'all') {
      return 'No $selectedFilter orders';
    }

    switch (status?.toLowerCase()) {
      case 'pending':
        return localizations.noPendingOrders;
      case 'processing':
        return localizations.noProcessingOrders;
      case 'completed':
        return localizations.noCompletedOrders;
      default:
        return localizations.noOrdersFound;
    }
  }

  String getEmptySubMessage() {
    if (searchController.text.isNotEmpty) {
      return 'Try different keywords or filters';
    }

    if (selectedFilter != 'all') {
      return 'Try changing the time filter';
    }

    return localizations.noOrdersFoundForStatus;
  }

  // Order Status Utilities
  Color getStatusColor(String status, ThemeData theme) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return theme.colorScheme.primary;
    }
  }

  IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.access_time_filled_rounded;
      case 'processing':
        return Icons.local_shipping_rounded;
      case 'completed':
        return Icons.check_circle_rounded;
      default:
        return Icons.shopping_bag_rounded;
    }
  }

  String formatOrderDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  bool isOrderOverdue(Order order) {
    final now = DateTime.now();
    return order.status == 'pending' &&
        order.placedOrderCreation
            .isBefore(now.subtract(const Duration(days: 3)));
  }

  // Widget Builders
  Widget buildSupplierBadge(int count, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.storefront,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            '$count ${count == 1 ? 'Supplier' : 'Suppliers'}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTab(String label, IconData icon, Color color) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget buildFilterChips(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filterOptions.map((filter) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  filter[0].toUpperCase() + filter.substring(1),
                  style: TextStyle(
                    fontWeight: selectedFilter == filter
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                selected: selectedFilter == filter,
                onSelected: (_) => applyFilter(filter),
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                checkmarkColor: Theme.of(context).colorScheme.primary,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Cleanup
  void dispose() {
    tabController.dispose();
    fabAnimationController.dispose();
    searchController.dispose();
    searchFocusNode.dispose();
    scrollController.dispose();
  }
}

// Now let's refactor the main widget to use the OrderUIManager
