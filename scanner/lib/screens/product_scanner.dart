import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;

class ProductCaptureScreen extends StatefulWidget {
  const ProductCaptureScreen({super.key});

  @override
  State<ProductCaptureScreen> createState() => _ProductCaptureScreenState();
}

class _ProductCaptureScreenState extends State<ProductCaptureScreen>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isTakingPicture = false;
  XFile? _capturedImage;
  File? _croppedImage;
  bool _isFlashOn = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final GlobalKey _cameraPreviewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initializePulseAnimation();
    _initializeCamera();
  }

  void _initializePulseAnimation() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      await _cameraController!.setFlashMode(FlashMode.off);

      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to initialize camera');
      }
    }
  }

  Future<void> _takePicture() async {
    if (_isTakingPicture ||
        !_isCameraInitialized ||
        _cameraController == null) {
      return;
    }

    setState(() => _isTakingPicture = true);
    HapticFeedback.mediumImpact();

    try {
      final XFile picture = await _cameraController!.takePicture();

      // Crop the image to the scan box area
      final croppedFile = await _cropImageToScanBox(picture);

      HapticFeedback.lightImpact();

      if (mounted) {
        setState(() {
          _capturedImage = picture;
          _croppedImage = croppedFile;
          _isTakingPicture = false;
        });
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
      if (mounted) {
        setState(() => _isTakingPicture = false);
        _showErrorSnackBar('Failed to capture image');
      }
    }
  }

  /// Crops the captured image to match the scan box area
  Future<File?> _cropImageToScanBox(XFile imageFile) async {
    try {
      // Get the camera preview box dimensions
      final RenderBox? previewBox =
          _cameraPreviewKey.currentContext?.findRenderObject() as RenderBox?;
      if (previewBox == null) {
        debugPrint('Preview box not found');
        return null;
      }

      final previewSize = previewBox.size;
      final screenWidth = MediaQuery.of(context).size.width;

      // Calculate scan box dimensions (matching the overlay)
      final scanBoxWidth = screenWidth *
          0.75; // Same as in _buildScannerOverlay (screenWidth - 64)
      final scanBoxSize = scanBoxWidth; // Square aspect ratio

      // Calculate scan box position relative to preview
      // The scan box is centered horizontally
      final horizontalMargin = (screenWidth - scanBoxWidth) / 2;

      // Calculate vertical position
      // Based on Column layout: Spacer -> ScanBox -> Instructions -> Spacer(flex: 2)
      // Total flex = 3, scan box is after 1 flex unit
      final totalHeight = previewSize.height;
      final instructionsHeight = 120.0; // Approximate height of instructions
      final spacerHeight = (totalHeight - scanBoxSize - instructionsHeight) / 3;
      final verticalOffset = spacerHeight;

      // Read the original image
      final bytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(bytes);

      if (originalImage == null) {
        debugPrint('Failed to decode image');
        return null;
      }

      // Calculate scale factors between preview and actual image
      final scaleX = originalImage.width / previewSize.width;
      final scaleY = originalImage.height / previewSize.height;

      // Calculate crop area in image coordinates
      final cropX = (horizontalMargin * scaleX).round();
      final cropY = (verticalOffset * scaleY).round();
      final cropWidth = (scanBoxSize * scaleX).round();
      final cropHeight = (scanBoxSize * scaleY).round();

      // Ensure crop area is within image bounds
      final safeCropX = cropX.clamp(0, originalImage.width - 1);
      final safeCropY = cropY.clamp(0, originalImage.height - 1);
      final safeCropWidth = cropWidth.clamp(1, originalImage.width - safeCropX);
      final safeCropHeight =
          cropHeight.clamp(1, originalImage.height - safeCropY);

      // Crop the image
      final croppedImage = img.copyCrop(
        originalImage,
        safeCropX,
        safeCropY,
        safeCropWidth,
        safeCropHeight,
      );

      // Save the cropped image
      final croppedPath = imageFile.path.replaceAll('.jpg', '_cropped.jpg');
      final croppedFile = File(croppedPath);
      await croppedFile.writeAsBytes(img.encodeJpg(croppedImage, quality: 95));

      return croppedFile;
    } catch (e) {
      debugPrint('Error cropping image: $e');
      return null;
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_isCameraInitialized) return;

    try {
      setState(() => _isFlashOn = !_isFlashOn);
      await _cameraController!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
      HapticFeedback.selectionClick();
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  void _retakePicture() {
    HapticFeedback.selectionClick();
    setState(() {
      _capturedImage = null;
      _croppedImage = null;
    });
  }

  void _useImage() {
    // Return the cropped image if available, otherwise return the original
    final imageToReturn = _croppedImage ??
        (_capturedImage != null ? File(_capturedImage!.path) : null);

    if (imageToReturn != null) {
      HapticFeedback.mediumImpact();
      Navigator.pop(context, imageToReturn);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final safeAreaPadding = MediaQuery.of(context).padding;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: _capturedImage == null
            ? _buildCameraMode(colorScheme, safeAreaPadding, loc)
            : _buildPreviewMode(colorScheme, safeAreaPadding, loc),
      ),
    );
  }

  Widget _buildCameraMode(ColorScheme colorScheme, EdgeInsets safeAreaPadding,
      AppLocalizations loc) {
    return Stack(
      children: [
        // Camera Preview
        if (_isCameraInitialized && _cameraController != null)
          Positioned.fill(
            child: RepaintBoundary(
              key: _cameraPreviewKey,
              child: CameraPreview(_cameraController!),
            ),
          )
        else
          _buildLoadingCamera(colorScheme, loc),

        // Scanner Overlay & Guides
        if (_isCameraInitialized) _buildScannerOverlay(colorScheme, loc),

        // Top Bar with Controls
        _buildTopBar(colorScheme, safeAreaPadding, loc),

        // Bottom Capture Button
        _buildCameraControls(colorScheme, safeAreaPadding, loc),

        // Processing Overlay
        if (_isTakingPicture) _buildProcessingOverlay(colorScheme, loc),
      ],
    );
  }

  Widget _buildLoadingCamera(ColorScheme colorScheme, AppLocalizations loc) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              loc.initCam,
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(ColorScheme colorScheme, EdgeInsets safeAreaPadding,
      AppLocalizations loc) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: safeAreaPadding.top + 8,
          bottom: 20,
          left: 16,
          right: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.black.withOpacity(0.4),
              Colors.transparent,
            ],
            stops: const [0.0, 0.7, 1.0],
          ),
        ),
        child: Row(
          children: [
            _buildCircleButton(
              icon: Icons.close,
              onPressed: () => Navigator.pop(context),
              colorScheme: colorScheme,
            ),
            const SizedBox(width: 16),
            Text(
              loc.captureProduct,
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (_isCameraInitialized)
              _buildCircleButton(
                icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                onPressed: _toggleFlash,
                colorScheme: colorScheme,
                isActive: _isFlashOn,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onPressed,
    required ColorScheme colorScheme,
    bool isActive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isActive
            ? colorScheme.primary.withOpacity(0.3)
            : Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
        border:
            isActive ? Border.all(color: colorScheme.primary, width: 2) : null,
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: isActive ? colorScheme.primary : colorScheme.onPrimary,
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildScannerOverlay(ColorScheme colorScheme, AppLocalizations loc) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Column(
          children: [
            const Spacer(),
            // Scanner Frame
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      children: [
                        // Animated border
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: colorScheme.primary.withOpacity(
                                    0.6 + (_pulseAnimation.value - 1) * 0.4,
                                  ),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(24),
                              ),
                            );
                          },
                        ),
                        // Corner indicators
                        _buildCornerIndicators(colorScheme.primary),
                        // Center crosshair
                        Center(
                          child: Icon(
                            Icons.center_focus_strong,
                            size: 48,
                            color: colorScheme.primary.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Instructions card
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.photo_camera_outlined,
                          color: colorScheme.primary,
                          size: 32,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          loc.positionProductInFrame,
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          loc.scanHint,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colorScheme.onPrimary.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerIndicators(Color color) {
    const cornerLength = 32.0;
    const cornerThickness = 4.0;

    return Stack(
      children: [
        // Top left
        Positioned(
          top: 0,
          left: 0,
          child: CustomPaint(
            size: const Size(cornerLength, cornerLength),
            painter: _CornerPainter(
              color: color,
              position: _CornerPosition.topLeft,
              thickness: cornerThickness,
            ),
          ),
        ),
        // Top right
        Positioned(
          top: 0,
          right: 0,
          child: CustomPaint(
            size: const Size(cornerLength, cornerLength),
            painter: _CornerPainter(
              color: color,
              position: _CornerPosition.topRight,
              thickness: cornerThickness,
            ),
          ),
        ),
        // Bottom left
        Positioned(
          bottom: 0,
          left: 0,
          child: CustomPaint(
            size: const Size(cornerLength, cornerLength),
            painter: _CornerPainter(
              color: color,
              position: _CornerPosition.bottomLeft,
              thickness: cornerThickness,
            ),
          ),
        ),
        // Bottom right
        Positioned(
          bottom: 0,
          right: 0,
          child: CustomPaint(
            size: const Size(cornerLength, cornerLength),
            painter: _CornerPainter(
              color: color,
              position: _CornerPosition.bottomRight,
              thickness: cornerThickness,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraControls(ColorScheme colorScheme,
      EdgeInsets safeAreaPadding, AppLocalizations loc) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          bottom: safeAreaPadding.bottom + 24,
          top: 32,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.black.withOpacity(0.4),
              Colors.transparent,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Capture Button
            GestureDetector(
              onTap: _takePicture,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.primary,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary,
                  ),
                  child: _isTakingPicture
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.camera_alt,
                          size: 36,
                          color: colorScheme.onPrimary,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              loc.tapHint,
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewMode(ColorScheme colorScheme, EdgeInsets safeAreaPadding,
      AppLocalizations loc) {
    // Show cropped image if available, otherwise show original
    final imageToShow = _croppedImage ??
        (_capturedImage != null ? File(_capturedImage!.path) : null);

    if (imageToShow == null) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // Image Preview
        Positioned.fill(
          child: Container(
            color: Colors.black,
            child: Center(
              child: Hero(
                tag: 'captured_image',
                child: Image.file(
                  imageToShow,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),

        // Top Bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.only(
              top: safeAreaPadding.top + 8,
              bottom: 20,
              left: 16,
              right: 16,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              children: [
                _buildCircleButton(
                  icon: Icons.close,
                  onPressed: () => Navigator.pop(context),
                  colorScheme: colorScheme,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.reviewPhoto,
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_croppedImage != null)
                      Text(
                        loc.croppedToFrame,
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Bottom Actions
        _buildPreviewActions(colorScheme, safeAreaPadding, loc),
      ],
    );
  }

  Widget _buildPreviewActions(ColorScheme colorScheme,
      EdgeInsets safeAreaPadding, AppLocalizations loc) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          bottom: safeAreaPadding.bottom + 24,
          top: 24,
          left: 24,
          right: 24,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.9),
              Colors.black.withOpacity(0.6),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Use Photo Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _useImage,
                icon: const Icon(Icons.check_circle_outline, size: 24),
                label: Text(
                  loc.usePhoto,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Retake Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: _retakePicture,
                icon: const Icon(Icons.refresh, size: 24),
                label: Text(
                  loc.takeAgain,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.onPrimary,
                  side: BorderSide(
                    color: colorScheme.onPrimary.withOpacity(0.4),
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay(
      ColorScheme colorScheme, AppLocalizations loc) {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: colorScheme.surface.withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  strokeWidth: 4,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                loc.processingImage,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }
}

// Corner Painter
enum _CornerPosition { topLeft, topRight, bottomLeft, bottomRight }

class _CornerPainter extends CustomPainter {
  final Color color;
  final _CornerPosition position;
  final double thickness;

  _CornerPainter({
    required this.color,
    required this.position,
    required this.thickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness + 2
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final path = Path();
    final length = size.width * 0.7;

    switch (position) {
      case _CornerPosition.topLeft:
        path
          ..moveTo(0, length)
          ..lineTo(0, 0)
          ..lineTo(length, 0);
        break;
      case _CornerPosition.topRight:
        path
          ..moveTo(size.width - length, 0)
          ..lineTo(size.width, 0)
          ..lineTo(size.width, length);
        break;
      case _CornerPosition.bottomLeft:
        path
          ..moveTo(0, size.height - length)
          ..lineTo(0, size.height)
          ..lineTo(length, size.height);
        break;
      case _CornerPosition.bottomRight:
        path
          ..moveTo(size.width - length, size.height)
          ..lineTo(size.width, size.height)
          ..lineTo(size.width, size.height - length);
        break;
    }

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
