import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

String deliveryStatusText(String? status, AppLocalizations loc) {
  switch ((status ?? '').toLowerCase().trim()) {
    case 'pending':
      return loc.deliveryStatusPendingTxt;
    case 'processing':
      return loc.processingTxt;
    case 'confirmed':
      return loc.deliveryStatusConfirmedTxt;
    case 'shipped':
      return loc.shippedTxt;
    case 'in_transit':
      return loc.deliveryStatusInTransitTxt;
    case 'out_for_delivery':
      return loc.deliveryOutForDelivery;
    case 'delivered':
      return loc.deliveryStatusDeliveredTxt;
    case 'failed':
      return loc.deliveryFailed;
    case 'cancelled':
    case 'canceled':
      return loc.deliveryStatusCancelledTxt;
    case 'returned':
      return loc.deliveryReturned;
    case 'refunded':
      return loc.refunded;
    default:
      return loc.unknownTxt;
  }
}

Color deliveryStatusColor(String? status, ThemeData theme) {
  switch ((status ?? '').toLowerCase().trim()) {
    case 'delivered':
      return Colors.green.shade700;
    case 'shipped':
    case 'in_transit':
    case 'out_for_delivery':
      return Colors.blue.shade700;
    case 'confirmed':
    case 'processing':
      return Colors.teal.shade700;
    case 'pending':
      return Colors.orange.shade800;
    case 'failed':
    case 'cancelled':
    case 'canceled':
      return Colors.red.shade700;
    case 'returned':
      return Colors.purple.shade700;
    case 'refunded':
      return Colors.deepPurple.shade700;
    default:
      return theme.colorScheme.onSurfaceVariant;
  }
}

String humanizeShippingMethod(String? method, AppLocalizations loc) {
  if (method == null || method.trim().isEmpty) return '';
  switch (method.toLowerCase().trim()) {
    case 'standard':
      return loc.standardTxt;
    case 'express':
      return loc.express;
    case 'same_day':
    case 'sameday':
      return loc.shippingMethodSameDay;
    case 'overnight':
      return loc.overnight;
    case 'pickup':
      return loc.pickup;
    default:
      final cleaned = method.replaceAll('_', ' ').trim();
      return cleaned.isEmpty
          ? ''
          : cleaned[0].toUpperCase() + cleaned.substring(1);
  }
}
