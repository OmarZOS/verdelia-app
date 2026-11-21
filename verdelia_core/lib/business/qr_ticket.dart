import 'package:flutter/foundation.dart';

/// What the QR is for. Extend this as new flows appear — deliveries,
/// carts, invoices, transfers, whatever. `opaqueId` is the only field
/// the UI reads; the rest is source-specific payload that the
/// [QRSource] knows how to turn into a ticket.
enum QRSubjectKind {
  payment,
  // delivery,
  // cart,
  // add more as needed
}

@immutable
class QRSubject {
  final QRSubjectKind kind;

  /// Domain id this QR refers to (invoice id, delivery id, cart id, …).
  final String opaqueId;

  /// Source-specific parameters (amount, currency, payee, address,
  /// provider, etc.). The [QRSource] decides what it needs; the
  /// screen treats this as opaque.
  final Map<String, dynamic> params;

  const QRSubject({
    required this.kind,
    required this.opaqueId,
    this.params = const {},
  });

  /// A short label the UI can show without knowing the domain.
  /// Sources override this via [QRSource.labelFor] when they want
  /// something prettier.
  String get defaultLabel => '$kind:$opaqueId';

  @override
  String toString() => 'QRSubject(${kind.name}, $opaqueId)';
}

/// The ticket the server mints. Same shape for every subject type —
/// only `qrText` and `ticketId` are actually used by the UI; the rest
/// is source metadata the notifier keeps so [QRSource.cancel] and the
/// success handler can do the right thing.
@immutable
class QRTicket {
  final String ticketId;
  final String qrText;
  final DateTime expiresAt;
  final QRSubject subject;

  const QRTicket({
    required this.ticketId,
    required this.qrText,
    required this.expiresAt,
    required this.subject,
  });
}

enum QROutcome { success, failure, expired, cancelled }

@immutable
class QREvent {
  final QROutcome outcome;
  final String? message;
  final String? reference;

  /// Arbitrary result payload the source wants to hand back to the
  /// caller after success. E.g. a payment source might attach
  /// `{'paid_amount': ..., 'method': ...}`.
  final Map<String, dynamic>? data;

  const QREvent({
    required this.outcome,
    this.message,
    this.reference,
    this.data,
  });
}
