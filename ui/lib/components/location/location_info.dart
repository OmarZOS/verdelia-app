import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/business/Supplier.dart';
import 'package:event/supplier_change_notifier.dart';
import 'package:ui/components/LocationTile.dart';
// import 'package:ui/components/SupplierProductCard.dart';

// Add this method to your _OrganisationPickerState class
Widget buildLocationInfo(BuildContext context,
    SupplierChangeNotifier supplierNotifier, Supplier supplier) {
  // Find the supplier by name

  // // If supplier not found, show appropriate message
  // if (supplier == null) {
  //   return _buildNoLocationInfo();
  // }

  // Use FutureBuilder to handle the async operation
  return FutureBuilder<Supplier?>(
    future: supplierNotifier.getSupplierById(supplier.idProductProvider),
    builder: (context, snapshot) {
      // Show loading state
      if (snapshot.connectionState == ConnectionState.waiting) {
        return _buildLocationLoading();
      }

      // Show error state
      if (snapshot.hasError) {
        return _buildLocationError('Failed to load location data');
      }

      // Show data
      final detailedSupplier = snapshot.data;
      return _buildResponsiveLocationDetails(
          context, detailedSupplier ?? supplier);
    },
  );
}

// Loading state widget
Widget _buildLocationLoading() {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 12.0),
    child: Center(
      child: SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            Colors.grey[400]!,
          ),
        ),
      ),
    ),
  );
}

// Error state widget
Widget _buildLocationError(String message) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      children: [
        Icon(
          Icons.error_outline,
          size: 14,
          color: Colors.red[400],
        ),
        const SizedBox(width: 6),
        Text(
          message,
          style: TextStyle(
            color: Colors.red[600],
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

// Enhanced no location info widget to match premium style
Widget _buildNoLocationInfo(BuildContext context) {
  return Container(
    margin: const EdgeInsets.only(top: 4, bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      // color: Colors.grey[50],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        // color: Colors.grey,
        width: 1,
      ),
    ),
    child: Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            // color: Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.location_off_outlined,
            size: 16,
            // color: Colors.grey[500],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            AppLocalizations.of(context)!.no_location_information_available,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    ),
  );
}

// Responsive grid version
Widget _buildResponsiveLocationDetails(
    BuildContext context, Supplier supplier) {
  final hasLocationData = (supplier.addressStreet.isNotEmpty) ||
      (supplier.addressCity.isNotEmpty) ||
      (supplier.addressPostalCode.isNotEmpty) ||
      (supplier.addressCountry.isNotEmpty);

  if (!hasLocationData) {
    return _buildNoLocationInfo(context);
  }

  return Container(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLocationTile(context, supplier),
        const SizedBox(height: 8),

        // ✅ Responsive 2-column grid
        LayoutBuilder(
          builder: (context, constraints) {
            final double itemWidth =
                (constraints.maxWidth - 8) / 2; // half width minus spacing

            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (supplier.addressStreet.isNotEmpty)
                  SizedBox(
                    width: itemWidth,
                    child: _buildGridLocationItem(
                      context,
                      supplier.addressStreet,
                      AppLocalizations.of(context)!.streetText,
                      FontAwesomeIcons.road,
                      Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                if (supplier.addressCity.isNotEmpty)
                  SizedBox(
                    width: itemWidth,
                    child: _buildGridLocationItem(
                      context,
                      supplier.addressCity,
                      AppLocalizations.of(context)!.cityText,
                      Icons.location_city_outlined,
                      Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                if (supplier.addressPostalCode.isNotEmpty)
                  SizedBox(
                    width: itemWidth,
                    child: _buildGridLocationItem(
                      context,
                      supplier.addressPostalCode,
                      AppLocalizations.of(context)!.postalCodeText,
                      Icons.local_post_office_outlined,
                      Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                if (supplier.addressCountry.isNotEmpty)
                  SizedBox(
                    width: itemWidth,
                    child: _buildGridLocationItem(
                      context,
                      supplier.addressCountry,
                      AppLocalizations.of(context)!.countryText,
                      Icons.public_outlined,
                      Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );
}

// Premium grid item widget
Widget _buildGridLocationItem(BuildContext context, String text, String label,
    IconData icon, Color color) {
  return Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      // color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: Colors.grey[200]!,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 14,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 12,
                  // fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
