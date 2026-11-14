import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

/// A single tile in the pricing summary grid.
///
/// [amount] is either a currency value (when [isPercentage] is false)
/// or a percentage. Rendering goes through `AppLocalizations` so the
/// currency symbol and the `%` sign land on the correct side of the
/// numeral in every locale, including RTL.
class PricingCard extends StatelessWidget {
  final String title;

  /// Money amount or percentage, in [Decimal].
  final Decimal amount;

  final bool isPercentage;
  final Color color;
  final Color textColor;
  final IconData icon;

  const PricingCard({
    super.key,
    required this.title,
    required this.amount,
    this.isPercentage = false,
    required this.color,
    required this.textColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    // `Decimal.toStringAsFixed` produces the same one-decimal
    // (percent) / two-decimal (currency) strings the `double` path
    // did. The currency symbol and percent sign placement come from
    // the ARB `price` / `percent` strings, unchanged.
    final value = isPercentage
        ? loc.percent(amount.toStringAsFixed(1))
        : loc.price(amount.toStringAsFixed(2));

    return LayoutBuilder(
      builder: (context, constraints) {
        final showIconRow =
            constraints.maxHeight >= 96 || !constraints.hasBoundedHeight;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (showIconRow)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, color: textColor, size: 20),
                    if (isPercentage)
                      Icon(
                        // `>= Decimal.zero` for the trend icon. The
                        // old `>= 0` compares against an int; `Decimal`
                        // has no `>= int` operator.
                        amount >= Decimal.zero
                            ? Icons.trending_up
                            : Icons.trending_down,
                        color: textColor,
                        size: 16,
                      ),
                  ],
                ),
              if (constraints.hasBoundedHeight) const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: textColor.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      value,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                      ),
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
