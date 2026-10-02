import 'package:app_constants/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:app_constants/app_constants.dart';
import 'package:verdelia_core/app/AppUser.dart';
import 'package:verdelia_core/app/Person.dart';
import 'package:event/personnel_notifier.dart';
import 'package:event/user_change_notifier.dart';
import 'package:ui/components/search/CustomerSearchDialog.dart';
import 'package:ui/utils/qr_utils.dart';
import 'package:provider/provider.dart';

class CustomerSection extends StatefulWidget {
  final AppUser? selectedCustomer;
  final Person? selectedPerson;
  final ValueChanged<AppUser?> onCustomerChanged;
  final ValueChanged<Person?> onPersonChanged;
  final String? supplierId;
  final bool showPersonsAsUsers;
  final VoidCallback? onQRScanned;
  final AppUser? defaultCustomer; // Default customer to show initially
  final bool clearable; // Whether the default can be cleared

  const CustomerSection({
    super.key,
    required this.selectedCustomer,
    required this.selectedPerson,
    required this.onCustomerChanged,
    required this.onPersonChanged,
    this.supplierId,
    this.showPersonsAsUsers = true,
    this.onQRScanned,
    this.defaultCustomer, // Provide a default customer
    this.clearable = true, // Default can be changed/cleared
  });

  @override
  State<CustomerSection> createState() => _CustomerSectionState();
}

class _CustomerSectionState extends State<CustomerSection> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      // Initialize with default customer if none is selected
      if (widget.selectedCustomer == null &&
          widget.selectedPerson == null &&
          widget.defaultCustomer != null) {
        // Use a post-frame callback to ensure UI is ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onCustomerChanged(widget.defaultCustomer);
        });
      }
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    // Determine which type of customer is selected
    final hasCustomer = widget.selectedCustomer != null;
    final hasPerson = widget.selectedPerson != null;
    final hasAnySelection = hasCustomer || hasPerson;

    // Check if this is the default customer
    final isDefaultCustomer =
        widget.selectedCustomer?.idAppUser == widget.defaultCustomer?.idAppUser;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          // Customer Selection Area with QR button
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // QR Code Button
                _buildQRButton(context, theme),

                // Divider
                Container(
                  width: 1,
                  height: 48,
                  color: theme.colorScheme.outline.withOpacity(0.1),
                ),

                // Search Area
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showCustomerSearchDialog(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            hasAnySelection ? Icons.person : Icons.search,
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: !hasAnySelection
                                ? Text(
                                    loc.searchCustomers,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  )
                                : Text(
                                    _getSelectedCustomerName(),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                          ),
                          if (hasAnySelection)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: hasPerson
                                    ? Colors.orange.withOpacity(0.1)
                                    : theme.colorScheme.primary
                                        .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: hasPerson
                                      ? Colors.orange.withOpacity(0.3)
                                      : theme.colorScheme.primary
                                          .withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                hasPerson ? loc.persons : loc.users,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: hasPerson
                                      ? Colors.orange
                                      : theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Selected Customer/Person Card
          if (hasAnySelection) ...[
            const SizedBox(height: 12),
            _buildCustomerInfoCard(context, theme, loc, isDefaultCustomer),
          ],
        ],
      ),
    );
  }

  Widget _buildQRButton(BuildContext context, ThemeData theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleQRCodeOption(context),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.qr_code_scanner_rounded,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSelectedCustomerName() {
    if (widget.selectedCustomer != null) {
      return '${widget.selectedCustomer!.personFirstName} ${widget.selectedCustomer!.personLastName}';
    } else if (widget.selectedPerson != null) {
      return widget.selectedPerson!.fullName;
    }
    return '';
  }

  Widget _buildCustomerInfoCard(
    BuildContext context,
    ThemeData theme,
    AppLocalizations loc,
    bool isDefaultCustomer,
  ) {
    final isPerson = widget.selectedPerson != null;
    final name = isPerson
        ? widget.selectedPerson!.fullName
        : '${widget.selectedCustomer!.personFirstName} ${widget.selectedCustomer!.personLastName}';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isPerson
              ? Colors.orange.withOpacity(0.2)
              : isDefaultCustomer
                  ? Colors.green.withOpacity(0.2) // Different color for default
                  : theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Avatar with default indicator
            Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isPerson
                          ? [Colors.orange, Colors.deepOrange]
                          : isDefaultCustomer
                              ? [
                                  Colors.green,
                                  Colors.greenAccent
                                ] // Different for default
                              : [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.secondary,
                                ],
                    ),
                  ),
                  child: Icon(
                    isPerson ? Icons.person_outline : Icons.person,
                    color: theme.colorScheme.onPrimary,
                    size: 20,
                  ),
                ),
                if (isDefaultCustomer)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 8,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (isDefaultCustomer)
                              Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.green.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    'Default',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (isPerson)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            loc.persons,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (isPerson && widget.selectedPerson!.age != null)
                    Text(
                      '${widget.selectedPerson!.age} years',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            // Only show clear button if customer is clearable
            if (widget.clearable || !isDefaultCustomer)
              IconButton(
                icon: Icon(
                  Icons.delete_forever,
                  color: isPerson ? Colors.orange : theme.colorScheme.primary,
                  size: 20,
                ),
                onPressed: () {
                  // Clear both selections
                  widget.onCustomerChanged(null);
                  widget.onPersonChanged(null);
                },
                tooltip: loc.changeCustomer,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleQRCodeOption(BuildContext context) async {
    if (widget.onQRScanned != null) {
      // If callback is provided, use it
      widget.onQRScanned!();
      return;
    }

    // Default QR handling
    final qrCode = await Navigator.pushNamed(context, AppRoutes.QRScanPage);
    if (qrCode is! String || qrCode.isEmpty) return;

    final userId = extractUserIdFromQR(qrCode);
    if (userId == null) {
      _showErrorMessage(context, 'Invalid QR code');
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final userNotifier = context.read<AppUserNotifier>();
      final AppUser? user = await userNotifier.fetchUserPassively(userId);

      Navigator.pop(context); // Dismiss loading

      if (user == null) {
        _showErrorMessage(context, 'User not found');
        return;
      }

      // Select the user
      widget.onCustomerChanged(user);
      widget.onPersonChanged(null);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Customer selected: ${user.personFirstName}'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Dismiss loading
      _showErrorMessage(context, 'Failed to fetch user: $e');
    }
  }

  void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showCustomerSearchDialog(BuildContext context) async {
    final result = await showDialog<dynamic>(
      context: context,
      builder: (context) => CustomerSearchDialog(
        onCustomerSelected: (customer) {
          widget.onCustomerChanged(customer);
        },
        onPersonSelected: (person) {
          widget.onPersonChanged(person);
        },
        supplierId: int.tryParse(widget.supplierId ?? "0"),
        currentSelectedCustomer: widget.selectedCustomer,
        showPersonsAsUsers: widget.showPersonsAsUsers,
      ),
    );
  }
}
