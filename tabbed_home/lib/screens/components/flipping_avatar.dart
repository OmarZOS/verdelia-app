import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:ui/components/image/image_url.dart';

/// A circular avatar that flips to reveal a QR code.
///
/// Tap the avatar (or the small button) to flip between:
///   Front — user profile image (or a placeholder icon)
///   Back  — QR code containing [qrData]
class FlippingAvatar extends StatefulWidget {
  final String? imageUrl;
  final String qrData;
  final double size;
  final Color? borderColor;
  final Color? backgroundColor;

  const FlippingAvatar({
    super.key,
    required this.imageUrl,
    required this.qrData,
    this.size = 100,
    this.borderColor,
    this.backgroundColor,
  });

  @override
  State<FlippingAvatar> createState() => _FlippingAvatarState();
}

class _FlippingAvatarState extends State<FlippingAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _flip;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flip = Tween<double>(begin: 0, end: math.pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_controller.isAnimating) return;
    if (_controller.value < 0.5) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  /// True when the back face should be visible.
  bool get _isBackFaceVisible => _controller.value > 0.5;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final diameter = widget.size * 2;

    return GestureDetector(
      onTap: _toggle,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: SizedBox(
          width: diameter,
          height: diameter,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedBuilder(
                animation: _flip,
                builder: (context, _) {
                  final angle = _flip.value;
                  final isBack = angle > math.pi / 2;

                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle),
                    child: isBack
                        // Counter-rotate the back face so its content isn't mirrored.
                        ? Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(math.pi),
                            child: _buildBackFace(context, scheme),
                          )
                        : _buildFrontFace(context, scheme),
                  );
                },
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: _FlipButton(
                  isFrontVisible: !_isBackFaceVisible,
                  onTap: _toggle,
                  scheme: scheme,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== FACES ====================

  Widget _buildFrontFace(BuildContext context, ColorScheme scheme) {
    return _Face(
      size: widget.size,
      borderColor: widget.borderColor ?? scheme.primary,
      backgroundColor: widget.backgroundColor ?? scheme.surfaceContainerHighest,
      child: _buildAvatarContent(context, scheme),
    );
  }

  Widget _buildBackFace(BuildContext context, ColorScheme scheme) {
    return _Face(
      size: widget.size,
      borderColor: widget.borderColor ?? scheme.primary,
      backgroundColor: widget.backgroundColor ?? scheme.surface,
      child: Padding(
        padding: EdgeInsets.all(widget.size * 0.15),
        child: QrImageView(
          data: widget.qrData,
          version: QrVersions.auto,
          backgroundColor: Colors.transparent,
          eyeStyle: QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: scheme.onSurface,
          ),
          dataModuleStyle: QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: scheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarContent(BuildContext context, ColorScheme scheme) {
    // Route the raw URL through the shared resolver so relative paths
    // coming from the API (`/uploads/avatar.png`) get joined with the
    // FS base, and placeholders / empty strings fall through to the
    // icon instead of trying to load a broken image.
    final resolved = resolveImageUrl(widget.imageUrl);

    if (resolved == null) {
      return _buildFallbackIcon(scheme);
    }

    return ClipOval(
      child: Image.network(
        resolved,
        width: widget.size * 2,
        height: widget.size * 2,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(
            child: SizedBox(
              width: widget.size * 0.4,
              height: widget.size * 0.4,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _buildFallbackIcon(scheme),
      ),
    );
  }

  Widget _buildFallbackIcon(ColorScheme scheme) {
    return Icon(
      Icons.person_rounded,
      size: widget.size * 0.9,
      color: scheme.onSurfaceVariant,
    );
  }
}

// ==================== SHARED CIRCULAR FRAME ====================

/// The circular border + shadow + background shared by both faces.
/// Eliminates duplication between front and back.
class _Face extends StatelessWidget {
  final double size;
  final Color borderColor;
  final Color backgroundColor;
  final Widget child;

  const _Face({
    required this.size,
    required this.borderColor,
    required this.backgroundColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * 2,
      height: size * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Center(child: child),
    );
  }
}

// ==================== FLIP BUTTON ====================

/// Small floating action button that sits on the avatar's corner.
class _FlipButton extends StatelessWidget {
  final bool isFrontVisible;
  final VoidCallback onTap;
  final ColorScheme scheme;

  const _FlipButton({
    required this.isFrontVisible,
    required this.onTap,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: scheme.primary,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            isFrontVisible ? Icons.qr_code_2_rounded : Icons.person_rounded,
            color: scheme.onPrimary,
            size: 22,
          ),
        ),
      ),
    );
  }
}
