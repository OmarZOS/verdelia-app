// lib/provider_geo/components/suppliers_panel.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
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
  bool _categoriesFetched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SupplierChangeNotifier>().fetchSupplierCategories();
      _categoriesFetched = true;
    });
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

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeaderSection(ThemeData theme, AppLocalizations loc) {
    final active = widget.selectedLocation != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
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
          // Drag handle
          Container(
            width: 60,
            height: 5,
            decoration: BoxDecoration(
              color: theme.dividerColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          Row(
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _buildFilterButton(theme, loc),
            ],
          ),
          if (widget.selectedLocation != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: InputChip(
                  label: Text(
                    widget.selectedLocation!['name']?.toString() ?? '',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onDeleted: () => widget.onDeleteLocationFilter?.call(),
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
  // ============================================================
  // LIST
  // ============================================================

  Widget _buildSupplierList(
      ThemeData theme, AppLocalizations loc, bool isDarkMode) {
    if (widget.isLoading && widget.suppliers.isEmpty) {
      return const Expanded(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.suppliers.isEmpty) {
      return Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              loc.notFoundError,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        controller: widget.scrollController,
        itemCount: widget.suppliers.length,
        itemBuilder: (context, index) {
          final supplier = widget.suppliers[index];
          return _SupplierTile(
            supplier: supplier,
            isDarkMode: isDarkMode,
            onFocusLocation: () => widget.focusOnLocation(
              supplier.locationLatitude,
              supplier.locationLongitude,
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterButton(ThemeData theme, AppLocalizations loc) {
    final active = widget.selectedLocation != null;

    // Explicit min tap target. Material's guideline is 48x48. We give
    // it 48x48 exactly so hit testing never lands on a partially
    // animated edge.
    return SizedBox(
      width: 48,
      height: 48,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: theme.colorScheme.primary.withOpacity(active ? 0.2 : 0.1),
          ),
          child: InkWell(
            onTap: () {
              LocationFilterBottomSheet.show(
                context,
                widget.applyLocationFilter,
                widget.selectedLocation,
              );
            },
            borderRadius: BorderRadius.circular(12),
            splashColor: theme.colorScheme.primary.withOpacity(0.15),
            highlightColor: theme.colorScheme.primary.withOpacity(0.08),
            child: Center(
              child: Icon(
                Icons.filter_list_rounded,
                color: active
                    ? theme.colorScheme.primary
                    : theme.colorScheme.primary.withOpacity(0.7),
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SUPPLIER TILE
// ============================================================================
//
// Extracted into its own widget so the per-supplier Selector lives at a
// stable widget identity. Rebuilding the parent list doesn't re-subscribe
// each row.

class _SupplierTile extends StatelessWidget {
  final Supplier supplier;
  final bool isDarkMode;
  final VoidCallback onFocusLocation;

  const _SupplierTile({
    required this.supplier,
    required this.isDarkMode,
    required this.onFocusLocation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final localeLang = Localizations.localeOf(context).languageCode;

    return Selector<SupplierChangeNotifier, String>(
      selector: (_, notifier) {
        for (final category in notifier.supplierCategories) {
          if (category.productProviderTypeId ==
              supplier.productProviderTypeId) {
            return localizedCategoryHierarchy(
              categoryPath: category.productCategoryDesc,
              localizedLeaf: category.nameFor(localeLang),
              localizations: loc,
            );
          }
        }
        return '';
      },
      builder: (context, categoryName, _) {
        return Card(
          color: isDarkMode
              ? theme.colorScheme.primaryContainer.withOpacity(0.2)
              : null,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: _SupplierAvatar(supplier: supplier),
            title: _SupplierTitle(
              supplier: supplier,
              categoryName: categoryName,
            ),
            subtitle: _SupplierSubtitle(supplier: supplier),
            trailing: IconButton(
              icon: Icon(
                FontAwesomeIcons.locationDot,
                color: supplier.hasLocation
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
              ),
              onPressed: supplier.hasLocation ? onFocusLocation : null,
            ),
            onTap: () {
              context
                  .read<SupplierChangeNotifier>()
                  .selectSupplier(supplier.idProductProvider);
              showSupplierDetails(context, supplier);
            },
          ),
        );
      },
    );
  }
}

// ── Avatar ──

class _SupplierAvatar extends StatelessWidget {
  final Supplier supplier;

  const _SupplierAvatar({required this.supplier});

  bool get _hasValidImage {
    final url = supplier.supplierImageUrl;
    return url != null && url.isNotEmpty && url.startsWith('http');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CircleAvatar(
      radius: 40,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: _hasValidImage
          ? Image.network(
              supplier.supplierImageUrl!,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              key: ValueKey(supplier.supplierImageUrl),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => _fallbackIcon(theme),
            )
          : _fallbackIcon(theme),
    );
  }

  Widget _fallbackIcon(ThemeData theme) {
    return SvgPicture.asset(
      'assets/icons/${supplier.productProviderTypeId}.svg',
      package: 'provider_geo',
      width: 30,
      height: 30,
      color: theme.colorScheme.onSurface,
    );
  }
}

// ── Title ──

class _SupplierTitle extends StatelessWidget {
  final Supplier supplier;
  final String categoryName;

  const _SupplierTitle({
    required this.supplier,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localeLang = Localizations.localeOf(context).languageCode;
    final displayName = supplier.nameFor(localeLang);
    final category =
        categoryName.isNotEmpty ? categoryName : _fallbackCategory(context);

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          displayName,
          style: theme.textTheme.titleMedium,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _fallbackCategory(BuildContext context) {
    return AppLocalizations.of(context)?.all ?? 'General';
  }
}

// ── Subtitle ──

class _SupplierSubtitle extends StatelessWidget {
  final Supplier supplier;

  const _SupplierSubtitle({required this.supplier});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final localeLang = Localizations.localeOf(context).languageCode;
    final organisationName = supplier.organisationNameFor(localeLang);

    if (organisationName.isEmpty) return const SizedBox.shrink();

    return Text(
      loc.by_organisation(organisationName),
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface.withOpacity(0.6),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
