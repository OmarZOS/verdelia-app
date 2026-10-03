// lib/ui/components/pricing_config_card.dart

import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:app_constants/app_constants.dart';
import 'package:event/views/pricing_config_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

/// Pure view over [PricingState].
///
/// The card never derives anything. It reads the five values, renders
/// four inputs (base, tax, and whichever of profit/final is the driver
/// for the current mode), and emits raw user input. Deriving the paired
/// field is [PricingState]'s job — that's why the paired field can't
/// desync: there is exactly one place that computes it.
class PricingConfigCard extends StatefulWidget {
  final double basePrice;
  final double taxPercentage;
  final double profitMargin;
  final double finalPrice;
  final PricingMode mode;

  /// AI-suggested selling price, or null. Purely a display / one-tap
  /// affordance — the card does not store it.
  final double? aiPrice;

  final ValueChanged<double> onBasePriceChanged;
  final ValueChanged<double> onTaxPercentageChanged;
  final ValueChanged<double> onProfitMarginChanged;
  final ValueChanged<double> onFinalPriceChanged;
  final ValueChanged<PricingMode> onModeChanged;

  /// Push the AI price into the driver field for the current mode.
  final VoidCallback onAcceptAiPrice;

  /// Debounce for text-field commits.
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

  @override
  void initState() {
    super.initState();
    _basePriceController = _makeController(widget.basePrice);
    _taxController = _makeController(widget.taxPercentage);
    _profitController = _makeController(widget.profitMargin);
    _finalPriceController = _makeController(widget.finalPrice);

    _basePriceFocus.addListener(() => _flushOnBlur(_basePriceFocus, 'base'));
    _taxFocus.addListener(() => _flushOnBlur(_taxFocus, 'tax'));
    _profitFocus.addListener(() => _flushOnBlur(_profitFocus, 'profit'));
    _finalPriceFocus.addListener(() => _flushOnBlur(_finalPriceFocus, 'final'));
  }

  TextEditingController _makeController(double value) {
    final text = value.toStringAsFixed(2);
    return TextEditingController(text: text)
      ..selection = TextSelection(baseOffset: 0, extentOffset: text.length);
  }

  @override
  void didUpdateWidget(covariant PricingConfigCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Sync controllers from state, but never stomp a field the user is
    // actively typing in. If the user is focused, the controller is
    // authoritative and the state will catch up on commit.
    if (widget.basePrice != oldWidget.basePrice && !_basePriceFocus.hasFocus) {
      _basePriceController.text = widget.basePrice.toStringAsFixed(2);
    }
    if (widget.taxPercentage != oldWidget.taxPercentage &&
        !_taxFocus.hasFocus) {
      _taxController.text = widget.taxPercentage.toStringAsFixed(2);
    }
    if (widget.profitMargin != oldWidget.profitMargin &&
        !_profitFocus.hasFocus) {
      _profitController.text = widget.profitMargin.toStringAsFixed(2);
    }
    if (widget.finalPrice != oldWidget.finalPrice &&
        !_finalPriceFocus.hasFocus) {
      _finalPriceController.text = widget.finalPrice.toStringAsFixed(2);
    }

    if (widget.mode != oldWidget.mode) {
      _profitController.text = widget.profitMargin.toStringAsFixed(2);
      _finalPriceController.text = widget.finalPrice.toStringAsFixed(2);
    }
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

  /// Emit the raw user input for [field]. No derivation here.
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

  double _parse(String text) => double.tryParse(text) ?? 0.0;

  // ==================== AI suggestion ====================

  /// True when the AI price is present and differs from the current
  /// final price.
  bool get _aiAvailable {
    final ai = widget.aiPrice;
    if (ai == null || ai <= 0) return false;
    return (widget.finalPrice - ai).abs() >= 0.01;
  }

  // ==================== Build ====================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;

    // Preview derivations — display only, never stored.
    final taxAmount = widget.basePrice * widget.taxPercentage / 100;
    final priceAfterTax = widget.basePrice + taxAmount;
    final profitAmount = widget.mode == PricingMode.byProfit
        ? priceAfterTax * (widget.profitMargin / 100)
        : widget.finalPrice - priceAfterTax;
    final profitPercentage = widget.mode == PricingMode.byProfit
        ? widget.profitMargin
        : priceAfterTax > 0
            ? (profitAmount / priceAfterTax) * 100
            : 0.0;

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
                ),
              ),
            ],
          ),
          if (widget.aiPrice != null && widget.aiPrice! > 0) ...[
            const SizedBox(height: 14),
            _AiSuggestionStrip(
              aiPrice: widget.aiPrice!,
              currentFinal: widget.finalPrice,
              available: _aiAvailable,
              onAccept: widget.onAcceptAiPrice,
              onReset: () => widget.onFinalPriceChanged(0.0),
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
            suffix: 'DZD',
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
              suffix: 'DZD',
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

// ==================== AI SUGGESTION STRIP ====================

class _AiSuggestionStrip extends StatelessWidget {
  final double aiPrice;
  final double currentFinal;
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

    final diff = (currentFinal - aiPrice).abs();
    final applied = !available;
    final higher = currentFinal > aiPrice;

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
                ),
                const SizedBox(height: 2),
                Text(
                  'DZD ${aiPrice.toStringAsFixed(2)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
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
                    ),
                  ),
              ],
            ),
          ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 12),
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
                Icon(
                  icon,
                  size: 16,
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: selected ? cs.primary : cs.onSurfaceVariant,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
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
  final double basePrice;
  final double taxAmount;
  final double priceAfterTax;
  final double profitAmount;
  final double profitPercentage;
  final double finalPrice;

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
    final profitPositive = profitAmount >= 0;

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
          ),
          const SizedBox(height: 14),
          _PreviewRow(
            label: loc.pricingBasePriceLabel,
            value: _fmt(basePrice, loc),
          ),
          const SizedBox(height: 8),
          _PreviewRow(
            label: loc.pricingTaxLabel,
            value: '+ ${_fmt(taxAmount, loc)}',
          ),
          const SizedBox(height: 8),
          _PreviewRow(
            label: loc.pricingPriceAfterTaxLabel,
            value: _fmt(priceAfterTax, loc),
            muted: true,
          ),
          const SizedBox(height: 8),
          _PreviewRow(
            label: loc.pricingProfitRowLabel(
              profitPercentage.toStringAsFixed(2),
            ),
            value: '${profitPositive ? '+' : ''} ${_fmt(profitAmount, loc)}',
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
                ),
              ),
              Text(
                _fmt(finalPrice, loc),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
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
                  Text(
                    '${profitPositive ? '+' : ''}'
                    '${profitPercentage.toStringAsFixed(2)}%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: profitPositive ? Colors.green.shade700 : cs.error,
                      fontWeight: FontWeight.w700,
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

  String _fmt(double amount, AppLocalizations loc) {
    return loc.price(amount.toStringAsFixed(2));
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: muted
                  ? cs.onSurfaceVariant.withOpacity(0.7)
                  : cs.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: valueColor ?? cs.onSurface,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
