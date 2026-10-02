// lib/ui/components/business_operations/business_operations_list.dart

import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

import 'package:verdelia_core/business/finance/BusinessOperation.dart';
import 'package:event/personnel_notifier.dart';
import 'package:event/supplier_change_notifier.dart';
import 'package:ui/components/business_operations/BusinessOperationUIElements.dart';
import 'package:ui/components/business_operations/BusinessOperationsUIManager.dart';
import 'package:provider/provider.dart';

class BusinessOperationsList extends StatelessWidget {
  const BusinessOperationsList({
    super.key,
    required this.operations,
    required this.isLoadingMore,
    required this.hasMore,
    required this.onLoadMore,
    required this.onTapOperation,
  });

  final List<BusinessOperation> operations;
  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final ValueChanged<BusinessOperation> onTapOperation;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 50),
      sliver: SliverList.builder(
        itemCount: operations.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // The sentinel at the end is just a visual loader. Trigger the
          // load in a post-frame callback so we never fire a side effect
          // during build.
          if (index == operations.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) onLoadMore();
            });
            return _LoadingMoreIndicator(active: isLoadingMore);
          }

          final op = operations[index];
          return BusinessOperationCard(
            operation: op,
            isLast: index == operations.length - 1,
            onTap: () => onTapOperation(op),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card
// ---------------------------------------------------------------------------

class BusinessOperationCard extends StatelessWidget {
  const BusinessOperationCard({
    super.key,
    required this.operation,
    required this.isLast,
    required this.onTap,
  });

  final BusinessOperation operation;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, isLast ? 20 : 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The rail now reads the lifecycle status, not the
                // invoice status. Payment state is shown as a chip below.
                StatusRail(status: operation.status),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(operation: operation, l10n: l10n),
                      const SizedBox(height: 14),
                      FinancialInfoBlock(operation: operation),
                      const SizedBox(height: 12),
                      DocumentInfoRow(operation: operation),
                    ],
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

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.operation, required this.l10n});

  final BusinessOperation operation;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                BusinessOperationsUIManager.getOperationTitle(operation, l10n),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              FutureBuilder<String>(
                future: BusinessOperationsUIManager.getOperationSubtitle(
                  operation,
                  l10n,
                  context.read<PersonnelNotifier>(),
                  context.read<SupplierChangeNotifier>(),
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text(
                      '${l10n.loading}...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return const SizedBox.shrink();
                  }
                  final subtitle = snapshot.data ?? '';
                  if (subtitle.isEmpty) return const SizedBox.shrink();
                  return Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  );
                },
              ),
              if (operation.createdAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    BusinessOperationsUIManager.formatDate(
                      operation.createdAt!,
                    ),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // SourceBadge now takes the operation itself; it reads sourceType.
        SourceBadge(operation: operation),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Loader sentinel
// ---------------------------------------------------------------------------

class _LoadingMoreIndicator extends StatelessWidget {
  const _LoadingMoreIndicator({this.active = true});

  final bool active;

  @override
  Widget build(BuildContext context) {
    if (!active) return const SizedBox(height: 40);
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
