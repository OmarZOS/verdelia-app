// financial_ui_manager.dart
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/business/finance/FinancialDocument.dart';

class FinancialUIManager {
  // ==================== COLORS ====================

  static const Color paidColor = Color(0xFF10B981);
  static const Color partialColor = Color(0xFFF59E0B);
  static const Color unpaidColor = Color(0xFFEF4444);
  static const Color pendingColor = Color(0xFF6B7280);
  static const Color canceledColor = Color(0xFF374151);
  static const Color depositColor = Color(0xFF8B5CF6);
  static const Color infoColor = Color(0xFF3B82F6);

  // ==================== ICONS ====================

  static const IconData invoiceIcon = Icons.receipt_long;
  static const IconData depositIcon = Icons.account_balance_wallet;
  static const IconData cartIcon = Icons.shopping_cart;
  static const IconData receiptIcon = Icons.description;
  static const IconData userIcon = Icons.person;
  static const IconData personIcon = Icons.person_outline;
  static const IconData paymentIcon = Icons.payment;
  static const IconData calendarIcon = Icons.calendar_today;

  // ==================== TEXT STYLES ====================

  static TextStyle titleStyle(BuildContext context) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      );

  static TextStyle subtitleStyle(BuildContext context) => TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );

  static TextStyle amountStyle(BuildContext context) => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      );

  static TextStyle smallAmountStyle(BuildContext context) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onSurface,
      );

  // ==================== DOCUMENT TYPE METHODS ====================

  static String getDocumentTypeDisplay(String documentType,
      [AppLocalizations? loc]) {
    switch (documentType) {
      case 'invoice':
        return loc?.invoice ?? 'Invoice';
      case 'deposit':
        return loc?.deposit ?? 'Deposit';
      case 'pending_cart':
        return loc?.pendingCart ?? 'Pending Cart';
      case 'cart_with_payments':
        return loc?.paidCart ?? 'Paid Cart';
      case 'receipt':
        return loc?.receipt ?? 'Receipt';
      default:
        return documentType.replaceAll('_', ' ').capitalize();
    }
  }

  static IconData getDocumentIcon(String documentType) {
    switch (documentType) {
      case 'invoice':
        return invoiceIcon;
      case 'deposit':
        return depositIcon;
      case 'pending_cart':
      case 'cart_with_payments':
        return cartIcon;
      case 'receipt':
        return receiptIcon;
      default:
        return Icons.description;
    }
  }

  static Color getDocumentColor(String documentType, ThemeData theme) {
    switch (documentType) {
      case 'invoice':
        return theme.colorScheme.primary;
      case 'deposit':
        return depositColor;
      case 'pending_cart':
        return partialColor;
      case 'receipt':
        return paidColor;
      default:
        return infoColor;
    }
  }

  // ==================== PAYMENT STATUS METHODS ====================

  static String getPaymentStatusDisplay(String paymentStatus,
      [AppLocalizations? loc]) {
    final status = paymentStatus.toLowerCase();

    if (status == 'paid' ||
        status.contains('fully_paid') ||
        status.contains('covers_full') ||
        status.contains('fully_covered')) {
      return loc?.paid ?? 'Paid';
    }

    if (status == 'deposited' ||
        status.contains('partial') ||
        status.contains('deposit_') ||
        status.contains('received')) {
      return loc?.depositReceived ?? 'Deposit Received';
    }

    if (status == 'unpaid' ||
        status.contains('no_deposit') ||
        status.contains('pending_payment')) {
      return loc?.unpaid ?? 'Unpaid';
    }

    if (status.contains('cancel')) return loc?.cancelled ?? 'Cancelled';
    if (status.contains('overdue')) return loc?.overdue ?? 'Overdue';
    if (status.contains('pending')) return loc?.pending ?? 'Pending';
    if (status.contains('draft')) return loc?.draft ?? 'Draft';

    return paymentStatus.replaceAll('_', ' ').capitalize();
  }

  static Color getPaymentStatusColor(String paymentStatus, ThemeData theme) {
    final status = paymentStatus.toLowerCase();

    if (status.contains('cancel')) return canceledColor;
    if (status.contains('overdue')) return theme.colorScheme.error;
    if (status.contains('draft')) return theme.colorScheme.secondary;
    if (status.contains('pending')) return pendingColor;

    if (status == 'paid' ||
        status.contains('fully_paid') ||
        status.contains('covers_full') ||
        status.contains('fully_covered')) {
      return paidColor;
    }

    if (status == 'deposited' ||
        status.contains('partial') ||
        status.contains('deposit_') ||
        status.contains('received')) {
      return depositColor;
    }

    if (status == 'unpaid' ||
        status.contains('no_deposit') ||
        status.contains('pending_payment')) {
      return unpaidColor;
    }

    return infoColor;
  }

  static IconData getPaymentStatusIcon(String paymentStatus) {
    final status = paymentStatus.toLowerCase();

    if (status.contains('cancel')) return Icons.cancel;
    if (status.contains('overdue')) return Icons.warning;
    if (status.contains('draft')) return Icons.edit_note;
    if (status.contains('pending')) return Icons.schedule;

    if (status.contains('paid') ||
        status.contains('fully_paid') ||
        status.contains('covers_full') ||
        status.contains('fully_covered')) {
      return Icons.check_circle;
    }

    if (status == 'deposited' ||
        status.contains('partial') ||
        status.contains('deposit_') ||
        status.contains('received')) {
      return Icons.account_balance_wallet;
    }

    if (status == 'unpaid' ||
        status.contains('no_deposit') ||
        status.contains('pending_payment')) {
      return Icons.pending_actions;
    }

    return Icons.circle;
  }

  // ==================== FORMATTING METHODS ====================

  /// Formats a monetary amount for display.
  ///
  /// Accepts `num` so both `Decimal` (the money-migrated models) and
  /// `double` (raw payload values the meta cards still read from
  /// `Map<String, dynamic>`) flow through unchanged. The body only
  /// calls `toStringAsFixed(2)`, which is on `num`.
  static String formatCurrency(Decimal amount, BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return loc.price(amount);
  }

  static String formatDate(DateTime? date, [BuildContext? context]) {
    if (date == null) return '-';

    if (context != null) {
      final loc = AppLocalizations.of(context);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) return loc?.today ?? 'Today';
      if (difference.inDays == 1) return loc?.yesterday ?? 'Yesterday';
      if (difference.inDays < 7) {
        return '${difference.inDays} ${loc?.daysAgo ?? 'days ago'}';
      }
    }

    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatDateTime(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('MMM dd, yyyy HH:mm').format(date);
  }

  // ==================== UI COMPONENTS ====================

  static Widget buildStatusBadge({
    required String status,
    required BuildContext context,
    double fontSize = 12,
  }) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final color = getPaymentStatusColor(status, theme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            getPaymentStatusIcon(status),
            size: fontSize,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            getPaymentStatusDisplay(status, loc),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a "paid X of Y" progress bar with a percentage label.
  ///
  /// All three money parameters are [Decimal] so the sum and the
  /// division stay exact. The result is converted to `double` at the
  /// two boundaries that need it: `LinearProgressIndicator.value`
  /// (Flutter layout) and the `* 100` for the percentage label.
  static Widget buildPaymentProgress({
    required BuildContext context,
    required Decimal amount,
    required Decimal paid,
    required Decimal deposited,
    double height = 8,
  }) {
    final loc = AppLocalizations.of(context);
    final Decimal totalReceived = deposited + paid;

    // `Decimal / Decimal` returns `Rational`; `.toDecimal(scaleOnInfinitePrecision: 2)` is
    // required. The `[0, 1]` clamp is a manual three-branch because
    // `Decimal` has no `.clamp`.
    Decimal ratioDecimal;
    if (amount <= Decimal.zero) {
      ratioDecimal = Decimal.zero;
    } else {
      final raw =
          (totalReceived / amount).toDecimal(scaleOnInfinitePrecision: 2);
      if (raw < Decimal.zero) {
        ratioDecimal = Decimal.zero;
      } else if (raw > Decimal.one) {
        ratioDecimal = Decimal.one;
      } else {
        ratioDecimal = raw;
      }
    }

    final double ratio = ratioDecimal.toDouble();
    final Decimal percentageDecimal =
        (totalReceived / (amount > Decimal.zero ? amount : Decimal.one))
                .toDecimal(scaleOnInfinitePrecision: 2) *
            Decimal.fromInt(100);
    final double percentage = percentageDecimal.toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              loc?.paymentProgress ?? 'Payment Progress',
              style: subtitleStyle(context),
            ),
            Text(
              '${formatCurrency(totalReceived, context)} / '
              '${formatCurrency(amount, context)}',
              style: subtitleStyle(context),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: ratio,
          minHeight: height,
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          valueColor: AlwaysStoppedAnimation<Color>(
            ratioDecimal >= Decimal.one ? paidColor : depositColor,
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  static Widget buildLoadingState({
    required BuildContext context,
    String? message,
  }) {
    final loc = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            message ?? loc?.loadingDocuments ?? 'Loading documents...',
            style: subtitleStyle(context),
          ),
        ],
      ),
    );
  }

  static Widget buildEmptyState({
    required BuildContext context,
    String? message,
    IconData? icon,
    VoidCallback? onRetry,
  }) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.inbox_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              message ?? loc?.noDocumentsFound ?? 'No documents found',
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(loc?.retry ?? 'Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget buildErrorState({
    required BuildContext context,
    required String message,
    required VoidCallback onRetry,
  }) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              loc?.errorLoadingDocuments ?? 'Error Loading Documents',
              style: titleStyle(context),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: subtitleStyle(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(loc?.retry ?? 'Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== EXTENSIONS ====================

extension StringExtensions on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
