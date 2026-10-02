import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/business/finance/ProvidedService.dart';
import 'package:provider_store/components/service/details/pricing_card.dart';
import 'package:provider_store/components/service/details/section_container.dart';

class ServicePricingSection extends StatelessWidget {
  final ProvidedService service;

  const ServicePricingSection({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return SectionContainer(
      icon: Icons.monetization_on_outlined,
      title: localizations?.pricing ?? 'Pricing & Costs',
      color: colorScheme.secondary,
      child: Column(
        children: [
          // Price Cards Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              PricingCard(
                title: localizations?.basePrice ?? 'Base Price',
                amount: service.basePrice,
                color: colorScheme.primaryContainer,
                textColor: colorScheme.onPrimaryContainer,
                icon: Icons.price_change_outlined,
              ),
              PricingCard(
                title: localizations?.finalPrice ?? 'Final Price',
                amount: service.finalPrice,
                color: colorScheme.secondaryContainer,
                textColor: colorScheme.onSecondaryContainer,
                icon: Icons.sell_outlined,
              ),
              PricingCard(
                title: localizations?.totalCost ?? 'Total Cost',
                amount: service.totalCost,
                color: colorScheme.tertiaryContainer,
                textColor: colorScheme.onTertiaryContainer,
                icon: Icons.account_balance_wallet_outlined,
              ),
              PricingCard(
                title: localizations?.profitMargin ?? 'Profit Margin',
                amount: service.profitMargin,
                isPercentage: true,
                color: service.profitMargin >= 0
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                textColor:
                    service.profitMargin >= 0 ? Colors.green : Colors.red,
                icon: service.profitMargin >= 0
                    ? Icons.trending_up
                    : Icons.trending_down,
              ),
            ],
          ),

          // Discount Info
          if (service.discountPercentage > 0) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_offer,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations?.serviceDiscount(
                                  service.discountPercentage.toStringAsFixed(0),
                                  localizations?.serviceDiscountOff ?? 'off') ??
                              '${service.discountPercentage.toStringAsFixed(0)}% off',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.primary,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          localizations?.discountApplied ??
                              'Discount applied from base price',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Pricing Config
          if (service.pricingConfig.toJson().isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildPricingConfig(context),
          ],
        ],
      ),
    );
  }

  Widget _buildPricingConfig(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final config = service.pricingConfig;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pricing Configuration',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _buildConfigChips(config, colorScheme),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildConfigChips(
      ProvidedServicePricingConfig config, ColorScheme colorScheme) {
    final chips = <Widget>[];

    if (config.recommendedAge != null) {
      chips.add(_buildConfigChip('Age: ${config.recommendedAge}', colorScheme));
    }
    if (config.recommendedFrequency != null) {
      chips.add(_buildConfigChip(
          'Frequency: ${config.recommendedFrequency}', colorScheme));
    }
    if (config.ageGroup != null) {
      chips.add(_buildConfigChip('Age Group: ${config.ageGroup}', colorScheme));
    }
    if (config.sampleType != null) {
      chips.add(_buildConfigChip('Sample: ${config.sampleType}', colorScheme));
    }
    if (config.specialistConsultation == true) {
      chips.add(_buildConfigChip('Specialist Consultation', colorScheme));
    }
    if (config.governmentFunded == true) {
      chips.add(_buildConfigChip('Government Funded', colorScheme));
    }
    if (config.materialOptions?.isNotEmpty == true) {
      chips.add(_buildConfigChip(
          'Materials: ${config.materialOptions?.join(', ')}', colorScheme));
    }
    if (config.includes?.isNotEmpty == true) {
      chips.add(_buildConfigChip(
          'Includes: ${config.includes?.join(', ')}', colorScheme));
    }

    return chips;
  }

  Widget _buildConfigChip(String text, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}
