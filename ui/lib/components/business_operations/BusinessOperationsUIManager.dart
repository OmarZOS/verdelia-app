// lib/ui/managers/business_operations_ui_manager.dart

import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

import 'package:verdelia_core/business/finance/BusinessOperation.dart';
import 'package:event/personnel_notifier.dart';
import 'package:event/supplier_change_notifier.dart';
import 'package:ui/components/supplier/SupplierUIProvider.dart';

/// Centralizes every status → color/icon/label mapping the UI needs.
///
/// The operation model is envelope-shaped: `sourceType` (`cart` | `delivery`),
/// `sourceId`, `status` (cart/delivery lifecycle), `invoiceStatus`
/// (paid/unpaid/partially_paid), plus commercial/settlement/cost/profit fields.
/// The old `paymentStatus`, `operationType`, `documentType`, `sellerId`,
/// `orderId`, `cartId`, `invoiceId` fields no longer exist on the model.
class BusinessOperationsUIManager {
  BusinessOperationsUIManager._();

  // ---------------------------------------------------------------------
  // Invoice status (this is what "paid / unpaid / partial" now means)
  // ---------------------------------------------------------------------

  static final Map<String, InvoiceStatusConfig> _invoiceStatusConfig = {
    'paid': const InvoiceStatusConfig(
      displayName: 'Paid',
      color: Colors.green,
      icon: Icons.check_circle,
      priority: 1,
    ),
    'partially_paid': const InvoiceStatusConfig(
      displayName: 'Partially Paid',
      color: Colors.orange,
      icon: Icons.pending,
      priority: 2,
    ),
    'unpaid': const InvoiceStatusConfig(
      displayName: 'Unpaid',
      color: Colors.red,
      icon: Icons.error_outline,
      priority: 3,
    ),
    'cancelled': const InvoiceStatusConfig(
      displayName: 'Cancelled',
      color: Colors.grey,
      icon: Icons.cancel_outlined,
      priority: 4,
    ),
  };

  static InvoiceStatusConfig getInvoiceStatusConfig(String? status) {
    final key = (status ?? '').toLowerCase();
    return _invoiceStatusConfig[key] ??
        InvoiceStatusConfig(
          displayName: status ?? 'Unknown',
          color: Colors.grey,
          icon: Icons.help_outline,
          priority: 99,
        );
  }

  // ---------------------------------------------------------------------
  // Source type (replaces the old "operationType" / "documentType" axes)
  // ---------------------------------------------------------------------

  static final Map<String, SourceTypeConfig> _sourceTypeConfig = {
    'cart': const SourceTypeConfig(
      displayName: 'Cart',
      color: Colors.blue,
      icon: Icons.shopping_cart_outlined,
    ),
    'delivery': const SourceTypeConfig(
      displayName: 'Order',
      color: Colors.teal,
      icon: Icons.local_shipping_outlined,
    ),
  };

  static SourceTypeConfig getSourceTypeConfig(String? type) {
    final key = (type ?? '').toLowerCase();
    return _sourceTypeConfig[key] ??
        SourceTypeConfig(
          displayName: type ?? 'Unknown',
          color: Colors.grey,
          icon: Icons.category_outlined,
        );
  }

  // ---------------------------------------------------------------------
  // Lifecycle status (cart_status / delivery_status)
  // ---------------------------------------------------------------------

  static final Map<String, LifecycleStatusConfig> _lifecycleStatusConfig = {
    'open': const LifecycleStatusConfig(
      displayName: 'Open',
      color: Colors.blueGrey,
      icon: Icons.lock_open_outlined,
      priority: 1,
    ),
    'pending': const LifecycleStatusConfig(
      displayName: 'Pending',
      color: Colors.orange,
      icon: Icons.hourglass_empty,
      priority: 2,
    ),
    'processing': const LifecycleStatusConfig(
      displayName: 'Processing',
      color: Colors.blue,
      icon: Icons.autorenew,
      priority: 3,
    ),
    'checkout': const LifecycleStatusConfig(
      displayName: 'Checkout',
      color: Colors.indigo,
      icon: Icons.shopping_bag_outlined,
      priority: 4,
    ),
    'partial': const LifecycleStatusConfig(
      displayName: 'Partial',
      color: Colors.amber,
      icon: Icons.pie_chart_outline,
      priority: 5,
    ),
    'delivered': const LifecycleStatusConfig(
      displayName: 'Delivered',
      color: Colors.green,
      icon: Icons.check_circle_outline,
      priority: 6,
    ),
    'completed': const LifecycleStatusConfig(
      displayName: 'Completed',
      color: Colors.green,
      icon: Icons.done_all,
      priority: 7,
    ),
    'abandoned': const LifecycleStatusConfig(
      displayName: 'Abandoned',
      color: Colors.grey,
      icon: Icons.remove_circle_outline,
      priority: 8,
    ),
    'canceled': const LifecycleStatusConfig(
      displayName: 'Canceled',
      color: Colors.red,
      icon: Icons.cancel_outlined,
      priority: 9,
    ),
  };

  static LifecycleStatusConfig getLifecycleStatusConfig(String? status) {
    final key = (status ?? '').toLowerCase();
    return _lifecycleStatusConfig[key] ??
        LifecycleStatusConfig(
          displayName: status ?? 'Unknown',
          color: Colors.grey,
          icon: Icons.help_outline,
          priority: 99,
        );
  }

  // ---------------------------------------------------------------------
  // Titles and subtitles
  // ---------------------------------------------------------------------

  /// Title for a single operation. Prefers invoice number when available,
  /// otherwise falls back to the source type + id.
  static String getOperationTitle(
    BusinessOperation operation,
    AppLocalizations l10n,
  ) {
    final invoiceNumber = operation.invoice?['invoice_number'] as String?;
    if (invoiceNumber != null && invoiceNumber.isNotEmpty) {
      return '${l10n.invoice} $invoiceNumber';
    }
    if (operation.isCart) {
      return '${l10n.cart} #${operation.sourceId}';
    }
    if (operation.isDelivery) {
      return '${l10n.order} #${operation.sourceId}';
    }
    return l10n.transactionDetails;
  }

  /// Subtitle composed of client + supplier + (optional) seller.
  /// Seller is only present for carts (`cart_selling_user`); deliveries
  /// do not carry a seller, so it's omitted.
  static Future<String> getOperationSubtitle(
    BusinessOperation operation,
    AppLocalizations l10n,
    PersonnelNotifier? personnelNotifier,
    SupplierChangeNotifier supplierNotifier,
  ) async {
    final parts = <String>[];

    // Client
    if (operation.clientId != null && personnelNotifier != null) {
      final clientText = await _getClientText(
        operation.clientId!,
        'user',
        l10n.client,
        personnelNotifier,
      );
      if (clientText.isNotEmpty) parts.add(clientText);
    }

    // Supplier
    if (operation.supplierId != null && operation.supplierId! != 0) {
      final supplierText = await SupplierUIProvider.getSupplierText(
        operation.supplierId!,
        l10n.supplier,
        supplierNotifier,
      );
      if (supplierText.isNotEmpty) parts.add(supplierText);
    }

    // Seller — only carts carry it, in the raw cart payload.
    final sellerId = _extractSellerId(operation);
    if (sellerId != null && sellerId != 0 && personnelNotifier != null) {
      final sellerText = await _getSellerText(
        sellerId,
        l10n.seller,
        personnelNotifier,
      );
      if (sellerText.isNotEmpty) parts.add(sellerText);
    }

    return parts.join(' • ');
  }

  static int? _extractSellerId(BusinessOperation operation) {
    final cart = operation.cart;
    if (cart == null) return null;
    final seller = cart['cart_selling_user'];
    return seller is int ? seller : null;
  }

  static Future<String> _getClientText(
    int clientId,
    String clientType,
    String clientLabel,
    PersonnelNotifier personnelNotifier,
  ) async {
    try {
      final client = await personnelNotifier.getCustomerDisplayInfo(
        customerId: clientId,
        customerType: clientType,
        personId: clientId,
      );
      final name = client?.displayName?.trim() ?? '';
      return name.isNotEmpty ? '$clientLabel: $name' : clientLabel;
    } catch (e) {
      debugPrint('Error getting client name: $e');
      return clientLabel;
    }
  }

  static Future<String> _getSellerText(
    int sellerId,
    String sellerLabel,
    PersonnelNotifier personnelNotifier,
  ) async {
    try {
      final customer = await personnelNotifier.getCustomerDisplayInfo(
        customerId: sellerId,
        customerType: 'user',
        personId: null,
      );
      final name = customer?.displayName?.trim() ?? '';
      return name.isNotEmpty ? '$sellerLabel: $name' : sellerLabel;
    } catch (e) {
      debugPrint('Error getting seller name: $e');
      return sellerLabel;
    }
  }

  // ---------------------------------------------------------------------
  // Formatting helpers
  // ---------------------------------------------------------------------

  static String formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day}/${local.month}/${local.year} '
        '${local.hour}:${local.minute.toString().padLeft(2, '0')}';
  }

  /// Format an ROI ratio (nullable) as a percentage string.
  static String formatRoi(double? roi) {
    if (roi == null) return '—';
    return '${(roi * 100).toStringAsFixed(1)}%';
  }

  /// Color for the source badge. Distinct from the invoice status color.
  static Color getSourceBadgeColor(
    String? sourceType,
    ColorScheme colorScheme,
  ) {
    switch ((sourceType ?? '').toLowerCase()) {
      case 'cart':
        return colorScheme.primary;
      case 'delivery':
        return colorScheme.secondary;
      default:
        return colorScheme.primary;
    }
  }

  /// Optional: derive a short summary of the operation's mix.
  /// Since the new model doesn't ship a single "operationType" string,
  /// derive it from item/service counts on the operation.
  static String deriveOperationTypeLabel(BusinessOperation op) {
    final hasItems = op.itemCount > 0;
    final hasServices = op.serviceCount > 0;
    if (hasItems && hasServices) return 'Mixed';
    if (hasItems) return 'Products';
    if (hasServices) return 'Services';
    return 'Empty';
  }

  static IconData deriveOperationTypeIcon(BusinessOperation op) {
    final hasItems = op.itemCount > 0;
    final hasServices = op.serviceCount > 0;
    if (hasItems && hasServices) return Icons.blender;
    if (hasItems) return Icons.shopping_bag_outlined;
    if (hasServices) return Icons.handyman_outlined;
    return Icons.inbox_outlined;
  }
}

// ---------------------------------------------------------------------------
// Config models
// ---------------------------------------------------------------------------

class InvoiceStatusConfig {
  final String displayName;
  final Color color;
  final IconData icon;
  final int priority;

  const InvoiceStatusConfig({
    required this.displayName,
    required this.color,
    required this.icon,
    required this.priority,
  });
}

class SourceTypeConfig {
  final String displayName;
  final Color color;
  final IconData icon;

  const SourceTypeConfig({
    required this.displayName,
    required this.color,
    required this.icon,
  });
}

class LifecycleStatusConfig {
  final String displayName;
  final Color color;
  final IconData icon;
  final int priority;

  const LifecycleStatusConfig({
    required this.displayName,
    required this.color,
    required this.icon,
    required this.priority,
  });
}
