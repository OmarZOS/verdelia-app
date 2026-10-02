import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:event/views/checkout_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ParameterInputDialog extends StatefulWidget {
  final String title;
  final String? initialKey;
  final String? initialValue;
  final bool showSaveOption;
  final Function(CheckoutParameter)? onSaveToPreferences;

  const ParameterInputDialog({
    super.key,
    required this.title,
    this.initialKey,
    this.initialValue,
    this.showSaveOption = true,
    this.onSaveToPreferences,
  });

  @override
  State<ParameterInputDialog> createState() => _ParameterInputDialogState();
}

class _ParameterInputDialogState extends State<ParameterInputDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  bool _saveToPreferences = false;
  List<Map<String, String>> _savedParameters = [];
  bool _isLoadingSavedParams = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialKey != null) {
      _keyController.text = widget.initialKey!;
    }
    if (widget.initialValue != null) {
      _valueController.text = widget.initialValue!;
    }
    _loadSavedParameters();
  }

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedParameters() async {
    if (!widget.showSaveOption) return;

    setState(() => _isLoadingSavedParams = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final parametersJson = prefs.getStringList('checkout_parameters') ?? [];

      _savedParameters.clear();
      for (final jsonString in parametersJson) {
        try {
          final map = json.decode(jsonString) as Map<String, dynamic>;
          _savedParameters.add({
            'key': map['key']?.toString() ?? '',
            'value': map['value']?.toString() ?? '',
          });
        } catch (e) {
          print('Error parsing saved parameter: $e');
        }
      }
    } catch (e) {
      print('Error loading saved parameters: $e');
    } finally {
      setState(() => _isLoadingSavedParams = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        Icons.tune,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loc.addParameterDescription,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Key Input
                  TextFormField(
                    controller: _keyController,
                    decoration: InputDecoration(
                      labelText: loc.parameterKey,
                      hintText: loc.parameterKeyHint,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      prefixIcon: Icon(
                        Icons.key,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return loc.parameterKeyRequired;
                      }
                      if (value.length > 50) {
                        return loc.parameterKeyTooLong;
                      }
                      return null;
                    },
                    textCapitalization: TextCapitalization.words,
                  ),

                  const SizedBox(height: 16),

                  // Value Input
                  TextFormField(
                    controller: _valueController,
                    decoration: InputDecoration(
                      labelText: loc.parameterValue,
                      hintText: loc.parameterValueHint,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      prefixIcon: Icon(
                        Icons.text_fields,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    maxLines: 3,
                    minLines: 1,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return loc.parameterValueRequired;
                      }
                      if (value.length > 200) {
                        return loc.parameterValueTooLong;
                      }
                      return null;
                    },
                  ),

                  // Save to Preferences Option
                  if (widget.showSaveOption) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: _saveToPreferences,
                          onChanged: (value) {
                            setState(() {
                              _saveToPreferences = value ?? false;
                            });
                          },
                          activeColor: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            loc.saveToPreferences,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Saved Parameters Section
                  if (widget.showSaveOption) ...[
                    _buildSavedParametersSection(context, theme, loc),
                    const SizedBox(height: 16),
                  ],

                  // Suggested Parameters
                  _buildSuggestedParameters(context, theme, loc),

                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(loc.cancel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(loc.save),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSavedParametersSection(
    BuildContext context,
    ThemeData theme,
    AppLocalizations loc,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              loc.savedParameters,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (_isLoadingSavedParams)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_savedParameters.isEmpty && !_isLoadingSavedParams)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                loc.noSavedParameters,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else if (!_isLoadingSavedParams)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _savedParameters.map((param) {
              return InputChip(
                label: Text(param['key']!),
                avatar: Icon(
                  Icons.bookmark,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                onPressed: () {
                  setState(() {
                    _keyController.text = param['key']!;
                    _valueController.text = param['value']!;
                    _saveToPreferences = false; // Already saved
                  });
                },
                backgroundColor: theme.colorScheme.surface,
                side: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildSuggestedParameters(
    BuildContext context,
    ThemeData theme,
    AppLocalizations loc,
  ) {
    final suggestedParameters = [
      {'key': 'Priority', 'value': 'High'},
      {'key': 'Special Instructions', 'value': 'Handle with care'},
      {'key': 'Delivery Time', 'value': 'Before 5 PM'},
      {'key': 'Contact Person', 'value': 'Store Manager'},
      {'key': 'Gift Wrapping', 'value': 'Yes'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.suggestedParameters,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestedParameters.map((param) {
            return InputChip(
              label: Text(param['key']!),
              avatar: Icon(
                Icons.add,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              onPressed: () {
                setState(() {
                  _keyController.text = param['key']!;
                  _valueController.text = param['value']!;
                });
              },
              backgroundColor: theme.colorScheme.surface,
              side: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final parameter = CheckoutParameter(
        key: _keyController.text.trim(),
        value: _valueController.text.trim(),
      );

      final result = {
        'parameter': parameter,
        'saveToPreferences': _saveToPreferences,
      };

      if (_saveToPreferences && widget.onSaveToPreferences != null) {
        widget.onSaveToPreferences!(parameter);
      }

      Navigator.pop(context, result);
    }
  }
}
