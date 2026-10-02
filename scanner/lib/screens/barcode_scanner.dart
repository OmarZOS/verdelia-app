import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vibration/vibration.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final Function(String) onBarcodeScanned;
  const BarcodeScannerScreen({super.key, required this.onBarcodeScanned});
  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with TickerProviderStateMixin {
  MobileScannerController cameraController = MobileScannerController();
  late AnimationController _animationController;
  bool _isScanning = true;
  bool _hasFlash = false;
  bool _flashEnabled = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Check flash availability
    // cameraController.hasFlash.then((value) {
    //   setState(() {
    //     _hasFlash = value;
    //   });
    // });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          loc.scanBarcode,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_hasFlash)
            IconButton(
              icon: Icon(
                _flashEnabled ? Icons.flash_on : Icons.flash_off,
                color: colorScheme.onPrimary,
              ),
              onPressed: _toggleFlash,
            ),
        ],
      ),
      body: Stack(
        children: [
          // Camera Scanner
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              if (!_isScanning) return;

              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null &&
                    _isValidBarcode(barcode.rawValue!)) {
                  _onBarcodeDetected(barcode.rawValue!, loc);
                  break;
                }
              }
            },
          ),

          // Scanner overlay with improved design
          CustomPaint(
            painter: ScannerOverlay(colorScheme: colorScheme),
          ),

          // Animated scanning line
          Positioned(
            top: MediaQuery.of(context).size.height / 2 -
                (MediaQuery.of(context).size.width * 0.7) / 2,
            left: MediaQuery.of(context).size.width * 0.15,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Container(
                  width: MediaQuery.of(context).size.width * 0.7,
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        colorScheme.primary.withOpacity(0.8),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  transform: Matrix4.translationValues(
                    0,
                    (_animationController.value) *
                        MediaQuery.of(context).size.width *
                        0.7,
                    0,
                  ),
                );
              },
            ),
          ),

          // Corner indicators
          _buildCornerIndicators(colorScheme.primary),

          // Instructions with improved design
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withOpacity(0.7)
                    : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    CupertinoIcons.barcode_viewfinder,
                    size: 32,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    loc.alignBarcode,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.positionBarcode,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Torch toggle for devices without flash in app bar
          if (!_hasFlash)
            Positioned(
              top: 100,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    _flashEnabled ? Icons.flash_on : Icons.flash_off,
                    color: colorScheme.onPrimary,
                    size: 28,
                  ),
                  onPressed: _toggleFlash,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCornerIndicators(Color color) {
    final size = MediaQuery.of(context).size.width * 0.7;
    final top = MediaQuery.of(context).size.height / 2 - size / 2;
    final left = MediaQuery.of(context).size.width * 0.15;

    return Positioned(
      top: top,
      left: left,
      child: Container(
        width: size,
        height: size,
        child: Stack(
          children: [
            // Top left corner
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                width: 40,
                height: 40,
                child: CustomPaint(
                  painter: CornerPainter(color, CornerPosition.topLeft),
                ),
              ),
            ),
            // Top right corner
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 40,
                height: 40,
                child: CustomPaint(
                  painter: CornerPainter(color, CornerPosition.topRight),
                ),
              ),
            ),
            // Bottom left corner
            Positioned(
              bottom: 0,
              left: 0,
              child: Container(
                width: 40,
                height: 40,
                child: CustomPaint(
                  painter: CornerPainter(color, CornerPosition.bottomLeft),
                ),
              ),
            ),
            // Bottom right corner
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 40,
                height: 40,
                child: CustomPaint(
                  painter: CornerPainter(color, CornerPosition.bottomRight),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleFlash() {
    setState(() {
      _flashEnabled = !_flashEnabled;
    });
    cameraController.toggleTorch();
  }

  Future<void> _onBarcodeDetected(String barcode, AppLocalizations loc) async {
    setState(() {
      _isScanning = false;
    });

    // Vibrate on successful scan
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 200);
    }

    // Show success feedback
    _showSuccessFeedback(loc);

    // Process after a short delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      Navigator.pop(context, barcode);
      _processScannedBarcode(barcode);
    }
  }

  void _showSuccessFeedback(AppLocalizations loc) {
    final colorScheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: colorScheme.onPrimary),
            const SizedBox(width: 12),
            Text(
              loc.barcodeScanSuccess,
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(milliseconds: 1000),
      ),
    );
  }

  bool _isValidBarcode(String barcode) {
    final regex = RegExp(r'^\d{12,13}$');
    return regex.hasMatch(barcode);
  }

  void _processScannedBarcode(String barcode) {
    widget.onBarcodeScanned(barcode);
    // Handle the scanned barcode
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text('Barcode scanned: $barcode'),
    //     backgroundColor: Theme.of(context).colorScheme.primary,
    //     behavior: SnackBarBehavior.floating,
    //     shape: RoundedRectangleBorder(
    //       borderRadius: BorderRadius.circular(12),
    //     ),
    //   ),
    // );
  }

  @override
  void dispose() {
    _animationController.dispose();
    cameraController.dispose();
    super.dispose();
  }
}

// Enhanced Scanner Overlay
class ScannerOverlay extends CustomPainter {
  final ColorScheme colorScheme;

  ScannerOverlay({required this.colorScheme});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final center = Offset(size.width / 2, size.height / 2);
    final scanRect = Rect.fromCenter(
      center: center,
      width: size.width * 0.7,
      height: size.width * 0.7,
    );

    final scanPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(scanRect, const Radius.circular(16)),
      );

    final combinedPath = Path.combine(
      PathOperation.difference,
      path,
      scanPath,
    );

    canvas.drawPath(combinedPath, paint);

    // Draw border with gradient
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..shader = LinearGradient(
        colors: [
          colorScheme.primary,
          colorScheme.primary.withOpacity(0.7),
          colorScheme.primary,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(scanRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(scanRect, const Radius.circular(16)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// Corner Painter for scanner frame
enum CornerPosition { topLeft, topRight, bottomLeft, bottomRight }

class CornerPainter extends CustomPainter {
  final Color color;
  final CornerPosition position;

  CornerPainter(this.color, this.position);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final path = Path();

    switch (position) {
      case CornerPosition.topLeft:
        path
          ..moveTo(0, 20)
          ..lineTo(0, 0)
          ..lineTo(20, 0);
        break;
      case CornerPosition.topRight:
        path
          ..moveTo(size.width - 20, 0)
          ..lineTo(size.width, 0)
          ..lineTo(size.width, 20);
        break;
      case CornerPosition.bottomLeft:
        path
          ..moveTo(0, size.height - 20)
          ..lineTo(0, size.height)
          ..lineTo(20, size.height);
        break;
      case CornerPosition.bottomRight:
        path
          ..moveTo(size.width - 20, size.height)
          ..lineTo(size.width, size.height)
          ..lineTo(size.width, size.height - 20);
        break;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
