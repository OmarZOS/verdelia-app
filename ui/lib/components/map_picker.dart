import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:app_constants/app_constants.dart';

Future<LatLng?> showLocationInputDialog(BuildContext context) async {
  TextEditingController latController = TextEditingController();
  TextEditingController lngController = TextEditingController();
  return showDialog<LatLng>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(AppLocalizations.of(context)!.insertCoordinatesMsg),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.latitudeMsg),
            ),
            TextField(
              controller: lngController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.longitudeMsg),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: Text(AppLocalizations.of(context)!.cancelTxt),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            child: Text(AppLocalizations.of(context)!.setLocationMsg),
            onPressed: () {
              double? latitude = double.tryParse(latController.text);
              double? longitude = double.tryParse(lngController.text);
              if (latitude != null && longitude != null) {
                Navigator.of(context).pop(LatLng(latitude, longitude));
              } else {
                // Show an error or handle invalid input
              }
            },
          ),
        ],
      );
    },
  );
}
