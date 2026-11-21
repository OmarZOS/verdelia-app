import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui/components/payment_dtos.dart';
import 'package:ui/components/qr/qr_display.dart'; // for QrPayload
import 'package:ui/screens/payment_form_screen.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

/// The signature the caller must supply so the card can submit a
/// scanned payment. This is the only external dependency: everything
/// else (scanning, parsing, routing, error UI) lives in this widget.
typedef SubmitPayment = Future<String?> Function(
  Decimal amount,
  String method,
  String notes,
);

/// A wallet card that, on tapping the QR chip, opens the scanner,
/// parses the payload, and pushes `PaymentFormScreen`. The card
/// returns whether the payment succeeded via `Navigator.pop(true)`.
class ProfileWalletCard extends StatefulWidget {
  final WalletAccount? wallet;
  final String? selfPayeeId;
  final SubmitPayment onSubmit;
  final bool busy;

  const ProfileWalletCard({
    super.key,
    required this.wallet,
    required this.onSubmit,
    this.selfPayeeId,
    this.busy = false,
  });

  @override
  State<ProfileWalletCard> createState() => _ProfileWalletCardState();
}

class _ProfileWalletCardState extends State<ProfileWalletCard> {
  bool _scanning = false;

  Future<void> _startScanAndPay() async {
    final wallet = widget.wallet;

    if (_scanning || widget.busy || wallet == null || wallet.isLocked) {
      return;
    }

    setState(() => _scanning = true);

    try {
      HapticFeedback.selectionClick();

      final raw = await _launchScanner();

      if (!mounted || raw == null || raw.isEmpty) return;

      final payload = QrPayload.tryParse(raw);

      if (payload == null) {
        _showError(
          AppLocalizations.of(context)!.paymentQrInvalidPayload,
        );
        return;
      }

      if (widget.selfPayeeId != null && payload.payeeId == widget.selfPayeeId) {
        _showError(
          AppLocalizations.of(context)!.paymentQrSelfPay,
        );
        return;
      }

      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PaymentFormScreen(
            amountDue: payload.amount,
            initialAmount: payload.amount,
            currency: payload.currency,
            title: payload.invoiceRef,
            actor: PaymentActor.client,
            wallet: wallet,
            payeeId: payload.payeeId,
            onSubmit: widget.onSubmit,
          ),
        ),
      );

      if (!mounted) return;

      if (result == true) {
        _showSuccess();
      }
    } finally {
      if (mounted) {
        setState(() => _scanning = false);
      }
    }
  }

  Future<String?> _launchScanner() async {
    // Scanner implementation stays here.
    return null;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  void _showSuccess() {
    final l10n = AppLocalizations.of(context)!;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.paymentSuccessTitle),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    if (widget.wallet == null) {
      return _Hint(
        icon: Icons.account_balance_wallet_outlined,
        title: l10n.walletSectionText,
        body: l10n.paymentWalletMissingBody,
      );
    }

    final w = widget.wallet!;
    final locked = w.isLocked;
    final empty = w.balance <= Decimal.zero;
    final accent = locked || empty ? cs.error : cs.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              size: 20,
              color: accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  locked
                      ? l10n.paymentWalletLocked
                      : empty
                          ? l10n.paymentWalletEmpty
                          : l10n.paymentWalletAvailable,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${w.balance.toStringAsFixed(2)} ${w.currency}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: accent,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ScanToPayChip(
            label: l10n.scanToPayLabel,
            enabled: !widget.busy && !locked,
            onPressed: () => _startScanAndPay(),
          ),
        ],
      ),
    );
  }

  /// Full flow: scan → parse → push payment screen → surface result.
}

/// Icon-only pill chip matching `_StatusBadge` styling.
class ScanToPayChip extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback? onPressed;

  const ScanToPayChip({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = enabled ? cs.primary : cs.onSurfaceVariant.withOpacity(0.4);
    final bg = (enabled ? cs.primary : cs.onSurfaceVariant).withOpacity(0.12);

    return Tooltip(
      message: label,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Icon(
              Icons.qr_code_scanner_rounded,
              size: 22,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _Hint({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
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
