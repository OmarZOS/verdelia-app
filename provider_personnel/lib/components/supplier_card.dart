// lib/ui/SupplierCard.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:verdelia_core/app/ManagementRule.dart';
import 'package:verdelia_core/business/Supplier.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:event/supplier_change_notifier.dart';
import 'package:provider_personnel/personnel_management_screen.dart';
import 'package:provider/provider.dart';
import 'package:ui/utils/category_hierarchy.dart';

class SupplierCard extends StatelessWidget {
  final ManagementRule? managementRule;
  final Supplier? supplier;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? statusColor;
  final String? statusText;

  const SupplierCard({
    super.key,
    this.managementRule,
    this.supplier,
    this.onTap,
    this.trailing,
    this.statusColor,
    this.statusText,
  });

  // ==================== Name resolution ====================

  String _localizedName(BuildContext context) {
    if (supplier != null) {
      final localeLang = Localizations.localeOf(context).languageCode;
      return supplier!.nameFor(localeLang);
    }
    return _supplierName;
  }

  String get _supplierName {
    if (supplier != null) {
      return supplier!.providerName;
    }
    if (managementRule?.productProvider?.providerName != null) {
      return managementRule!.productProvider!.providerName!;
    }
    return '';
  }

  // ==================== Lookups ====================

  int get _supplierId {
    if (supplier != null) return supplier!.idProductProvider;
    if (managementRule?.productProvider?.idProductProvider != null) {
      return managementRule!.productProvider!.idProductProvider;
    }
    return 0;
  }

  int get _orgId {
    if (supplier != null) return supplier!.idProviderOrganisation;
    if (managementRule?.productProvider?.idProviderOrganisation != null) {
      return managementRule!.productProvider!.idProviderOrganisation;
    }
    return 0;
  }

  int get _providerTypeId {
    if (supplier != null) return supplier!.productProviderTypeId;
    if (managementRule?.productProvider?.productProviderTypeId != null) {
      return managementRule!.productProvider!.productProviderTypeId;
    }
    return 0;
  }

  String get _contactInfo {
    if (supplier?.locationName != null && supplier!.locationName!.isNotEmpty) {
      return supplier!.locationName!;
    }
    if (managementRule?.productProvider?.providerContactInfo != null) {
      return managementRule!.productProvider!.providerContactInfo!;
    }
    return '';
  }

  bool get _isActive {
    if (managementRule != null) return managementRule!.isActive;
    return true;
  }

  bool get _isPending {
    if (managementRule != null) return managementRule!.isPending;
    return false;
  }

  // ==================== Build ====================

  @override
  Widget build(BuildContext context) {
    if (managementRule == null && supplier == null) {
      return const SizedBox.shrink();
    }

    final hasValidData = (supplier != null) ||
        (managementRule?.productProvider != null &&
            managementRule!.productProvider!.providerName != null);

    if (!hasValidData) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap ?? () => _navigateToPersonnelManagement(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Below ~280dp there isn't room for logo + info + a
              // trailing permission chip. Move the trailing widget
              // below the info block instead of pushing it off-screen.
              final stacked = trailing != null && constraints.maxWidth < 280;

              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildSupplierLogo(context),
                        const SizedBox(width: 16),
                        Expanded(child: _buildSupplierInfo(context)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: trailing!,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  _buildSupplierLogo(context),
                  const SizedBox(width: 16),
                  Expanded(child: _buildSupplierInfo(context)),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    trailing!,
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSupplierLogo(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _isActive
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: _providerTypeId == 0
                  ? Icon(
                      _getCategoryIcon(_providerTypeId),
                      color: _isActive
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                      size: 28,
                    )
                  : SvgPicture.asset(
                      'assets/icons/${_providerTypeId + 1}.svg',
                      package: 'provider_geo',
                      width: 20,
                      height: 20,
                      color: _isActive
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color:
                    statusColor ?? (_isActive ? Colors.green : Colors.orange),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.surface,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierInfo(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final languageCode = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _localizedName(context),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (_contactInfo.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _contactInfo,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        // Wrap so the status and category chips flow to a new line
        // when they don't fit side by side. No overflow, no ellipsis
        // — just a vertical stack when space is tight.
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildStatusChip(context, theme, l10n),
            _buildCategoryChip(theme, colorScheme, languageCode, l10n),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(
      BuildContext context, ThemeData theme, AppLocalizations l10n) {
    final color = statusColor ?? _getStatusColor(context);
    final label = statusText ?? _getStatusText(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        softWrap: false,
      ),
    );
  }

  Widget _buildCategoryChip(
    ThemeData theme,
    ColorScheme colorScheme,
    String languageCode,
    AppLocalizations l10n,
  ) {
    return Selector<SupplierChangeNotifier, LocalizedCategoryHierarchy?>(
      selector: (_, notifier) {
        for (final category in notifier.supplierCategories) {
          if (category.productProviderTypeId == _providerTypeId) {
            return localizedCategoryHierarchyParts(
              categoryPath: category.productCategoryDesc,
              localizedLeaf: category.nameFor(languageCode),
              localizations: l10n,
            );
          }
        }
        return null;
      },
      builder: (context, hierarchy, _) {
        final leaf =
            (hierarchy?.leaf.isNotEmpty ?? false) ? hierarchy!.leaf : l10n.all;

        // The chip shows only the leaf; the full path lives in the
        // tooltip so nothing is lost. On touch devices the tooltip
        // shows on long-press, on desktop/Web on hover.
        final fullLabel = hierarchy?.fullLabel ?? leaf;

        return Tooltip(
          message: fullLabel,
          waitDuration: const Duration(milliseconds: 400),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 140),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.category_outlined,
                  size: 12,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    leaf,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==================== Status helpers ====================

  Color _getStatusColor(BuildContext context) {
    final theme = Theme.of(context);

    if (statusColor != null) return statusColor!;

    if (_isActive) {
      return theme.colorScheme.primary;
    } else if (_isPending) {
      return theme.colorScheme.secondary;
    } else {
      return theme.colorScheme.error;
    }
  }

  String _getStatusText(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isActive) {
      return l10n.activeStatus ?? 'Active';
    } else if (_isPending) {
      return l10n.pendingStatus ?? 'Pending';
    } else {
      return l10n.status_inactive ?? 'Inactive';
    }
  }

  IconData _getCategoryIcon(int categoryId) {
    const icons = [
      Icons.restaurant_rounded,
      Icons.store_rounded,
      Icons.local_offer_rounded,
      Icons.build_rounded,
      Icons.medical_services_rounded,
      Icons.school_rounded,
      Icons.home_work_rounded,
      Icons.business_rounded,
    ];
    return icons[categoryId % icons.length];
  }

  // ==================== Navigation ====================

  void _navigateToPersonnelManagement(BuildContext context) {
    final id = _supplierId;
    final orgId = _orgId;

    if (id == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.cannotNavigateInvalidSupplier ??
                'Cannot navigate: Invalid supplier ID',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PersonnelManagementScreen(
          supplierName: _supplierName,
          orgId: orgId,
          supplierId: id,
        ),
      ),
    );
  }
}
