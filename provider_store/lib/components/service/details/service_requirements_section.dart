import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/business/finance/ProvidedService.dart';
import 'package:provider_store/components/service/details/requirement_card.dart';
import 'package:provider_store/components/service/details/section_container.dart';

class ServiceRequirementsSection extends StatelessWidget {
  final ProvidedService service;

  const ServiceRequirementsSection({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Resource Requirements
        if (service.resourceRequirements.isNotEmpty)
          SectionContainer(
            icon: Icons.inventory_2_outlined,
            title:
                localizations?.resourceRequirements ?? 'Resource Requirements',
            color: colorScheme.tertiary,
            child: Column(
              children: [
                ...service.resourceRequirements.map(
                  (resource) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: RequirementCard.resource(
                      name: resource.name,
                      quantity: resource.quantity,
                      unitCost: resource.costPerUnit,
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
                        localizations?.totalResourceCost ??
                            'Total Resource Cost:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        localizations.price(
                            service.totalResourceCost.toStringAsFixed(2)),
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
            title: localizations?.staffRequirements ?? 'Staff Requirements',
            color: Colors.purple,
            child: Column(
              children: [
                ...service.staffRequirements.map(
                  (staff) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: RequirementCard.staff(
                      role: staff.role.toString(),
                      minCount: staff.minCount,
                      maxCount: staff.maxCount,
                      allocatedHours: staff.allocatedHours,
                      hourlyRate: staff.hourlyRate,
                      averageCost: staff.averageCost,
                      notes: staff.notes,
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
                        localizations?.totalStaffCost ?? 'Total Staff Cost:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        localizations
                            .price(service.totalStaffCost.toStringAsFixed(2)),
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
          title: localizations?.costSummary ?? 'Cost Summary',
          color: Colors.orange,
          child: Column(
            children: [
              _buildSummaryRow(
                context,
                localizations?.resourceCost ?? 'Resource Cost',
                service.totalResourceCost,
                colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              _buildSummaryRow(
                context,
                localizations?.staffCost ?? 'Staff Cost',
                service.totalStaffCost,
                colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Divider(color: colorScheme.outline),
              const SizedBox(height: 12),
              _buildSummaryRow(
                context,
                localizations?.totalServiceCost ?? 'Total Service Cost',
                service.totalCost,
                colorScheme.primary,
                isBold: true,
              ),
              const SizedBox(height: 8),
              _buildSummaryRow(
                context,
                localizations?.servicePrice ?? 'Service Price',
                service.finalPrice,
                colorScheme.secondary,
                isBold: true,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: service.profitMargin >= 0
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: service.profitMargin >= 0
                        ? Colors.green.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      service.profitMargin >= 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color:
                          service.profitMargin >= 0 ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${localizations?.profitMargin ?? 'Profit Margin'}: ',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Text(
                      '${service.profitMargin.toStringAsFixed(1)}%',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: service.profitMargin >= 0
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
    double value,
    Color color, {
    bool isBold = false,
  }) {
    AppLocalizations loc = AppLocalizations.of(context)!;

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
