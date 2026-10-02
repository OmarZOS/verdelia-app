import 'package:flutter/material.dart';
import 'package:verdelia_core/business/Supplier.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

class MapScreen extends StatefulWidget {
  final Function(GoogleMapController) onMapCreated;
  final Position? userLocation;
  final List<Supplier> suppliers;
  final Function(Supplier)? onSupplierTap;

  const MapScreen({
    Key? key,
    required this.onMapCreated,
    required this.userLocation,
    required this.suppliers,
    this.onSupplierTap,
  }) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  bool _isMapReady = false;
  bool _isUpdatingMarkers = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateMarkers());
  }

  @override
  void didUpdateWidget(MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.suppliers != oldWidget.suppliers ||
        widget.userLocation != oldWidget.userLocation) {
      _updateMarkers();
    }
  }

  Future<void> _updateMarkers() async {
    if (_isUpdatingMarkers) return;
    _isUpdatingMarkers = true;

    try {
      final markers = await _createMarkers();
      if (!mounted) return;

      setState(() {
        _markers
          ..clear()
          ..addAll(markers);
      });

      if (_isMapReady && markers.isNotEmpty) {
        await _adjustCameraToMarkers(markers);
      }
    } catch (e) {
      debugPrint('Error updating markers: $e');
    } finally {
      _isUpdatingMarkers = false;
    }
  }

  Future<Set<Marker>> _createMarkers() async {
    final markers = <Marker>{};
    final loc = AppLocalizations.of(context);

    // Add user location marker
    if (widget.userLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId("user_location"),
        position: LatLng(
          widget.userLocation!.latitude,
          widget.userLocation!.longitude,
        ),
        infoWindow: InfoWindow(title: loc?.myLocationText ?? "Your Location"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        zIndex: 2,
      ));
    }

    // Add supplier markers
    for (final supplier in widget.suppliers) {
      if (supplier.locationLatitude == null ||
          supplier.locationLongitude == null) {
        continue;
      }

      markers.add(Marker(
        markerId: MarkerId('supplier_${supplier.idProductProvider}'),
        position: LatLng(
          supplier.locationLatitude!,
          supplier.locationLongitude!,
        ),
        infoWindow: InfoWindow(
          title: supplier.providerName,
          snippet: loc?.tapForDetailsText ?? "Tap for details",
        ),
        onTap: () => widget.onSupplierTap?.call(supplier),
        zIndex: 1,
      ));
    }

    return markers;
  }

  Future<void> _adjustCameraToMarkers(Set<Marker> markers) async {
    try {
      final bounds = _calculateBounds(markers);
      await _mapController.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100),
      );
    } catch (e) {
      // Fallback to first marker if bounds calculation fails
      if (markers.isNotEmpty) {
        await _mapController.animateCamera(
          CameraUpdate.newLatLngZoom(markers.first.position, 12),
        );
      }
    }
  }

  LatLngBounds _calculateBounds(Set<Marker> markers) {
    if (markers.isEmpty || !mounted) {
      return LatLngBounds(
        southwest: const LatLng(0, 0),
        northeast: const LatLng(0, 0),
      );
    }

    double? minLat, maxLat, minLng, maxLng;

    for (final marker in markers) {
      final lat = marker.position.latitude;
      final lng = marker.position.longitude;

      minLat = minLat == null ? lat : (lat < minLat ? lat : minLat);
      maxLat = maxLat == null ? lat : (lat > maxLat ? lat : maxLat);
      minLng = minLng == null ? lng : (lng < minLng ? lng : minLng);
      maxLng = maxLng == null ? lng : (lng > maxLng ? lng : maxLng);
    }

    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialPosition = widget.userLocation != null
        ? LatLng(widget.userLocation!.latitude, widget.userLocation!.longitude)
        : const LatLng(36.6563, 3.0); // Default to Algeria coordinates

    return Stack(
      children: [
        GoogleMap(
          onMapCreated: (controller) {
            _mapController = controller;
            widget.onMapCreated(controller);
            setState(() => _isMapReady = true);
            _updateMarkers();
          },
          initialCameraPosition: CameraPosition(
            target: initialPosition,
            zoom: 10.0,
          ),
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          compassEnabled: true,
          mapToolbarEnabled: false,
          zoomControlsEnabled: false,
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            heroTag: 'map_location_button',
            mini: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: Icon(
              Icons.my_location,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              if (widget.userLocation != null && _isMapReady) {
                _mapController.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(
                      widget.userLocation!.latitude,
                      widget.userLocation!.longitude,
                    ),
                    15,
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
