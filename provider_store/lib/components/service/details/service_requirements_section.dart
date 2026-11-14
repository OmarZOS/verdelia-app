import 'package:decimal/decimal.dart';
import 'package:event/service_change_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:verdelia_core/business/finance/ProvidedService.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:provider_store/components/service/details/requirement_card.dart';
import 'package:provider_store/components/service/details/section_container.dart';

class ServiceRequirementsSection extends StatelessWidget {
  final ProvidedService service;

  const ServiceRequirementsSection({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final localeLang = Localizations.localeOf(context).languageCode;

    return Column(
      children: [
        // Resource Requirements
        if (service.resourceRequirements.isNotEmpty)
          SectionContainer(
            icon: Icons.inventory_2_outlined,
            title: localizations.resourceRequirements,
            color: colorScheme.tertiary,
            child: Column(
              children: [
                ...service.resourceRequirements.map(
                  (resource) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: RequirementCard.resource(
                      loc: localizations,
                      name: resource.name,
                      // `quantity` and `totalCost` are `Decimal` after
                      // the ServiceResourceRequirement migration.
                      quantity: resource.quantity,
                      totalCost: resource.totalCost,
                      type: resource.type,
                      isConsumable: resource.isConsumable,
                      notes: resource.notes,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        localizations.totalResourceCost,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        localizations.price(
                          // `totalResourceCost` is `Decimal` after the
                          // ProvidedService migration;
                          // `toStringAsFixed(2)` works on both types.
                          service.totalResourceCost.toStringAsFixed(2),
                        ),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.primary,
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Staff Requirements
        if (service.staffRequirements.isNotEmpty) ...[
          const SizedBox(height: 24),
          SectionContainer(
            icon: Icons.people_outline,
            title: localizations.staffRequirements,
            color: Colors.purple,
            child: Column(
              children: [
                ...service.staffRequirements.map((staff) {
                  final inline = staff.roleNameFor(localeLang);
                  final cached = context
                      .read<ServiceNotifier>()
                      .staffRoleName(staff.role, languageCode: localeLang);
                  final roleName = inline.isNotEmpty
                      ? inline
                      : (cached.isNotEmpty ? cached : '${staff.role}');

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: RequirementCard.staff(
                      loc: localizations,
                      role: roleName,
                      minCount: staff.minCount,
                      maxCount: staff.maxCount,
                      // `allocatedHours`, `hourlyRate` and `averageCost`
                      // are `Decimal` after the ServiceStaffRequirement
                      // migration.
                      allocatedHours: staff.allocatedHours,
                      hourlyRate: staff.hourlyRate,
                      averageCost: staff.averageCost,
                      notes: staff.notes,
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        localizations.totalStaffCost,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        localizations.price(
                          service.totalStaffCost.toStringAsFixed(2),
                        ),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.primary,
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // Cost Summary
        const SizedBox(height: 24),
        SectionContainer(
          icon: Icons.summarize_outlined,
          title: localizations.costSummary,
          color: Colors.orange,
          child: Column(
            children: [
              _buildSummaryRow(
                context,
                localizations.resourceCost,
                service.totalResourceCost,
                colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              _buildSummaryRow(
                context,
                localizations.staffCost,
                service.totalStaffCost,
                colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Divider(color: colorScheme.outline),
              const SizedBox(height: 12),
              _buildSummaryRow(
                context,
                localizations.totalServiceCost,
                service.totalCost,
                colorScheme.primary,
                isBold: true,
              ),
              const SizedBox(height: 8),
              _buildSummaryRow(
                context,
                localizations.servicePrice,
                service.finalPrice,
                colorScheme.secondary,
                isBold: true,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  // `profitMargin` is `Decimal` after the
                  // ProvidedService migration; the sign check and
                  // colour branch are `>= Decimal.zero`.
                  color: service.profitMargin >= Decimal.zero
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: service.profitMargin >= Decimal.zero
                        ? Colors.green.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      service.profitMargin >= Decimal.zero
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: service.profitMargin >= Decimal.zero
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${localizations.profitMargin}: ',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Text(
                      // `Decimal.toStringAsFixed(1)` renders the same
                      // one-decimal string the `double` path did.
                      '${service.profitMargin.toStringAsFixed(1)}%',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: service.profitMargin >= Decimal.zero
                                    ? Colors.green
                                    : Colors.red,
                              ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    Decimal value,
    Color color, {
    bool isBold = false,
  }) {
    final loc = AppLocalizations.of(context)!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              ),
        ),
        Text(
          // `Decimal.toStringAsFixed(2)` produces the same formatted
          // string the `double` path did.
          loc.price(value.toStringAsFixed(2)),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: color,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
