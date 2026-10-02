import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:app_constants/app_constants.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:product_catalog/screens/order_now_screen.dart';

class AddToCart extends StatelessWidget {
  const AddToCart({
    super.key,
    required this.product,
    required this.onAddToCartPressed,
  });

  final Product product;
  final VoidCallback onAddToCartPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: AppConstants.kDefaultPaddin),
      child: Row(
        children: [
          // Add to Cart Button
          _buildAddToCartButton(context, isDarkMode),
          const SizedBox(width: AppConstants.kDefaultPaddin),
          // Order Now Button
          Expanded(
            child: _buildOrderNowButton(context, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildAddToCartButton(BuildContext context, bool isDarkMode) {
    return Material(
      borderRadius: BorderRadius.circular(18),
      color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onAddToCartPressed,
        splashColor: Theme.of(context).primaryColor.withOpacity(0.2),
        highlightColor: Theme.of(context).primaryColor.withOpacity(0.1),
        child: Container(
          height: 50,
          width: 58,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.5),
            ),
          ),
          child: SvgPicture.asset(
            "assets/icons/add_to_cart.svg",
            package: "product_catalog",
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderNowButton(BuildContext context, ThemeData theme) {
    return ElevatedButton(
      onPressed: () => _navigateToOrderNowScreen(context),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        elevation: 2,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Text(
          AppLocalizations.of(context)!.orderNowTxt.toUpperCase(),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: theme.colorScheme.onPrimary,
          ),
          key: ValueKey(AppLocalizations.of(context)!.orderNowTxt),
        ),
      ),
    );
  }

  Future<void> _navigateToOrderNowScreen(BuildContext context) async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            OrderNowScreen(product: product),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );

    if (result != null) {
      // Handle the selected store
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.ordersText} $result'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}
