// lib/ui/components/pricing_config_card.dart

import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:app_constants/app_constants.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

class PricingConfigCard extends StatefulWidget {
  /// Base price, in [Decimal].
  final Decimal basePrice;

  /// Tax percentage (e.g. `19` for 19%), in [Decimal].
  final Decimal taxPercentage;

  /// Profit margin percentage (e.g. `25` for 25%), in [Decimal].
  final Decimal profitMargin;

  /// Final sale price, in [Decimal].
  final Decimal finalPrice;

  final PricingMode mode;

  /// AI-suggested final price, in [Decimal]. Null when no suggestion.
  final Decimal? aiPrice;

  final ValueChanged<Decimal> onBasePriceChanged;
  final ValueChanged<Decimal> onTaxPercentageChanged;
  final ValueChanged<Decimal> onProfitMarginChanged;
  final ValueChanged<Decimal> onFinalPriceChanged;
  final ValueChanged<PricingMode> onModeChanged;

  final VoidCallback onAcceptAiPrice;

  final Duration debounce;

  const PricingConfigCard({
    super.key,
    required this.basePrice,
    required this.taxPercentage,
    required this.profitMargin,
    required this.finalPrice,
    required this.mode,
    required this.onBasePriceChanged,
    required this.onTaxPercentageChanged,
    required this.onProfitMarginChanged,
    required this.onFinalPriceChanged,
    required this.onModeChanged,
    required this.onAcceptAiPrice,
    this.aiPrice,
    this.debounce = const Duration(milliseconds: 400),
  });

  @override
  State<PricingConfigCard> createState() => _PricingConfigCardState();
}

class _PricingConfigCardState extends State<PricingConfigCard> {
  late final TextEditingController _basePriceController;
  late final TextEditingController _taxController;
  late final TextEditingController _profitController;
  late final TextEditingController _finalPriceController;

  final _basePriceFocus = FocusNode();
  final _taxFocus = FocusNode();
  final _profitFocus = FocusNode();
  final _finalPriceFocus = FocusNode();

  Timer? _debounce;
  String? _pendingField;

  final Map<String, String> _lastRendered = {
    'base': '',
    'tax': '',
    'profit': '',
    'final': '',
  };

  @override
  void initState() {
    super.initState();

    _basePriceController = _makeController(widget.basePrice, 'base');
    _taxController = _makeController(widget.taxPercentage, 'tax');
    _profitController = _makeController(widget.profitMargin, 'profit');
    _finalPriceController = _makeController(widget.finalPrice, 'final');

    _basePriceFocus.addListener(() => _flushOnBlur(_basePriceFocus, 'base'));
    _taxFocus.addListener(() => _flushOnBlur(_taxFocus, 'tax'));
    _profitFocus.addListener(() => _flushOnBlur(_profitFocus, 'profit'));
    _finalPriceFocus.addListener(() => _flushOnBlur(_finalPriceFocus, 'final'));
  }

  /// Create a controller seeded with the parent's value, and record
  /// what the field currently shows.
  TextEditingController _makeController(Decimal value, String field) {
    final text = value.toStringAsFixed(2);
    _lastRendered[field] = text;
    return TextEditingController(text: text)
      ..selection = TextSelection(baseOffset: 0, extentOffset: text.length);
  }

  @override
  void didUpdateWidget(covariant PricingConfigCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    _syncField(
      controller: _basePriceController,
      focusNode: _basePriceFocus,
      field: 'base',
      incoming: widget.basePrice,
      oldValue: oldWidget.basePrice,
    );
    _syncField(
      controller: _taxController,
      focusNode: _taxFocus,
      field: 'tax',
      incoming: widget.taxPercentage,
      oldValue: oldWidget.taxPercentage,
    );
    _syncField(
      controller: _profitController,
      focusNode: _profitFocus,
      field: 'profit',
      incoming: widget.profitMargin,
      oldValue: oldWidget.profitMargin,
    );
    _syncField(
      controller: _finalPriceController,
      focusNode: _finalPriceFocus,
      field: 'final',
      incoming: widget.finalPrice,
      oldValue: oldWidget.finalPrice,
    );

    if (widget.mode != oldWidget.mode) {
      _forceSyncField(
        controller: _profitController,
        focusNode: _profitFocus,
        field: 'profit',
        value: widget.profitMargin,
      );
      _forceSyncField(
        controller: _finalPriceController,
        focusNode: _finalPriceFocus,
        field: 'final',
        value: widget.finalPrice,
      );
    }
  }

  void _syncField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String field,
    required Decimal incoming,
    required Decimal oldValue,
  }) {
    if (incoming == oldValue) return;
    if (focusNode.hasFocus) return;

    final formatted = incoming.toStringAsFixed(2);
    if (_lastRendered[field] == formatted) return;

    controller.text = formatted;
    _lastRendered[field] = formatted;
  }

  void _forceSyncField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String field,
    required Decimal value,
  }) {
    if (focusNode.hasFocus) return;
    final formatted = value.toStringAsFixed(2);
    if (controller.text == formatted) return;
    controller.text = formatted;
    _lastRendered[field] = formatted;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _basePriceController.dispose();
    _taxController.dispose();
    _profitController.dispose();
    _finalPriceController.dispose();
    _basePriceFocus.dispose();
    _taxFocus.dispose();
    _profitFocus.dispose();
    _finalPriceFocus.dispose();
    super.dispose();
  }

  // ==================== Commit ====================

  void _flushOnBlur(FocusNode focus, String field) {
    if (!focus.hasFocus && _pendingField == field) {
      _commit(field);
    }
  }

  void _scheduleCommit(String field) {
    _pendingField = field;
    _debounce?.cancel();
    _debounce = Timer(widget.debounce, () => _commit(field));
  }

  void _commit(String field) {
    _debounce?.cancel();
    _pendingField = null;

    switch (field) {
      case 'base':
        widget.onBasePriceChanged(_parse(_basePriceController.text));
        break;
      case 'tax':
        widget.onTaxPercentageChanged(_parse(_taxController.text));
        break;
      case 'profit':
        widget.onProfitMarginChanged(_parse(_profitController.text));
        break;
      case 'final':
        widget.onFinalPriceChanged(_parse(_finalPriceController.text));
        break;
    }
  }

  /// Parse user-typed text into a [Decimal]. Empty or unparseable
  /// input becomes `Decimal.zero`, matching the old
  /// `double.tryParse(text) ?? 0.0`.
  Decimal _parse(String text) => _readDecimal(text) ?? Decimal.zero;

  // ==================== AI suggestion ====================

  bool get _aiAvailable {
    final ai = widget.aiPrice;
    if (ai == null || ai <= Decimal.zero) return false;
    return (widget.finalPrice - ai).abs() >= Decimal.parse('0.01');
  }

  // ==================== Build ====================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;

    // `taxAmount = basePrice * taxPercentage / 100`, in Decimal.
    // `.toDecimal(scaleOnInfinitePrecision: 2)` is required — `Decimal / Decimal` returns a
    // `Rational`.
    final Decimal taxAmount =
        (widget.basePrice * widget.taxPercentage / Decimal.fromInt(100))
            .toDecimal(scaleOnInfinitePrecision: 2);

    final Decimal priceAfterTax = widget.basePrice + taxAmount;

    // `profitAmount` and `profitPercentage` branch on `widget.mode`.
    // Both branches compute in `Decimal`; the `byFinalPrice` branch's
    // division needs `.toDecimal(scaleOnInfinitePrecision: 2)`.
    final Decimal profitAmount;
    if (widget.mode == PricingMode.byProfit) {
      profitAmount =
          (priceAfterTax * widget.profitMargin / Decimal.fromInt(100))
              .toDecimal(scaleOnInfinitePrecision: 2);
    } else {
      profitAmount = widget.finalPrice - priceAfterTax;
    }

    final Decimal profitPercentage;
    if (widget.mode == PricingMode.byProfit) {
      profitPercentage = widget.profitMargin;
    } else if (priceAfterTax > Decimal.zero) {
      profitPercentage = (profitAmount / priceAfterTax)
              .toDecimal(scaleOnInfinitePrecision: 2) *
          Decimal.fromInt(100);
    } else {
      profitPercentage = Decimal.zero;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, color: colorScheme.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  loc.pricingSectionTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (widget.aiPrice != null && widget.aiPrice! > Decimal.zero) ...[
            const SizedBox(height: 14),
            _AiSuggestionStrip(
              aiPrice: widget.aiPrice!,
              currentFinal: widget.finalPrice,
              available: _aiAvailable,
              onAccept: widget.onAcceptAiPrice,
              onReset: () => widget.onFinalPriceChanged(Decimal.zero),
            ),
          ],
          const SizedBox(height: 20),
          _ModeSelector(
            mode: widget.mode,
            onChanged: widget.onModeChanged,
          ),
          const SizedBox(height: 20),
          _NumericField(
            label: loc.pricingBasePriceLabel,
            helper: loc.pricingBasePriceHelper,
            controller: _basePriceController,
            focusNode: _basePriceFocus,
            icon: Icons.inventory_2_outlined,
            suffix: loc.currencyCode,
            onChanged: (_) => _scheduleCommit('base'),
            onSubmitted: (_) => _commit('base'),
          ),
          const SizedBox(height: 14),
          _NumericField(
            label: loc.pricingTaxLabel,
            helper: loc.pricingTaxHelper,
            controller: _taxController,
            focusNode: _taxFocus,
            icon: Icons.percent_rounded,
            suffix: '%',
            onChanged: (_) => _scheduleCommit('tax'),
            onSubmitted: (_) => _commit('tax'),
          ),
          const SizedBox(height: 14),
          if (widget.mode == PricingMode.byProfit)
            _NumericField(
              label: loc.pricingProfitLabel,
              helper: loc.pricingProfitHelper,
              controller: _profitController,
              focusNode: _profitFocus,
              icon: Icons.trending_up_rounded,
              suffix: '%',
              onChanged: (_) => _scheduleCommit('profit'),
              onSubmitted: (_) => _commit('profit'),
            )
          else
            _NumericField(
              label: loc.pricingFinalPriceLabel,
              helper: loc.pricingFinalPriceHelper,
              controller: _finalPriceController,
              focusNode: _finalPriceFocus,
              icon: Icons.sell_outlined,
              suffix: loc.currencyCode,
              onChanged: (_) => _scheduleCommit('final'),
              onSubmitted: (_) => _commit('final'),
            ),
          const SizedBox(height: 24),
          _PricePreview(
            basePrice: widget.basePrice,
            taxAmount: taxAmount,
            priceAfterTax: priceAfterTax,
            profitAmount: profitAmount,
            profitPercentage: profitPercentage,
            finalPrice: widget.finalPrice,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Shared number formatting helpers
// ══════════════════════════════════════════════════════════════════

extension _PricingFormatting on AppLocalizations {
  String signedPrice(Decimal amount, {bool alwaysSign = false}) {
    final formatted = price(amount.abs().toStringAsFixed(2));
    if (amount < Decimal.zero) return priceNegative(formatted);
    if (alwaysSign) return pricePositive(formatted);
    return formatted;
  }

  String signedPercent(Decimal value, {bool alwaysSign = false}) {
    final formatted = value.abs().toStringAsFixed(2);
    if (value < Decimal.zero) return '$formatted%−';
    if (alwaysSign) return '+$formatted%';
    return '$formatted%';
  }
}

// ==================== AI SUGGESTION STRIP ====================

class _AiSuggestionStrip extends StatelessWidget {
  /// AI-suggested price, in [Decimal].
  final Decimal aiPrice;

  /// Current final price, in [Decimal].
  final Decimal currentFinal;

  final bool available;
  final VoidCallback onAccept;
  final VoidCallback onReset;

  const _AiSuggestionStrip({
    required this.aiPrice,
    required this.currentFinal,
    required this.available,
    required this.onAccept,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;

    // `(currentFinal - aiPrice).abs` on `Decimal` returns `Decimal`.
    final Decimal diff = (currentFinal - aiPrice).abs();
    final applied = !available;
    final bool higher = currentFinal > aiPrice;

    final accent = applied
        ? Colors.green
        : higher
            ? Colors.orange
            : Colors.blue;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, size: 20, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  applied
                      ? loc.pricingAiPriceApplied
                      : loc.pricingAiSuggestedPrice,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  loc.price(aiPrice.toStringAsFixed(2)),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!applied)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      higher
                          ? loc.pricingAiHigherDiff(
                              diff.toStringAsFixed(2),
                            )
                          : loc.pricingAiLowerDiff(
                              diff.toStringAsFixed(2),
                            ),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: accent,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: applied ? cs.primary.withOpacity(0.2) : cs.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                applied ? Icons.check_circle : Icons.price_change,
                size: 20,
                color: applied ? cs.primary : cs.onSurfaceVariant,
              ),
              onPressed: applied ? onReset : onAccept,
              padding: EdgeInsets.zero,
              splashRadius: 16,
              tooltip: applied
                  ? loc.pricingAiResetTooltip
                  : loc.pricingAiAcceptTooltip,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== MODE SELECTOR ====================

class _ModeSelector extends StatelessWidget {
  final PricingMode mode;
  final ValueChanged<PricingMode> onChanged;

  const _ModeSelector({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _ModeTab(
            label: loc.pricingModeByProfit,
            icon: Icons.trending_up_rounded,
            selected: mode == PricingMode.byProfit,
            onTap: () => onChanged(PricingMode.byProfit),
          ),
          _ModeTab(
            label: loc.pricingModeByFinalPrice,
            icon: Icons.sell_rounded,
            selected: mode == PricingMode.byFinalPrice,
            onTap: () => onChanged(PricingMode.byFinalPrice),
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  static const double _iconMinWidth = 120;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showIcon = constraints.maxWidth >= _iconMinWidth;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: selected ? cs.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: cs.shadow.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (showIcon) ...[
                      Icon(
                        icon,
                        size: 16,
                        color: selected ? cs.primary : cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: selected ? cs.primary : cs.onSurfaceVariant,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==================== NUMERIC FIELD ====================

class _NumericField extends StatelessWidget {
  final String label;
  final String helper;
  final TextEditingController controller;
  final FocusNode focusNode;
  final IconData icon;
  final String suffix;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  const _NumericField({
    required this.label,
    required this.helper,
    required this.controller,
    required this.focusNode,
    required this.icon,
    required this.suffix,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          textInputAction: TextInputAction.done,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: cs.onSurfaceVariant),
            suffixText: suffix,
            helperText: helper,
            helperStyle: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant.withOpacity(0.7),
            ),
            helperMaxLines: 2,
            filled: true,
            fillColor: cs.surfaceVariant.withOpacity(0.3),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.outline.withOpacity(0.15)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.primary, width: 2),
            ),
          ),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ==================== PRICE PREVIEW ====================

class _PricePreview extends StatelessWidget {
  /// Base price, in [Decimal].
  final Decimal basePrice;

  /// Tax amount, in [Decimal].
  final Decimal taxAmount;

  /// Price after tax (`basePrice + taxAmount`), in [Decimal].
  final Decimal priceAfterTax;

  /// Profit amount, in [Decimal].
  final Decimal profitAmount;

  /// Profit percentage, in [Decimal].
  final Decimal profitPercentage;

  /// Final price, in [Decimal].
  final Decimal finalPrice;

  const _PricePreview({
    required this.basePrice,
    required this.taxAmount,
    required this.priceAfterTax,
    required this.profitAmount,
    required this.profitPercentage,
    required this.finalPrice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;
    final profitPositive = profitAmount >= Decimal.zero;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primaryContainer.withOpacity(0.15),
            cs.primaryContainer.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.pricingBreakdownLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          _PreviewRow(
            label: loc.pricingBasePriceLabel,
            value: loc.signedPrice(basePrice),
          ),
          const SizedBox(height: 8),
          _PreviewRow(
            label: loc.pricingTaxLabel,
            value: loc.signedPrice(taxAmount, alwaysSign: true),
          ),
          const SizedBox(height: 8),
          _PreviewRow(
            label: loc.pricingPriceAfterTaxLabel,
            value: loc.signedPrice(priceAfterTax),
            muted: true,
          ),
          const SizedBox(height: 8),
          _PreviewRow(
            label: loc.pricingProfitRowLabel(
              profitPercentage.toStringAsFixed(2),
            ),
            value: loc.signedPrice(profitAmount, alwaysSign: true),
            valueColor: profitPositive ? Colors.green.shade700 : cs.error,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  loc.pricingFinalPriceLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerEnd,
                  child: Text(
                    loc.signedPrice(finalPrice),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color:
                    (profitPositive ? Colors.green : cs.error).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    profitPositive
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    size: 14,
                    color: profitPositive ? Colors.green.shade700 : cs.error,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      loc.signedPercent(
                        profitPercentage,
                        alwaysSign: true,
                      ),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color:
                            profitPositive ? Colors.green.shade700 : cs.error,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool muted;

  const _PreviewRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: muted
                  ? cs.onSurfaceVariant.withOpacity(0.7)
                  : cs.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: valueColor ?? cs.onSurface,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Decimal helper
// ============================================================================

/// Parses text into a [Decimal]. Returns `null` for empty or
/// unparseable input, so callers can pick their own fallback.
Decimal? _readDecimal(dynamic v) {
  if (v == null) return null;
  if (v is Decimal) return v;
  if (v is int) return Decimal.fromInt(v);
  if (v is double) {
    if (v.isNaN || v.isInfinite) return null;
    return Decimal.tryParse(v.toString());
  }
  if (v is String) {
    final trimmed = v.trim();
    if (trimmed.isEmpty) return null;
    return Decimal.tryParse(trimmed);
  }
  return null;
}
