import 'dart:async';
import 'dart:io';
import 'dart:developer';

import 'package:geolocator/geolocator.dart';
import 'package:verdelia_core/mediation/StorageService.dart';
import 'supplier_state.dart';

class SupplierLocation {
  final StorageService _storage;
  final SupplierState _state;
  static const _timeoutSeconds = 15;

  SupplierLocation({
    required StorageService storage,
    required SupplierState state,
  })  : _storage = storage,
        _state = state;

  Future<Position?> getCurrentLocation() async {
    if (_state.isLoading) return null;

    if (!Platform.isAndroid && !Platform.isIOS) {
      _storeFailure('UNSUPPORTED_PLATFORM', 'Location only on mobile');
      return null;
    }

    _state.isLoading = true;

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _storeFailure('SERVICES_DISABLED', 'Location services disabled');
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          _storeFailure('PERMISSION_DENIED', 'Location permissions denied');
          return null;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(Duration(seconds: _timeoutSeconds));

      _state.currentLocation = position;
      _storeSuccess('SUCCESS', position);
      return position;
    } on TimeoutException {
      _storeFailure('TIMEOUT', 'Location request timed out');
      return null;
    } catch (e) {
      _storeFailure('LOCATION_ERROR', e.toString());
      return null;
    } finally {
      _state.isLoading = false;
    }
  }

  void _storeSuccess(String code, data) {
    _storage.setSuccessResponse('location_$code', data,
        statusCode: 200, responseCode: code);
  }

  void _storeFailure(String code, String message) {
    _storage.setFailureResponse('location_$code',
        data: message, statusCode: 500, errorCode: code, message: message);
  }
}
