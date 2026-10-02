import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:event/views/checkout_view_model.dart';
import 'package:provider_store/components/selling_point/checkout/parameter_input_dialog.dart';

class NotesParametersSection extends StatefulWidget {
  final String notes;
  final List<CheckoutParameter> parameters;
  final List<CheckoutParameter> savedParameters;
  final bool isLoadingParameters;
  final ValueChanged<String> onNotesChanged;
  final ValueChanged<List<CheckoutParameter>> onParametersChanged;
  final Function(CheckoutParameter) onSaveParameter;
  final Function(int, CheckoutParameter) onUpdateParameter;
  final Function(int) onDeleteParameter;
  final Function(CheckoutParameter) onUseSavedParameter;

  const NotesParametersSection({
    super.key,
    required this.notes,
    required this.parameters,
    required this.savedParameters,
    required this.isLoadingParameters,
    required this.onNotesChanged,
    required this.onParametersChanged,
    required this.onSaveParameter,
    required this.onUpdateParameter,
    required this.onDeleteParameter,
    required this.onUseSavedParameter,
  });

  @override
  State<NotesParametersSection> createState() => _NotesParametersSectionState();
}

class _NotesParametersSectionState extends State<NotesParametersSection> {
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _notesController.text = widget.notes;
  }

  @override
  void didUpdateWidget(covariant NotesParametersSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.notes != _notesController.text) {
      _notesController.text = widget.notes;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row(
          //   children: [
          //     Icon(
          //       Icons.note_add_outlined,
          //       color: theme.colorScheme.primary,
          //       size: 20,
          //     ),
          //     const SizedBox(width: 8),
          //     Text(
          //       loc.notesParameters,
          //       style: theme.textTheme.titleMedium?.copyWith(
          //         fontWeight: FontWeight.w600,
          //       ),
          //     ),
          //   ],
          // ),
          const SizedBox(height: 12),

          // Notes Field
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.notes,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: loc.addNotesHere,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                    onChanged: widget.onNotesChanged,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Saved Parameters Section
          if (widget.savedParameters.isNotEmpty) ...[
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.1),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.bookmark,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          loc.savedParameters,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (widget.isLoadingParameters)
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
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.savedParameters.map((param) {
                        return ActionChip(
                          label: Text(param.key),
                          avatar: Icon(
                            Icons.bookmark,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          onPressed: () => widget.onUseSavedParameter(param),
                          backgroundColor: theme.colorScheme.surface,
                          side: BorderSide(
                            color: theme.colorScheme.outline.withOpacity(0.2),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Current Parameters Section
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        loc.currentParameters,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.add_circle_outline,
                          color: theme.colorScheme.primary,
                        ),
                        onPressed: _addParameter,
                        tooltip: loc.addParameter,
                      ),
                    ],
                  ),
                  if (!widget.parameters.isEmpty) const SizedBox(height: 8),
                  if (!widget.parameters.isEmpty)
                    _buildParametersList(context, loc, theme),
                  //   _buildEmptyParametersState(context, loc, theme)
                  // else
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyParametersState(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      // decoration: BoxDecoration(
      //   borderRadius: BorderRadius.circular(8),
      //   color: theme.colorScheme.surface,
      // ),
      child: Center(
        // Add this
        child: Column(
          mainAxisSize: MainAxisSize.min, // Important when using Center
          children: [
            Icon(
              Icons.tune,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              loc.noParametersAdded,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              loc.addParametersToCustomizeOrder,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParametersList(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.parameters.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: theme.colorScheme.outline.withOpacity(0.1),
      ),
      itemBuilder: (context, index) {
        final parameter = widget.parameters[index];
        final isSaved =
            widget.savedParameters.any((p) => p.key == parameter.key);

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isSaved
                  ? theme.colorScheme.primary.withOpacity(0.1)
                  : theme.colorScheme.surfaceVariant.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSaved ? Icons.bookmark : Icons.label,
              size: 18,
              color: isSaved
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          title: Row(
            children: [
              Text(
                parameter.key,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isSaved)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(
                    Icons.bookmark,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
          subtitle: Text(
            parameter.value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isSaved)
                IconButton(
                  icon: Icon(
                    Icons.bookmark_add,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: () => _saveParameterToPreferences(parameter),
                  tooltip: loc.saveToPreferences,
                ),
              IconButton(
                icon: Icon(
                  Icons.edit,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: () => _editParameter(index, parameter),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: theme.colorScheme.error,
                ),
                onPressed: () => _removeParameter(index),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addParameter() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ParameterInputDialog(
        title: AppLocalizations.of(context)!.addParameter,
        showSaveOption: true,
        onSaveToPreferences: widget.onSaveParameter,
      ),
    );

    if (result != null && result['parameter'] != null) {
      final parameter = result['parameter'] as CheckoutParameter;
      final newParameters = List<CheckoutParameter>.from(widget.parameters);
      newParameters.add(parameter);
      widget.onParametersChanged(newParameters);
    }
  }

  void _editParameter(int index, CheckoutParameter parameter) async {
    final isSaved = widget.savedParameters.any((p) => p.key == parameter.key);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ParameterInputDialog(
        title: AppLocalizations.of(context)!.editParameter,
        initialKey: parameter.key,
        initialValue: parameter.value,
        showSaveOption: !isSaved,
        onSaveToPreferences: isSaved
            ? null
            : (newParam) => widget.onUpdateParameter(
                  widget.savedParameters
                      .indexWhere((p) => p.key == parameter.key),
                  newParam,
                ),
      ),
    );

    if (result != null && result['parameter'] != null) {
      final newParameter = result['parameter'] as CheckoutParameter;
      final newParameters = List<CheckoutParameter>.from(widget.parameters);
      newParameters[index] = newParameter;
      widget.onParametersChanged(newParameters);
    }
  }

  void _removeParameter(int index) {
    final newParameters = List<CheckoutParameter>.from(widget.parameters);
    newParameters.removeAt(index);
    widget.onParametersChanged(newParameters);
  }

  void _saveParameterToPreferences(CheckoutParameter parameter) async {
    try {
      await widget.onSaveParameter(parameter);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Parameter "${parameter.key}" saved to preferences'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save parameter: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
