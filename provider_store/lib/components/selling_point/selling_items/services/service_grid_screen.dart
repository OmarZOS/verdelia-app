import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/business/finance/ProvidedService.dart';
import 'package:event/service_change_notifier.dart';
import 'package:provider_store/components/selling_point/selling_items/item_card_with_controls.dart';
import 'package:provider/provider.dart';
import 'package:event/cart_change_notifier.dart';
import 'package:provider_store/components/selling_point/selling_items/services/service_grid.dart';

class ServiceGridSliver extends StatelessWidget {
  final List<ProvidedService> services;
  final bool isLoading;
  final CartChangeNotifier cartNotifier;
  final Function(ProvidedService) onAddToCart;
  final Function(ProvidedService) onRemoveFromCart;
  final Function(ProvidedService) onConfigure;

  const ServiceGridSliver({
    super.key,
    required this.services,
    required this.isLoading,
    required this.cartNotifier,
    required this.onAddToCart,
    required this.onRemoveFromCart,
    required this.onConfigure,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final selectedServiceIds = _getSelectedServiceIds();

    if (isLoading && services.isEmpty) {
      return SliverFillRemaining(
        child: _LoadingState(localizations: localizations),
      );
    }

    if (services.isEmpty) {
      return SliverFillRemaining(
        child: _EmptyState(localizations: localizations),
      );
    }

    return SliverList(
      delegate: SliverChildListDelegate([
        // Header with selection count
        _ServicesHeader(
          selectedCount: selectedServiceIds.length,
          totalCount: services.length,
        ),
        const SizedBox(height: 8),
        // Services Grid
        ServiceGrid(
          services: services,
          cartNotifier: cartNotifier,
          onAddToCart: onAddToCart,
          onRemoveFromCart: onRemoveFromCart,
          onConfigure: onConfigure,
        ),
      ]),
    );
  }

  Set<int> _getSelectedServiceIds() {
    return cartNotifier.cartItems
        .where((item) => item.service?.id != null)
        .map((item) => item.service!.id)
        .toSet();
  }
}

// ==================== HEADER ====================

class _ServicesHeader extends StatelessWidget {
  final int selectedCount;
  final int totalCount;

  const _ServicesHeader({
    required this.selectedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final localizations = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary.withOpacity(0.08),
              colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.primary.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Icon with selection count badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primaryContainer
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.medical_services_rounded,
                    color: colorScheme.onPrimary,
                    size: 24,
                  ),
                ),
                if (selectedCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        selectedCount.toString(),
                        style: TextStyle(
                          color: colorScheme.onTertiary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.services,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    selectedCount > 0
                        ? localizations.selected(selectedCount)
                        : localizations.browseAndSelectServices,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: selectedCount > 0
                          ? colorScheme.tertiary
                          : colorScheme.onSurfaceVariant,
                      fontWeight: selectedCount > 0 ? FontWeight.w600 : null,
                    ),
                  ),
                ],
              ),
            ),
            // Total count badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                localizations.available(totalCount),
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== LOADING STATE ====================

class _LoadingState extends StatelessWidget {
  final AppLocalizations localizations;

  const _LoadingState({required this.localizations});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: colorScheme.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            localizations.loadingServices,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localizations.preparingServiceCatalog,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== EMPTY STATE ====================

class _EmptyState extends StatelessWidget {
  final AppLocalizations localizations;

  const _EmptyState({required this.localizations});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withOpacity(0.05),
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.1),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.handyman_rounded,
                size: 48,
                color: colorScheme.primary.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              localizations.noServicesAvailable,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                localizations.servicesWillAppearHere,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
