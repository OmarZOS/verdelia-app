import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

String invoiceStatusText(String status, AppLocalizations loc) {
  switch (status.toLowerCase().trim()) {
    case 'paid':
      return loc.invoiceStatusPaidTxt;
    case 'unpaid':
      return loc.invoiceStatusUnpaidTxt;
    case 'partially_paid':
      return loc.invoiceStatusPartiallyPaidTxt;
    case 'overdue':
      return loc.invoiceStatusOverdueTxt;
    case 'refunded':
      return loc.invoiceStatusRefundedTxt;
    case 'canceled':
    case 'cancelled':
      return loc.invoiceStatusCanceledTxt;
    default:
      return loc.unknownTxt;
  }
}

Color invoiceStatusColor(String status, ThemeData theme) {
  switch (status.toLowerCase().trim()) {
    case 'paid':
      return Colors.green.shade700;
    case 'unpaid':
      return Colors.orange.shade800;
    case 'partially_paid':
      return Colors.amber.shade800;
    case 'overdue':
      return Colors.red.shade700;
    case 'refunded':
      return Colors.purple.shade700;
    case 'canceled':
    case 'cancelled':
      return theme.colorScheme.onSurfaceVariant;
    default:
      return theme.colorScheme.onSurfaceVariant;
  }
}
