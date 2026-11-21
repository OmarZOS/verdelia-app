import 'package:locator/locator.dart';
import 'package:verdelia_core/business/qr_ticket.dart';
import 'package:verdelia_core/business/finance/services/InvoiceService.dart';
import 'package:verdelia_core/business/services/DeliveryService.dart';

/// One implementation per subject kind. The screen and notifier never
/// touch domain services directly — they go through this.
abstract class QRSource {
  /// Ask the backend for a fresh ticket.
  Future<QRTicket> create(QRSubject subject);

  // /// Subscribe to the outcome. Emits at most one terminal event; the
  // /// notifier handles closing the subscription.
  // Stream<QREvent> watch(String ticketId);

  // /// Invalidate the ticket server-side when the user leaves without
  // /// paying. Best effort — the server expires tickets anyway.
  // Future<void> cancel(String ticketId);

  // /// Optional display label for the screen title; falls back to
  // /// [QRSubject.defaultLabel].
  // String? labelFor(QRSubject subject) => null;

  // /// Optional secondary line (e.g. "Invoice INV-40-20261118", "Cart
  // /// from Verdélia Local"). The default is empty.
  // String? subtitleFor(QRSubject subject) => null;

  // /// Optional post-success callback — e.g. mark the cart as paid,
  // /// close the delivery, etc. Runs on the UI isolate after the
  // /// terminal event; must be fast or return a Future.
  // Future<void> onSuccess(QRSubject subject, QREvent event) async {}
}

/// Resolves the right [QRSource] for a subject kind.
///
/// Registered lazily so adding a new kind doesn't require touching the
/// screen. Wire new sources here.
class QRSources {
  static QRSource forKind(QRSubjectKind kind) {
    switch (kind) {
      case QRSubjectKind.payment:
        return _PaymentQRSource();
      // case QRSubjectKind.delivery:
      //   return _DeliveryQRSource();
      // case QRSubjectKind.cart:
      //   return _CartQRSource();
    }
  }
}

// ==================== PAYMENT ====================

class _PaymentQRSource implements QRSource {
  final InvoiceService _service = AppLocator.get<InvoiceService>();

  @override
  Future<QRTicket> create(QRSubject subject) async {
    // final ticket = await _service.createPaymentQr(
    //   invoiceId: int.parse(subject.opaqueId),
    //   amount: subject.params['amount'],
    //   currency: subject.params['currency'] as String? ?? 'DZD',
    //   payeeId: subject.params['payeeId'] as String? ?? '',
    //   note: subject.params['note'] as String?,
    // );
    return QRTicket(
      ticketId: "0",
      qrText: "",
      expiresAt: DateTime.now().add(Duration(hours: 1)),
      subject: subject,
    );
  }

  // @override
  // Stream<QREvent> watch(String ticketId) =>
  //     _service.watchPaymentQr(ticketId).map((e) => QREvent(
  //           outcome: _mapOutcome(e.outcome),
  //           message: e.message,
  //           reference: e.reference,
  //         ));

  // @override
  // Future<void> cancel(String ticketId) => _service.cancelPaymentQr(ticketId);

  // @override
  // String? labelFor(QRSubject s) => s.params['title'] as String?;

  QROutcome _mapOutcome(dynamic o) {
    final name = o.toString().split('.').last.toLowerCase();
    switch (name) {
      case 'success':
        return QROutcome.success;
      case 'expired':
        return QROutcome.expired;
      case 'cancelled':
        return QROutcome.cancelled;
      default:
        return QROutcome.failure;
    }
  }
}

// ==================== DELIVERY ====================

// class _DeliveryQRSource implements QRSource {
//   final DeliveryService _service = AppLocator.get<DeliveryService>();

//   @override
//   Future<QRTicket> create(QRSubject subject) async {
//     final ticket = await _service.createDeliveryQr(
//       deliveryId: int.parse(subject.opaqueId),
//       // whatever fields the delivery QR needs
//     );
//     return QRTicket(
//       ticketId: ticket.ticketId,
//       qrText: ticket.qrText,
//       expiresAt: ticket.expiresAt,
//       subject: subject,
//     );
//   }

//   @override
//   Stream<QREvent> watch(String ticketId) =>
//       _service.watchDeliveryQr(ticketId).map((e) => QREvent(
//             outcome: _mapOutcome(e.outcome),
//             message: e.message,
//             reference: e.reference,
//           ));

//   @override
//   Future<void> cancel(String ticketId) => _service.cancelDeliveryQr(ticketId);

//   QROutcome _mapOutcome(dynamic o) {
//     final name = o.toString().split('.').last.toLowerCase();
//     switch (name) {
//       case 'success':
//         return QROutcome.success;
//       case 'expired':
//         return QROutcome.expired;
//       case 'cancelled':
//         return QROutcome.cancelled;
//       default:
//         return QROutcome.failure;
//     }
//   }
// }

// ==================== CART ====================

// class _CartQRSource implements QRSource {
//   final CartService _service = AppLocator.get<CartService>();

//   @override
//   Future<QRTicket> create(QRSubject subject) async {
//     final ticket = await _service.createCartQr(
//       cartId: int.parse(subject.opaqueId),
//     );
//     return QRTicket(
//       ticketId: ticket.ticketId,
//       qrText: ticket.qrText,
//       expiresAt: ticket.expiresAt,
//       subject: subject,
//     );
//   }

//   @override
//   Stream<QREvent> watch(String ticketId) =>
//       _service.watchCartQr(ticketId).map((e) => QREvent(
//             outcome: _mapOutcome(e.outcome),
//             message: e.message,
//             reference: e.reference,
//           ));

//   @override
//   Future<void> cancel(String ticketId) => _service.cancelCartQr(ticketId);

//   QROutcome _mapOutcome(dynamic o) {
//     final name = o.toString().split('.').last.toLowerCase();
//     switch (name) {
//       case 'success':
//         return QROutcome.success;
//       case 'expired':
//         return QROutcome.expired;
//       case 'cancelled':
//         return QROutcome.cancelled;
//       default:
//         return QROutcome.failure;
//     }
//   }
// }
