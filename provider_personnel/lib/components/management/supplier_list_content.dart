import 'package:flutter/material.dart';
import 'package:verdelia_core/app/ManagementRule.dart';
import 'package:event/personnel_notifier.dart';
import 'package:provider_personnel/components/supplier_card.dart';
import 'package:provider_personnel/components/management/supplier_empty_state.dart';
import 'package:provider_personnel/components/management/supplier_loading_shimmer.dart';
import 'package:provider/provider.dart';

class SupplierListContent extends StatelessWidget {
  final String searchQuery;
  final int? selectedCategoryId;
  final int userId;
  final bool showActiveOnly; // Show only active suppliers
  final bool showPendingOnly; // Show only pending suppliers

  const SupplierListContent({
    super.key,
    required this.searchQuery,
    this.selectedCategoryId,
    required this.userId,
    this.showActiveOnly = false,
    this.showPendingOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PersonnelNotifier>(
      builder: (context, notifier, child) {
        // Get all management rules for this user
        final allRules = notifier.getRulesForUser(userId);

        if (notifier.isLoading && allRules.isEmpty) {
          return const SliverToBoxAdapter(child: SupplierLoadingShimmer());
        }

        // Filter rules based on status flags
        List<ManagementRule> filteredRules = allRules;

        if (showActiveOnly) {
          filteredRules = filteredRules
              .where((rule) => rule.isActive && !rule.isPending)
              .toList();
        } else if (showPendingOnly) {
          filteredRules =
              filteredRules.where((rule) => rule.isPending).toList();
        }

        // Apply search and category filters
        final displayRules = filteredRules.where(_filterRule).toList();

        if (displayRules.isEmpty) {
          return SliverToBoxAdapter(
            child: SupplierEmptyState(
              searchQuery: searchQuery,
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: SupplierCard(managementRule: displayRules[index]),
            ),
            childCount: displayRules.length,
          ),
        );
      },
    );
  }

  bool _filterRule(ManagementRule rule) {
    final productProvider = rule.productProvider;
    final providerDetails = productProvider?.productProviderDetails;

    if (productProvider == null || providerDetails == null) {
      return false; // Skip rules without provider info
    }

    // Search filter - check provider name and organisation name
    final providerName = providerDetails.providerName ?? '';
    final organisationName =
        rule.providerOrganisation?.providerOrganisationName ?? '';
    final organisationDesc =
        rule.providerOrganisation?.providerOrganisationDesc ?? '';

    final query = searchQuery.toLowerCase().trim();
    final matchesSearch = query.isEmpty ||
        providerName.toLowerCase().contains(query) ||
        organisationName.toLowerCase().contains(query) ||
        organisationDesc.toLowerCase().contains(query);

    // Category filter
    final matchesCategory = selectedCategoryId == null ||
        selectedCategoryId == 0 || // "All" category
        productProvider.productProviderTypeId == selectedCategoryId;

    return matchesSearch && matchesCategory;
  }
}
