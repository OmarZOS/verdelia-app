import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:verdelia_core/app/VerdeliaImage.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:locator/locator.dart';

class ImagePickerSection extends StatefulWidget {
  final String? initialImageUrl;
  final String entityType;
  final String ownerId;
  final String entityId;
  final bool landscape;
  final File? capturedImageFile;
  final void Function(VerdeliaImage? newImageUrl)? onImageUploaded;

  const ImagePickerSection({
    super.key,
    required this.initialImageUrl,
    required this.entityType,
    required this.ownerId,
    required this.entityId,
    this.onImageUploaded,
    this.landscape = false,
    this.capturedImageFile,
  });

  @override
  State<ImagePickerSection> createState() => _ImagePickerSectionState();
}

class _ImagePickerSectionState extends State<ImagePickerSection> {
  File? _pickedImageFile;
  bool _isHovering = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _pickedImageFile = widget.capturedImageFile;
  }

  @override
  void didUpdateWidget(ImagePickerSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.capturedImageFile != oldWidget.capturedImageFile) {
      _pickedImageFile = widget.capturedImageFile;
    }
  }

  Future<void> _pickImage() async {
    final loc = AppLocalizations.of(context)!;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(loc.gallery),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(loc.camera),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 2400,
        maxHeight: 2400,
      );
      if (picked == null || !mounted) return;

      final image = AppLocator.get<VerdeliaImage>()
        ..setupImage(
          filepath: picked.path,
          filename: picked.name,
          entityType: widget.entityType,
          ownerId: widget.ownerId,
          entityId: widget.entityId,
        );

      setState(() => _pickedImageFile = File(picked.path));
      widget.onImageUploaded?.call(image);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${loc.imagePickFailed}: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _removeImage() {
    HapticFeedback.lightImpact();
    setState(() => _pickedImageFile = null);
    widget.onImageUploaded?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;
    final hasImage = _pickedImageFile != null ||
        (widget.initialImageUrl?.isNotEmpty ?? false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _isHovering = true),
          onExit: (_) => setState(() => _isHovering = false),
          child: Material(
            color: colors.surfaceContainerLow,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: _isHovering ? colors.primary : colors.outlineVariant,
                width: _isHovering ? 1.5 : 1,
              ),
            ),
            child: InkWell(
              onTap: _pickImage,
              child: SizedBox(
                height: widget.landscape ? 210 : 230,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_pickedImageFile != null)
                      Image.file(
                        _pickedImageFile!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholder(theme, loc),
                      )
                    else if (widget.initialImageUrl?.isNotEmpty ?? false)
                      Image.network(
                        widget.initialImageUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          final expected = progress.expectedTotalBytes;
                          return Center(
                            child: CircularProgressIndicator(
                              value: expected == null
                                  ? null
                                  : progress.cumulativeBytesLoaded / expected,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholder(theme, loc),
                      )
                    else
                      _buildPlaceholder(theme, loc),
                    if (_isHovering)
                      ColoredBox(
                        color: Colors.black.withValues(alpha: 0.42),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                hasImage
                                    ? Icons.edit_outlined
                                    : Icons.add_a_photo_outlined,
                                size: 32,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                hasImage ? loc.changeImage : loc.selectImage,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(hasImage ? loc.changeImage : loc.uploadImage),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            if (_pickedImageFile != null) ...[
              const SizedBox(width: 10),
              Tooltip(
                message: loc.removeImage,
                child: IconButton.filledTonal(
                  onPressed: _removeImage,
                  icon: const Icon(Icons.delete_outline),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(50, 50),
                    backgroundColor: colors.errorContainer,
                    foregroundColor: colors.onErrorContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildPlaceholder(ThemeData theme, AppLocalizations loc) {
    final colors = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.surfaceContainerLow, colors.surfaceContainerHighest],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_search_outlined,
            size: 42,
            color: colors.onSurfaceVariant.withValues(alpha: 0.75),
          ),
          const SizedBox(height: 10),
          Text(
            loc.noImageSelected,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
