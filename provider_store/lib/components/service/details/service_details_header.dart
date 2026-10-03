import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/business/finance/ProvidedService.dart';
import 'package:provider_store/components/service/details/service_status_chip.dart';

class ServiceDetailsHeader extends StatelessWidget {
  final ProvidedService service;
  final VoidCallback onBackPressed;
  final VoidCallback? onEditPressed;

  const ServiceDetailsHeader({
    super.key,
    required this.service,
    required this.onBackPressed,
    this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: colorScheme.surface,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_rounded,
          color: colorScheme.onSurface,
        ),
        onPressed: onBackPressed,
      ),
      actions: [
        if (onEditPressed != null)
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              color: colorScheme.primary,
            ),
            onPressed: onEditPressed,
          ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          // Treat anything within ~20dp of the collapsed height as
          // collapsed. Matches the visual moment the title settles.
          final collapsedHeight =
              kToolbarHeight + MediaQuery.of(context).padding.top;
          final isExpanded = constraints.biggest.height > collapsedHeight + 20;

          // Icon stays modest in both states so the collapsed toolbar
          // row never exceeds the ~56dp slot.
          final iconSize = isExpanded ? 56.0 : 32.0;

          return FlexibleSpaceBar(
            titlePadding: EdgeInsets.only(
              left: 72,
              right: onEditPressed != null ? 56 : 16,
              // Bottom padding keeps the title centred in the collapsed
              // toolbar; larger when expanded to sit above the gradient.
              bottom: isExpanded ? 16 : 4,
            ),
            centerTitle: false,
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Text column is the flexible part. Collapsed state is
                // strictly one line — no chip, no second line — so the
                // row height is bounded by the icon and the toolbar
                // slot is never exceeded.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        service.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                          fontSize: isExpanded ? 18 : 16,
                        ),
                        // Collapsed: one line. Expanded: up to two.
                        maxLines: isExpanded ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: isExpanded,
                      ),
                      if (isExpanded) ...[
                        const SizedBox(height: 4),
                        ServiceStatusChip(isActive: service.isActive),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: isExpanded ? 12 : 8),
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getServiceIcon(service.categoryId),
                    size: isExpanded ? 28 : 18,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.primary.withOpacity(0.1),
                    colorScheme.surface,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getServiceIcon(int categoryId) {
    const icons = {
      1: Icons.medical_services, // Pathology
      2: Icons.monitor_heart, // Imaging
      3: Icons.vaccines, // Vaccinations
      4: Icons.airline_seat_recline_normal, // Health Checkups
      5: Icons.medical_services, // Dental
      6: Icons.science, // Other
    };
    return icons[categoryId] ?? Icons.medical_services_outlined;
  }
}
