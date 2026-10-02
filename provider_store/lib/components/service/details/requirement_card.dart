import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

class RequirementCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double cost;
  final String? details;
  final IconData icon;
  final Color color;

  const RequirementCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.cost,
    this.details,
    required this.icon,
    required this.color,
  });

  factory RequirementCard.resource({
    required String name,
    required double quantity,
    required double unitCost,
    required double totalCost,
    required String type,
    required bool isConsumable,
    String? notes,
  }) {
    return RequirementCard(
      title: name,
      subtitle: '$quantity ${isConsumable ? 'units' : 'items'} • $type',
      cost: totalCost,
      details: notes,
      icon: isConsumable ? Icons.inventory : Icons.build,
      color: Colors.blue,
    );
  }

  factory RequirementCard.staff({
    required String role,
    required int minCount,
    required int maxCount,
    required double allocatedHours,
    required double hourlyRate,
    required double averageCost,
    String? notes,
  }) {
    return RequirementCard(
      title: role,
      subtitle: '$minCount-${maxCount} staff • ${allocatedHours}h each',
      cost: averageCost,
      details: notes,
      icon: Icons.person,
      color: Colors.purple,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    AppLocalizations loc = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                if (details != null && details!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    details!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            loc.price(cost.toStringAsFixed(2)),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}
