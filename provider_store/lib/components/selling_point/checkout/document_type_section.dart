import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:ui/components/document/DocumentTypeManager.dart';

class DocumentTypeSection extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onChanged;

  const DocumentTypeSection({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    // Document type options with icons and localized labels
    final documentTypes = [
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          // Padding(
          //   padding: const EdgeInsets.only(bottom: 12),
          //   child: Row(
          //     children: [
          //       Icon(
          //         Icons.description,
          //         color: theme.colorScheme.primary,
          //         size: 20,
          //       ),
          //       const SizedBox(width: 8),
          //       Text(
          //         loc?.documentType ?? 'Document Type',
          //         style: theme.textTheme.titleMedium?.copyWith(
          //           fontWeight: FontWeight.w600,
          //           color: theme.colorScheme.onSurface,
          //         ),
          //       ),
          //     ],
          //   ),
          // ),

          // Document type chips
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: documentTypes.map((type) {
                    final isSelected = selectedType == type.id;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              type.icon,
                              size: 16,
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              type.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        selected: isSelected,
                        onSelected: (_) => onChanged(type.id),
                        selectedColor: theme.colorScheme.primary,
                        backgroundColor: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceVariant.withOpacity(0.3),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        visualDensity: VisualDensity.compact,
                        elevation: isSelected ? 1 : 0,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // Description based on selected type
          if (selectedType != 'none') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DocumentTypeManager.getDocumentTypeInfo(
                        type: selectedType, theme: theme)
                    .color
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: DocumentTypeManager.getDocumentTypeInfo(
                          type: selectedType, theme: theme)
                      .color
                      .withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    DocumentTypeManager.getDocumentTypeInfo(
                            type: selectedType, theme: theme)
                        .icon,
                    size: 16,
                    color: DocumentTypeManager.getDocumentTypeInfo(
                            type: selectedType, theme: theme)
                        .color,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      DocumentTypeManager.getDocumentTypeInfo(
                              type: selectedType, theme: theme)
                          .description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
