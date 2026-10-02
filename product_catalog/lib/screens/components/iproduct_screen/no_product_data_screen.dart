import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

class NoProductDataScreen extends StatelessWidget {
  final String barcode;
  final VoidCallback onScanAgain;
  final VoidCallback onAddManually;

  const NoProductDataScreen({
    super.key,
    required this.barcode,
    required this.onScanAgain,
    required this.onAddManually,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Illustration
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 56,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                localizations.noProductDataTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Barcode display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      barcode,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontFamily: 'Monospace',
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                localizations.noProductDataDescription,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Options
              Column(
                children: [
                  // Scan Again Button
                  FilledButton(
                    onPressed: onScanAgain,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.qr_code_scanner_rounded),
                        const SizedBox(width: 8),
                        Text(localizations.scanAgainText),
                      ],
                    ),
                  ),
                  // const SizedBox(height: 12),

                  // // Add Manually Button
                  // OutlinedButton(
                  //   onPressed: onAddManually,
                  //   style: OutlinedButton.styleFrom(
                  //     minimumSize: const Size(double.infinity, 56),
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(12),
                  //     ),
                  //     side: BorderSide(color: colorScheme.primary),
                  //   ),
                  //   child: Row(
                  //     mainAxisAlignment: MainAxisAlignment.center,
                  //     children: [
                  //       const Icon(Icons.add_circle_outline_rounded),
                  //       const SizedBox(width: 8),
                  //       Text(localizations.addManuallyText),
                  //     ],
                  //   ),
                  // ),
                ],
              ),

              const SizedBox(height: 24),

              // Help text
              // Text(
              //   localizations.noProductDataHelp,
              //   style: theme.textTheme.bodySmall?.copyWith(
              //     color: colorScheme.onSurfaceVariant.withOpacity(0.6),
              //   ),
              //   textAlign: TextAlign.center,
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
