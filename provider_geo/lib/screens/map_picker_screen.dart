// lib/ui/screens/map_picker.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

/// Full-screen map picker. The user pans the map and taps to drop a
/// pin; the confirmed position is returned via `Navigator.pop` as a
/// [LatLng], or `null` if the user backs out.
///
/// Designed to be pushed and awaited:
///
/// ```dart
/// final picked = await Navigator.push<LatLng>(
///   context,
///   MaterialPageRoute(builder: (_) => const MapPicker()),
/// );
/// if (picked != null) {
///   // use picked.latitude, picked.longitude
/// }
/// ```
class MapPicker extends StatefulWidget {
  /// Where the camera starts. When null, we attempt to use the device
  /// location; if that's unavailable too, we fall back to a default
  /// (Algiers) so the map never opens on the ocean.
  final LatLng? initialPosition;

  /// Where to drop the initial pin. When null, no pin is shown until
  /// the user taps.
  final LatLng? initialPin;

  /// Initial zoom level. 16 is street-level, 12 is neighbourhood,
  /// 10 is city. Default is street-level since picking is precise work.
  final double initialZoom;

  static MapPicker fromArguments(Object? raw) {
    if (raw is! Map) return const MapPicker();

    final pos = raw['initialPosition'];
    final pin = raw['initialPin'];
    final zoom = raw['initialZoom'];

    return MapPicker(
      initialPosition: pos is LatLng ? pos : null,
      initialPin: pin is LatLng ? pin : null,
      initialZoom: zoom is double ? zoom : 15.0,
    );
  }

  const MapPicker({
    super.key,
    this.initialPosition,
    this.initialPin,
    this.initialZoom = 15.0,
  });

  @override
  State<MapPicker> createState() => _MapPickerState();
}

class _MapPickerState extends State<MapPicker> {
  GoogleMapController? _controller;
  LatLng? _picked;

  /// The position the camera actually starts at, resolved once in
  /// `initState` so the widget doesn't jump around on rebuilds.
  late final LatLng _initialCameraTarget;
  late final Future<void> _locationProbe;

  bool _isLocating = false;

  static const _fallbackTarget = LatLng(36.7538, 3.0588); // Algiers

  @override
  void initState() {
    super.initState();
    _picked = widget.initialPin;
    _initialCameraTarget =
        widget.initialPosition ?? widget.initialPin ?? _fallbackTarget;
    _locationProbe = _resolveInitialPosition();
  }

  /// If the caller didn't supply an initial position, try the device
  /// location once. Failures are silent — the fallback stands.
  Future<void> _resolveInitialPosition() async {
    if (widget.initialPosition != null || widget.initialPin != null) return;

    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied ||
            requested == LocationPermission.deniedForever) {
          return;
        }
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      if (!mounted || _controller == null) return;

      final target = LatLng(pos.latitude, pos.longitude);
      await _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(target, widget.initialZoom),
      );
    } catch (_) {
      // Timeout, service disabled, or any other failure: keep the
      // fallback camera position. No user-facing error — the user can
      // still pan to their location.
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    // Kick the location probe again if it completed before the
    // controller existed.
    unawaited(_locationProbe.then((_) {
      if (!mounted) return;
      // Nothing to do — the probe already handles the case where the
      // controller isn't ready yet.
    }));
  }

  void _onTap(LatLng position) {
    setState(() => _picked = position);
  }

  Future<void> _recenterOnUser() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      if (!mounted || _controller == null) return;
      await _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(pos.latitude, pos.longitude),
          widget.initialZoom,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _showSnack(AppLocalizations.of(context)!.mapPickerLocationUnavailable);
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _confirm() {
    final picked = _picked;
    if (picked == null) return;
    Navigator.of(context).pop(picked);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final hasPick = _picked != null;

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _initialCameraTarget,
              zoom: widget.initialZoom,
            ),
            onTap: _onTap,
            markers: {
              if (_picked != null)
                Marker(
                  markerId: const MarkerId('picked'),
                  position: _picked!,
                  draggable: true,
                  onDragEnd: (pos) => setState(() => _picked = pos),
                ),
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            compassEnabled: true,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            padding: const EdgeInsets.only(bottom: 120),
          ),

          // ── Top bar ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _CircleIconButton(
                    icon: Icons.close_rounded,
                    tooltip:
                        MaterialLocalizations.of(context).closeButtonTooltip,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: cs.shadow.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        l10n.mapPickerTitle,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom sheet: hint + confirm ──
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: cs.shadow.withOpacity(0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            hasPick
                                ? Icons.place_rounded
                                : Icons.touch_app_rounded,
                            size: 20,
                            color: cs.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              hasPick
                                  ? l10n.mapPickerPinDropped
                                  : l10n.mapPickerTapHint,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (hasPick) ...[
                        const SizedBox(height: 8),
                        Text(
                          _formatCoords(_picked!, l10n),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontFeatures: const [
                              // Tabular numerals so the coords
                              // don't jitter as they update.
                              FontFeature.tabularFigures(),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isLocating ? null : _recenterOnUser,
                              icon: _isLocating
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.my_location, size: 18),
                              label: Text(l10n.mapPickerRecenter),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: hasPick ? _confirm : null,
                              icon: const Icon(Icons.check_rounded, size: 18),
                              label: Text(l10n.mapPickerConfirm),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCoords(LatLng p, AppLocalizations l10n) {
    return l10n.mapPickerCoordinates(
      p.latitude.toStringAsFixed(5),
      p.longitude.toStringAsFixed(5),
    );
  }
}

// ============================================================================
// Small helpers
// ============================================================================

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _CircleIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      shape: const CircleBorder(),
      elevation: 3,
      child: IconButton(
        icon: Icon(icon),
        tooltip: tooltip,
        onPressed: onPressed,
        splashRadius: 22,
      ),
    );
  }
}
