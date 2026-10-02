import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:verdelia_core/business/Organisation.dart';
import 'package:verdelia_core/business/Supplier.dart';
import 'package:verdelia_core/mediation/StorageService.dart';
import 'supplier_filter.dart';

class SupplierState {
  final List<Supplier> suppliers = [];
  List<SupplierCategory> categories = [];
  final Map<int, Organisation> organisations = {};
  Position? currentLocation;
  SupplierFilter filter = const SupplierFilter();
  bool isLoading = false;
  bool hasMoreSuppliers = true;
  bool hasMoreOrganisations = true;
  int suppliersPage = 0;
  int organisationsPage = 0;

  // Pagination constants
  static const int itemsPerPage = 50;
  static const int organisationsPerPage = 30;

  List<Supplier> get filteredSuppliers => _applyFilters();

  List<Supplier> _applyFilters() {
    if (filter.isEmpty) return List.unmodifiable(suppliers);

    return suppliers.where((supplier) {
      if (filter.name != null &&
          !supplier.providerName
              .toLowerCase()
              .contains(filter.name!.toLowerCase())) {
        return false;
      }
      if (filter.organisationId != null &&
          supplier.idProviderOrganisation != filter.organisationId) {
        return false;
      }
      if (filter.ownerId != null &&
          supplier.productProviderOwnerId != filter.ownerId) {
        return false;
      }
      if (filter.types != null && filter.types!.isNotEmpty) {
        final type = supplier.productProviderTypeId;
        if (type == null || !filter.types!.contains(type)) {
          return false;
        }
      }
      if (filter.hasLocation != null) {
        final hasLoc = supplier.locationLatitude != null &&
            supplier.locationLongitude != null;
        if (hasLoc != filter.hasLocation) return false;
      }
      return true;
    }).toList();
  }

  void reset() {
    suppliers.clear();
    categories.clear();
    organisations.clear();
    currentLocation = null;
    filter = const SupplierFilter();
    suppliersPage = 0;
    organisationsPage = 0;
    hasMoreSuppliers = true;
    hasMoreOrganisations = true;
    isLoading = false;
  }

  Organisation? getOrganisation(int id) => organisations[id];
}
