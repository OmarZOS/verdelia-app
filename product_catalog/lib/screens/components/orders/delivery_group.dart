import 'package:verdelia_core/business/finance/OrderedItem.dart';

/// A single delivery and the ordered items that share it.
///
/// Items without a nested `delivery` record are collected into a
/// single "unassigned" group with `delivery == null`, so the UI can
/// render them without a delivery header (in a "Items" section that
/// follows the delivery blocks).
class DeliveryGroup {
  final OrderItemDelivery? delivery;
  final List<OrderedItem> items;

  const DeliveryGroup({required this.delivery, required this.items});

  bool get hasDelivery => delivery != null;

  /// Stable sort key for deterministic ordering: delivered/known
  /// deliveries first, ordered by id, then the unassigned group last.
  int get sortKey {
    if (delivery == null) return 1 << 30;
    return delivery!.idDelivery;
  }

  /// Groups [items] by their nested delivery id.
  ///
  /// Ordering: delivery groups sorted by `idDelivery`, then a trailing
  /// group of items with no delivery record. Within each group, item
  /// order is preserved.
  static List<DeliveryGroup> fromItems(List<OrderedItem> items) {
    final byDeliveryId = <int, List<OrderedItem>>{};
    final unassigned = <OrderedItem>[];

    for (final item in items) {
      final d = item.delivery;
      if (d == null) {
        unassigned.add(item);
      } else {
        byDeliveryId.putIfAbsent(d.idDelivery, () => []).add(item);
      }
    }

    final groups = <DeliveryGroup>[];
    for (final entry in byDeliveryId.entries) {
      groups.add(
        DeliveryGroup(
          delivery: entry.value.first.delivery,
          items: entry.value,
        ),
      );
    }
    groups.sort((a, b) => a.sortKey.compareTo(b.sortKey));

    if (unassigned.isNotEmpty) {
      groups.add(DeliveryGroup(delivery: null, items: unassigned));
    }
    return groups;
  }
}
