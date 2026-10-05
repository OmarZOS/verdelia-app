import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:verdelia_core/business/finance/ProvidedService.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

class ServiceConfigurationSheet extends StatefulWidget {
  final ProvidedService service;
  final int initialQuantity;
  final String? initialScheduledDate;
  final String? initialScheduledTime;
  final String? initialNotes;
  final Function({
    required int quantity,
    String? scheduledDate,
    String? scheduledTime,
    String? notes,
    Map<String, dynamic>? parameters,
  }) onSave;

  const ServiceConfigurationSheet({
    super.key,
    required this.service,
    required this.initialQuantity,
    this.initialScheduledDate,
    this.initialScheduledTime,
    this.initialNotes,
    required this.onSave,
  });

  @override
  State<ServiceConfigurationSheet> createState() =>
      _ServiceConfigurationSheetState();
}

class _ServiceConfigurationSheetState extends State<ServiceConfigurationSheet> {
  static const int _maxQuantity = 999;

  late int _quantity;
  late final TextEditingController _notesController;
  late final TextEditingController _dateController;
  late final TextEditingController _timeController;
  late final TextEditingController _quantityController;
  late final FocusNode _quantityFocus;

  final Map<String, dynamic> _parameters = {};
  bool _isScheduled = false;
  String? _scheduleError;

  @override
  void initState() {
    super.initState();

    _quantity = widget.initialQuantity.clamp(1, _maxQuantity);
    _notesController = TextEditingController(text: widget.initialNotes);
    _dateController =
        TextEditingController(text: widget.initialScheduledDate ?? '');
    _timeController =
        TextEditingController(text: widget.initialScheduledTime ?? '');
    _quantityController = TextEditingController(text: _quantity.toString());
    _quantityFocus = FocusNode()..addListener(_onQuantityFocusChanged);

    _isScheduled = (widget.initialScheduledDate ?? '').isNotEmpty;
  }

  @override
  void dispose() {
    _quantityFocus
      ..removeListener(_onQuantityFocusChanged)
      ..dispose();
    _notesController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════
  // Build
  // ══════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DragHandle(colorScheme: colorScheme),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(
                        service: widget.service,
                        loc: loc,
                        onClose: () => Navigator.pop(context),
                      ),
                      const SizedBox(height: 24),
                      _Section(
                        colorScheme: colorScheme,
                        child: _QuantitySection(
                          loc: loc,
                          theme: theme,
                          colorScheme: colorScheme,
                          unitPrice: widget.service.finalPrice,
                          controller: _quantityController,
                          focusNode: _quantityFocus,
                          onDecrement: _quantity > 1 ? _decrement : null,
                          onIncrement:
                              _quantity < _maxQuantity ? _increment : null,
                          onSubmitted: _commitTypedQuantity,
                        ),
                      ),
                      if (widget.service.description.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _Section(
                          colorScheme: colorScheme,
                          child: _ServiceDetailsSection(
                            service: widget.service,
                            loc: loc,
                            theme: theme,
                            colorScheme: colorScheme,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _SchedulingCard(
                        isScheduled: _isScheduled,
                        dateController: _dateController,
                        timeController: _timeController,
                        scheduleError: _scheduleError,
                        loc: loc,
                        onToggle: (value) => setState(() {
                          _isScheduled = value;
                          if (!value) _scheduleError = null;
                        }),
                        onPickDate: _showDatePicker,
                        onPickTime: _showTimePicker,
                      ),
                      const SizedBox(height: 16),
                      _Section(
                        colorScheme: colorScheme,
                        child: _NotesSection(
                          controller: _notesController,
                          loc: loc,
                          theme: theme,
                          colorScheme: colorScheme,
                        ),
                      ),
                      if (_shouldShowParameters()) ...[
                        const SizedBox(height: 16),
                        _Section(
                          colorScheme: colorScheme,
                          child: _ParametersSection(loc: loc),
                        ),
                      ],
                      const SizedBox(height: 24),
                      _Actions(
                        loc: loc,
                        colorScheme: colorScheme,
                        onCancel: () => Navigator.pop(context),
                        onSave: _handleSave,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // Quantity handling
  // ══════════════════════════════════════════════════════════════════

  void _onQuantityFocusChanged() {
    if (!_quantityFocus.hasFocus) {
      _commitTypedQuantity();
    }
  }

  void _increment() {
    if (_quantity >= _maxQuantity) return;
    setState(() => _quantity++);
    _syncQuantityField();
  }

  void _decrement() {
    if (_quantity <= 1) return;
    setState(() => _quantity--);
    _syncQuantityField();
  }

  void _commitTypedQuantity() {
    final parsed = int.tryParse(_quantityController.text.trim());
    final resolved = (parsed ?? _quantity).clamp(1, _maxQuantity);

    if (resolved != _quantity) {
      setState(() => _quantity = resolved);
    }

    final text = resolved.toString();
    if (_quantityController.text != text) {
      _quantityController.text = text;
      _quantityController.selection = TextSelection.collapsed(
        offset: text.length,
      );
    }
  }

  void _syncQuantityField() {
    if (_quantityFocus.hasFocus) return;
    final text = _quantity.toString();
    if (_quantityController.text != text) {
      _quantityController.text = text;
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // Save
  // ══════════════════════════════════════════════════════════════════

  void _handleSave() {
    _commitTypedQuantity();

    if (_isScheduled) {
      final date = _dateController.text.trim();
      final time = _timeController.text.trim();
      if (date.isEmpty || time.isEmpty) {
        final loc = AppLocalizations.of(context)!;
        setState(() => _scheduleError = loc.scheduleCompletePrompt);
        return;
      }
    }

    final loc = AppLocalizations.of(context)!;
    final notes = _notesController.text.trim();

    widget.onSave(
      quantity: _quantity,
      scheduledDate: _isScheduled ? _dateController.text.trim() : null,
      scheduledTime: _isScheduled ? _timeController.text.trim() : null,
      notes: notes.isEmpty ? null : notes,
      parameters: _parameters.isNotEmpty ? _parameters : null,
    );

    // The loc read above is only used for _scheduleError; keep it in
    // case a future validation path needs a message. Silenced via `_`.
    assert(loc is AppLocalizations);

    Navigator.pop(context);
  }

  // ══════════════════════════════════════════════════════════════════
  // Date + time pickers
  // ══════════════════════════════════════════════════════════════════

  Future<void> _showDatePicker() async {
    final initial = _parseDate(_dateController.text) ?? _defaultDate();
    final locale = Localizations.localeOf(context);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      // Allow picking past dates so a service that was already
      // scheduled can have its date adjusted backwards if needed.
      // Tighten this to `DateTime.now()` if past dates are invalid
      // for your business rules.
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: locale,
    );

    if (picked != null) {
      setState(() {
        _dateController.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        _scheduleError = null;
      });
    }
  }

  Future<void> _showTimePicker() async {
    final initial = _parseTime(_timeController.text) ?? TimeOfDay.now();
    final locale = Localizations.localeOf(context);

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      // Force 24h format to match the `HH:mm` string we store.
      // Set to null to follow the platform's locale setting.
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _timeController.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        _scheduleError = null;
      });
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // Date/time parsing helpers
  // ══════════════════════════════════════════════════════════════════

  /// Parse a `YYYY-MM-DD` string. Returns null on any malformed input.
  DateTime? _parseDate(String raw) {
    if (raw.isEmpty) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  /// Parse an `HH:mm` string. Returns null on any malformed input.
  TimeOfDay? _parseTime(String raw) {
    if (raw.isEmpty) return null;
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  /// A sensible default for a new scheduling: tomorrow at the same
  /// time of day.
  DateTime _defaultDate() => DateTime.now().add(const Duration(days: 1));

  // ══════════════════════════════════════════════════════════════════
  // Parameters (stub)
  // ══════════════════════════════════════════════════════════════════

  bool _shouldShowParameters() {
    // Wire to your service model once it exposes configurable
    // parameters. Currently always false — no parameters section.
    return false;
  }
}

// ══════════════════════════════════════════════════════════════════
// Shared pieces
// ══════════════════════════════════════════════════════════════════

class _DragHandle extends StatelessWidget {
  final ColorScheme colorScheme;

  const _DragHandle({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withOpacity(0.2),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final ProvidedService service;
  final AppLocalizations loc;
  final VoidCallback onClose;

  const _Header({
    required this.service,
    required this.loc,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.settings_rounded,
            color: cs.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                service.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                loc.configureService,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: onClose,
          tooltip: loc.close,
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final Widget child;
  final ColorScheme colorScheme;

  const _Section({required this.child, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;

  const _SectionTitle({
    required this.icon,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Quantity section — editable field + stepper buttons
// ══════════════════════════════════════════════════════════════════

class _QuantitySection extends StatelessWidget {
  final AppLocalizations loc;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final double unitPrice;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final VoidCallback onSubmitted;

  const _QuantitySection({
    required this.loc,
    required this.theme,
    required this.colorScheme,
    required this.unitPrice,
    required this.controller,
    required this.focusNode,
    required this.onDecrement,
    required this.onIncrement,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.production_quantity_limits_rounded,
          title: loc.quantity,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _QuantityButton(
              icon: Icons.remove,
              onPressed: onDecrement,
              color: colorScheme.primary,
              semanticLabel: loc.decreaseQuantity,
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 64,
                        maxWidth: 120,
                      ),
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        onSubmitted: (_) => onSubmitted(),
                        onEditingComplete: onSubmitted,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                          height: 1.1,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 8,
                          ),
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: colorScheme.primary.withOpacity(0.3),
                            ),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: colorScheme.primary.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loc.itemsLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _QuantityButton(
              icon: Icons.add,
              onPressed: onIncrement,
              color: colorScheme.primary,
              semanticLabel: loc.increaseQuantity,
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Price math line: unit × qty = total. Wrapped in a
        // FittedBox so a long formatted total can't overflow.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            '${loc.currencySymbol}${unitPrice.toStringAsFixed(2)} '
            '× ${controller.text} '
            '= ${loc.currencySymbol}${(unitPrice * _currentQuantity(controller)).toStringAsFixed(2)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  int _currentQuantity(TextEditingController c) {
    return int.tryParse(c.text.trim()) ?? 1;
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final String? semanticLabel;

  const _QuantityButton({
    required this.icon,
    required this.onPressed,
    required this.color,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Material(
          color:
              enabled ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.08),
          shape: const CircleBorder(),
          child: IconButton(
            icon: Icon(
              icon,
              size: 20,
              color: enabled ? color : Colors.grey.shade400,
            ),
            onPressed: onPressed,
            splashRadius: 24,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Service details
// ══════════════════════════════════════════════════════════════════

class _ServiceDetailsSection extends StatelessWidget {
  final ProvidedService service;
  final AppLocalizations loc;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _ServiceDetailsSection({
    required this.service,
    required this.loc,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.info_rounded,
          title: loc.serviceDetails,
        ),
        const SizedBox(height: 10),
        Text(
          service.description,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        // Meta line: duration on the left, price on the right. Uses
        // Wrap so on narrow sheets the price drops to a new line
        // instead of crowding the duration.
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            _MetaItem(
              icon: Icons.schedule_rounded,
              label: service.durationFormatted,
              theme: theme,
              colorScheme: colorScheme,
            ),
            _MetaItem(
              icon: Icons.attach_money_rounded,
              label: loc.price(service.finalPrice.toStringAsFixed(2)),
              theme: theme,
              colorScheme: colorScheme,
            ),
          ],
        ),
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _MetaItem({
    required this.icon,
    required this.label,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Scheduling card
// ══════════════════════════════════════════════════════════════════

class _SchedulingCard extends StatelessWidget {
  final bool isScheduled;
  final TextEditingController dateController;
  final TextEditingController timeController;
  final String? scheduleError;
  final AppLocalizations loc;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  const _SchedulingCard({
    required this.isScheduled,
    required this.dateController,
    required this.timeController,
    required this.scheduleError,
    required this.loc,
    required this.onToggle,
    required this.onPickDate,
    required this.onPickTime,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheduleError != null
              ? cs.error.withOpacity(0.5)
              : cs.outlineVariant.withOpacity(0.5),
          width: scheduleError != null ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => onToggle(!isScheduled),
            leading: Icon(
              Icons.calendar_today_rounded,
              color: isScheduled ? cs.primary : cs.onSurfaceVariant,
            ),
            title: Text(
              loc.scheduleService,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              isScheduled ? loc.serviceWillBeScheduled : loc.addSchedulingInfo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Switch(
              value: isScheduled,
              onChanged: onToggle,
              activeColor: cs.primary,
            ),
          ),
          if (isScheduled) ...[
            Divider(height: 1, color: cs.outlineVariant.withOpacity(0.5)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _ReadOnlyField(
                    controller: dateController,
                    label: loc.scheduledDate,
                    icon: Icons.calendar_month_rounded,
                    onTap: onPickDate,
                  ),
                  const SizedBox(height: 12),
                  _ReadOnlyField(
                    controller: timeController,
                    label: loc.scheduledTime,
                    icon: Icons.schedule_rounded,
                    onTap: onPickTime,
                  ),
                  if (scheduleError != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 14,
                          color: cs.error,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            scheduleError!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.error,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ReadOnlyField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
      ),
      readOnly: true,
      onTap: onTap,
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Notes section
// ══════════════════════════════════════════════════════════════════

class _NotesSection extends StatelessWidget {
  final TextEditingController controller;
  final AppLocalizations loc;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _NotesSection({
    required this.controller,
    required this.loc,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.notes_rounded,
          title: loc.specialInstructions,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          maxLines: 3,
          minLines: 2,
          decoration: InputDecoration(
            hintText: loc.addNotesHere,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: colorScheme.surface,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Parameters section (stub)
// ══════════════════════════════════════════════════════════════════

class _ParametersSection extends StatelessWidget {
  final AppLocalizations loc;

  const _ParametersSection({required this.loc});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.tune_rounded,
          title: loc.serviceParameters,
        ),
        const SizedBox(height: 12),
        Text(
          loc.customizeServiceParameters,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Actions
// ══════════════════════════════════════════════════════════════════

class _Actions extends StatelessWidget {
  final AppLocalizations loc;
  final ColorScheme colorScheme;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _Actions({
    required this.loc,
    required this.colorScheme,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Stack vertically on very narrow sheets where two buttons
        // can't hold "Cancel" + "Save Configuration" in the ambient
        // locale.
        final stack = constraints.maxWidth < 340;

        final cancelButton = OutlinedButton(
          onPressed: onCancel,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            loc.cancel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );

        final saveButton = FilledButton(
          onPressed: onSave,
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            loc.saveConfiguration,
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );

        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              saveButton,
              const SizedBox(height: 8),
              cancelButton,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: cancelButton),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: saveButton),
          ],
        );
      },
    );
  }
}
