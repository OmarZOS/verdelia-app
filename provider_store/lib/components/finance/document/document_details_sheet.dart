import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/app/AppUser.dart';
import 'package:verdelia_core/business/finance/Customer.dart';
import 'package:verdelia_core/business/finance/FinancialDocument.dart';
import 'package:event/finance_change_notifier.dart';
import 'package:event/personnel_notifier.dart';
import 'package:event/supplier_change_notifier.dart';
import 'package:event/user_change_notifier.dart';
import 'package:ui/components/finance/financial_ui_manager.dart';
import 'package:ui/components/supplier/SupplierUIProvider.dart';
import 'package:ui/screens/payment_form_screen.dart';
import 'package:provider/provider.dart';

class DocumentDetailsSheet extends StatelessWidget {
  final FinancialDocument document;

  const DocumentDetailsSheet({super.key, required this.document});

  // ==================== PUBLIC HELPERS ====================

  /// True when the document has no real customer attached.
  ///
  /// A document counts as "guest" when neither a customer id nor a person id
  /// was populated. Verify against live data before relying on this — if the
  /// backend sometimes leaves both fields empty for a real customer, they'll
  /// be misclassified.
  static bool isGuestDocument(FinancialDocument doc) {
    final hasCustomerId = (doc.customerId ?? 0) > 0;
    final hasPersonId = (doc.customerPersonId ?? 0) > 0;
    return !hasCustomerId && !hasPersonId;
  }

  /// Label for the guest identity, e.g. "Guest #42".
  ///
  /// Uses `sourceId` as the cart id — that's what the finance notifier
  /// groups by. If your backend puts a different id in `sourceId`, adjust
  /// here or rename the label.
  static String guestLabel(FinancialDocument doc, AppLocalizations loc) {
    final cartId = doc.sourceId ?? 0;
    return cartId > 0 ? 'Guest #$cartId' : loc.unknown;
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final documentColor =
        FinancialUIManager.getDocumentColor(document.documentType, theme);

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 32,
            spreadRadius: -12,
            offset: const Offset(0, -12),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              alignment: Alignment.center,
              child: Container(
                width: 60,
                height: 6,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, theme, loc, documentColor),
                    const SizedBox(height: 28),
                    _buildFinancialMetrics(context, theme, loc),
                    const SizedBox(height: 28),
                    _buildPaymentProgress(context, theme, loc),
                    const SizedBox(height: 28),
                    _buildCustomerGrid(context, theme, loc),
                    const SizedBox(height: 28),
                    _buildDocumentGrid(context, theme, loc),
                    const SizedBox(height: 32),
                    _buildActionButtons(context, theme, loc),
                    SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== HEADER ====================

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    AppLocalizations loc,
    Color documentColor,
  ) {
    final isGuest = isGuestDocument(document);
    final statusColor =
        FinancialUIManager.getPaymentStatusColor(document.paymentStatus, theme);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            documentColor.withOpacity(0.12),
            documentColor.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Document type and number ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: documentColor.withOpacity(0.18),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: documentColor.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  FinancialUIManager.getDocumentIcon(document.documentType),
                  color: documentColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      FinancialUIManager.getDocumentTypeDisplay(
                          document.documentType, loc),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: documentColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      document.documentNumber,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Status badge · date · (guest chip) ──
          // Layout: status + guest chip on the left, spacer, then date.
          // Using a Wrap for the left cluster so long status+guest
          // combinations don't overflow on narrow screens.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          statusColor.withOpacity(0.15),
                          statusColor.withOpacity(0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      FinancialUIManager.getPaymentStatusDisplay(
                              document.paymentStatus, loc)
                          .toUpperCase(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),

                  // Guest chip (only when guest)
                  if (isGuest)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            guestLabel(document, loc),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              // Date on its own row — no Spacer crowding
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    FinancialUIManager.formatDate(document.issueDate),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== FINANCIAL METRICS ====================

  Widget _buildFinancialMetrics(
      BuildContext context, ThemeData theme, AppLocalizations loc) {
    final totalPaid = document.totalPaid ?? 0;
    final totalDeposited = document.totalDeposited ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            loc.financialOverview.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context: context,
                theme: theme,
                title: loc.totalAmount,
                amount: document.documentAmount,
                icon: Icons.receipt_long_rounded,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                context: context,
                theme: theme,
                title: loc.totalPaid,
                amount: totalPaid,
                icon: Icons.payments_rounded,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                context: context,
                theme: theme,
                title: loc.deposits,
                amount: totalDeposited,
                icon: Icons.account_balance_wallet_rounded,
                color: Colors.amber.shade700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required ThemeData theme,
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              FinancialUIManager.formatCurrency(amount, context),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== PAYMENT PROGRESS ====================

  Widget _buildPaymentProgress(
      BuildContext context, ThemeData theme, AppLocalizations loc) {
    final totalPaid = document.totalPaid ?? 0;
    final totalDeposited = document.totalDeposited ?? 0;
    final totalReceived = totalPaid + totalDeposited;
    final percentagePaid = document.documentAmount > 0
        ? (totalReceived / document.documentAmount * 100).clamp(0.0, 100.0)
        : 0.0;
    final remainingAmount = document.remainingAmount;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surfaceVariant.withOpacity(0.3),
            theme.colorScheme.surfaceVariant.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.paymentProgress,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${percentagePaid.toStringAsFixed(0)}%',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 12,
              color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (percentagePaid / 100).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primaryContainer,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Breakdown
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.remaining.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      FinancialUIManager.formatCurrency(
                          remainingAmount, context),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: remainingAmount > 0
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                color: theme.colorScheme.outline.withOpacity(0.1),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PAID + DEPOSITED',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      FinancialUIManager.formatCurrency(totalReceived, context),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== CUSTOMER ====================

  Widget _buildCustomerGrid(
      BuildContext context, ThemeData theme, AppLocalizations loc) {
    // ── Guest path ──
    if (isGuestDocument(document)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            theme: theme,
            icon: Icons.person_outline_rounded,
            iconColor: theme.colorScheme.primary,
            title: loc.customerDetails,
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildGuestCard(theme: theme, loc: loc),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSellerInfoCard(
                  theme: theme,
                  loc: loc,
                  context: context,
                ),
              ),
            ],
          ),
        ],
      );
    }

    // ── Normal path ──
    return FutureBuilder<Customer?>(
      future: _fetchCustomerInfo(context),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final customer = snapshot.data;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildSectionHeader(
                  theme: theme,
                  icon: Icons.person_rounded,
                  iconColor: theme.colorScheme.primary,
                  title: loc.customerDetails,
                ),
                if (isLoading) ...[
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),

            // Customer + seller as a responsive 2-column layout
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildCustomerInfoCard(
                        theme: theme,
                        icon: Icons.badge_rounded,
                        label: loc.customerName,
                        value: customer?.displayName ?? loc.loading,
                        color: theme.colorScheme.primary,
                        isLoading: isLoading,
                        avatarUrl: customer?.avatarUrl,
                      ),
                      const SizedBox(height: 16),
                      _buildContactInfoCard(
                        theme: theme,
                        customer: customer,
                        loc: loc,
                        isLoading: isLoading,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      _buildCustomerTypeCard(
                        theme: theme,
                        customer: customer,
                        loc: loc,
                        isLoading: isLoading,
                      ),
                      const SizedBox(height: 16),
                      _buildSellerInfoCard(
                        theme: theme,
                        loc: loc,
                        context: context,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Address
            if (customer?.address != null && customer!.address!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildAddressCard(
                theme: theme,
                address: customer.address!,
                loc: loc,
              ),
            ],

            // Error state
            if (snapshot.hasError) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.error.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: theme.colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Unable to load customer details',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader({
    required ThemeData theme,
    required IconData icon,
    required Color iconColor,
    required String title,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Future<Customer?> _fetchCustomerInfo(BuildContext context) async {
    try {
      final personnelNotifier =
          Provider.of<PersonnelNotifier>(context, listen: false);
      return await personnelNotifier.getCustomerDisplayInfo(
        customerId: document.customerId ?? 0,
        customerType: document.customerType ?? 'unknown',
        personId: document.customerPersonId,
      );
    } catch (e) {
      debugPrint('Error fetching customer info: $e');
      return null;
    }
  }

  Widget _buildGuestCard({
    required ThemeData theme,
    required AppLocalizations loc,
  }) {
    final cartId = document.sourceId ?? 0;
    final hasCartId = cartId > 0;
    final color = theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surfaceVariant.withOpacity(0.35),
            theme.colorScheme.surfaceVariant.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  size: 18,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  loc.customerName.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            hasCartId ? 'Guest #$cartId' : loc.unknown,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Walk-in customer',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoCard({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isLoading,
    String? avatarUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.12),
            color.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              if (avatarUrl != null && avatarUrl.isNotEmpty) ...[
                Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: NetworkImage(avatarUrl),
                      fit: BoxFit.cover,
                    ),
                    border: Border.all(
                      color: color.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            _buildSkeletonBar(theme: theme, color: color)
          else
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _buildCustomerTypeCard({
    required ThemeData theme,
    required Customer? customer,
    required AppLocalizations loc,
    required bool isLoading,
  }) {
    final isUser = customer?.isUser == true;
    final isPerson = customer?.isPerson == true;
    final color =
        isUser ? Colors.blue : (isPerson ? Colors.purple : Colors.grey);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.12),
            color.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isUser
                      ? Icons.person_outline_rounded
                      : Icons.person_pin_rounded,
                  size: 18,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  loc.customerType.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            _buildSkeletonBar(theme: theme, color: color)
          else
            Text(
              customer?.typeDisplayName ?? loc.unknown,
              style: theme.textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContactInfoCard({
    required ThemeData theme,
    required Customer? customer,
    required AppLocalizations loc,
    required bool isLoading,
  }) {
    final hasContactInfo = customer?.email != null || customer?.phone != null;
    final primaryContact = customer?.email ?? customer?.phone;
    final color = hasContactInfo ? Colors.teal : Colors.grey;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.12),
            color.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  customer?.email != null
                      ? Icons.email_rounded
                      : Icons.phone_rounded,
                  size: 18,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'CONTACT',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            _buildSkeletonBar(theme: theme, color: color)
          else if (hasContactInfo)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  primaryContact!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (customer?.email != null && customer?.phone != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    customer!.phone!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            )
          else
            Text(
              loc.notAvailable,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  // ==================== SELLER ====================

  Widget _buildSellerInfoCard({
    required ThemeData theme,
    required AppLocalizations loc,
    required BuildContext context,
  }) {
    final hasSeller = document.sellerId != null && document.sellerId! > 0;
    final color = hasSeller ? Colors.blue : Colors.grey;

    if (!hasSeller) {
      return _buildNoSellerCard(theme, loc, color);
    }

    return FutureBuilder<AppUser?>(
      future: context
          .read<AppUserNotifier>()
          .fetchUserPassively(document.sellerId.toString()),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return _sellerCardShell(
          theme: theme,
          color: color,
          child: isLoading
              ? _buildSkeletonBar(theme: theme, color: color)
              : Text(
                  snapshot.hasData && snapshot.data != null
                      ? _getUserDisplayName(snapshot.data!)
                      : loc.notAssigned,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
        );
      },
    );
  }

  Widget _buildNoSellerCard(
      ThemeData theme, AppLocalizations loc, Color color) {
    return _sellerCardShell(
      theme: theme,
      color: color,
      child: Text(
        loc.notAssigned,
        style: theme.textTheme.titleMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _sellerCardShell({
    required ThemeData theme,
    required Color color,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.12),
            color.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.assignment_ind_rounded,
                  size: 18,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'SELLER',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  String _getUserDisplayName(AppUser user) {
    final firstName = user.personFirstName?.trim();
    final lastName = user.personLastName?.trim();
    final userName = user.appUserName?.trim();

    if (firstName != null && firstName.isNotEmpty) {
      if (lastName != null && lastName.isNotEmpty) {
        return '$firstName $lastName';
      }
      return firstName;
    }
    if (userName != null && userName.isNotEmpty) {
      return userName;
    }
    return user.appUserName?.trim() ?? 'User #${user.idAppUser}';
  }

  // ==================== ADDRESS ====================

  Widget _buildAddressCard({
    required ThemeData theme,
    required String address,
    required AppLocalizations loc,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.08),
            Colors.orange.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'ADDRESS',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            address,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== DOCUMENT DETAILS ====================

  Widget _buildDocumentGrid(
      BuildContext context, ThemeData theme, AppLocalizations loc) {
    // Build a flat list of items so we can lay them out in two columns
    // without a GridView-in-a-scroll-view footgun.
    final items = <Widget>[
      _buildGridItem(
        theme: theme,
        icon: Icons.calendar_month_rounded,
        label: loc.issueDate,
        value: FinancialUIManager.formatDate(document.issueDate),
        color: Colors.teal,
      ),
      _buildGridItem(
        theme: theme,
        icon: document.dueDate != null
            ? Icons.timer_rounded
            : Icons.timer_off_rounded,
        label: loc.dueDate,
        value: document.dueDate != null
            ? FinancialUIManager.formatDate(document.dueDate!)
            : loc.notAssigned,
        color: document.dueDate != null
            ? (document.isOverdue ? theme.colorScheme.error : Colors.orange)
            : theme.colorScheme.onSurfaceVariant,
        isWarning: document.dueDate != null && document.isOverdue,
      ),
      _buildGridItem(
        theme: theme,
        icon: Icons.history_rounded,
        label: loc.daysIssued,
        value: '${document.daysIssued} ${loc.days}',
        color: Colors.indigo,
        isWarning: document.daysIssued > 30,
      ),
    ];

    // Optional supplier card takes the full width
    final supplierId = document.supplierId ?? 0;
    final showSupplier = supplierId > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.description_rounded,
                color: theme.colorScheme.secondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              loc.documentDetails,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // First row: two items side by side
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: items[0]),
            const SizedBox(width: 16),
            Expanded(child: items[1]),
          ],
        ),
        const SizedBox(height: 16),
        // Second row: one item + optional full-width supplier
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: items[2]),
            const SizedBox(width: 16),
            if (showSupplier)
              Expanded(
                child: FutureBuilder<String>(
                  future: SupplierUIProvider.getSupplierText(
                    supplierId,
                    loc.supplier,
                    context.read<SupplierChangeNotifier>(),
                  ),
                  builder: (context, snapshot) {
                    return _buildGridItem(
                      theme: theme,
                      icon: Icons.business_rounded,
                      label: loc.supplier,
                      value: snapshot.hasData
                          ? snapshot.data!
                          : '${loc.loading}...',
                      color: Colors.deepOrange,
                    );
                  },
                ),
              )
            else
              const Spacer(),
          ],
        ),
      ],
    );
  }

  Widget _buildGridItem({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(isWarning ? 0.2 : 0.1),
            color.withOpacity(isWarning ? 0.08 : 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(isWarning ? 0.4 : 0.2),
          width: isWarning ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ==================== ACTION BUTTONS ====================

  Widget _buildActionButtons(
      BuildContext context, ThemeData theme, AppLocalizations loc) {
    final remainingAmount = document.remainingAmount;
    final hasBalance = remainingAmount > 0;

    return Column(
      children: [
        if (hasBalance) ...[
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primaryContainer,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentFormScreen(
                        amountDue: document.remainingAmount,
                        onSubmit: (amount, method, notes) async {
                          final notifier =
                              context.read<FinanceChangeNotifier>();
                          final result = await notifier.submitPayment(
                            invoiceId: document.documentId,
                            amount: amount,
                            method: method,
                            notes: notes,
                          );
                          return result.isSuccess ? null : result.message;
                        },

                        // sourceDocument: document,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 22, horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.payments_rounded,
                        color: theme.colorScheme.onPrimary,
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Flexible(
                        child: Text(
                          loc.makePayment(FinancialUIManager.formatCurrency(
                              remainingAmount, context)),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        Row(
          children: [
            Expanded(
              child: _buildSecondaryButton(
                theme: theme,
                icon: Icons.share_rounded,
                label: loc.share,
                color: theme.colorScheme.secondary,
                onPressed: () => _showShareOptions(context, theme, loc),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSecondaryButton(
                theme: theme,
                icon: Icons.download_rounded,
                label: loc.download,
                color: theme.colorScheme.tertiary,
                onPressed: () => _downloadDocument(context, theme, loc),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
            foregroundColor: theme.colorScheme.onSurfaceVariant,
          ),
          child: Text(
            loc.close.toUpperCase(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryButton({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== SHARE ====================

  void _showShareOptions(
      BuildContext context, ThemeData theme, AppLocalizations loc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      loc.shareDocument,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Share ${document.documentNumber}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.link_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
                title: Text(
                  loc.copyLink,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showNotImplemented(context, 'Copy link');
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.email_rounded, color: Colors.blue),
                ),
                title: Text(
                  loc.shareViaEmail,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showNotImplemented(context, 'Email');
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.chat_rounded, color: Colors.green),
                ),
                title: Text(
                  loc.shareViaMessage,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showNotImplemented(context, 'Message');
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(sheetContext),
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: Text(
                  loc.close.toUpperCase(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotImplemented(BuildContext context, String feature) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is not implemented yet'),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ==================== DOWNLOAD ====================

  /// No fake "download complete" — this is a placeholder until the real
  /// download service is wired up.
  void _downloadDocument(
      BuildContext context, ThemeData theme, AppLocalizations loc) {
    _showNotImplemented(context, 'Download');
  }

  // ==================== SKELETON ====================

  Widget _buildSkeletonBar({
    required ThemeData theme,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      height: 24,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: color),
        ),
      ),
    );
  }
}
