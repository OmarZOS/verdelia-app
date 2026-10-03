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

  static String _localizeResourceType(String type, AppLocalizations loc) {
    switch (type.trim().toLowerCase()) {
      case 'consumable':
        return loc.resourceTypeConsumable;
      case 'non_consumable':
      case 'non-consumable':
      case 'reusable':
        return loc.resourceTypeNonConsumable;
      case 'raw_material':
      case 'raw-material':
        return loc.resourceTypeRawMaterial;
      case 'equipment':
        return loc.resourceTypeEquipment;
      case 'tool':
        return loc.resourceTypeTool;
      case 'supply':
        return loc.resourceTypeSupply;
      default:
        return type;
    }
  }

  factory RequirementCard.resource({
    required AppLocalizations loc,
    required String name,
    required double quantity,
    required String type,
    required bool isConsumable,
    required double totalCost,
    String? notes,
  }) {
    final unitLabel =
        isConsumable ? loc.resourceUnitsLabel : loc.resourceItemsLabel;

    // Localize the backend `type` token. Unknown values fall through to
    // the raw string so a new backend enum doesn't blank out the card.
    final typeLabel = _localizeResourceType(type, loc);

    return RequirementCard(
      title: name,
      subtitle: '$quantity $unitLabel • $typeLabel',
      cost: totalCost,
      details: notes,
      icon: isConsumable ? Icons.inventory : Icons.build,
      color: Colors.blue,
    );
  }

  factory RequirementCard.staff({
    required AppLocalizations loc,
    required String role,
    required int minCount,
    required int maxCount,
    required double allocatedHours,
    required double hourlyRate,
    required double averageCost,
    String? notes,
  }) {
    // Count label: "2" when min == max, "1-3" otherwise.
    final range = minCount == maxCount ? '$minCount' : '$minCount-$maxCount';
    final staffLabel = loc.staffCountLabel(range);

    // Hours label — drops the decimal when it's a whole number.
    final hoursValue = allocatedHours == allocatedHours.roundToDouble()
        ? allocatedHours.toStringAsFixed(0)
        : allocatedHours.toStringAsFixed(1);
    final hoursLabel = loc.staffHoursEachLabel(hoursValue);

    // Hourly rate, formatted with the locale's currency helper.
    final rateLabel = loc.staffHourlyRateLabel(
      loc.price(hourlyRate.toStringAsFixed(2)),
    );

    return RequirementCard(
      title: role,
      subtitle: '$staffLabel • $hoursLabel • $rateLabel',
      cost: averageCost,
      details: notes,
      icon: Icons.person,
      color: Colors.purple,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;

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
