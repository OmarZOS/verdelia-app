import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:app_constants/app_constants.dart';
import 'package:verdelia_core/mediation/StorageService.dart';
import 'package:verdelia_core/app/VerdeliaImage.dart';
import 'package:locator/locator.dart';

class VerdeliaImageImpl extends VerdeliaImage<FormData> {
  VerdeliaImageImpl();

  @override
  Future<FormData> formData() async {
    return FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filepath,
        filename: filename,
      ),
    });
  }

  @override
  Future<String?> uploadImage() async {
    StorageService storageService = AppLocator.get<StorageService>();
    log("uploading");
    final dynamic result = await storageService.insertBinary(
        '${AppConstants.fsBaseUrl}${AppConstants.postImageEndpoint}/$entityType/$ownerId/$entityId/',
        await formData());

    if (result is! Map || result['path'] is! String) {
      throw StateError('Image upload response did not include a path.');
    }

    return (result['path'] as String).replaceFirst('files/', '');
  }
}
