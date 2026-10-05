import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

class CheckoutButton extends StatelessWidget {
  /// Called when the user taps the button. When null, the button is
  /// disabled regardless of [isLoading] — Flutter renders the greyed
  /// state and the tap does nothing.
  final VoidCallback? onPressed;

  /// When true, the button is disabled and shows a spinner instead of
  /// its label. Combine with a non-null [onPressed] to indicate "this
  /// action is currently in flight" rather than "this action is
  /// unavailable".
  final bool isLoading;

  /// Optional custom label. Defaults to the localized "Place Order".
  final String? label;

  const CheckoutButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;

    // Disabled when either the callback is missing or we're busy.
    final disabled = isLoading || onPressed == null;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          disabledBackgroundColor: cs.onSurface.withOpacity(0.12),
          disabledForegroundColor: cs.onSurface.withOpacity(0.38),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: disabled ? 0 : 2,
          shadowColor: cs.primary.withOpacity(0.3),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: isLoading
              ? SizedBox(
                  key: const ValueKey('spinner'),
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      // The disabled foreground, because when loading
                      // the button is also disabled and the indicator
                      // must be readable against the disabled bg.
                      cs.onSurface.withOpacity(0.7),
                    ),
                  ),
                )
              : Row(
                  key: const ValueKey('label'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.shopping_cart_checkout,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        (label ?? loc.placeOrder).toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
