import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:event/product_change_notifier.dart';
import 'package:provider/provider.dart';
import 'package:ui/components/image/image_url.dart';

class ProductSelectorDialog extends StatelessWidget {
  final int? supplierId;
  final int? selectedProductId;

  const ProductSelectorDialog({
    super.key,
    this.supplierId,
    this.selectedProductId,
  });

  static Future<Product?> show(
    BuildContext context, {
    int? supplierId,
    int? selectedProductId,
  }) {
    return showDialog<Product>(
      context: context,
      builder: (dialogContext) => ProductSelectorDialog(
        supplierId: supplierId,
        selectedProductId: selectedProductId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ProductSelectorDialogContent(
      supplierId: supplierId,
      selectedProductId: selectedProductId,
    );
  }
}

class _ProductSelectorDialogContent extends StatefulWidget {
  final int? supplierId;
  final int? selectedProductId;

  const _ProductSelectorDialogContent({
    this.supplierId,
    this.selectedProductId,
  });

  @override
  State<_ProductSelectorDialogContent> createState() =>
      _ProductSelectorDialogContentState();
}

class _ProductSelectorDialogContentState
    extends State<_ProductSelectorDialogContent> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Product> _filteredProducts = [];

  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  int? _selectedProductId;
  String _searchQuery = '';
  Timer? _debounceTimer;
  int _itemsPerPage = 20;

  @override
  void initState() {
    super.initState();
    _selectedProductId = widget.selectedProductId;
    _loadProducts();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Locale-aware product name — mirrors the resolution the cards use.
  String _nameFor(Product product, String lang) {
    if (lang == 'ar' || lang == 'fr') {
      final localized = product.nameFor(lang);
      if (localized.trim().isNotEmpty) return localized;
    }
    return product.product_name;
  }

  Future<void> _loadProducts({bool reset = false}) async {
    if (_isLoading || (!_hasMore && !reset)) return;

    setState(() {
      _isLoading = true;
      if (reset) {
        _filteredProducts.clear();
        _currentPage = 0;
        _hasMore = true;
      }
    });

    try {
      final productNotifier = Provider.of<ProductNotifier>(
        context,
        listen: false,
      );

      List<Product>? products;

      if (widget.supplierId != null && widget.supplierId! > 0) {
        final cached = productNotifier.getCachedSupplierProducts(
          widget.supplierId!,
        );

        if (cached != null) {
          products = cached;
        } else {
          products = await productNotifier
              .fetchSupplierProducts(widget.supplierId!, includeHidden: true);
        }
        _itemsPerPage = products?.length ?? 20;
      } else {
        if (_searchQuery.isNotEmpty) {
          await productNotifier.searchProducts(_searchQuery);
        } else {
          await productNotifier.fetchProducts(reset: reset);
        }
        products = productNotifier.products;
        _itemsPerPage = productNotifier.itemsPerPage;
      }

      final lang = Localizations.localeOf(context).languageCode;
      var filtered = products ?? [];
      if (_searchQuery.isNotEmpty && widget.supplierId != null) {
        filtered = filtered
            .where(
              (p) =>
                  _nameFor(p, lang)
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ||
                  (p.product_brand ?? '')
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()),
            )
            .toList();
      }

      setState(() {
        if (reset) {
          _filteredProducts.clear();
          _filteredProducts.addAll(filtered);
        } else {
          _filteredProducts.addAll(filtered);
        }
        _hasMore = filtered.length >= _itemsPerPage;
        _currentPage++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      final loc = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.errorOccurred)),
      );
    }
  }

  void _loadMore() {
    if (!_isLoading && _hasMore && _searchQuery.isEmpty) {
      _loadProducts();
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = query;
        _currentPage = 0;
        _hasMore = true;
      });
      _loadProducts(reset: true);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _currentPage = 0;
      _hasMore = true;
    });
    _loadProducts(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    loc.selectProductTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.outline.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(Icons.search, color: colors.onSurfaceVariant, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: loc.searchProductsHint,
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant.withOpacity(0.6),
                        ),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      onPressed: _clearSearch,
                      icon: Icon(Icons.clear,
                          color: colors.onSurfaceVariant, size: 20),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (widget.supplierId != null && widget.supplierId! > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.store, size: 16, color: colors.primary),
                    const SizedBox(width: 4),
                    Text(
                      loc.supplierProductsBadge,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: _filteredProducts.isEmpty && !_isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: colors.onSurfaceVariant.withOpacity(0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty
                                ? loc.noProductsFoundForQuery(_searchQuery)
                                : loc.noProductsAvailable,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_searchQuery.isNotEmpty)
                            TextButton(
                              onPressed: _clearSearch,
                              child: Text(loc.clearSearch),
                            ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadProducts(reset: true),
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: _filteredProducts.length +
                            (_hasMore && !_isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _filteredProducts.length) {
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colors.primary,
                                  ),
                                ),
                              ),
                            );
                          }
                          final product = _filteredProducts[index];
                          final isSelected =
                              _selectedProductId == product.id_product;
                          return _buildProductTile(product, isSelected);
                        },
                      ),
                    ),
            ),
            if (_isLoading && _filteredProducts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(loc.cancel),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final selectedProduct = _filteredProducts.firstWhere(
                      (p) => p.id_product == _selectedProductId,
                      orElse: () => null as Product,
                    );
                    Navigator.pop(context, selectedProduct);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                  ),
                  child: Text(loc.confirm),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductTile(Product product, bool isSelected) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final lang = Localizations.localeOf(context).languageCode;
    final displayName = _nameFor(product, lang);

    // Prefer the seller's own gallery image; fall back to the origin
    // reference image when the gallery is empty or malformed.
    final imageUrl = resolveImageUrl(product.primaryImageUrl) ??
        resolveImageUrl(product.product_origin?.iproductImageUrl);

    final stock = product.product_quantity ?? 0;
    final hasGallery = product.product_images.length > 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? colors.primaryContainer.withOpacity(0.15)
            : colors.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? colors.primary : colors.outline.withOpacity(0.1),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedProductId = product.id_product;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // ─── Thumbnail with gallery count overlay ─────
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: colors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                          image: imageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(imageUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: imageUrl == null
                            ? Icon(
                                Icons.inventory_2,
                                color: colors.onSurfaceVariant.withOpacity(0.4),
                                size: 24,
                              )
                            : null,
                      ),
                      if (hasGallery)
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${product.product_images.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                height: 1.0,
                                fontFeatures: [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName.isNotEmpty
                            ? displayName
                            : AppLocalizations.of(context)!.unnamedProduct,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? colors.primary : colors.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if ((product.product_brand ?? '').isNotEmpty)
                        Text(
                          product.product_brand!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      Row(
                        children: [
                          Text(
                            AppLocalizations.of(context)!.price(
                              product.product_price?.toStringAsFixed(2) ??
                                  '0.00',
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: stock > 0
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!
                                  .stockLabel(stock.toString()),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: stock > 0 ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      size: 16,
                      color: colors.onPrimary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
