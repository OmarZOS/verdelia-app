// lib/provider_store/components/delivery/DeliveryDetailsSheet.dart
import 'package:event/delivery_change_notifier.dart';
import 'package:event/product_change_notifier.dart';
import 'package:flutter/material.dart';
import 'package:verdelia_core/business/Delivery.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:provider_store/components/orders/details/delivery_details_screen.dart';

/// Edit-only sheet. Collects metadata about a delivery — packages,
/// shipping method, goods description, and the products attached to
/// this delivery — and commits them through [onCommit].
///
/// The product list is scoped to the ids the caller passes in via
/// [initialProductIds]. The sheet never browses the provider's full
/// catalog; it edits what's already in scope.
///
/// This sheet does NOT advance the delivery's status. Transitions are
/// handled by `DeliveryTransitionSheet`.
class DeliveryDetailsSheet extends StatefulWidget {
  final DeliveryChangeNotifier notifier;
  final Delivery delivery;
  final int providerId;
  final List<int> initialProductIds;

  /// Optional focus hint. When set, the sheet will scroll to and
  /// briefly highlight the section relevant to the fix.
  final DeliveryDetailsFocus? focusOn;

  final Future<bool> Function(Map<String, dynamic> fields) onCommit;

  const DeliveryDetailsSheet({
    super.key,
    required this.notifier,
    required this.delivery,
    required this.onCommit,
    this.providerId = 0,
    this.initialProductIds = const [],
    this.focusOn,
  });

  /// Open the edit sheet as a modal. Returns the fields the user saved,
  /// or null if they dismissed the sheet.
  static Future<Map<String, dynamic>?> open(
    BuildContext context, {
    required DeliveryChangeNotifier notifier,
    required Delivery delivery,
    int providerId = 0,
    List<int> initialProductIds = const [],
    DeliveryDetailsFocus? focusOn,
    Future<bool> Function(Map<String, dynamic> fields)? onCommit,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DeliveryDetailsSheet(
        notifier: notifier,
        delivery: delivery,
        providerId: providerId,
        initialProductIds: initialProductIds,
        focusOn: focusOn,
        onCommit: onCommit ??
            (fields) => notifier.updateDetails(
                  delivery.id_delivery,
                  body: fields,
                ),
      ),
    );
  }

  @override
  State<DeliveryDetailsSheet> createState() => _DeliveryDetailsSheetState();
}

/// Optional focus hint for [DeliveryDetailsSheet]. Used by the
/// transition flow to open the sheet with the relevant section
/// scrolled into view.
enum DeliveryDetailsFocus {
  recipient,
  destination,
  packages,
  products,
  shipping,
  additional,
}

class _DeliveryDetailsSheetState extends State<DeliveryDetailsSheet> {
  final _formKey = GlobalKey<FormState>();
  final _packages = <_PackageInput>[];
  final _goodsController = TextEditingController();
  final _merchantController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _hsCodeController = TextEditingController();
  final _searchController = TextEditingController();
  final _feeController = TextEditingController();

  final _packagesKey = GlobalKey();
  final _productsKey = GlobalKey();

  final Set<int> _selected = {};

  String _shippingMethod = 'standard';
  String _searchQuery = '';
  bool _isLoading = false;
  bool _selectionExpanded = false;
  bool _pruned = false;

  double get _totalWeight => _packages.fold(
        0,
        (total, package) => total + (double.tryParse(package.weight.text) ?? 0),
      );

  static const _shippingMethods = [
    'standard',
    'express',
    'overnight',
    'pickup',
    'courier',
    'same_day',
    'international',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);

    for (final id in widget.initialProductIds) {
      if (id > 0) _selected.add(id);
    }

    final delivery = widget.delivery;
    final count = delivery.delivery_package_count ?? 1;
    final weight = (delivery.delivery_total_weight ?? 0) / count;
    final dimensions = (delivery.delivery_cargo_dimensions ?? '')
        .split(RegExp(r'\s*,\s*|\s*\|\s*;\s*'));
    for (var i = 0; i < count; i++) {
      final parts = i < dimensions.length
          ? dimensions[i].split(RegExp(r'\s*[xX]\s*'))
          : <String>[];
      _packages.add(_PackageInput(
        length: parts.isNotEmpty ? parts[0] : '',
        width: parts.length > 1 ? parts[1] : '',
        height: parts.length > 2 ? parts[2] : '',
        weight: weight,
      ));
    }

    _goodsController.text = delivery.delivery_goods_description ?? '';
    _merchantController.text = delivery.delivery_merchant_name ?? '';
    _instructionsController.text = delivery.delivery_special_instructions ?? '';
    _hsCodeController.text = delivery.hs_code ?? '';
    _shippingMethod = delivery.delivery_shipping_method;
    _feeController.text =
        delivery.delivery_fee != null ? delivery.delivery_fee!.toString() : '';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pruned) return;
    _pruned = true;

    final scope = _effectiveProviderId;
    if (scope <= 0) return;

    final catalog = context.read<ProductNotifier>().products;
    final valid = catalog
        .where((p) => p.product_provider_id == scope)
        .map((p) => p.id_product ?? 0)
        .toSet();

    _selected.removeWhere((id) => !valid.contains(id));
  }

  int get _effectiveProviderId => widget.providerId > 0
      ? widget.providerId
      : (widget.delivery.delivery_provider_id ?? 0);

  @override
  void dispose() {
    for (final p in _packages) {
      p.dispose();
    }
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _goodsController.dispose();
    _merchantController.dispose();
    _instructionsController.dispose();
    _hsCodeController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final next = _searchController.text.trim();
    if (next == _searchQuery) return;
    setState(() => _searchQuery = next);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _header(l10n),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    KeyedSubtree(
                      key: _productsKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _section(l10n.deliveryDetailsSectionProducts,
                              Icons.inventory_2_outlined),
                          _productSelection(l10n),
                        ],
                      ),
                    ),
                    KeyedSubtree(
                      key: _packagesKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _section(l10n.deliveryDetailsSectionPackages,
                              Icons.inventory_outlined),
                          _packageFields(l10n),
                        ],
                      ),
                    ),
                    _section(l10n.deliveryDetailsSectionShipping,
                        Icons.local_shipping),
                    _shippingFields(l10n),
                    _section(l10n.deliveryDetailsSectionAdditional,
                        Icons.note_outlined),
                    _additionalFields(l10n),
                    const SizedBox(height: 24),
                    _submitButton(l10n),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            splashRadius: 22,
          ),
          Expanded(
            child: Text(
              l10n.deliveryDetailsTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: _isLoading ? null : () => _submit(l10n),
            child: Text(
              l10n.commonSave,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: cs.primary),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // ── Product selection ──

  Widget _productSelection(AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    final productNotifier = context.watch<ProductNotifier>();
    final scope = _effectiveProviderId;

    final allowedIds = widget.initialProductIds.toSet();

    final visibleProducts = productNotifier.products.where((p) {
      final id = p.id_product ?? 0;
      if (id <= 0) return false;
      if (!allowedIds.contains(id)) return false;
      if (scope > 0 && p.product_provider_id != scope) return false;
      return true;
    }).toList();

    final filtered = _searchQuery.isEmpty
        ? visibleProducts
        : visibleProducts.where((p) {
            final q = _searchQuery.toLowerCase();
            return (p.product_name ?? '').toLowerCase().contains(q) ||
                (p.product_brand ?? '').toLowerCase().contains(q) ||
                (p.product_barcode ?? '').toLowerCase().contains(q);
          }).toList();

    final selectedProducts =
        visibleProducts.where((p) => _selected.contains(p.id_product)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (visibleProducts.length > 5) _searchBox(cs, l10n),
        if (visibleProducts.length > 5) const SizedBox(height: 10),
        if (selectedProducts.isNotEmpty) ...[
          _selectionSummary(selectedProducts, l10n),
          const SizedBox(height: 10),
        ],
        if (visibleProducts.isEmpty)
          _emptyCatalog(cs, l10n)
        else if (filtered.isEmpty)
          _noMatches(cs, l10n)
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: filtered.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: cs.outlineVariant.withOpacity(0.3),
                ),
                itemBuilder: (context, i) => _productRow(filtered[i], cs, l10n),
              ),
            ),
          ),
      ],
    );
  }

  Widget _searchBox(ColorScheme cs, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: l10n.deliveryDetailsProductSearchHint,
          prefixIcon: Icon(Icons.search, color: cs.onSurfaceVariant),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.close_rounded,
                      size: 18, color: cs.onSurfaceVariant),
                  onPressed: () => _searchController.clear(),
                ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  Widget _productRow(
    Product product,
    ColorScheme cs,
    AppLocalizations l10n,
  ) {
    final id = product.id_product ?? 0;
    if (id <= 0) return const SizedBox.shrink();

    final selected = _selected.contains(id);
    final stock = product.product_quantity ?? 0;
    final outOfStock = stock <= 0;

    final name = product.product_name?.trim().isNotEmpty == true
        ? product.product_name!
        : l10n.deliveryDetailsProductFallback(id);
    final brand = product.product_brand?.trim() ?? '';

    return Material(
      color: selected ? cs.primary.withOpacity(0.06) : Colors.transparent,
      child: InkWell(
        onTap: outOfStock ? null : () => _toggleProduct(id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? cs.primary : Colors.transparent,
                  border: Border.all(
                    color: selected ? cs.primary : cs.outline.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: selected
                    ? Icon(Icons.check_rounded, size: 14, color: cs.onPrimary)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w600,
                        color: outOfStock
                            ? cs.onSurface.withOpacity(0.4)
                            : cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (brand.isNotEmpty) ...[
                          Flexible(
                            child: Text(
                              brand,
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        _stockPill(stock, cs, l10n),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stockPill(int stock, ColorScheme cs, AppLocalizations l10n) {
    final out = stock <= 0;
    final color = out ? cs.error : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        out ? l10n.deliveryDetailsStockOut : l10n.deliveryDetailsStockIn(stock),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _selectionSummary(
    List<Product> selectedProducts,
    AppLocalizations l10n,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () =>
                setState(() => _selectionExpanded = !_selectionExpanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 18, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.deliveryDetailsProductsSelected(
                          selectedProducts.length),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _selectionExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 20,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _selectionExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: selectedProducts
                          .map((p) => _selectedChip(p, cs, l10n))
                          .toList(),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _selectedChip(
    Product p,
    ColorScheme cs,
    AppLocalizations l10n,
  ) {
    final name = p.product_name?.trim().isNotEmpty == true
        ? p.product_name!
        : l10n.deliveryDetailsProductFallback(p.id_product ?? 0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _toggleProduct(p.id_product ?? 0),
              borderRadius: BorderRadius.circular(50),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(Icons.close_rounded,
                    size: 14, color: cs.onSurfaceVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCatalog(ColorScheme cs, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.inventory_2_outlined,
              color: cs.onSurfaceVariant, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.deliveryDetailsNoProducts,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _noMatches(ColorScheme cs, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.search_off, color: cs.onSurfaceVariant, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.deliveryDetailsNoMatches(_searchQuery),
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => _searchController.clear(),
            child: Text(l10n.commonClear),
          ),
        ],
      ),
    );
  }

  void _toggleProduct(int id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  // ── Packages ──

  Widget _packageFields(AppLocalizations l10n) {
    return Column(
      children: [
        ..._packages.asMap().entries.map((entry) {
          final index = entry.key;
          final package = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _dimension(
                        package.length,
                        l10n.deliveryDetailsDimensionLength,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _dimension(
                        package.width,
                        l10n.deliveryDetailsDimensionWidth,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _dimension(
                        package.height,
                        l10n.deliveryDetailsDimensionHeight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: package.weight,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText:
                              l10n.deliveryDetailsPackageWeightLabel(index + 1),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (value) {
                          final w = double.tryParse(value ?? '');
                          return w == null || w <= 0
                              ? l10n.deliveryDetailsValidationEnterWeight
                              : null;
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: _packages.length == 1
                          ? null
                          : () => setState(() {
                                _packages.removeAt(index).dispose();
                              }),
                      icon: const Icon(Icons.remove_circle_outline),
                      tooltip: l10n.deliveryDetailsRemovePackage,
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _packages.add(_PackageInput())),
            icon: const Icon(Icons.add),
            label: Text(l10n.deliveryDetailsAddPackage),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            l10n.deliveryDetailsPackageSummary(
              _packages.length,
              _totalWeight.toStringAsFixed(2),
            ),
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _dimension(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        final d = double.tryParse(value ?? '');
        return d == null || d <= 0
            ? AppLocalizations.of(context)!.deliveryDetailsValidationRequired
            : null;
      },
    );
  }

  Widget _shippingFields(AppLocalizations l10n) {
    return Column(
      children: [
        TextFormField(
          controller: _feeController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: l10n.deliveryDetailsFeeLabel,
            helperText: l10n.deliveryDetailsFeeHelper,
            prefixIcon: const Icon(Icons.payments_outlined),
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return null;
            final f = double.tryParse(value);
            if (f == null) return l10n.deliveryDetailsValidationEnterAmount;
            if (f < 0) return l10n.deliveryDetailsValidationFeeNegative;
            return null;
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _shippingMethod,
          decoration: InputDecoration(
            labelText: l10n.deliveryDetailsShippingMethodLabel,
            border: const OutlineInputBorder(),
          ),
          items: _shippingMethods
              .map((method) => DropdownMenuItem(
                    value: method,
                    child: Text(
                      DeliveryShippingConfig.labelFor(method, l10n),
                    ),
                  ))
              .toList(),
          onChanged: (value) => setState(() => _shippingMethod = value!),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _hsCodeController,
          decoration: InputDecoration(
            labelText: l10n.deliveryDetailsHsCodeLabel,
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _additionalFields(AppLocalizations l10n) {
    return Column(
      children: [
        TextFormField(
          controller: _merchantController,
          decoration: InputDecoration(
            labelText: l10n.deliveryDetailsMerchantLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _goodsController,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: l10n.deliveryDetailsGoodsLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _instructionsController,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: l10n.deliveryDetailsInstructionsLabel,
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _submitButton(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () => _submit(l10n),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          l10n.deliveryDetailsSaveButton,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  List<int> _validSelectedIds() {
    final scope = _effectiveProviderId;
    final catalog = context.read<ProductNotifier>().products;
    return catalog
        .where((p) =>
            _selected.contains(p.id_product) &&
            (scope <= 0 || p.product_provider_id == scope))
        .map((p) => p.id_product ?? 0)
        .where((id) => id > 0)
        .toList();
  }

  Map<String, dynamic> _buildFields() {
    final dimensions = _packages
        .map((p) => [
              p.length.text.trim(),
              p.width.text.trim(),
              p.height.text.trim(),
            ].join('x'))
        .join(', ');

    final selectedIds = _validSelectedIds();
    final feeText = _feeController.text.trim();

    return {
      'delivery_package_count': _packages.length,
      'delivery_total_weight': _totalWeight,
      'delivery_cargo_dimensions': dimensions,
      'delivery_shipping_method': _shippingMethod,
      if (feeText.isNotEmpty && double.tryParse(feeText) != null)
        'delivery_fee': double.parse(feeText),
      if (_goodsController.text.trim().isNotEmpty)
        'delivery_goods_description': _goodsController.text.trim(),
      if (_merchantController.text.trim().isNotEmpty)
        'delivery_merchant_name': _merchantController.text.trim(),
      if (_instructionsController.text.trim().isNotEmpty)
        'delivery_special_instructions': _instructionsController.text.trim(),
      if (_hsCodeController.text.trim().isNotEmpty)
        'hs_code': _hsCodeController.text.trim(),
      if (selectedIds.isNotEmpty) 'selected_product_ids': selectedIds,
    };
  }

  Future<void> _submit(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;

    final fields = _buildFields();
    setState(() => _isLoading = true);

    try {
      final success = await widget.onCommit(fields);
      if (!mounted) return;
      if (success) {
        Navigator.pop(context, fields);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.deliveryDetailsSaveFailed),
          backgroundColor: Colors.red,
        ));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.deliveryDetailsSaveError(error.toString())),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _PackageInput {
  final length = TextEditingController();
  final width = TextEditingController();
  final height = TextEditingController();
  final weight = TextEditingController();

  _PackageInput({
    String length = '',
    String width = '',
    String height = '',
    double? weight,
  }) {
    this.length.text = length;
    this.width.text = width;
    this.height.text = height;
    if (weight != null) this.weight.text = weight.toString();
  }

  void dispose() {
    length.dispose();
    width.dispose();
    height.dispose();
    weight.dispose();
  }
}
