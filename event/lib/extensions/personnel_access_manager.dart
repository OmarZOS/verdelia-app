// personnel_access_manager.dart
// RESPONSIBILITY: Coordinate between Personnel and Supplier notifiers

import 'dart:developer';

import 'package:event/personnel_notifier.dart';
import 'package:event/supplier_change_notifier.dart';
import 'package:verdelia_core/business/Supplier.dart';

class AccessibleSupplier {
  final Supplier supplier;
  final SupplierAccessType accessType;

  const AccessibleSupplier({
    required this.supplier,
    required this.accessType,
  });

  /// Check if this supplier is owned by the user
  bool get isOwner => accessType == SupplierAccessType.owner;

  /// Check if this supplier is managed (staff access)
  bool get isManaged => accessType == SupplierAccessType.managed;

  /// Get the supplier ID
  int get id => supplier.idProductProvider;

  /// Get the supplier name
  String get name => supplier.providerName ?? 'Unnamed Business';

  @override
  String toString() {
    return 'AccessibleSupplier(id: ${supplier.idProductProvider}, name: ${supplier.providerName}, accessType: $accessType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccessibleSupplier &&
        other.supplier.idProductProvider == supplier.idProductProvider &&
        other.accessType == accessType;
  }

  @override
  int get hashCode => supplier.idProductProvider.hashCode ^ accessType.hashCode;
}

class PersonnelAccessManager {
  final PersonnelNotifier personnelNotifier;
  final SupplierChangeNotifier supplierNotifier;

  PersonnelAccessManager({
    required this.personnelNotifier,
    required this.supplierNotifier,
  });

  // personnel_access_manager.dart

  Future<List<AccessibleSupplier>> getAccessibleSuppliersWithAccessType(
    int userId, {
    bool forceRefresh = false,
  }) async {
    log('🔄 [MANAGER] Fetching accessible suppliers for user: $userId');

    // ✅ Load owned suppliers first
    final ownedSuppliers = await supplierNotifier.fetchOwnedSuppliers(
      userId,
      forceRefresh: forceRefresh,
    );

    log('👑 [MANAGER] Loaded ${ownedSuppliers.length} owned suppliers');

    // ✅ If we already have suppliers and not forcing refresh, use them
    List<Supplier> allSuppliers;
    if (supplierNotifier.suppliers.isNotEmpty && !forceRefresh) {
      allSuppliers = supplierNotifier.suppliers;
      log('📦 [MANAGER] Using ${allSuppliers.length} cached suppliers');
    } else {
      log('📦 [MANAGER] Fetching all suppliers...');
      await supplierNotifier.fetchSuppliers(
        ownerId: userId,
        reset: true,
        forceRefresh: forceRefresh,
      );
      allSuppliers = supplierNotifier.suppliers;
      log('📦 [MANAGER] Fetched ${allSuppliers.length} suppliers');
    }

    // ✅ Get accessible IDs from personnel (for managed suppliers)
    final accessibleIds = personnelNotifier.getAccessibleSupplierIds(userId);
    final accessibleIdSet = accessibleIds.toSet();

    // ✅ Build result efficiently using a Set for O(1) lookups
    final result = <AccessibleSupplier>[];
    final addedIds = <int>{};

    // Process all suppliers
    for (final supplier in allSuppliers) {
      final supplierId = supplier.idProductProvider;
      if (addedIds.contains(supplierId)) continue;

      final isOwned = supplier.productProviderOwnerId == userId;
      final isManaged = accessibleIdSet.contains(supplierId);

      if (!isOwned && !isManaged) continue;

      result.add(AccessibleSupplier(
        supplier: supplier,
        accessType:
            isOwned ? SupplierAccessType.owner : SupplierAccessType.managed,
      ));
      addedIds.add(supplierId);
    }

    // ✅ Add any owned suppliers that weren't in allSuppliers
    for (final supplier in ownedSuppliers) {
      final supplierId = supplier.idProductProvider;
      if (addedIds.contains(supplierId)) continue;

      result.add(AccessibleSupplier(
        supplier: supplier,
        accessType: SupplierAccessType.owner,
      ));
      addedIds.add(supplierId);
    }

    log('✅ [MANAGER] Found ${result.length} accessible suppliers');

    // Sort: Owners first, then managed
    result.sort((a, b) {
      if (a.accessType == b.accessType) {
        return a.name.compareTo(b.name);
      }
      return a.accessType == SupplierAccessType.owner ? -1 : 1;
    });

    return result;
  }

  List<AccessibleSupplier> getAccessibleSuppliersWithAccessTypeSync(
      int userId) {
    final allSuppliers = supplierNotifier.suppliers;
    final accessibleIds = personnelNotifier.getAccessibleSupplierIds(userId);
    final accessibleIdSet = accessibleIds.toSet();

    final result = <AccessibleSupplier>[];
    final addedIds = <int>{};

    for (final supplier in allSuppliers) {
      final supplierId = supplier.idProductProvider;
      if (addedIds.contains(supplierId)) continue;

      final isOwned = supplier.productProviderOwnerId == userId;
      final isManaged = accessibleIdSet.contains(supplierId);

      if (!isOwned && !isManaged) continue;

      result.add(AccessibleSupplier(
        supplier: supplier,
        accessType:
            isOwned ? SupplierAccessType.owner : SupplierAccessType.managed,
      ));
      addedIds.add(supplierId);
    }

    result.sort((a, b) {
      if (a.accessType == b.accessType) {
        return a.name.compareTo(b.name);
      }
      return a.accessType == SupplierAccessType.owner ? -1 : 1;
    });

    return result;
  }

  /// Get all suppliers a user has access to (owned + managed)
  Future<List<Supplier>> getAccessibleSuppliers(int userId) async {
    final ownedSuppliers = supplierNotifier.getSuppliersOwnedByUser(userId);
    final accessibleIds = personnelNotifier.getAccessibleSupplierIds(userId);

    // Filter out owned IDs that are already in the list
    final ownedIds = ownedSuppliers.map((s) => s.idProductProvider).toSet();
    final managedIds =
        accessibleIds.where((id) => !ownedIds.contains(id)).toList();

    // Fetch managed suppliers in batch
    final managedSuppliers =
        await supplierNotifier.getSuppliersByIds(managedIds);

    return [...ownedSuppliers, ...managedSuppliers];
  }

  /// Get only managed suppliers (excludes owned)
  Future<List<Supplier>> getManagedSuppliers(int userId) async {
    final accessibleIds = personnelNotifier.getAccessibleSupplierIds(userId);
    final ownedIds = supplierNotifier
        .getSuppliersOwnedByUser(userId)
        .map((s) => s.idProductProvider)
        .toSet();

    final managedIds =
        accessibleIds.where((id) => !ownedIds.contains(id)).toList();
    return await supplierNotifier.getSuppliersByIds(managedIds);
  }

  /// Check if user owns a supplier
  bool isOwner(int userId, int supplierId) {
    // Fast path: already-loaded suppliers list.
    for (final s in supplierNotifier.suppliers) {
      if (s.idProductProvider == supplierId) {
        return s.productProviderOwnerId == userId;
      }
    }
    // Fallback: dedicated owner cache.
    return supplierNotifier
        .getSuppliersOwnedByUser(userId)
        .any((s) => s.idProductProvider == supplierId);
  }

  /// Get access type for a supplier
  SupplierAccessType getAccessType(int userId, int supplierId) {
    if (isOwner(userId, supplierId)) {
      return SupplierAccessType.owner;
    }
    if (personnelNotifier.hasAccessToSupplier(userId, supplierId)) {
      return SupplierAccessType.managed;
    }
    return SupplierAccessType.none;
  }
}

enum SupplierAccessType {
  owner,
  managed,
  none,
}
