import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/business/finance/ProvidedService.dart';
import 'package:provider_store/components/service/details/pricing_card.dart';
import 'package:provider_store/components/service/details/section_container.dart';

class ServicePricingSection extends StatelessWidget {
  final ProvidedService service;

  const ServicePricingSection({super.key, required this.service});

  /// Below this width the 2-column grid is too cramped to read,
  /// so we drop to a single column.
  static const double _twoColumnMinWidth = 320;

  @override
  Widget build(BuildContext context) {
    // Non-null: gen_l10n always provides an instance via the delegate.
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    // `basePrice`, `finalPrice`, `totalCost`, `profitMargin` are all
    // `Decimal` after the ProvidedService migration.
    final Decimal basePrice = service.basePrice;
    final Decimal finalPrice = service.finalPrice;
    final Decimal totalCost = service.totalCost;
    final Decimal profitMargin = service.profitMargin;

    return SectionContainer(
      icon: Icons.monetization_on_outlined,
      title: l10n.pricing,
      color: colorScheme.secondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Price Cards Grid (responsive) ──
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < _twoColumnMinWidth;
              final crossAxisCount = narrow ? 1 : 2;

              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: narrow ? 2.6 : 1.2,
                children: [
                  PricingCard(
                    title: l10n.basePrice,
                    amount: basePrice,
                    color: colorScheme.primaryContainer,
                    textColor: colorScheme.onPrimaryContainer,
                    icon: Icons.price_change_outlined,
                  ),
                  PricingCard(
                    title: l10n.finalPrice,
                    amount: finalPrice,
                    color: colorScheme.secondaryContainer,
                    textColor: colorScheme.onSecondaryContainer,
                    icon: Icons.sell_outlined,
                  ),
                  PricingCard(
                    title: l10n.totalCost,
                    amount: totalCost,
                    color: colorScheme.tertiaryContainer,
                    textColor: colorScheme.onTertiaryContainer,
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                  PricingCard(
                    title: l10n.profitMargin,
                    amount: profitMargin,
                    isPercentage: true,
                    color: profitMargin >= Decimal.zero
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    textColor: profitMargin >= Decimal.zero
                        ? Colors.green
                        : Colors.red,
                    icon: profitMargin >= Decimal.zero
                        ? Icons.trending_up
                        : Icons.trending_down,
                  ),
                ],
              );
            },
          ),

          // ── Discount Info ──
          if (service.discountPercentage > Decimal.zero) ...[
            const SizedBox(height: 20),
            _buildDiscountBanner(context, l10n, colorScheme),
          ],

          // ── Pricing Config ──
          if (service.pricingConfig.toJson().isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildPricingConfig(context, l10n),
          ],
        ],
      ),
    );
  }

  // ==========================================================
  // Discount banner
  // ==========================================================

  Widget _buildDiscountBanner(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    final String pct = _formatPercent(service.discountPercentage);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.local_offer, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.serviceDiscount(pct, l10n.serviceDiscountOff),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.discountApplied,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Formats a percentage value without a trailing `.0`.
  /// `12.0 → "12"`, `12.5 → "12.5"`.
  ///
  /// `.truncate()` returns the integer part as `Decimal`, so the
  /// comparison `value == value.truncate()` is `Decimal == Decimal` —
  /// exact. `Decimal.toStringAsFixed(0)` / `(1)` produce the same
  /// strings `double.toStringAsFixed` did.
  String _formatPercent(Decimal value) {
    if (value == value.truncate()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  // ==========================================================
  // Pricing config
  // ==========================================================

  Widget _buildPricingConfig(BuildContext context, AppLocalizations l10n) {
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
            l10n.pricingConfiguration,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          _buildConfigChips(context, l10n, config, colorScheme),
        ],
      ),
    );
  }

  Widget _buildConfigChips(
    BuildContext context,
    AppLocalizations l10n,
    ProvidedServicePricingConfig config,
    ColorScheme colorScheme,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxChipWidth = constraints.maxWidth;

        final chips = <Widget>[];

        void add(String text) {
          chips.add(_buildConfigChip(text, colorScheme, maxChipWidth));
        }

        if (config.recommendedAge != null) {
          add(l10n.pricingConfigAge('${config.recommendedAge}'));
        }
        if (config.recommendedFrequency != null) {
          add(l10n.pricingConfigFrequency('${config.recommendedFrequency}'));
        }
        if (config.ageGroup != null) {
          add(l10n.pricingConfigAgeGroup('${config.ageGroup}'));
        }
        if (config.sampleType != null) {
          add(l10n.pricingConfigSample('${config.sampleType}'));
        }
        if (config.specialistConsultation == true) {
          add(l10n.pricingConfigSpecialist);
        }
        if (config.governmentFunded == true) {
          add(l10n.pricingConfigGovernmentFunded);
        }
        if (config.materialOptions?.isNotEmpty == true) {
          add(l10n.pricingConfigMaterials(config.materialOptions!.join(', ')));
        }
        if (config.includes?.isNotEmpty == true) {
          add(l10n.pricingConfigIncludes(config.includes!.join(', ')));
        }

        return ClipRect(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips,
          ),
        );
      },
    );
  }

  Widget _buildConfigChip(
    String text,
    ColorScheme colorScheme,
    double maxWidth,
  ) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
        ),
      ),
    );
  }
}
