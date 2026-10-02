import 'dart:async';

import 'package:app_constants/app_routes.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:app_constants/app_constants.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:verdelia_core/business/iProduct.dart';
import 'package:event/user_change_notifier.dart';
import 'package:event/product_change_notifier.dart';
import 'package:event/preferenceChangeNotifier.dart';
import 'package:product_catalog/screens/components/ProductCard.dart';
import 'package:ui/components/floating_buttons.dart';
import 'package:product_catalog/screens/iproduct_details_screen.dart';
import 'package:provider/provider.dart';

class ProductCatalogScreen extends StatefulWidget {
  const ProductCatalogScreen({Key? key}) : super(key: key);

  @override
  ProductCatalogScreenState createState() => ProductCatalogScreenState();
}

class ProductCatalogScreenState extends State<ProductCatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  late List<String> _categories = [];
  int _selectedCategoryId = 0;
  final ScrollController _scrollController = ScrollController();
  late ProductNotifier _productNotifier;

  // Debounce search
  Timer? _searchTimer;
  static const _searchDelay = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _productNotifier = Provider.of<ProductNotifier>(context, listen: false);
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_scrollListener);

    // Initial fetch with cache support
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _productNotifier.fetchProducts(reset: true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeCategories();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchTimer?.cancel();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeCategories() {
    final categs =
        AppLocalizations.of(context)!.productCategoryTextList.split(",");
    _categories = [AppLocalizations.of(context)!.allText, ...categs];
    _productNotifier.productCategories = categs;
  }

  void _onSearchChanged() {
    // Debounce search to avoid too many requests
    if (_searchTimer?.isActive ?? false) _searchTimer?.cancel();
    _searchTimer = Timer(_searchDelay, () {
      if (mounted) {
        _filterProducts();
      }
    });
  }

  void _filterProducts() {
    String query = _searchController.text;
    _productNotifier.searchProducts(query);
  }

  void _selectCategory(int index) {
    if (_selectedCategoryId == index) return;

    setState(() {
      _selectedCategoryId = index;
    });

    // Clear search when changing category
    if (_searchController.text.isNotEmpty) {
      _searchController.clear();
    }

    _productNotifier.fetchProducts(categoryId: _selectedCategoryId);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_productNotifier.isLoading &&
        _productNotifier.hasMoreProducts) {
      _productNotifier.fetchProducts(categoryId: _selectedCategoryId);
    }
  }

  Future<void> _refreshProducts() async {
    // Invalidate cache and refresh
    _productNotifier.invalidateProductCache();
    await _productNotifier.fetchProducts(
      categoryId: _selectedCategoryId,
      reset: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = context.read<LocaleProvider>().locale?.languageCode == "ar";

    return Scaffold(
      floatingActionButton: CustomSpeedDial(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        uniqueId: 'product_fab',
        horizontalButtons: [
          SpeedDialButton(
            icon: const Icon(CupertinoIcons.barcode_viewfinder),
            label: AppLocalizations.of(context)!.scannerTxt,
            onTap: () async {
              String? barcode = await Navigator.pushNamed(
                context,
                AppRoutes.productScanPage,
              ) as String?;

              if (barcode != null && mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => IProductDetailsScreen(
                      barcode: barcode,
                    ),
                  ),
                );
              }
            },
          ),
        ],
        verticalButtons: [
          SpeedDialButton(
            icon: Icon(CupertinoIcons.list_dash),
            label: AppLocalizations.of(context)!.ordersText,
            onTap: () => Navigator.pushNamed(context, AppRoutes.ordersPage),
          ),
          SpeedDialButton(
            icon: Icon(Icons.shopping_cart),
            label: AppLocalizations.of(context)!.cartText,
            onTap: () => Navigator.pushNamed(context, AppRoutes.cartPage),
          ),
        ],
      ),
      appBar: AppBar(
        elevation: 0,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (value) => _filterProducts(),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)?.searchTxt,
              prefixIcon: Icon(
                Icons.search_outlined,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 18,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _filterProducts();
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
      body: Consumer<ProductNotifier>(
        builder: (context, productNotifier, child) {
          final products =
              productNotifier.filterProductsByCategory(_selectedCategoryId);

          // Apply search filter locally for better performance
          var filteredProducts = products;
          final query = _searchController.text.toLowerCase();
          if (query.isNotEmpty) {
            filteredProducts = products.where((product) {
              return (product.product_name?.toLowerCase().contains(query) ??
                      false) ||
                  (product.product_brand?.toLowerCase().contains(query) ??
                      false);
            }).toList();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildCategoryRow(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.kDefaultPaddin / 4,
                  ),
                  child: RefreshIndicator(
                    onRefresh: _refreshProducts,
                    child: _buildProductGrid(filteredProducts, productNotifier),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: _categories.asMap().entries.map((entry) {
          final index = entry.key;
          final category = entry.value;
          final isSelected = _productNotifier.currentCategory == index;
          final iconPath = 'assets/icons/$index.svg';

          return GestureDetector(
            onTap: () => _selectCategory(index),
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppConstants.kDefaultPaddin / 2,
                vertical: AppConstants.kDefaultPaddin / 4,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.kDefaultPaddin / 2,
                vertical: AppConstants.kDefaultPaddin / 3,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: SvgPicture.asset(
                      iconPath,
                      package: "product_catalog",
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category,
                    style: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductGrid(
      List<Product> products, ProductNotifier productNotifier) {
    // ✅ Show loading indicator when loading and no products
    if (productNotifier.isLoading && products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)?.loadingProducts ??
                  "Loading products...",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // ✅ Show empty state only when NOT loading and products are empty
    if (products.isEmpty && !productNotifier.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)?.noProductsFound ??
                  "No products found",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            if (_searchController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  _filterProducts();
                },
                child: Text(
                  AppLocalizations.of(context)?.clearSearch ?? "Clear search",
                ),
              ),
            ],
          ],
        ),
      );
    }

    // ✅ Show products with loading indicator at bottom for pagination
    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            controller: _scrollController,
            itemCount: products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(
                product: product,
                key: ValueKey(product.id_product),
              );
            },
          ),
        ),
        // ✅ Show loading indicator at bottom when loading more
        if (productNotifier.isLoading && products.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }
}
