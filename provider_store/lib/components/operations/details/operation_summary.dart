// lib/ui/components/business_operations/operation_summary.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:verdelia_core/app/AppUser.dart';
import 'package:verdelia_core/business/finance/BusinessOperation.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:event/user_change_notifier.dart';
import 'package:event/personnel_notifier.dart';
import 'package:event/supplier_change_notifier.dart';

class OperationSummary extends StatelessWidget {
  final BusinessOperation operation;

  const OperationSummary({super.key, required this.operation});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.operationSummary,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _SummaryGrid(operation: operation),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary grid
// ---------------------------------------------------------------------------

class _SummaryGrid extends StatelessWidget {
  final BusinessOperation operation;

  const _SummaryGrid({required this.operation});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: [
        _SummaryItem(
          label: loc.operationId,
          valueFuture: Future.value(_operationId()),
          icon: Icons.numbers,
          color: cs.primary,
        ),
        _ClientSummaryItem(
          operation: operation,
          localizations: loc,
          color: cs.secondary,
        ),
        _SupplierSummaryItem(
          operation: operation,
          localizations: loc,
          color: Colors.orange,
        ),
        _SellerSummaryItem(
          operation: operation,
          localizations: loc,
          color: Colors.purple,
        ),
      ],
    );
  }

  String _operationId() {
    if (operation.isCart) return 'Cart #${operation.sourceId}';
    if (operation.isDelivery) return 'Order #${operation.sourceId}';
    return '#${operation.sourceId}';
  }
}

// ---------------------------------------------------------------------------
// Generic summary tile
// ---------------------------------------------------------------------------

class _SummaryItem extends StatelessWidget {
  final String label;
  final Future<String> valueFuture;
  final IconData icon;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.valueFuture,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                FutureBuilder<String>(
                  future: valueFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingSkeleton(cs);
                    }
                    if (snapshot.hasError) {
                      return Text(
                        'N/A',
                        style: TextStyle(
                          color: cs.error,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }
                    return Text(
                      snapshot.data ?? 'N/A',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        overflow: TextOverflow.ellipsis,
                      ),
                      maxLines: 1,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton(ColorScheme cs) {
    return SizedBox(
      height: 16,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: cs.surfaceVariant,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Client
// ---------------------------------------------------------------------------

class _ClientSummaryItem extends StatelessWidget {
  final BusinessOperation operation;
  final AppLocalizations localizations;
  final Color color;

  const _ClientSummaryItem({
    required this.operation,
    required this.localizations,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final clientId = operation.clientId;
    final hasClient = clientId != null && clientId > 0;

    if (!hasClient) {
      return _SummaryItem(
        label: localizations.client,
        valueFuture: Future.value('N/A'),
        icon: Icons.person,
        color: color,
      );
    }

    return FutureBuilder<String>(
      future: _getClientName(context, clientId),
      builder: (context, snapshot) {
        final value = snapshot.connectionState == ConnectionState.waiting
            ? '${localizations.loading}...'
            : snapshot.hasError
                ? '#$clientId'
                : snapshot.data ?? '#$clientId';

        return _SummaryItem(
          label: localizations.client,
          valueFuture: Future.value(value),
          icon: Icons.person,
          color: color,
        );
      },
    );
  }

  Future<String> _getClientName(BuildContext context, int clientId) async {
    try {
      final personnelNotifier = context.read<PersonnelNotifier>();
      final customer = await personnelNotifier.getCustomerDisplayInfo(
        customerId: clientId,
        customerType: 'user',
        personId: clientId,
      );

      if (customer != null && (customer.displayName?.isNotEmpty ?? false)) {
        return customer.displayName!;
      }

      final appUserNotifier = context.read<AppUserNotifier>();
      final user =
          await appUserNotifier.fetchUserPassively(clientId.toString());
      if (user != null) return _userDisplayName(user);

      return '#$clientId';
    } catch (e) {
      debugPrint('Error fetching client name: $e');
      return '#$clientId';
    }
  }
}

// ---------------------------------------------------------------------------
// Supplier
// ---------------------------------------------------------------------------

class _SupplierSummaryItem extends StatelessWidget {
  final BusinessOperation operation;
  final AppLocalizations localizations;
  final Color color;

  const _SupplierSummaryItem({
    required this.operation,
    required this.localizations,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final supplierId = operation.supplierId;
    final hasSupplier = supplierId != null && supplierId > 0;

    if (!hasSupplier) {
      return _SummaryItem(
        label: localizations.supplier,
        valueFuture: Future.value('N/A'),
        icon: Icons.business,
        color: color,
      );
    }

    return FutureBuilder<String>(
      future: _getSupplierName(context, supplierId),
      builder: (context, snapshot) {
        final value = snapshot.connectionState == ConnectionState.waiting
            ? '${localizations.loading}...'
            : snapshot.hasError
                ? '#$supplierId'
                : snapshot.data ?? '#$supplierId';

        return _SummaryItem(
          label: localizations.supplier,
          valueFuture: Future.value(value),
          icon: Icons.business,
          color: color,
        );
      },
    );
  }

  Future<String> _getSupplierName(BuildContext context, int supplierId) async {
    try {
      final supplierNotifier = context.read<SupplierChangeNotifier>();
      final supplier = await supplierNotifier.getSupplierById(
        supplierId,
        forceRefresh: false,
      );
      if (supplier != null && (supplier.providerName?.isNotEmpty ?? false)) {
        return supplier.providerName!;
      }
      return '#$supplierId';
    } catch (e) {
      debugPrint('Error fetching supplier name: $e');
      return '#$supplierId';
    }
  }
}

// ---------------------------------------------------------------------------
// Seller — carts only; the seller id lives inside the raw cart payload.
// ---------------------------------------------------------------------------

class _SellerSummaryItem extends StatelessWidget {
  final BusinessOperation operation;
  final AppLocalizations localizations;
  final Color color;

  const _SellerSummaryItem({
    required this.operation,
    required this.localizations,
    required this.color,
  });

  /// The new operation model has no top-level seller id. Carts carry it in
  /// `cart.cart_selling_user`; deliveries do not carry a seller at all.
  int? get _sellerId {
    final cart = operation.cart;
    if (cart == null) return null;
    final v = cart['cart_selling_user'];
    return v is int ? v : null;
  }

  @override
  Widget build(BuildContext context) {
    final sellerId = _sellerId;
    final hasSeller = sellerId != null && sellerId > 0;

    if (!hasSeller) {
      return _SummaryItem(
        label: localizations.seller,
        valueFuture: Future.value('N/A'),
        icon: Icons.person_outline,
        color: color,
      );
    }

    return FutureBuilder<String>(
      future: _getSellerName(context, sellerId),
      builder: (context, snapshot) {
        final value = snapshot.connectionState == ConnectionState.waiting
            ? '${localizations.loading}...'
            : snapshot.hasError
                ? '#$sellerId'
                : snapshot.data ?? '#$sellerId';

        return _SummaryItem(
          label: localizations.seller,
          valueFuture: Future.value(value),
          icon: Icons.person_outline,
          color: color,
        );
      },
    );
  }

  Future<String> _getSellerName(BuildContext context, int sellerId) async {
    try {
      final appUserNotifier = context.read<AppUserNotifier>();
      final user =
          await appUserNotifier.fetchUserPassively(sellerId.toString());
      if (user != null) return _userDisplayName(user);
      return '#$sellerId';
    } catch (e) {
      debugPrint('Error fetching seller name: $e');
      return '#$sellerId';
    }
  }
}

// ---------------------------------------------------------------------------
// Shared display-name helper for AppUser
// ---------------------------------------------------------------------------

String _userDisplayName(AppUser user) {
  final first = user.personFirstName?.trim();
  final last = user.personLastName?.trim();
  final username = user.appUserName?.trim();

  if (first != null && first.isNotEmpty) {
    if (last != null && last.isNotEmpty) return '$first $last';
    return first;
  }
  if (username != null && username.isNotEmpty) return username;
  return 'User #${user.idAppUser}';
}
