import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/business/finance/ProvidedService.dart';

class ServicePriceColumn extends StatelessWidget {
  final ProvidedService service;

  const ServicePriceColumn({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context).textTheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Current Price
        Text(
          loc.price(service.finalPrice.toStringAsFixed(2)),
          style: theme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: colorScheme.primary,
            fontSize: 24,
          ),
        ),

        // Original Price with discount
        if (service.discountPercentage > 0) ...[
          const SizedBox(height: 4),
          Text(
            loc.price(service.basePrice.toStringAsFixed(2)),
            style: theme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],

        // Duration indicator
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            service.durationFormatted,
            style: theme.labelSmall?.copyWith(
              color: colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Profit indicator
        if (service.profitMargin > 0) ...[
          const SizedBox(height: 8),
          Text(
            '${service.profitMargin.toStringAsFixed(1)}% ${loc.profitMargin ?? 'margin'}',
            style: theme.labelSmall?.copyWith(
              color: colorScheme.tertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
