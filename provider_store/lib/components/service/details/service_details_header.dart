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
          final isExpanded = constraints.biggest.height == kToolbarHeight;

          return FlexibleSpaceBar(
            titlePadding: EdgeInsets.only(
              left: 72,
              bottom: isExpanded ? 16 : 8, // Adjust padding based on state
              right:
                  onEditPressed != null ? 56 : 16, // Make room for edit button
            ),
            centerTitle: false,
            title: Container(
              padding: const EdgeInsets.only(right: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      service.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                        fontSize:
                            isExpanded ? 18 : 20, // Smaller when collapsed
                      ),
                      maxLines: isExpanded ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!isExpanded) const SizedBox(height: 4),
                  if (!isExpanded)
                    ServiceStatusChip(isActive: service.isActive),
                ],
              ),
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
              child: Stack(
                children: [
                  Positioned(
                    right: 20,
                    bottom: 20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getServiceIcon(service.categoryId),
                        size: 40,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
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
