// lib/ui/components/supplier/supplier_details_modal.dart

import 'dart:developer' as developer;

import 'package:app_constants/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:verdelia_core/business/Supplier.dart';
import 'package:event/product_change_notifier.dart';
import 'package:event/supplier_change_notifier.dart';
import 'package:ui/SupplierProductCard.dart';
import 'package:ui/components/supplier/BusinessOwner.dart';
import 'package:ui/components/supplier/contactTile.dart';
import 'package:ui/components/location/location_info.dart';
import 'package:ui/components/supplier/delete_confirm.dart';
import 'package:provider/provider.dart';

void showSupplierDetails(BuildContext context, Supplier supplier) {
  final theme = Theme.of(context);
  final productNotifier = context.read<ProductNotifier>();
  final supplierNotifier = context.read<SupplierChangeNotifier>();

  developer.log(
    'showSupplierDetails id=${supplier.idProductProvider}',
    name: 'SupplierDetailsModal',
  );

  // Fetch fresh supplier data in the background.
  supplierNotifier.getSupplierById(supplier.idProductProvider);

  final isDarkMode = theme.brightness == Brightness.dark;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: isDarkMode
        ? Colors.white.withOpacity(0.5)
        : Colors.black.withOpacity(0.5),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) => _SupplierDetailsModal(
        supplier: supplier,
        supplierNotifier: supplierNotifier,
        productNotifier: productNotifier,
        scrollController: scrollController,
      ),
    ),
  );
}

class _SupplierDetailsModal extends StatefulWidget {
  final Supplier supplier;
  final SupplierChangeNotifier supplierNotifier;
  final ProductNotifier productNotifier;
  final ScrollController scrollController;

  const _SupplierDetailsModal({
    required this.supplier,
    required this.supplierNotifier,
    required this.productNotifier,
    required this.scrollController,
  });

  @override
  State<_SupplierDetailsModal> createState() => _SupplierDetailsModalState();
}

class _SupplierDetailsModalState extends State<_SupplierDetailsModal> {
  late Future<List<Product>> _supplierProductsFuture;

  /// Cached products from the notifier, kept around so we can render
  /// a horizontal list while the fresh fetch is in flight.
  List<Product>? _cachedProducts;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final supplierId = widget.supplier.idProductProvider;

    final cached = widget.productNotifier.getCachedSupplierProducts(supplierId);
    _cachedProducts = (cached != null && cached.isNotEmpty) ? cached : null;

    _supplierProductsFuture = _fetchSupplierProducts();
  }

  /// Returns the supplier's products. Prefers whatever the notifier
  /// already has in memory so the sheet paints instantly; only hits
  /// the network when there's nothing to show.
  Future<List<Product>> _fetchSupplierProducts() async {
    final supplierId = widget.supplier.idProductProvider;

    final existing = widget.productNotifier.products
        .where((p) => p.product_provider_id == supplierId)
        .toList();
    if (existing.isNotEmpty) return existing;

    final cached = widget.productNotifier.getCachedSupplierProducts(supplierId);
    if (cached != null && cached.isNotEmpty) return cached;

    return widget.productNotifier.fetchSupplierProducts(supplierId);
  }

  void _retry() {
    setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final supplier = widget.supplier;
    final contacts = parseContactInfo(supplier.providerContactInfo);

    final localeLang = Localizations.localeOf(context).languageCode;
    final displayName = supplier.nameFor(localeLang);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(context, supplier, loc),
          Expanded(
            child: CustomScrollView(
              controller: widget.scrollController,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 16),
                      _buildSectionHeader(context, loc.locationText),
                      buildLocationInfo(
                        context,
                        widget.supplierNotifier,
                        supplier,
                      ),
                      const SizedBox(height: 24),
                      if (supplier.providerContactInfo.isNotEmpty)
                        _buildSectionHeader(context, loc.contactInfoMsg),
                      ...contacts.map(
                        (contact) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: buildContactTile(
                            context,
                            contact['type']!,
                            contact['value']!,
                          ),
                        ),
                      ),
                      _buildSectionHeader(
                        context,
                        loc.productsFromSupplier(displayName),
                      ),
                      const SizedBox(height: 8),
                    ]),
                  ),
                ),
                _buildProductSection(context, loc, theme),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(loc.close),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRODUCTS
  // ============================================================

  Widget _buildProductSection(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
  ) {
    return SliverToBoxAdapter(
      child: FutureBuilder<List<Product>>(
        future: _supplierProductsFuture,
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final products = snapshot.data ?? const <Product>[];
          final cached = _cachedProducts;

          // Fresh data ready.
          if (snapshot.hasData && products.isNotEmpty) {
            return _productStrip(context, products);
          }

          // Fresh data ready but empty.
          if (snapshot.hasData && products.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  loc.noOtherProductsAvailable,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // Error.
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: theme.colorScheme.error,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.failedToLoadProducts,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    onPressed: _retry,
                    child: Text(loc.retryButton),
                  ),
                ],
              ),
            );
          }

          // Loading. Show cached products if we have any, plus a
          // small spinner below.
          if (isLoading && cached != null && cached.isNotEmpty) {
            return Column(
              children: [
                _productStrip(context, cached),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ],
            );
          }

          // Loading with nothing to show.
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  Widget _productStrip(BuildContext context, List<Product> products) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _buildProductCard(
          context,
          products[index],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    // Match the card width to the sheet width without hardcoding a
    // pixel value that breaks on tablets or small phones.
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = (screenWidth * 0.75).clamp(220.0, 360.0);

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.productDetails,
          arguments: {'product': product},
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: cardWidth,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SupplierProductCard(
            product: product,
            supplierName: product.product_brand ?? '',
            stockQuantity: product.product_quantity ?? 0,
            minOrderQty: '1',
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(
    BuildContext context,
    Supplier supplier,
    AppLocalizations loc,
  ) {
    final theme = Theme.of(context);
    final localeLang = Localizations.localeOf(context).languageCode;
    final displayName = supplier.nameFor(localeLang);
    final organisationName = supplier.organisationNameFor(localeLang);

    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: theme.colorScheme.outline.withOpacity(0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.start,
            children: [
              _SupplierHeaderAvatar(supplier: supplier),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (organisationName.isNotEmpty)
                      Text(
                        organisationName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (isBusinessOwner(context, supplier.productProviderOwnerId))
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.start,
                  children: [
                    IconButton(
                      iconSize: 27,
                      color: theme.colorScheme.tertiary,
                      tooltip: loc.deleteTooltip,
                      onPressed: () {
                        showDeleteConfirmation(
                          context,
                          widget.supplierNotifier,
                          supplier.idProductProvider,
                        );
                      },
                      icon: const Icon(Icons.delete),
                    ),
                    IconButton(
                      iconSize: 27,
                      color: theme.colorScheme.secondary,
                      tooltip: loc.editTooltip,
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.providerCreate,
                          arguments: {'supplier': supplier},
                        );
                      },
                      icon: const Icon(Icons.edit_location_alt),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ============================================================================
// HEADER AVATAR
// ============================================================================

class _SupplierHeaderAvatar extends StatelessWidget {
  final Supplier supplier;

  const _SupplierHeaderAvatar({required this.supplier});

  bool get _hasValidImage {
    final url = supplier.supplierImageUrl;
    return url != null && url.isNotEmpty && url.startsWith('http');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CircleAvatar(
      radius: 50,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: _hasValidImage
          ? ClipOval(
              child: Image.network(
                supplier.supplierImageUrl!,
                fit: BoxFit.cover,
                width: 100,
                height: 100,
                key: ValueKey(supplier.supplierImageUrl),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                },
                errorBuilder: (_, __, ___) => _fallbackIcon(theme),
              ),
            )
          : _fallbackIcon(theme),
    );
  }

  Widget _fallbackIcon(ThemeData theme) {
    return SvgPicture.asset(
      'assets/icons/${supplier.productProviderTypeId}.svg',
      package: 'provider_geo',
      width: 40,
      height: 40,
      color: theme.colorScheme.onSurface,
    );
  }
}
