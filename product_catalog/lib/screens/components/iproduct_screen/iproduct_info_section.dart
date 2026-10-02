import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/business/iProduct.dart';

import 'gluten_free_badge.dart';
import 'info_card.dart';

class IProductInfoSection extends StatelessWidget {
  final IProduct iproduct;

  const IProductInfoSection({super.key, required this.iproduct});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProductHeader(context, theme, localizations),
        const SizedBox(height: 28),
        _buildInfoCards(context, theme),
        const SizedBox(height: 32),
        _buildDetailedInfo(context, theme),
      ],
    );
  }

  Widget _buildProductHeader(
      BuildContext context, ThemeData theme, AppLocalizations localizations) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                iproduct.iproductName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              if (iproduct.iproductBrand.isNotEmpty)
                Text(
                  iproduct.iproductBrand,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 16),
              _buildBarcodeSection(context, theme),
            ],
          ),
        ),
        const SizedBox(width: 16),
        GlutenFreeBadge(
            isGlutenFree: iproduct.iproductGlutenStatus == 'gluten_free'),
      ],
    );
  }

  Widget _buildBarcodeSection(BuildContext context, ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.qr_code_scanner_rounded,
              size: 20, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.barcodeText,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  iproduct.iproductBarcode,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'Monospace',
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon:
                Icon(Icons.copy_rounded, size: 20, color: colorScheme.primary),
            onPressed: () => _copyBarcode(context, iproduct.iproductBarcode),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards(BuildContext context, ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        InfoCard(
          icon: Icons.price_change_rounded,
          title: AppLocalizations.of(context)!.priceText,
          value: iproduct.formattedPrice,
          color: colorScheme.primary,
          isRecent: iproduct.isPriceRecent,
        ),
        InfoCard(
          icon: _getSourceIcon(iproduct.iproductInfoSource),
          title: AppLocalizations.of(context)!.sourceText,
          value: _getSourceText(iproduct.iproductInfoSource),
          color: colorScheme.secondary,
        ),
        InfoCard(
          icon: Icons.model_training_rounded,
          title: AppLocalizations.of(context)!.modelText,
          value: iproduct.iproductModelName,
          color: colorScheme.tertiary,
        ),
      ],
    );
  }

  Widget _buildDetailedInfo(BuildContext context, ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.productDetailsText,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          _buildDetailRow(
            context,
            icon: Icons.calendar_month_rounded,
            label: AppLocalizations.of(context)!.createdText,
            value: _formatDate(iproduct.iproductCreatedAt),
          ),
          _buildDetailRow(
            context,
            icon: Icons.update_rounded,
            label: AppLocalizations.of(context)!.lastUpdatedText,
            value: _formatDate(iproduct.iproductUpdatedAt),
          ),
          if (iproduct.iproductLastPriceUpdate != null)
            _buildDetailRow(
              context,
              icon: Icons.price_check_rounded,
              label: AppLocalizations.of(context)!.priceUpdatedText,
              value: _formatDate(iproduct.iproductLastPriceUpdate!),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon,
              size: 20, color: colorScheme.onSurfaceVariant.withOpacity(0.6)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _copyBarcode(BuildContext context, String barcode) {
    // Clipboard.setData(ClipboardData(text: barcode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.copiedToClipboardText),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  IconData _getSourceIcon(String source) {
    if (source.contains('ai') || source.contains('generated'))
      return Icons.psychology_rounded;
    if (source.contains('manual') || source.contains('user'))
      return Icons.person_rounded;
    if (source.contains('scan')) return Icons.qr_code_scanner_rounded;
    return Icons.source_rounded;
  }

  String _getSourceText(String source) {
    if (source.contains('ai_generated')) return 'AI Generated';
    if (source.contains('manual')) return 'Manual Entry';
    if (source.contains('scan')) return 'Scanned';
    return source.replaceAll('_', ' ');
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
