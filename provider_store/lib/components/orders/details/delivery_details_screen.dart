// lib/provider_store/screens/DeliveryDetailScreen.dart
//
// Live view of one delivery. The screen does not hold its own copy of
// the delivery — it reads the current row from the notifier on every
// build. When a mutation succeeds, the notifier replaces the cached
// row and notifies; this screen rebuilds against the fresh instance,
// and every section (status hero, shipping block, bottom actions)
// reflects the new state in the same frame.
//
// Sheets that the screen opens also read the live row from the
// notifier, so what the user sees in a modal matches what the screen
// shows underneath it.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:verdelia_core/business/Delivery.dart';
import 'package:verdelia_core/business/finance/Order.dart';
import 'package:event/delivery_change_notifier.dart';
import 'package:event/product_change_notifier.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:provider_store/components/delivery/DeliveryDetailsSheet.dart';
import 'package:provider_store/components/delivery/DeliveryTransitionSheet.dart';

// ============================================================================
// DELIVERY DETAIL SCREEN
// ============================================================================

class DeliveryDetailScreen extends StatelessWidget {
  /// The delivery the screen was opened with. Only its id is used —
  /// the live row comes from the notifier on every build.
  final Delivery delivery;
  final DeliveryChangeNotifier notifier;

  const DeliveryDetailScreen({
    super.key,
    required this.delivery,
    required this.notifier,
  });

  Delivery _live(DeliveryChangeNotifier n) =>
      n.getDeliveryByIdSync(delivery.id_delivery) ?? delivery;

  @override
  Widget build(BuildContext context) {
    return Consumer<DeliveryChangeNotifier>(
      builder: (context, n, _) {
        final live = _live(n);
        final cs = Theme.of(context).colorScheme;
        final l10n = AppLocalizations.of(context)!;
        final status = DeliveryStatusConfig.fromStatus(
          live.delivery_status.wireValue,
          l10n,
        );
        final order = live.order;

        return Scaffold(
          backgroundColor: cs.surface,
          appBar: _buildAppBar(context, l10n, live),
          body: SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                live.canBeUpdated ? 120 : 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusHero(delivery: live, status: status),
                  const SizedBox(height: 16),
                  if (order != null && order.hasOrderingUser)
                    _Section(
                      icon: Icons.person_outline_rounded,
                      title: l10n.deliveryDetailSectionCustomer,
                      child: _CustomerBlock(order: order),
                    ),
                  if (order != null && order.hasOrderingUser)
                    const SizedBox(height: 12),
                  if (live.hasDetailedOrder)
                    _Section(
                      icon: Icons.shopping_bag_outlined,
                      title: l10n.deliveryDetailSectionItems,
                      badge: l10n.deliveryDetailSectionItemsCount(
                          live.orderItems.length),
                      child: _ItemsBlock(delivery: live),
                    ),
                  if (live.hasDetailedOrder) const SizedBox(height: 12),
                  if (live.delivery_address != null ||
                      live.recipient_person > 0 ||
                      live.recipient_provider > 0)
                    _Section(
                      icon: Icons.location_on_outlined,
                      title: l10n.deliveryDetailSectionDestination,
                      child: _DestinationBlock(delivery: live),
                    ),
                  if (live.delivery_address != null ||
                      live.recipient_person > 0 ||
                      live.recipient_provider > 0)
                    const SizedBox(height: 12),
                  _Section(
                    icon: Icons.local_shipping_outlined,
                    title: l10n.deliveryDetailSectionShipping,
                    child: _ShippingBlock(delivery: live),
                  ),
                  const SizedBox(height: 12),
                  _Section(
                    icon: Icons.info_outline_rounded,
                    title: l10n.deliveryDetailSectionMetadata,
                    initiallyExpanded: false,
                    child: _MetadataBlock(delivery: live),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: live.canBeUpdated
              ? _BottomActions(
                  delivery: live,
                  onTransition: (action) =>
                      _openTransitionSheet(context, live, action),
                )
              : null,
        );
      },
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    AppLocalizations l10n,
    Delivery live,
  ) {
    final cs = Theme.of(context).colorScheme;
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
      title: Text(
        l10n.deliveryDetailTitleWithId(live.id_delivery),
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: l10n.deliveryDetailRefreshTooltip,
          onPressed: () {
            notifier.refreshDelivery(live.id_delivery);
            _snack(context, l10n.deliveryDetailRefreshing);
          },
        ),
        if (live.canBeUpdated)
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.deliveryDetailEditTooltip,
            onPressed: () => _openDetailsSheet(context, live),
          ),
      ],
    );
  }

  Future<void> _openDetailsSheet(
    BuildContext context,
    Delivery live,
  ) async {
    final productNotifier = context.read<ProductNotifier>();
    final providerId = live.delivery_provider_id ?? notifier.currentProviderId;

    final initialProductIds =
        await _resolveProviderProductIds(live, productNotifier, providerId);
    if (!context.mounted) return;

    await DeliveryDetailsSheet.open(
      context,
      notifier: notifier,
      delivery: live,
      providerId: providerId,
      initialProductIds: initialProductIds,
      // No onCommit override — the sheet's default writes through
      // notifier.updateDetails.
    );
  }

  Future<void> _openTransitionSheet(
    BuildContext context,
    Delivery live,
    DeliveryAction action,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DeliveryTransitionSheet(
        notifier: notifier,
        delivery: live,
        action: action,
      ),
    );
  }

  Future<List<int>> _resolveProviderProductIds(
    Delivery live,
    ProductNotifier productNotifier,
    int providerId,
  ) async {
    final out = <int>{};
    for (final item in live.orderItems) {
      final id = item.orderedProductId ?? 0;
      if (id <= 0) continue;

      final embedded = item.orderedProduct;
      if (embedded != null &&
          embedded.idProduct != null &&
          embedded.idProduct! > 0) {
        if (providerId <= 0 || embedded.productProviderId == providerId) {
          out.add(embedded.idProduct!);
        }
        continue;
      }

      final product = await productNotifier.getProductById(id);
      if (product == null) continue;
      if (providerId > 0 && product.product_provider_id != providerId) continue;
      out.add(id);
    }
    return out.toList();
  }

  static void _snack(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? cs.errorContainer : cs.tertiaryContainer,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 2),
        ),
      );
  }
}

// ============================================================================
// BOTTOM ACTIONS
// ============================================================================
//
// The action surface for a delivery. Reads the live delivery passed by
// the screen; picks the next forward action from DeliveryAction
// (imported from DeliveryTransitionSheet) so the enum is defined once
// for the whole app.

class _BottomActions extends StatelessWidget {
  final Delivery delivery;
  final Future<void> Function(DeliveryAction action) onTransition;

  const _BottomActions({
    required this.delivery,
    required this.onTransition,
  });

  DeliveryAction? get _next {
    for (final a in DeliveryAction.values) {
      if (a.isApplicableTo(delivery) && !a.isDestructive) return a;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final next = _next;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          if (delivery.canBeCancelled) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => onTransition(DeliveryAction.cancel),
                icon: const Icon(Icons.close_rounded, size: 18),
                label: Text(l10n.deliveryDetailActionCancel),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.error,
                  side: BorderSide(color: cs.error.withOpacity(0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: next == null ? null : () => onTransition(next),
              icon: Icon(next?.icon ?? Icons.check_circle_rounded, size: 18),
              label: Text(
                next?.verb(l10n) ?? '—',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// STATUS HERO
// ============================================================================

class _StatusHero extends StatelessWidget {
  final Delivery delivery;
  final DeliveryStatusConfig status;

  const _StatusHero({required this.delivery, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            status.color.withOpacity(0.15),
            status.color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: status.color.withOpacity(0.20),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(status.icon, color: status.color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: status.color,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.deliveryDetailTitleWithId(delivery.id_delivery),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                if (delivery.delivery_updated_at != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _relativeTime(delivery.delivery_updated_at!, l10n),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (delivery.delivery_fee != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  l10n.deliveryDetailFieldFee,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  l10n.price(delivery.delivery_fee.toString()),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  static String _relativeTime(DateTime ts, AppLocalizations l10n) {
    final diff = DateTime.now().difference(ts);
    if (diff.inSeconds < 60) return l10n.deliveryDetailUpdatedJustNow;
    if (diff.inMinutes < 60) {
      return l10n.deliveryDetailUpdatedMinutesAgo(diff.inMinutes);
    }
    if (diff.inHours < 24) {
      return l10n.deliveryDetailUpdatedHoursAgo(diff.inHours);
    }
    if (diff.inDays < 7) {
      return l10n.deliveryDetailUpdatedDaysAgo(diff.inDays);
    }
    return l10n.deliveryDetailUpdatedOnDate(ts.day, ts.month, ts.year);
  }
}

// ============================================================================
// SECTION
// ============================================================================

class _Section extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? badge;
  final Widget child;
  final bool initiallyExpanded;

  const _Section({
    required this.icon,
    required this.title,
    required this.child,
    this.badge,
    this.initiallyExpanded = true,
  });

  @override
  State<_Section> createState() => _SectionState();
}

class _SectionState extends State<_Section> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Icon(widget.icon, size: 20, color: cs.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  if (widget.badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        widget.badge!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: widget.child,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// INFO ROW
// ============================================================================

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool copyable;
  final bool emphasized;

  const _InfoRow({
    required this.label,
    required this.value,
    this.copyable = false,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final valueWidget = Text(
      value,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
        color: cs.onSurface,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: copyable
                ? GestureDetector(
                    onLongPress: () {
                      Clipboard.setData(ClipboardData(text: value));
                      DeliveryDetailScreen._snack(
                        context,
                        l10n.deliveryDetailCopiedToClipboard,
                      );
                    },
                    child: Row(
                      children: [
                        Flexible(child: valueWidget),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.copy_rounded,
                          size: 13,
                          color: cs.onSurfaceVariant.withOpacity(0.5),
                        ),
                      ],
                    ),
                  )
                : valueWidget,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CUSTOMER BLOCK
// ============================================================================

class _CustomerBlock extends StatelessWidget {
  final Order order;

  const _CustomerBlock({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final user = order.orderingUser;

    final displayName = order.orderingUserName;
    final initials = order.orderingUserInitials;
    final imageUrl = order.orderingUserImageUrl;

    final rows = <Widget>[];

    void add(String label, dynamic value, {bool copyable = false}) {
      if (value == null) return;
      final text = value.toString().trim();
      if (text.isEmpty || text == 'null') return;
      rows.add(_InfoRow(label: label, value: text, copyable: copyable));
    }

    if (user != null) {
      add(l10n.deliveryDetailFieldUsername, user.appUserName, copyable: true);
      if (user.appUserEmail != null && user.appUserEmail!.isNotEmpty) {
        add(l10n.deliveryDetailFieldEmail, user.appUserEmail!, copyable: true);
      }
      if (user.appUserType != null) {
        add(l10n.deliveryDetailFieldUserType, user.appUserType);
      }
      if (user.personPhone != null && user.personPhone!.isNotEmpty) {
        add(l10n.deliveryDetailFieldPhone, user.personPhone!, copyable: true);
      }
      add(l10n.deliveryDetailFieldUserId, user.idAppUser, copyable: true);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primaryContainer,
                image: (imageUrl != null && imageUrl.isNotEmpty)
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                        onError: (_, __) {},
                      )
                    : null,
              ),
              alignment: Alignment.center,
              child: (imageUrl == null || imageUrl.isEmpty)
                  ? Text(
                      initials,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: cs.onPrimaryContainer,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (user?.appUserName != null &&
                      user!.appUserName!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '@${user.appUserName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (rows.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 8),
          ...rows,
        ],
      ],
    );
  }
}

// ============================================================================
// ITEMS BLOCK
// ============================================================================

class _ItemsBlock extends StatelessWidget {
  final Delivery delivery;

  const _ItemsBlock({required this.delivery});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final items = delivery.orderItems;

    if (items.isEmpty) {
      return Text(
        l10n.deliveryDetailEmptyItems,
        style: theme.textTheme.bodySmall?.copyWith(
          color: cs.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final productNotifier = context.watch<ProductNotifier>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < items.length; i++) ...[
          _ResolvedItemRow(
            item: items[i],
            productNotifier: productNotifier,
          ),
          if (i != items.length - 1)
            Divider(
              height: 20,
              color: cs.outlineVariant.withOpacity(0.4),
            ),
        ],
        const SizedBox(height: 12),
        _TotalsBlock(delivery: delivery),
      ],
    );
  }
}

// ============================================================================
// RESOLVED ITEM ROW
// ============================================================================

class _ResolvedItemRow extends StatefulWidget {
  final OrderedItem item;
  final ProductNotifier productNotifier;

  const _ResolvedItemRow({
    required this.item,
    required this.productNotifier,
  });

  @override
  State<_ResolvedItemRow> createState() => _ResolvedItemRowState();
}

class _ResolvedItemRowState extends State<_ResolvedItemRow> {
  Future<_ResolvedProduct>? _future;
  AppLocalizations? _l10n;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n ??= AppLocalizations.of(context)!;
    _future ??= _resolve(_l10n!);
  }

  @override
  void didUpdateWidget(covariant _ResolvedItemRow old) {
    super.didUpdateWidget(old);
    if (old.item.idOrderedItem != widget.item.idOrderedItem && _l10n != null) {
      _future = _resolve(_l10n!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n!;
    return FutureBuilder<_ResolvedProduct>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData) {
          return _ItemRowSkeleton(
            quantityLabel: l10n
                .deliveryDetailItemQuantityLabel(widget.item.orderedQuantity),
          );
        }

        final resolved = snapshot.data!;
        return _ItemRow(
          item: widget.item,
          displayName: resolved.name,
          brand: resolved.brand,
          barcode: resolved.barcode,
          quantifier: resolved.quantifier,
          isResolved: resolved.found,
        );
      },
    );
  }

  Future<_ResolvedProduct> _resolve(AppLocalizations l10n) async {
    final item = widget.item;

    final embedded = item.orderedProduct;
    final embeddedName = embedded?.productName?.trim();
    if (embeddedName != null && embeddedName.isNotEmpty) {
      return _ResolvedProduct(
        name: embeddedName,
        brand: embedded?.productBrand,
        barcode: embedded?.productBarcode,
        quantifier: embedded?.productQuantifier,
        found: true,
      );
    }

    final id = item.orderedProductId ?? 0;
    if (id > 0) {
      final cached = await widget.productNotifier.getProductById(id);
      if (cached != null) {
        final name = cached.product_name?.trim();
        return _ResolvedProduct(
          name: (name != null && name.isNotEmpty)
              ? name
              : l10n.deliveryDetailProductFallback(id),
          brand: cached.product_brand,
          barcode: cached.product_barcode,
          quantifier: cached.product_quantifier,
          found: (name != null && name.isNotEmpty),
        );
      }
    }

    return _ResolvedProduct(
      name: l10n.deliveryDetailProductFallback(id),
      found: false,
    );
  }
}

// ============================================================================
// SKELETON
// ============================================================================

class _ItemRowSkeleton extends StatelessWidget {
  final String quantityLabel;

  const _ItemRowSkeleton({required this.quantityLabel});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            quantityLabel,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _shimmerBar(cs, widthFactor: 0.7, height: 14),
              const SizedBox(height: 6),
              _shimmerBar(cs, widthFactor: 0.45, height: 11),
              const SizedBox(height: 6),
              _shimmerBar(cs, widthFactor: 0.55, height: 10),
            ],
          ),
        ),
        _shimmerBar(cs, width: 60, height: 14),
      ],
    );
  }

  Widget _shimmerBar(
    ColorScheme cs, {
    double? width,
    double? widthFactor,
    required double height,
  }) {
    final bar = Container(
      height: height,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
    );
    if (width != null) return SizedBox(width: width, child: bar);
    if (widthFactor != null) {
      return FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: widthFactor,
        child: bar,
      );
    }
    return bar;
  }
}

class _ResolvedProduct {
  final String name;
  final String? brand;
  final String? barcode;
  final String? quantifier;
  final bool found;

  const _ResolvedProduct({
    required this.name,
    this.brand,
    this.barcode,
    this.quantifier,
    required this.found,
  });
}

// ============================================================================
// ITEM ROW
// ============================================================================

class _ItemRow extends StatelessWidget {
  final OrderedItem item;
  final String displayName;
  final String? brand;
  final String? barcode;
  final String? quantifier;
  final bool isResolved;

  const _ItemRow({
    required this.item,
    required this.displayName,
    this.brand,
    this.barcode,
    this.quantifier,
    this.isResolved = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final sublineParts = <String>[
      if (brand != null && brand!.trim().isNotEmpty) brand!.trim(),
      if (barcode != null && barcode!.trim().isNotEmpty) barcode!.trim(),
      if (item.orderedProductId != null) '#${item.orderedProductId}',
    ];
    final subline = sublineParts.join(' · ');

    final unitLine = l10n.deliveryDetailItemUnitLine(
      item.unitPrice.toStringAsFixed(2),
      quantifier ?? '',
      item.appliedVat.toStringAsFixed(1),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:
                isResolved ? cs.primaryContainer : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            l10n.deliveryDetailItemQuantityLabel(item.orderedQuantity),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: isResolved ? cs.onPrimaryContainer : cs.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (subline.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subline,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 4),
              Text(
                unitLine,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              if (item.isDelivered) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 12,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.deliveryDetailItemDelivered,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        Text(
          l10n.price(item.totalPrice.toStringAsFixed(2)),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// TOTALS BLOCK
// ============================================================================

class _TotalsBlock extends StatelessWidget {
  final Delivery delivery;

  const _TotalsBlock({required this.delivery});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final subtotal = delivery.deliverySubtotal();
    final discount = delivery.orderDiscount;
    final net = delivery.deliveryNetTotal;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _line(
            theme,
            cs,
            l10n.deliveryDetailTotalsSubtotal,
            l10n.price(subtotal.toStringAsFixed(2)),
          ),
          if (discount > 0) ...[
            const SizedBox(height: 6),
            _line(
              theme,
              cs,
              l10n.deliveryDetailTotalsDiscount,
              l10n.deliveryDetailDiscountValue(discount.toStringAsFixed(2)),
              valueColor: cs.error,
            ),
          ],
          const Divider(height: 20),
          _line(
            theme,
            cs,
            l10n.deliveryDetailTotalsTotal,
            l10n.price(net.toStringAsFixed(2)),
            emphasized: true,
          ),
        ],
      ),
    );
  }

  Widget _line(
    ThemeData theme,
    ColorScheme cs,
    String label,
    String value, {
    Color? valueColor,
    bool emphasized = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ?? cs.onSurface,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// DESTINATION BLOCK
// ============================================================================

class _DestinationBlock extends StatelessWidget {
  final Delivery delivery;

  const _DestinationBlock({required this.delivery});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rows = <Widget>[];

    void add(String label, dynamic value, {bool copyable = false}) {
      if (value == null) return;
      final text = value.toString().trim();
      if (text.isEmpty || text == 'null') return;
      rows.add(_InfoRow(label: label, value: text, copyable: copyable));
    }

    final address = delivery.delivery_address;
    if (address != null) {
      add(l10n.deliveryDetailFieldAddress, address.fullAddress);
      if (address.addressStreet != null) {
        add(l10n.deliveryDetailFieldStreet, address.addressStreet!);
      }
      if (address.addressCity != null) {
        add(l10n.deliveryDetailFieldCity, address.addressCity!);
      }
      if (address.addressPostalCode != null) {
        add(l10n.deliveryDetailFieldPostalCode, address.addressPostalCode!);
      }
      if (address.addressCountry != null) {
        add(l10n.deliveryDetailFieldCountry, address.addressCountry!);
      }
    }

    if (rows.isEmpty) {
      return _EmptyHint(text: l10n.deliveryDetailEmptyDestination);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }
}

// ============================================================================
// SHIPPING BLOCK
// ============================================================================

class _ShippingBlock extends StatelessWidget {
  final Delivery delivery;

  const _ShippingBlock({required this.delivery});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rows = <Widget>[];

    void add(String label, dynamic value, {bool copyable = false}) {
      if (value == null) return;
      final text = value.toString().trim();
      if (text.isEmpty || text == 'null') return;
      rows.add(_InfoRow(label: label, value: text, copyable: copyable));
    }

    add(
        l10n.deliveryDetailFieldMethod,
        DeliveryShippingConfig.labelFor(
            delivery.delivery_shipping_method, l10n));
    if (delivery.delivery_package_count != null) {
      add(
        l10n.deliveryDetailFieldPackages,
        l10n.deliveryDetailPackageCount(delivery.delivery_package_count!),
      );
    }
    if (delivery.delivery_total_weight != null) {
      add(
        l10n.deliveryDetailFieldTotalWeight,
        l10n.deliveryDetailWeightKg(
            delivery.delivery_total_weight!.toStringAsFixed(2)),
      );
    }
    if (delivery.delivery_cargo_dimensions != null) {
      add(l10n.deliveryDetailFieldDimensions,
          delivery.delivery_cargo_dimensions!);
    }
    if (delivery.delivery_goods_description != null) {
      add(l10n.deliveryDetailFieldGoods, delivery.delivery_goods_description!);
    }
    if (delivery.hs_code != null) {
      add(l10n.deliveryDetailFieldHsCode, delivery.hs_code!);
    }
    if (delivery.delivery_merchant_name != null) {
      add(l10n.deliveryDetailFieldMerchant, delivery.delivery_merchant_name!);
    }
    if (delivery.delivery_special_instructions != null) {
      add(l10n.deliveryDetailFieldInstructions,
          delivery.delivery_special_instructions!);
    }
    add(
      l10n.deliveryDetailFieldFee,
      l10n.price((delivery.delivery_fee ?? 0).toStringAsFixed(2)),
    );

    if (rows.isEmpty) {
      return _EmptyHint(text: l10n.deliveryDetailEmptyShipping);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }
}

// ============================================================================
// METADATA BLOCK
// ============================================================================

class _MetadataBlock extends StatelessWidget {
  final Delivery delivery;

  const _MetadataBlock({required this.delivery});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rows = <Widget>[];

    void add(String label, dynamic value, {bool copyable = false}) {
      if (value == null) return;
      final text = value.toString().trim();
      if (text.isEmpty || text == 'null') return;
      rows.add(_InfoRow(label: label, value: text, copyable: copyable));
    }

    add(l10n.deliveryDetailFieldDeliveryId, delivery.id_delivery,
        copyable: true);
    add(l10n.deliveryDetailFieldProviderId, delivery.delivery_provider_id,
        copyable: true);
    add(l10n.deliveryDetailFieldBrokerId, delivery.delivery_broker_id,
        copyable: true);
    add(l10n.deliveryDetailFieldInvoiceRef, delivery.delivery_invoice_ref,
        copyable: true);
    add(l10n.deliveryDetailFieldSourceType, delivery.delivery_source_type);
    add(l10n.deliveryDetailFieldSourceId, delivery.delivery_source_id,
        copyable: true);
    add(l10n.deliveryDetailFieldAddressId, delivery.delivery_address_id,
        copyable: true);
    add(
      l10n.deliveryDetailFieldCurrentAddressId,
      delivery.delivery_current_address_id,
      copyable: true,
    );

    if (delivery.delivery_broker != null) {
      delivery.delivery_broker!.forEach((k, v) {
        add(l10n.deliveryDetailFieldBrokerEntry(k), v);
      });
    }

    if (delivery.delivery_created_at != null) {
      add(l10n.deliveryDetailFieldCreated, _fmt(delivery.delivery_created_at!));
    }
    if (delivery.delivery_updated_at != null) {
      add(l10n.deliveryDetailFieldUpdated, _fmt(delivery.delivery_updated_at!));
    }

    if (rows.isEmpty) {
      return _EmptyHint(text: l10n.deliveryDetailEmptyMetadata);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  static String _fmt(DateTime dt) => '${dt.day}/${dt.month}/${dt.year} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _EmptyHint extends StatelessWidget {
  final String text;

  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          fontStyle: FontStyle.italic,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 13,
        ),
      ),
    );
  }
}

// ============================================================================
// STATUS CONFIG — localized
// ============================================================================

class DeliveryStatusConfig {
  final IconData icon;
  final Color color;
  final String label;

  const DeliveryStatusConfig({
    required this.icon,
    required this.color,
    required this.label,
  });

  factory DeliveryStatusConfig.fromStatus(
    String status,
    AppLocalizations l10n,
  ) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return DeliveryStatusConfig(
          icon: Icons.schedule_rounded,
          color: const Color(0xFFF59E0B),
          label: l10n.deliveryStatusPending,
        );
      case 'PROCESSING':
        return DeliveryStatusConfig(
          icon: Icons.hourglass_top_rounded,
          color: const Color(0xFF3B82F6),
          label: l10n.deliveryStatusProcessing,
        );
      case 'CONFIRMED':
        return DeliveryStatusConfig(
          icon: Icons.verified_outlined,
          color: const Color(0xFF0EA5E9),
          label: l10n.deliveryStatusConfirmed,
        );
      case 'SHIPPED':
        return DeliveryStatusConfig(
          icon: Icons.local_shipping_rounded,
          color: const Color(0xFF8B5CF6),
          label: l10n.deliveryStatusShipped,
        );
      case 'IN_TRANSIT':
        return DeliveryStatusConfig(
          icon: Icons.local_shipping_outlined,
          color: const Color(0xFF8B5CF6),
          label: l10n.deliveryStatusInTransit,
        );
      case 'OUT_FOR_DELIVERY':
        return DeliveryStatusConfig(
          icon: Icons.delivery_dining_outlined,
          color: const Color(0xFFF97316),
          label: l10n.deliveryStatusOutForDelivery,
        );
      case 'DELIVERED':
        return DeliveryStatusConfig(
          icon: Icons.check_circle_outline_rounded,
          color: const Color(0xFF10B981),
          label: l10n.deliveryStatusDelivered,
        );
      case 'FAILED':
        return DeliveryStatusConfig(
          icon: Icons.error_outline_rounded,
          color: const Color(0xFFEF4444),
          label: l10n.deliveryStatusFailed,
        );
      case 'CANCELLED':
        return DeliveryStatusConfig(
          icon: Icons.cancel_outlined,
          color: const Color(0xFF6B7280),
          label: l10n.deliveryStatusCancelled,
        );
      case 'RETURNED':
        return DeliveryStatusConfig(
          icon: Icons.assignment_return_outlined,
          color: const Color(0xFFF59E0B),
          label: l10n.deliveryStatusReturned,
        );
      case 'REFUNDED':
        return DeliveryStatusConfig(
          icon: Icons.replay_rounded,
          color: const Color(0xFF06B6D4),
          label: l10n.deliveryStatusRefunded,
        );
      default:
        return DeliveryStatusConfig(
          icon: Icons.help_outline_rounded,
          color: const Color(0xFF9CA3AF),
          label: l10n.deliveryStatusUnknown,
        );
    }
  }
}

// ============================================================================
// SHIPPING METHOD LABELS — localized
// ============================================================================

class DeliveryShippingConfig {
  static String labelFor(String? method, AppLocalizations l10n) {
    switch ((method ?? 'standard').toLowerCase()) {
      case 'standard':
        return l10n.shippingMethodStandard;
      case 'express':
        return l10n.shippingMethodExpress;
      case 'overnight':
        return l10n.shippingMethodOvernight;
      case 'freight':
        return l10n.shippingMethodFreight;
      case 'pickup':
        return l10n.shippingMethodPickup;
      case 'courier':
        return l10n.shippingMethodCourier;
      case 'same_day':
        return l10n.shippingMethodSameDay;
      case 'international':
        return l10n.shippingMethodInternational;
      default:
        return l10n.shippingMethodStandard;
    }
  }
}
