import 'package:app_constants/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:verdelia_core/app/AppUser.dart';
import 'package:verdelia_core/app/Person.dart';
import 'package:event/cart_change_notifier.dart';
import 'package:event/product_change_notifier.dart';
import 'package:event/user_change_notifier.dart';
import 'package:event/views/checkout_view_model.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:provider_store/components/selling_point/checkout/checkout_footer.dart';
import 'package:provider_store/components/selling_point/checkout/delivery_section.dart';
import 'package:provider_store/components/selling_point/checkout/document_type_section.dart';
import 'package:provider_store/components/selling_point/checkout/notes_parameters_section.dart';
import 'package:provider_store/components/selling_point/checkout/order_items_section.dart';
import 'package:provider_store/components/selling_point/checkout/payment_section.dart';
import 'package:ui/components/document/Delivery_Type_UI_Manager.dart';
import 'package:ui/components/document/DocumentTypeManager.dart';
import 'package:ui/components/finance/Payment_Type_UI_Manager.dart';
import 'package:ui/components/search/customer_search_section.dart';

class CheckoutScreen extends StatefulWidget {
  final int supplierId;

  const CheckoutScreen({super.key, required this.supplierId});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late final CheckoutViewModel _viewModel;
  final _formKey = GlobalKey<FormState>();

  final Map<_Section, bool> _expanded = {
    _Section.customer: true,
    _Section.items: true,
    _Section.document: false,
    _Section.payment: false,
    _Section.delivery: false,
    _Section.notes: false,
  };

  /// Guards against re-entry: `_processCheckout` may be invoked from
  /// a race between the button and the keyboard's submit action.
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _viewModel = CheckoutViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _toggle(_Section section) {
    setState(() => _expanded[section] = !(_expanded[section] ?? false));
  }

  // ==================== CHECKOUT FLOW ====================

  Future<void> _processCheckout() async {
    if (_isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? true)) return;

    final cart = context.read<CartChangeNotifier>();
    final user = context.read<AppUserNotifier>();
    final products = context.read<ProductNotifier>();
    final loc = AppLocalizations.of(context)!;

    if (cart.cart.isEmpty) {
      _showError(loc.cartEmptyError);
      return;
    }

    final currentUser = user.appUser;
    if (currentUser == null) {
      _showError(loc.loginRequiredError);
      return;
    }

    final confirmed = await _confirm();
    if (confirmed != true || !mounted) return;

    setState(() => _isSubmitting = true);

    try {
      // Freeze the total before the cart is cleared so the success
      // dialog shows the amount that was actually paid.
      final totalAmount = cart.cart.subtotal;

      final result = await _viewModel.processCartCheckout(
        cart: cart.cart,
        sellingUserId: currentUser.idAppUser ?? 0,
        providerId: widget.supplierId,
      );

      if (!mounted) return;

      if (!result.isSuccess) {
        _showError(result.message);
        return;
      }

      await products.fetchProducts(
        providerId: products.currentProviderId,
        reset: true,
      );
      if (!mounted) return;

      cart.clearCart();
      _viewModel.resetAfterCheckout();

      await _showSuccess(result, totalAmount);
      if (!mounted) return;
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<bool?> _confirm() {
    final cart = context.read<CartChangeNotifier>();
    final loc = AppLocalizations.of(context)!;
    final vm = _viewModel;

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.confirmCheckout),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.checkoutSummary,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              if (vm.selectedCustomer != null || vm.selectedPerson != null)
                _SummaryRow(
                  icon: Icons.person,
                  title: loc.customer,
                  value: _customerName(vm),
                ),
              _SummaryRow(
                icon: Icons.shopping_cart,
                title: loc.itemsText,
                value: loc.itemsCount(cart.cartItemCount),
              ),
              _SummaryRow(
                icon: Icons.attach_money,
                title: loc.total,
                value: loc.price(cart.cartTotal.toStringAsFixed(2)),
                isTotal: true,
              ),
              const Divider(height: 24),
              _SummaryRow(
                icon: Icons.description,
                title: loc.documentType,
                value: _documentName(vm.documentType, loc),
              ),
              _SummaryRow(
                icon: Icons.payment,
                title: loc.paymentMethod,
                value: _paymentName(vm.paymentMethod, loc),
              ),
              _SummaryRow(
                icon: Icons.local_shipping,
                title: loc.delivery,
                value: _deliveryName(vm.deliveryType, loc),
              ),
              if (vm.notes.isNotEmpty) ...[
                const Divider(height: 24),
                _SummaryRow(
                  icon: Icons.notes,
                  title: loc.notes,
                  value: vm.notes,
                  maxLines: 3,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(loc.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(loc.confirmAndPay),
          ),
        ],
      ),
    );
  }

  Future<void> _showSuccess(CheckoutResult result, double totalAmount) {
    final loc = AppLocalizations.of(context)!;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final cs = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          icon: Icon(
            Icons.check_circle_rounded,
            color: cs.primary,
            size: 48,
          ),
          title: Text(loc.orderSuccessful),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loc.orderPlacedSuccessfully,
                textAlign: TextAlign.center,
              ),
              if (result.orderId != null) ...[
                const SizedBox(height: 16),
                Text(
                  '${loc.orderId}: #${result.orderId}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 8),
              Text(
                '${loc.total}: ${loc.price(totalAmount.toStringAsFixed(2))}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: cs.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).popUntil((route) {
                debugPrint('Route in stack: ${route.settings.name}');
                return route.settings.name == AppRoutes.storeManage;
              }),
              child: Text(loc.continueShopping),
            ),
          ],
        );
      },
    );
  }

  void _showError(String message) {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: scheme.errorContainer,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(12),
        ),
      );
  }

  // ==================== NAME RESOLVERS ====================

  String _customerName(CheckoutViewModel vm) {
    final loc = AppLocalizations.of(context)!;
    if (vm.selectedCustomer != null) {
      final c = vm.selectedCustomer!;
      final name =
          '${c.personFirstName ?? ''} ${c.personLastName ?? ''}'.trim();
      return name.isEmpty ? loc.guest : name;
    }
    if (vm.selectedPerson != null) return vm.selectedPerson!.fullName;
    return loc.guest;
  }

  String _documentName(String type, AppLocalizations loc) {
    switch (type) {
      case 'invoice':
        return loc.invoice;
      case 'receipt':
        return loc.receipt;
      case 'invoice_receipt':
        return loc.invoiceReceipt;
      case 'none':
        return loc.none;
      default:
        return loc.invoiceReceipt;
    }
  }

  String _paymentName(String method, AppLocalizations loc) {
    switch (method) {
      case 'cash':
        return loc.cash;
      case 'card':
        return loc.card;
      case 'bank':
        return loc.bankTransfer;
      case 'mobile':
        return loc.mobileMoney;
      default:
        return method;
    }
  }

  String _deliveryName(String type, AppLocalizations loc) {
    switch (type) {
      case 'pickup':
        return loc.pickup;
      case 'delivery':
        return loc.delivery;
      default:
        return type;
    }
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return ChangeNotifierProvider<CheckoutViewModel>.value(
      value: _viewModel,
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.checkout),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline_rounded),
              onPressed: _showHelp,
              tooltip: loc.help,
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: Stack(
            children: [
              _buildSections(context),
              _buildLoadingOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSections(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Column(
        children: [
          _ExpandableSection(
            sectionKey: const ValueKey('section_customer'),
            title: loc.customer,
            icon: Icons.person_outline_rounded,
            badge: Consumer<CheckoutViewModel>(
              builder: (_, vm, __) => Text(
                _customerName(vm),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            isExpanded: _expanded[_Section.customer]!,
            onToggle: () => _toggle(_Section.customer),
            child: _buildCustomerSection(),
          ),
          _ExpandableSection(
            sectionKey: const ValueKey('section_items'),
            title: loc.itemsText,
            icon: Icons.shopping_cart_outlined,
            badge: Consumer<CartChangeNotifier>(
              builder: (_, cart, __) => Text(
                loc.items(
                  cart.cartItemCount,
                  cart.productItemCount,
                  cart.serviceItemCount,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            isExpanded: _expanded[_Section.items]!,
            onToggle: () => _toggle(_Section.items),
            child: const OrderItemsSection(),
          ),
          _ExpandableSection(
            sectionKey: const ValueKey('section_document'),
            title: loc.documentType,
            icon: Icons.description_outlined,
            badge: Consumer<CheckoutViewModel>(
              builder: (_, vm, __) => Text(
                _documentName(vm.documentType, loc),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            isExpanded: _expanded[_Section.document]!,
            onToggle: () => _toggle(_Section.document),
            child: Consumer<CheckoutViewModel>(
              builder: (_, vm, __) => DocumentTypeSection(
                selectedType: vm.documentType,
                onChanged: vm.setDocumentType,
              ),
            ),
          ),
          _ExpandableSection(
            sectionKey: const ValueKey('section_payment'),
            title: loc.payment,
            icon: Icons.payment_outlined,
            badge: Consumer<CheckoutViewModel>(
              builder: (_, vm, __) => Text(
                PaymentTypeUIManager.getPaymentTypeById(
                      vm.paymentType,
                      loc,
                    )?.label ??
                    vm.paymentType,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            isExpanded: _expanded[_Section.payment]!,
            onToggle: () => _toggle(_Section.payment),
            child: _buildPaymentSection(),
          ),
          _ExpandableSection(
            sectionKey: const ValueKey('section_delivery'),
            title: loc.delivery,
            icon: Icons.local_shipping_outlined,
            badge: Consumer<CheckoutViewModel>(
              builder: (_, vm, __) => Text(
                DeliveryUIManager.getDeliveryTypeById(
                      vm.deliveryType,
                      loc,
                    )?.label ??
                    vm.deliveryType,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            isExpanded: _expanded[_Section.delivery]!,
            onToggle: () => _toggle(_Section.delivery),
            child: _buildDeliverySection(),
          ),
          _ExpandableSection(
            sectionKey: const ValueKey('section_notes'),
            title: loc.notesParameters,
            icon: Icons.note_add_outlined,
            badge: Consumer<CheckoutViewModel>(
              builder: (_, vm, __) => vm.parameters.isEmpty
                  ? const SizedBox.shrink()
                  : Text('${vm.parameters.length}'),
            ),
            isExpanded: _expanded[_Section.notes]!,
            onToggle: () => _toggle(_Section.notes),
            child: _buildNotesSection(),
          ),
          const SizedBox(height: 16),
          Consumer<CheckoutViewModel>(
            builder: (_, vm, __) => CheckoutFooter(
              onCheckoutPressed: _processCheckout,
              isLoading: vm.isProcessing || _isSubmitting,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection() {
    final loc = AppLocalizations.of(context)!;
    return Consumer<CheckoutViewModel>(
      builder: (context, vm, _) => CustomerSection(
        defaultCustomer: _guestUser(loc),
        selectedCustomer: vm.selectedCustomer,
        selectedPerson: vm.selectedPerson,
        onCustomerChanged: (customer) => vm.setSelectedCustomer(customer, null),
        onPersonChanged: (person) => vm.setSelectedCustomer(null, person),
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Consumer<CheckoutViewModel>(
      builder: (context, vm, _) => PaymentSection(
        paymentType: vm.paymentType,
        paymentMethod: vm.paymentMethod,
        onPaymentTypeChanged: vm.setPaymentType,
        onPaymentMethodChanged: vm.setPaymentMethod,
        onInstallmentDateChanged: vm.setInstallmentDate,
        onDepositChanged: vm.setDepositAmount,
        onCardDetailsChanged: vm.setCardDetails,
        onBankDetailsChanged: vm.setBankDetails,
        onMobileProviderChanged: vm.setMobileProvider,
        onCardTypeChanged: vm.setCardType,
      ),
    );
  }

  Widget _buildDeliverySection() {
    return Consumer<CheckoutViewModel>(
      builder: (context, vm, _) => DeliverySection(
        selectedType: vm.deliveryType,
        onChanged: vm.setDeliveryType,
        onDeliveryDataChanged: vm.setDeliveryData,
        customer: vm.selectedPerson,
      ),
    );
  }

  Widget _buildNotesSection() {
    return Consumer<CheckoutViewModel>(
      builder: (context, vm, _) => NotesParametersSection(
        notes: vm.notes,
        parameters: vm.parameters,
        savedParameters: vm.savedParameters,
        isLoadingParameters: vm.isLoadingParameters,
        onNotesChanged: vm.setNotes,
        onParametersChanged: vm.setParameters,
        onSaveParameter: vm.saveParameter,
        onUpdateParameter: vm.updateParameter,
        onDeleteParameter: vm.deleteParameter,
        onUseSavedParameter: vm.useSavedParameter,
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Selector<CheckoutViewModel, bool>(
      selector: (_, vm) => vm.isProcessing || _isSubmitting,
      builder: (context, isProcessing, _) {
        if (!isProcessing) return const SizedBox.shrink();
        return Positioned.fill(
          child: AbsorbPointer(
            child: ColoredBox(
              color: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.4),
              child: const Center(child: CircularProgressIndicator.adaptive()),
            ),
          ),
        );
      },
    );
  }

  AppUser _guestUser(AppLocalizations loc) {
    return AppUser(
      idAppUser: 0,
      appUserPersonId: 0,
      appUserType: AppUserType.guest,
      appUserName: 'guest',
      appUserPassword: '',
      appUserPreferences: '',
      appUserImageUrl: '',
      idPerson: 0,
      personDetailsId: 0,
      personFirstName: loc.guestCustomer,
      personLastName: '',
      personBirthDate: '',
      appUserEmail: loc.guestEmail,
      personGender: Gender.unspecified,
      personCountryCode: '',
      bloodType: 'B+',
      idLocation: 0,
      locationLatitude: 0.0,
      locationLongitude: 0.0,
      locationName: loc.guestLocation,
      locationAddressId: 0,
      addressStreet: '',
      addressCity: '',
      addressPostalCode: '',
      addressCountry: '',
      privileges: [],
    );
  }

  void _showHelp() {
    final loc = AppLocalizations.of(context)!;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.checkoutHelp),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HelpItem(
                icon: Icons.person_outline_rounded,
                title: loc.customer,
                description: loc.customerHelpDescription,
              ),
              _HelpItem(
                icon: Icons.shopping_cart_outlined,
                title: loc.itemsText,
                description: loc.itemsHelpDescription,
              ),
              _HelpItem(
                icon: Icons.description_outlined,
                title: loc.documentType,
                description: loc.documentTypeHelpDescription,
              ),
              _HelpItem(
                icon: Icons.payment_outlined,
                title: loc.paymentMethod,
                description: loc.paymentMethodHelpDescription,
              ),
              _HelpItem(
                icon: Icons.local_shipping_outlined,
                title: loc.delivery,
                description: loc.deliveryHelpDescription,
              ),
              _HelpItem(
                icon: Icons.note_add_outlined,
                title: loc.notesParameters,
                description: loc.notesParametersHelpDescription,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(loc.gotIt),
          ),
        ],
      ),
    );
  }
}

// ==================== SUPPORTING WIDGETS ====================

enum _Section { customer, items, document, payment, delivery, notes }

class _ExpandableSection extends StatelessWidget {
  final Key? sectionKey;
  final String title;
  final IconData icon;
  final Widget? badge;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget child;

  const _ExpandableSection({
    this.sectionKey,
    required this.title,
    required this.icon,
    this.badge,
    required this.isExpanded,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      key: sectionKey,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color:
                        isExpanded ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color:
                                isExpanded ? scheme.primary : scheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (badge != null) ...[
                          const SizedBox(height: 2),
                          DefaultTextStyle.merge(
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            child: badge!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: isExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: child,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isTotal;
  final int maxLines;

  const _SummaryRow({
    required this.icon,
    required this.title,
    required this.value,
    this.isTotal = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final titleStyle = TextStyle(
      fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
      color: scheme.onSurfaceVariant,
    );
    final valueStyle = TextStyle(
      fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
      color: isTotal ? scheme.primary : scheme.onSurface,
      fontSize: isTotal ? 16 : 14,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment:
            maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              '$title:',
              style: titleStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: valueStyle,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _HelpItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
