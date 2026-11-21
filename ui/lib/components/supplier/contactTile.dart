import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ui/components/Linkifier.dart';
import 'package:ui/components/externalAppLauncher.dart';

List<Widget> buildContactTiles(BuildContext context, String contactInfo) {
  final theme = Theme.of(context);
  final contacts = parseContactInfo(contactInfo);

  return contacts.map((contact) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent, // so background shows
        child: InkWell(
          borderRadius: BorderRadius.circular(12), // match container radius
          onTap: () =>
              launchExternalApp(context, contact['type']!, contact['value']!),
          onLongPress: () {
            Clipboard.setData(ClipboardData(text: contact['value']!));
          },
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.onSurfaceVariant,
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: buildContactTile(
              context,
              contact['type']!,
              contact['value']!,
            ),
          ),
        ),
      ),
    );
  }).toList();
}

Widget buildContactTile(BuildContext context, String type, String value) {
  final theme = Theme.of(context);
  final icon = getContactIcon(type);
  final displayValue = value.trim().replaceAll(" ", "");

  return Row(
    children: [
      // Icon container
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child:
              FaIcon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
      const SizedBox(width: 12),

      // Contact info
      Expanded(
        child: GestureDetector(
          onTap: () => launchExternalApp(context, type, displayValue),
          onLongPress: () {
            Clipboard.setData(ClipboardData(text: displayValue));
          },
          child: Text(
            displayValue.split(RegExp(r"[=/]")).where((t) => t != "").last,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ),
    ],
  );
}

FaIconData getContactIcon(String type) {
  final lowercaseType = type.toLowerCase();

  if (lowercaseType.contains('facebook')) return FontAwesomeIcons.facebook;
  if (lowercaseType.contains('phone')) return FontAwesomeIcons.phone;
  if (lowercaseType.contains('website')) return FontAwesomeIcons.globe;
  if (lowercaseType.contains('instagram')) return FontAwesomeIcons.instagram;
  if (lowercaseType.contains('email')) return FontAwesomeIcons.envelope;
  if (lowercaseType.contains('whatsapp')) return FontAwesomeIcons.whatsapp;
  if (lowercaseType.contains('tiktok')) return FontAwesomeIcons.tiktok;

  return FontAwesomeIcons.addressCard; // default icon
}

List<Map<String, String>> parseContactInfo(String contactInfo) {
  final List<Map<String, String>> contacts = [];
  // Improved regex to better handle website URLs
  final pattern = RegExp(r'([A-Za-z]+):\s*([^,]+)(?:,\s*|$)');
  final matches = pattern.allMatches(contactInfo);

  for (final match in matches) {
    if (match.groupCount >= 2) {
      contacts.add({
        'type': match.group(1)?.trim() ?? '',
        'value': match.group(2)?.trim() ?? '',
      });
    }
  }

  return contacts;
}

Widget buildDetailRow(
  BuildContext context, {
  required FaIconData icon,
  required String label,
  required String value,
  Widget? trailing,
  VoidCallback? onLongPress,
}) {
  final theme = Theme.of(context);

  // Map of contact types to icons
  final Map<String, FaIconData> contactIcons = {
    'instagram': FontAwesomeIcons.instagram,
    'facebook': FontAwesomeIcons.facebook,
    'email': FontAwesomeIcons.envelope,
    'phone': FontAwesomeIcons.phone,
    'tiktok': FontAwesomeIcons.tiktok,
  };

  // Get the appropriate icon
  final lowercaseLabel = label.toLowerCase();
  final matchedIcon = contactIcons.entries
      .firstWhere((e) => lowercaseLabel.contains(e.key),
          orElse: () => MapEntry('', icon))
      .value;

  return GestureDetector(
    onLongPress: onLongPress,
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon container
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: FaIcon(
                matchedIcon,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label (only shown if not a recognized contact type)
                if (!contactIcons.keys.any(lowercaseLabel.contains))
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                if (!contactIcons.keys.any(lowercaseLabel.contains))
                  const SizedBox(height: 4),

                // Value with link detection
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Linkify(
                    text: value,
                    style: theme.textTheme.bodyMedium,
                    linkStyle: TextStyle(
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                    options: const LinkifyOptions(humanize: false),
                    // onOpen: (link) =>
                    // _handleLinkOpen(context, link, lowercaseLabel),
                    linkifiers: const [
                      UrlLinkifier(),
                      EmailLinkifier(),
                      PhoneNumberLinkifier(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Trailing widget if provided
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing,
          ],
        ],
      ),
    ),
  );
}
