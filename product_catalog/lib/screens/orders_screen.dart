import 'package:decimal/decimal.dart';
import 'package:event/finance_change_notifier.dart';
import 'package:flutter/material.dart';
import 'package:product_catalog/screens/components/orders/order_card.dart';
import 'package:product_catalog/screens/components/orders/order_details_sheet.dart';
import 'package:product_catalog/screens/components/orders/order_grouping.dart';
import 'package:product_catalog/screens/components/orders/order_tab_bar.dart';
import 'package:product_catalog/screens/components/orders/orders_header.dart';
import 'package:ui/components/payment_dtos.dart';
import 'package:ui/screens/payment_form_screen.dart';
import 'package:verdelia_core/app/AppUser.dart';
import 'package:verdelia_core/business/finance/Order.dart';
import 'package:event/order_change_notifier.dart';
import 'package:event/user_change_notifier.dart';
import 'package:provider/provider.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

import 'components/orders/outstanding_invoice_banner.dart';

class OrdersScreen extends StatefulWidget {
  final OrderChangeNotifier? cartChangeNotifier;
  final void Function(Order order, InvoiceSummary invoice)? onPayInvoice;

  OrdersScreen({
    Key? key,
    required this.cartChangeNotifier,
    this.onPayInvoice,
  }) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isInitialLoad = true;
  OrderGrouping _grouping = OrderGrouping.delivery;
  final Set<String> _collapsedGroups = <String>{};
  late OrderChangeNotifier _orderNotifier;
  OrderTab _tab = OrderTab.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrders());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _orderNotifier = widget.cartChangeNotifier ??
        Provider.of<OrderChangeNotifier>(context, listen: false);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    if (!mounted) return;
    final appUser =
        Provider.of<AppUserNotifier>(context, listen: false).appUser;
    final userId = appUser?.idAppUser;
    if (userId == null) {
      if (mounted) setState(() => _isInitialLoad = false);
      return;
    }
    await _orderNotifier.fetchOrders(appUserId: userId);
    if (mounted) setState(() => _isInitialLoad = false);
  }

  Future<void> _refreshOrders() async {
    final appUser =
        Provider.of<AppUserNotifier>(context, listen: false).appUser;
    final userId = appUser?.idAppUser;
    if (userId == null) return;
    await _orderNotifier.fetchOrders(appUserId: userId);
  }

  List<Order> _filtered(List<Order> all) {
    switch (_tab) {
      case OrderTab.all:
        return all;
      case OrderTab.inProgress:
        return all
            .where((o) => o.isPending || o.isProcessing || o.isShipped)
            .toList();
      case OrderTab.completed:
        return all.where((o) => o.isCompleted).toList();
      case OrderTab.cancelled:
        return all.where((o) => o.isCancelled || o.isRefunded).toList();
    }
  }

  List<Order> _outstanding(List<Order> all) =>
      all.where((o) => o.hasExpandedInvoice && o.isInvoiceOutstanding).toList();

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
        builder: (context, notifier, _) {
          final all = notifier.orders;
          final isLoading = _isInitialLoad && all.isEmpty;
          final isEmpty = all.isEmpty && !isLoading;
          final outstanding = _outstanding(all);
          final filtered = _filtered(all);

          final outstandingAmount = outstanding.fold(
            Decimal.zero,
            (sum, o) => sum + (o.invoice?.grandTotal ?? Decimal.zero),
          );

          return RefreshIndicator(
            onRefresh: _refreshOrders,
            color: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.surface,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // ── Header ──
                SliverToBoxAdapter(
                  child: isLoading || isEmpty
                      ? const SizedBox.shrink()
                      : OrdersHeader(
                          orders: all,
                          outstandingCount: outstanding.length,
                          outstandingAmount: outstandingAmount,
                        ),
                ),

                // ── Outstanding-invoice banner ──
                SliverToBoxAdapter(
                  child: outstanding.isEmpty
                      ? const SizedBox.shrink()
                      : OutstandingInvoiceBanner(
                          orders: outstanding,
                          onPayInvoice: (o, inv) => _handlePayInvoice(o, inv),
                        ),
                ),

                // ── Tabs (pinned) ──
                SliverPersistentHeader(
                  pinned: true,
                  delegate: OrderTabBarDelegate(
                    tab: _tab,
                    onChanged: (t) => setState(() => _tab = t),
                    counts: {
                      OrderTab.all: all.length,
                      OrderTab.inProgress: all
                          .where((o) =>
                              o.isPending || o.isProcessing || o.isShipped)
                          .length,
                      OrderTab.completed:
                          all.where((o) => o.isCompleted).length,
                      OrderTab.cancelled: all
                          .where((o) => o.isCancelled || o.isRefunded)
                          .length,
                    },
                    hidden: isLoading || isEmpty,
                  ),
                ),

                // ── Body ──
                if (isLoading)
                  SliverToBoxAdapter(child: _buildLoadingState(theme, loc))
                else if (isEmpty)
                  SliverToBoxAdapter(child: _buildEmptyState(loc, theme))
                else if (filtered.isEmpty)
                  SliverToBoxAdapter(child: _buildEmptyTabState(theme, loc))
                else ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: _GroupingSelector(
                        value: _grouping,
                        onChanged: (g) => setState(() {
                          _grouping = g;
                          _collapsedGroups.clear();
                        }),
                        loc: loc,
                      ),
                    ),
                  ),
                  ..._buildGroupedSlivers(filtered, theme, loc),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme, AppLocalizations loc) {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              loc.loadingOrdersTxt,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations loc, ThemeData theme) {
    return SizedBox(
      height: 300,
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
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(loc.refreshTxt),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTabState(ThemeData theme, AppLocalizations loc) {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_alt_off_outlined,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
            ),
            const SizedBox(height: 12),
            Text(
              loc.noOrdersInTabTxt,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGroupedSlivers(
    List<Order> filtered,
    ThemeData theme,
    AppLocalizations loc,
  ) {
    final groups = _groupOrders(filtered, _grouping);
    final slivers = <Widget>[];

    for (final group in groups) {
      final collapsed = _collapsedGroups.contains(group.key);

      slivers.add(SliverToBoxAdapter(
        child: _GroupHeader(
          group: group,
          collapsed: collapsed,
          onToggle: () => setState(() {
            if (collapsed) {
              _collapsedGroups.remove(group.key);
            } else {
              _collapsedGroups.add(group.key);
            }
          }),
          theme: theme,
        ),
      ));

      if (!collapsed) {
        slivers.add(SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              final order = group.orders[i];
              return OrderCard(
                order: order,
                onTap: () => _showOrderDetails(order, loc, theme, context),
              );
            },
            childCount: group.orders.length,
          ),
        ));
      }
    }

    return slivers;
  }

  void _showOrderDetails(
    Order order,
    AppLocalizations loc,
    ThemeData theme,
    BuildContext context,
  ) async {
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
                loc.loadingOrderDetailsTxt,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );

    try {
      await _orderNotifier.fetchOrderDetails(orderId: order.idPlacedOrder);
      if (!mounted) return;
      Navigator.pop(context);
      _showOrderDetailsSheet(order, loc, theme, context);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showErrorSheet(e.toString(), loc, theme, context);
    }
  }

  void _showOrderDetailsSheet(
    Order order,
    AppLocalizations loc,
    ThemeData theme,
    BuildContext context,
  ) {
    final detailed = _orderNotifier.getOrderWithDetails(order.idPlacedOrder);
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
        child: detailed == null || !detailed.hasItems()
            ? _buildErrorState(loc.failedToLoadDetails, theme, loc)
            : OrderDetailsSheet(
                order: detailed,
                onPayInvoice: (o, inv) => _handlePayInvoice(o, inv),
              ),
      ),
    );
  }

  void _showErrorSheet(
    String error,
    AppLocalizations loc,
    ThemeData theme,
    BuildContext context,
  ) {
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
          child: Padding(
            padding: const EdgeInsets.all(32),
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
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
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
      ),
    );
  }

  // ==================== PAYMENT FLOW ====================

  Future<void> _handlePayInvoice(
    Order order,
    InvoiceSummary invoice,
  ) async {
    if (widget.onPayInvoice != null) {
      widget.onPayInvoice!(order, invoice);
      return;
    }

    final appUser =
        Provider.of<AppUserNotifier>(context, listen: false).appUser;

    if (appUser == null) {
      _snack(AppLocalizations.of(context)!.loginRequiredError);
      return;
    }

    final actor = _actorFor(appUser);
    final wallet = await _loadWallet(appUser);
    if (!mounted) return;

    final payeeId = _payeeIdFor(appUser, order);

    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PaymentFormScreen(
          actor: PaymentActor.client,
          amountDue: invoice.grandTotal,
          initialAmount: null,
          wallet: wallet,
          payeeId: payeeId,
          currency: 'DZD',
          title: invoice.reference ?? '#${order.idPlacedOrder}',
          currencySymbol: '',
          onSubmit: (amount, method, notes) async {
            return _submitInvoicePayment(
              order: order,
              invoice: invoice,
              amount: amount,
              method: method,
              notes: notes,
              actor: actor,
            );
          },
        ),
      ),
    );

    if (ok == true && mounted) {
      await _refreshOrders();
    }
  }

  PaymentActor _actorFor(AppUser appUser) {
    switch (appUser.appUserType) {
      case AppUserType.provider:
        return PaymentActor.provider;
      case AppUserType.customer:
      case AppUserType.patient:
      case AppUserType.guest:
      case null:
        return PaymentActor.client;
    }
  }

  String? _payeeIdFor(AppUser appUser, Order order) {
    if (appUser.appUserType == AppUserType.provider) {
      final userId = appUser.idAppUser;
      if (userId != null && userId > 0) return 'user:$userId';
      return null;
    }

    final supplierId = _supplierIdFromOrder(order);
    if (supplierId != null && supplierId > 0) {
      return 'provider:$supplierId';
    }
    return null;
  }

  static int? _supplierIdFromOrder(Order order) {
    try {
      final dynamic dynamicOrder = order;
      final raw = dynamicOrder.providerUserId;
      if (raw is int) return raw > 0 ? raw : null;
      if (raw is num) {
        final asInt = raw.toInt();
        return asInt > 0 ? asInt : null;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<WalletAccount?> _loadWallet(AppUser appUser) async {
    final wallet = appUser.wallet;
    if (wallet == null) return null;
    if (wallet.isClosed || wallet.isInactive) return null;

    final locked = !wallet.canTransact;

    return WalletAccount(
      id: wallet.idWallet?.toString() ?? 'user:${appUser.idAppUser}',
      label: appUser.displayName.isNotEmpty ? appUser.displayName : 'Wallet',
      balance: Decimal.parse(wallet.walletBalance.toStringAsFixed(2)),
      currency: wallet.walletCurrency,
      isLocked: locked,
    );
  }

  Future<String?> _submitInvoicePayment({
    required Order order,
    required InvoiceSummary invoice,
    required Decimal amount,
    required String method,
    required String notes,
    required PaymentActor actor,
  }) async {
    try {
      final notifier =
          Provider.of<FinanceChangeNotifier>(context, listen: false);
      final r = await notifier.submitPayment(
        invoiceId: invoice.invoiceId,
        amount: amount,
        method: method,
        notes: notes,
      );

      if (method == "wallet" && r.isSuccess) {
        final userNotifier =
            Provider.of<AppUserNotifier>(context, listen: false);
        final current = userNotifier.appUser;
        if (current != null) {
          if (current.canDebitWallet(amount.toDouble())) {
            current.debitWallet(amount.toDouble());
          } else {
            // Local mirror disagrees with the server — refresh
            // rather than persist an incorrect balance.
            // await userNotifier.refresh();
          }
        }
      }

      return r.isSuccess ? null : r.message;
    } catch (e) {
      return 'Payment failed: $e';
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
      );
  }

  Widget _buildErrorState(
    String error,
    ThemeData theme,
    AppLocalizations loc,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== GROUPING ====================

  List<OrderGroup> _groupOrders(List<Order> orders, OrderGrouping grouping) {
    final loc = AppLocalizations.of(context)!;
    final buckets = <String, List<Order>>{};

    for (final o in orders) {
      final key = _bucketKeyFor(o, grouping);
      buckets.putIfAbsent(key, () => []).add(o);
    }

    final ordered = _orderedBucketKeys(grouping);
    final groups = <OrderGroup>[];

    // Known buckets, in fixed display order.
    for (final key in ordered) {
      final bucket = buckets.remove(key);
      if (bucket == null || bucket.isEmpty) continue;
      groups.add(OrderGroup(
        key: key,
        label: _bucketLabel(key, grouping, loc),
        icon: _bucketIcon(key, grouping),
        orders: bucket,
      ));
    }

    // Unknown buckets — server introduced a state we don't recognize.
    // Surface them at the bottom so nothing silently disappears.
    for (final entry in buckets.entries) {
      if (entry.value.isEmpty) continue;
      groups.add(OrderGroup(
        key: entry.key,
        label: _bucketLabel(entry.key, grouping, loc),
        icon: Icons.circle_outlined,
        orders: entry.value,
      ));
    }
    return groups;
  }

  String _bucketKeyFor(Order o, OrderGrouping g) {
    switch (g) {
      case OrderGrouping.delivery:
        return _deliveryBucket(o);
      case OrderGrouping.invoice:
        return _invoiceBucket(o);
      case OrderGrouping.status:
        return _statusBucket(o);
    }
  }

  String _deliveryBucket(Order o) {
    final lines = o.items;
    if (lines == null || lines.isEmpty) return 'no_delivery';

    var anyPending = false;
    var anyShipped = false;
    var allDelivered = true;

    for (final line in lines) {
      final s = (line.orderedItemDeliveryStatus ?? '').toLowerCase();
      if (s != 'delivered') allDelivered = false;
      if (s == 'pending' || s.isEmpty) anyPending = true;
      if (s == 'shipped' || s == 'out_for_delivery') anyShipped = true;
    }

    if (allDelivered) return 'delivered';
    if (anyShipped) return 'in_transit';
    if (anyPending) return 'awaiting_dispatch';
    return 'partially_delivered';
  }

  String _invoiceBucket(Order o) {
    if (!o.hasExpandedInvoice) return 'no_invoice';
    final inv = o.invoice!;
    if (inv.isPaid) return 'paid';
    if (inv.isPartiallyPaid) return 'partially_paid';
    if (inv.isRefunded) return 'refunded';
    if (inv.isOutstanding) return 'outstanding';
    return 'unpaid';
  }

  String _statusBucket(Order o) {
    if (o.isPending) return 'pending';
    if (o.isProcessing) return 'processing';
    if (o.isShipped) return 'shipped';
    if (o.isCompleted) return 'completed';
    if (o.isCancelled) return 'cancelled';
    if (o.isRefunded) return 'refunded';
    return 'unknown';
  }

  List<String> _orderedBucketKeys(OrderGrouping g) {
    switch (g) {
      case OrderGrouping.delivery:
        return const [
          'awaiting_dispatch',
          'in_transit',
          'partially_delivered',
          'delivered',
          'no_delivery',
        ];
      case OrderGrouping.invoice:
        return const [
          'outstanding',
          'partially_paid',
          'unpaid',
          'paid',
          'refunded',
          'no_invoice',
        ];
      case OrderGrouping.status:
        return const [
          'pending',
          'processing',
          'shipped',
          'completed',
          'cancelled',
          'refunded',
          'unknown',
        ];
    }
  }

  String _bucketLabel(String key, OrderGrouping g, AppLocalizations loc) {
    switch (g) {
      case OrderGrouping.delivery:
        switch (key) {
          case 'awaiting_dispatch':
            return loc.deliveryTransitionReady;
          case 'in_transit':
            return loc.deliveryInTransit;
          case 'partially_delivered':
            return loc.partial;
          case 'delivered':
            return loc.deliveryDelivered;
          case 'no_delivery':
            return loc.none;
        }
        break;
      case OrderGrouping.invoice:
        switch (key) {
          case 'outstanding':
            return loc.outstanding;
          case 'partially_paid':
            return loc.partial;
          case 'unpaid':
            return loc.unpaid;
          case 'paid':
            return loc.paid;
          case 'refunded':
            return loc.refunded;
          case 'no_invoice':
            return loc.none;
        }
        break;
      case OrderGrouping.status:
        switch (key) {
          case 'pending':
            return loc.pending;
          case 'processing':
            return loc.processing;
          case 'shipped':
            return loc.shippedTxt;
          case 'completed':
            return loc.completed;
          case 'cancelled':
            return loc.canceled;
          case 'refunded':
            return loc.refunded;
          case 'unknown':
            return loc.none;
        }
        break;
    }
    return key.replaceAll('_', ' ');
  }

  IconData _bucketIcon(String key, OrderGrouping g) {
    switch (g) {
      case OrderGrouping.delivery:
        switch (key) {
          case 'awaiting_dispatch':
            return Icons.inventory_2_outlined;
          case 'in_transit':
            return Icons.local_shipping_outlined;
          case 'partially_delivered':
            return Icons.incomplete_circle;
          case 'delivered':
            return Icons.check_circle_outline;
          case 'no_delivery':
            return Icons.storefront_outlined;
        }
        break;
      case OrderGrouping.invoice:
        switch (key) {
          case 'outstanding':
            return Icons.receipt_long_outlined;
          case 'partially_paid':
            return Icons.pie_chart_outline;
          case 'unpaid':
            return Icons.money_off_csred_outlined;
          case 'paid':
            return Icons.verified_outlined;
          case 'refunded':
            return Icons.replay_outlined;
          case 'no_invoice':
            return Icons.description_outlined;
        }
        break;
      case OrderGrouping.status:
        switch (key) {
          case 'pending':
            return Icons.schedule;
          case 'processing':
            return Icons.sync;
          case 'shipped':
            return Icons.local_shipping_outlined;
          case 'completed':
            return Icons.check_circle_outline;
          case 'cancelled':
            return Icons.cancel_outlined;
          case 'refunded':
            return Icons.replay_outlined;
        }
        break;
    }
    return Icons.circle_outlined;
  }
}

class _GroupingSelector extends StatelessWidget {
  final OrderGrouping value;
  final ValueChanged<OrderGrouping> onChanged;
  final AppLocalizations loc;

  const _GroupingSelector({
    required this.value,
    required this.onChanged,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: OrderGrouping.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final g = OrderGrouping.values[i];
          final selected = g == value;
          return ChoiceChip(
            selected: selected,
            onSelected: (_) => onChanged(g),
            avatar: Icon(
              g.icon,
              size: 16,
              color: selected ? cs.onPrimary : cs.onSurfaceVariant,
            ),
            label: Text(
              g.label(loc),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            selectedColor: cs.primary,
            labelStyle: TextStyle(
              color: selected ? cs.onPrimary : cs.onSurface,
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final OrderGroup group;
  final bool collapsed;
  final VoidCallback onToggle;
  final ThemeData theme;

  const _GroupHeader({
    required this.group,
    required this.collapsed,
    required this.onToggle,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Material(
        color: cs.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(group.icon, size: 18, color: cs.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    group.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _Badge(count: group.count, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  '${group.total.toStringAsFixed(2)} DZD',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: collapsed ? 0.0 : 0.5,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    Icons.expand_more,
                    size: 20,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  final Color color;
  const _Badge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
