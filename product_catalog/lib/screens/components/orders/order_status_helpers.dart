import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

/// Shared date format for order/delivery timestamps.
final DateFormat kOrderDateFmt = DateFormat('MMM d, yyyy • HH:mm');

class StatusPalette {
  final Color background;
  final Color foreground;
  final IconData icon;
  final String label;

  const StatusPalette({
    required this.background,
    required this.foreground,
    required this.icon,
    required this.label,
  });
}

/// Colour/icon/text for an *order* status (placed_order_state).
StatusPalette orderStatusPalette(
  String? status,
  ThemeData theme,
  AppLocalizations loc,
) {
  final key = (status ?? '').toLowerCase().trim();
  switch (key) {
    case 'delivered':
      return StatusPalette(
        background: Colors.green.withOpacity(0.12),
        foreground: Colors.green.shade700,
        icon: Icons.check_circle_outline,
        label: loc.deliveredTxt,
      );
    case 'shipped':
      return StatusPalette(
        background: Colors.blue.withOpacity(0.12),
        foreground: Colors.blue.shade700,
        icon: Icons.local_shipping_outlined,
        label: loc.shippedTxt,
      );
    case 'processing':
      return StatusPalette(
        background: theme.colorScheme.primary.withOpacity(0.12),
        foreground: theme.colorScheme.primary,
        icon: Icons.autorenew,
        label: loc.processingTxt,
      );
    case 'partial':
      return StatusPalette(
        background: Colors.amber.withOpacity(0.15),
        foreground: Colors.amber.shade900,
        icon: Icons.pie_chart_outline,
        label: loc.partial,
      );
    case 'pending':
      return StatusPalette(
        background: Colors.orange.withOpacity(0.12),
        foreground: Colors.orange.shade800,
        icon: Icons.schedule,
        label: loc.pendingTxt,
      );
    case 'cancelled':
    case 'canceled':
      return StatusPalette(
        background: Colors.red.withOpacity(0.12),
        foreground: Colors.red.shade700,
        icon: Icons.cancel_outlined,
        label: loc.cancelledTxt,
      );
    case 'returned':
      return StatusPalette(
        background: Colors.purple.withOpacity(0.12),
        foreground: Colors.purple.shade700,
        icon: Icons.undo,
        label: loc.deliveryReturned,
      );
    default:
      return StatusPalette(
        background: theme.colorScheme.surfaceVariant,
        foreground: theme.colorScheme.onSurfaceVariant,
        icon: Icons.help_outline,
        label: loc.unknownTxt,
      );
  }
}
