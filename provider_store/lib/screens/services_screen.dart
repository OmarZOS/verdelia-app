import 'package:app_constants/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:verdelia_core/business/Supplier.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/app/ManagementRule.dart';
import 'package:verdelia_core/business/finance/ProvidedService.dart';
import 'package:verdelia_core/business/privileges/Privileges.dart';
import 'package:event/personnel_notifier.dart';
import 'package:event/service_change_notifier.dart';
import 'package:provider_store/components/selling_point/selling_point_supplier.dart';
import 'package:provider_store/components/service/service_card.dart';
import 'package:provider_store/components/service/service_search_bar.dart';
import 'package:provider_store/components/service/services_empty_state.dart';
import 'package:provider_store/components/service/services_loading_state.dart';
import 'package:provider_store/screens/service_details_screen.dart';
import 'package:ui/components/store/StoreDashboardHeader.dart';
import 'package:provider/provider.dart';

class ServicesScreen extends StatefulWidget {
  final PrivilegeLevel privilegeLevel;
  final int userId;
  final List<int> accessibleSuppliers;
  final List<ManagementRule> userRules;
  final PersonnelNotifier personnelNotifier;
  final ServiceNotifier serviceNotifier;
  final int selectedSupplierId;

  const ServicesScreen({
    super.key,
    required this.privilegeLevel,
    required this.userId,
    required this.accessibleSuppliers,
    required this.userRules,
    required this.personnelNotifier,
    required this.serviceNotifier,
    required this.selectedSupplierId,
  });

  bool get canManage => privilegeLevel == PrivilegeLevel.manage;
  bool get hasMultipleSuppliers => accessibleSuppliers.length > 1;

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _ServicesContent(
      privilegeLevel: widget.privilegeLevel,
      userId: widget.userId,
      accessibleSuppliers: widget.accessibleSuppliers,
      userRules: widget.userRules,
      personnelNotifier: widget.personnelNotifier,
      serviceNotifier: widget.serviceNotifier,
      selectedSupplierId: widget.selectedSupplierId,
    );
  }
}

class _ServicesContent extends StatelessWidget {
  final PrivilegeLevel privilegeLevel;
  final int userId;
  final List<int> accessibleSuppliers;
  final List<ManagementRule> userRules;
  final PersonnelNotifier personnelNotifier;
  final ServiceNotifier serviceNotifier;
  final int selectedSupplierId;

  const _ServicesContent({
    required this.privilegeLevel,
    required this.userId,
    required this.accessibleSuppliers,
    required this.userRules,
    required this.personnelNotifier,
    required this.serviceNotifier,
    required this.selectedSupplierId,
  });

  bool get canManage => privilegeLevel == PrivilegeLevel.manage;
  bool get hasMultipleSuppliers => accessibleSuppliers.length > 1;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      floatingActionButton:
          canManage ? _buildFloatingActionButton(context, localizations) : null,
      body: SafeArea(
        child: Column(
          children: [
            // ── Shared header ──
            DashboardHeader(
              leadingIcon: Icons.handyman_rounded,
              title: localizations?.services ?? 'Services',
              subtitle:
                  '${serviceNotifier.services.length} ${localizations?.servicesAvailable ?? 'available'}',
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () => serviceNotifier.refresh(),
                  tooltip: localizations?.refresh ?? 'Refresh',
                ),
              ],
              searchBar: ServiceSearchBar(
                onSearchChanged: serviceNotifier.searchServices,
              ),
            ),

            // ── Optional supplier selector ──
            if (hasMultipleSuppliers)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SupplierSelector(
                  accessibleSuppliers: _getAccessibleSuppliers(),
                  selectedSupplierId: serviceNotifier.currentProviderId,
                  onSupplierChanged: (id) {
                    serviceNotifier.fetchServices(
                        providerId: id ?? 0, reset: true);
                  },
                ),
              ),

            // ── Service list ──
            Expanded(child: _buildContent(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(
      BuildContext context, AppLocalizations? localizations) {
    final colorScheme = Theme.of(context).colorScheme;

    return FloatingActionButton.extended(
      onPressed: () => _handleAddService(context),
      icon: const Icon(Icons.add),
      label: Text(localizations?.addService ?? 'Add Service'),
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
    );
  }

  void _handleAddService(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppRoutes.serviceForm,
      arguments: {
        'providerId': accessibleSuppliers.length == 1
            ? accessibleSuppliers.first
            : (serviceNotifier.currentProviderId ?? 0),
      },
    );
  }

  List<Supplier> _getAccessibleSuppliers() {
    final suppliers = <Supplier>[];
    final supplierIds = <int>{};

    for (final rule in userRules) {
      if (!rule.isActive) continue;

      final supplier = rule.productProvider;
      if (supplier != null &&
          !supplierIds.contains(supplier.idProductProvider)) {
        supplierIds.add(supplier.idProductProvider);
        suppliers.add(supplier);
      }
    }

    return suppliers;
  }

  Widget _buildContent(BuildContext context) {
    if (serviceNotifier.isLoading) {
      return const ServicesLoadingState();
    }

    if (serviceNotifier.services.isEmpty) {
      return const ServicesEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async => serviceNotifier.refresh(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: serviceNotifier.services.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final service = serviceNotifier.services[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ServiceCard(
              service: service,
              canManage: canManage,
              onTap: () => _handleServiceTap(context, service),
              onEdit:
                  canManage ? () => _handleEditService(context, service) : null,
              onDelete: canManage
                  ? () => _handleDeleteService(context, service)
                  : null,
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleEditService(
      BuildContext context, ProvidedService service) async {
    final resolvedProviderId = service.productProviderId > 0
        ? service.productProviderId
        : (selectedSupplierId > 0
            ? selectedSupplierId
            : (serviceNotifier.currentProviderId ?? 0));

    await Navigator.pushNamed(
      context,
      AppRoutes.serviceForm,
      arguments: {
        'providerId': resolvedProviderId,
        'service': service,
      },
    );
  }

  Future<void> _handleDeleteService(
      BuildContext context, ProvidedService service) async {
    final localizations = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(localizations?.delete ?? 'Delete service?'),
        content: Text(
          '${localizations?.deleteDocumentConfirmation ?? 'This action cannot be undone.'}\n\n${service.name}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(localizations?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(localizations?.delete ?? 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    final statusCode = await serviceNotifier.deleteService(service.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          statusCode == 200 || statusCode == 204
              ? (localizations?.deleteSuccess ?? 'Service deleted')
              : (localizations?.deleteFailure ?? 'Failed to delete service'),
        ),
        backgroundColor: statusCode == 200 || statusCode == 204
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _handleServiceTap(BuildContext context, ProvidedService service) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceDetailsScreenLoader(
          serviceId: service.id,
          listService: service,
          canManage: canManage,
          selectedSupplierId: selectedSupplierId,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Service details loader — unchanged
// ─────────────────────────────────────────────────────────────

class ServiceDetailsScreenLoader extends StatefulWidget {
  final int serviceId;
  final ProvidedService listService;
  final bool canManage;
  final int selectedSupplierId;

  const ServiceDetailsScreenLoader({
    super.key,
    required this.serviceId,
    required this.listService,
    required this.canManage,
    required this.selectedSupplierId,
  });

  @override
  State<ServiceDetailsScreenLoader> createState() =>
      _ServiceDetailsScreenLoaderState();
}

class _ServiceDetailsScreenLoaderState
    extends State<ServiceDetailsScreenLoader> {
  late Future<ProvidedService> _serviceFuture;

  @override
  void initState() {
    super.initState();
    _serviceFuture = _fetchServiceDetails();
  }

  Future<ProvidedService> _fetchServiceDetails() async {
    final notifier = Provider.of<ServiceNotifier>(
      context,
      listen: false,
    );
    final detailedService =
        await notifier.fetchServiceDetails(widget.serviceId);
    return detailedService!;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProvidedService>(
      future: _serviceFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading service details...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.listService.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load service details',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.listService.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You can go back and try again',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Go Back'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _serviceFuture = _fetchServiceDetails();
                            });
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.hasData) {
          final detailedService = snapshot.data!;
          return ServiceDetailsScreen(
            initialService: detailedService,
            onEditPressed: widget.canManage
                ? () => _openEditForm(context, detailedService)
                : null,
          );
        }

        return ServiceDetailsScreen(
          initialService: widget.listService,
          onEditPressed: widget.canManage
              ? () => _openEditForm(context, widget.listService)
              : null,
        );
      },
    );
  }

  Future<void> _openEditForm(
      BuildContext context, ProvidedService service) async {
    final resolvedProviderId = service.productProviderId > 0
        ? service.productProviderId
        : (widget.selectedSupplierId > 0
            ? widget.selectedSupplierId
            : (Provider.of<ServiceNotifier>(context, listen: false)
                    .currentProviderId ??
                0));

    await Navigator.pushNamed(
      context,
      AppRoutes.serviceForm,
      arguments: {'providerId': resolvedProviderId, 'service': service},
    );
  }
}
