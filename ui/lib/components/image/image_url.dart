// lib/ui/utils/image_url.dart (in the presentation layer)

import 'package:app_constants/app_constants.dart';

/// Resolve a [ProductImage.url] to a fully-qualified `http(s)` URL.
///
/// Returns null when the value can't be rendered. Rules:
///   1. Null / empty → null.
///   2. Already `http://` or `https://` → returned as-is.
///   3. Anything else → treated as a relative path and joined onto
///      [AppConstants.fsBaseUrl] with a single slash between.
///
/// This is where the `fsBaseUrl` knowledge lives — the core model
/// never learns about the file server.
String? resolveImageUrl(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  final lower = trimmed.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    return trimmed;
  }

  final base = AppConstants.fsBaseUrl.endsWith('/')
      ? AppConstants.fsBaseUrl.substring(0, AppConstants.fsBaseUrl.length - 1)
      : AppConstants.fsBaseUrl;
  final path = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;

  return '$base/$path';
}

/// Resolve a whole gallery, keeping only entries whose URL survives.
/// Order-preserving, idempotent.
List<({int id, String url})> resolveGallery(List<dynamic> images) {
  final out = <({int id, String url})>[];
  for (final img in images) {
    final resolved = resolveImageUrl(img.url as String?);
    if (resolved == null) continue;
    out.add((id: img.id as int, url: resolved));
  }
  return List.unmodifiable(out);
}
