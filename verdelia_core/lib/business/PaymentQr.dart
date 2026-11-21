import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

/// What the backend mints when asked for a payment QR.
///
/// Kept in the domain (not the UI) so `InvoiceService` can return it
/// without pulling in `qr_flutter` or `AppLocalizations`.
@immutable
class PaymentQrTicket {
  final String ticketId;

  /// The exact string the QR encodes. The UI draws this; nothing else.
  final String qrText;

  /// When the QR stops being valid.
  final DateTime expiresAt;

  const PaymentQrTicket({
    required this.ticketId,
    required this.qrText,
    required this.expiresAt,
  });

  factory PaymentQrTicket.fromJson(Map<String, dynamic> json) {
    return PaymentQrTicket(
      ticketId: json['ticket_id'] as String? ?? '',
      qrText: json['qr_text'] as String? ?? '',
      expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? '') ??
          DateTime.now().add(const Duration(minutes: 10)),
    );
  }
}

/// Lifecycle events emitted on the `watchPaymentQr` stream.
enum PaymentQrOutcome { success, failure, expired, cancelled }

@immutable
class PaymentQrEvent {
  final PaymentQrOutcome outcome;

  /// Server-provided message for the dialog. Display, don't parse.
  final String? message;

  /// Optional receipt/reference on success.
  final String? reference;

  /// Amount the payer actually settled, if the server sends it.
  /// Needed because a QR can be over/underpaid.
  final Decimal? paidAmount;

  const PaymentQrEvent({
    required this.outcome,
    this.message,
    this.reference,
    this.paidAmount,
  });

  factory PaymentQrEvent.fromJson(Map<String, dynamic> json) {
    return PaymentQrEvent(
      outcome: _parseOutcome(json['outcome'] as String?),
      message: json['message'] as String?,
      reference: json['reference'] as String?,
      paidAmount: _parseDecimal(json['paid_amount']),
    );
  }

  static PaymentQrOutcome _parseOutcome(String? raw) {
    switch ((raw ?? '').toLowerCase().trim()) {
      case 'success':
      case 'paid':
      case 'settled':
        return PaymentQrOutcome.success;
      case 'expired':
        return PaymentQrOutcome.expired;
      case 'cancelled':
      case 'canceled':
        return PaymentQrOutcome.cancelled;
      default:
        return PaymentQrOutcome.failure;
    }
  }

  static Decimal? _parseDecimal(dynamic raw) {
    if (raw == null) return null;
    if (raw is Decimal) return raw;
    if (raw is num) return Decimal.tryParse(raw.toString());
    if (raw is String) return Decimal.tryParse(raw);
    return null;
  }
}
