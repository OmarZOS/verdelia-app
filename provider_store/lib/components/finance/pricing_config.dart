import 'package:flutter/material.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:event/views/pricing_config_view_model.dart';
import 'package:ui/components/pricing_config_card.dart';
import 'package:provider/provider.dart';
import 'package:event/product_change_notifier.dart';

class PricingConfigScreen extends StatefulWidget {
  final PricingConfigViewModel viewModel;
  final bool isLoading;

  /// The provider whose products are being priced. `null` or `0` means
  /// "no provider selected" — the product grid shows an empty state.
  final int? providerId;

  final VoidCallback onSave;
  final ValueChanged<double> onBasePriceChanged;
  final ValueChanged<double> onTaxPercentageChanged;
  final ValueChanged<double> onProfitMarginChanged;
  final ValueChanged<double> onFinalPriceChanged;
  final ValueChanged<PricingMode> onModeChanged;
  final ValueChanged<Product> onToggleProductSelection;
  final VoidCallback onToggleSelectAll;
  final VoidCallback onUpdateSelectedProducts;
  final VoidCallback onClearSelection;

  const PricingConfigScreen({
    super.key,
    required this.viewModel,
    required this.isLoading,
    this.providerId,
    required this.onSave,
    required this.onBasePriceChanged,
    required this.onTaxPercentageChanged,
    required this.onProfitMarginChanged,
    required this.onFinalPriceChanged,
    required this.onModeChanged,
    required this.onToggleProductSelection,
    required this.onToggleSelectAll,
    required this.onUpdateSelectedProducts,
    required this.onClearSelection,
  });

  @override
  State<PricingConfigScreen> createState() => _PricingConfigScreenState();
}

class _PricingConfigScreenState extends State<PricingConfigScreen>
    with SingleTickerProviderStateMixin {
  late double _localBasePrice;
  late double _localTaxPercentage;
  late double _localProfitMargin;
  late double _localFinalPrice;
  late PricingMode _localMode;

  bool _isEditingBasePrice = false;
  bool _isEditingTax = false;
  bool _isEditingProfit = false;
  bool _isEditingFinalPrice = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  int? get _providerId => (widget.providerId != null && widget.providerId! > 0)
      ? widget.providerId
      : null;

  @override
  void initState() {
    super.initState();
    _initLocalValues();
    _initAnimation();
    _loadProductsForProvider();
  }

  @override
  void didUpdateWidget(covariant PricingConfigScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Provider changed → reload the product set.
    if (oldWidget.providerId != widget.providerId) {
      _loadProductsForProvider();
    }

    if (widget.viewModel.basePrice != oldWidget.viewModel.basePrice &&
        !_isEditingBasePrice) {
      _localBasePrice = widget.viewModel.basePrice;
    }
    if (widget.viewModel.taxPercentage != oldWidget.viewModel.taxPercentage &&
        !_isEditingTax) {
      _localTaxPercentage = widget.viewModel.taxPercentage;
    }
    if (widget.viewModel.profitMargin != oldWidget.viewModel.profitMargin &&
        !_isEditingProfit) {
      _localProfitMargin = widget.viewModel.profitMargin;
    }
    if (widget.viewModel.finalPrice != oldWidget.viewModel.finalPrice &&
        !_isEditingFinalPrice) {
      _localFinalPrice = widget.viewModel.finalPrice;
    }
    if (widget.viewModel.mode != oldWidget.viewModel.mode) {
      _localMode = widget.viewModel.mode;
    }
  }

  /// Load the current provider's products into the ProductNotifier.
  ///
  /// This is a side-effect read: we don't own the notifier, we just tell it
  /// to fetch for the provider we care about. If you already have a parent
  /// that loads products, you can drop this method and rely on that.
  void _loadProductsForProvider() {
    final providerId = _providerId;
    if (providerId == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final productNotifier =
          Provider.of<ProductNotifier>(context, listen: false);
      // Adjust the method name to match ProductNotifier. Common variants:
      //   fetchProducts(providerId: ...)
      //   loadProducts(providerId: ...)
      //   setProvider(providerId)
      productNotifier.fetchProducts(providerId: providerId);
    });
  }

  void _initLocalValues() {
    _localBasePrice = widget.viewModel.basePrice;
    _localTaxPercentage = widget.viewModel.taxPercentage;
    _localProfitMargin = widget.viewModel.profitMargin;
    _localFinalPrice = widget.viewModel.finalPrice;
    _localMode = widget.viewModel.mode;
  }

  void _initAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: _buildAppBar(context),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _providerId == null
            ? _buildNoProviderState(context)
            : _buildBody(context),
      ),
      floatingActionButton:
          _providerId == null ? null : _buildFloatingActionButton(),
    );
  }

  // ==================== APP BAR ====================

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      title: const Text('Pricing Configuration'),
      centerTitle: false,
      elevation: 0,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      actions: [
        if (widget.viewModel.selectedProducts.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 16, color: colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  '${widget.viewModel.selectedProducts.length} selected',
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        IconButton(
          icon: const Icon(Icons.save_outlined),
          onPressed:
              widget.isLoading || _providerId == null ? null : widget.onSave,
          tooltip: 'Save Configuration',
        ),
      ],
    );
  }

  // ==================== BODY ====================

  Widget _buildBody(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PricingConfigCard(
                  basePrice: _localBasePrice,
                  taxPercentage: _localTaxPercentage,
                  profitMargin: _localProfitMargin,
                  finalPrice: _localFinalPrice,
                  mode: _localMode,
                  onBasePriceChanged: (value) {
                    setState(() => _localBasePrice = value);
                    widget.onBasePriceChanged(value);
                  },
                  onTaxPercentageChanged: (value) {
                    setState(() => _localTaxPercentage = value);
                    widget.onTaxPercentageChanged(value);
                  },
                  onProfitMarginChanged: (value) {
                    setState(() => _localProfitMargin = value);
                    widget.onProfitMarginChanged(value);
                  },
                  onFinalPriceChanged: (value) {
                    setState(() => _localFinalPrice = value);
                    widget.onFinalPriceChanged(value);
                  },
                  onModeChanged: (value) {
                    setState(() => _localMode = value);
                    widget.onModeChanged(value);
                  },
                ),
                const SizedBox(height: 24),
                _buildProductSelector(context),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        if (widget.viewModel.selectedProducts.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildBatchActions(context),
            ),
          ),
        if (widget.isLoading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 80),
        ),
      ],
    );
  }

  // ==================== NO PROVIDER ====================

  Widget _buildNoProviderState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.storefront_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Select a supplier first',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Choose a supplier to configure pricing.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== PRODUCT SELECTOR ====================

  Widget _buildProductSelector(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<ProductNotifier>(
      builder: (context, productNotifier, _) {
        // Guard: if the notifier has stale products from a different
        // provider, we don't want to show them. If your ProductNotifier
        // tracks the currently loaded provider id, this is where you'd
        // assert it matches `_providerId`.
        final products = productNotifier.products;

        if (productNotifier.isLoading && products.isEmpty) {
          return _buildLoadingSkeleton(context);
        }

        if (products.isEmpty) {
          return _buildEmptyProductState(context);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.production_quantity_limits,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Select Products',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: widget.onToggleSelectAll,
                  icon: Icon(
                    widget.viewModel.selectedProducts.length == products.length
                        ? Icons.deselect
                        : Icons.select_all,
                    size: 18,
                  ),
                  label: Text(
                    widget.viewModel.selectedProducts.length == products.length
                        ? 'Deselect All'
                        : 'Select All',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return _buildProductSelectionCard(
                  context,
                  products[index],
                  index,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductSelectionCard(
      BuildContext context, Product product, int index) {
    final isSelected = widget.viewModel.selectedProducts.contains(product);
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      transform: Matrix4.identity()..scale(isSelected ? 1.02 : 1.0),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primaryContainer,
                  colorScheme.primaryContainer.withOpacity(0.8),
                ],
              )
            : null,
        color: isSelected ? null : colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          width: 2,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onToggleProductSelection(product),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        product.product_name ?? 'Product',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurface,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        key: ValueKey(isSelected),
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Current:',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          ),
                          Text(
                            'DZD ${product.product_price?.toStringAsFixed(2)}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (isSelected) ...[
                        const Divider(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'New:',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: colorScheme.primary,
                                  ),
                            ),
                            Text(
                              'DZD ${widget.viewModel.finalPrice.toStringAsFixed(2)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Profit:',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: widget.viewModel.profitMargin >= 0
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (widget.viewModel.profitMargin >= 0
                                        ? Colors.green
                                        : Colors.red)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${widget.viewModel.profitMargin.toStringAsFixed(2)}%',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: widget.viewModel.profitMargin >= 0
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== BATCH ACTIONS ====================

  Widget _buildBatchActions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedCount = widget.viewModel.selectedProducts.length;

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      builder: (context, double opacity, child) {
        return Opacity(opacity: opacity, child: child);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer,
              colorScheme.primaryContainer.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    selectedCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Products Selected',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                ),
                      ),
                      Text(
                        'Update $selectedCount product${selectedCount > 1 ? 's' : ''}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (widget.viewModel.profitMargin >= 0
                            ? Colors.green
                            : Colors.red)
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${widget.viewModel.profitMargin.toStringAsFixed(2)}% Profit',
                    style: TextStyle(
                      color: widget.viewModel.profitMargin >= 0
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Final Price per Product:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                  ),
                  Text(
                    'DZD ${widget.viewModel.finalPrice.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onClearSelection,
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('Clear'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: colorScheme.surface,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: widget.isLoading
                        ? null
                        : widget.onUpdateSelectedProducts,
                    icon: widget.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.update, size: 18),
                    label: Text(
                        widget.isLoading ? 'Updating...' : 'Update Prices'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== SKELETONS ====================

  Widget _buildLoadingSkeleton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 100,
              height: 24,
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const Spacer(),
            Container(
              width: 80,
              height: 36,
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: 4,
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyProductState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Products Available',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add products to configure pricing',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ==================== FAB ====================

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: widget.isLoading ? null : widget.onSave,
      icon: const Icon(Icons.save),
      label: const Text('Save'),
      elevation: 2,
    );
  }
}
