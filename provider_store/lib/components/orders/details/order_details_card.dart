import 'package:flutter/material.dart';
import 'package:verdelia_core/app/Address.dart';
import 'package:verdelia_core/app/Person.dart';
import 'package:verdelia_core/business/Delivery.dart';
import 'package:verdelia_core/business/finance/Order.dart';
import 'package:provider_store/components/selling_point/checkout/delivery_section.dart';

class OrderDetailsCard extends StatefulWidget {
  final Order order;
  final Person? customer;
  final Address? customerAddress;
  final ValueChanged<DeliveryData>? onDeliveryDataChanged;
  final bool showDeliveryTab;
  final bool isEditable;

  const OrderDetailsCard({
    super.key,
    required this.order,
    this.customer,
    this.customerAddress,
    this.onDeliveryDataChanged,
    this.showDeliveryTab = true,
    this.isEditable = false,
  });

  @override
  State<OrderDetailsCard> createState() => _OrderDetailsCardState();
}

class _OrderDetailsCardState extends State<OrderDetailsCard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedDeliveryType = 'pickup';
  DeliveryData? _deliveryData;
  bool _isFirstBuild = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.showDeliveryTab ? 2 : 1,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPending = widget.order.isPending;
    final isPaid = widget.order.isPaid;

    // Prevent premature layout issues
    if (_isFirstBuild) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _isFirstBuild = false;
        });
      });
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          // Header with Tabs
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Icon(
                          Icons.receipt_long_rounded,
                          color: theme.colorScheme.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order Details',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Order #${widget.order.idPlacedOrder} • ${widget.order.status.toUpperCase()}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isPending && widget.isEditable)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit_note,
                                size: 14,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Editable',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (widget.showDeliveryTab)
                  TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorColor: theme.colorScheme.primary,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                    unselectedLabelStyle:
                        const TextStyle(fontWeight: FontWeight.normal),
                    // IMPORTANT: Prevent premature hit testing
                    physics: _isFirstBuild
                        ? const NeverScrollableScrollPhysics()
                        : null,
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Text('Order Info'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_shipping_outlined,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Text('Delivery'),
                            if (widget.order.hasItems() &&
                                widget.order.items!
                                    .any((item) => item.hasDeliveryFee))
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${widget.order.items!.where((item) => item.hasDeliveryFee).length}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Tab Content - Use Expanded only if parent has constraints
          if (_isFirstBuild)
            // Show loading skeleton during first build
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else
            Expanded(
              child: TabBarView(
                controller: _tabController,
                // IMPORTANT: Disable physics during initial build
                physics: _isFirstBuild
                    ? const NeverScrollableScrollPhysics()
                    : const ClampingScrollPhysics(),
                children: [
                  // Tab 1: Order Details Grid - Use SingleChildScrollView for safety
                  SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: _buildOrderDetailsGrid(theme),
                  ),

                  // Tab 2: Delivery Section
                  if (widget.showDeliveryTab)
                    DeliverySection(
                      selectedType: _selectedDeliveryType,
                      onChanged: (type) {
                        setState(() => _selectedDeliveryType = type);
                      },
                      onDeliveryDataChanged: (data) {
                        setState(() => _deliveryData = data);
                        widget.onDeliveryDataChanged?.call(data);
                      },
                      customer: widget.customer,
                      customerAddress: widget.customerAddress,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailsGrid(ThemeData theme) {
    final order = widget.order;
    final items = order.items ?? [];
    final hasDeliveryItems = items.any((item) => item.hasDeliveryFee);
    final totalDeliveryFee = items.fold(
        0.0, (sum, item) => sum + (item.orderedItemDeliveryFee ?? 0));
    final totalVat = items.fold(0.0, (sum, item) => sum + item.vatAmount);
    final totalDiscount = order.orderDiscount ?? 0;

    // Grid items configuration
    final gridItems = [
      _GridItem(
        title: 'Order Total',
        value: 'DZD ${order.totalPrice.toStringAsFixed(2)}',
        icon: Icons.attach_money_rounded,
        color: Colors.green,
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.15),
            Colors.green.withOpacity(0.05),
          ],
        ),
      ),
      _GridItem(
        title: 'Net Amount',
        value: 'DZD ${order.netPrice.toStringAsFixed(2)}',
        icon: Icons.account_balance_wallet_outlined,
        color: Colors.blue,
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.15),
            Colors.blue.withOpacity(0.05),
          ],
        ),
      ),
      _GridItem(
        title: 'Items Count',
        value: '${order.itemCount} items',
        subtitle: '${order.totalQuantity} units',
        icon: Icons.shopping_bag_rounded,
        color: Colors.purple,
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.15),
            Colors.purple.withOpacity(0.05),
          ],
        ),
      ),
      _GridItem(
        title: 'Payment',
        value: order.paymentStatus?.toUpperCase() ?? 'PENDING',
        subtitle: order.paymentMethod ?? 'Not specified',
        icon: _getPaymentIcon(order.paymentStatus),
        color: _getPaymentColor(order.paymentStatus),
        gradient: LinearGradient(
          colors: [
            _getPaymentColor(order.paymentStatus).withOpacity(0.15),
            _getPaymentColor(order.paymentStatus).withOpacity(0.05),
          ],
        ),
      ),
      if (totalDiscount > 0)
        _GridItem(
          title: 'Discount',
          value: '-DZD ${totalDiscount.toStringAsFixed(2)}',
          icon: Icons.local_offer_outlined,
          color: Colors.orange,
          gradient: LinearGradient(
            colors: [
              Colors.orange.withOpacity(0.15),
              Colors.orange.withOpacity(0.05),
            ],
          ),
        ),
      if (totalVat > 0)
        _GridItem(
          title: 'Total VAT',
          value: 'DZD ${totalVat.toStringAsFixed(2)}',
          subtitle:
              '${(items.map((e) => e.appliedVat).reduce((a, b) => a + b) / items.length).toStringAsFixed(1)}% avg',
          icon: Icons.request_quote_outlined,
          color: Colors.teal,
          gradient: LinearGradient(
            colors: [
              Colors.teal.withOpacity(0.15),
              Colors.teal.withOpacity(0.05),
            ],
          ),
        ),
      if (hasDeliveryItems)
        _GridItem(
          title: 'Delivery Fee',
          value: '+DZD ${totalDeliveryFee.toStringAsFixed(2)}',
          subtitle:
              '${items.where((item) => item.hasDeliveryFee).length} items',
          icon: Icons.local_shipping,
          color: Colors.deepOrange,
          gradient: LinearGradient(
            colors: [
              Colors.deepOrange.withOpacity(0.15),
              Colors.deepOrange.withOpacity(0.05),
            ],
          ),
        ),
      _GridItem(
        title: 'Created Date',
        value: _formatDate(order.placedOrderCreation),
        subtitle: _formatTime(order.placedOrderCreation),
        icon: Icons.calendar_today_rounded,
        color: Colors.indigo,
        gradient: LinearGradient(
          colors: [
            Colors.indigo.withOpacity(0.15),
            Colors.indigo.withOpacity(0.05),
          ],
        ),
      ),
      _GridItem(
        title: 'Last Updated',
        value: _formatDate(order.placedOrderLastMod),
        subtitle: _formatRelativeTime(order.placedOrderLastMod),
        icon: Icons.update_rounded,
        color: Colors.pink,
        gradient: LinearGradient(
          colors: [
            Colors.pink.withOpacity(0.15),
            Colors.pink.withOpacity(0.05),
          ],
        ),
      ),
    ];

    // Use Container instead of Padding to avoid layout issues
    return Container(
      padding: const EdgeInsets.all(20),
      child: GridView.builder(
        shrinkWrap: true, // IMPORTANT for nested scroll views
        physics:
            const NeverScrollableScrollPhysics(), // Prevent nested scrolling
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemCount: gridItems.length,
        itemBuilder: (context, index) {
          final item = gridItems[index];
          return _buildGridCard(theme, item);
        },
      ),
    );
  }

  Widget _buildGridCard(ThemeData theme, _GridItem item) {
    // Use a StatefulBuilder to manage hover state safely
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;

        return MouseRegion(
          onEnter: (_) {
            if (!_isFirstBuild) {
              setState(() => isHovered = true);
            }
          },
          onExit: (_) {
            if (!_isFirstBuild) {
              setState(() => isHovered = false);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: item.gradient,
              border: Border.all(
                color: item.color.withOpacity(isHovered ? 0.3 : 0.2),
                width: isHovered ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow
                      .withOpacity(isHovered ? 0.1 : 0.05),
                  blurRadius: isHovered ? 12 : 8,
                  offset: Offset(0, isHovered ? 4 : 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _isFirstBuild
                    ? null
                    : () {
                        // Handle tap if needed
                      },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: item.color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              item.icon,
                              size: 20,
                              color: item.color,
                            ),
                          ),
                          const Spacer(),
                          if (item.showBadge ?? false)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: item.color.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'NEW',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: item.color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item.title,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.value,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const Spacer(),
                      // Progress indicator for payment status
                      if (item.title == 'Payment' && widget.order.isPending)
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: item.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: FractionallySizedBox(
                            widthFactor: 0.6, // 60% progress
                            child: Container(
                              decoration: BoxDecoration(
                                color: item.color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper Methods
  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  IconData _getPaymentIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid':
        return Icons.check_circle_outline;
      case 'pending':
        return Icons.access_time;
      case 'failed':
        return Icons.error_outline;
      case 'refunded':
        return Icons.rotate_left;
      default:
        return Icons.payment;
    }
  }

  Color _getPaymentColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

class _GridItem {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final LinearGradient gradient;
  final bool? showBadge;

  _GridItem({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.gradient,
    this.showBadge,
  });
}
