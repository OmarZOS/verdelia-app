// lib/ui/components/image/fallback_network_image.dart

import 'package:flutter/material.dart';
import 'package:ui/components/image/image_url.dart';

/// Renders the first candidate URL that actually loads.
///
/// Walks [candidates] in order. When the current URL fails to load
/// (network error, 404, malformed data), it advances to the next one.
/// Renders [placeholderBuilder] only when every candidate has failed.
class FallbackNetworkImage extends StatefulWidget {
  final List<String?> candidates;
  final BoxFit fit;
  final WidgetBuilder placeholderBuilder;

  const FallbackNetworkImage({
    super.key,
    required this.candidates,
    this.fit = BoxFit.cover,
    required this.placeholderBuilder,
  });

  @override
  State<FallbackNetworkImage> createState() => _FallbackNetworkImageState();
}

class _FallbackNetworkImageState extends State<FallbackNetworkImage> {
  late List<String> _urls;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _urls = _resolveUrls();
  }

  @override
  void didUpdateWidget(covariant FallbackNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameCandidates(oldWidget.candidates, widget.candidates)) {
      _urls = _resolveUrls();
      _index = 0;
    }
  }

  List<String> _resolveUrls() {
    final seen = <String>{};
    final out = <String>[];
    for (final candidate in widget.candidates) {
      final resolved = resolveImageUrl(candidate);
      if (resolved != null && resolved.isNotEmpty && seen.add(resolved)) {
        out.add(resolved);
      }
    }
    return out;
  }

  bool _sameCandidates(List<String?> a, List<String?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _advance() {
    if (_index + 1 >= _urls.length) return;
    setState(() => _index++);
  }

  @override
  Widget build(BuildContext context) {
    if (_urls.isEmpty || _index >= _urls.length) {
      return widget.placeholderBuilder(context);
    }

    return Image.network(
      _urls[_index],
      key: ValueKey(_urls[_index]),
      fit: widget.fit,
      errorBuilder: (_, __, ___) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _advance();
        });
        return widget.placeholderBuilder(context);
      },
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
