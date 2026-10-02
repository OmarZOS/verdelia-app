import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:app_constants/app_constants.dart';
import 'package:verdelia_core/business/finance/Order.dart';
import 'package:event/order_change_notifier.dart';
import 'package:event/user_change_notifier.dart';
import 'package:provider/provider.dart';
import 'package:event/cart_change_notifier.dart';
import 'package:intl/intl.dart';

class OrdersScreen extends StatefulWidget {
  final OrderChangeNotifier? cartChangeNotifier;
  OrdersScreen({Key? key, required this.cartChangeNotifier}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    // Load orders once when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  Future<void> _loadOrders() async {
    if (!mounted) return;

    final userId = Provider.of<AppUserNotifier>(context, listen: false)
        .appUser!
        .idAppUser!;

    // Use the provided cartChangeNotifier or get from context
    if (widget.cartChangeNotifier != null) {
      await widget.cartChangeNotifier!.fetchOrders(appUserId: userId);
    } else {
      await Provider.of<OrderChangeNotifier>(context, listen: false)
          .fetchOrders(appUserId: userId);
    }

    if (mounted) {
      setState(() => _isInitialLoad = false);
    }
  }

  Future<void> _refreshOrders() async {
    final userId = Provider.of<AppUserNotifier>(context, listen: false)
        .appUser!
        .idAppUser!;

    if (widget.cartChangeNotifier != null) {
      await widget.cartChangeNotifier!.fetchOrders(appUserId: userId);
    } else {
      await Provider.of<OrderChangeNotifier>(context, listen: false)
          .fetchOrders(appUserId: userId);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.ordersText),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<OrderChangeNotifier>(
        builder: (context, cartNotifier, child) {
          // Handle initial loading
          if (_isInitialLoad && cartNotifier.orders.isEmpty) {
            return _buildLoadingState(theme);
          }

          final orders = cartNotifier.orders;

          if (orders.isEmpty) {
            return _buildEmptyState(loc, theme);
          }

          return RefreshIndicator(
            onRefresh: _refreshOrders,
            color: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.surface,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Header with order count
                SliverToBoxAdapter(
                  child: _buildHeader(orders.length, loc, theme, orders),
                ),

                // Orders list
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final order = orders[index];
                      return _buildOrderCard(order, loc, theme, context);
                    },
                    childCount: orders.length,
                  ),
                ),

                // Bottom padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: 20),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your orders...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations loc, ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _refreshOrders,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 80,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 20),
              Text(
                loc.noOrdersTxt,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                loc.yourOrdersWillAppearHere,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _refreshOrders,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(loc.refreshTxt),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateTotalPaid(List<dynamic> orders) {
    return orders.fold(0.0, (sum, order) {
      final price = order.totalPrice is double
          ? order.totalPrice
          : double.tryParse(order.totalPrice?.toString() ?? '0') ?? 0.0;
      return sum + price;
    });
  }

  Widget _buildHeader(
    int orderCount,
    AppLocalizations loc,
    ThemeData theme,
    List<dynamic> orders,
  ) {
    final totalPaid = _calculateTotalPaid(orders);
    final completedOrders = orders
        .where((order) =>
            (order.status ?? '') == OrderStates.COMPLETED_ORDER_STATE)
        .length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.analytics_outlined,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),

          // Stats section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.yourOrderStats,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                const SizedBox(height: 8),

                // Mini stats row that wraps if needed
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _buildMiniStat(
                      value: orderCount.toString(),
                      label: loc.ordersText,
                      theme: theme,
                    ),
                    _buildMiniStat(
                      value: loc.price(totalPaid.toStringAsFixed(0)),
                      label: loc.spentTxt,
                      theme: theme,
                    ),
                    _buildMiniStat(
                      value: completedOrders.toString(),
                      label: loc.completedTxt,
                      theme: theme,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Achievement badge (keeps its space minimal)
          if (orderCount >= 5) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Icon(
                Icons.emoji_events,
                color: Colors.amber,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required String value,
    required String label,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(Order order, AppLocalizations loc, ThemeData theme,
      BuildContext context) {
    final dateFormat =
        DateFormat('HH:mm dd-MM-yyyy'); // Example: 05 Oct 2025, 19:02

    final orderDate = order.placedOrderLastMod;
    // (order.orderedTimestamp != null &&
    //         order.orderedTimestamp != "")
    //     ? dateFormat.format(DateTime.parse(order.orderedTimestamp.toString()))
    //     : loc.dateTimeNotAvailable;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Navigate to order details
            _showOrderDetails(order, loc, theme, context);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        loc.orderIdentifierTxt(order.idPlacedOrder.toString()),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildStatusChip(order.status, theme, loc),
                  ],
                ),
                const SizedBox(height: 12),

                // Order details
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      loc.dateTimeFormat(
                          (orderDate.day < 10)
                              ? '0${orderDate.day}'
                              : orderDate.day,
                          (orderDate.hour < 10)
                              ? '0${orderDate.hour}'
                              : orderDate.hour,
                          (orderDate.minute < 10)
                              ? '0${orderDate.minute}'
                              : orderDate.minute,
                          (orderDate.month < 10)
                              ? '0${orderDate.month}'
                              : orderDate.month,
                          orderDate.year), // orderDate,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Price row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      loc.totalTxt,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      loc.price(order.totalPrice?.toStringAsFixed(2) ?? '0.00'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),

                // Action buttons
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showOrderDetails(order, loc, theme, context);
                        },
                        icon: Icon(
                          Icons.remove_red_eye_outlined,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        label: Text(
                          loc.viewDetails,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: BorderSide(
                              color:
                                  theme.colorScheme.primary.withOpacity(0.3)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // IconButton(
                    //   onPressed: () {
                    //     _showDeleteDialog(order, loc, theme, context);
                    //   },
                    //   icon: Icon(
                    //     Icons.delete_outline,
                    //     size: 20,
                    //     color: theme.colorScheme.error.withOpacity(0.7),
                    //   ),
                    //   style: IconButton.styleFrom(
                    //     backgroundColor:
                    //         theme.colorScheme.error.withOpacity(0.1),
                    //     padding: const EdgeInsets.all(8),
                    //   ),
                    // ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(
      String? status, ThemeData theme, AppLocalizations loc) {
    final statusColor = _getStatusColor(status, theme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Text(
        _getStatusText(status, loc).toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: statusColor,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _getStatusText(String? status, AppLocalizations loc) {
    switch (status?.toUpperCase()) {
      case OrderStates.COMPLETED_ORDER_STATE:
        return loc.completedTxt;
      case OrderStates.DELIVERED_ORDER_STATE:
        return loc.deliveredTxt;
      case OrderStates.PENDING_ORDER_STATE:
        return loc.pendingTxt;
      case OrderStates.CANCELLED_ORDER_STATE:
        return loc.cancelledTxt;
      case OrderStates.PROCESSING_ORDER_STATE:
        return loc.processingTxt;
      default:
        return loc.unknownTxt;
    }
  }

  Color _getStatusColor(String? status, ThemeData theme) {
    switch (status?.toUpperCase()) {
      case OrderStates.COMPLETED_ORDER_STATE:
      case OrderStates.DELIVERED_ORDER_STATE:
        return Colors.green;
      case OrderStates.PENDING_ORDER_STATE:
        return Colors.orange;
      case OrderStates.CANCELLED_ORDER_STATE:
        return Colors.red;
      case OrderStates.PROCESSING_ORDER_STATE:
        return theme.colorScheme.primary;
      default:
        return theme.colorScheme.onSurface.withOpacity(0.5);
    }
  }

  void _showOrderDetails(Order order, AppLocalizations loc, ThemeData theme,
      BuildContext context) async {
    // Show loading bottom sheet first
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Loading order details...',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // Fetch details asynchronously
      await widget.cartChangeNotifier!
          .fetchOrderDetails(orderId: order.idPlacedOrder);

      // Close the loading sheet
      Navigator.pop(context);

      // Now show the actual details sheet
      _showOrderDetailsSheet(order, loc, theme, context);
    } catch (e) {
      // Close loading sheet on error
      Navigator.pop(context);

      // Show error sheet
      _showErrorSheet(e.toString(), loc, theme, context);
    }
  }

  void _showOrderDetailsSheet(Order order, AppLocalizations loc,
      ThemeData theme, BuildContext context) {
    final detailedOrder =
        widget.cartChangeNotifier!.getOrderWithDetails(order.idPlacedOrder);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: detailedOrder == null || !detailedOrder.hasItems()
            ? _buildErrorState(loc.failedToLoadDetails, theme, loc)
            : _buildOrderDetailsContent(detailedOrder, loc, theme, context),
      ),
    );
  }

  void _showErrorSheet(String error, AppLocalizations loc, ThemeData theme,
      BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                loc.failedToLoadDetails,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  error,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(loc.close),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderDetailsContent(Order? order, AppLocalizations loc,
      ThemeData theme, BuildContext context) {
    return Column(
      children: [
        // Drag handle
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              Text(
                loc.order_number(order?.idPlacedOrder.toString() ?? "0"),
                // "${loc.orderFor} #${}",
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                "${loc.totalTxt}: ${loc.price((order?.totalPrice ?? 0.0).toStringAsFixed(2))}",
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Divider(color: theme.colorScheme.outlineVariant),
              const SizedBox(height: 8),

              // Order status
              Row(
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getStatusText(order?.status ?? "", loc),
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Order items
              Text(
                loc.orderItemsTxt, // Make sure this exists in your AppLocalizations
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (order != null)
                ...order.items!
                    .map((item) => _buildOrderItemCard(item, theme, loc)),

              const SizedBox(height: 24),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_outlined),
                  label: Text(loc.close),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    iconColor: theme.colorScheme.onPrimary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItemCard(
      OrderedItem item, ThemeData theme, AppLocalizations loc) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.shopping_bag_outlined,
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(item.orderedProduct?.productName ?? ""),
        subtitle: Text(loc.qtyTxt(item.orderedQuantity,
            loc.price(item.unitPrice.toStringAsFixed(2)))),
        trailing: Text(
          loc.price(item.totalPrice.toStringAsFixed(2)),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, ThemeData theme, AppLocalizations loc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            loc.failedToLoadDetails,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Order order, AppLocalizations loc, ThemeData theme,
      BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Order?',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete order #${order.idPlacedOrder}? This action cannot be undone.',
          style: theme.textTheme.bodyMedium,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              loc.cancelTxt,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement delete functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Order #${order.idPlacedOrder} deleted'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
