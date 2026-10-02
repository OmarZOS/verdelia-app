import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:verdelia_core/business/Supplier.dart';
import 'package:url_launcher/url_launcher.dart';

ListTile buildLocationTile(BuildContext context, Supplier supplier) {
  final theme = Theme.of(context);
  final hasLocation =
      supplier.locationLatitude != null && supplier.locationLongitude != null;

  Future<void> openInMaps() async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${supplier.locationLatitude},${supplier.locationLongitude}';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps')),
      );
    }
  }

  void copyToClipboard() {
    final coords =
        '${supplier.locationLatitude.toStringAsFixed(6)}, ${supplier.locationLongitude?.toStringAsFixed(6)}';
    Clipboard.setData(ClipboardData(text: coords));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Coordinates copied: $coords')),
    );
  }

  return ListTile(
    onTap: hasLocation ? openInMaps : null,
    onLongPress: hasLocation ? copyToClipboard : null,
    leading: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(
          Icons.location_on,
          color: hasLocation
              ? theme.colorScheme.onSurfaceVariant
              : theme.colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
    ),
    title: Text(
      supplier.locationName ?? 'No location specified',
      style: theme.textTheme.bodyMedium,
    ),
    subtitle: hasLocation
        ? Text(
            '${supplier.locationLatitude.toStringAsFixed(4)}, '
            '${supplier.locationLongitude.toStringAsFixed(4)}',
            style: theme.textTheme.bodySmall,
          )
        : null,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
    minLeadingWidth: 0,
  );
}
