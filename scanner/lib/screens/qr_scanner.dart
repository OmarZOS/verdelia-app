import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vibration/vibration.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

class QRScannerScreen extends StatefulWidget {
  final Function(String) onQRcodeScanned;
  const QRScannerScreen({super.key, required this.onQRcodeScanned});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with TickerProviderStateMixin {
  MobileScannerController cameraController = MobileScannerController();
  late AnimationController _animationController;
  bool _isScanning = true;
  bool _hasFlash = false;
  bool _flashEnabled = false;
  bool _hasMultipleCameras = false;
  CameraFacing _cameraFacing = CameraFacing.back;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Check device capabilities
    _checkDeviceCapabilities();
  }

  Future<void> _checkDeviceCapabilities() async {
    // final hasFlash = await cameraController.hasFlash;
    // final hasMultipleCameras = await cameraController.hasMultipleCameras;

    setState(() {
      // _hasFlash = hasFlash;
      // _hasMultipleCameras = hasMultipleCameras;
    });
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
          loc.scanQR,
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
                color:
                    _flashEnabled ? colorScheme.primary : colorScheme.onPrimary,
              ),
              onPressed: _toggleTorch,
            ),
          if (_hasMultipleCameras)
            IconButton(
              icon: Icon(
                _cameraFacing == CameraFacing.back
                    ? Icons.camera_rear
                    : Icons.camera_front,
                color: colorScheme.onPrimary,
              ),
              onPressed: _switchCamera,
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
                if (barcode.rawValue != null) {
                  _onQRCodeDetected(barcode.rawValue!, loc);
                  break;
                }
              }
            },
          ),

          // Scanner overlay with improved design
          CustomPaint(
            painter: QRScannerOverlay(colorScheme: colorScheme),
          ),

          // Animated scanning line
          Positioned(
            top: MediaQuery.of(context).size.height / 2 -
                (MediaQuery.of(context).size.width * 0.6) / 2,
            left: MediaQuery.of(context).size.width * 0.2,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Container(
                  width: MediaQuery.of(context).size.width * 0.6,
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        colorScheme.primary.withOpacity(0.9),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.6),
                        blurRadius: 10,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  transform: Matrix4.translationValues(
                    0,
                    (_animationController.value - 0.5) *
                        MediaQuery.of(context).size.width *
                        0.6,
                    0,
                  ),
                );
              },
            ),
          ),

          // Corner indicators
          _buildCornerIndicators(colorScheme.primary, loc),

          // Instructions with improved design
          Positioned(
            bottom: 120,
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
                    Icons.qr_code_2,
                    size: 36,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    loc.scannerHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.alignQR,
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

          // Bottom action buttons
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Manual input button
                _buildActionButton(
                  icon: Icons.keyboard,
                  label: loc.manualInput,
                  color: colorScheme.secondary,
                  onTap: _showManualInputDialog,
                ),

                // Gallery button
                _buildActionButton(
                  icon: Icons.photo_library,
                  label: loc.gallery,
                  color: colorScheme.tertiary ?? colorScheme.primary,
                  onTap: _pickImageFromGallery,
                ),
              ],
            ),
          ),

          // Floating torch button for easy access
          if (_hasFlash)
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
                    color: _flashEnabled
                        ? colorScheme.primary
                        : colorScheme.onPrimary,
                    size: 28,
                  ),
                  onPressed: _toggleTorch,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: IconButton(
            icon: Icon(icon, color: color),
            onPressed: onTap,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            shadows: [
              Shadow(
                blurRadius: 4,
                color: Colors.black.withOpacity(0.8),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCornerIndicators(Color color, AppLocalizations loc) {
    final size = MediaQuery.of(context).size.width * 0.6;
    final top = MediaQuery.of(context).size.height * 0.35 - size / 2;
    final left = MediaQuery.of(context).size.width * 0.2;

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

  void _toggleTorch() {
    setState(() {
      _flashEnabled = !_flashEnabled;
    });
    cameraController.toggleTorch();
  }

  void _switchCamera() {
    setState(() {
      _cameraFacing = _cameraFacing == CameraFacing.back
          ? CameraFacing.front
          : CameraFacing.back;
    });
    cameraController.switchCamera();
  }

  Future<void> _onQRCodeDetected(String code, AppLocalizations loc) async {
    setState(() {
      _isScanning = false;
    });

    // Vibrate on successful scan
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 200);
    }

    // Show success feedback
    _showSuccessFeedback(loc);

    // Process after a short delay to show feedback
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      Navigator.pop(context, code);
      _processScannedCode(code);
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
            Expanded(
              child: Text(
                loc.qrSuccess,
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  void _showManualInputDialog() {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.manualQR),
        content: TextField(
          decoration: InputDecoration(
            hintText: loc.manualQRHint,
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancelTxt),
          ),
          ElevatedButton(
            onPressed: () {
              // Handle manual input
              Navigator.pop(context);
            },
            child: Text(loc.submitText),
          ),
        ],
      ),
    );
  }

  void _pickImageFromGallery() {
    // Implement image picker for QR code scanning from gallery
    // You can use image_picker package for this
  }

  void _processScannedCode(String code) {
    widget.onQRcodeScanned(code);
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text('QR Code detected: $code'),
    //     backgroundColor: Theme.of(context).colorScheme.primary,
    //     behavior: SnackBarBehavior.floating,
    //     shape: RoundedRectangleBorder(
    //       borderRadius: BorderRadius.circular(12),
    //     ),
    //   ),
    // );
    // Handle the scanned QR code
  }

  @override
  void dispose() {
    _animationController.dispose();
    cameraController.dispose();
    super.dispose();
  }
}

// QR Scanner Specific Overlay
class QRScannerOverlay extends CustomPainter {
  final ColorScheme colorScheme;

  QRScannerOverlay({required this.colorScheme});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final center = Offset(size.width / 2, size.height / 2);
    final scanRect = Rect.fromCenter(
      center: center,
      width: size.width * 0.6,
      height: size.width * 0.6,
    );

    final scanPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(scanRect, const Radius.circular(12)),
      );

    final combinedPath = Path.combine(
      PathOperation.difference,
      path,
      scanPath,
    );

    canvas.drawPath(combinedPath, paint);

    // Draw border with gradient for QR code
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..shader = LinearGradient(
        colors: [
          colorScheme.primary,
          colorScheme.primary.withOpacity(0.8),
          colorScheme.primary,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(scanRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(scanRect, const Radius.circular(12)),
      borderPaint,
    );

    // Draw QR code corner markers
    _drawQRCornerMarkers(canvas, scanRect, colorScheme.primary);
  }

  void _drawQRCornerMarkers(Canvas canvas, Rect rect, Color color) {
    final markerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final markerSize = 20.0;

    // Top left marker
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.top + markerSize)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.left + markerSize, rect.top),
      markerPaint,
    );

    // Top right marker
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - markerSize, rect.top)
        ..lineTo(rect.right, rect.top)
        ..lineTo(rect.right, rect.top + markerSize),
      markerPaint,
    );

    // Bottom left marker
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.bottom - markerSize)
        ..lineTo(rect.left, rect.bottom)
        ..lineTo(rect.left + markerSize, rect.bottom),
      markerPaint,
    );

    // Bottom right marker
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - markerSize, rect.bottom)
        ..lineTo(rect.right, rect.bottom)
        ..lineTo(rect.right, rect.bottom - markerSize),
      markerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// Reuse the same CornerPainter enum and class from previous implementation
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
