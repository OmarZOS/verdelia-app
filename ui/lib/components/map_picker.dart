import 'package:app_constants/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

Future<LatLng?> showLocationInputDialog(BuildContext context) async {
  return showDialog<LatLng>(
    context: context,
    builder: (_) => const _LocationInputDialog(),
  );
}

class _LocationInputDialog extends StatefulWidget {
  const _LocationInputDialog();

  @override
  State<_LocationInputDialog> createState() => _LocationInputDialogState();
}

class _LocationInputDialogState extends State<_LocationInputDialog> {
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  String? _error;

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _openMapPicker() async {
    // Seed the picker from whatever the user has typed, when valid.
    final seedLat = double.tryParse(_latController.text.trim());
    final seedLng = double.tryParse(_lngController.text.trim());
    final seed =
        (seedLat != null && seedLng != null) ? LatLng(seedLat, seedLng) : null;

    final picked = await Navigator.pushNamed(
      context,
      AppRoutes.mapPicker,
      arguments: <String, dynamic>{
        if (seed != null) 'initialPosition': seed,
        if (seed != null) 'initialPin': seed,
      },
    ) as LatLng?;

    if (!mounted || picked == null) return;

    setState(() {
      _latController.text = picked.latitude.toStringAsFixed(6);
      _lngController.text = picked.longitude.toStringAsFixed(6);
      _error = null;
    });
  }

  void _confirm() {
    final l10n = AppLocalizations.of(context)!;
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());

    if (lat == null || lng == null) {
      setState(() => _error = l10n.invalidCoordinatesMsg);
      return;
    }
    if (lat < -90 || lat > 90) {
      setState(() => _error = l10n.invalidLatitudeMsg);
      return;
    }
    if (lng < -180 || lng > 180) {
      setState(() => _error = l10n.invalidLongitudeMsg);
      return;
    }

    Navigator.of(context).pop(LatLng(lat, lng));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.insertCoordinatesMsg),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _latController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
              ],
              decoration: InputDecoration(
                labelText: l10n.latitudeMsg,
                hintText: '36.753800',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lngController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
              ],
              decoration: InputDecoration(
                labelText: l10n.longitudeMsg,
                hintText: '3.058800',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _openMapPicker,
              icon: const Icon(Icons.map_outlined, size: 18),
              label: Text(l10n.pickOnMapMsg),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelTxt),
        ),
        ElevatedButton(
          onPressed: _confirm,
          child: Text(l10n.setLocationMsg),
        ),
      ],
    );
  }
}
