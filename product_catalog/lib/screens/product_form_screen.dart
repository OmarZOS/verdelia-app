// lib/screens/product_form_screen.dart

import 'package:event/user_change_notifier.dart';
import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:verdelia_core/business/product_form_data.dart';
import 'package:event/assistant_change_notifier.dart';
import 'package:ui/components/ImagePickerSection.dart';
import 'package:product_catalog/screens/components/form/ai_assistance_section.dart';
import 'package:product_catalog/screens/components/form/ai_assistant.dart';
import 'package:product_catalog/screens/components/form/form_controllers.dart';
import 'package:product_catalog/screens/components/form/form_initializer.dart';
import 'package:product_catalog/screens/components/form/loading_overlay.dart';
import 'package:product_catalog/screens/components/form/product_form_fields.dart';
import 'package:product_catalog/screens/components/form/submit_handler.dart';
import 'package:product_catalog/screens/components/form/submit_section.dart';
import 'package:provider/provider.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({Key? key}) : super(key: key);

  @override
  State<ProductFormScreen> createState() => ProductFormScreenState();
}

class ProductFormScreenState extends State<ProductFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ProductFormData _formData = ProductFormData();
  final FormControllers _controllers = FormControllers();
  late final FormStateManager _stateManager;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _stateManager = FormStateManager(
      formData: _formData,
      controllers: _controllers,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final productArg = args?['product'];
    final existingProduct = productArg is Product ? productArg : null;

    final ownerId = context.read<AppUserNotifier>().appUser?.idAppUser ?? 0;

    final rawProviderId = args?['providerId'];
    final providerId = rawProviderId is int
        ? rawProviderId
        : int.tryParse('${rawProviderId ?? ''}') ?? 0;
    final lockProvider = args?['lockProvider'] == true;

    if (existingProduct != null) {
      _stateManager.initializeForUpdate(
        product: existingProduct,
        ownerId: ownerId,
        providerId: providerId,
        lockProvider: lockProvider,
      );
    } else {
      _stateManager.initializeForCreate(
        ownerId: ownerId,
        providerId: providerId,
        lockProvider: lockProvider,
      );
    }

    _initialized = true;
  }

  @override
  void dispose() {
    _controllers.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    await SubmitHandler.submitForm(
      context: context,
      formKey: _formKey,
      formData: _formData,
      controllers: _controllers,
      isUpdate: _stateManager.isUpdate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<AssistantNotifier>(
      builder: (context, assistantNotifier, child) {
        return Scaffold(
          appBar: _buildAppBar(localizations, colorScheme),
          floatingActionButton: assistantNotifier.isLoading
              ? null
              : FloatingActionButton(
                  onPressed: () =>
                      AiAssistant.showOptions(context, _formData, _controllers),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  child: const Icon(Icons.auto_awesome),
                ),
          body: Stack(
            children: [
              // Background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorScheme.surface,
                      colorScheme.surfaceVariant.withOpacity(0.3),
                    ],
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      // AI assistance only on create.
                      if (!_stateManager.isUpdate)
                        AiAssistanceSection(
                          formData: _formData,
                          controllers: _controllers,
                        ),

                      // Image picker: always visible, in both modes.
                      _buildImagePickerSection(),

                      const SizedBox(height: 24),

                      ProductFormFields(
                        formData: _formData,
                        controllers: _controllers,
                        formKey: _formKey,
                        isUpdate: _stateManager.isUpdate,
                      ),

                      const SizedBox(height: 32),

                      SubmitSection(
                        onSubmit: _submitForm,
                        isUpdate: _stateManager.isUpdate,
                        hasAiData: false,
                      ),
                    ],
                  ),
                ),
              ),

              if (assistantNotifier.isLoading) const LoadingOverlay(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImagePickerSection() {
    return ImagePickerSection(
      initialImageUrl: _formData.imageUrl ?? "",
      entityType: 'product',
      ownerId: '${_formData.ownerId}',
      entityId: '${_formData.productId}',
      onImageUploaded: (newImage) {
        setState(() {
          _formData.image = newImage;
          _formData.imageId = 0;
        });
      },
      capturedImageFile: _formData.imageFile,
    );
  }

  AppBar _buildAppBar(AppLocalizations localizations, ColorScheme colorScheme) {
    return AppBar(
      title: Text(_stateManager.isUpdate
          ? localizations.updateProductText
          : localizations.addProductTxt),
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      centerTitle: false,
    );
  }
}
