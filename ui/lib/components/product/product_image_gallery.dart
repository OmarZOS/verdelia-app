// lib/ui/components/product/product_image_gallery.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:ui/components/image/image_url.dart';

// ══════════════════════════════════════════════════════════════════
// THUMBNAIL STRIP
// ══════════════════════════════════════════════════════════════════

/// Horizontal, swipeable strip of small product thumbnails.
///
/// - Tap any thumbnail → opens the full-screen slider at that index.
/// - A soft glow marks the currently selected thumb.
/// - Scrolls edge-to-edge with a snap feel.
///
/// Designed to sit directly under the product header on the details
/// screen, or inside a bottom sheet.
class ProductImageThumbnailStrip extends StatefulWidget {
  final List<ProductImage> images;

  /// Optional: which image to consider "selected" on first render.
  final int initialIndex;

  /// Height of each thumbnail. Width scales to keep a 1:1 aspect.
  final double size;

  /// Gap between thumbnails.
  final double spacing;

  /// Called when the user taps a thumb. If null, the widget opens the
  /// internal slider by default. Provide a callback to override that.
  final ValueChanged<int>? onTap;
  final ValueChanged<ProductImage>? onImageRemoved;

  const ProductImageThumbnailStrip({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.size = 64,
    this.spacing = 10,
    this.onTap,
    this.onImageRemoved,
  });

  @override
  State<ProductImageThumbnailStrip> createState() =>
      _ProductImageThumbnailStripState();
}

class _ProductImageThumbnailStripState
    extends State<ProductImageThumbnailStrip> {
  late List<ProductImage> _images;
  late int _selected;
  late final ScrollController _controller;
  final Set<ProductImage> _failedImages = {};

  @override
  void initState() {
    super.initState();
    _images = _usableImages(widget.images);
    _selected = widget.initialIndex.clamp(
      0,
      _images.isEmpty ? 0 : _images.length - 1,
    );
    _controller = ScrollController(
      initialScrollOffset: _selected * (widget.size + widget.spacing),
    );
  }

  List<ProductImage> _usableImages(Iterable<ProductImage> images) => images
      .where((image) =>
          !_failedImages.contains(image) && resolveImageUrl(image.url) != null)
      .toList();

  void _dropImage(ProductImage image) {
    if (!_failedImages.add(image)) return;
    widget.onImageRemoved?.call(image);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final index = _images.indexOf(image);
      if (index < 0) return;
      setState(() {
        _images.removeAt(index);
        if (_images.isEmpty) {
          _selected = 0;
        } else if (_selected >= _images.length) {
          _selected = _images.length - 1;
        } else if (index < _selected) {
          _selected--;
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openSlider(int index) async {
    setState(() => _selected = index);

    if (widget.onTap != null) {
      widget.onTap!(index);
      return;
    }

    await ProductImageSlider.show(
      context,
      images: _images,
      initialIndex: index,
      heroTagPrefix: 'product-thumb',
      onImageRemoved: _dropImage,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_images.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: widget.size,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: _images.length,
        separatorBuilder: (_, __) => SizedBox(width: widget.spacing),
        itemBuilder: (context, i) {
          final img = _images[i];
          final isSelected = i == _selected;

          return _ThumbnailTile(
            image: img,
            size: widget.size,
            selected: isSelected,
            heroTag: 'product-thumb-$i',
            onTap: () => _openSlider(i),
            onImageFailed: () => _dropImage(img),
            placeholderColor: cs.surfaceContainerHighest,
          );
        },
      ),
    );
  }
}

class _ThumbnailTile extends StatelessWidget {
  final ProductImage image;
  final double size;
  final bool selected;
  final String heroTag;
  final VoidCallback onTap;
  final VoidCallback onImageFailed;
  final Color placeholderColor;

  const _ThumbnailTile({
    required this.image,
    required this.size,
    required this.selected,
    required this.heroTag,
    required this.onTap,
    required this.onImageFailed,
    required this.placeholderColor,
  });

  @override
  Widget build(BuildContext context) {
    final url = resolveImageUrl(image.url);

    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? cs.primary.withOpacity(0.9)
                : cs.outlineVariant.withOpacity(0.6),
            width: selected ? 2.2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: cs.primary.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ColoredBox(
            color: placeholderColor,
            child: url != null
                ? Hero(
                    tag: heroTag,
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        onImageFailed();
                        return const SizedBox.shrink();
                      },
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return _LoadingTile(size: size);
                      },
                    ),
                  )
                : _BrokenTile(size: size),
          ),
        ),
      ),
    );
  }
}

class _BrokenTile extends StatelessWidget {
  final double size;
  const _BrokenTile({required this.size});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        size: size * 0.4,
        color: cs.onSurface.withOpacity(0.4),
      ),
    );
  }
}

class _LoadingTile extends StatelessWidget {
  final double size;
  const _LoadingTile({required this.size});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: SizedBox(
        width: size * 0.35,
        height: size * 0.35,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: cs.primary.withOpacity(0.6),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// FULL-SCREEN SLIDER
// ══════════════════════════════════════════════════════════════════

/// Full-screen, swipeable image gallery.
///
/// Features:
///   - Horizontal swipe between images.
///   - Snap-to-page physics.
///   - Animated dot indicator pinned above the bottom safe area.
///   - Counter pill in the top-right (`3 / 7`).
///   - Tap-to-close on the backdrop, drag-down-to-dismiss.
///   - Hero transition from the thumbnail strip.
///   - Volume-button / arrow-key navigation on supported platforms.
class ProductImageSlider extends StatefulWidget {
  final List<ProductImage> images;
  final int initialIndex;
  final String heroTagPrefix;
  final ValueChanged<ProductImage>? onImageRemoved;

  const ProductImageSlider({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.heroTagPrefix = 'product-slider',
    this.onImageRemoved,
  });

  /// Convenience opener for the common case.
  static Future<void> show(
    BuildContext context, {
    required List<ProductImage> images,
    int initialIndex = 0,
    String heroTagPrefix = 'product-thumb',
    ValueChanged<ProductImage>? onImageRemoved,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (_, __, ___) => ProductImageSlider(
          images: images,
          initialIndex: initialIndex,
          heroTagPrefix: heroTagPrefix,
          onImageRemoved: onImageRemoved,
        ),
        transitionsBuilder: (context, anim, _, child) {
          final curved = CurvedAnimation(
            parent: anim,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(opacity: curved, child: child);
        },
      ),
    );
  }

  @override
  State<ProductImageSlider> createState() => _ProductImageSliderState();
}

class _ProductImageSliderState extends State<ProductImageSlider> {
  late List<ProductImage> _images;
  late final PageController _pageController;
  late int _current;
  double _dragOffset = 0;
  final Set<ProductImage> _failedImages = {};

  @override
  void initState() {
    super.initState();
    _images = widget.images
        .where((image) => resolveImageUrl(image.url) != null)
        .toList();
    _current = widget.initialIndex.clamp(
      0,
      _images.isEmpty ? 0 : _images.length - 1,
    );
    _pageController = PageController(initialPage: _current);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index < 0 || index >= _images.length) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _dropImage(ProductImage image) {
    if (!_failedImages.add(image)) return;
    widget.onImageRemoved?.call(image);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final index = _images.indexOf(image);
      if (index < 0) return;
      setState(() {
        _images.removeAt(index);
        if (_images.isEmpty) {
          _current = 0;
        } else if (_current >= _images.length) {
          _current = _images.length - 1;
        } else if (index < _current) {
          _current--;
        }
      });
      if (_images.isNotEmpty) _pageController.jumpToPage(_current);
    });
  }

  // Handle keyboard arrow navigation for desktop / web.
  void _handleKey(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _goTo(_current - 1);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _goTo(_current + 1);
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_images.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text('No images', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    return RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: _handleKey,
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            // ─── Dismiss gesture wrapper ─────────────────────────
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: (d) {
                setState(() {
                  _dragOffset = (_dragOffset + d.delta.dy).clamp(0, 400);
                });
              },
              onVerticalDragEnd: (_) {
                if (_dragOffset > 120) {
                  Navigator.of(context).pop();
                } else {
                  setState(() => _dragOffset = 0);
                }
              },
              onTap: () => Navigator.of(context).pop(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                transform: Matrix4.identity()
                  ..translate(0.0, _dragOffset * 0.6),
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (i) => setState(() => _current = i),
                  itemCount: _images.length,
                  itemBuilder: (context, i) {
                    final img = _images[i];
                    return _SliderPage(
                      image: img,
                      heroTag: '${widget.heroTagPrefix}-$i',
                      onImageFailed: () => _dropImage(img),
                    );
                  },
                ),
              ),
            ),

            // ─── Top bar: close + counter ─────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Row(
                    children: [
                      _GlassCircleButton(
                        icon: Icons.close_rounded,
                        onTap: () => Navigator.of(context).pop(),
                        tooltip: MaterialLocalizations.of(context)
                            .closeButtonTooltip,
                      ),
                      const Spacer(),
                      _CounterPill(
                        current: _current + 1,
                        total: _images.length,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─── Bottom: dot indicator ────────────────────────────
            if (_images.length > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _DotIndicator(
                      count: _images.length,
                      current: _current,
                      onTap: _goTo,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SliderPage extends StatelessWidget {
  final ProductImage image;
  final String heroTag;
  final VoidCallback onImageFailed;

  const _SliderPage({
    required this.image,
    required this.heroTag,
    required this.onImageFailed,
  });

  @override
  Widget build(BuildContext context) {
    final url = resolveImageUrl(image.url);
    if (url == null) {
      return const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Colors.white24,
          size: 64,
        ),
      );
    }

    return Center(
      child: Hero(
        tag: heroTag,
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          clipBehavior: Clip.none,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) {
                onImageFailed();
                return const SizedBox.shrink();
              },
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                final total = progress.expectedTotalBytes;
                final value = total != null
                    ? progress.cumulativeBytesLoaded / total
                    : null;
                return Center(
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      value: value,
                      strokeWidth: 2.5,
                      color: Colors.white70,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Small pieces
// ══════════════════════════════════════════════════════════════════

class _GlassCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _GlassCircleButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withOpacity(0.08),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

class _CounterPill extends StatelessWidget {
  final int current;
  final int total;

  const _CounterPill({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Text(
        '$current / $total',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  final int count;
  final int current;
  final ValueChanged<int> onTap;

  const _DotIndicator({
    required this.count,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return GestureDetector(
          onTap: () => onTap(i),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: active ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.white38,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}
