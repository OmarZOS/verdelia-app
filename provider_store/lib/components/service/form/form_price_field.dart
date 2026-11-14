// components/form_price_field.dart
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FormPriceField extends StatelessWidget {
  final String label;

  /// Initial value, in [Decimal]. Null or zero renders an empty field.
  final Decimal? value;

  final bool isRequired;

  /// Fires with the parsed [Decimal] when the form is saved.
  final Function(Decimal) onSaved;

  /// Fires with the parsed [Decimal] on every keystroke.
  final Function(Decimal)? onChanged;

  const FormPriceField({
    super.key,
    required this.label,
    required this.value,
    required this.isRequired,
    required this.onSaved,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Row(
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colors.onSurface,
                ),
              ),
              if (isRequired)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    '*',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: TextFormField(
            // `Decimal` has `toStringAsFixed`, same as `double`.
            initialValue: value != null && value! > Decimal.zero
                ? value!.toStringAsFixed(2)
                : '',
            decoration: InputDecoration(
              hintText: '0.00',
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant.withOpacity(0.6),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              prefixText: 'DZD ',
              prefixStyle: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              floatingLabelBehavior: FloatingLabelBehavior.never,
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface,
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'^\d*\.?\d{0,2}$'),
              ),
            ],
            validator: (val) {
              if (isRequired && (val == null || val.isEmpty)) {
                return 'This field is required';
              }
              if (val != null && val.isNotEmpty) {
                // Validate against `Decimal` so the value that gets
                // saved is the same value the validator accepted.
                final parsed = Decimal.tryParse(val);
                if (parsed == null || parsed < Decimal.zero) {
                  return 'Please enter a valid price';
                }
              }
              return null;
            },
            onSaved: (val) {
              final parsed = Decimal.tryParse(val ?? '') ?? Decimal.zero;
              onSaved(parsed);
            },
            onChanged: (val) {
              final parsed = Decimal.tryParse(val) ?? Decimal.zero;
              onChanged?.call(parsed);
            },
          ),
        ),
      ],
    );
  }
}
