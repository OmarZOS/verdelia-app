// lib/provider_geo/components/suppliers_panel.dart

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SupplierChangeNotifier>().fetchSupplierCategories();
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
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
    final localeLang = Localizations.localeOf(context).languageCode;

    return Card(
      color: isDarkMode
          ? theme.colorScheme.primaryContainer.withOpacity(0.2)
          : null,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _SupplierAvatar(supplier: supplier),
        title: _SupplierTitle(supplier: supplier),
        subtitle: _SupplierSubtitle(supplier: supplier),
        trailing: IconButton(
          icon: Icon(
            FontAwesomeIcons.locationDot,
            color: supplier.hasLocation
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
          ),
          onPressed: supplier.hasLocation ? onFocusLocation : null,
          tooltip: AppLocalizations.of(context)?.focusOnMapTooltip,
        ),
        onTap: () {
          context
              .read<SupplierChangeNotifier>()
              .selectSupplier(supplier.idProductProvider);
          showSupplierDetails(context, supplier);
        },
      ),
    );
  }
}

// ── Avatar ──

class _SupplierAvatar extends StatelessWidget {
  final Supplier supplier;

  const _SupplierAvatar({required this.supplier});

  static const double _radius = 24;

  bool get _hasValidImage {
    final url = supplier.supplierImageUrl;
    return url != null && url.isNotEmpty && url.startsWith('http');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diameter = _radius * 2;

    return CircleAvatar(
      radius: _radius,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: _hasValidImage
          ? ClipOval(
              child: Image.network(
                supplier.supplierImageUrl!,
                width: diameter,
                height: diameter,
                fit: BoxFit.cover,
                key: ValueKey(supplier.supplierImageUrl),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
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
              ),
            )
          : _fallbackIcon(theme),
    );
  }

  Widget _fallbackIcon(ThemeData theme) {
    return SvgPicture.asset(
      'assets/icons/${supplier.productProviderTypeId}.svg',
      package: 'provider_geo',
      width: 24,
      height: 24,
      color: theme.colorScheme.onSurface,
    );
  }
}

// ── Title ──

class _SupplierTitle extends StatelessWidget {
  final Supplier supplier;

  const _SupplierTitle({required this.supplier});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localeLang = Localizations.localeOf(context).languageCode;
    final displayName = supplier.nameFor(localeLang);

    return Text(
      displayName,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// ── Subtitle: organisation name + optional category chip ──

class _SupplierSubtitle extends StatelessWidget {
  final Supplier supplier;

  const _SupplierSubtitle({required this.supplier});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final localeLang = Localizations.localeOf(context).languageCode;
    final organisationName = supplier.organisationNameFor(localeLang);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (organisationName.isNotEmpty)
          Text(
            loc.by_organisation(organisationName),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        if (organisationName.isNotEmpty) const SizedBox(height: 4),
        _CategoryChip(supplier: supplier),
      ],
    );
  }
}

// ── Category chip ──

class _CategoryChip extends StatelessWidget {
  final Supplier supplier;

  const _CategoryChip({required this.supplier});

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
            // Leaf only — the chip is a glance affordance. The full
            // path is available from the same category if a future
            // screen needs it.
            return localizedCategoryLeaf(
              categoryPath: category.productCategoryDesc,
              localizedLeaf: category.nameFor(localeLang),
              localizations: loc,
            );
          }
        }
        return '';
      },
      builder: (context, categoryName, _) {
        final label = categoryName.isNotEmpty ? categoryName : loc.all;

        return Container(
          constraints: const BoxConstraints(maxWidth: 140),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.category_outlined,
                size: 11,
                color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
