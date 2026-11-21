// personnel_access_manager.dart
import 'dart:developer';

import 'package:event/personnel_notifier.dart';
import 'package:event/supplier_change_notifier.dart';
import 'package:verdelia_core/business/Supplier.dart';

enum SupplierAccessType { owner, managed, none }

class AccessibleSupplier {
  final Supplier supplier;
  final bool isOwner;
  final bool isManaged;
  final int? ruleId;

  const AccessibleSupplier({
    required this.supplier,
    required this.isOwner,
    required this.isManaged,
    this.ruleId,
  });

  SupplierAccessType get accessType {
    if (isOwner) return SupplierAccessType.owner;
    if (isManaged) return SupplierAccessType.managed;
    return SupplierAccessType.none;
  }

  int get id => supplier.idProductProvider;
  String get name => supplier.providerName ?? 'Unnamed Business';

  @override
  String toString() =>
      'AccessibleSupplier(id: $id, owner: $isOwner, managed: $isManaged, '
      'ruleId: $ruleId)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccessibleSupplier &&
          other.id == id &&
          other.isOwner == isOwner &&
          other.isManaged == isManaged &&
          other.ruleId == ruleId;

  @override
  int get hashCode => Object.hash(id, isOwner, isManaged, ruleId);
}

class PersonnelAccessManager {
  final PersonnelNotifier personnelNotifier;
  final SupplierChangeNotifier supplierNotifier;

  /// The `userId` the personnel notifier was last scoped to. Read
  /// from the notifier's own cache marker so the manager and the
  /// notifier cannot disagree.
  PersonnelAccessManager({
    required this.personnelNotifier,
    required this.supplierNotifier,
  });

  Future<List<AccessibleSupplier>> getAccessibleSuppliersWithAccessType(
    int userId, {
    bool forceRefresh = false,
  }) async {
    log('[MANAGER] Resolving accessible suppliers for user $userId');

    await _ensureOwnedSuppliersLoaded(userId, forceRefresh: forceRefresh);
    await _ensurePersonnelLoaded(userId, forceRefresh: forceRefresh);

    final ownedSuppliers = supplierNotifier.getSuppliersOwnedByUser(userId);
    final allSuppliers = supplierNotifier.suppliers;
    final accessibleIdSet =
        personnelNotifier.getAccessibleSupplierIds(userId).toSet();

    final result = <AccessibleSupplier>[];
    final addedIds = <int>{};

    // Pass 1: suppliers present in the general list.
    for (final supplier in allSuppliers) {
      final supplierId = supplier.idProductProvider;
      if (addedIds.contains(supplierId)) continue;

      final isOwned = supplier.productProviderOwnerId == userId;
      final isManaged = accessibleIdSet.contains(supplierId);
      if (!isOwned && !isManaged) continue;

      result.add(AccessibleSupplier(
        supplier: supplier,
        isOwner: isOwned,
        isManaged: isManaged,
        ruleId: isManaged
            ? personnelNotifier.getRuleIdFor(userId, supplierId)
            : null,
      ));
      addedIds.add(supplierId);
    }

    // Pass 2: owned suppliers the list pass missed.
    for (final supplier in ownedSuppliers) {
      final supplierId = supplier.idProductProvider;
      if (addedIds.contains(supplierId)) continue;

      final isManaged = accessibleIdSet.contains(supplierId);
      result.add(AccessibleSupplier(
        supplier: supplier,
        isOwner: true,
        isManaged: isManaged,
        ruleId: isManaged
            ? personnelNotifier.getRuleIdFor(userId, supplierId)
            : null,
      ));
      addedIds.add(supplierId);
    }

    _sortAccessible(result);
    return result;
  }

  List<AccessibleSupplier> getAccessibleSuppliersWithAccessTypeSync(
    int userId, {
    List<Supplier>? ownedSuppliers,
  }) {
    final owned =
        ownedSuppliers ?? supplierNotifier.getSuppliersOwnedByUser(userId);
    final accessibleIdSet =
        personnelNotifier.getAccessibleSupplierIds(userId).toSet();

    final result = <AccessibleSupplier>[];
    final addedIds = <int>{};

    for (final supplier in supplierNotifier.suppliers) {
      final supplierId = supplier.idProductProvider;
      if (addedIds.contains(supplierId)) continue;

      final isOwned = supplier.productProviderOwnerId == userId;
      final isManaged = accessibleIdSet.contains(supplierId);
      if (!isOwned && !isManaged) continue;

      result.add(AccessibleSupplier(
        supplier: supplier,
        isOwner: isOwned,
        isManaged: isManaged,
        ruleId: isManaged
            ? personnelNotifier.getRuleIdFor(userId, supplierId)
            : null,
      ));
      addedIds.add(supplierId);
    }

    for (final supplier in owned) {
      final supplierId = supplier.idProductProvider;
      if (addedIds.contains(supplierId)) continue;

      final isManaged = accessibleIdSet.contains(supplierId);
      result.add(AccessibleSupplier(
        supplier: supplier,
        isOwner: true,
        isManaged: isManaged,
        ruleId: isManaged
            ? personnelNotifier.getRuleIdFor(userId, supplierId)
            : null,
      ));
      addedIds.add(supplierId);
    }

    _sortAccessible(result);
    return result;
  }

  Future<List<Supplier>> getAccessibleSuppliers(int userId) async {
    final accessible = await getAccessibleSuppliersWithAccessType(userId);
    return accessible.map((a) => a.supplier).toList();
  }

  Future<List<Supplier>> getManagedSuppliers(int userId) async {
    final accessible = await getAccessibleSuppliersWithAccessType(userId);
    return accessible
        .where((a) => a.isManaged && !a.isOwner)
        .map((a) => a.supplier)
        .toList();
  }

  bool isOwner(int userId, int supplierId) {
    // Only trust the state fast-path when the owned cache is warm
    // for this user. Otherwise ask the (user-keyed) owned cache.
    if (supplierNotifier.ownedCacheUserId == userId) {
      for (final s in supplierNotifier.suppliers) {
        if (s.idProductProvider == supplierId) {
          return s.productProviderOwnerId == userId;
        }
      }
    }
    return supplierNotifier
        .getSuppliersOwnedByUser(userId)
        .any((s) => s.idProductProvider == supplierId);
  }

  SupplierAccessType getAccessType(int userId, int supplierId) {
    final owned = isOwner(userId, supplierId);
    final managed = personnelNotifier.hasAccessToSupplier(userId, supplierId);
    if (owned) return SupplierAccessType.owner;
    if (managed) return SupplierAccessType.managed;
    return SupplierAccessType.none;
  }

  // ── Internals ─────────────────────────────────────────────────────

  Future<void> _ensureOwnedSuppliersLoaded(
    int userId, {
    required bool forceRefresh,
  }) async {
    if (!forceRefresh && supplierNotifier.ownedCacheUserId == userId) {
      return;
    }
    await supplierNotifier.fetchOwnedSuppliers(
      userId,
      forceRefresh: forceRefresh,
    );
  }

  Future<void> _ensurePersonnelLoaded(
    int userId, {
    required bool forceRefresh,
  }) async {
    // fetchForUser is idempotent when the notifier is already scoped
    // to this user and `forceRefresh` is false — the loading guard
    // inside `loadPersonnel` handles it.
    if (!forceRefresh) {
      await personnelNotifier.fetchForUser(userId, forceRefresh: false);
      return;
    }
    await personnelNotifier.fetchForUser(userId, forceRefresh: true);
  }

  void _sortAccessible(List<AccessibleSupplier> list) {
    list.sort((a, b) {
      final rank = _rank(a).compareTo(_rank(b));
      if (rank != 0) return rank;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }

  int _rank(AccessibleSupplier a) {
    if (a.isOwner) return 0;
    if (a.isManaged) return 1;
    return 2;
  }
}
