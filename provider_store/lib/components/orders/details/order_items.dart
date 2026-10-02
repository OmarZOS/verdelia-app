import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/app/ManagementRule.dart';
import 'package:verdelia_core/business/finance/Order.dart';
import 'package:verdelia_core/business/Supplier.dart';
import 'package:verdelia_core/business/privileges/Privileges.dart';
import 'package:provider_store/components/orders/details/customer_details_card.dart';
import 'package:provider_store/components/orders/details/order_items.dart';
import 'package:ui/components/finance/financial_ui_manager.dart';
import 'package:ui/components/order/order_ui_manager.dart';
import 'package:event/order_change_notifier.dart';
import 'package:provider/provider.dart';
import 'package:event/cart_change_notifier.dart';
import 'package:event/personnel_notifier.dart';
import 'package:badges/badges.dart' as badges;

import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/business/finance/Order.dart';
import 'package:ui/components/order/order_ui_manager.dart';

class OrderItemsCard extends StatefulWidget {
  final Order order;
  final bool showActions;
  final Function(OrderedItem)? onItemTap;
  final Function(OrderedItem, int)? onQuantityUpdate;
  final bool isEditable;

  const OrderItemsCard({
    super.key,
    required this.order,
    this.showActions = true,
    this.onItemTap,
    this.onQuantityUpdate,
    this.isEditable = false,
  });

  @override
  State<OrderItemsCard> createState() => _OrderItemsCardState();
}

class _OrderItemsCardState extends State<OrderItemsCard> {
  bool _isExpanded = true;
  String _sortOption = 'position'; // position, name, price, quantity
  bool _groupByCategory = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasItems = widget.order.hasItems();
    final items = widget.order.items ?? [];

    if (!hasItems) {
      return _buildEmptyItemsState(theme);
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(theme, items.length),

          if (_isExpanded) ...[
            const SizedBox(height: 12),

            // Sorting & Filtering Options
            _buildSortingOptions(theme),
            const SizedBox(height: 8),

            // Items List
            _buildItemsList(theme, items),
            const SizedBox(height: 20),

            // Summary Section
            _buildOrderSummary(theme),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, int itemCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
              Icons.shopping_basket_rounded,
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
                  'Order Items',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$itemCount ${itemCount == 1 ? 'item' : 'items'} • ${_getTotalQuantity()} total units',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() => _isExpanded = !_isExpanded);
            },
            icon: Icon(
              _isExpanded
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded,
              color: theme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            tooltip: _isExpanded ? 'Collapse items' : 'Expand items',
          ),
        ],
      ),
    );
  }

  Widget _buildSortingOptions(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          PopupMenuButton<String>(
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sort_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Sort',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              setState(() => _sortOption = value);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'position',
                child: Row(
                  children: [
                    Icon(
                      Icons.format_list_numbered,
                      size: 20,
                      color: theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 12),
                    Text('Original Order'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'name',
                child: Row(
                  children: [
                    Icon(
                      Icons.sort_by_alpha,
                      size: 20,
                      color: theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 12),
                    Text('Name (A-Z)'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'price',
                child: Row(
                  children: [
                    Icon(
                      Icons.attach_money,
                      size: 20,
                      color: theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 12),
                    Text('Price (High-Low)'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'quantity',
                child: Row(
                  children: [
                    Icon(
                      Icons.format_list_numbered_rtl,
                      size: 20,
                      color: theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 12),
                    Text('Quantity'),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          if (widget.order.items?.any(
                  (item) => item.orderedProduct?.productCategoryId != null) ??
              false)
            FilterChip(
              label: Text('Group by Category'),
              selected: _groupByCategory,
              onSelected: (selected) {
                setState(() => _groupByCategory = selected);
              },
              avatar: Icon(
                _groupByCategory ? Icons.check : Icons.category_outlined,
                size: 18,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemsList(ThemeData theme, List<OrderedItem> items) {
    // Sort items based on selected option
    final sortedItems = _sortItems(items);

    if (_groupByCategory) {
      return _buildGroupedItems(theme, sortedItems);
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: sortedItems.length,
      separatorBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Divider(
          height: 1,
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      itemBuilder: (context, index) {
        return _buildOrderItemTile(theme, sortedItems[index], index + 1);
      },
    );
  }

  Widget _buildGroupedItems(ThemeData theme, List<OrderedItem> items) {
    final groupedItems = <int, List<OrderedItem>>{};

    for (final item in items) {
      final categoryId = item.orderedProduct?.productCategoryId ?? 0;
      if (!groupedItems.containsKey(categoryId)) {
        groupedItems[categoryId] = [];
      }
      groupedItems[categoryId]!.add(item);
    }

    return Column(
      children: groupedItems.entries.map((entry) {
        final categoryItems = entry.value;
        final categoryName = _getCategoryName(entry.key);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    _getCategoryIcon(entry.key),
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    categoryName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${categoryItems.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...categoryItems.asMap().entries.map((itemEntry) {
              final index = itemEntry.key;
              final item = itemEntry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildOrderItemTile(theme, item, index + 1),
                    if (index < categoryItems.length - 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Divider(
                          height: 1,
                          color: theme.colorScheme.outline.withOpacity(0.1),
                          indent: 56,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildOrderItemTile(ThemeData theme, OrderedItem item, int position) {
    final product = item.orderedProduct;
    final hasDelivery = item.hasDeliveryFee;
    final isDelivered = item.isDelivered;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => widget.onItemTap?.call(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Position indicator
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$position',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product?.productName ?? 'Unknown Product',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.isEditable &&
                            widget.onQuantityUpdate != null)
                          _buildQuantitySelector(theme, item),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Product details
                    if (product?.productBrand != null &&
                        product!.productBrand.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.branding_watermark_outlined,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            product.productBrand,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),

                    // SKU/Barcode
                    if (product?.productBarcode != null &&
                        product!.productBarcode.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'SKU: ${product.productBarcode}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ),

                    // Price & Quantity
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Unit Price
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'DZD ${item.unitPrice.toStringAsFixed(2)}/unit',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Quantity
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '× ${item.orderedQuantity}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Item total
                        Text(
                          FinancialUIManager.formatCurrency(
                              item.totalPrice, context),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),

                    // Discount & VAT
                    if (item.productDiscount != null &&
                        item.productDiscount! > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.local_offer_outlined,
                                  size: 12,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '-DZD ${item.productDiscount!.toStringAsFixed(2)}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (item.appliedVat > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'VAT ${item.appliedVat}%',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],

                    // Delivery Status
                    if (hasDelivery ||
                        item.orderedItemDeliveryStatus != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            isDelivered
                                ? Icons.check_circle_outline_rounded
                                : Icons.local_shipping_outlined,
                            size: 14,
                            color: isDelivered
                                ? Colors.green
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _getDeliveryStatusText(item),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDelivered
                                    ? Colors.green
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item.orderedItemDeliveryFee != null &&
                              item.orderedItemDeliveryFee! > 0)
                            Text(
                              '+DZD ${item.orderedItemDeliveryFee!.toStringAsFixed(2)}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantitySelector(ThemeData theme, OrderedItem item) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              Icons.remove,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            onPressed: () {
              final newQty = item.orderedQuantity - 1;
              if (newQty > 0) {
                widget.onQuantityUpdate?.call(item, newQty);
              }
            },
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '${item.orderedQuantity}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.add,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            onPressed: () {
              widget.onQuantityUpdate?.call(item, item.orderedQuantity + 1);
            },
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(ThemeData theme) {
    final subtotal = widget.order.totalPrice;
    final discount = widget.order.orderDiscount ?? 0;
    final vat =
        widget.order.items?.fold(0.0, (sum, item) => sum + item.vatAmount) ?? 0;
    final delivery = widget.order.items?.fold(
            0.0, (sum, item) => sum + (item.orderedItemDeliveryFee ?? 0)) ??
        0;
    final total = subtotal - discount + vat + delivery;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Column(
          children: [
            _buildSummaryRow(
              theme,
              'Subtotal',
              'DZD ${subtotal.toStringAsFixed(2)}',
            ),
            if (discount > 0) ...[
              const SizedBox(height: 4),
              _buildSummaryRow(
                theme,
                'Discount',
                '-DZD ${discount.toStringAsFixed(2)}',
                color: Colors.green,
              ),
            ],
            if (vat > 0) ...[
              const SizedBox(height: 4),
              _buildSummaryRow(
                theme,
                'VAT',
                'DZD ${vat.toStringAsFixed(2)}',
                color: Colors.blue,
              ),
            ],
            if (delivery > 0) ...[
              const SizedBox(height: 4),
              _buildSummaryRow(
                theme,
                'Delivery',
                'DZD ${delivery.toStringAsFixed(2)}',
                color: Colors.orange,
              ),
            ],
            const SizedBox(height: 8),
            Divider(
              height: 1,
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              theme,
              'Total Amount',
              'DZD ${total.toStringAsFixed(2)}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    ThemeData theme,
    String label,
    String value, {
    Color? color,
    bool isTotal = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color ??
                (isTotal
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface),
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyItemsState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.shopping_basket_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Items',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This order doesn\'t contain any items',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper Methods
  List<OrderedItem> _sortItems(List<OrderedItem> items) {
    switch (_sortOption) {
      case 'name':
        items.sort((a, b) => (a.orderedProduct?.productName ?? '')
            .compareTo(b.orderedProduct?.productName ?? ''));
        break;
      case 'price':
        items.sort((a, b) => b.totalPrice.compareTo(a.totalPrice));
        break;
      case 'quantity':
        items.sort((a, b) => b.orderedQuantity.compareTo(a.orderedQuantity));
        break;
      case 'position':
      default:
        // Keep original order
        break;
    }
    return items;
  }

  String _getCategoryName(int categoryId) {
    // This would come from your category service
    final categories = {
      1: 'Electronics',
      2: 'Clothing',
      3: 'Food & Beverages',
      4: 'Home & Garden',
      5: 'Books & Media',
      6: 'Sports & Outdoors',
    };
    return categories[categoryId] ?? 'Category $categoryId';
  }

  IconData _getCategoryIcon(int categoryId) {
    final icons = {
      1: Icons.electrical_services,
      2: Icons.checkroom,
      3: Icons.restaurant,
      4: Icons.home,
      5: Icons.menu_book,
      6: Icons.sports_soccer,
    };
    return icons[categoryId] ?? Icons.category;
  }

  String _getDeliveryStatusText(OrderedItem item) {
    final status = item.orderedItemDeliveryStatus?.toLowerCase();
    switch (status) {
      case 'delivered':
        return 'Delivered • ${_formatDeliveryTime(item)}';
      case 'in_transit':
        return 'In Transit • ${_formatDeliveryTime(item)}';
      case 'pending':
        return 'Delivery Pending';
      default:
        return 'Delivery status not available';
    }
  }

  String _formatDeliveryTime(OrderedItem item) {
    // You would have delivery timestamps in your actual implementation
    return 'Today';
  }

  int _getTotalQuantity() {
    return widget.order.items
            ?.fold(0, (sum, item) => (sum ?? 0) + item.orderedQuantity) ??
        0;
  }
}

class EmptyState extends StatelessWidget {
  final OrderUIManager uiManager;
  final String? status;
  final VoidCallback? onCreateOrder;
  final VoidCallback? onViewTutorial;
  final bool showActionButtons;

  const EmptyState({
    super.key,
    required this.uiManager,
    this.status,
    this.onCreateOrder,
    this.onViewTutorial,
    this.showActionButtons = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = uiManager.getStatusIcon(status ?? 'all');
    final message = uiManager.getEmptyMessage(status);
    final subMessage = uiManager.getEmptySubMessage();
    final color = uiManager.getStatusColor(status ?? 'all', theme);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated illustration
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withOpacity(0.15),
                    color.withOpacity(0.05),
                    Colors.transparent,
                  ],
                  stops: const [0.1, 0.5, 1.0],
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Icon(
                    icon,
                    size: 64,
                    color: color,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Message
            Text(
              message,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Sub-message
            Text(
              subMessage,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Action buttons
            if (showActionButtons) ...[
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

              if (uiManager.searchController.text.isEmpty) ...[
                if (onCreateOrder != null)
                  FilledButton.icon(
                    onPressed: onCreateOrder,
                    icon: const Icon(Icons.add),
                    label: const Text('Create New Order'),
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
                const SizedBox(height: 12),
                if (onViewTutorial != null)
                  OutlinedButton.icon(
                    onPressed: onViewTutorial,
                    icon: const Icon(Icons.help_outline),
                    label: const Text('View Tutorial'),
                    style: OutlinedButton.styleFrom(
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

              // Quick stats
              if (status == null) ...[
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem(
                        theme,
                        icon: Icons.access_time,
                        label: 'Pending',
                        value: '0',
                        color: Colors.orange,
                      ),
                      _buildStatItem(
                        theme,
                        icon: Icons.local_shipping,
                        label: 'Processing',
                        value: '0',
                        color: Colors.blue,
                      ),
                      _buildStatItem(
                        theme,
                        icon: Icons.check_circle,
                        label: 'Completed',
                        value: '0',
                        color: Colors.green,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
