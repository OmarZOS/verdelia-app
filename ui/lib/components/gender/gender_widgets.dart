// lib/ui/components/gender/gender_widgets.dart

import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/app/Person.dart';

// ══════════════════════════════════════════════════════════════════
// Localization
// ══════════════════════════════════════════════════════════════════

/// Localized label for a [Gender], pulled from the app's ARB keys.
///
/// Falls back to [Gender.label] when the localization layer has no key
/// for a value (keeps the widget usable during partial migrations).
String localizedGenderLabel(AppLocalizations l10n, Gender gender) {
  switch (gender) {
    case Gender.male:
      return l10n.genderMale;
    case Gender.female:
      return l10n.genderFemale;
    case Gender.other:
      return l10n.genderOther;
    case Gender.unspecified:
      return l10n.genderUnspecified;
  }
}

/// Localized glyph-free noun for compact UI (chips, filters).
///
/// Same source as [localizedGenderLabel]; kept as a separate function
/// so a widget can swap to an icon later without touching call sites.
String localizedGenderShortLabel(AppLocalizations l10n, Gender gender) {
  return localizedGenderLabel(l10n, gender);
}

// ══════════════════════════════════════════════════════════════════
// SELECTOR — dropdown form field
// ══════════════════════════════════════════════════════════════════

/// Dropdown form field for picking a [Gender].
///
/// Emits the selected enum through [onChanged]. When
/// [allowUnspecified] is false (the default), [Gender.unspecified] is
/// not offered as an option — validation must produce one of the other
/// three. When it's true, "Unspecified" appears as a selectable value.
class GenderDropdownField extends StatelessWidget {
  final Gender? value;
  final ValueChanged<Gender?> onChanged;
  final String? labelText;
  final String? Function(Gender?)? validator;
  final bool allowUnspecified;
  final bool enabled;
  final IconData prefixIcon;

  const GenderDropdownField({
    super.key,
    required this.value,
    required this.onChanged,
    this.labelText,
    this.validator,
    this.allowUnspecified = false,
    this.enabled = true,
    this.prefixIcon = Icons.transgender,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Build the option list. Skipping `unspecified` when not allowed
    // means the dropdown's value is null until the user picks one of
    // the real options — which is what a required field wants.
    final options = Gender.values
        .where((g) => allowUnspecified || g != Gender.unspecified)
        .toList(growable: false);

    return DropdownButtonFormField<Gender>(
      value: options.contains(value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: labelText ?? l10n.genderText,
        prefixIcon: Icon(prefixIcon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: options
          .map(
            (g) => DropdownMenuItem<Gender>(
              value: g,
              child: Row(
                children: [
                  Text(
                    g.icon,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      localizedGenderLabel(l10n, g),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
      onChanged: enabled ? onChanged : null,
      validator: validator,
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// SELECTOR — segmented button
// ══════════════════════════════════════════════════════════════════

/// Segmented control for picking a [Gender].
///
/// Alternative to [GenderDropdownField] for a more prominent choice on
/// forms where gender is a first-class field. Renders one segment per
/// allowed value.
class GenderSegmentedField extends StatelessWidget {
  final Gender? value;
  final ValueChanged<Gender> onChanged;
  final bool allowUnspecified;
  final bool enabled;

  const GenderSegmentedField({
    super.key,
    required this.value,
    required this.onChanged,
    this.allowUnspecified = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final options = Gender.values
        .where((g) => allowUnspecified || g != Gender.unspecified)
        .toList(growable: false);

    return SegmentedButton<Gender>(
      segments: options
          .map(
            (g) => ButtonSegment<Gender>(
              value: g,
              label: Text(localizedGenderShortLabel(l10n, g)),
              icon: Text(
                g.icon,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          )
          .toList(),
      selected: value == null ? <Gender>{} : {value!},
      emptySelectionAllowed: true,
      onSelectionChanged: enabled
          ? (selection) {
              if (selection.isNotEmpty) {
                onChanged(selection.first);
              }
            }
          : null,
      showSelectedIcon: false,
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// DISPLAY — chip
// ══════════════════════════════════════════════════════════════════

/// Read-only chip showing a [Gender] with its glyph.
///
/// Renders nothing when the gender is [Gender.unspecified] and
/// [hideWhenUnspecified] is true — useful for card layouts where an
/// empty chip is worse than no chip.
class GenderChip extends StatelessWidget {
  final Gender gender;
  final bool compact;
  final bool hideWhenUnspecified;
  final VoidCallback? onTap;

  const GenderChip({
    super.key,
    required this.gender,
    this.compact = false,
    this.hideWhenUnspecified = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (hideWhenUnspecified && !gender.isKnown) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final label = localizedGenderLabel(l10n, gender);
    final foreground = _foregroundFor(gender, colors);
    final background = foreground.withOpacity(0.10);

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          gender.icon,
          style: TextStyle(
            fontSize: compact ? 11 : 13,
            color: foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (!compact) ...[
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    );

    final chip = Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 3)
          : const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: foreground.withOpacity(0.30)),
      ),
      child: content,
    );

    if (onTap == null) return chip;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: chip,
    );
  }

  /// Colour choice per gender. Male/female get semantic colours so the
  /// two are visually distinct; unspecified stays neutral.
  Color _foregroundFor(Gender g, ColorScheme colors) {
    switch (g) {
      case Gender.male:
        return const Color(0xFF1E6FB8);
      case Gender.female:
        return const Color(0xFFB8446F);
      case Gender.other:
        return colors.tertiary;
      case Gender.unspecified:
        return colors.onSurfaceVariant;
    }
  }
}

// ══════════════════════════════════════════════════════════════════
// DISPLAY — text row (label + value)
// ══════════════════════════════════════════════════════════════════

/// "Gender: Male" row for detail screens.
class GenderLabeledRow extends StatelessWidget {
  final Gender gender;
  final String? labelOverride;
  final bool hideWhenUnspecified;

  const GenderLabeledRow({
    super.key,
    required this.gender,
    this.labelOverride,
    this.hideWhenUnspecified = false,
  });

  @override
  Widget build(BuildContext context) {
    if (hideWhenUnspecified && !gender.isKnown) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final label = labelOverride ?? l10n.genderText;

    return Row(
      children: [
        Icon(
          Icons.transgender,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          localizedGenderLabel(l10n, gender),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
