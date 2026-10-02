import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:app_constants/app_response_codes.dart';
import 'package:verdelia_core/app/VerdeliaException.dart';
import 'package:verdelia_core/business/product_form_data.dart';
import 'package:event/assistant_change_notifier.dart';
import 'package:event/components/lib.dart';
import 'package:event/product_change_notifier.dart';
import 'package:ui/Services/ResponseHandler.dart';
import 'package:product_catalog/screens/components/form/form_controllers.dart';
import 'package:provider/provider.dart';

class SubmitHandler {
  static Future<void> submitForm({
    required BuildContext context,
    required GlobalKey<FormState> formKey,
    required ProductFormData formData,
    required FormControllers controllers,
    required bool isUpdate,
  }) async {
    try {
      if (formKey.currentState?.validate() != true) return;

      formKey.currentState?.save();

      final assistantNotifier = context.read<AssistantNotifier>();
      final assistantSource = assistantNotifier.source_of_data;
      final sourceIsAssistant = assistantSource == DataSource.aiGenerated ||
          assistantSource == DataSource.databaseFetched;
      final assistedFieldsWereEdited =
          assistantNotifier.fieldData.values.any((field) => field.isEdited);
      final assistantOrigin = sourceIsAssistant && !assistedFieldsWereEdited
          ? formData.assistantOrigin
          : null;

      final product = formData.toProduct(
        assistantProductOrigin: assistantOrigin,
      )..productImage = formData.image;
      final productNotifier = context.read<ProductNotifier>();

      final savedProduct = await productNotifier.addOrUpdateProduct(product);
      if (savedProduct == null) {
        throw StateError('The product could not be saved.');
      }

      if (!context.mounted) return;

      ResponseHandler.handleResponse(
        context: context,
        statusCode: 200,
        responseCode: AppResponseCodes.put_success,
        finalMessage: AppLocalizations.of(context)!.putSuccess,
      );

      // Pop just the form and hand the saved product back to the caller.
      Navigator.of(context).pop(savedProduct);
    } on VerdeliaException catch (e) {
      if (!context.mounted) return;
      ResponseHandler.handleResponse(
        context: context,
        statusCode: e.statusCode ?? 500,
        responseCode: e.message,
        finalMessage: e.error?.toString() ?? e.message,
      );
    } catch (e) {
      if (!context.mounted) return;
      ResponseHandler.handleResponse(
        context: context,
        statusCode: 500,
        responseCode: 'UNKNOWN_ERROR',
        finalMessage: 'An unexpected error occurred: $e',
      );
    }
  }
}
