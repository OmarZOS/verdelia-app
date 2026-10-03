// lib/provider_geo/components/suppliers_panel.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:app_constants/app_constants.dart';
import 'package:verdelia_core/business/Supplier.dart';
import 'package:provider_geo/components/location_filter.dart';
import 'package:ui/components/supplier/supplier_screen.dart';
import 'package:provider/provider.dart';
import 'package:event/supplier_change_notifier.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ui/utils/category_hierarchy.dart';

class PanelContent extends StatefulWidget {
  final List<Supplier> suppliers;
  final bool isLoading;
  final ScrollController scrollController;
  final Function focusOnLocation;
  final dynamic selectedLocation;
  final Function? onDeleteLocationFilter;
  final Function applyLocationFilter;

  const PanelContent({
    Key? key,
    required this.suppliers,
    required this.isLoading,
    required this.scrollController,
    required this.focusOnLocation,
    required this.selectedLocation,
    this.onDeleteLocationFilter,
    required this.applyLocationFilter,
  }) : super(key: key);

  @override
  State<PanelContent> createState() => _PanelContentState();
}

class _PanelContentState extends State<PanelContent> {
  final ValueNotifier<bool>? _localFilterNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _localFilterNotifier!.value = widget.selectedLocation != null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted)
        context.read<SupplierChangeNotifier>().fetchSupplierCategories();
    });
  }

  @override
  void didUpdateWidget(covariant PanelContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedLocation != oldWidget.selectedLocation) {
      _localFilterNotifier?.value = widget.selectedLocation != null;
    }
  }

  @override
  void dispose() {
    _localFilterNotifier?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeaderSection(theme, loc),
        const SizedBox(height: 8),
        _buildSupplierList(theme, loc, isDarkMode),
      ],
    );
  }

  Widget _buildHeaderSection(ThemeData theme, AppLocalizations loc) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 60,
              height: 5,
              decoration: BoxDecoration(
                color: theme.dividerColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  loc.providersText,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: _localFilterNotifier!,
                builder: (context, isFilterApplied, child) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: widget.selectedLocation != null
                          ? theme.colorScheme.primary.withOpacity(0.2)
                          : theme.colorScheme.primary.withOpacity(0.1),
                    ),
                    child: IconButton(
                      onPressed: () => LocationFilterBottomSheet.show(
                        context,
                        widget.applyLocationFilter,
                        widget.selectedLocation,
                      ),
                      icon: Icon(
                        Icons.filter_list_rounded,
                        color: widget.selectedLocation != null
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primary.withOpacity(0.7),
                        size: 24,
                      ),
                      // tooltip: loc.filterByLocationTooltip,
                    ),
                  );
                },
              ),
            ],
          ),
          if (widget.selectedLocation != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InputChip(
                  label: Text(
                    widget.selectedLocation!["name"],
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onDeleted: () {
                    if (widget.onDeleteLocationFilter != null) {
                      widget.onDeleteLocationFilter!();
                    }
                  },
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  deleteIcon: Icon(
                    Icons.close,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSupplierList(
      ThemeData theme, AppLocalizations loc, bool isDarkMode) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.suppliers.isEmpty) {
      return Center(
        child: Text(
          loc.notFoundError,
          style: theme.textTheme.bodyLarge,
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        controller: widget.scrollController,
        itemCount: widget.suppliers.length,
        itemBuilder: (context, index) {
          final supplier = widget.suppliers[index];
          final languageCode = Localizations.localeOf(context).languageCode;
          final localizations = AppLocalizations.of(context)!;
          return Selector<SupplierChangeNotifier, String>(
            selector: (_, notifier) {
              final matchingCategories = notifier.supplierCategories.where(
                (category) =>
                    category.productProviderTypeId ==
                    supplier.productProviderTypeId,
              );
              if (matchingCategories.isEmpty) return '';
              final category = matchingCategories.first;
              return localizedCategoryHierarchy(
                categoryPath: category.productCategoryDesc,
                localizedLeaf: category.nameFor(languageCode),
                localizations: localizations,
              );
            },
            builder: (context, categoryName, _) => _buildSupplierItem(
              supplier,
              theme,
              loc,
              isDarkMode,
              categoryName,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSupplierItem(Supplier supplier, ThemeData theme,
      AppLocalizations loc, bool isDarkMode, String categoryName) {
    final category = categoryName.isNotEmpty ? categoryName : 'General';

    return Card(
      color: isDarkMode
          ? theme.colorScheme.primaryContainer.withOpacity(0.2)
          : null,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildSupplierImage(supplier, theme),
        title: _buildSupplierTitle(supplier, category, theme),
        subtitle: _buildSupplierSubtitle(supplier, theme, loc),
        trailing: _buildLocationButton(supplier, theme),
        onTap: () {
          Provider.of<SupplierChangeNotifier>(context, listen: false)
              .selectSupplier(supplier.idProductProvider);
          showSupplierDetails(context, supplier);
        },
      ),
    );
  }

  Widget _buildSupplierImage(Supplier supplier, ThemeData theme) {
    return CircleAvatar(
        radius: 40,
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Image.network(
          (supplier.supplierImageUrl ?? ""),
          width: 40,
          height: 40,
          alignment: Alignment.center,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return SvgPicture.asset(
              'assets/icons/${supplier.productProviderTypeId}.svg',
              package: "provider_geo",
              width: 30,
              height: 30,
              color: Theme.of(context).colorScheme.onSurface,
            );
          },
          key: ValueKey(supplier.supplierImageUrl),
        ));
  }

  Widget _buildSupplierTitle(
      Supplier supplier, String category, ThemeData theme) {
    // Resolve the supplier name for the ambient locale. `nameFor`
    // prefers the naming contribution's translation when present and
    // falls back to the flat provider name otherwise.
    final localeLang = Localizations.localeOf(context).languageCode;
    final displayName = supplier.nameFor(localeLang);

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          displayName,
          style: theme.textTheme.titleMedium,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            category,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSupplierSubtitle(
      Supplier supplier, ThemeData theme, AppLocalizations loc) {
    // Same treatment for the organisation name.
    final localeLang = Localizations.localeOf(context).languageCode;
    final organisationName = supplier.organisationNameFor(localeLang);

    return Text(
      loc.by_organisation(organisationName),
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface.withOpacity(0.6),
      ),
    );
  }

  Widget _buildLocationButton(Supplier supplier, ThemeData theme) {
    return IconButton(
      icon: Icon(
        FontAwesomeIcons.locationDot,
        color: theme.colorScheme.primary,
      ),
      onPressed: () => widget.focusOnLocation(
          supplier.locationLatitude, supplier.locationLongitude),
    );
  }
}
