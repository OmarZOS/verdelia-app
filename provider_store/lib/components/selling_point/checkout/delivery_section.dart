import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/app/Person.dart';
import 'package:verdelia_core/app/Address.dart';
import 'package:verdelia_core/business/Delivery.dart';
import 'package:ui/components/document/Delivery_Type_UI_Manager.dart';

class DeliverySection extends StatefulWidget {
  final String selectedType;
  final ValueChanged<String> onChanged;
  final ValueChanged<DeliveryData>? onDeliveryDataChanged;
  final Person? customer;
  final Address? customerAddress;

  const DeliverySection({
    super.key,
    required this.selectedType,
    required this.onChanged,
    this.onDeliveryDataChanged,
    this.customer,
    this.customerAddress,
  });

  @override
  State<DeliverySection> createState() => _DeliverySectionState();
}

class _DeliverySectionState extends State<DeliverySection>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  DeliveryData _deliveryData = DeliveryData();
  bool _isLoadingPrice = false;
  double _estimatedPrice = 0.0;

  // Animation controllers - FIXED: Using mixin instead of ScaffoldMessenger
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  // Dimension controllers
  final TextEditingController _lengthController = TextEditingController();
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  String _selectedUnit = 'cm';
  final List<String> _unitOptions = ['cm', 'm'];

  @override
  void initState() {
    super.initState();
    _initializeDeliveryData();

    // FIXED: Use the SingleTickerProviderStateMixin
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this, // Using 'this' as the vsync provider
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );

    // Initialize animation state based on current selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.selectedType == 'delivery' && mounted) {
        _expandController.forward();
      }
    });
  }

  @override
  void didUpdateWidget(covariant DeliverySection oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle animation when delivery type changes
    if (widget.selectedType != oldWidget.selectedType) {
      if (widget.selectedType == 'delivery') {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _initializeDeliveryData() {
    if (widget.customerAddress != null) {
      _deliveryData = DeliveryUIManager.createDeliveryDataFromCustomer(
        customer: widget.customer,
        address: widget.customerAddress,
      );
    }
    _parseExistingDimensions();
  }

  void _parseExistingDimensions() {
    if (_deliveryData.deliveryCargoDimensions?.isNotEmpty == true) {
      final dimensions = DeliveryUIManager.parseDimensions(
        _deliveryData.deliveryCargoDimensions ?? "",
      );
      if (dimensions != null) {
        // Use a post-frame callback to avoid setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _lengthController.text = dimensions.length.toString();
              _widthController.text = dimensions.width.toString();
              _heightController.text = dimensions.height.toString();
              _selectedUnit = dimensions.unit;
            });
          }
        });
      }
    }
  }

  void _updateDimensions() {
    final dimensions = _buildDimensions();
    _deliveryData = _deliveryData.copyWith(
      deliveryCargoDimensions: dimensions ?? '',
    );

    if (mounted) setState(() {});
    _notifyDataChanged();

    if (dimensions != null) _estimatePrice();
  }

  String? _buildDimensions() {
    final l = _parseDouble(_lengthController.text);
    final w = _parseDouble(_widthController.text);
    final h = _parseDouble(_heightController.text);

    if (l == null || w == null || h == null) return null;

    return DeliveryUIManager.formatDimensions(
      DimensionData(length: l, width: w, height: h, unit: _selectedUnit),
    );
  }

  double? _parseDouble(String value) {
    final trimmed = value.trim();
    return trimmed.isNotEmpty ? double.tryParse(trimmed) : null;
  }

// ============================================================================
// PRICE ESTIMATION
// ============================================================================

  void _estimatePrice() async {
    if (!_canEstimatePrice()) return;

    _setLoading(true);

    try {
      final price = await DeliveryUIManager.estimateDeliveryPrice(
        deliveryData: _deliveryData,
      );

      if (mounted) {
        _updateWithPrice(price);
      }
    } catch (_) {
      _setLoading(false);
    }
  }

  bool _canEstimatePrice() {
    return (_deliveryData.deliveryAddressId ?? 0) > 0 &&
        (_deliveryData.deliveryTotalWeight ?? 0) > 0;
  }

  void _setLoading(bool loading) {
    if (mounted) {
      setState(() => _isLoadingPrice = loading);
    }
  }

  void _updateWithPrice(double price) {
    if (!mounted) return;

    setState(() {
      _estimatedPrice = price;
      _deliveryData = _deliveryData.copyWith(deliveryFee: price);
      _isLoadingPrice = false;
    });

    _notifyDataChanged();
  }

  void _notifyDataChanged() {
    widget.onDeliveryDataChanged?.call(_deliveryData);
  }

  void _fillCustomerAddress() {
    if (widget.customerAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No customer address available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final newData = DeliveryUIManager.createDeliveryDataFromCustomer(
      customer: widget.customer,
      address: widget.customerAddress,
    );

    setState(() => _deliveryData = newData);

    _notifyDataChanged();
    _estimatePrice();

    // Quick visual feedback
    // HapticFeedback.lightImpact();

    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text(
    //         'Address filled from ${widget.customer?.fullName ?? 'customer'}'),
    //     duration: const Duration(seconds: 2),
    //   ),
    // );
  }

  void _handleDataChanged(DeliveryData newData) {
    if (mounted) {
      setState(() {
        _deliveryData = newData;
      });
    }
    _notifyDataChanged();
    _estimatePrice();
  }

  void _onDeliveryTypeChanged(String type) {
    widget.onChanged(type);
    if (type == 'delivery') {
      _expandController.forward();
    } else {
      _expandController.reverse();
      if (mounted) {
        setState(() {
          _deliveryData = DeliveryData();
        });
      }
      widget.onDeliveryDataChanged?.call(_deliveryData);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final deliveryTypes = DeliveryUIManager.getDeliveryTypes(loc);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced Header
          _buildEnhancedHeader(context, theme, loc),
          const SizedBox(height: 16),

          // Delivery Type Cards with enhanced design
          _buildDeliveryTypeCards(context, theme, deliveryTypes),
          const SizedBox(height: 20),

          // Animated Delivery Form
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: FadeTransition(
              opacity: _expandAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDeliveryFormSection(context, theme, loc),
                  if (_estimatedPrice > 0) ...[
                    const SizedBox(height: 16),
                    _buildEnhancedPriceEstimation(context, theme, loc),
                  ],
                  if (widget.customerAddress != null) ...[
                    const SizedBox(height: 12),
                    _buildEnhancedQuickFillButton(context, theme, loc),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedHeader(
      BuildContext context, ThemeData theme, AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primaryContainer.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_shipping_rounded,
              color: theme.colorScheme.onPrimaryContainer,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.deliveryType,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loc.selectDeliveryType,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (widget.selectedType == 'delivery' && _estimatedPrice > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.attach_money,
                    size: 14,
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '\$${_estimatedPrice.toStringAsFixed(2)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeliveryTypeCards(
    BuildContext context,
    ThemeData theme,
    List<DeliveryType> deliveryTypes,
  ) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: deliveryTypes.map((type) {
        final isSelected = widget.selectedType == type.id;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withOpacity(0.1),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _onDeliveryTypeChanged(type.id),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        type.icon,
                        color: isSelected
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      type.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      type.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.onPrimaryContainer
                                .withOpacity(0.8)
                            : theme.colorScheme.onSurfaceVariant,
                        overflow: TextOverflow.ellipsis,
                      ),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          size: 16,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDeliveryFormSection(
    BuildContext context,
    ThemeData theme,
    AppLocalizations loc,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Form Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.inventory_2_rounded,
                    color: theme.colorScheme.onSecondaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  loc.deliveryDetails,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Delivery Details Form
            DeliveryUIManager.buildPremiumDeliveryDetailsForm(
              context: context,
              deliveryData: _deliveryData,
              formKey: _formKey,
              lengthController: _lengthController,
              widthController: _widthController,
              heightController: _heightController,
              selectedUnit: _selectedUnit,
              unitOptions: _unitOptions,
              onDataChanged: _handleDataChanged,
              onUnitChanged: (value) {
                setState(() {
                  _selectedUnit = value ?? 'cm';
                  _updateDimensions();
                });
              },
              onDimensionChanged: _updateDimensions,
              formAnimation: Tween<double>(begin: 0, end: 1).animate(
                CurvedAnimation(
                  parent: ModalRoute.of(context)!.animation!,
                  curve: Curves.easeInOut,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedPriceEstimation(
    BuildContext context,
    ThemeData theme,
    AppLocalizations loc,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer.withOpacity(0.8),
            theme.colorScheme.tertiaryContainer.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.attach_money_rounded,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    loc.estimatedDeliveryFee,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              if (_isLoadingPrice)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                      theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Cost', // You might need to add this to your localizations
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loc.priceMayChange,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onPrimaryContainer.withOpacity(0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  '\$${_estimatedPrice.toStringAsFixed(2)}',
                  key: ValueKey(_estimatedPrice),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onPrimaryContainer,
                    fontSize: 32,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: 0.7,
            backgroundColor:
                theme.colorScheme.onPrimaryContainer.withOpacity(0.1),
            color: theme.colorScheme.onPrimaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedQuickFillButton(
    BuildContext context,
    ThemeData theme,
    AppLocalizations loc,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.secondaryContainer,
            theme.colorScheme.primaryContainer.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _fillCustomerAddress,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onPrimaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_fix_high_rounded,
                    color: theme.colorScheme.primaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.useCustomerAddress,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fill address from customer profile', // You might need to add this to your localizations
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer
                              .withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
