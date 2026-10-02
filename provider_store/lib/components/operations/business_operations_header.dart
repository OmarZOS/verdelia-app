// lib/ui/components/business_operations/business_operations_header.dart

import 'package:event/views/business_ops_notifier.dart';
import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:verdelia_core/business/finance/BusinessOperation.dart';

class BusinessOperationsHeader extends StatelessWidget {
  const BusinessOperationsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    final notifier = context.watch<BusinessOperationNotifier>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(color: cs.outline.withOpacity(0.1)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: cs.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.businessOperations,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loc.viewAllBusinessTransactions,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: notifier.isBusy ? null : () => notifier.refresh(),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                color: cs.primary,
                style: IconButton.styleFrom(
                  backgroundColor: cs.primary.withOpacity(0.1),
                  padding: const EdgeInsets.all(8),
                ),
                tooltip: loc.refresh,
              ),
            ],
          ),
          // Top suppliers strip — driven by the envelope's bySupplier buckets.
          if (notifier.bySupplier.isNotEmpty) ...[
            const SizedBox(height: 16),
            _TopSuppliers(buckets: notifier.bySupplier),
          ],
        ],
      ),
    );
  }
}

class _TopSuppliers extends StatelessWidget {
  final Map<String, BusinessOperationsBucket> buckets;

  const _TopSuppliers({required this.buckets});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Sort by grand_total desc, take 3.
    final entries = buckets.entries.toList()
      ..sort((a, b) =>
          (b.value.grandTotal ?? 0).compareTo(a.value.grandTotal ?? 0));
    final top = entries.take(3).toList();

    if (top.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Suppliers',
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 32,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: top.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final e = top[index];
              final supplierId = e.key;
              final bucket = e.value;
              final total = bucket.grandTotal ?? 0;

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: _colorForIndex(index, cs),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      'Supplier $supplierId',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      total.toStringAsFixed(0),
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _colorForIndex(int index, ColorScheme cs) {
    final colors = [cs.primary, cs.secondary, cs.tertiary];
    return colors[index % colors.length];
  }
}
