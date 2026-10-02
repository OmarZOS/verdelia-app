// duration_picker_field.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

class DurationPickerField extends StatefulWidget {
  final String label;
  final bool isRequired;
  final Duration value;
  final ValueChanged<Duration> onChanged;
  final bool initiallyExpanded;

  const DurationPickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.isRequired = false,
    this.initiallyExpanded = false,
  });

  @override
  State<DurationPickerField> createState() => _DurationPickerFieldState();
}

class _DurationPickerFieldState extends State<DurationPickerField> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // -------- Label row --------
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Row(
            children: [
              Text(
                widget.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                ),
              ),
              if (widget.isRequired)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    '*',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.error,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // -------- Summary tile --------
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cs.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: cs.outline.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.time,
                  size: 18,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _formatDuration(widget.value, loc),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: widget.value > Duration.zero
                          ? cs.onSurface
                          : cs.onSurfaceVariant.withOpacity(0.6),
                      fontWeight: widget.value > Duration.zero
                          ? FontWeight.w600
                          : FontWeight.w400,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    CupertinoIcons.chevron_down,
                    size: 16,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),

        // -------- Inline wheel --------
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              decoration: BoxDecoration(
                color: cs.surfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: cs.outline.withOpacity(0.15),
                ),
              ),
              child: CupertinoTimerPicker(
                mode: CupertinoTimerPickerMode.hm,
                initialTimerDuration: widget.value,
                minuteInterval: 5,
                alignment: Alignment.center,
                backgroundColor: Colors.transparent,
                onTimerDurationChanged: widget.onChanged,
              ),
            ),
          ),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  /// Pick the ARB shape that matches the duration, and let the ARB
  /// compose the actual sentence. No string concatenation here — that
  /// would defeat ICU pluralization and word-order flexibility.
  String _formatDuration(Duration d, AppLocalizations loc) {
    if (d == Duration.zero) return "-";

    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);

    if (hours == 0) {
      return loc.durationMinutesOnly(minutes);
    }
    if (minutes == 0) {
      return loc.durationHoursOnly(hours);
    }
    return loc.durationHoursMinutes(hours, minutes);
  }
}
