import 'dart:io';

import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:app_constants/app_constants.dart';
import 'package:verdelia_core/app/VerdeliaImage.dart';
import 'package:event/user_change_notifier.dart';
import 'package:ui/components/ImagePickerSection.dart';
import 'package:provider/provider.dart';

class UploadImagePage extends StatefulWidget {
  const UploadImagePage({super.key});

  @override
  State<UploadImagePage> createState() => _UploadImagePageState();
}

class _UploadImagePageState extends State<UploadImagePage> {
  VerdeliaImage? _selectedImage;
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userNotifier = Provider.of<AppUserNotifier>(context, listen: false);
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String entity = args['entity'];
    final String entityId = args['id'].toString();

    return Scaffold(
      appBar: AppBar(
        title: Text('Add ${_capitalizeFirstLetter(entity)} Image'),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_selectedImage != null)
            IconButton(
              icon: _isUploading
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : const Icon(Icons.check),
              onPressed: _isUploading ? null : _handleUpload,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Image Preview Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    ImagePickerSection(
                      initialImageUrl: null,
                      entityType: entity,
                      onImageUploaded: (image) {
                        setState(() {
                          _selectedImage = image;
                        });
                      },
                      landscape: (entity == "recipe"),
                      ownerId: userNotifier.appUser!.idAppUser.toString(),
                      entityId: entityId,
                    ),
                    if (_isUploading) ...[
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        backgroundColor: theme.colorScheme.surfaceVariant,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // const SizedBox(height: 24),

            // Image Picker Section
            // Upload Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload),
                label: Text(_isUploading
                    ? AppLocalizations.of(context)!.uploadingImage
                    : AppLocalizations.of(context)!.uploadImage),
                onPressed: _selectedImage != null && !_isUploading
                    ? _handleUpload
                    : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                icon: const Icon(Icons.schedule_outlined, size: 20),
                label: Text(
                  AppLocalizations.of(context)!.laterText,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                onPressed: () {
                  // Handle later action
                  Navigator.pop(context, "");
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  foregroundColor:
                      Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUpload() async {
    if (_selectedImage == null) return;

    setState(() => _isUploading = true);

    try {
      final url = await _selectedImage?.uploadImage();

      // await Future.delayed(const Duration(seconds: 2)); // Simulate upload

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Image uploaded successfully!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      Navigator.pop(
          context,
          ((url != null)
              ? (AppConstants.fsBaseUrl + url)
              : "")); // Return success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  String _capitalizeFirstLetter(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
  }
}
