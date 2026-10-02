import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

class SellingPointAppBar extends StatelessWidget {
  final Function() onScanBarcode;

  const SellingPointAppBar({required this.onScanBarcode});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final localizations = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          _IconBadge(colorScheme: colorScheme),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.pointOfSale,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  localizations.quickTransactions,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          _ScanButton(
            colorScheme: colorScheme,
            onPressed: onScanBarcode,
            tooltip: localizations.scanBarcode,
          ),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final ColorScheme colorScheme;

  const _IconBadge({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primaryContainer],
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.point_of_sale,
        color: colorScheme.onPrimary,
        size: 22,
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  final ColorScheme colorScheme;
  final VoidCallback onPressed;
  final String tooltip;

  const _ScanButton({
    required this.colorScheme,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(Icons.qr_code_scanner, color: colorScheme.primary),
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: colorScheme.primary.withOpacity(0.1),
        padding: const EdgeInsets.all(10),
      ),
    );
  }
}

class SellingPointSearchBar extends StatefulWidget {
  final TextEditingController searchController;
  final Function(String) onSearchChanged;

  const SellingPointSearchBar({
    required this.searchController,
    required this.onSearchChanged,
  });

  @override
  State<SellingPointSearchBar> createState() => _SellingPointSearchBarState();
}

class _SellingPointSearchBarState extends State<SellingPointSearchBar> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: widget.searchController,
          decoration: InputDecoration(
            hintText: localizations.searchTxt,
            prefixIcon: Icon(Icons.search, color: colorScheme.primary),
            suffixIcon: widget.searchController.text.isNotEmpty
                ? IconButton(
                    icon:
                        Icon(Icons.close, color: colorScheme.onSurfaceVariant),
                    onPressed: () {
                      widget.searchController.clear();
                      widget.onSearchChanged('');
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: colorScheme.surface,
            // contentPadding:
            //     const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onChanged: widget.onSearchChanged,
        ),
      ),
    );
  }
}
