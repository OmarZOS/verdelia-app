import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

/// Generic QR screen. The subject decides which [QRSource] is used, so
/// the same screen serves payments, deliveries, carts, …
///
/// Pops with the terminal [QREvent] on success/failure/expiry/cancel,
/// or `null` if the user dismissed it before any outcome arrived.
class QRScreen extends StatefulWidget {
  final QRSubject subject;

  /// Optional override of the screen title. Falls back to the
  /// source's [QRSource.labelFor], then [QRSubject.defaultLabel].
  final String? title;

  const QRScreen({
    super.key,
    required this.subject,
    this.title,
  });

  @override
  State<QRScreen> createState() => _QRScreenState();
}

class _QRScreenState extends State<QRScreen> {
  late final QRNotifier _notifier;
  late final QRSource _source;
  Timer? _countdown;

  @override
  void initState() {
    super.initState();
    _source = QRSources.forKind(widget.subject.kind);
    _notifier = QRNotifier(_source);
    _notifier.addListener(_onNotifierChanged);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _notifier.createTicket(widget.subject),
    );
    _startCountdownTicker();
  }

  @override
  void dispose() {
    _countdown?.cancel();
    _notifier.removeListener(_onNotifierChanged);
    _notifier.dispose();
    super.dispose();
  }

  void _startCountdownTicker() {
    _countdown?.cancel();
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_notifier.isDone) {
        _countdown?.cancel();
        _countdown = null;
        return;
      }
      setState(() {});
    });
  }

  void _onNotifierChanged() {
    if (!mounted) return;
    final event = _notifier.event;
    if (event == null) {
      setState(() {});
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _finish(event);
    });
  }

  Future<void> _finish(QREvent event) async {
    final loc = AppLocalizations.of(context)!;
    final success = event.outcome == QROutcome.success;

    // Let the source react (close delivery, mark cart, etc.).
    if (success) {
      try {
        await _source.onSuccess(widget.subject, event);
      } catch (_) {
        // Don't block on post-success bookkeeping.
      }
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final color =
            success ? theme.colorScheme.primary : theme.colorScheme.error;
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          icon: Icon(
            success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            size: 56,
            color: color,
          ),
          title: Text(
            success ? loc.paymentSuccessTitle : loc.paymentFailedTitle,
          ),
          content: Text(
            event.message ??
                (success ? loc.paymentSuccessTitle : loc.paymentFailedBody),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(loc.ok),
            ),
          ],
        );
      },
    );
    if (!mounted) return;
    Navigator.pop(context, event);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final title = widget.title ??
        _source.labelFor(widget.subject) ??
        widget.subject.defaultLabel;
    final subtitle = _source.subtitleFor(widget.subject);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context, null),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _notifier.isCreating
              ? const Center(
                  key: ValueKey('creating'),
                  child: CircularProgressIndicator(),
                )
              : _notifier.ticket == null
                  ? _buildError(theme, loc)
                  : _buildQr(theme, loc, subtitle),
        ),
      ),
    );
  }

  Widget _buildError(ThemeData theme, AppLocalizations loc) {
    return Center(
      key: const ValueKey('error'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              _notifier.error ?? loc.failedToLoadDetails,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _notifier.regenerate(widget.subject),
              icon: const Icon(Icons.refresh),
              label: Text(loc.refreshTxt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQr(
    ThemeData theme,
    AppLocalizations loc,
    String? subtitle,
  ) {
    final ticket = _notifier.ticket!;
    final remaining = ticket.expiresAt.difference(DateTime.now());
    final expired = remaining.isNegative;
    final mmss = _formatDuration(remaining);

    return SingleChildScrollView(
      key: const ValueKey('qr'),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (subtitle != null && subtitle.isNotEmpty) ...[
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: QrImageView(
              data: ticket.qrText,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                expired ? Icons.timer_off_outlined : Icons.timer_outlined,
                size: 16,
                color: expired
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                expired ? loc.paymentQrExpired : loc.paymentQrExpiresIn(mmss),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: expired
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (expired)
            FilledButton.icon(
              onPressed: () => _notifier.regenerate(widget.subject),
              icon: const Icon(Icons.refresh),
              label: Text(loc.paymentQrRegenerate),
            )
          else
            OutlinedButton.icon(
              onPressed: () => _notifier.cancel(),
              icon: const Icon(Icons.cancel_outlined),
              label: Text(loc.cancel),
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return '00:00';
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
