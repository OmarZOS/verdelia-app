// lib/provider_store/components/delivery/DeliveryDetailsSheet.dart

import 'package:event/delivery_change_notifier.dart';
import 'package:event/product_change_notifier.dart';
import 'package:flutter/material.dart';
import 'package:verdelia_core/business/Delivery.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:provider_store/components/orders/details/delivery_details_screen.dart';

/// Edit-only sheet for a delivery's metadata: packages, shipping
/// method, broker, goods description, and the products attached to
/// this delivery. Commits through [onCommit].
///
/// Does not advance the delivery's status. Transitions are handled
/// by `DeliveryTransitionSheet`.
class DeliveryDetailsSheet extends StatefulWidget {
  final DeliveryChangeNotifier notifier;
  final Delivery delivery;
  final int providerId;
  final List<int> initialProductIds;
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
  final _weightController = TextEditingController();

  final Set<int> _selected = {};

  String _shippingMethod = 'standard';
  String _searchQuery = '';
  bool _isLoading = false;
  bool _selectionExpanded = false;
  bool _pruned = false;

  int? _selectedBrokerId;

  /// Total cargo weight, in kilograms. Kept as `double` internally
  /// because it aggregates user-typed measurements (parsed from text
  /// fields via `double.tryParse`), and the only places it crosses a
  /// type boundary are reads from `Delivery.delivery_total_weight`
  /// (now `Decimal`) and writes back to the wire payload (which the
  /// server still accepts as a JSON number).
  double? _totalWeight;

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

    // `Delivery.delivery_total_weight` is `Decimal?` after the
    // migration; convert to `double` for the internal accumulator.
    // The value is a measurement, not money, so `double` is fine
    // here — the read is lossless for any two-decimal kilogram
    // value the backend could store.
    _totalWeight = delivery.delivery_total_weight?.toDouble();
    _weightController.text = _totalWeight?.toString() ?? '';

    // Each package is one entry in the comma-separated list. Each
    // entry has the shape `<L>x<W>x<H><unit>:<weight><weight_unit>`,
    // e.g. `5x5x5m:1.5kg`. The parser tolerates both the new form
    // and the legacy `<L>x<W>x<H>` form (no weight, unit defaults to
    // meters).
    final rawDimensions = delivery.delivery_cargo_dimensions ?? '';
    if (rawDimensions.trim().isNotEmpty) {
      final segments = rawDimensions
          .split(RegExp(r'\s*,\s*'))
          .where((s) => s.trim().isNotEmpty);
      for (final segment in segments) {
        _packages.add(_PackageInput.fromWire(segment));
      }
    }
    if (_packages.isEmpty) {
      _packages.add(_PackageInput());
    }

    _goodsController.text = delivery.delivery_goods_description ?? '';
    _merchantController.text = delivery.delivery_merchant_name ?? '';
    _instructionsController.text = delivery.delivery_special_instructions ?? '';
    _hsCodeController.text = delivery.hs_code ?? '';
    _shippingMethod = delivery.delivery_shipping_method;

    // `Delivery.delivery_fee` is `Decimal?` after the migration.
    // `.toString()` is deterministic — `Decimal("25.00")` → `"25.00"`,
    // `Decimal("25")` → `"25"`. The text field re-parses it on save,
    // so either form round-trips correctly.
    _feeController.text = delivery.delivery_fee?.toString() ?? '';

    final rawBrokerId = delivery.delivery_broker_id;
    _selectedBrokerId =
        (rawBrokerId == null || rawBrokerId == 0) ? null : rawBrokerId;

    // Load brokers once. If the notifier already has them, this is a
    // no-op; the picker's retry button covers the failure case.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.notifier.fetchBrokers();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pruned) return;
    _pruned = true;

    final scope = _effectiveProviderId;
    if (scope <= 0) return;

    final valid = context
        .read<ProductNotifier>()
        .products
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
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    _goodsController.dispose();
    _merchantController.dispose();
    _instructionsController.dispose();
    _hsCodeController.dispose();
    _feeController.dispose();
    _weightController.dispose();
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
                    _section(l10n.deliveryDetailsSectionProducts,
                        Icons.inventory_2_outlined),
                    _productSelection(l10n),
                    _section(l10n.deliveryDetailsSectionPackages,
                        Icons.inventory_outlined),
                    _packageFields(l10n),
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

  // ── Products ──

  Widget _productSelection(AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    final scope = _effectiveProviderId;
    final allowed = widget.initialProductIds.toSet();

    final visible = context.watch<ProductNotifier>().products.where((p) {
      final id = p.id_product ?? 0;
      return id > 0 &&
          allowed.contains(id) &&
          (scope <= 0 || p.product_provider_id == scope);
    }).toList();

    final filtered = _searchQuery.isEmpty
        ? visible
        : visible.where((p) {
            final q = _searchQuery.toLowerCase();
            return (p.product_name ?? '').toLowerCase().contains(q) ||
                (p.product_brand ?? '').toLowerCase().contains(q) ||
                (p.product_barcode ?? '').toLowerCase().contains(q);
          }).toList();

    final selected =
        visible.where((p) => _selected.contains(p.id_product)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (visible.length > 5) _searchBox(cs, l10n),
        if (visible.length > 5) const SizedBox(height: 10),
        if (selected.isNotEmpty) ...[
          _selectionSummary(selected, l10n),
          const SizedBox(height: 10),
        ],
        if (visible.isEmpty)
          _emptyBox(cs, l10n.deliveryDetailsNoProducts,
              icon: Icons.inventory_2_outlined)
        else if (filtered.isEmpty)
          _emptyBox(cs, l10n.deliveryDetailsNoMatches(_searchQuery),
              icon: Icons.search_off,
              action: TextButton(
                onPressed: () => _searchController.clear(),
                child: Text(l10n.commonClear),
              ))
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
                itemBuilder: (_, i) => _productRow(filtered[i], cs, l10n),
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
    final name = (product.product_name?.trim().isNotEmpty ?? false)
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
        style:
            TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _selectionSummary(List<Product> selected, AppLocalizations l10n) {
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
                      l10n.deliveryDetailsProductsSelected(selected.length),
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
                    child: Icon(Icons.expand_more_rounded,
                        size: 20, color: cs.onPrimaryContainer),
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
                      children: selected
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

  Widget _selectedChip(Product p, ColorScheme cs, AppLocalizations l10n) {
    final name = (p.product_name?.trim().isNotEmpty ?? false)
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
          InkWell(
            onTap: () => _toggleProduct(p.id_product ?? 0),
            borderRadius: BorderRadius.circular(50),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(Icons.close_rounded,
                  size: 14, color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyBox(
    ColorScheme cs,
    String message, {
    required IconData icon,
    Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: cs.onSurfaceVariant, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ),
          if (action != null) action,
        ],
      ),
    );
  }

  void _toggleProduct(int id) {
    setState(() {
      if (!_selected.add(id)) _selected.remove(id);
    });
  }

  // ── Packages ──

  Widget _packageFields(AppLocalizations l10n) {
    return Column(
      children: [
        for (var i = 0; i < _packages.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _packageRow(i, l10n),
          ),
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
              _totalWeight?.toString() ?? '—',
            ),
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _packageRow(int index, AppLocalizations l10n) {
    final pkg = _packages[index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _dimensionField(
                controller: pkg.length,
                label: l10n.deliveryDetailsDimensionLength,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 2,
              child: _dimensionField(
                controller: pkg.width,
                label: l10n.deliveryDetailsDimensionWidth,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 2,
              child: _dimensionField(
                controller: pkg.height,
                label: l10n.deliveryDetailsDimensionHeight,
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 72,
              child: DropdownButtonFormField<String>(
                value: pkg.unit,
                decoration: InputDecoration(
                  labelText: l10n.deliveryDetailsUnitLabel,
                  border: const OutlineInputBorder(),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'm', child: Text('m')),
                  DropdownMenuItem(value: 'cm', child: Text('cm')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => pkg.unit = v);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: TextFormField(
                controller: pkg.weight,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.deliveryDetailsPackageWeightLabel(index + 1),
                  border: const OutlineInputBorder(),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return null;
                  final w = double.tryParse(text);
                  return (w == null || w < 0)
                      ? l10n.deliveryDetailsValidationEnterWeight
                      : null;
                },
                onChanged: (_) => setState(() {
                  _totalWeight = _sumPackageWeights();
                }),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 78,
              child: DropdownButtonFormField<String>(
                value: pkg.weightUnit,
                decoration: InputDecoration(
                  labelText: l10n.deliveryDetailsWeightUnitLabel,
                  border: const OutlineInputBorder(),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'kg', child: Text('kg')),
                  DropdownMenuItem(value: 'g', child: Text('g')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    pkg.weightUnit = v;
                    _totalWeight = _sumPackageWeights();
                  });
                },
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: _packages.length == 1
                  ? null
                  : () => setState(() {
                        _packages.removeAt(index).dispose();
                        _totalWeight = _sumPackageWeights();
                      }),
              icon: const Icon(Icons.remove_circle_outline),
              tooltip: l10n.deliveryDetailsRemovePackage,
            ),
          ],
        ),
      ],
    );
  }

  Widget _dimensionField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
      validator: (value) {
        final d = double.tryParse(value ?? '');
        return (d == null || d <= 0)
            ? AppLocalizations.of(context)!.deliveryDetailsValidationRequired
            : null;
      },
    );
  }

  /// Sum every package's weight, normalized to kilograms. Packages
  /// entered in grams contribute `weight / 1000`.
  ///
  /// Stays `double` because weight is a measurement, not money, and
  /// the only place this value crosses a `Decimal` boundary is the
  /// read from `Delivery.delivery_total_weight` (already converted to
  /// `double` in `initState`) and the write back to the wire payload.
  double? _sumPackageWeights() {
    double totalKg = 0;
    bool any = false;
    for (final pkg in _packages) {
      final raw = double.tryParse(pkg.weight.text.trim());
      if (raw == null) continue;
      any = true;
      totalKg += pkg.weightUnit == 'g' ? raw / 1000 : raw;
    }
    return any ? totalKg : null;
  }

  // ── Shipping ──

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
            final text = value?.trim() ?? '';
            if (text.isEmpty) return null;
            final f = double.tryParse(text);
            if (f == null) return l10n.deliveryDetailsValidationEnterAmount;
            if (f < 0) return l10n.deliveryDetailsValidationFeeNegative;
            return null;
          },
        ),
        const SizedBox(height: 12),
        _brokerPicker(l10n),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _shippingMethod,
          decoration: InputDecoration(
            labelText: l10n.deliveryDetailsShippingMethodLabel,
            border: const OutlineInputBorder(),
          ),
          items: _shippingMethods
              .map((m) => DropdownMenuItem(
                    value: m,
                    child: Text(DeliveryShippingConfig.labelFor(m, l10n)),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _shippingMethod = v!),
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

  Widget _brokerPicker(AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;

    final notifier = context.watch<DeliveryChangeNotifier>();
    final brokers = notifier.brokers;
    final loading = notifier.isBrokersLoading;
    final error = notifier.brokerError;

    final ids = brokers.map((b) => b.id).toSet();
    final value = (_selectedBrokerId != null && ids.contains(_selectedBrokerId))
        ? _selectedBrokerId
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<int?>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.deliveryDetailsBrokerLabel,
            prefixIcon: const Icon(Icons.store_mall_directory_outlined),
            border: const OutlineInputBorder(),
            helperText: _brokerHelper(l10n, brokers.length, loading, error),
            helperMaxLines: 2,
          ),
          items: [
            DropdownMenuItem<int?>(
              value: null,
              child: Text(
                l10n.deliveryDetailsBrokerNone,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            ...brokers.map((b) => DropdownMenuItem<int?>(
                  value: b.id,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          b.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!b.verified) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: cs.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            l10n.deliveryDetailsBrokerUnverified,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: cs.error,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                )),
          ],
          onChanged:
              loading ? null : (v) => setState(() => _selectedBrokerId = v),
        ),
        if (error != null && brokers.isEmpty && !loading)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => widget.notifier.refreshBrokers(),
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(l10n.commonRetry),
              ),
            ),
          ),
      ],
    );
  }

  String? _brokerHelper(
    AppLocalizations l10n,
    int count,
    bool loading,
    String? error,
  ) {
    if (loading) return l10n.deliveryDetailsBrokerLoading;
    if (error != null) return l10n.deliveryDetailsBrokerLoadFailed;
    if (count == 0) return l10n.deliveryDetailsBrokerNoneAvailable;
    return l10n.deliveryDetailsBrokerHelper(count);
  }

  // ── Additional ──

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

  // ── Commit ──

  List<int> _validSelectedIds() {
    final scope = _effectiveProviderId;
    return context
        .read<ProductNotifier>()
        .products
        .where((p) =>
            _selected.contains(p.id_product) &&
            (scope <= 0 || p.product_provider_id == scope))
        .map((p) => p.id_product ?? 0)
        .where((id) => id > 0)
        .toList();
  }

  Map<String, dynamic> _buildFields() {
    // Serialize packages to the compact wire form:
    //
    //     <L>x<W>x<H><unit>:<weight><weight_unit>
    //
    // One entry per package, joined with `, `.
    final dimensionsWire =
        _packages.map((p) => p.toWire()).where((s) => s.isNotEmpty).join(', ');

    final selectedIds = _validSelectedIds();
    final feeText = _feeController.text.trim();

    return {
      'delivery_package_count': _packages.length,
      // `_totalWeight` is `double?` internally; the wire payload
      // takes a JSON number, which is what `double` produces.
      'delivery_total_weight': _totalWeight ?? _sumPackageWeights(),
      'delivery_cargo_dimensions': dimensionsWire,
      'delivery_shipping_method': _shippingMethod,
      'delivery_broker_id': _selectedBrokerId,
      // The server model for `delivery_fee` is `Optional[float]`; a
      // `double` is the right wire type. `Delivery.delivery_fee` is
      // `Decimal?` after the client migration, but the write path
      // still emits a JSON number.
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
          content: Text(l10n.deliveryDetailsSaveFailed),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

/// A single package's input state.
class _PackageInput {
  final TextEditingController length;
  final TextEditingController width;
  final TextEditingController height;
  final TextEditingController weight;

  String unit;
  String weightUnit;

  _PackageInput({
    String length = '',
    String width = '',
    String height = '',
    String weight = '',
    this.unit = 'm',
    this.weightUnit = 'kg',
  })  : length = TextEditingController(text: length),
        width = TextEditingController(text: width),
        height = TextEditingController(text: height),
        weight = TextEditingController(text: weight);

  factory _PackageInput.fromWire(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return _PackageInput();

    final halves = trimmed.split(':');
    final dimsPart = halves.isNotEmpty ? halves[0].trim() : '';
    final weightPart = halves.length > 1 ? halves[1].trim() : '';

    String lengthText = '';
    String widthText = '';
    String heightText = '';
    String unit = 'm';
    final dimMatch = RegExp(
      r'^(\d+(?:\.\d+)?)\s*[xX]\s*(\d+(?:\.\d+)?)\s*[xX]\s*(\d+(?:\.\d+)?)\s*([a-zA-Z]*)$',
    ).firstMatch(dimsPart);
    if (dimMatch != null) {
      lengthText = dimMatch.group(1)!;
      widthText = dimMatch.group(2)!;
      heightText = dimMatch.group(3)!;
      final parsedUnit = dimMatch.group(4)?.toLowerCase() ?? '';
      if (parsedUnit == 'cm') unit = 'cm';
    }

    String weightText = '';
    String weightUnit = 'kg';
    if (weightPart.isNotEmpty) {
      final wMatch = RegExp(
        r'^(\d+(?:\.\d+)?)\s*(kg|g)?$',
        caseSensitive: false,
      ).firstMatch(weightPart);
      if (wMatch != null) {
        weightText = wMatch.group(1)!;
        final parsedUnit = wMatch.group(2)?.toLowerCase() ?? '';
        if (parsedUnit == 'g') weightUnit = 'g';
      }
    }

    return _PackageInput(
      length: lengthText,
      width: widthText,
      height: heightText,
      weight: weightText,
      unit: unit,
      weightUnit: weightUnit,
    );
  }

  String toWire() {
    final l = length.text.trim();
    final w = width.text.trim();
    final h = height.text.trim();

    if (l.isEmpty && w.isEmpty && h.isEmpty) return '';

    final weightText = weight.text.trim();
    final wPart = weightText.isEmpty ? '' : ':$weightText$weightUnit';

    return '${l}x${w}x${h}$unit$wPart';
  }

  void dispose() {
    length.dispose();
    width.dispose();
    height.dispose();
    weight.dispose();
  }
}
