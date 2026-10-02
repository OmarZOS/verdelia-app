import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:flutter/services.dart';

/// A self-contained payment form.
///
/// Caller provides everything the screen needs:
///   - [amountDue]: the maximum the user can pay (post-payment validation)
///   - [onSubmit]: async callback that receives the amount + method + notes;
///                 return `null` on success, or an error message to display
///   - [initialAmount]: optional starting amount (defaults to [amountDue])
///   - [currencySymbol]: prefix for displayed amounts (defaults to empty)
///   - [title]: optional header text. If null, uses the localized default.
class PaymentFormScreen extends StatefulWidget {
  final double amountDue;
  final double? initialAmount;
  final String currencySymbol;

  /// If null, falls back to `loc.paymentType` or similar. Pass a pre-built
  /// string here if you want to include the document number, etc.
  final String? title;

  final Future<String?> Function(double amount, String method, String notes)
      onSubmit;

  const PaymentFormScreen({
    super.key,
    required this.amountDue,
    required this.onSubmit,
    this.initialAmount,
    this.currencySymbol = '',
    this.title,
  });

  @override
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  late final TextEditingController _amountController;
  final TextEditingController _notesController = TextEditingController();

  String _method = 'cash';
  String? _error;
  bool _submitting = false;

  static const _methods = <String, IconData>{
    'cash': Icons.payments_rounded,
    'card': Icons.credit_card_rounded,
    'bank_transfer': Icons.account_balance_rounded,
    'mobile_money': Icons.phone_android_rounded,
  };

  @override
  void initState() {
    super.initState();
    final start = widget.initialAmount ?? widget.amountDue;
    _amountController = TextEditingController(
      text: start > 0 ? start.toStringAsFixed(2) : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ==================== LOCALIZED LABELS ====================

  /// Localized display name for a payment method id.
  ///
  /// If your `AppLocalizations` doesn't yet have these keys, add them to the
  /// ARB file. Until then, the fallback (the id with underscores replaced)
  /// is what the UI will show.
  String _methodLabel(String id, AppLocalizations loc) {
    switch (id) {
      case 'cash':
        return loc.paymentMethodCash;
      case 'card':
        return loc.paymentMethodCard;
      case 'bank_transfer':
        return loc.paymentMethodBankTransfer;
      case 'mobile_money':
        return loc.paymentMethodMobileMoney;
      default:
        return id.replaceAll('_', ' ').toUpperCase();
    }
  }

  // ==================== VALIDATION ====================

  String? _validateAmount(String raw, AppLocalizations loc) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return loc.paymentErrorEnterAmount;
    final value = double.tryParse(trimmed);
    if (value == null) return loc.paymentErrorInvalidNumber;
    if (value <= 0) return loc.paymentErrorMustBePositive;
    if (value > widget.amountDue) {
      return loc.paymentErrorExceedsDue(_fmt(context, widget.amountDue));
    }
    return null;
  }

  // ==================== HELPERS ====================

  String _fmt(BuildContext ctx, double amount) =>
      AppLocalizations.of(ctx)!.price(amount.toStringAsFixed(2));

  double get _currentAmount =>
      double.tryParse(_amountController.text.trim()) ?? 0.0;

  // ==================== SUBMIT ====================

  Future<void> _submit(AppLocalizations loc) async {
    final err = _validateAmount(_amountController.text, loc);
    if (err != null) {
      setState(() => _error = err);
      return;
    }

    setState(() {
      _error = null;
      _submitting = true;
    });

    try {
      final result = await widget.onSubmit(
        _currentAmount,
        _method,
        _notesController.text.trim(),
      );

      if (!mounted) return;

      if (result != null) {
        setState(() => _error = result);
        return;
      }

      await _showSuccess(loc);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showSuccess(AppLocalizations loc) async {
    final theme = Theme.of(context);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: Icon(
          Icons.check_circle_rounded,
          size: 56,
          color: theme.colorScheme.primary,
        ),
        title: Text(loc.paymentSuccessTitle),
        content: Text(
          loc.paymentSuccessBody(
            _fmt(context, _currentAmount),
            _methodLabel(_method, loc),
          ),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.ok),
          ),
        ],
      ),
    );
  }

  void _setAmount(double value) {
    final clamped = value.clamp(0.0, widget.amountDue);
    setState(() {
      _amountController.text = clamped.toStringAsFixed(2);
      _error = _validateAmount(
          _amountController.text, AppLocalizations.of(context)!);
    });
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final canSubmit = !_submitting && _error == null && _currentAmount > 0;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title ?? loc.paymentType,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SummaryCard(
                amountDue: widget.amountDue,
                amountEntered: _currentAmount,
                formatter: (double amt) => _fmt(context, amt),
                labelOutstanding: loc.paymentOutstandingLabel,
                labelRemainingAfter: loc.paymentRemainingAfter,
                labelSettlesFull: loc.paymentSettlesFull,
              ),
              const SizedBox(height: 24),
              _SectionLabel(text: loc.paymentAmountLabel),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                enabled: !_submitting,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixText: widget.currencySymbol,
                  errorText: _error,
                  filled: true,
                  fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.end,
                onChanged: (raw) {
                  final err = _validateAmount(raw, loc);
                  setState(() {
                    _error = err;
                  });
                },
              ),
              const SizedBox(height: 16),
              if (widget.amountDue > 0) ...[
                _SectionLabel(text: loc.paymentQuickAmounts),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _QuickAmountChip(
                      label: '25%',
                      onTap: _submitting
                          ? null
                          : () => _setAmount(widget.amountDue * 0.25),
                    ),
                    _QuickAmountChip(
                      label: '50%',
                      onTap: _submitting
                          ? null
                          : () => _setAmount(widget.amountDue * 0.50),
                    ),
                    _QuickAmountChip(
                      label: '75%',
                      onTap: _submitting
                          ? null
                          : () => _setAmount(widget.amountDue * 0.75),
                    ),
                    _QuickAmountChip(
                      label: loc.paymentFullAmount,
                      onTap: _submitting
                          ? null
                          : () => _setAmount(widget.amountDue),
                      highlighted: true,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              _SectionLabel(text: loc.paymentMethodLabel),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _methods.entries.map((e) {
                  final selected = _method == e.key;
                  return ChoiceChip(
                    avatar: Icon(
                      e.value,
                      size: 18,
                      color: selected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    label: Text(_methodLabel(e.key, loc)),
                    selected: selected,
                    onSelected: _submitting
                        ? null
                        : (_) => setState(() => _method = e.key),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              _SectionLabel(text: loc.paymentNotesLabel),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                enabled: !_submitting,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: loc.paymentNotesHint,
                  filled: true,
                  fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: canSubmit ? () => _submit(loc) : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Text(
                        loc.paymentSubmitButton(_fmt(context, _currentAmount)),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== SECTION LABEL ====================

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text.toUpperCase(),
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _QuickAmountChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool highlighted;

  const _QuickAmountChip({
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bg = highlighted
        ? colorScheme.primary.withOpacity(0.1)
        : colorScheme.surfaceVariant.withOpacity(0.4);
    final fg = highlighted ? colorScheme.primary : colorScheme.onSurface;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== SUMMARY CARD ====================

class _SummaryCard extends StatelessWidget {
  final double amountDue;
  final double amountEntered;
  final String Function(double) formatter;
  final String labelOutstanding;
  final String Function(String amount) labelRemainingAfter;
  final String labelSettlesFull;

  const _SummaryCard({
    required this.amountDue,
    required this.amountEntered,
    required this.formatter,
    required this.labelOutstanding,
    required this.labelRemainingAfter,
    required this.labelSettlesFull,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = (amountDue - amountEntered).clamp(0.0, amountDue);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            labelOutstanding.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatter(amountDue),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (amountEntered > 0 && remaining > 0) ...[
            const SizedBox(height: 12),
            Text(
              labelRemainingAfter(formatter(remaining)),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (amountEntered >= amountDue && amountDue > 0) ...[
            const SizedBox(height: 12),
            Text(
              labelSettlesFull,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
