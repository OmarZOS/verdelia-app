import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/app/Person.dart';
import 'package:verdelia_core/app/Address.dart';
import 'package:verdelia_core/business/Delivery.dart';
import 'package:ui/components/location/address_form.dart';

class DeliveryUIManager {
  // Private constructor to prevent instantiation
  DeliveryUIManager._();

  // ========== DATA MODELS & UTILITIES ==========

  // Delivery type data models
  static List<DeliveryType> getDeliveryTypes(AppLocalizations loc) {
    return [
      DeliveryType(
        id: 'pickup',
        icon: Icons.store_mall_directory_rounded,
        label: loc.pickup,
        description: loc.pickupDesc,
        color: Colors.blue,
        gradient: const [Color(0xFF2196F3), Color(0xFF21CBF3)],
      ),
      DeliveryType(
        id: 'delivery',
        icon: Icons.delivery_dining_rounded,
        label: loc.delivery,
        description: loc.deliveryDesc,
        color: Colors.green,
        gradient: const [Color(0xFF4CAF50), Color(0xFF8BC34A)],
      ),
    ];
  }

  // Parse dimensions from string
  static DimensionData? parseDimensions(String dimensions) {
    final regex = RegExp(
        r'(\d+(?:\.\d+)?)\s*[xX×]\s*(\d+(?:\.\d+)?)\s*[xX×]\s*(\d+(?:\.\d+)?)\s*([a-zA-Z]+)');
    final match = regex.firstMatch(dimensions);

    if (match != null && match.groupCount >= 4) {
      return DimensionData(
        length: double.tryParse(match.group(1)!) ?? 0.0,
        width: double.tryParse(match.group(2)!) ?? 0.0,
        height: double.tryParse(match.group(3)!) ?? 0.0,
        unit: match.group(4)!,
      );
    }
    return null;
  }

  // Format dimensions to string
  static String formatDimensions(DimensionData dimensions) {
    return '${dimensions.length}x${dimensions.width}x${dimensions.height} ${dimensions.unit}';
  }

  // Create delivery data from customer info
  static DeliveryData createDeliveryDataFromCustomer({
    required Person? customer,
    required Address? address,
  }) {
    return DeliveryData(
      deliveryAddressId: address?.id_address ?? 0,
      recipientPerson: customer?.id_person ?? 0,
      deliveryMerchantName: customer?.fullName ?? '',
      deliveryCurrentAddressId: address?.id_address ?? 0,
    );
  }

  // ========== VALIDATION ==========

  static String? validatePackageCount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter package count';
    }

    final count = int.tryParse(value);
    if (count == null) {
      return 'Please enter a valid number';
    }

    if (count <= 0) {
      return 'Package count must be greater than zero';
    }

    if (count > 999) {
      return 'Package count cannot exceed 999';
    }

    return null;
  }

  static String? validateWeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter weight';
    }

    final weight = double.tryParse(value);
    if (weight == null) {
      return 'Please enter a valid number';
    }

    if (weight <= 0) {
      return 'Weight must be greater than zero';
    }

    if (weight > 1000) {
      return 'Weight cannot exceed 1000 kg';
    }

    return null;
  }

  // ========== PRICE ESTIMATION ==========

  static Future<double> estimateDeliveryPrice({
    required DeliveryData deliveryData,
    Duration delay = const Duration(milliseconds: 500),
  }) async {
    await Future.delayed(delay);

    final basePrice = 5.0;
    final weightMultiplier = (deliveryData.deliveryTotalWeight ?? 0) * 0.5;
    final shippingMultiplier = switch (deliveryData.deliveryShippingMethod) {
      'express' => 1.5,
      'overnight' => 2.0,
      'freight' => 3.0,
      _ => 1.0,
    };

    return (basePrice + weightMultiplier) * shippingMultiplier;
  }

  // ========== PREMIUM UI COMPONENTS ==========

  // Premium delivery option card with animations
  static Widget buildDeliveryOptionCard({
    required BuildContext context,
    required DeliveryType type,
    required bool isSelected,
    required VoidCallback onTap,
    required Animation<double> selectionAnimation,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: selectionAnimation,
      builder: (context, child) {
        final scale = isSelected ? 1.0 + selectionAnimation.value * 0.02 : 1.0;
        final elevation =
            isSelected ? 8.0 + selectionAnimation.value * 4.0 : 2.0;

        return Transform.scale(
          scale: scale,
          child: Card(
            elevation: elevation,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected
                    ? Color.lerp(theme.colorScheme.primary.withOpacity(0.3),
                        theme.colorScheme.primary, selectionAnimation.value)!
                    : theme.colorScheme.outline.withOpacity(0.1),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: type.gradient
                            .map((color) => color.withOpacity(
                                0.1 + selectionAnimation.value * 0.1))
                            .toList(),
                      )
                    : null,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(20),
                  highlightColor: theme.colorScheme.primary.withOpacity(0.1),
                  splashColor: theme.colorScheme.primary.withOpacity(0.2),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated Icon Container
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: type.gradient,
                                  )
                                : LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      theme.colorScheme.surfaceVariant,
                                      theme.colorScheme.surfaceVariant
                                          .withOpacity(0.8),
                                    ],
                                  ),
                            shape: BoxShape.circle,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color:
                                          type.gradient.first.withOpacity(0.3),
                                      blurRadius: 15,
                                      spreadRadius: 3,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            type.icon,
                            color: isSelected
                                ? Colors.white
                                : theme.colorScheme.onSurfaceVariant,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Title with selection indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              type.label,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 24 * selectionAnimation.value,
                                height: 24,
                                child: FadeTransition(
                                  opacity: selectionAnimation,
                                  child: Icon(
                                    Icons.check_circle_rounded,
                                    color: theme.colorScheme.primary,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Description
                        Text(
                          type.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isSelected
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.onSurfaceVariant
                                    .withOpacity(0.8),
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                        ),

                        // Selection indicator bar
                        if (isSelected)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 60 * selectionAnimation.value,
                              height: 4,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: type.gradient,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Premium section header with gradient
  static Widget buildPremiumSectionHeader({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer.withOpacity(0.2),
            theme.colorScheme.secondaryContainer.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Premium text field with floating label
  static Widget buildPremiumTextField({
    required BuildContext context,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? initialValue,
    ValueChanged<String>? onChanged,
    FormFieldValidator<String>? validator,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          floatingLabelStyle: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.error,
              width: 1.5,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.error,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: theme.colorScheme.surface,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: maxLines > 1 ? 20 : 18,
          ),
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          prefixIconColor: theme.colorScheme.onSurfaceVariant,
          suffixIconColor: theme.colorScheme.onSurfaceVariant,
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        onChanged: onChanged,
        validator: validator,
        enabled: enabled,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  // Premium dimensions input with visual feedback
  static Widget buildPremiumDimensionsInput({
    required BuildContext context,
    required TextEditingController lengthController,
    required TextEditingController widthController,
    required TextEditingController heightController,
    required String selectedUnit,
    required List<String> unitOptions,
    required ValueChanged<String?> onUnitChanged,
    required VoidCallback onDimensionChanged,
  }) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildPremiumSectionHeader(
          context: context,
          icon: Icons.aspect_ratio_rounded,
          title: loc.dimensions,
          subtitle: loc.enterPackageDimensions,
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            // Length
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'Length',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  buildPremiumTextField(
                    context: context,
                    label: '',
                    hint: 'L',
                    keyboardType: TextInputType.number,
                    initialValue: lengthController.text,
                    onChanged: (value) {
                      lengthController.text = value;
                      onDimensionChanged();
                    },
                    prefixIcon: Icon(
                      Icons.straighten_rounded,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Width
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'Width',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  buildPremiumTextField(
                    context: context,
                    label: '',
                    hint: 'W',
                    keyboardType: TextInputType.number,
                    initialValue: widthController.text,
                    onChanged: (value) {
                      widthController.text = value;
                      onDimensionChanged();
                    },
                    prefixIcon: Icon(
                      Icons.width_normal_rounded,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Height
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'Height',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  buildPremiumTextField(
                    context: context,
                    label: '',
                    hint: 'H',
                    keyboardType: TextInputType.number,
                    initialValue: heightController.text,
                    onChanged: (value) {
                      heightController.text = value;
                      onDimensionChanged();
                    },
                    prefixIcon: Icon(
                      Icons.height_rounded,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Unit dropdown
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Unit',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  width: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                    ),
                    value: selectedUnit,
                    items: unitOptions.map((unit) {
                      return DropdownMenuItem<String>(
                        value: unit,
                        child: Text(
                          unit,
                          style: theme.textTheme.bodyLarge,
                        ),
                      );
                    }).toList(),
                    onChanged: onUnitChanged,
                    isExpanded: true,
                    icon: Icon(
                      Icons.arrow_drop_down_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    dropdownColor: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ],
        ),

        // Visual dimension preview
        if (lengthController.text.isNotEmpty &&
            widthController.text.isNotEmpty &&
            heightController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: _buildDimensionPreview(
              context,
              length: double.tryParse(lengthController.text) ?? 0,
              width: double.tryParse(widthController.text) ?? 0,
              height: double.tryParse(heightController.text) ?? 0,
              unit: selectedUnit,
            ),
          ),
      ],
    );
  }

  static Widget _buildDimensionPreview(
    BuildContext context, {
    required double length,
    required double width,
    required double height,
    required String unit,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primaryContainer.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Package Preview',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // 3D box visualization
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.inventory_2_rounded,
                    color: theme.colorScheme.primary,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDimensionRow(
                      context,
                      label: 'Length',
                      value: '$length $unit',
                    ),
                    _buildDimensionRow(
                      context,
                      label: 'Width',
                      value: '$width $unit',
                    ),
                    _buildDimensionRow(
                      context,
                      label: 'Height',
                      value: '$height $unit',
                    ),
                    const SizedBox(height: 8),
                    Divider(
                      height: 1,
                      color: theme.colorScheme.outline.withOpacity(0.2),
                    ),
                    const SizedBox(height: 8),
                    _buildDimensionRow(
                      context,
                      label: 'Volume',
                      value:
                          '${(length * width * height).toStringAsFixed(2)} ${unit}³',
                      isTotal: true,
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

  static Widget _buildDimensionRow(
    BuildContext context, {
    required String label,
    required String value,
    bool isTotal = false,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isTotal
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Premium price estimation with animations
  static Widget buildPremiumPriceEstimation({
    required BuildContext context,
    required double estimatedPrice,
    required bool isLoading,
    String? subtitle,
    required Animation<double> priceAnimation,
  }) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: priceAnimation,
      builder: (context, child) {
        return Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.secondaryContainer,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                // Header with loading indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.price_check_rounded,
                          color: theme.colorScheme.onPrimaryContainer,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Estimated Delivery',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onPrimaryContainer,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    if (isLoading)
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation(
                            theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Price display with count-up animation
                FadeTransition(
                  opacity: priceAnimation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                      CurvedAnimation(
                        parent: priceAnimation,
                        curve: Curves.elasticOut,
                      ),
                    ),
                    child: Text(
                      '\$${(estimatedPrice * priceAnimation.value).toStringAsFixed(2)}',
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onPrimaryContainer,
                        fontSize: 48,
                        letterSpacing: -1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Subtitle
                if (subtitle != null)
                  FadeTransition(
                    opacity: priceAnimation,
                    child: Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer
                            .withOpacity(0.9),
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Progress indicator
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: LinearProgressIndicator(
                    value: 0.8,
                    backgroundColor:
                        theme.colorScheme.onPrimaryContainer.withOpacity(0.2),
                    color: theme.colorScheme.onPrimaryContainer,
                    borderRadius: BorderRadius.circular(10),
                    minHeight: 6,
                  ),
                ),

                // Additional info
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildPriceDetail(
                        context,
                        icon: Icons.schedule_rounded,
                        label: 'Delivery Time',
                        value: '2-3 days',
                      ),
                      _buildPriceDetail(
                        context,
                        icon: Icons.local_shipping_rounded,
                        label: 'Shipping',
                        value: 'Standard',
                      ),
                      _buildPriceDetail(
                        context,
                        icon: Icons.verified_rounded,
                        label: 'Insurance',
                        value: 'Included',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildPriceDetail(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: theme.colorScheme.onPrimaryContainer.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.onPrimaryContainer,
            size: 18,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // Premium quick fill button with ripple effect
  static Widget buildPremiumQuickFillButton({
    required BuildContext context,
    required VoidCallback onPressed,
    bool enabled = true,
    required Animation<double> hoverAnimation,
  }) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return MouseRegion(
      // onEnter: (_) => hoverAnimation.value = 1.0,
      // onExit: (_) => hoverAnimation.value = 0.0,
      child: AnimatedBuilder(
        animation: hoverAnimation,
        builder: (context, child) {
          return GestureDetector(
            onTap: enabled ? onPressed : null,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary
                        .withOpacity(0.1 + hoverAnimation.value * 0.1),
                    theme.colorScheme.secondary
                        .withOpacity(0.1 + hoverAnimation.value * 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.primary
                      .withOpacity(0.2 + hoverAnimation.value * 0.2),
                  width: 1 + hoverAnimation.value,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary
                        .withOpacity(0.1 * hoverAnimation.value),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Animated icon
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary
                              .withOpacity(0.3 * (1 + hoverAnimation.value)),
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.useCustomerAddress,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Fill address details automatically from customer profile',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Animated arrow
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    transform: Matrix4.translationValues(
                      10 * hoverAnimation.value,
                      0,
                      0,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Premium delivery details form
  static Widget buildPremiumDeliveryDetailsForm({
    required BuildContext context,
    required DeliveryData deliveryData,
    required GlobalKey<FormState> formKey,
    required TextEditingController lengthController,
    required TextEditingController widthController,
    required TextEditingController heightController,
    required String selectedUnit,
    required List<String> unitOptions,
    required ValueChanged<DeliveryData> onDataChanged,
    required ValueChanged<String?> onUnitChanged,
    required VoidCallback onDimensionChanged,
    required Animation<double> formAnimation,
  }) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return AnimatedBuilder(
      animation: formAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - formAnimation.value)),
          child: Opacity(
            opacity: formAnimation.value,
            child: Card(
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Form header
                        buildPremiumSectionHeader(
                          context: context,
                          icon: Icons.inventory_2_rounded,
                          title: loc.packageDetails,
                          subtitle:
                              'Enter package specifications for accurate delivery',
                        ),
                        const SizedBox(height: 32),

                        // Package count and weight
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Package Count',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  buildPremiumTextField(
                                    context: context,
                                    label: '',
                                    hint: 'e.g., 1, 2, 3',
                                    keyboardType: TextInputType.number,
                                    initialValue:
                                        (deliveryData.deliveryPackageCount ??
                                                    0) >
                                                0
                                            ? deliveryData.deliveryPackageCount
                                                .toString()
                                            : '',
                                    validator: validatePackageCount,
                                    onChanged: (value) {
                                      final newData = deliveryData.copyWith(
                                        deliveryPackageCount:
                                            int.tryParse(value) ?? 0,
                                      );
                                      onDataChanged(newData);
                                    },
                                    prefixIcon: Icon(
                                      Icons.layers_rounded,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Weight (kg)',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  buildPremiumTextField(
                                    context: context,
                                    label: '',
                                    hint: 'e.g., 5.5',
                                    keyboardType: TextInputType.number,
                                    initialValue:
                                        (deliveryData.deliveryTotalWeight ??
                                                    0) >
                                                0
                                            ? deliveryData.deliveryTotalWeight
                                                .toString()
                                            : '',
                                    validator: validateWeight,
                                    onChanged: (value) {
                                      final newData = deliveryData.copyWith(
                                        deliveryTotalWeight:
                                            double.tryParse(value) ?? 0.0,
                                      );
                                      onDataChanged(newData);
                                    },
                                    prefixIcon: Icon(
                                      Icons.scale_rounded,
                                      size: 20,
                                    ),
                                    suffixIcon: Text(
                                      'kg',
                                      style:
                                          theme.textTheme.bodyLarge?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Dimensions
                        buildPremiumDimensionsInput(
                          context: context,
                          lengthController: lengthController,
                          widthController: widthController,
                          heightController: heightController,
                          selectedUnit: selectedUnit,
                          unitOptions: unitOptions,
                          onUnitChanged: onUnitChanged,
                          onDimensionChanged: onDimensionChanged,
                        ),
                        const SizedBox(height: 32),

                        // Goods description
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Goods Description',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            buildPremiumTextField(
                              context: context,
                              label: '',
                              hint: 'Describe what is being delivered...',
                              maxLines: 3,
                              initialValue:
                                  deliveryData.deliveryGoodsDescription,
                              onChanged: (value) {
                                final newData = deliveryData.copyWith(
                                  deliveryGoodsDescription: value,
                                );
                                onDataChanged(newData);
                              },
                              prefixIcon: Icon(
                                Icons.description_rounded,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // HS Code
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HS Code (Optional)',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            buildPremiumTextField(
                              context: context,
                              label: '',
                              hint: 'Harmonized System code for customs',
                              initialValue: deliveryData.hsCode,
                              onChanged: (value) {
                                final newData = deliveryData.copyWith(
                                  hsCode: value,
                                );
                                onDataChanged(newData);
                              },
                              prefixIcon: Icon(
                                Icons.code_rounded,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Address form section
                        buildPremiumSectionHeader(
                          context: context,
                          icon: Icons.location_on_rounded,
                          title: 'Delivery Address',
                          subtitle: 'Enter the delivery destination',
                        ),
                        const SizedBox(height: 24),
                        AddressForm(
                          onAddressChanged: (address) {
                            // Handle address changes
                            // print(
                            //     'Address changed: ${address.formattedSingleLine}');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Enhanced success message with animation
  static void showPremiumSuccessMessage(BuildContext context, String message) {
    final theme = Theme.of(context);

    // Create overlay for animated success icon
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 100,
        left: MediaQuery.of(context).size.width / 2 - 60,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 48,
                ),
                SizedBox(height: 8),
                Text(
                  'Success!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Remove overlay after animation
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });

    // Show snackbar message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: theme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  // Get delivery type by ID
  static DeliveryType? getDeliveryTypeById(String id, AppLocalizations loc) {
    return getDeliveryTypes(loc).firstWhere(
      (type) => type.id == id,
      orElse: () => DeliveryType(
        id: 'unknown',
        icon: Icons.help_outline,
        label: 'Unknown',
        description: 'Unknown delivery type',
        color: Colors.grey,
        gradient: [],
      ),
    );
  }
}

// Enhanced Data Models
class DeliveryType {
  final String id;
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final List<Color> gradient;

  const DeliveryType({
    required this.id,
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.gradient,
  });
}

class DimensionData {
  final double length;
  final double width;
  final double height;
  final String unit;

  const DimensionData({
    required this.length,
    required this.width,
    required this.height,
    required this.unit,
  });

  double get volume => length * width * height;
}
