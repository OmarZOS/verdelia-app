import 'dart:async';

import 'package:event/components/qr_source.dart';
import 'package:flutter/foundation.dart';
import 'package:verdelia_core/business/qr_ticket.dart';

class QRNotifier extends ChangeNotifier {
  final QRSource source;
  QRNotifier(this.source);

  QRTicket? _ticket;
  bool _creating = false;
  String? _error;
  QREvent? _event;
  StreamSubscription<QREvent>? _subscription;
  bool _disposed = false;

  QRTicket? get ticket => _ticket;
  bool get isCreating => _creating;
  String? get error => _error;
  QREvent? get event => _event;
  bool get isDone => _event != null;
  bool get isWaiting =>
      _ticket != null && _event == null && !_creating && _error == null;

  Future<bool> createTicket(QRSubject subject) async {
    if (_disposed || _creating || _ticket != null) return false;
    _creating = true;
    _error = null;
    _notify();

    try {
      final ticket = await source.create(subject);
      if (_disposed) return false;
      if (ticket.qrText.isEmpty) {
        _error = 'Server returned an empty QR.';
        _creating = false;
        _notify();
        return false;
      }
      _ticket = ticket;
      _creating = false;
      _notify();
      // _subscribe(ticket.ticketId);
      return true;
    } catch (e) {
      _error = 'Failed to create QR: $e';
      _creating = false;
      _notify();
      return false;
    }
  }

  // void _subscribe(String ticketId) {
  //   _subscription?.cancel();
  //   // _subscription = source.watch(ticketId).listen(
  //     (event) {
  //       if (_disposed) return;
  //       _event = event;
  //       _notify();
  //       if (_isTerminal(event.outcome)) {
  //         _subscription?.cancel();
  //         _subscription = null;
  //       }
  //     },
  //     onError: (Object e, StackTrace st) {
  //       if (_disposed) return;
  //       _event = QREvent(
  //         outcome: QROutcome.failure,
  //         message: 'Connection lost: $e',
  //       );
  //       _notify();
  //       _subscription?.cancel();
  //       _subscription = null;
  //     },
  //   );
  // }

  bool _isTerminal(QROutcome o) => true; // all outcomes are terminal

  Future<void> regenerate(QRSubject subject) async {
    _subscription?.cancel();
    _subscription = null;
    _ticket = null;
    _event = null;
    _error = null;
    _notify();
    await createTicket(subject);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    _subscription = null;
    final t = _ticket;
    if (t != null && _event == null) {
      // source.cancel(t.ticketId).catchError((_) {});
    }
    super.dispose();
  }
}
