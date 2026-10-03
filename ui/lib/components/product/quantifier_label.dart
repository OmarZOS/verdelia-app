// lib/components/product/quantifier_label.dart

import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

/// Translates a canonical backend unit token (e.g. `'kg'`, `'mL'`) into
/// its localized display string.
///
/// Unknown units fall through unchanged, so a new backend unit never
/// blanks out the UI — it just shows up verbatim until a translation
/// is added here.
String localizedQuantifier(String unit, AppLocalizations loc) {
  return switch (unit) {
    'g' => loc.quantifier_g,
    'kg' => loc.quantifier_kg,
    'mg' => loc.quantifier_mg,
    'L' => loc.quantifier_L,
    'mL' => loc.quantifier_mL,
    'pc' => loc.quantifier_pc,
    'pkg' => loc.quantifier_pkg,
    'box' => loc.quantifier_box,
    'bag' => loc.quantifier_bag,
    'slice' => loc.quantifier_slice,
    'cup' => loc.quantifier_cup,
    _ => unit,
  };
}

/// Convenience widget: renders the quantifier as a pill, or nothing at
/// all when the raw value is null/blank.
///
/// Keeps the "is there a quantifier?" branch out of every call site.
class QuantifierLabel extends StatelessWidget {
  const QuantifierLabel({
    super.key,
    required this.raw,
    this.pillBuilder,
    this.style,
  });

  /// Raw backend value, e.g. `'kg'`. Null or blank → renders nothing.
  final String? raw;

  /// Optional override so callers can wrap the text in their own
  /// container (e.g. `_Pill`). Receives the localized label and the
  /// resolved text style. When null, a plain [Text] is rendered.
  final Widget Function(BuildContext context, String label, TextStyle? style)?
      pillBuilder;

  /// Optional text style forwarded to [Text] and the pill builder.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) {
      return const SizedBox.shrink();
    }

    final loc = AppLocalizations.of(context)!;
    final label = localizedQuantifier(value, loc);
    final resolvedStyle = style ?? Theme.of(context).textTheme.bodySmall;

    if (pillBuilder != null) {
      return pillBuilder!(context, label, resolvedStyle);
    }
    return Text(label, style: resolvedStyle);
  }
}
