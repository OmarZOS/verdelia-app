import 'package:decimal/decimal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:verdelia_core/business/finance/ProvidedService.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:provider_store/components/service/service_chip.dart';
import 'package:provider_store/components/service/service_price_column.dart';

class ServiceCard extends StatelessWidget {
  final ProvidedService service;
  final bool canManage;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ServiceCard({
    super.key,
    required this.service,
    required this.canManage,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  static const double _compactBreakpoint = 360;
  static const double _tightBreakpoint = 320;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < _compactBreakpoint;
          final tight = constraints.maxWidth < _tightBreakpoint;

          return _CardShell(
            service: service,
            compact: compact,
            tight: tight,
            canManage: canManage,
            onEdit: onEdit,
            onDelete: onDelete,
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Shell
// ══════════════════════════════════════════════════════════════════

class _CardShell extends StatelessWidget {
  final ProvidedService service;
  final bool compact;
  final bool tight;
  final bool canManage;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _CardShell({
    required this.service,
    required this.compact,
    required this.tight,
    required this.canManage,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final padding = tight ? 12.0 : (compact ? 16.0 : 20.0);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                color: _categoryColor(colorScheme, service.categoryId),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(padding),
            child: compact
                ? _CompactLayout(
                    service: service,
                    tight: tight,
                    canManage: canManage,
                    onEdit: onEdit,
                    onDelete: onDelete,
                  )
                : _WideLayout(
                    service: service,
                    canManage: canManage,
                    onEdit: onEdit,
                    onDelete: onDelete,
                  ),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(ColorScheme cs, int categoryId) {
    final colors = [
      cs.primary,
      cs.secondary,
      cs.tertiary,
      cs.error,
      cs.primary.withOpacity(0.7),
      cs.secondary.withOpacity(0.7),
    ];
    return colors[categoryId % colors.length];
  }
}

// ══════════════════════════════════════════════════════════════════
// Wide layout
// ══════════════════════════════════════════════════════════════════

class _WideLayout extends StatelessWidget {
  final ProvidedService service;
  final bool canManage;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _WideLayout({
    required this.service,
    required this.canManage,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LeadingIcon(
          service: service,
          size: 56,
          iconSize: 28,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _ServiceTitle(service: service, loc: loc),
              const SizedBox(height: 8),
              if ((service.description).trim().isNotEmpty) ...[
                _ServiceDescription(service: service, maxLines: 2),
                const SizedBox(height: 12),
              ],
              _ServiceChips(service: service, loc: loc),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120),
          child: ServicePriceColumn(service: service),
        ),
        if (canManage) _ActionMenu(onEdit: onEdit, onDelete: onDelete),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Compact layout
// ══════════════════════════════════════════════════════════════════

class _CompactLayout extends StatelessWidget {
  final ProvidedService service;
  final bool tight;
  final bool canManage;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _CompactLayout({
    required this.service,
    required this.tight,
    required this.canManage,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LeadingIcon(
              service: service,
              size: tight ? 40 : 48,
              iconSize: tight ? 20 : 24,
            ),
            SizedBox(width: tight ? 10 : 12),
            Expanded(
              child: _ServiceTitle(service: service, loc: loc),
            ),
            if (canManage) ...[
              const SizedBox(width: 4),
              _ActionMenu(
                onEdit: onEdit,
                onDelete: onDelete,
                compact: true,
              ),
            ],
          ],
        ),
        if ((service.description).trim().isNotEmpty) ...[
          SizedBox(height: tight ? 8 : 10),
          _ServiceDescription(service: service, maxLines: 2),
        ],
        if (!tight) ...[
          const SizedBox(height: 12),
          _ServiceChips(service: service, loc: loc),
        ],
        SizedBox(height: tight ? 8 : 10),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: ServicePriceColumn(service: service),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Shared building blocks
// ══════════════════════════════════════════════════════════════════

class _LeadingIcon extends StatelessWidget {
  final ProvidedService service;
  final double size;
  final double iconSize;

  const _LeadingIcon({
    required this.service,
    required this.size,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary.withOpacity(0.15),
            cs.primaryContainer.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Center(
        child: Icon(
          _getServiceIcon(service.categoryId),
          color: cs.primary,
          size: iconSize,
        ),
      ),
    );
  }

  IconData _getServiceIcon(int categoryId) {
    return Icons.handyman_rounded;
  }
}

class _ServiceTitle extends StatelessWidget {
  final ProvidedService service;
  final AppLocalizations? loc;

  const _ServiceTitle({required this.service, required this.loc});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          service.name,
          style: theme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
            height: 1.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (!service.isActive) ...[
          const SizedBox(height: 4),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: cs.errorContainer.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                loc?.status_inactive ?? 'Inactive',
                style: theme.labelSmall?.copyWith(
                  color: cs.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ServiceDescription extends StatelessWidget {
  final ProvidedService service;
  final int maxLines;

  const _ServiceDescription({
    required this.service,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      service.description,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _ServiceChips extends StatelessWidget {
  final ProvidedService service;
  final AppLocalizations? loc;

  const _ServiceChips({required this.service, required this.loc});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // `discountPercentage` is `Decimal` after the ProvidedService
    // migration. `> Decimal.zero` matches the old `> 0`; the
    // `toStringAsFixed(0)` renders the same whole-number percent
    // the `double` path did.
    final Decimal discount = service.discountPercentage;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ServiceChip.duration(service.durationFormatted),
        if (service.isActive)
          ServiceChip.active(
            loc?.status_active ?? 'Active',
            colorScheme: cs,
          ),
        if (discount > Decimal.zero)
          ServiceChip.discount(
            '${discount.toStringAsFixed(0)}%',
            colorScheme: cs,
          ),
      ],
    );
  }
}

class _ActionMenu extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool compact;

  const _ActionMenu({
    required this.onEdit,
    required this.onDelete,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        color: cs.onSurfaceVariant,
        size: compact ? 20 : 24,
      ),
      padding: EdgeInsets.zero,
      constraints:
          compact ? const BoxConstraints(minWidth: 32, minHeight: 32) : null,
      iconSize: compact ? 20 : 24,
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 20, color: cs.onSurface),
              const SizedBox(width: 12),
              Text(AppLocalizations.of(context)?.edit ?? 'Edit'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 20, color: cs.error),
              const SizedBox(width: 12),
              Text(AppLocalizations.of(context)?.delete ?? 'Delete'),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'edit' && onEdit != null) onEdit!();
        if (value == 'delete' && onDelete != null) onDelete!();
      },
    );
  }
}
