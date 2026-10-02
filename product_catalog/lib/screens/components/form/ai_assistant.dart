import 'dart:io';

import 'package:app_constants/app_routes.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:app_constants/app_constants.dart';
import 'package:verdelia_core/app/VerdeliaImage.dart';
import 'package:verdelia_core/business/iProduct.dart';
import 'package:verdelia_core/business/product_form_data.dart';
import 'package:event/assistant_change_notifier.dart';
import 'package:event/components/lib.dart';
import 'package:locator/locator.dart';
import 'package:product_catalog/screens/components/form/form_controllers.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;

class AiAssistant {
  static Future<void> showOptions(BuildContext context,
      ProductFormData formData, FormControllers controllers) async {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final option = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome,
                        color: colorScheme.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations.aiAssistantTitle,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                          ),
                          Text(
                            localizations.aiAssistantSubtitle,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Options
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildAiOption(
                      context,
                      icon: CupertinoIcons.barcode_viewfinder,
                      title: localizations.scanBarcode,
                      subtitle:
                          localizations.automaticallyFillDetailsFromBarcode,
                      color: colorScheme.primary,
                      onTap: () => Navigator.pop(context, 1),
                    ),
                    const SizedBox(height: 12),
                    _buildAiOption(
                      context,
                      icon: Icons.camera_alt,
                      title: localizations.takeProductPhoto,
                      subtitle: localizations.aiWillAnalyseImage,
                      color: colorScheme.secondary,
                      onTap: () => Navigator.pop(context, 3),
                    ),
                  ],
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: colorScheme.outline.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(localizations.cancelTxt),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (option != null) {
      await _handleOption(context, option, formData, controllers);
    }
  }

  static Widget _buildAiOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        trailing: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_forward, color: color, size: 16),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  static Future<void> _handleOption(
    BuildContext context,
    int option,
    ProductFormData formData,
    FormControllers controllers,
  ) async {
    final assistantNotifier = context.read<AssistantNotifier>();

    try {
      if (option == 1) {
        // Handle barcode scanning
        await _handleBarcodeScanning(
            context, formData, controllers, assistantNotifier);
      } else if (option == 3) {
        // Handle product photo capture
        await _handleProductPhotoCapture(
            context, formData, controllers, assistantNotifier);
      }
    } catch (e) {
      _showErrorSnackBar(context, 'AI assistance failed: ${e.toString()}');
    }
  }

  static Future<void> _handleBarcodeScanning(
    BuildContext context,
    ProductFormData formData,
    FormControllers controllers,
    AssistantNotifier assistantNotifier,
  ) async {
    final String? scannedCode = await Navigator.pushNamed(
      context,
      AppRoutes.productScanPage,
    ) as String?;

    if (scannedCode != null && scannedCode.isNotEmpty) {
      // Update barcode field immediately with user input source
      assistantNotifier.setFieldData(
        fieldId: ProductAssistedFields.IPRODUCT_BARCODE,
        value: scannedCode,
        source: DataSource.userInput,
      );

      // Update form data and controller
      formData.productBarcode = scannedCode;
      controllers.barcode.text = scannedCode;

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text('Looking up product...'),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 5),
        ),
      );

      // Fetch product data from barcode
      await assistantNotifier.fetchProductByBarcode(scannedCode);

      // Remove loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Auto-sync form with the fetched data
      _syncFormWithAssistantData(
          context, formData, controllers, assistantNotifier);
    }
  }

  static Future<void> _handleProductPhotoCapture(
    BuildContext context,
    ProductFormData formData,
    FormControllers controllers,
    AssistantNotifier assistantNotifier,
  ) async {
    final File? capturedImage = await Navigator.pushNamed(
      context,
      AppRoutes.productCapturePage,
    ) as File?;

    if (capturedImage != null) {
      // Handle image setup
      final verdeliaImage = AppLocator.get<VerdeliaImage>();
      verdeliaImage.setupImage(
        filepath: capturedImage.path,
        filename: path.basename(capturedImage.path),
        entityType: "product",
        ownerId: "${formData.ownerId}",
        entityId: '${formData.productId}',
      );

      // Update form data
      formData.imageFile = capturedImage;
      formData.image = verdeliaImage;

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text('Analyzing product image...'),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 10),
        ),
      );

      // Start AI recognition
      await assistantNotifier.recognizeProductFromImage(capturedImage);

      // Remove loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Auto-sync form with the recognized data
      _syncFormWithAssistantData(
          context, formData, controllers, assistantNotifier);

      // Show success message with confidence score
      final confidence = assistantNotifier.getProductConfidenceScore();
      if (confidence > 0) {
        _showSuccessSnackBar(
          context,
          'Product recognized with ${(confidence * 100).toStringAsFixed(0)}% confidence',
        );
      }
    }
  }

  static void _syncFormWithAssistantData(
    BuildContext context,
    ProductFormData formData,
    FormControllers controllers,
    AssistantNotifier assistantNotifier,
  ) {
    final IProduct? currentProduct = assistantNotifier.product;

    if (currentProduct == null || !context.mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      formData.assistantOrigin = currentProduct;

      // Get all field data from assistant
      final nameField =
          assistantNotifier.getFieldData(ProductAssistedFields.IPRODUCT_NAME);
      final brandField =
          assistantNotifier.getFieldData(ProductAssistedFields.IPRODUCT_BRAND);
      final barcodeField = assistantNotifier
          .getFieldData(ProductAssistedFields.IPRODUCT_BARCODE);
      final priceField = assistantNotifier
          .getFieldData(ProductAssistedFields.IPRODUCT_ESTIMATED_PRICE_DA);
      final quantityField =
          assistantNotifier.getFieldData(ProductAssistedFields.QUANTITY);
      final quantifierField =
          assistantNotifier.getFieldData(ProductAssistedFields.QUANTIFIER);
      final descriptionField =
          assistantNotifier.getFieldData(ProductAssistedFields.DESCRIPTION);

      // Update form data and controllers for non-edited fields
      if (nameField != null && !nameField.isEdited) {
        final name = nameField.value?.toString() ?? '';
        controllers.name.text = name;
        formData.productName = name;
      }

      if (brandField != null && !brandField.isEdited) {
        final brand = brandField.value?.toString() ?? '';
        controllers.brand.text = brand;
        formData.productBrand = brand;
      }

      if (barcodeField != null && !barcodeField.isEdited) {
        final barcode = barcodeField.value?.toString() ?? '';
        controllers.barcode.text = barcode;
        formData.productBarcode = barcode;
      }

      if (priceField != null && !priceField.isEdited) {
        final price = priceField.value?.toString() ?? '0.0';
        controllers.price.text = price;
        formData.price = double.tryParse(price);
      }

      if (quantityField != null && !quantityField.isEdited) {
        final quantity = quantityField.value?.toString() ?? '1';
        controllers.quantity.text = quantity;
        formData.quantity = int.tryParse(quantity);
      }

      if (quantifierField != null && !quantifierField.isEdited) {
        final quantifier = quantifierField.value?.toString() ?? 'pc';
        if (AppConstants.productUnits.contains(quantifier)) {
          formData.quantifier = quantifier;
        }
      }

      if (descriptionField != null && !descriptionField.isEdited) {
        final description = descriptionField.value?.toString() ?? '';
        controllers.description.text = description;
        formData.productDescription = description;
      }

      // Show confidence score in debug
      final confidence = assistantNotifier.getProductConfidenceScore();
      if (confidence > 0) {
        debugPrint(
            "🎯 AI Assistant - Overall confidence: ${(confidence * 100).toStringAsFixed(0)}%");
      }
    });
  }

  static void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle,
                color: Theme.of(context).colorScheme.onPrimary),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline,
                color: Theme.of(context).colorScheme.onError),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
