import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Renders a QR code for [data] inside a padded, theme-aware frame.
///
/// Use this anywhere a QR code needs to be shown — a flip-avatar back
/// face, a payment ticket screen, a delivery hand-off sheet. The widget
/// is purely presentational: it owns no state and does not fetch
/// anything. Callers pass the exact string that should be encoded.
///
/// The QR is drawn with square modules and square eyes in the theme's
/// on-surface colour so it stays scannable against the light surface
/// background, and the surrounding padding is proportional to [size]
/// so the code doesn't butt against the edge at any scale.
class QrDisplay extends StatelessWidget {
  /// The exact string to encode. Must not be empty — an empty payload
  /// renders a blank frame, which looks like a bug; assert instead.
  final String data;

  /// Rendered width and height of the QR area, in logical pixels.
  /// The surrounding padding is [size] * [paddingRatio].
  final double size;

  /// Padding around the QR, as a fraction of [size]. 0.12 keeps the
  /// quiet zone (the margin scanners need) without wasting space.
  final double paddingRatio;

  /// Colour of the QR modules. Defaults to the theme's on-surface so
  /// the code is legible on the surface background.
  final Color? moduleColor;

  /// Background behind the QR. Defaults to the surrounding surface, so
  /// the QR blends with its container. Pass `Colors.white` when the
  /// QR is rendered on a coloured background.
  final Color? backgroundColor;

  /// Optional error-correction level. `M` (the library default) is a
  /// good balance for UI display; use `H` if the QR may be partially
  /// obscured (a logo in the centre, a sticker over a corner).
  final int errorCorrectionLevel;

  const QrDisplay({
    super.key,
    required this.data,
    this.size = 160,
    this.paddingRatio = 0.12,
    this.moduleColor,
    this.backgroundColor,
    this.errorCorrectionLevel = QrErrorCorrectLevel.M,
  }) : assert(data != '', 'QrDisplay requires non-empty data');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = moduleColor ?? scheme.onSurface;
    final bg = backgroundColor ?? Colors.transparent;
    final pad = size * paddingRatio;

    return SizedBox(
      width: size + pad * 2,
      height: size + pad * 2,
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: QrImageView(
          data: data,
          version: QrVersions.auto,
          size: size,
          backgroundColor: bg,
          errorCorrectionLevel: errorCorrectionLevel,
          eyeStyle: QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: fg,
          ),
          dataModuleStyle: QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: fg,
          ),
        ),
      ),
    );
  }
}
