// supplier_entities_content.dart

import 'package:flutter/material.dart';
import 'package:verdelia_core/app/ManagementRule.dart';
import 'package:verdelia_core/business/Supplier.dart';
import 'package:event/personnel_notifier.dart';
import 'package:event/supplier_change_notifier.dart';
import 'package:event/user_change_notifier.dart';
import 'package:provider_personnel/components/management/supplier_empty_state.dart';
import 'package:provider_personnel/components/management/supplier_loading_shimmer.dart';
import 'package:provider/provider.dart';
import 'package:provider_personnel/components/supplier_card.dart';
import 'package:ui/components/supplier/supplier_screen.dart';

class SupplierEntitiesContent extends StatelessWidget {
  final String searchQuery;
  final int? selectedCategoryId;
  final bool showAllSuppliers;

  const SupplierEntitiesContent({
    Key? key,
    this.searchQuery = '',
    this.selectedCategoryId,
    this.showAllSuppliers = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<PersonnelNotifier, SupplierChangeNotifier>(
      builder: (context, personnelNotifier, supplierNotifier, child) {
        final userId = context.read<AppUserNotifier>().appUser?.idAppUser ?? 0;

        if (userId == 0) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        // Get all management rules for this user
        final allRules = personnelNotifier.getRulesForUser(userId);

        // Get owned suppliers
        final ownedSuppliers = supplierNotifier.suppliers
            .where((s) => s.productProviderOwnerId == userId)
            .toList();

        if (personnelNotifier.isLoading && allRules.isEmpty) {
          return const SliverToBoxAdapter(child: SupplierLoadingShimmer());
        }

        // Filter rules based on status
        List<ManagementRule> filteredRules = allRules;

        if (!showAllSuppliers) {
          // Show only active rules if not showing all
          filteredRules = filteredRules
              .where((rule) => rule.isActive && !rule.isPending)
              .toList();
        }

        // Apply search and category filters
        final displayRules = filteredRules.where((rule) {
          final productProvider = rule.productProvider;
          if (productProvider == null) return false;

          final providerName =
              productProvider.productProviderDetails.providerName ?? '';
          final organisationName =
              rule.providerOrganisation?.providerOrganisationName ?? '';

          final query = searchQuery.toLowerCase().trim();
          final matchesSearch = query.isEmpty ||
              providerName.toLowerCase().contains(query) ||
              organisationName.toLowerCase().contains(query);

          final matchesCategory = selectedCategoryId == null ||
              selectedCategoryId == 0 ||
              productProvider.productProviderTypeId == selectedCategoryId;

          return matchesSearch && matchesCategory;
        }).toList();

        // If no rules but has owned suppliers, show them
        if (displayRules.isEmpty &&
            ownedSuppliers.isNotEmpty &&
            !showAllSuppliers) {
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final supplier = ownedSuppliers[index];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: SupplierCard(
                    managementRule: _createRuleFromSupplier(supplier),
                    supplier: supplier,
                    onTap: () {
                      showSupplierDetails(context, supplier);
                    },
                  ),
                );
              },
              childCount: ownedSuppliers.length,
            ),
          );
        }

        if (displayRules.isEmpty) {
          return SliverToBoxAdapter(
            child: SupplierEmptyState(
              searchQuery: searchQuery,
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final rule = displayRules[index];
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: SupplierCard(managementRule: rule),
              );
            },
            childCount: displayRules.length,
          ),
        );
      },
    );
  }

  ManagementRule _createRuleFromSupplier(Supplier supplier) {
    return ManagementRule(
      idManagementRule: -1,
      ruleRefOrg: supplier.idProviderOrganisation,
      ruleRefProvider: supplier.idProductProvider,
      ruleRefUser: supplier.productProviderOwnerId,
      managementRuleCode: 0xFF,
      managementRuleStatus: 'ACTIVE',
      managementRuleExpiry: null,
      productProvider: ProductProvider(
        productProviderTypeId: supplier.productProviderTypeId,
        productProviderLocationId: supplier.idLocation ?? 0,
        productProviderOrgId: supplier.idProviderOrganisation,
        idProductProvider: supplier.idProductProvider,
        productProviderDetailsId: supplier.idProductProvider,
        productProviderOwner: supplier.productProviderOwnerId,
        productProviderDetails: ProductProviderDetails(
          providerName: supplier.providerName,
          idproviderDetailsId: supplier.idProductProvider,
          providerContactInfo: supplier.locationName ?? '',
        ),
      ),
      providerOrganisation: ProviderOrganisation(
        idproviderOrganisation: supplier.idProviderOrganisation,
        providerOrganisationName: supplier.providerName,
        // providerOrganisationDesc: supplier.providerDescription,
      ),
    );
  }
}
