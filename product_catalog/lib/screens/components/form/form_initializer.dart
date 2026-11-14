// lib/screens/components/form/form_state_manager.dart

import 'package:verdelia_core/business/Product.dart';
import 'package:verdelia_core/business/product_form_data.dart';
import 'package:product_catalog/screens/components/form/form_controllers.dart';

/// Owns the create-vs-update decision and the initial hydration of the
/// form state.
///
/// It is deliberately dumb: it does not read `BuildContext`, it does not
/// look up notifiers, and it does not do any I/O. The screen calls
/// [initializeForCreate] or [initializeForUpdate] once, after it has
/// collected the route arguments and the current user.
class FormStateManager {
  final ProductFormData formData;
  final FormControllers controllers;

  bool initialized = false;
  bool isUpdate = false;

  FormStateManager({
    required this.formData,
    required this.controllers,
  });

  /// Configure the form for creating a new product.
  ///
  /// - Resets [formData] to its defaults.
  /// - Clears controllers.
  /// - Records the current user as the owner.
  /// - Locks the provider when a provider hint is supplied by the caller.
  void initializeForCreate({
    required int ownerId,
    int providerId = 0,
    bool lockProvider = false,
  }) {
    if (initialized) return;

    // Defaults for a new product.
    formData.quantifier = 'pc';
    formData.categoryId = 1;
    formData.typeId = 1;
    formData.ownerId = ownerId;

    // VAT is not seeded here. `PricingState` owns its own default
    // (19% on its side), and `ProductFormFields` is what reconciles
    // the two representations. Leaving `productVatValue` null on
    // create means the write path omits the field and the server
    // applies whatever default the jurisdiction and category imply.

    // Optional provider hint from the caller.
    if (providerId > 0) {
      formData.selectedProviderId = providerId;
      formData.providerId = providerId;
      formData.lockProvider = lockProvider;
    }

    controllers.syncWithFormData(formData);

    isUpdate = false;
    initialized = true;
  }

  /// Configure the form for editing an existing product.
  ///
  /// - Hydrates [formData] from the product.
  /// - Syncs controllers to the hydrated values.
  /// - Preserves the provider from the product unless the caller
  ///   explicitly supplies a different one.
  ///
  /// `populateFromProduct` already carries `productVatValue` across
  /// from the Product, so an edit session starts with the product's
  /// own VAT rate. The pricing section reads it from `formData` when
  /// it seeds `PricingState`.
  void initializeForUpdate({
    required Product product,
    required int ownerId,
    int providerId = 0,
    bool lockProvider = false,
  }) {
    if (initialized) return;

    formData.populateFromProduct(product);
    formData.ownerId = ownerId;

    // Caller-supplied provider hint wins over the product's own.
    if (providerId > 0) {
      formData.selectedProviderId = providerId;
      formData.providerId = providerId;
      formData.lockProvider = lockProvider;
    } else {
      // populateFromProduct already set selectedProviderId and locked it.
      // Keep that.
    }

    controllers.syncWithFormData(formData);

    isUpdate = true;
    initialized = true;
  }
}
