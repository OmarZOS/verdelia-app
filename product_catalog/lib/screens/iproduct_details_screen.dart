import 'package:flutter/material.dart';
import 'package:app_constants/app_constants.dart';
import 'package:verdelia_core/business/iProduct.dart';
import 'package:event/assistant_change_notifier.dart';
import 'package:event/components/lib.dart';
import 'package:product_catalog/screens/components/iproduct_screen/available_products_section.dart';
import 'package:product_catalog/screens/components/iproduct_screen/iproduct_hero_image.dart';
import 'package:product_catalog/screens/components/iproduct_screen/iproduct_info_section.dart';
import 'package:product_catalog/screens/components/iproduct_screen/no_product_data_screen.dart';
import 'package:provider/provider.dart';

class IProductDetailsScreen extends StatefulWidget {
  final String barcode;

  const IProductDetailsScreen({Key? key, required this.barcode})
      : super(key: key);

  @override
  State<IProductDetailsScreen> createState() => _IProductDetailsScreenState();
}

class _IProductDetailsScreenState extends State<IProductDetailsScreen> {
  late Future<IProduct?> _iproductFuture;

  @override
  void initState() {
    super.initState();
    _iproductFuture = _fetchIProduct();
  }

  Future<IProduct?> _fetchIProduct() async {
    try {
      final notifier = context.read<AssistantNotifier>();

      // Call your existing fetchProductByBarcode method
      await notifier.fetchProductByBarcode(widget.barcode, onlyFromDB: true);

      // Wait for operation to complete
      await Future.delayed(const Duration(milliseconds: 100));

      // Check if operation was successful and product exists
      if (!notifier.isLoading && notifier.product != null) {
        return notifier.product;
      }

      // If no product found, check the operation state
      if (notifier.lastOperation == "barcode_no_product") {
        return null;
      }

      // Handle error states
      if (notifier.lastOperation == "barcode_error" ||
          notifier.lastOperation == "barcode_invalid" ||
          notifier.lastOperation == "barcode_invalid_api") {
        throw Exception(notifier.lastError ?? "Failed to fetch product");
      }

      return null;
    } catch (e) {
      debugPrint('Error fetching iProduct: $e');
      rethrow;
    }
  }

  void _retryFetch() {
    setState(() {
      _iproductFuture = _fetchIProduct();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<IProduct?>(
      future: _iproductFuture,
      builder: (context, snapshot) {
        final colorScheme = Theme.of(context).colorScheme;
        final notifier = context.watch<AssistantNotifier>();

        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting ||
            notifier.isLoading) {
          return _buildLoadingScreen(context);
        }

        // Handle error state
        if (snapshot.hasError || notifier.lastOperation == "barcode_error") {
          return _buildErrorScreen(
              context,
              snapshot.error?.toString() ??
                  notifier.lastError ??
                  "Unknown error");
        }

        // Check for specific error cases from your notifier
        if (notifier.lastError == "barcode_invalid" ||
            notifier.lastError == "barcode_invalid_api") {
          return _buildErrorScreen(
              context, notifier.lastError ?? "Invalid barcode");
        }

        // Get the product data
        final iproduct = snapshot.data ?? notifier.product;

        // Handle no data state (when product not found)
        if (iproduct == null ||
            notifier.lastOperation == "barcode_no_product" ||
            (iproduct.iproductName.isEmpty && iproduct.iproductBrand.isEmpty)) {
          return NoProductDataScreen(
            barcode: widget.barcode,
            onScanAgain: () => Navigator.pop(context),
            onAddManually: () {
              _navigateToAddProduct(context, widget.barcode);
            },
          );
        }

        // Show product details
        return _buildProductDetailsScreen(context, iproduct, colorScheme);
      },
    );
  }

  Widget _buildLoadingScreen(BuildContext context) {
    final notifier = context.read<AssistantNotifier>();
    final operation = notifier.lastOperation;

    String loadingText = 'Fetching product information...';

    // Customize loading text based on operation
    if (operation == "barcode_lookup") {
      loadingText = 'Looking up barcode in database...';
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              loadingText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            // Show operation message if available
            if (notifier.lastOperation != null &&
                notifier.lastOperation!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  notifier.lastOperation!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withOpacity(0.7),
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context, String error) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final notifier = context.read<AssistantNotifier>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to Load Product',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.length > 100 ? '${error.substring(0, 100)}...' : error,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              // Show operation details if available
              if (notifier.lastOperation != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Operation: ${notifier.lastOperation}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _retryFetch,
                    child: const Text('Retry'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductDetailsScreen(
    BuildContext context,
    IProduct iproduct,
    ColorScheme colorScheme,
  ) {
    final notifier = context.read<AssistantNotifier>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            collapsedHeight: 80,
            pinned: true,
            floating: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: _buildBackButton(context, colorScheme),
            flexibleSpace: FlexibleSpaceBar(
              background: IProductHeroImage(iproduct: iproduct),
            ),
            // Show data source if available
            bottom: notifier.source_of_data != null
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(30),
                    child: Container(
                      color: Colors.transparent,
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getSourceText(notifier.source_of_data!),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ),
                    ),
                  )
                : null,
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.kDefaultPaddin),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IProductInfoSection(iproduct: iproduct),
                    const SizedBox(height: 32),
                    AvailableProductsSection(barcode: iproduct.iproductBarcode),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(top: 12, left: 12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surface.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
        color: colorScheme.onSurface,
      ),
    );
  }

  String _getSourceText(DataSource source) {
    switch (source) {
      case DataSource.aiGenerated:
        return 'AI Generated';
      case DataSource.databaseFetched:
        return 'From Database';
      default:
        return 'Unknown Source';
    }
  }

  void _navigateToAddProduct(BuildContext context, String barcode) {
    // TODO: Implement navigation to product creation screen
    // This would be where you create a new product manually
    // Example:
    // Navigator.pushNamed(
    //   context,
    //   '/create-product',
    //   arguments: {'barcode': barcode},
    // );

    // For now, show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Create new product for barcode: $barcode'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
