// lib/screens/product_details/editor_widgets.dart

import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:event/product_change_notifier.dart';
import 'package:provider/provider.dart';
import 'package:ui/utils/category_hierarchy.dart';
import 'package:ui/components/image/image_url.dart';
import 'package:ui/components/product/quantifier_label.dart';

String _productCategoryHierarchy(
  Product product,
  List<ProductCategory> categories,
  String languageCode,
  AppLocalizations localizations,
) {
  for (final category in categories) {
    if (category.productCategoryId == product.product_category_id) {
      return localizedCategoryHierarchy(
        categoryPath: category.productCategoryDesc,
        localizedLeaf: category.nameFor(languageCode),
        localizations: localizations,
      );
    }
  }
  return localizedCategoryHierarchy(
    categoryPath: product.product_category_name ?? '',
    localizedLeaf: '',
    localizations: localizations,
  );
}

// ==================================================================
// Fallback network image
// ==================================================================

/// Renders the first candidate URL that actually loads.
///
/// Walks [candidates] in order. When the current URL fails to load
/// (network error, 404, malformed data), it advances to the next one.
/// Renders [placeholderBuilder] only when every candidate has failed.
///
/// URLs are resolved and de-duplicated once on init, so a repeated
/// source (e.g. the seller attached the origin image) is never fetched
/// twice.
class FallbackNetworkImage extends StatefulWidget {
  final List<String?> candidates;
  final BoxFit fit;
  final WidgetBuilder placeholderBuilder;

  const FallbackNetworkImage({
    super.key,
    required this.candidates,
    this.fit = BoxFit.cover,
    required this.placeholderBuilder,
  });

  @override
  State<FallbackNetworkImage> createState() => _FallbackNetworkImageState();
}

class _FallbackNetworkImageState extends State<FallbackNetworkImage> {
  late List<String> _urls;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _urls = _resolveUrls();
  }

  @override
  void didUpdateWidget(covariant FallbackNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Restart the walk when the candidate list changes (e.g. the
    // product was edited and now points at a different image).
    if (!_sameCandidates(oldWidget.candidates, widget.candidates)) {
      _urls = _resolveUrls();
      _index = 0;
    }
  }

  List<String> _resolveUrls() {
    final seen = <String>{};
    final out = <String>[];
    for (final candidate in widget.candidates) {
      final resolved = resolveImageUrl(candidate);
      if (resolved != null && resolved.isNotEmpty && seen.add(resolved)) {
        out.add(resolved);
      }
    }
    return out;
  }

  bool _sameCandidates(List<String?> a, List<String?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _advance() {
    if (_index + 1 >= _urls.length) return;
    setState(() => _index++);
  }

  @override
  Widget build(BuildContext context) {
    if (_urls.isEmpty || _index >= _urls.length) {
      return widget.placeholderBuilder(context);
    }

    return Image.network(
      _urls[_index],
      key: ValueKey(_urls[_index]),
      fit: widget.fit,
      errorBuilder: (_, __, ___) {
        // Defer the advance so we never call setState while the error
        // callback is still inside the build phase.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _advance();
        });
        return widget.placeholderBuilder(context);
      },
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

// ==================================================================
// Hero strip
// ==================================================================

class EditorHero extends StatelessWidget {
  final Product product;
  final bool isRTL;

  /// Pre-resolved display name. When provided and non-empty, the hero
  /// uses it directly instead of reading `product.product_name`.
  ///
  /// This lets the caller decide whether the linked IProduct's name or
  /// the flat Product name wins. `EditorProductView` passes the value
  /// from its `_localizedName` getter, which prefers the origin.
  final String? displayName;

  const EditorHero({
    super.key,
    required this.product,
    required this.isRTL,
    this.displayName,
  });

  /// Ordered image candidates: seller's primary, the rest of the seller
  /// gallery, then the linked origin's reference image. Passed straight
  /// to [FallbackNetworkImage], which picks the first one that loads.
  List<String?> _imageCandidates() => <String?>[
        product.primaryImageUrl,
        ...product.imageUrls,
        product.product_origin?.iproductImageUrl,
      ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;
    final categoryLabel = _productCategoryHierarchy(
      product,
      context.watch<ProductNotifier>().productCategories,
      Localizations.localeOf(context).languageCode,
      loc,
    );

    final hasGallery = product.product_images.length > 1;

    final name = _resolveDisplayName(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primary.withOpacity(0.08), cs.surface],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Thumbnail with optional gallery count badge ──────
          SizedBox(
            width: 110,
            height: 110,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    color: cs.surfaceVariant,
                    child: FallbackNetworkImage(
                      candidates: _imageCandidates(),
                      placeholderBuilder: (context) => _placeholder(cs),
                    ),
                  ),
                ),
                if (hasGallery)
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.collections_outlined,
                            size: 11,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${product.product_images.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              height: 1.0,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Badge(
                  label: loc.editorModeBadge,
                  color: cs.tertiary,
                ),
                const SizedBox(height: 10),
                if ((product.product_brand ?? '').isNotEmpty)
                  Text(
                    product.product_brand!,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (categoryLabel.isNotEmpty)
                      _Pill(
                        label: categoryLabel,
                        color: cs.secondary,
                      ),
                    QuantifierLabel(
                      raw: product.product_quantifier,
                      pillBuilder: (context, label, style) => _Pill(
                        label: label,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _resolveDisplayName(BuildContext context) {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!.trim();
    }

    final localeLang = Localizations.localeOf(context).languageCode;
    final localized = (localeLang == 'ar' || localeLang == 'fr')
        ? product.nameFor(localeLang)
        : product.product_name;
    if (localized.trim().isNotEmpty) return localized.trim();

    final raw = (product.product_nameRaw ?? '').trim();
    if (raw.isNotEmpty) return raw;

    // Fall back to the id so editors can at least identify the row.
    final id = product.id_product;
    return id != null ? 'Product #$id' : '—';
  }

  Widget _placeholder(ColorScheme cs) {
    return Center(
      child: Icon(
        Icons.image_outlined,
        size: 36,
        color: cs.onSurfaceVariant.withOpacity(0.5),
      ),
    );
  }
}

// ==================================================================
// Pricing hero: base price + final price + margin
// ==================================================================

class PricingHero extends StatelessWidget {
  final Product product;

  const PricingHero({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;

    final base = product.product_base_price ?? 0;
    final finalPrice = product.product_price ?? 0;
    final margin = product.unitMargin;
    final marginPct = product.unitMarginPercent;
    final hasBase = base > 0;
    final marginColor = (margin ?? 0) >= 0 ? const Color(0xFF1E8E5A) : cs.error;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.payments_outlined,
                  size: 16,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                loc.pricingSectionTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _BigPrice(
                  label: loc.basePriceLabel,
                  caption: loc.basePriceCaption,
                  value: hasBase ? base : null,
                  color: cs.onSurfaceVariant,
                ),
              ),
              Container(
                width: 1,
                height: 56,
                color: cs.outlineVariant.withOpacity(0.5),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _BigPrice(
                  label: loc.finalPriceLabel,
                  caption: loc.finalPriceCaption,
                  value: finalPrice > 0 ? finalPrice : null,
                  color: cs.primary,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          if (hasBase) ...[
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _KpiPill(
                    label: loc.marginLabel,
                    value: margin == null
                        ? '—'
                        : '${margin >= 0 ? '+' : ''}${margin.toStringAsFixed(2)}',
                    color: marginColor,
                    icon: (margin ?? 0) >= 0
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _KpiPill(
                    label: loc.marginPercentLabel,
                    value: marginPct == null
                        ? '—'
                        : '${(marginPct * 100).toStringAsFixed(1)}%',
                    color: marginColor,
                    icon: Icons.percent_rounded,
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: cs.tertiaryContainer.withOpacity(0.35),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: cs.onTertiaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      loc.setBasePriceHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onTertiaryContainer,
                      ),
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

// ==================================================================
// Actions
// ==================================================================

class EditorActions extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onToggleVisibility;
  final bool isVisible;

  const EditorActions({
    super.key,
    required this.onEdit,
    required this.onToggleVisibility,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: Text(loc.edit),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onToggleVisibility,
            icon: Icon(
              isVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18,
            ),
            label: Text(isVisible ? loc.hideAction : loc.showAction),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: cs.outline.withOpacity(0.4)),
            ),
          ),
        ),
      ],
    );
  }
}

// ==================================================================
// Stock
// ==================================================================

class StockCard extends StatelessWidget {
  final Product product;

  const StockCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;
    final stock = product.product_quantity ?? 0;
    final reserved = product.product_reserved_quantity ?? 0;
    final available = product.product_available_quantity;
    final total = stock > 0 ? stock : 1;
    final reservedRatio = (reserved / total).clamp(0.0, 1.0);
    final availableRatio = (available / total).clamp(0.0, 1.0);

    return _SectionCard(
      icon: Icons.inventory_2_outlined,
      title: loc.stockSectionTitle,
      trailing: _Pill(
        label: available > 0 ? loc.inStockLabel : loc.outOfStockLabel,
        color: available > 0 ? const Color(0xFF1E8E5A) : cs.error,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: (availableRatio * 1000).round().clamp(1, 1000),
                    child: const ColoredBox(
                      color: Color(0xFF1E8E5A),
                    ),
                  ),
                  if (reserved > 0)
                    Expanded(
                      flex: (reservedRatio * 1000).round().clamp(1, 1000),
                      child: ColoredBox(color: cs.tertiary),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: loc.stockTotalLabel,
                  value: '$stock',
                  color: cs.onSurface,
                ),
              ),
              Expanded(
                child: _Stat(
                  label: loc.stockReservedLabel,
                  value: '$reserved',
                  color: cs.tertiary,
                ),
              ),
              Expanded(
                child: _Stat(
                  label: loc.stockAvailableLabel,
                  value: '$available',
                  color: available > 0 ? const Color(0xFF1E8E5A) : cs.error,
                  bold: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// Metadata
// ==================================================================

class MetadataCard extends StatelessWidget {
  final Product product;

  const MetadataCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final origin = product.product_origin;
    final categoryLabel = _productCategoryHierarchy(
      product,
      context.watch<ProductNotifier>().productCategories,
      Localizations.localeOf(context).languageCode,
      loc,
    );

    // Barcode: prefer the origin's extracted barcode when present —
    // it came from the physical product, not from a human typing.
    final barcode = (origin != null && origin.iproductBarcode.isNotEmpty)
        ? origin.iproductBarcode
        : (product.product_barcode ?? '—');

    // Imported brand: the origin's own brand field, when non-empty
    // and different from the seller's. Shown as a distinct chip so a
    // steward can spot a mismatch.
    final originBrand = (origin != null &&
            origin.iproductBrand.isNotEmpty &&
            origin.iproductBrand != (product.product_brand ?? ''))
        ? origin.iproductBrand
        : null;

    final entries = <_MetaEntry>[
      _MetaEntry(
        icon: Icons.tag,
        label: loc.metaIdLabel,
        value: '${product.id_product ?? '—'}',
      ),
      _MetaEntry(
        icon: Icons.category_outlined,
        label: loc.metaCategoryLabel,
        value: categoryLabel.isNotEmpty ? categoryLabel : '—',
      ),
      _MetaEntry(
        icon: Icons.qr_code,
        label: loc.metaBarcodeLabel,
        value: barcode,
      ),
      _MetaEntry(
        icon: Icons.straighten,
        label: loc.metaUnitLabel,
        value: product.product_quantifier ?? '—',
      ),
      _MetaEntry(
        icon: Icons.storefront_outlined,
        label: loc.metaProviderLabel,
        value: '${product.product_provider_id ?? '—'}',
      ),
      _MetaEntry(
        icon: Icons.person_outline,
        label: loc.metaOwnerLabel,
        value: '${product.product_owner_id ?? '—'}',
      ),
      _MetaEntry(
        icon: Icons.public,
        label: loc.metaOriginLabel,
        value: '${product.product_origin_id ?? '—'}',
      ),
      _MetaEntry(
        icon: Icons.visibility_outlined,
        label: loc.productVisibilityTitle,
        value: product.isVisible
            ? loc.visibilityVisibleLabel
            : loc.visibilityHiddenLabel,
      ),
      // ---- origin-only rows, rendered when the origin exists ----
      if (originBrand != null)
        _MetaEntry(
          icon: Icons.business_outlined,
          label: loc.metaImportedBrandLabel,
          value: originBrand,
        ),
      if (origin != null && origin.iproductInfoSource.isNotEmpty)
        _MetaEntry(
          icon: Icons.auto_awesome_outlined,
          label: loc.metaImportSourceLabel,
          value: origin.iproductInfoSource,
        ),
      if (origin != null)
        _MetaEntry(
          icon: Icons.verified_outlined,
          label: loc.metaImportConfidenceLabel,
          value: '${(origin.iproductInfoConfidence * 100).round()}%',
        ),
    ];

    return _SectionCard(
      icon: Icons.info_outline,
      title: loc.metadataSectionTitle,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: entries.map((e) => _MetaChip(entry: e)).toList(),
      ),
    );
  }
}

// ==================================================================
// Danger zone
// ==================================================================

class DangerZoneCard extends StatelessWidget {
  final VoidCallback onDelete;

  const DangerZoneCard({super.key, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.errorContainer.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.error.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 18, color: cs.error),
              const SizedBox(width: 8),
              Text(
                loc.dangerZoneTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            loc.dangerZoneBody,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(loc.delete),
              style: FilledButton.styleFrom(
                backgroundColor: cs.error,
                foregroundColor: cs.onError,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// Building blocks
// ==================================================================

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: cs.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _BigPrice extends StatelessWidget {
  final String label;
  final String caption;
  final double? value;
  final Color color;
  final bool alignEnd;

  const _BigPrice({
    required this.label,
    required this.caption,
    required this.value,
    required this.color,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final crossAxis =
        alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: crossAxis,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value == null ? '—' : value!.toStringAsFixed(2),
          style: theme.textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
            height: 1.05,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          caption,
          style: theme.textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

class _KpiPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _KpiPill({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool bold;

  const _Stat({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _MetaEntry {
  final IconData icon;
  final String label;
  final String value;
  const _MetaEntry({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _MetaChip extends StatelessWidget {
  final _MetaEntry entry;
  const _MetaChip({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(entry.icon, size: 13, color: cs.primary),
          const SizedBox(width: 6),
          Text(
            '${entry.label}: ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          Text(
            entry.value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
