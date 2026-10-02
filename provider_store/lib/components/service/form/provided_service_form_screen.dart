// service_form_screen.dart
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/app/VerdeliaException.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:verdelia_core/business/finance/ProvidedService.dart';
import 'package:event/product_change_notifier.dart';
import 'package:event/service_change_notifier.dart';
import 'package:event/user_change_notifier.dart';
import 'package:provider_store/components/service/form/ProductSelectorDialog.dart';
import 'package:provider_store/components/service/form/cost_summary_card.dart';
import 'package:provider_store/components/service/form/form_section_header.dart';
import 'package:ui/Services/ResponseHandler.dart';
import 'package:provider/provider.dart';

// Import the new components
import 'form_section_header.dart';
import 'form_input_field.dart';
import 'empty_state.dart';
import 'cost_summary_card.dart';
import 'discount_indicator.dart';
import 'progress_section.dart';
import 'resource_dialog.dart';
import 'staff_dialog.dart';
import 'form_price_field.dart';
import 'form_checkbox_option.dart';
import 'form_chip_input.dart';
import 'requirement_card.dart';
import 'category_dropdown.dart';
import 'role_dropdown.dart';
import 'duration_picker_field.dart';

class ProvidedServiceFormScreen extends StatefulWidget {
  const ProvidedServiceFormScreen({super.key});

  @override
  State<ProvidedServiceFormScreen> createState() =>
      _ProvidedServiceFormScreenState();
}

class _ProvidedServiceFormScreenState extends State<ProvidedServiceFormScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Form data
  String _serviceName = '';
  String _serviceDescription = '';
  int _categoryId = 0;
  int _providerId = 0;
  double _basePrice = 0.0;
  double _finalPrice = 0.0;
  int _actualDuration = 0;

  final List<ServiceResourceRequirement> _resourceRequirements = [];
  final List<ServiceStaffRequirement> _staffRequirements = [];

  // Pricing config
  String _recommendedAge = '';
  String _recommendedFrequency = '';
  String _ageGroup = '';
  String _sampleType = '';
  bool _specialistConsultation = false;
  bool _governmentFunded = false;
  bool _consultationIncluded = false;
  bool _digitalImaging = false;
  List<String> _materialOptions = [];
  List<String> _includes = [];

  // State
  bool _updatePage = false;
  int _id = 0;
  bool _isActive = true;
  DateTime? _createdAt;
  DateTime? _updatedAt;
  bool _initialized = false;
  List<ProvidedServiceCategory> _serviceCategories = [];
  List<StaffRole> _staffRoles = [];
  bool _isLoadingCategories = false;
  bool _isLoadingRoles = false;

  // Section states
  bool _basicInfoExpanded = true;
  bool _pricingExpanded = true;
  bool _pricingConfigExpanded = false;
  bool _resourcesExpanded = false;
  bool _staffExpanded = false;
  bool _costSummaryExpanded = false;

  // Completion states
  bool _basicInfoCompleted = false;
  bool _pricingCompleted = false;
  bool _pricingConfigCompleted = false;
  bool _resourcesCompleted = false;
  bool _staffCompleted = false;
  bool _costSummaryCompleted = false;

  // Submission state
  bool _isSubmitting = false;
  String? _currentOperationKey;

  // UI state
  bool _showDiscountWarning = false;
  bool _showProfitWarning = false;

  @override
  void initState() {
    super.initState();
    _log('Form initialized');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initializeForm();
      _initialized = true;
    }
  }

  void _initializeForm() {
    try {
      final route = ModalRoute.of(context);
      final args = route?.settings.arguments;
      ProvidedService? service;
      final routeProviderId =
          args is Map<String, dynamic> ? (args['providerId'] as int? ?? 0) : 0;
      final currentProviderId =
          Provider.of<ServiceNotifier>(context, listen: false)
                  .currentProviderId ??
              0;

      if (args is Map<String, dynamic>) {
        service = args["service"] as ProvidedService?;
      }
      if (service != null) {
        _updatePage = true;
        _id = service.id;
        _serviceName = service.name;
        _serviceDescription = service.description;
        _categoryId = service.categoryId;
        _providerId = service.productProviderId > 0
            ? service.productProviderId
            : (routeProviderId > 0 ? routeProviderId : currentProviderId);
        _basePrice = service.basePrice;
        _finalPrice = service.finalPrice;
        _actualDuration = service.actualDuration;
        _isActive = service.isActive;
        _createdAt = service.createdAt;
        _updatedAt = service.updatedAt;

        final config = service.pricingConfig;
        _recommendedAge = config.recommendedAge ?? '';
        _recommendedFrequency = config.recommendedFrequency ?? '';
        _ageGroup = config.ageGroup ?? '';
        _sampleType = config.sampleType ?? '';
        _specialistConsultation = config.specialistConsultation ?? false;
        _governmentFunded = config.governmentFunded ?? false;
        _consultationIncluded = config.consultationIncluded ?? false;
        _digitalImaging = config.digitalImaging ?? false;
        _materialOptions = config.materialOptions ?? [];
        _includes = config.includes ?? [];

        _resourceRequirements.addAll(service.resourceRequirements);
        _staffRequirements.addAll(service.staffRequirements);
      } else {
        _providerId = routeProviderId > 0 ? routeProviderId : currentProviderId;
      }

      _updateCompletionStates();
      _loadCategories();
      if (_categoryId > 0) _loadStaffRoles(_categoryId);
      _log('Form data loaded successfully');
    } catch (e, stackTrace) {
      _logError('Error loading form data', e, stackTrace);
    }
  }

  Future<void> _loadCategories() async {
    if (_isLoadingCategories) return;
    setState(() => _isLoadingCategories = true);
    final notifier = Provider.of<ServiceNotifier>(context, listen: false);
    final categories = await notifier.fetchServiceCategories();
    if (!mounted) return;
    setState(() {
      _serviceCategories = categories;
      _isLoadingCategories = false;
    });
  }

  Future<void> _loadStaffRoles(int categoryId) async {
    setState(() {
      _isLoadingRoles = true;
      _staffRoles = [];
    });
    final notifier = Provider.of<ServiceNotifier>(context, listen: false);
    final roles = await notifier.fetchStaffRolesByCategory(categoryId);
    if (!mounted || categoryId != _categoryId) return;
    setState(() {
      _staffRoles = roles;
      _isLoadingRoles = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _log(String message) {
    developer.log('ProvidedServiceForm: $message', name: 'ProvidedServiceForm');
  }

  void _logError(String message, Object error, StackTrace stackTrace) {
    developer.log('ERROR: $message - $error',
        name: 'ProvidedServiceForm', error: error, stackTrace: stackTrace);
  }

  // ===================== COMPLETION CHECKING =====================

  void _updateCompletionStates() {
    setState(() {
      _basicInfoCompleted = _serviceName.isNotEmpty &&
          _categoryId > 0 &&
          _providerId > 0 &&
          _actualDuration > 0;

      _pricingCompleted = _basePrice > 0 && _finalPrice > 0;

      _pricingConfigCompleted = _ageGroup.isNotEmpty ||
          _sampleType.isNotEmpty ||
          _specialistConsultation ||
          _governmentFunded ||
          _consultationIncluded ||
          _digitalImaging ||
          _materialOptions.isNotEmpty ||
          _includes.isNotEmpty;

      _resourcesCompleted = true;
      _staffCompleted = true;
      _costSummaryCompleted = _finalPrice > 0;

      // Update warnings
      _showDiscountWarning = _basePrice > 0 && _finalPrice > _basePrice;
      _showProfitWarning = _finalPrice > 0 && _finalPrice < _totalCost;
    });
  }

  // ===================== CALCULATIONS =====================

  double get _totalResourceCost {
    return _resourceRequirements.fold(
      0.0,
      (total, req) => total + (req.costPerUnit * req.quantity),
    );
  }

  double get _totalStaffCost {
    return _staffRequirements.fold(
      0.0,
      (total, req) =>
          total +
          (req.hourlyRate *
              req.allocatedHours *
              ((req.minCount + req.maxCount) / 2)),
    );
  }

  double get _totalCost => _totalResourceCost + _totalStaffCost;

  double get _profitMargin {
    if (_finalPrice <= 0) return 0;
    return ((_finalPrice - _totalCost) / _finalPrice * 100)
        .clamp(-100.0, 100.0);
  }

  double get _discountPercentage {
    if (_basePrice == 0) return 0;
    return ((_basePrice - _finalPrice) / _basePrice * 100);
  }

  // ===================== BUSINESS VALIDATION =====================

  String? _businessValidationError(AppLocalizations loc) {
    if (_providerId <= 0) return loc.validationProviderRequired;
    if (_categoryId <= 0) return loc.validationCategoryRequired;
    if (_actualDuration <= 0) return loc.validationDurationPositive;
    if (_basePrice <= 0) return loc.validationBasePricePositive;
    if (_finalPrice <= 0) return loc.validationFinalPricePositive;
    if (_finalPrice > _basePrice) {
      return loc.validationFinalPriceExceedsBase;
    }
    return null;
  }

  // ===================== SUBMISSION =====================

  Future<void> _submitForm() async {
    if (_isSubmitting) return;

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final loc = AppLocalizations.of(context)!;
      final validationError = _businessValidationError(loc);
      if (validationError != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(validationError)),
          );
        }
        return;
      }

      setState(() => _isSubmitting = true);

      _currentOperationKey = _updatePage
          ? 'update_service_${DateTime.now().millisecondsSinceEpoch}'
          : 'create_service_${DateTime.now().millisecondsSinceEpoch}';

      final pricingConfig = ProvidedServicePricingConfig(
        recommendedAge: _recommendedAge.isNotEmpty ? _recommendedAge : null,
        recommendedFrequency:
            _recommendedFrequency.isNotEmpty ? _recommendedFrequency : null,
        ageGroup: _ageGroup.isNotEmpty ? _ageGroup : null,
        sampleType: _sampleType.isNotEmpty ? _sampleType : null,
        specialistConsultation: _specialistConsultation,
        governmentFunded: _governmentFunded,
        consultationIncluded: _consultationIncluded,
        digitalImaging: _digitalImaging,
        materialOptions: _materialOptions.isNotEmpty ? _materialOptions : null,
        includes: _includes.isNotEmpty ? _includes : null,
      );

      final service = ProvidedService(
        id: _id,
        name: _serviceName,
        description: _serviceDescription,
        categoryId: _categoryId,
        productProviderId: _providerId,
        basePrice: _basePrice,
        finalPrice: _finalPrice,
        actualDuration: _actualDuration,
        pricingConfig: pricingConfig,
        isActive: _isActive,
        createdAt: _createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        deletedAt: null,
        resourceRequirements: List.from(_resourceRequirements),
        staffRequirements: List.from(_staffRequirements),
      );

      try {
        final serviceNotifier =
            Provider.of<ServiceNotifier>(context, listen: false);
        final authToken =
            Provider.of<AppUserNotifier>(context, listen: false).token;

        bool success = false;

        if (_updatePage) {
          final updated = await serviceNotifier.updateService(
            service,
            callerKey: _currentOperationKey,
            token: authToken,
          );
          success = updated != null;
        } else {
          final created = await serviceNotifier.addService(
            service,
            callerKey: _currentOperationKey,
            token: authToken,
          );
          success = created != null;
        }

        if (!mounted) return;

        if (success) {
          final response = serviceNotifier.getResponse(_currentOperationKey!);

          ResponseHandler.handleResponse(
            context: context,
            statusCode: response?.statusCode ?? 200,
            responseCode: response?.responseCode ?? 'SUCCESS',
            finalMessage: _updatePage
                ? AppLocalizations.of(context)!.updateSuccess
                : AppLocalizations.of(context)!.putSuccess,
          );

          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.pop(context, true);
            }
          });
        } else {
          final response = serviceNotifier.getResponse(_currentOperationKey!);

          ResponseHandler.handleResponse(
            context: context,
            statusCode: response?.statusCode ?? 500,
            responseCode: response?.responseCode ?? 'FAILED',
            finalMessage:
                response?.message ?? AppLocalizations.of(context)!.putFailure,
          );
        }
      } on VerdeliaException catch (e) {
        if (mounted) {
          ResponseHandler.handleResponse(
            context: context,
            statusCode: e.statusCode ?? 300,
            responseCode: e.message,
            finalMessage: e.message,
          );
        }
      } catch (e) {
        if (mounted) {
          ResponseHandler.handleResponse(
            context: context,
            statusCode: 500,
            responseCode: 'ERROR',
            finalMessage:
                AppLocalizations.of(context)!.unexpectedErrorWithDetail('$e'),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    }
  }

  // ===================== UI HELPERS =====================

  String _roleName(int roleId, AppLocalizations loc) {
    final matches = _staffRoles.where((role) => role.id == roleId);
    return matches.isEmpty ? loc.roleFallback(roleId) : matches.first.name;
  }

  // ===================== BUILD =====================

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _updatePage ? loc.editServiceTitle : loc.createServiceTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
      ),
      body: Column(
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // ==================== BASIC INFO ====================
                    FormSectionHeader(
                      title: loc.basicInformationSection,
                      icon: Icons.info_outline,
                      isExpanded: _basicInfoExpanded,
                      isCompleted: _basicInfoCompleted,
                      isOptional: false,
                      onTap: () => setState(
                        () => _basicInfoExpanded = !_basicInfoExpanded,
                      ),
                    ),
                    if (_basicInfoExpanded) ...[
                      const SizedBox(height: 12),
                      FormInputField(
                        label: loc.serviceNameLabel,
                        initialValue: _serviceName,
                        hintText: loc.serviceNameHint,
                        isRequired: true,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return loc.serviceNameRequired;
                          }
                          return null;
                        },
                        onSaved: (val) {
                          _serviceName = val ?? '';
                          _updateCompletionStates();
                        },
                        onChanged: (_) => _updateCompletionStates(),
                      ),
                      const SizedBox(height: 12),
                      FormInputField(
                        label: loc.descriptionLabel,
                        initialValue: _serviceDescription,
                        hintText: loc.descriptionHint,
                        maxLines: 3,
                        onSaved: (val) {
                          _serviceDescription = val ?? '';
                          _updateCompletionStates();
                        },
                      ),
                      const SizedBox(height: 12),
                      CategoryDropdown(
                        categories: _serviceCategories,
                        selectedCategoryId: _categoryId,
                        isLoading: _isLoadingCategories,
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _categoryId = value;
                            _staffRequirements.clear();
                          });
                          _loadStaffRoles(value);
                          _updateCompletionStates();
                        },
                      ),
                      const SizedBox(height: 16),

                      // -------- Duration picker --------
                      _buildDurationField(loc),

                      const SizedBox(height: 24),
                    ],

                    // ==================== PRICING ====================
                    FormSectionHeader(
                      title: loc.pricingSection,
                      icon: Icons.attach_money,
                      isExpanded: _pricingExpanded,
                      isCompleted: _pricingCompleted,
                      isOptional: false,
                      onTap: () => setState(
                        () => _pricingExpanded = !_pricingExpanded,
                      ),
                    ),
                    if (_pricingExpanded) ...[
                      const SizedBox(height: 12),
                      FormPriceField(
                        label: loc.basePriceLabel,
                        value: _basePrice,
                        isRequired: true,
                        onSaved: (val) {
                          _basePrice = val;
                          _updateCompletionStates();
                        },
                        onChanged: (_) => _updateCompletionStates(),
                      ),
                      const SizedBox(height: 12),
                      FormPriceField(
                        label: loc.finalPriceLabel,
                        value: _finalPrice,
                        isRequired: true,
                        onSaved: (val) {
                          _finalPrice = val;
                          _updateCompletionStates();
                        },
                        onChanged: (_) => _updateCompletionStates(),
                      ),
                      if (_basePrice > 0 || _finalPrice > 0) ...[
                        const SizedBox(height: 12),
                        DiscountIndicator(
                          basePrice: _basePrice,
                          finalPrice: _finalPrice,
                          discountPercentage: _discountPercentage,
                          showWarning: _showDiscountWarning,
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],

                    // ==================== PRICING CONFIG ====================
                    FormSectionHeader(
                      title: loc.pricingConfigurationSection,
                      icon: Icons.settings,
                      isExpanded: _pricingConfigExpanded,
                      isCompleted: _pricingConfigCompleted,
                      isOptional: true,
                      onTap: () => setState(
                        () => _pricingConfigExpanded = !_pricingConfigExpanded,
                      ),
                    ),
                    if (_pricingConfigExpanded) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FormInputField(
                              label: loc.ageGroupLabel,
                              initialValue: _ageGroup,
                              hintText: loc.ageGroupHint,
                              onSaved: (val) {
                                _ageGroup = val ?? '';
                                _updateCompletionStates();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FormInputField(
                              label: loc.sampleTypeLabel,
                              initialValue: _sampleType,
                              hintText: loc.sampleTypeHint,
                              onSaved: (val) {
                                _sampleType = val ?? '';
                                _updateCompletionStates();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: [
                          FormCheckboxOption(
                            label: loc.specialistConsultationLabel,
                            value: _specialistConsultation,
                            onChanged: (val) {
                              setState(
                                  () => _specialistConsultation = val ?? false);
                              _updateCompletionStates();
                            },
                          ),
                          const SizedBox(height: 8),
                          FormCheckboxOption(
                            label: loc.governmentFundedLabel,
                            value: _governmentFunded,
                            onChanged: (val) {
                              setState(() => _governmentFunded = val ?? false);
                              _updateCompletionStates();
                            },
                          ),
                          const SizedBox(height: 8),
                          FormCheckboxOption(
                            label: loc.consultationIncludedLabel,
                            value: _consultationIncluded,
                            onChanged: (val) {
                              setState(
                                  () => _consultationIncluded = val ?? false);
                              _updateCompletionStates();
                            },
                          ),
                          const SizedBox(height: 8),
                          FormCheckboxOption(
                            label: loc.digitalImagingLabel,
                            value: _digitalImaging,
                            onChanged: (val) {
                              setState(() => _digitalImaging = val ?? false);
                              _updateCompletionStates();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FormChipInput(
                        label: loc.materialOptionsLabel,
                        items: _materialOptions,
                        onAdd: (material) {
                          if (!_materialOptions.contains(material)) {
                            setState(() => _materialOptions.add(material));
                            _updateCompletionStates();
                          }
                        },
                        onRemove: (index) {
                          setState(() => _materialOptions.removeAt(index));
                          _updateCompletionStates();
                        },
                      ),
                      const SizedBox(height: 12),
                      FormChipInput(
                        label: loc.includesLabel,
                        items: _includes,
                        onAdd: (include) {
                          if (!_includes.contains(include)) {
                            setState(() => _includes.add(include));
                            _updateCompletionStates();
                          }
                        },
                        onRemove: (index) {
                          setState(() => _includes.removeAt(index));
                          _updateCompletionStates();
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ==================== RESOURCES ====================
                    FormSectionHeader(
                      title: loc.resourceRequirementsSection,
                      icon: Icons.inventory,
                      isExpanded: _resourcesExpanded,
                      isCompleted: _resourcesCompleted,
                      isOptional: false,
                      onTap: () => setState(
                        () => _resourcesExpanded = !_resourcesExpanded,
                      ),
                    ),
                    if (_resourcesExpanded) ...[
                      const SizedBox(height: 12),
                      if (_resourceRequirements.isEmpty)
                        EmptyState(
                          message: loc.noResourcesAdded,
                          icon: Icons.inventory_2_outlined,
                        )
                      else
                        ..._resourceRequirements.asMap().entries.map((entry) {
                          final index = entry.key;
                          final req = entry.value;
                          return RequirementCard(
                            title: req.name,
                            subtitle:
                                '${req.quantity} × DZD ${req.costPerUnit.toStringAsFixed(2)} = DZD ${(req.costPerUnit * req.quantity).toStringAsFixed(2)}',
                            onEdit: () => _showResourceDialog(
                              existing: req,
                              index: index,
                            ),
                            onDelete: () => setState(() {
                              _resourceRequirements.removeAt(index);
                              _updateCompletionStates();
                            }),
                          );
                        }).toList(),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FloatingActionButton.small(
                          onPressed: () => _showResourceDialog(),
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add, size: 20),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ==================== STAFF ====================
                    FormSectionHeader(
                      title: loc.staffRequirementsSection,
                      icon: Icons.people,
                      isExpanded: _staffExpanded,
                      isCompleted: _staffCompleted,
                      isOptional: false,
                      onTap: () => setState(
                        () => _staffExpanded = !_staffExpanded,
                      ),
                    ),
                    if (_staffExpanded) ...[
                      const SizedBox(height: 12),
                      if (_staffRequirements.isEmpty)
                        EmptyState(
                          message: loc.noStaffAdded,
                          icon: Icons.people_outline,
                        )
                      else
                        ..._staffRequirements.asMap().entries.map((entry) {
                          final index = entry.key;
                          final req = entry.value;
                          return RequirementCard(
                            title:
                                '${_roleName(req.role, loc)} (${req.minCount}-${req.maxCount})',
                            subtitle:
                                '${req.allocatedHours}h × DZD ${req.hourlyRate.toStringAsFixed(2)}/h ≈ DZD ${(req.hourlyRate * req.allocatedHours * ((req.minCount + req.maxCount) / 2)).toStringAsFixed(2)}',
                            onEdit: () => _showStaffDialog(
                              existing: req,
                              index: index,
                            ),
                            onDelete: () => setState(() {
                              _staffRequirements.removeAt(index);
                              _updateCompletionStates();
                            }),
                          );
                        }).toList(),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FloatingActionButton.small(
                          onPressed: () => _showStaffDialog(),
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add, size: 20),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ==================== COST SUMMARY ====================
                    FormSectionHeader(
                      title: loc.costSummarySection,
                      icon: Icons.calculate,
                      isExpanded: _costSummaryExpanded,
                      isCompleted: _costSummaryCompleted,
                      isOptional: false,
                      onTap: () => setState(
                        () => _costSummaryExpanded = !_costSummaryExpanded,
                      ),
                    ),
                    if (_costSummaryExpanded) ...[
                      const SizedBox(height: 12),
                      CostSummaryCard(
                        resourceCost: _totalResourceCost,
                        staffCost: _totalStaffCost,
                        totalCost: _totalCost,
                        finalPrice: _finalPrice,
                        profitMargin: _profitMargin,
                        showWarning: _showProfitWarning,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Progress Bar and Submit Button
          ProgressSection(
            completedSections: [
              _basicInfoCompleted,
              _pricingCompleted,
              _pricingConfigCompleted,
              _resourcesCompleted,
              _staffCompleted,
              _costSummaryCompleted,
            ],
            isSubmitting: _isSubmitting,
            isUpdate: _updatePage,
            totalSections: 6,
            onSubmit: _submitForm,
          ),
        ],
      ),
    );
  }

  // ===================== DURATION FIELD =====================

  /// Duration input backed by a [CupertinoTimerPicker].
  ///
  /// The picker is always a valid Duration, so the old "must be > 0"
  /// validator is unreachable at the widget level. The submit-time
  /// business validation (`validationDurationPositive`) still catches
  /// a zero value.
  Widget _buildDurationField(AppLocalizations loc) {
    return DurationPickerField(
      label: loc.durationLabel,
      isRequired: true,
      value: Duration(minutes: _actualDuration),
      initiallyExpanded: _actualDuration == 0,
      onChanged: (d) {
        final minutes = d.inMinutes;
        if (minutes == _actualDuration) return;
        setState(() => _actualDuration = minutes);
        _updateCompletionStates();
      },
    );
  }

  // ===================== DIALOG METHODS =====================

  void _showResourceDialog({ServiceResourceRequirement? existing, int? index}) {
    showDialog(
      context: context,
      builder: (context) => ResourceRequirementDialog(
        existing: existing,
        index: index,
        providerId: _providerId,
        serviceId: _id,
        onSave: (requirement, isEdit, editIndex) {
          setState(() {
            if (isEdit && editIndex != null) {
              _resourceRequirements[editIndex] = requirement;
            } else {
              _resourceRequirements.add(requirement);
            }
            _updateCompletionStates();
          });
        },
      ),
    );
  }

  void _showStaffDialog({ServiceStaffRequirement? existing, int? index}) {
    showDialog(
      context: context,
      builder: (context) => StaffRequirementDialog(
        existing: existing,
        index: index,
        serviceId: _id,
        staffRoles: _staffRoles,
        isLoadingRoles: _isLoadingRoles,
        onSave: (requirement, isEdit, editIndex) {
          setState(() {
            if (isEdit && editIndex != null) {
              _staffRequirements[editIndex] = requirement;
            } else {
              _staffRequirements.add(requirement);
            }
            _updateCompletionStates();
          });
        },
      ),
    );
  }
}
