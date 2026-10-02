// lib/screens/product_details_screen.dart

import 'package:app_constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:event/preferenceChangeNotifier.dart';
import 'package:event/product_change_notifier.dart';
import 'package:event/user_change_notifier.dart';
import 'package:product_catalog/screens/components/product/customer_view.dart';
import 'package:product_catalog/screens/components/product/editor_view.dart';
import 'package:provider/provider.dart';

class ProductDetailsScreen extends StatelessWidget {
  final ProductDetailsMode mode;

  const ProductDetailsScreen({
    super.key,
    this.mode = ProductDetailsMode.customer,
  });

  @override
  Widget build(BuildContext context) {
    return _ProductDetailsScreenContent(mode: mode);
  }
}

class _ProductDetailsScreenContent extends StatefulWidget {
  final ProductDetailsMode mode;

  const _ProductDetailsScreenContent({required this.mode});

  @override
  State<_ProductDetailsScreenContent> createState() =>
      _ProductDetailsScreenContentState();
}

class _ProductDetailsScreenContentState
    extends State<_ProductDetailsScreenContent> {
  Product? _product;
  ProductDetailsMode _mode = ProductDetailsMode.customer;
  bool _initialized = false;
  late ProductNotifier _productNotifier;

  bool get _isEditor => _mode == ProductDetailsMode.editor;
  bool get _hasProduct => _product != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final productArg = args?['product'];
    _product = productArg is Product ? productArg : null;

    final modeArg = args?['mode'] as String?;
    switch (modeArg) {
      case 'editor':
        _mode = ProductDetailsMode.editor;
        break;
      case 'customer':
        _mode = ProductDetailsMode.customer;
        break;
      default:
        _mode = widget.mode;
    }

    _productNotifier = context.read<ProductNotifier>();
    if (_hasProduct) {
      _productNotifier.startPollingProductUpdates(_product!);
    }

    _initialized = true;
  }

  @override
  void dispose() {
    _productNotifier.stopPollingProductUpdates();
    super.dispose();
  }

  void _onProductUpdated(Product updated) {
    if (!mounted) return;
    setState(() => _product = updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRTL = context.read<LocaleProvider>().locale?.languageCode == 'ar';
    final isLoggedIn = context.read<AppUserNotifier>().isAuthenticated;
    final isDarkMode = theme.brightness == Brightness.dark;

    if (!_hasProduct) {
      return _MissingProductScaffold(theme: theme);
    }

    if (_isEditor) {
      return EditorProductView(
        product: _product!,
        isRTL: isRTL,
        onProductUpdated: _onProductUpdated,
      );
    }

    return CustomerProductView(
      product: _product!,
      isRTL: isRTL,
      isLoggedIn: isLoggedIn,
      isDarkMode: isDarkMode,
      onProductUpdated: _onProductUpdated,
    );
  }
}

class _MissingProductScaffold extends StatelessWidget {
  final ThemeData theme;

  const _MissingProductScaffold({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 56,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Product not available',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
