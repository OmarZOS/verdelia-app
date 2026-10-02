import 'dart:developer';

import 'package:app_constants/app_routes.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:app_constants/app_constants.dart';
import 'package:event/extensions/personnel_access_manager.dart';
import 'package:event/personnel_notifier.dart';
import 'package:event/supplier_change_notifier.dart';
import 'package:event/user_change_notifier.dart';
import 'package:provider_geo/screens/supplier_form_page.dart';
import 'package:ui/components/floating_buttons.dart';
import 'package:ui/components/supplier/supplier_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider_geo/screens/map_locations_screen.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:provider/provider.dart';
import '../components/suppliers_panel.dart';

class SuppliersMapScreen extends StatefulWidget {
  const SuppliersMapScreen({Key? key}) : super(key: key);

  @override
  _SuppliersMapScreenState createState() => _SuppliersMapScreenState();
}

class _SuppliersMapScreenState extends State<SuppliersMapScreen> {
  late final TextEditingController _searchController;
  GoogleMapController? _mapController;
  final PanelController _panelController = PanelController();
  dynamic _selectedLocation;
  final ValueNotifier<bool> _isFilterApplied = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _fetchLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _isFilterApplied.dispose();
    super.dispose();
  }

  void onDeleteLocationFilter() {
    Provider.of<SupplierChangeNotifier>(context, listen: false).fetchSuppliers(
      reset: true,
    );
    setState(() {
      _selectedLocation = null;
      _isFilterApplied.value = false;
    });
  }

  Future<void> _fetchLocation() async {
    Provider.of<SupplierChangeNotifier>(context, listen: false)
        .fetchSuppliers();

    await Provider.of<SupplierChangeNotifier>(context, listen: false)
        .getCurrentLocation();
  }

  void _focusOnLocation(double latitude, double longitude,
      {double zoomLevel = 5}) {
    _panelController.close();
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(latitude, longitude),
        zoomLevel,
      ),
    );
  }

  void _applyLocationFilter(dynamic location) {
    _focusOnLocation(location["latitude"], location["longitude"],
        zoomLevel: location["zoom_level"]);
    setState(() {
      _selectedLocation = location;
      _isFilterApplied.value = true;
      _handleGeoSearch(location);
    });
  }

  void _handleGeoSearch(dynamic location) {
    Provider.of<SupplierChangeNotifier>(context, listen: false)
        .searchSuppliersByGeo(
      longitude: location["longitude"],
      latitude: location["latitude"],
      radiusKm: location["radius_km"],
      reset: true,
    );
    _panelController.open();
  }

  void _handleSearch(String query) {
    Provider.of<SupplierChangeNotifier>(context, listen: false)
        .searchSuppliers(query);
    _panelController.open();
  }

  // ============================================================
  // ✅ FIX: Get dashboard data for speed dial navigation
  // ============================================================

  Future<Map<String, dynamic>> _getDashboardData() async {
    final personnelNotifier = context.read<PersonnelNotifier>();
    final supplierNotifier = context.read<SupplierChangeNotifier>();
    final userNotifier = context.read<AppUserNotifier>();

    final userId = userNotifier.appUser?.idAppUser ?? 0;

    final accessManager = PersonnelAccessManager(
      personnelNotifier: personnelNotifier,
      supplierNotifier: supplierNotifier,
    );

    final userRules = personnelNotifier.getRulesForUser(userId);
    final suppliersWithAccess =
        await accessManager.getAccessibleSuppliersWithAccessType(
      userId,
      forceRefresh: false,
    );
    final suppliers = suppliersWithAccess.map((s) => s.supplier).toList();
    final supplierIds = suppliersWithAccess.map((s) => s.id).toList();

    return {
      'userId': userId,
      'supplierIds': supplierIds,
      'userRules': userRules,
      'suppliers': suppliers,
      'suppliersWithAccess': suppliersWithAccess,
    };
  }

  // ============================================================
  // ✅ FIX: Navigate to SupplierEntitiesScreen with arguments
  // ============================================================

  Future<void> _navigateToSupplierEntities() async {
    final data = await _getDashboardData();

    if (!mounted) return;

    Navigator.pushNamed(
      context,
      AppRoutes.supplierEntitiesPage,
      arguments: {
        'userId': data['userId'],
        'accessibleSuppliers': data['supplierIds'],
        'userRules': data['userRules'],
        'suppliers': data['suppliers'],
        'suppliersWithAccess': data['suppliersWithAccess'],
      },
    );
  }

  // ============================================================
  // ✅ FIX: Navigate to Store Manage
  // ============================================================

  void _navigateToStoreManage() {
    Navigator.pushNamed(context, AppRoutes.storeManage);
  }

  // ============================================================
  // ✅ FIX: Navigate to Provider Create
  // ============================================================

  void _navigateToProviderCreate() {
    Navigator.pushNamed(context, AppRoutes.providerCreate);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      floatingActionButton: CustomSpeedDial(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        horizontalButtons: [
          SpeedDialButton(
            icon: Icon(Icons.add_business,
                color: Theme.of(context).colorScheme.onPrimary),
            label: AppLocalizations.of(context)?.addSupplierTxt,
            backgroundColor: Theme.of(context).colorScheme.primary,
            onTap: _navigateToProviderCreate,
          ),
        ],
        verticalButtons: [
          SpeedDialButton(
            icon: Icon(FontAwesomeIcons.moneyBill1Wave,
                color: Theme.of(context).colorScheme.onPrimary),
            label: AppLocalizations.of(context)?.businesses,
            backgroundColor: Theme.of(context).colorScheme.primary,
            onTap: _navigateToSupplierEntities,
          ),
          SpeedDialButton(
            icon: Icon(FontAwesomeIcons.store,
                color: Theme.of(context).colorScheme.onPrimary),
            label: AppLocalizations.of(context)?.manageSuppliers,
            backgroundColor: Theme.of(context).colorScheme.primary,
            onTap: _navigateToStoreManage,
          ),
        ],
      ),
      appBar: AppBar(
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onChanged: _handleSearch,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)?.searchTxt,
              prefixIcon: Icon(Icons.search_outlined,
                  color: Theme.of(context).colorScheme.onSurface),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
      body: Stack(
        children: [
          if (kIsWeb || defaultTargetPlatform == TargetPlatform.linux)
            Container(
              color: Theme.of(context).colorScheme.surfaceVariant,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc.mapNotAvailableText,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            )
          else
            Consumer<SupplierChangeNotifier>(
              builder: (context, supplierNotifier, child) {
                return MapScreen(
                  onMapCreated: (controller) => _mapController = controller,
                  userLocation: supplierNotifier.currentLocation,
                  suppliers: supplierNotifier.suppliers,
                  onSupplierTap: (supplier) {
                    Provider.of<SupplierChangeNotifier>(context, listen: false)
                        .selectSupplier(supplier.idProductProvider);

                    _focusOnLocation(
                      supplier.locationLatitude,
                      supplier.locationLongitude,
                    );
                    Future.delayed(const Duration(milliseconds: 400), () {
                      showSupplierDetails(context, supplier);
                    });
                  },
                );
              },
            ),

          // Sliding Panel with optimized rebuilds
          SlidingUpPanel(
            controller: _panelController,
            minHeight: 80,
            maxHeight: MediaQuery.of(context).size.height * 0.6,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            backdropEnabled: true,
            backdropOpacity: 0.2,
            backdropColor: Theme.of(context).colorScheme.onSurface,
            panelBuilder: (scrollController) {
              return Consumer<SupplierChangeNotifier>(
                builder: (context, supplierNotifier, child) {
                  return PanelContent(
                    suppliers: supplierNotifier.suppliers,
                    isLoading: supplierNotifier.isLoading,
                    scrollController: scrollController,
                    focusOnLocation: _focusOnLocation,
                    selectedLocation: _selectedLocation,
                    onDeleteLocationFilter: onDeleteLocationFilter,
                    applyLocationFilter: _applyLocationFilter,
                  );
                },
              );
            },
            color: Theme.of(context).colorScheme.surface,
            collapsed: _buildCollapsedPanel(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedPanel(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.providersText,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
