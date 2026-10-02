import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

// Supporting data classes
class DocumentTypeOption {
  final String id;
  final IconData icon;
  final String label;

  const DocumentTypeOption({
    required this.id,
    required this.icon,
    required this.label,
  });
}

class DocumentTypeInfo {
  final IconData icon;
  final Color color;
  final String description;

  const DocumentTypeInfo({
    required this.icon,
    required this.color,
    required this.description,
  });
}

class DocumentTypeManager {
  // Private constructor to prevent instantiation
  DocumentTypeManager._();

  // Get document type options with localized labels
  static List<DocumentTypeOption> getDocumentTypeOptions(
    BuildContext context,
  ) {
    final loc = AppLocalizations.of(context);

    return [
      DocumentTypeOption(
        id: 'invoice',
        icon: Icons.receipt_long,
        label: loc?.invoice ?? 'Invoice',
      ),
      DocumentTypeOption(
        id: 'invoice_receipt',
        icon: Icons.receipt,
        label: loc?.invoiceReceipt ?? 'Invoice + Receipt',
      ),
      DocumentTypeOption(
        id: 'receipt',
        icon: Icons.description,
        label: loc?.receiptOnly ?? 'Receipt Only',
      ),
      DocumentTypeOption(
        id: 'none',
        icon: Icons.block,
        label: loc?.none ?? 'None',
      ),
    ];
  }

  // Get document type information
  static DocumentTypeInfo getDocumentTypeInfo({
    required String type,
    ThemeData? theme,
  }) {
    switch (type) {
      case 'invoice':
        return DocumentTypeInfo(
          icon: Icons.receipt_long,
          color: Colors.blue,
          description: 'Creates an invoice document with VAT applied',
        );
      case 'invoice_receipt':
        return DocumentTypeInfo(
          icon: Icons.receipt,
          color: Colors.green,
          description: 'Creates both invoice and receipt documents',
        );
      case 'receipt':
        return DocumentTypeInfo(
          icon: Icons.description,
          color: Colors.purple,
          description: 'Creates a receipt only, no VAT applied',
        );
      case 'none':
        return DocumentTypeInfo(
          icon: Icons.block,
          color: Colors.grey,
          description: 'No document will be created',
        );
      default:
        return DocumentTypeInfo(
          icon: Icons.help_outline,
          color: theme?.colorScheme.secondary ?? Colors.grey,
          description: 'Unknown document type',
        );
    }
  }

  // Get document type by ID
  static DocumentTypeOption? getDocumentTypeById(
    BuildContext context,
    String id,
  ) {
    final options = getDocumentTypeOptions(context);
    return options.firstWhere((option) => option.id == id);
  }

  // Get default document type (useful for initial state)
  static String getDefaultDocumentType() {
    return 'invoice';
  }

  // Check if a document type is valid
  static bool isValidDocumentType(String type) {
    return ['invoice', 'invoice_receipt', 'receipt', 'none'].contains(type);
  }

  // Get all document type IDs
  static List<String> getAllDocumentTypeIds() {
    return ['invoice', 'invoice_receipt', 'receipt', 'none'];
  }
}
