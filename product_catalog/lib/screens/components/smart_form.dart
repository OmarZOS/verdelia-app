import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:event/assistant_change_notifier.dart';
import 'package:provider/provider.dart';
import 'package:event/components/lib.dart';

// Smart Form Field Widget
class SmartFormField extends StatefulWidget {
  final String fieldId;
  final TextEditingController controller;
  final String labelText;
  final String? Function(String?) validator;
  final void Function(String?) onSaved;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final int? maxLines;
  final bool showSourceBadge;
  final ValueChanged<String>? onChanged; // ADD THIS LINE

  const SmartFormField({
    Key? key,
    required this.fieldId,
    required this.controller,
    required this.labelText,
    required this.validator,
    required this.onSaved,
    this.keyboardType,
    this.suffixIcon,
    this.maxLines,
    this.showSourceBadge = true,
    this.onChanged, // ADD THIS LINE
  }) : super(key: key);

  @override
  State<SmartFormField> createState() => _SmartFormFieldState();
}

class _SmartFormFieldState extends State<SmartFormField> {
  bool _hasUserInteracted = false;
  late TextEditingController _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = widget.controller;
    // Don't add listener here to avoid redundant calls
  }

  @override
  void didUpdateWidget(SmartFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _internalController = widget.controller;
    }
  }

  void _markAsEdited() {
    if (!_hasUserInteracted) {
      setState(() {
        _hasUserInteracted = true;
      });
      context.read<AssistantNotifier>().markFieldAsEdited(widget.fieldId);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assistantNotifier = context.watch<AssistantNotifier>();
    final fieldData = assistantNotifier.fieldData[widget.fieldId];
    final showBadge = widget.showSourceBadge &&
        fieldData != null &&
        !fieldData.isEdited &&
        !_hasUserInteracted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showBadge) ...{
          _buildSourceBadge(fieldData.source, context),
          const SizedBox(height: 8),
        },
        TextFormField(
          controller: _internalController,
          decoration: InputDecoration(
            labelText: widget.labelText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: widget.suffixIcon,
            // Add subtle border color based on source when not edited
            enabledBorder: showBadge
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _getBorderColor(fieldData!.source, context),
                      width: 1.5,
                    ),
                  )
                : null,
            focusedBorder: showBadge
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _getBorderColor(fieldData!.source, context),
                      width: 2,
                    ),
                  )
                : null,
          ),
          keyboardType: widget.keyboardType,
          maxLines: widget.maxLines,
          validator: widget.validator,
          onSaved: widget.onSaved,
          onTap: _markAsEdited,
          onChanged: (value) {
            // Call the external onChanged callback
            widget.onChanged?.call(value);

            // Mark as edited on first meaningful change
            if (!_hasUserInteracted && value.isNotEmpty) {
              _markAsEdited();
            }
          },
        ),
      ],
    );
  }

  Widget _buildSourceBadge(DataSource source, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;

    final (color, text, icon) = switch (source) {
      DataSource.aiGenerated => (
          colorScheme.tertiaryContainer,
          loc.aiGenerated,
          Icons.auto_awesome_outlined,
        ),
      DataSource.databaseFetched => (
          colorScheme.secondaryContainer,
          loc.databaseFetched,
          Icons.storage_outlined,
        ),
      DataSource.userInput => (
          colorScheme.tertiary,
          loc.userInput,
          Icons.edit_outlined,
        ),
      DataSource.verdeliaInput => (
          colorScheme.surfaceVariant,
          loc.userInput,
          Icons.edit_outlined,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onTertiaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBorderColor(DataSource source, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return switch (source) {
      DataSource.aiGenerated => colorScheme.secondary,
      DataSource.databaseFetched => colorScheme.primary,
      DataSource.userInput => colorScheme.outline,
      DataSource.verdeliaInput => colorScheme.outline,
    };
  }
}

// Smart Dropdown Field
class SmartDropdownField<T> extends StatefulWidget {
  final String fieldId;
  final T value;
  final String labelText;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged; // This already exists
  final bool showSourceBadge;

  const SmartDropdownField({
    Key? key,
    required this.fieldId,
    required this.value,
    required this.labelText,
    required this.items,
    required this.onChanged, // This already exists
    this.showSourceBadge = true,
  }) : super(key: key);
  @override
  State<SmartDropdownField> createState() => _SmartDropdownFieldState<T>();
}

class _SmartDropdownFieldState<T> extends State<SmartDropdownField<T>> {
  bool _hasUserInteracted = false;

  void _markAsEdited() {
    if (!_hasUserInteracted) {
      setState(() {
        _hasUserInteracted = true;
      });
      context.read<AssistantNotifier>().markFieldAsEdited(widget.fieldId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final assistantNotifier = context.watch<AssistantNotifier>();
    final fieldData = assistantNotifier.fieldData[widget.fieldId];
    final showBadge = widget.showSourceBadge &&
        fieldData != null &&
        !fieldData.isEdited &&
        !_hasUserInteracted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showBadge) ...{
          _buildSourceBadge(fieldData.source, context),
          const SizedBox(height: 8),
        },
        // In _SmartDropdownFieldState build method
        DropdownButtonFormField<T>(
          value: widget.value,
          decoration: InputDecoration(
            labelText: widget.labelText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: showBadge
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _getBorderColor(fieldData!.source, context),
                      width: 1.5,
                    ),
                  )
                : null,
            focusedBorder: showBadge
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _getBorderColor(fieldData!.source, context),
                      width: 2,
                    ),
                  )
                : null,
          ),
          items: widget.items,
          onChanged: (value) {
            _markAsEdited();
            widget.onChanged?.call(value); // This properly calls the callback
          },
        ),
      ],
    );
  }

  Widget _buildSourceBadge(DataSource source, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;

    final (color, text, icon) = switch (source) {
      DataSource.aiGenerated => (
          colorScheme.tertiaryContainer,
          loc.aiGenerated,
          Icons.auto_awesome_outlined,
        ),
      DataSource.databaseFetched => (
          colorScheme.secondaryContainer,
          loc.databaseFetched,
          Icons.storage_outlined,
        ),
      DataSource.userInput => (
          colorScheme.tertiary,
          loc.userInput,
          Icons.edit_outlined,
        ),
      DataSource.verdeliaInput => (
          colorScheme.surfaceVariant,
          loc.userInput,
          Icons.edit_outlined,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onTertiaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBorderColor(DataSource source, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return switch (source) {
      DataSource.aiGenerated => colorScheme.tertiary,
      DataSource.databaseFetched => colorScheme.secondary,
      DataSource.userInput => colorScheme.tertiary,
      DataSource.verdeliaInput => colorScheme.outline,
    };
  }
}
