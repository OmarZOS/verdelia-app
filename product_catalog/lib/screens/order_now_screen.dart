import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/business/finance/Cart.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:verdelia_core/business/finance/Order.dart';
import 'package:event/cart_change_notifier.dart';
import 'package:event/order_change_notifier.dart';
import 'package:event/user_change_notifier.dart';
import 'package:provider/provider.dart';

class OrderNowScreen extends StatefulWidget {
  final Product product;

  const OrderNowScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<OrderNowScreen> createState() => _OrderNowScreenState();
}

class _OrderNowScreenState extends State<OrderNowScreen> {
  final TextEditingController _quantityController =
      TextEditingController(text: "1");
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  final FocusNode _quantityFocusNode = FocusNode();

  // Configurable values, in Decimal.
  static final Decimal _taxRate = Decimal.parse('0.19');
  static final Decimal _maxDiscount = Decimal.zero;

  int get quantity => int.tryParse(_quantityController.text) ?? 1;

  /// Unit price, in [Decimal].
  ///
  /// `Product.product_price` is `Decimal?` after the Product
  /// migration; `?? Decimal.zero` matches the old `?? 0.0`.
  Decimal get unitPrice => widget.product.product_price ?? Decimal.zero;

  /// Gross subtotal, in [Decimal]. `Decimal * int` isn't defined;
  /// widen the quantity with `Decimal.fromInt`.
  Decimal get subtotal => unitPrice * Decimal.fromInt(quantity);

  /// Tax amount, in [Decimal].
  Decimal get taxAmount => subtotal * _taxRate;

  /// Grand total, in [Decimal].
  Decimal get total => subtotal + taxAmount - _maxDiscount;

  @override
  void initState() {
    super.initState();
    _quantityController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _quantityFocusNode.dispose();
    super.dispose();
  }

  void _updateQuantity(int increment) {
    final newQuantity = (quantity + increment).clamp(1, 999);
    _quantityController.text = newQuantity.toString();
    setState(() {});
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final localizations = AppLocalizations.of(context)!;
    final userNotifier = context.read<AppUserNotifier>();

    try {
      // `Order.buildSingleOrderData` takes `Decimal?` for
      // `discount` and `taxRate` after the Order migration.
      final orderData = Order.buildSingleOrderData(
        product: widget.product,
        quantity: quantity,
        orderingUserId: userNotifier.appUser?.idAppUser ?? 0,
        discount: _maxDiscount,
        taxRate: _taxRate,
      );

      final orderNotifier = context.read<OrderChangeNotifier>();
      final OrderResult result = await orderNotifier.submitOrder(orderData);

      if (result.isSuccess) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(localizations.putSuccess),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        if (mounted) Navigator.pop(context);
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(localizations.putFailure),
            backgroundColor: Colors.amber,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text("${localizations.serverError}: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(localizations.orderNowTxt),
          elevation: 0,
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductHeader(theme, localizations),
                  const SizedBox(height: 24),
                  _buildQuantitySelector(localizations, theme),
                  const SizedBox(height: 24),
                  _buildPriceBreakdown(localizations, theme),
                  const SizedBox(height: 24),
                  _buildTotalSection(localizations, theme),
                  const Spacer(),
                  _buildOrderButton(localizations, theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductHeader(ThemeData theme, AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.orderFor,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.product.product_name ?? localizations.missingProductName,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          // `unitPrice` is `Decimal`; `toStringAsFixed(2)` produces
          // the same two-decimal string the `double` path did.
          localizations.price(unitPrice.toStringAsFixed(2)),
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector(
      AppLocalizations localizations, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.productQuantity,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQuantityButton(
                icon: Icons.remove,
                onPressed: quantity > 1 ? () => _updateQuantity(-1) : null,
                theme: theme,
              ),
              SizedBox(
                width: 80,
                child: TextFormField(
                  controller: _quantityController,
                  focusNode: _quantityFocusNode,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.colorScheme.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.colorScheme.outline),
                    ),
                  ),
                  validator: (value) {
                    final qty = int.tryParse(value ?? "");
                    if (qty == null || qty < 1) {
                      return "localizations.invalidQuantity";
                    }
                    if (qty > 999) {
                      return "localizations.maxQuantityExceeded";
                    }
                    return null;
                  },
                ),
              ),
              _buildQuantityButton(
                icon: Icons.add,
                onPressed: quantity < 999 ? () => _updateQuantity(1) : null,
                theme: theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required ThemeData theme,
  }) {
    return IconButton(
      icon: Icon(icon, size: 24),
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: onPressed != null
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withOpacity(0.2),
        foregroundColor: onPressed != null
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurface.withOpacity(0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _buildPriceBreakdown(AppLocalizations localizations, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildPriceRow(
            label: localizations.subtotalTxt,
            value: subtotal,
            theme: theme,
          ),
          const SizedBox(height: 8),
          _buildPriceRow(
            label:
                "${localizations.taxTxt} (${(_taxRate * Decimal.fromInt(100)).toStringAsFixed(0)}%)",
            value: taxAmount,
            theme: theme,
          ),
          if (_maxDiscount > Decimal.zero) ...[
            const SizedBox(height: 8),
            _buildPriceRow(
              label: localizations.discountText,
              value: -_maxDiscount,
              isDiscount: true,
              theme: theme,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceRow({
    required String label,
    required Decimal value,
    bool isDiscount = false,
    required ThemeData theme,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
        Text(
          // `value > 0` becomes `> Decimal.zero`. The
          // `toStringAsFixed(2)` is unchanged.
          AppLocalizations.of(context)!.price(
              "${isDiscount && value > Decimal.zero ? '-' : ''}${value.toStringAsFixed(2)}"),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDiscount ? Colors.green : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalSection(AppLocalizations localizations, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            localizations.totalTxt,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          Text(
            localizations.price(total.toStringAsFixed(2)),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderButton(AppLocalizations localizations, ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submitOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            shadowColor: theme.colorScheme.primary.withOpacity(0.3),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                )
              : Text(
                  localizations.confirmOrderTxt.toUpperCase(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}
