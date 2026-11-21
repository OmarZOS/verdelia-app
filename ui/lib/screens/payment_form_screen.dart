import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui/components/payment_dtos.dart';
import 'package:ui/components/qr/qr_display.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

class PaymentFormScreen extends StatefulWidget {
  final Decimal amountDue;
  final Decimal? initialAmount;
  final String currencySymbol;
  final String? title;
  final PaymentActor actor;
  final WalletAccount? wallet;
  final String? payeeId;
  final String currency;
  final Future<String?> Function(Decimal amount, String method, String notes)
      onSubmit;

  const PaymentFormScreen({
    super.key,
    required this.amountDue,
    required this.onSubmit,
    required this.actor,
    this.initialAmount,
    this.currencySymbol = '',
    this.title,
    this.wallet,
    this.payeeId,
    this.currency = 'DZD',
  });

  @override
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  late final TextEditingController _amountController;
  final TextEditingController _notesController = TextEditingController();

  // Bank-transfer-only fields. Folded into `notes` at submit time;
  // never sent as separate keys.
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _issueDateController = TextEditingController();

  late String _method;
  String? _error;
  bool _submitting = false;

  /// Snapshot of the QR payload. Regenerated whenever amount or notes
  /// change while the QR view is active.
  QrPayload? _qrPayload;

  /// Whether the QR view is on for the wallet method. Available to
  /// both actors. Reset whenever the method changes.
  bool _showQr = true;

  static const _providerMethods = <String, IconData>{
    'cash': Icons.payments_rounded,
    'bank_transfer': Icons.account_balance_rounded,
    'wallet': Icons.account_balance_wallet_rounded,
  };

  static const _clientMethods = <String, IconData>{
    'wallet': Icons.account_balance_wallet_rounded,
  };

  Map<String, IconData> get _methods =>
      widget.actor == PaymentActor.client ? _clientMethods : _providerMethods;

  bool get _isProvider => widget.actor == PaymentActor.provider;
  bool get _isBankTransfer => _method == 'bank_transfer';
  bool get _isWallet => _method == 'wallet';

  /// True when the QR panel should be shown. Both actors can use it,
  /// but only on the wallet method.
  bool get _isQrMode => _isWallet && _showQr;

  /// The effective method sent to `onSubmit`. Same string for both
  /// actors — payer/payee is determined by the invoice, not by this.
  String get _effectiveMethod => _method;

  /// Balance gating applies only when the actor is spending from
  /// their *own* wallet. Provider never sees this; client sees it
  /// only on the wallet path with QR off (the payer is someone else
  /// when QR is on).
  bool get _requiresOwnBalanceCheck =>
      widget.actor == PaymentActor.client && _isWallet;

  Decimal get _defaultAmount {
    final due = widget.amountDue;
    final w = widget.wallet;
    if (_requiresOwnBalanceCheck && w != null && w.balance < due) {
      return w.balance;
    }
    return due;
  }

// Client always uses wallet, no method choice.
  bool get _hideMethodSelection => widget.actor == PaymentActor.client;

// Provider doesn't submit; the QR is the payload.
  bool get _hideSubmitButton =>
      (widget.actor == PaymentActor.provider && _method == 'wallet');

// --- In initState, force wallet for client ---
  @override
  void initState() {
    super.initState();
    _method = _hideMethodSelection ? 'wallet' : _methods.keys.first;
    _showQr = (_method == 'wallet');

    final start = widget.initialAmount ?? _defaultAmount;
    _amountController = TextEditingController(
      text: start > Decimal.zero ? start.toStringAsFixed(2) : '',
    );

    final today = DateTime.now();
    _issueDateController.text = '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';

    // Build the initial QR payload so the panel isn't empty on first paint.
    _qrPayload = _buildQrPayload();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _referenceController.dispose();
    _issueDateController.dispose();
    super.dispose();
  }

  // ==================== LABELS ====================

  String _methodLabel(String id, AppLocalizations loc) {
    switch (id) {
      case 'cash':
        return loc.paymentMethodCash;
      case 'bank_transfer':
        return loc.paymentMethodBankTransfer;
      case 'wallet':
        return loc.paymentMethodWallet;
      default:
        return id.replaceAll('_', ' ').toUpperCase();
    }
  }

  String _effectiveMethodLabel(AppLocalizations loc) =>
      _methodLabel(_effectiveMethod, loc);

  // ==================== VALIDATION ====================

  String? _validateAmount(String raw, AppLocalizations loc) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return loc.paymentErrorEnterAmount;
    final value = Decimal.tryParse(trimmed);
    if (value == null) return loc.paymentErrorInvalidNumber;
    if (value <= Decimal.zero) return loc.paymentErrorMustBePositive;
    if (value > widget.amountDue) {
      return loc.paymentErrorExceedsDue(_fmt(context, widget.amountDue));
    }
    if (_requiresOwnBalanceCheck) {
      final w = widget.wallet;
      if (w == null) return loc.paymentErrorNoWallet;
      if (w.isLocked) return loc.paymentErrorWalletLocked;
      if (value > w.balance) {
        return loc.paymentErrorInsufficientWallet(_fmt(context, w.balance));
      }
    }
    return null;
  }

  /// Bank transfer requires both a reference and an issue date.
  String? _validateBankTransferFields(AppLocalizations loc) {
    if (!_isBankTransfer) return null;
    final ref = _referenceController.text.trim();
    if (ref.isEmpty) return loc.paymentErrorBankReferenceRequired;
    final date = _issueDateController.text.trim();
    if (date.isEmpty) return loc.paymentErrorBankIssueDateRequired;
    return null;
  }

  // ==================== HELPERS ====================

  String _fmt(BuildContext ctx, Decimal amount) =>
      AppLocalizations.of(ctx)!.price(amount.toStringAsFixed(2));

  Decimal get _currentAmount =>
      Decimal.tryParse(_amountController.text.trim()) ?? Decimal.zero;

  QrPayload? _buildQrPayload() {
    if (!_isQrMode) return null;
    if (_currentAmount <= Decimal.zero) return null;
    final payee = widget.payeeId;
    if (payee == null || payee.isEmpty) return null;
    return QrPayload(
      invoiceRef: widget.title ?? 'invoice',
      amount: _currentAmount,
      currency: widget.currency,
      payeeId: payee,
      issuedAt: DateTime.now(),
      note: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
  }

  void _refreshQrPayload() {
    final next = _buildQrPayload();
    if (next?.toUri() == _qrPayload?.toUri()) return;
    setState(() => _qrPayload = next);
  }

  void _onMethodChanged(String id) {
    setState(() {
      _method = id;
      // Keep QR on for wallet (the provider has no submit button, so
      // hiding it would leave nothing actionable). Off otherwise.
      _showQr = (id == 'wallet');
      // Rebuild after _showQr/_method are updated so _isQrMode is correct.
      _qrPayload = _buildQrPayload();
      _error = null;
    });
  }

  void _onQrToggle(bool show) {
    setState(() {
      _showQr = show;
      _qrPayload = _buildQrPayload();
    });
  }

  /// Merge the bank transfer reference + issue date into the user's
  /// notes. `onSubmit` still takes a single `notes` string — the
  /// bank fields become part of it with a stable, parseable prefix.
  String _composeNotes() {
    final userNote = _notesController.text.trim();
    if (!_isBankTransfer) return userNote;

    final ref = _referenceController.text.trim();
    final date = _issueDateController.text.trim();
    final prefix = '[bank_transfer] reference=$ref issue_date=$date';
    return userNote.isEmpty ? prefix : '$prefix\n$userNote';
  }

  // ==================== SUBMIT ====================

  Future<void> _submit(AppLocalizations loc) async {
    final amountErr = _validateAmount(_amountController.text, loc);
    if (amountErr != null) {
      setState(() => _error = amountErr);
      return;
    }
    final bankErr = _validateBankTransferFields(loc);
    if (bankErr != null) {
      setState(() => _error = bankErr);
      return;
    }

    setState(() {
      _error = null;
      _submitting = true;
    });

    try {
      final result = await widget.onSubmit(
        _currentAmount,
        _effectiveMethod,
        _composeNotes(),
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
            _effectiveMethodLabel(loc),
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

  void _setAmount(Decimal value) {
    final clamped = value < Decimal.zero
        ? Decimal.zero
        : (value > widget.amountDue ? widget.amountDue : value);
    setState(() {
      _amountController.text = clamped.toStringAsFixed(2);
      _error = _validateAmount(
        _amountController.text,
        AppLocalizations.of(context)!,
      );
      if (_isQrMode) _qrPayload = _buildQrPayload();
    });
  }

  Decimal _percentOfDue(int percent) {
    final raw =
        (widget.amountDue * Decimal.fromInt(percent)) / Decimal.fromInt(100);
    return _roundToCents(raw.toDecimal(scaleOnInfinitePrecision: 2));
  }

  Decimal _roundToCents(Decimal value) =>
      Decimal.parse(value.toStringAsFixed(2));

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final canSubmit =
        !_submitting && _error == null && _currentAmount > Decimal.zero;

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
                formatter: (Decimal amt) => _fmt(context, amt),
                labelOutstanding: loc.paymentOutstandingLabel,
                labelRemainingAfter: loc.paymentRemainingAfter,
                labelSettlesFull: loc.paymentSettlesFull,
              ),

              // Wallet balance display above the form is client-only:
              // the provider isn't spending from it, so showing their
              // own balance above a "collect" form is noise.
              if (widget.actor == PaymentActor.client) ...[
                const SizedBox(height: 12),
                _WalletBalanceCard(
                  wallet: widget.wallet,
                  formatter: (Decimal amt) => _fmt(context, amt),
                ),
              ],

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
                  setState(() => _error = err);
                  if (_isQrMode) _refreshQrPayload();
                },
              ),

              if (widget.amountDue > Decimal.zero) ...[
                const SizedBox(height: 16),
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
                          : () => _setAmount(_percentOfDue(25)),
                    ),
                    _QuickAmountChip(
                      label: '50%',
                      onTap: _submitting
                          ? null
                          : () => _setAmount(_percentOfDue(50)),
                    ),
                    _QuickAmountChip(
                      label: '75%',
                      onTap: _submitting
                          ? null
                          : () => _setAmount(_percentOfDue(75)),
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

              if (!_hideMethodSelection) ...[
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
                      onSelected:
                          _submitting ? null : (_) => _onMethodChanged(e.key),
                    );
                  }).toList(),
                ),
                if (_isWallet && (widget.actor == PaymentActor.client)) ...[
                  const SizedBox(height: 12),
                  _WalletQrToggle(
                    showingQr: _showQr,
                    onChanged: _submitting ? null : _onQrToggle,
                  ),
                ],
              ],

              // Bank-transfer-specific fields. Shown only when the
              // chip is bank_transfer.
              if (_isBankTransfer) ...[
                const SizedBox(height: 16),
                _SectionLabel(text: loc.paymentBankReferenceLabel),
                const SizedBox(height: 8),
                TextField(
                  controller: _referenceController,
                  enabled: !_submitting,
                  decoration: InputDecoration(
                    hintText: loc.paymentBankReferenceHint,
                    filled: true,
                    fillColor:
                        theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _SectionLabel(text: loc.paymentBankIssueDateLabel),
                const SizedBox(height: 8),
                TextField(
                  controller: _issueDateController,
                  enabled: !_submitting,
                  keyboardType: TextInputType.datetime,
                  decoration: InputDecoration(
                    hintText: loc.paymentBankIssueDateHint,
                    filled: true,
                    fillColor:
                        theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _HintPanel(
                  icon: Icons.info_outline_rounded,
                  title: loc.paymentBankHintTitle,
                  body: loc.paymentBankHintBody,
                ),
              ],

              // QR panel — both actors when wallet + QR is on.
              if (_isQrMode) ...[
                const SizedBox(height: 16),
                _QrPanel(
                  payload: _qrPayload,
                  amountLabel: _fmt(context, _currentAmount),
                  title: loc.paymentQrTitle,
                  subtitle: loc.paymentQrSubtitle,
                  emptyHint: loc.paymentQrEmptyHint,
                  isSubmitting: _submitting,
                  hasPayee: (widget.payeeId ?? '').isNotEmpty,
                  wallet: widget.wallet,
                  formatter: (Decimal amt) => _fmt(context, amt),
                ),
              ] else if (_isProvider && _method == 'cash') ...[
                const SizedBox(height: 16),
                _HintPanel(
                  icon: Icons.payments_outlined,
                  title: loc.paymentCashHintTitle,
                  body: loc.paymentCashHintBody(_fmt(context, _currentAmount)),
                ),
              ],

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
                onChanged: (_) {
                  setState(() {});
                  if (_isQrMode) _refreshQrPayload();
                },
              ),

              if (!_hideSubmitButton) ...[
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
                          // Provider: "Collect".
                          // Client: "Pay" in wallet mode,
                          //          "Mark as paid" in QR mode.
                          _isProvider
                              ? loc.paymentCollectButton(
                                  _fmt(context, _currentAmount),
                                )
                              : (_isQrMode
                                  ? loc.paymentCollectButton(
                                      _fmt(context, _currentAmount),
                                    )
                                  : loc.paymentSubmitButton(
                                      _fmt(context, _currentAmount),
                                    )),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== Supporting widgets ====================

class _WalletQrToggle extends StatelessWidget {
  final bool showingQr;
  final ValueChanged<bool>? onChanged;

  const _WalletQrToggle({required this.showingQr, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final enabled = onChanged != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? () => onChanged!(!showingQr) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: showingQr
                ? theme.colorScheme.primary.withOpacity(0.08)
                : theme.colorScheme.surfaceVariant.withOpacity(0.25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: showingQr
                  ? theme.colorScheme.primary.withOpacity(0.35)
                  : theme.colorScheme.outlineVariant.withOpacity(0.4),
            ),
          ),
          child: Row(
            children: [
              Icon(
                showingQr ? Icons.qr_code_2_rounded : Icons.qr_code_2_outlined,
                size: 18,
                color: showingQr
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.paymentQrToggleTitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: showingQr
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loc.paymentQrToggleSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: showingQr,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QrPanel extends StatelessWidget {
  final QrPayload? payload;
  final String amountLabel;
  final String title;
  final String subtitle;
  final String emptyHint;
  final bool isSubmitting;
  final bool hasPayee;
  final WalletAccount? wallet;
  final String Function(Decimal)? formatter;

  const _QrPanel({
    required this.payload,
    required this.amountLabel,
    required this.title,
    required this.subtitle,
    required this.emptyHint,
    this.isSubmitting = false,
    this.hasPayee = true,
    this.wallet,
    this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    if (!hasPayee) {
      return _HintPanel(
        icon: Icons.link_off_outlined,
        title: loc.paymentQrMissingPayeeTitle,
        body: loc.paymentQrMissingPayeeBody,
        tone: _HintTone.warning,
      );
    }
    if (payload == null) {
      return _HintPanel(
        icon: Icons.qr_code_2_outlined,
        title: title,
        body: emptyHint,
      );
    }

    final uri = payload!.toUri().toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.qr_code_2_rounded,
                  size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.4),
              ),
            ),
            child: QrDisplay(
              data: uri,
              size: 200,
              paddingRatio: 0,
              moduleColor: Colors.black,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            amountLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (wallet != null && formatter != null) ...[
            const SizedBox(height: 12),
            _WalletStrip(wallet: wallet!, formatter: formatter!),
          ],
        ],
      ),
    );
  }
}

class _WalletStrip extends StatelessWidget {
  final WalletAccount wallet;
  final String Function(Decimal) formatter;

  const _WalletStrip({required this.wallet, required this.formatter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final locked = wallet.isLocked;
    final empty = wallet.balance <= Decimal.zero;
    final color =
        locked || empty ? theme.colorScheme.error : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet_rounded, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              locked
                  ? loc.paymentWalletLocked
                  : empty
                      ? loc.paymentWalletEmpty
                      : loc.paymentWalletAvailable,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            formatter(wallet.balance),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

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

class _SummaryCard extends StatelessWidget {
  final Decimal amountDue;
  final Decimal amountEntered;
  final String Function(Decimal) formatter;
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
    final rawRemaining = amountDue - amountEntered;
    final remaining = rawRemaining < Decimal.zero ? Decimal.zero : rawRemaining;

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
          if (amountEntered > Decimal.zero && remaining > Decimal.zero) ...[
            const SizedBox(height: 12),
            Text(
              labelRemainingAfter(formatter(remaining)),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (amountEntered >= amountDue && amountDue > Decimal.zero) ...[
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

enum _HintTone { info, warning }

class _HintPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final _HintTone tone;

  const _HintPanel({
    required this.icon,
    required this.title,
    required this.body,
    this.tone = _HintTone.info,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = tone == _HintTone.warning
        ? theme.colorScheme.error
        : theme.colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletBalanceCard extends StatelessWidget {
  final WalletAccount? wallet;
  final String Function(Decimal) formatter;

  const _WalletBalanceCard({required this.wallet, required this.formatter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    if (wallet == null) {
      return _HintPanel(
        icon: Icons.account_balance_wallet_outlined,
        title: loc.paymentWalletMissingTitle,
        body: loc.paymentWalletMissingBody,
        tone: _HintTone.warning,
      );
    }

    final w = wallet!;
    final locked = w.isLocked;
    final empty = w.balance <= Decimal.zero;
    final color =
        locked || empty ? theme.colorScheme.error : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  w.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  locked
                      ? loc.paymentWalletLocked
                      : empty
                          ? loc.paymentWalletEmpty
                          : loc.paymentWalletAvailable,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatter(w.balance),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
