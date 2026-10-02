// lib/ui/SupplierCard.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:verdelia_core/app/ManagementRule.dart';
import 'package:verdelia_core/business/Supplier.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:event/supplier_change_notifier.dart';
import 'package:provider_personnel/personnel_management_screen.dart';
import 'package:provider/provider.dart';

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

  /// Locale-aware display name.
  ///
  /// Prefers the linked supplier's trilingual naming contribution when
  /// the ambient locale is one of the contribution's languages. Falls
  /// back to the flat `providerName` for any other locale, or when the
  /// supplier's payload didn't carry a naming block.
  ///
  /// The `managementRule` path has no naming support (its nested
  /// `productProvider` doesn't carry one), so it always uses the flat
  /// name.
  String _localizedName(BuildContext context) {
    if (supplier != null) {
      final localeLang = Localizations.localeOf(context).languageCode;
      // `Supplier.nameFor` already handles the fallback chain:
      // naming.<lang> → naming.en → flat providerName.
      return supplier!.nameFor(localeLang);
    }
    return _supplierName;
  }

  /// Flat provider name. Used for the management-rule path, for
  /// navigation, and anywhere a `BuildContext` isn't available.
  String get _supplierName {
    if (supplier != null) {
      return supplier!.providerName;
    }
    if (managementRule?.productProvider?.providerName != null) {
      return managementRule!.productProvider!.providerName!;
    }
    return 'Unknown Supplier';
  }

  // ==================== Lookups (unchanged) ====================

  int get _supplierId {
    if (supplier != null) {
      return supplier!.idProductProvider;
    }
    if (managementRule?.productProvider?.idProductProvider != null) {
      return managementRule!.productProvider!.idProductProvider;
    }
    return 0;
  }

  int get _orgId {
    if (supplier != null) {
      return supplier!.idProviderOrganisation;
    }
    if (managementRule?.productProvider?.idProviderOrganisation != null) {
      return managementRule!.productProvider!.idProviderOrganisation;
    }
    return 0;
  }

  int get _providerTypeId {
    if (supplier != null) {
      return supplier!.productProviderTypeId;
    }
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
    if (managementRule != null) {
      return managementRule!.isActive;
    }
    return true; // Owned suppliers are always active
  }

  bool get _isPending {
    if (managementRule != null) {
      return managementRule!.isPending;
    }
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
          child: Row(
            children: [
              _buildSupplierLogo(context),
              const SizedBox(width: 16),
              Expanded(child: _buildSupplierInfo(context)),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupplierLogo(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
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
                  package: "provider_geo",
                  width: 20,
                  height: 20,
                  color: _isActive
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: statusColor ?? (_isActive ? Colors.green : Colors.orange),
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.surface,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSupplierInfo(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final languageCode = Localizations.localeOf(context).languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Locale-aware supplier name. Falls back to the flat name
        // when no naming block is present.
        Text(
          _localizedName(context),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 4),

        if (_contactInfo.isNotEmpty)
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

        const SizedBox(height: 8),

        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(context).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                statusText ?? _getStatusText(context),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: statusColor ?? _getStatusColor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Selector<SupplierChangeNotifier, String>(
                selector: (_, notifier) => notifier.categoryName(
                  _providerTypeId,
                  languageCode: languageCode,
                ),
                builder: (context, categoryName, _) => Text(
                  categoryName.isNotEmpty ? categoryName : 'General',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==================== Status helpers ====================

  Color _getStatusColor(BuildContext context) {
    final theme = Theme.of(context);

    if (statusColor != null) {
      return statusColor!;
    }

    if (_isActive) {
      return theme.colorScheme.primary;
    } else if (_isPending) {
      return theme.colorScheme.secondary;
    } else {
      return theme.colorScheme.error;
    }
  }

  String _getStatusText(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    if (_isActive) {
      return localizations.activeStatus ?? 'Active';
    } else if (_isPending) {
      return localizations.pendingStatus ?? 'Pending';
    } else {
      return localizations.status_inactive ?? 'Inactive';
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
        const SnackBar(
          content: Text('Cannot navigate: Invalid supplier ID'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PersonnelManagementScreen(
          // Pass the flat name to the next screen. The personnel screen
          // displays it as a header, and we don't know its display
          // language yet. The screen itself can resolve the locale-aware
          // name from the supplier id if that becomes important.
          supplierName: _supplierName,
          orgId: orgId,
          supplierId: id,
        ),
      ),
    );
  }
}
