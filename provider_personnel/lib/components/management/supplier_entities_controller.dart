// supplier_entities_controller.dart (ChangeNotifier version)

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:verdelia_core/app/ManagementRule.dart';
import 'package:verdelia_core/business/Supplier.dart';
import 'package:event/personnel_notifier.dart';
import 'package:event/supplier_change_notifier.dart';
import 'package:event/user_change_notifier.dart';
import 'package:provider_personnel/components/management/supplier_app_bar.dart';
import 'package:provider_personnel/components/management/supplier_search_filter.dart';
import 'package:provider/provider.dart';

class SupplierEntitiesState {
  final String searchQuery;
  final int? selectedCategoryId;
  final bool showAllSuppliers;

  SupplierEntitiesState({
    this.searchQuery = '',
    this.selectedCategoryId,
    this.showAllSuppliers = true,
  });

  SupplierEntitiesState copyWith({
    String? searchQuery,
    int? selectedCategoryId,
    bool? showAllSuppliers,
  }) {
    return SupplierEntitiesState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      showAllSuppliers: showAllSuppliers ?? this.showAllSuppliers,
    );
  }
}

class SupplierEntitiesController extends ChangeNotifier {
  SupplierEntitiesState _state = SupplierEntitiesState();
  final TextEditingController _searchController = TextEditingController();

  SupplierEntitiesState get state => _state;

  void initializeData(BuildContext context) {
    final supplierNotifier = context.read<SupplierChangeNotifier>();
    final personnelNotifier = context.read<PersonnelNotifier>();

    supplierNotifier.fetchSupplierCategories();

    if (supplierNotifier.suppliers.isEmpty) {
      supplierNotifier.fetchSuppliers(reset: true);
    }

    personnelNotifier.loadPersonnel(supplierId: 0, includePending: true);

    _searchController.addListener(() {
      _state = _state.copyWith(
        searchQuery: _searchController.text.trim(),
      );
      notifyListeners();
    });
  }

  void updateCategory(int? categoryId) {
    _state = _state.copyWith(selectedCategoryId: categoryId);
    notifyListeners();
  }

  void toggleShowAll(bool showAll) {
    _state = _state.copyWith(showAllSuppliers: showAll);
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    _state = _state.copyWith(searchQuery: query);
    notifyListeners();
  }

  Widget buildAppBar(BuildContext context) {
    return SupplierAppBar(
      searchQuery: _state.searchQuery,
      selectedCategoryId: _state.selectedCategoryId,
      onCategoryChanged: updateCategory,
      showAllSuppliers: _state.showAllSuppliers,
      onShowAllChanged: toggleShowAll,
    );
  }

  Widget buildSearchFilter(BuildContext context) {
    return SupplierSearchFilter(
      searchController: _searchController,
      searchQuery: _state.searchQuery,
      onSearchChanged: (query) {
        _state = _state.copyWith(searchQuery: query);
        notifyListeners();
      },
      selectedCategoryId: _state.selectedCategoryId,
      onCategoryChanged: updateCategory,
    );
  }

  List<Supplier> filterOwnedSuppliers(
    List<Supplier> suppliers,
    String searchQuery,
    int? selectedCategoryId,
  ) {
    return suppliers.where((supplier) {
      final matchesSearch = searchQuery.isEmpty ||
          supplier.providerName
              .toLowerCase()
              .contains(searchQuery.toLowerCase());

      final matchesCategory = selectedCategoryId == null ||
          selectedCategoryId == 0 ||
          supplier.productProviderTypeId == selectedCategoryId;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<ManagementRule> filterManagedRules(
    List<ManagementRule> rules,
    String searchQuery,
    int? selectedCategoryId,
  ) {
    return rules.where((rule) {
      final productProvider = rule.productProvider;
      if (productProvider == null) return false;

      final providerName =
          productProvider.productProviderDetails.providerName ?? '';
      final organisationName =
          rule.providerOrganisation?.providerOrganisationName ?? '';

      final matchesSearch = searchQuery.isEmpty ||
          providerName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          organisationName.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesCategory = selectedCategoryId == null ||
          selectedCategoryId == 0 ||
          productProvider.productProviderTypeId == selectedCategoryId;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  Widget buildFloatingActionButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FloatingActionButton(
      onPressed: _addNewBusiness,
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Icon(Icons.add_business_rounded, size: 24),
    );
  }

  void _addNewBusiness() {
    // Navigate to add business screen
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
