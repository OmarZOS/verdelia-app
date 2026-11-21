// lib/screens/payment/payment_dtos.dart
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

/// Who is opening the payment form.
enum PaymentActor {
  /// The end customer paying their own invoice. Wallet-only.
  client,

  /// A provider (seller/staff) collecting money on behalf of the order.
  /// Can take cash or generate a bank QR for the payer to scan.
  provider,
}

/// Where a wallet balance comes from — the form doesn't fetch it, it's
/// passed in so the caller decides when and how to refresh.
@immutable
class WalletAccount {
  final String id;
  final String label;
  final Decimal balance;
  final String currency;
  final bool isLocked; // frozen / under review

  const WalletAccount({
    required this.id,
    required this.label,
    required this.balance,
    required this.currency,
    this.isLocked = false,
  });

  bool get canPay => !isLocked && balance > Decimal.zero;
}

/// Data encoded into the provider-side QR code so a third party's
/// wallet can pick it up and pay. Keep it small and canonical — the
/// scanner will parse exactly these fields.
@immutable
class QrPayload {
  final String invoiceRef;
  final Decimal amount;
  final String currency;
  final String payeeId; // provider wallet/merchant id
  final DateTime issuedAt;
  final String? note;

  const QrPayload({
    required this.invoiceRef,
    required this.amount,
    required this.currency,
    required this.payeeId,
    required this.issuedAt,
    this.note,
  });

  static QrPayload? tryParse(String raw) {
    try {
      final uri = Uri.parse(raw.trim());

      if (uri.scheme != 'walletpay' || uri.host != 'v1') {
        return null;
      }

      final params = uri.queryParameters;

      const requiredKeys = [
        'ref',
        'amount',
        'cur',
        'payee',
        'ts',
      ];

      for (final key in requiredKeys) {
        final value = params[key];
        if (value == null || value.trim().isEmpty) {
          return null;
        }
      }

      final amount = Decimal.tryParse(params['amount']!);
      if (amount == null || amount <= Decimal.zero) {
        return null;
      }

      final issuedAt = DateTime.tryParse(params['ts']!);
      if (issuedAt == null) {
        return null;
      }

      return QrPayload(
        invoiceRef: params['ref']!,
        amount: amount,
        currency: params['cur']!,
        payeeId: params['payee']!,
        issuedAt: issuedAt,
        note: params['note'],
      );
    } catch (_) {
      return null;
    }
  }

  /// A deterministic, versioned string the QR will encode.
  /// `walletpay://v1?ref=...&amount=...&cur=...&payee=...&ts=...`
  /// Swap for whatever your wallet ecosystem actually expects.
  String toUri() {
    final q = <String, String>{
      'ref': invoiceRef,
      'amount': amount.toStringAsFixed(2),
      'cur': currency,
      'payee': payeeId,
      'ts': issuedAt.toUtc().toIso8601String(),
      if (note != null && note!.isNotEmpty) 'note': note!,
    };
    final qs = q.entries
        .map((e) =>
            '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    return 'walletpay://v1?$qs';
  }
}
