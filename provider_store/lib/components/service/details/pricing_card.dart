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
  final double amount;
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

    // One decimal for percentages, two for currency. Currency symbol
    // comes from the ARB `price` string, so French gets "DA" and
    // Arabic gets "دج" without any code change here.
    final value = isPercentage
        ? loc.percent(amount.toStringAsFixed(1))
        : loc.price(amount.toStringAsFixed(2));

    return LayoutBuilder(
      builder: (context, constraints) {
        // The tile is expected to hold an icon row, a title, and the
        // value. If we're squeezed below this height, drop the icon
        // row so the text has room. The single-column grid uses a
        // wide-but-short cell, which can trip this on very small
        // screens.
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
                        amount >= 0 ? Icons.trending_up : Icons.trending_down,
                        color: textColor,
                        size: 16,
                      ),
                  ],
                ),
              // The Spacer still works when the icon row is hidden;
              // it just takes the slack that the row would have used.
              // In an unbounded-height context (rare for this widget),
              // we skip it to avoid a "Spacer in unbounded column"
              // assertion.
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
                  // FittedBox keeps the big number from overflowing
                  // when the tile narrows or the user scales text up.
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
