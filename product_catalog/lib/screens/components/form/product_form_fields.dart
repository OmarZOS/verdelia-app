// lib/screens/components/form/product_form_fields.dart

import 'package:app_constants/app_constants.dart';
import 'package:app_constants/app_routes.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/business/Supplier.dart';
import 'package:verdelia_core/business/iProduct.dart';
import 'package:verdelia_core/business/product_form_data.dart';
import 'package:event/assistant_change_notifier.dart';
import 'package:event/components/lib.dart';
import 'package:event/personnel_notifier.dart';
import 'package:event/product_change_notifier.dart';
import 'package:event/supplier_change_notifier.dart';
import 'package:event/user_change_notifier.dart';
import 'package:ui/components/hierarchical_category_picker.dart';
import 'package:ui/components/pricing_config_card.dart';
import 'package:ui/components/supplier/supplier_picker.dart';
import 'package:product_catalog/screens/components/form/form_controllers.dart';
import 'package:product_catalog/screens/components/form/pricing_state.dart';
import 'package:product_catalog/screens/components/smart_form.dart';

class ProductFormFields extends StatefulWidget {
  final ProductFormData formData;
  final FormControllers controllers;
  final GlobalKey<FormState> formKey;
  final bool isUpdate;

  const ProductFormFields({
    super.key,
    required this.formData,
    required this.controllers,
    required this.formKey,
    required this.isUpdate,
  });

  @override
  State<ProductFormFields> createState() => _ProductFormFieldsState();
}

class _ProductFormFieldsState extends State<ProductFormFields> {
  // Local aliases so every method body below compiles unchanged.
  ProductFormData get formData => widget.formData;
  FormControllers get controllers => widget.controllers;
  GlobalKey<FormState> get formKey => widget.formKey;
  bool get isUpdate => widget.isUpdate;

  @override
  void initState() {
    super.initState();
    context.read<PricingState>().load(
          basePrice: formData.productBasePrice ?? 0,
          finalPrice: formData.price ?? 0,
          mode: PricingMode.byFinalPrice,
        );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProductNotifier>().fetchCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final assistantNotifier = context.watch<AssistantNotifier>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ---------- Basic identity ----------

        _buildSmartField(
          context: context,
          fieldId: ProductAssistedFields.IPRODUCT_NAME,
          controller: controllers.name,
          label: loc.productNameTxt,
          validator: (value) =>
              (value?.isEmpty ?? true) ? loc.pleaseInputProductNameMsg : null,
        ),

        const SizedBox(height: 16),

        _buildSmartField(
          context: context,
          fieldId: ProductAssistedFields.IPRODUCT_BRAND,
          controller: controllers.brand,
          label: loc.productBrandTxt,
          validator: (value) =>
              (value?.isEmpty ?? true) ? loc.pleaseInputProductBrandMsg : null,
        ),

        const SizedBox(height: 16),

        _buildBarcodeField(context, loc),

        const SizedBox(height: 16),

        // ---------- Quantity & quantifier ----------

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildSmartField(
                context: context,
                fieldId: ProductAssistedFields.QUANTITY,
                controller: controllers.quantity,
                label: loc.productQuantityText,
                keyboardType: TextInputType.number,
                validator: _validateQuantity,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: _buildQuantifierField(context, loc),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ---------- Description ----------

        _buildSmartField(
          context: context,
          fieldId: ProductAssistedFields.DESCRIPTION,
          controller: controllers.description,
          label: loc.productDescriptionText,
          maxLines: 3,
          validator: _validateDescription,
        ),

        const SizedBox(height: 24),

        // ---------- Category ----------

        _buildCategoryPicker(context),

        const SizedBox(height: 24),

        // ---------- Supplier ----------

        _buildSupplierPicker(context),

        const SizedBox(height: 24),

        // ---------- Pricing (base + tax + margin + final + AI) ----------

        _buildPricingSection(context, assistantNotifier, loc),

        const SizedBox(height: 24),

        // ---------- Visibility ----------

        _buildVisibilityToggle(context),
      ],
    );
  }

  // ==================================================================
  // Pricing section
  // ==================================================================

  Widget _buildPricingSection(
    BuildContext context,
    AssistantNotifier assistantNotifier,
    AppLocalizations loc,
  ) {
    final priceField = assistantNotifier
        .getFieldData(ProductAssistedFields.IPRODUCT_ESTIMATED_PRICE_DA);
    final hasAIPrice = priceField?.value != null && !priceField!.isEdited;
    final aiPrice =
        hasAIPrice ? double.tryParse(priceField!.value.toString()) : null;

    return Consumer<PricingState>(
      builder: (context, pricingState, _) {
        // Single helper: whatever PricingState derives, push it into the
        // external controllers and formData. Called after every mutation
        // so the two representations never diverge.
        void syncOut() {
          final finalPrice = pricingState.finalPrice;
          final basePrice = pricingState.basePrice;

          formData.price = finalPrice;
          formData.productBasePrice = basePrice;

          controllers.price.text = finalPrice.toStringAsFixed(2);
          controllers.basePrice.text = basePrice.toStringAsFixed(2);
        }

        return PricingConfigCard(
          basePrice: pricingState.basePrice,
          taxPercentage: pricingState.taxPercentage,
          profitMargin: pricingState.profitMargin,
          finalPrice: pricingState.finalPrice,
          mode: pricingState.mode,
          aiPrice: aiPrice,
          onBasePriceChanged: (price) {
            assistantNotifier.markFieldAsEdited(
              ProductAssistedFields.IPRODUCT_ESTIMATED_PRICE_DA,
            );
            pricingState.basePrice = price;
            syncOut();
          },
          onTaxPercentageChanged: (tax) {
            assistantNotifier.markFieldAsEdited(
              ProductAssistedFields.IPRODUCT_ESTIMATED_PRICE_DA,
            );
            pricingState.taxPercentage = tax;
            syncOut();
          },
          onProfitMarginChanged: (margin) {
            assistantNotifier.markFieldAsEdited(
              ProductAssistedFields.IPRODUCT_ESTIMATED_PRICE_DA,
            );
            pricingState.profitMargin = margin;
            syncOut();
          },
          onFinalPriceChanged: (price) {
            assistantNotifier.markFieldAsEdited(
              ProductAssistedFields.IPRODUCT_ESTIMATED_PRICE_DA,
            );
            pricingState.finalPrice = price;
            syncOut();
          },
          onModeChanged: (mode) {
            assistantNotifier.markFieldAsEdited(
              ProductAssistedFields.IPRODUCT_ESTIMATED_PRICE_DA,
            );
            pricingState.mode = mode;
            syncOut();
          },
          onAcceptAiPrice: () {
            final ai = aiPrice;
            if (ai == null || ai <= 0) return;
            pricingState.applyAiPrice(ai);
            syncOut();
          },
        );
      },
    );
  }

  // ==================================================================
  // Quantifier
  // ==================================================================

  Widget _buildQuantifierField(BuildContext context, AppLocalizations loc) {
    final options = AppConstants.productUnits;
    final current = (formData.quantifier ?? 'pc').trim();

    return SmartDropdownField<String>(
      fieldId: ProductAssistedFields.QUANTIFIER,
      value: options.contains(current) ? current : 'pc',
      labelText: loc.productQuantifierTxt,
      items: options
          .map(
            (unit) => DropdownMenuItem<String>(
              value: unit,
              child: Text(_localizedQuantifier(unit, loc)),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          formData.quantifier = value;
        });
      },
    );
  }

  String _localizedQuantifier(String unit, AppLocalizations loc) {
    return switch (unit) {
      'g' => loc.quantifier_g,
      'kg' => loc.quantifier_kg,
      'mg' => loc.quantifier_mg,
      'L' => loc.quantifier_L,
      'mL' => loc.quantifier_mL,
      'pc' => loc.quantifier_pc,
      'pkg' => loc.quantifier_pkg,
      'box' => loc.quantifier_box,
      'bag' => loc.quantifier_bag,
      'slice' => loc.quantifier_slice,
      'cup' => loc.quantifier_cup,
      _ => unit,
    };
  }

  // ==================================================================
  // Visibility
  // ==================================================================

  Widget _buildVisibilityToggle(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final current = (formData.visibility ?? 'VISIBLE').toUpperCase();
    final isVisible = current == 'VISIBLE';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(
            isVisible
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 18,
            color: isVisible ? cs.primary : cs.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Visibility',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  isVisible
                      ? 'Buyers can see this product'
                      : 'Hidden from the catalog',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isVisible,
            onChanged: _toggleVisibility,
          ),
        ],
      ),
    );
  }

  void _toggleVisibility(bool isVisible) {
    setState(() {
      formData.visibility = isVisible ? 'VISIBLE' : 'HIDDEN';
    });
  }

  // ==================================================================
  // Generic smart field
  // ==================================================================

  Widget _buildSmartField({
    required BuildContext context,
    required String fieldId,
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return Consumer<AssistantNotifier>(
      builder: (context, assistantNotifier, child) {
        return SmartFormField(
          fieldId: fieldId,
          controller: controller,
          labelText: label,
          validator: validator!,
          onSaved: (value) => _onFieldSaved(fieldId, value),
          keyboardType: keyboardType,
          suffixIcon: suffixIcon,
          maxLines: maxLines,
          onChanged: onChanged,
        );
      },
    );
  }

  void _onFieldSaved(String fieldId, String? value) {
    switch (fieldId) {
      case ProductAssistedFields.IPRODUCT_NAME:
        formData.productName = value;
        break;
      case ProductAssistedFields.IPRODUCT_BRAND:
        formData.productBrand = value;
        break;
      case ProductAssistedFields.IPRODUCT_BARCODE:
        formData.productBarcode = value;
        break;
      case ProductAssistedFields.IPRODUCT_BASE_PRICE:
        formData.productBasePrice = double.tryParse(value ?? '0.0');
        break;
      case ProductAssistedFields.IPRODUCT_ESTIMATED_PRICE_DA:
        formData.price = double.tryParse(value ?? '0.0');
        break;
      case ProductAssistedFields.QUANTITY:
        formData.quantity = int.tryParse(value ?? '0');
        break;
      case ProductAssistedFields.DESCRIPTION:
        formData.productDescription = value;
        break;
    }
  }

  // ==================================================================
  // Validators
  // ==================================================================

  String? _validateQuantity(String? value) {
    if (value?.isEmpty == true) return 'Please enter quantity';
    final parsed = int.tryParse(value ?? '');
    if (parsed == null) return 'Please enter a valid number';
    if (parsed < 0) return 'Quantity cannot be negative';
    return null;
  }

  String? _validateDescription(String? value) {
    if (value?.isEmpty == true) return 'Please enter description';
    if (value!.length >= 300) {
      return 'Description too long (max 300 characters)';
    }
    return null;
  }

  // ==================================================================
  // Category & supplier
  // ==================================================================

  Widget _buildCategoryPicker(BuildContext context) {
    final productCategories =
        context.watch<ProductNotifier>().productCategories;
    if (productCategories.isEmpty) return const SizedBox.shrink();

    final languageCode = Localizations.localeOf(context).languageCode;
    return HierarchicalCategoryPicker(
      label: AppLocalizations.of(context)!.categoryText,
      selectedId:
          formData.categoryId ?? productCategories.first.productCategoryId,
      options: productCategories
          .map(
            (category) => HierarchicalCategoryOption(
              id: category.productCategoryId,
              path: category.productCategoryDesc,
              leafLabel: category.nameFor(languageCode),
            ),
          )
          .toList(),
      onChanged: (id) {
        setState(() {
          formData.typeId = id.leafId;
          formData.categoryId = id.leafId;
        });
      },
      iconAsset:
          'assets/icons/${formData.categoryId ?? productCategories.first.productCategoryId}.svg',
      package: 'product_catalog',
    );
  }

  Widget _buildSupplierPicker(BuildContext context) {
    final supplierNotifier = context.watch<SupplierChangeNotifier>();

    if (formData.lockProvider && formData.selectedProviderId > 0) {
      final supplier = supplierNotifier.suppliers.firstWhere(
        (s) => s.idProductProvider == formData.selectedProviderId,
      );
      final name = supplier?.providerName ?? '#${formData.selectedProviderId}';
      return _LockedSupplierRow(name: name);
    }

    final suppliers = supplierNotifier.suppliers.whereType<Supplier>().toList();
    if (suppliers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.supplier,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
        ),
        const SizedBox(height: 8),
        SupplierPicker(
          suppliers: suppliers,
          initialSelection: suppliers.firstWhere(
            (s) => s.idProductProvider == formData.selectedProviderId,
          ),
          onSupplierChanged: (selectedSupplier) {
            setState(() {
              formData.selectedProviderId = selectedSupplier.idProductProvider;
              formData.providerId = selectedSupplier.idProductProvider;
            });
          },
        ),
      ],
    );
  }

  // ==================================================================
  // Barcode
  // ==================================================================

  Widget _buildBarcodeField(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final assistantNotifier = context.watch<AssistantNotifier>();

    return _buildSmartField(
      context: context,
      fieldId: ProductAssistedFields.IPRODUCT_BARCODE,
      controller: controllers.barcode,
      label: localizations.productBarcodeTxt,
      validator: (value) => value?.isEmpty == true
          ? localizations.pleaseInputProductBarcodeMsg
          : null,
      suffixIcon: IconButton(
        icon: Icon(
          CupertinoIcons.barcode_viewfinder,
          color: Theme.of(context).colorScheme.primary,
        ),
        onPressed: assistantNotifier.isLoading
            ? null
            : () => _handleBarcodeScanning(context),
      ),
    );
  }

  Future<void> _handleBarcodeScanning(BuildContext context) async {
    final String? scannedCode = await Navigator.pushNamed(
      context,
      AppRoutes.productScanPage,
    ) as String?;

    if (scannedCode != null && scannedCode.isNotEmpty) {
      final assistantNotifier = context.read<AssistantNotifier>();

      assistantNotifier.setFieldData(
        fieldId: ProductAssistedFields.IPRODUCT_BARCODE,
        value: scannedCode,
        source: DataSource.userInput,
      );

      formData.productBarcode = scannedCode;
      controllers.barcode.text = scannedCode;

      await assistantNotifier.fetchProductByBarcode(scannedCode);
      _syncFormWithAiData(context);
    }
  }

  void _syncFormWithAiData(BuildContext context) {
    final assistantNotifier = context.read<AssistantNotifier>();
    final IProduct? currentProduct = assistantNotifier.product;

    if (currentProduct == null || !context.mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      formData.assistantOrigin = currentProduct;

      final nameField =
          assistantNotifier.getFieldData(ProductAssistedFields.IPRODUCT_NAME);
      final brandField =
          assistantNotifier.getFieldData(ProductAssistedFields.IPRODUCT_BRAND);
      final priceField = assistantNotifier
          .getFieldData(ProductAssistedFields.IPRODUCT_ESTIMATED_PRICE_DA);

      setState(() {
        if (nameField != null && !nameField.isEdited) {
          controllers.name.text = nameField.value?.toString() ?? '';
          formData.productName = nameField.value?.toString();
        }

        if (brandField != null && !brandField.isEdited) {
          controllers.brand.text = brandField.value?.toString() ?? '';
          formData.productBrand = brandField.value?.toString();
        }

        if (priceField != null && !priceField.isEdited) {
          controllers.price.text = priceField.value?.toString() ?? '';
          formData.price =
              double.tryParse(priceField.value?.toString() ?? '0.0');
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Product data loaded from barcode'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    });
  }
}

// ==================================================================
// Locked supplier row
// ==================================================================

class _LockedSupplierRow extends StatelessWidget {
  final String name;

  const _LockedSupplierRow({required this.name});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.supplier,
          style: theme.textTheme.labelMedium?.copyWith(
            color: cs.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Icon(Icons.storefront_rounded, size: 18, color: cs.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.lock_outline, size: 16, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ],
    );
  }
}
