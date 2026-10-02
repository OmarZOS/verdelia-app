import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/business/Supplier.dart';
import 'package:event/supplier_change_notifier.dart';
import 'package:provider/provider.dart';

class SupplierAppBar extends StatelessWidget {
  final String searchQuery;
  final int? selectedCategoryId;
  final ValueChanged<int?> onCategoryChanged;
  final bool showAllSuppliers;
  final ValueChanged<bool> onShowAllChanged;

  const SupplierAppBar({
    super.key,
    required this.searchQuery,
    this.selectedCategoryId,
    required this.onCategoryChanged,
    required this.showAllSuppliers,
    required this.onShowAllChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      snap: true,
      elevation: 0,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          return FlexibleSpaceBar(
            titlePadding: EdgeInsets.only(
              left: 16,
              bottom: constraints.maxHeight > 100 ? 16 : 8,
            ),
            expandedTitleScale: 1,
            centerTitle: false,
            title: _buildTitle(context, constraints),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.primary,
                    colorScheme.primaryContainer,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTitle(BuildContext context, BoxConstraints constraints) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final localizations = AppLocalizations.of(context)!;

    final isExpanded = constraints.maxHeight > 100;

    return Padding(
      padding: EdgeInsets.only(right: isExpanded ? 16 : 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.myBusinessesTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: isExpanded ? 24 : 20,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (isExpanded) const SizedBox(height: 4),
        ],
      ),
    );
  }
}
