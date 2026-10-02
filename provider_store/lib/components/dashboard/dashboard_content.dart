// (imports unchanged)

import 'package:app_constants/app_routes.dart';
import 'package:event/delivery_change_notifier.dart';
import 'package:event/finance_change_notifier.dart';
import 'package:event/product_change_notifier.dart';
import 'package:event/service_change_notifier.dart';
import 'package:event/supplier_change_notifier.dart';
import 'package:event/extensions/personnel_access_manager.dart';
import 'package:flutter/material.dart';
import 'package:verdelia_core/app/AppUser.dart';
import 'package:verdelia_core/business/Organisation.dart';
import 'package:verdelia_core/business/Supplier.dart';
import 'package:verdelia_core/business/privileges/Privileges.dart';
import 'package:event/cart_change_notifier.dart';
import 'package:event/personnel_notifier.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:provider_store/components/selling_point/cart_summary/cart_summary_screen.dart';
import 'dashboard_item.dart';
import 'dashboard_body.dart';
import 'dashboard_bottom_nav.dart';
import 'dashboard_fab.dart';
import 'no_access_screen.dart';
import 'pending_invitations_dialog.dart';
import 'package:provider/provider.dart';

// ============================================================
// DATA CLASSES
// ============================================================

class SupplierData {
  final int id;
  final String name;
  final Supplier supplier;
  final SupplierAccessType accessType;
  final int orgId;
  final String orgName;

  const SupplierData({
    required this.id,
    required this.name,
    required this.supplier,
    required this.accessType,
    required this.orgId,
    required this.orgName,
  });

  factory SupplierData.fromAccessible(AccessibleSupplier accessible) =>
      SupplierData(
        id: accessible.id,
        name: accessible.name,
        supplier: accessible.supplier,
        accessType: accessible.accessType,
        orgId: accessible.supplier.idProviderOrganisation,
        orgName: accessible.supplier.providerOrganisationName ?? '',
      );

  bool get isValid => id > 0;

  /// Locale-aware provider name. Falls back to the flat name when the
  /// supplier carries no naming contribution.
  String providerNameFor(String lang) => supplier.nameFor(lang);

  /// Locale-aware organisation name.
  String orgNameFor(String lang) => supplier.organisationNameFor(lang);
}

class _Module {
  final DashboardScreenType type;
  final IconData icon;

  /// ARB key resolved at build time. Storing the key rather than the
  /// already-localized string keeps this record const-constructible.
  final String labelKey;

  final List<String> privilegeIds;

  const _Module(this.type, this.icon, this.labelKey, this.privilegeIds);
}

// ============================================================
// DASHBOARD CONTENT
// ============================================================

class DashboardContent extends StatefulWidget {
  final AppUser currentUser;
  final PersonnelNotifier personnelNotifier;
  final SupplierChangeNotifier supplierNotifier;

  const DashboardContent({
    super.key,
    required this.currentUser,
    required this.personnelNotifier,
    required this.supplierNotifier,
  });

  @override
  State<DashboardContent> createState() => DashboardContentState();
}

class DashboardContentState extends State<DashboardContent> {
  int _selectedIndex = 0;
  int _selectedSupplierId = 0;
  bool _isLoading = true;

  late PersonnelAccessManager _accessManager;
  final List<SupplierData> _availableSuppliers = [];

  @override
  void initState() {
    super.initState();
    _accessManager = PersonnelAccessManager(
      personnelNotifier: widget.personnelNotifier,
      supplierNotifier: widget.supplierNotifier,
    );
    widget.supplierNotifier.addListener(_onSupplierChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    widget.supplierNotifier.removeListener(_onSupplierChanged);
    super.dispose();
  }

  void _onSupplierChanged() {
    final id = widget.supplierNotifier.selectedSupplierId ?? 0;
    if (id != 0 && id != _selectedSupplierId) {
      setState(() => _selectedSupplierId = id);
      _loadDataForSupplier(id);
    }
  }

  SupplierData? get _currentSupplier {
    if (_selectedSupplierId <= 0) return null;
    for (final s in _availableSuppliers) {
      if (s.id == _selectedSupplierId) return s;
    }
    return null;
  }

  /// Ambient locale for all name resolutions on this screen.
  String get _localeLang => Localizations.localeOf(context).languageCode;

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoading();
    if (_availableSuppliers.isEmpty) return _buildNoAccess();

    final items = _buildDashboardItems();
    if (items.isEmpty) return _buildNoAccess();

    return _buildDashboard(items);
  }

  Widget _buildDashboard(List<DashboardItem> items) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: DashboardBody(
              selectedIndex: _selectedIndex,
              items: items,
              selectedSupplierId: _selectedSupplierId,
            ),
          ),
        ],
      ),
      bottomNavigationBar: DashboardBottomNav(
        selectedIndex: _selectedIndex,
        items: items,
        onIndexChanged: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final current = _currentSupplier;

    // Resolve the two names for the ambient locale.
    final displayName = current?.providerNameFor(_localeLang) ??
        (l10n?.selectSupplier ?? 'Select supplier');
    final organisationName = current?.orgNameFor(_localeLang) ?? '';

    return Material(
      color: cs.surface,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: cs.outline.withOpacity(0.06)),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
                onPressed: () => Navigator.maybePop(context),
                tooltip: l10n?.back ?? 'Back',
                splashRadius: 22,
              ),
              Expanded(
                child: InkWell(
                  onTap: _availableSuppliers.isEmpty
                      ? null
                      : () => _showSupplierSheet(),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      children: [
                        _SupplierAvatar(
                          supplier: current,
                          size: 36,
                          selected: true,
                          localeLang: _localeLang,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                organisationName.isNotEmpty
                                    ? organisationName
                                    : (l10n?.noOrganisation ??
                                        'No organisation'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (current?.accessType == SupplierAccessType.owner)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: cs.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              (l10n?.owner ?? 'OWNER').toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        Icon(Icons.keyboard_arrow_down_rounded,
                            color: cs.onSurfaceVariant, size: 22),
                      ],
                    ),
                  ),
                ),
              ),
              _buildPendingInvitationsButton(cs),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SUPPLIER PICKER SHEET
  // ============================================================

  Future<void> _showSupplierSheet() async {
    final l10n = AppLocalizations.of(context);
    final lang = _localeLang;

    // Group suppliers by organisation.
    final byOrg = <int, List<SupplierData>>{};
    for (final s in _availableSuppliers) {
      byOrg.putIfAbsent(s.orgId, () => []).add(s);
    }

    // Sort orgs by locale-aware name.
    final orgs = byOrg.keys.toList()
      ..sort((a, b) {
        final nameA = _orgNameFor(a, lang) ?? '';
        final nameB = _orgNameFor(b, lang) ?? '';
        return nameA.compareTo(nameB);
      });

    // Sort suppliers within each org: owned first, then locale-aware
    // alphabetical. The locale-aware sort matters in Arabic, where
    // the collation order differs from ASCII.
    for (final list in byOrg.values) {
      list.sort((a, b) {
        final aOwner = a.accessType == SupplierAccessType.owner ? 0 : 1;
        final bOwner = b.accessType == SupplierAccessType.owner ? 0 : 1;
        if (aOwner != bOwner) return aOwner - bOwner;
        return a.providerNameFor(lang).compareTo(b.providerNameFor(lang));
      });
    }

    final currentOrgId = _currentSupplier?.orgId ?? -1;
    final expanded = <int>{
      if (currentOrgId != -1) currentOrgId,
      if (currentOrgId == -1 && orgs.isNotEmpty) orgs.first,
    };

    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final cs = Theme.of(ctx).colorScheme;
            final theme = Theme.of(ctx);

            void toggleOrg(int orgId) {
              setSheetState(() {
                if (expanded.contains(orgId)) {
                  expanded.remove(orgId);
                } else {
                  expanded.add(orgId);
                }
              });
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              snap: true,
              snapSizes: const [0.4, 0.7, 0.95],
              builder: (ctx, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 4),
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: cs.onSurfaceVariant.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n?.selectSupplier ?? 'Select supplier',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    l10n?.chooseSupplierHint ??
                                        'Choose the business you want to manage',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close_rounded,
                                  color: cs.onSurfaceVariant),
                              onPressed: () => Navigator.pop(ctx),
                              splashRadius: 22,
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: cs.outline.withOpacity(0.06)),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: orgs.length,
                          itemBuilder: (ctx, i) {
                            final orgId = orgs[i];
                            final orgSuppliers = byOrg[orgId]!;
                            final orgName = _orgNameFor(orgId, lang) ??
                                (l10n?.noOrganisation ?? 'No organisation');
                            final isExpanded = expanded.contains(orgId);

                            return _buildOrgGroup(
                              ctx,
                              orgName: orgName,
                              suppliers: orgSuppliers,
                              expanded: isExpanded,
                              currentSupplierId: _selectedSupplierId,
                              onToggle: () => toggleOrg(orgId),
                              localeLang: lang,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );

    if (selected != null && selected != _selectedSupplierId) {
      widget.supplierNotifier.selectSupplier(selected);
    }
  }

  /// Locale-aware org name lookup. Returns the naming-contribution
  /// translation when the supplier carries one, else the flat name.
  String? _orgNameFor(int orgId, String lang) {
    for (final s in _availableSuppliers) {
      if (s.orgId == orgId) {
        final resolved = s.orgNameFor(lang);
        if (resolved.isNotEmpty) return resolved;
      }
    }
    return null;
  }

  Widget _buildOrgGroup(
    BuildContext context, {
    required String orgName,
    required List<SupplierData> suppliers,
    required bool expanded,
    required int currentSupplierId,
    required VoidCallback onToggle,
    required String localeLang,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    final ownedCount =
        suppliers.where((s) => s.accessType == SupplierAccessType.owner).length;
    final managedCount = suppliers.length - ownedCount;
    final containsCurrent = suppliers.any((s) => s.id == currentSupplierId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: containsCurrent && !expanded
              ? cs.primary.withOpacity(0.04)
              : Colors.transparent,
          child: InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: expanded ? 0.25 : 0.0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.business_rounded,
                      size: 16,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          orgName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _countSummary(ownedCount, managedCount, l10n),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${suppliers.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: expanded
              ? Column(
                  children: suppliers
                      .map((s) => _buildSupplierTile(
                            context,
                            supplier: s,
                            selected: s.id == currentSupplierId,
                            localeLang: localeLang,
                          ))
                      .toList(),
                )
              : const SizedBox.shrink(),
        ),
        Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: cs.outline.withOpacity(0.06)),
      ],
    );
  }

  String _countSummary(int owned, int managed, AppLocalizations? l10n) {
    final ownedLabel = l10n?.owned ?? 'owned';
    final managedLabel = l10n?.managed ?? 'managed';
    if (owned > 0 && managed > 0) {
      return '$owned $ownedLabel · $managed $managedLabel';
    }
    if (owned > 0) return '$owned $ownedLabel';
    if (managed > 0) return '$managed $managedLabel';
    return '';
  }

  Widget _buildSupplierTile(
    BuildContext context, {
    required SupplierData supplier,
    required bool selected,
    required String localeLang,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isOwner = supplier.accessType == SupplierAccessType.owner;
    final l10n = AppLocalizations.of(context);

    // Locale-aware provider name for the tile title.
    final displayName = supplier.providerNameFor(localeLang);

    return InkWell(
      onTap: () => Navigator.pop(context, supplier.id),
      child: Container(
        padding:
            const EdgeInsets.only(left: 58, right: 20, top: 10, bottom: 10),
        color: selected ? cs.primary.withOpacity(0.06) : Colors.transparent,
        child: Row(
          children: [
            _SupplierAvatar(
              supplier: supplier,
              size: 36,
              selected: selected,
              localeLang: localeLang,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? cs.primary : cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        isOwner
                            ? Icons.star_rounded
                            : Icons.person_outline_rounded,
                        size: 12,
                        color: isOwner ? cs.primary : cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          isOwner
                              ? (l10n?.owner ?? 'Owner')
                              : (l10n?.managed ?? 'Managed'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isOwner ? cs.primary : cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: cs.primary, size: 20)
            else
              const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DATA LOADING
  // ============================================================

  Future<void> _loadData() async {
    final userId = widget.currentUser.idAppUser ?? 0;
    if (userId == 0) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      widget.supplierNotifier.setCurrentUserId(userId);

      await Future.wait([
        widget.supplierNotifier.fetchOwnedSuppliers(userId, forceRefresh: true),
        widget.personnelNotifier.loadPersonnel(
          userId: userId,
          reset: true,
          includePending: true,
        ),
      ]);

      final suppliersWithAccess =
          _accessManager.getAccessibleSuppliersWithAccessTypeSync(userId);

      _buildSupplierList(suppliersWithAccess);
    } catch (e, stack) {
      debugPrint('Error loading data: $e\n$stack');
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(l10n?.failedToLoadSuppliers ?? 'Failed to load suppliers'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _buildSupplierList(List<AccessibleSupplier> suppliersWithAccess) {
    _availableSuppliers
      ..clear()
      ..addAll(suppliersWithAccess.map(SupplierData.fromAccessible));

    final stillValid = _selectedSupplierId > 0 &&
        _availableSuppliers.any((s) => s.id == _selectedSupplierId);

    if (!stillValid) {
      _selectedSupplierId = 0;
      _autoSelectDefaults();
    }

    if (_selectedSupplierId > 0) {
      _loadDataForSupplier(_selectedSupplierId);
    }
  }

  Future<void> _loadDataForSupplier(int supplierId) async {
    if (supplierId <= 0) return;

    final productNotifier = context.read<ProductNotifier>();
    final serviceNotifier = context.read<ServiceNotifier>();
    final deliveryNotifier = context.read<DeliveryChangeNotifier>();
    final financeNotifier = context.read<FinanceChangeNotifier>();
    final cartNotifier = context.read<CartChangeNotifier>();
    final userId = widget.currentUser.idAppUser ?? 0;

    cartNotifier.clearCart();
    deliveryNotifier.setFilters(providerId: supplierId);

    await Future.wait([
      productNotifier.fetchProducts(
          providerId: supplierId, reset: true, includeHidden: true),
      serviceNotifier.fetchServices(providerId: supplierId, reset: true),
      deliveryNotifier.fetchFirstPage(),
      financeNotifier.setProvider(supplierId),
      widget.personnelNotifier.loadPersonnel(
        userId: userId,
        supplierId: supplierId,
        reset: true,
      ),
    ]);
  }

  void _autoSelectDefaults() {
    if (_availableSuppliers.isEmpty) return;
    final owned = _availableSuppliers
        .where((s) => s.accessType == SupplierAccessType.owner)
        .toList();
    final next =
        owned.isNotEmpty ? owned.first.id : _availableSuppliers.first.id;
    widget.supplierNotifier.selectSupplier(next);
  }

  // ============================================================
  // DASHBOARD ITEMS — localized module labels
  // ============================================================

  List<DashboardItem> _buildDashboardItems() {
    if (_selectedSupplierId == 0) return [];

    final l10n = AppLocalizations.of(context)!;
    final data = _availableSuppliers.firstWhere(
      (s) => s.id == _selectedSupplierId,
      orElse: () => _availableSuppliers.first,
    );
    if (data.id == 0) return [];

    final userId = widget.currentUser.idAppUser ?? 0;
    final isOwner = data.accessType == SupplierAccessType.owner;

    // Module labels resolved from ARB at build time. The `_Module`
    // record keeps the ARB key as a string so it stays
    // const-constructible; the actual localization happens here.
    const modules = [
      _Module(DashboardScreenType.suppliersPersonnel, Icons.people_rounded,
          'modulePersonnel', ['personnel_manage', 'personnel_view']),
      _Module(DashboardScreenType.inventory, Icons.inventory_2_rounded,
          'moduleInventory', ['inventory_manage', 'inventory_view']),
      _Module(DashboardScreenType.services, Icons.handyman_sharp,
          'moduleServices', ['services_manage', 'services_view']),
      _Module(DashboardScreenType.pos, Icons.point_of_sale, 'moduleSeller',
          ['pos_manage', 'pos_view']),
      _Module(DashboardScreenType.orders, Icons.delivery_dining, 'moduleOrders',
          ['orders_manage', 'orders_view']),
      _Module(DashboardScreenType.operations, Icons.sell, 'moduleOperations',
          ['operations_manage', 'operations_view']),
      _Module(DashboardScreenType.finance, Icons.attach_money, 'moduleFinance',
          ['finance_manage', 'finance_view']),
    ];

    final items = <DashboardItem>[];
    for (final m in modules) {
      final hasAccess =
          isOwner || _hasPrivilege(userId, [data.id], m.privilegeIds);
      if (!hasAccess) continue;
      items.add(DashboardItem(
        type: m.type,
        icon: m.icon,
        label: _labelForModule(m.labelKey, l10n),
        index: items.length,
        privilegeLevel: isOwner
            ? PrivilegeLevel.manage
            : _getPrivilegeLevel(userId, [data.id], m.privilegeIds) ??
                PrivilegeLevel.view,
        supplierAccessType: data.accessType,
      ));
    }
    return items;
  }

  /// Resolve a module label key to its localized string. Keeps the
  /// mapping in one place so adding a module is a one-line change.
  String _labelForModule(String key, AppLocalizations l10n) {
    switch (key) {
      case 'modulePersonnel':
        return l10n.modulePersonnel;
      case 'moduleInventory':
        return l10n.moduleInventory;
      case 'moduleServices':
        return l10n.moduleServices;
      case 'moduleSeller':
        return l10n.moduleSeller;
      case 'moduleOrders':
        return l10n.moduleOrders;
      case 'moduleOperations':
        return l10n.moduleOperations;
      case 'moduleFinance':
        return l10n.moduleFinance;
      default:
        return key;
    }
  }

  bool _hasPrivilege(
      int userId, List<int> supplierIds, List<String> privilegeIds) {
    for (final s in supplierIds) {
      for (final p in privilegeIds) {
        if (widget.personnelNotifier.hasPrivilege(userId, s, p)) return true;
      }
    }
    return false;
  }

  PrivilegeLevel? _getPrivilegeLevel(
      int userId, List<int> supplierIds, List<String> privilegeIds) {
    for (final s in supplierIds) {
      for (final p in privilegeIds) {
        if (widget.personnelNotifier.hasPrivilege(userId, s, p)) {
          return p.contains('_manage')
              ? PrivilegeLevel.manage
              : PrivilegeLevel.view;
        }
      }
    }
    return null;
  }

  // ============================================================
  // LOADING / NO ACCESS
  // ============================================================

  Widget _buildLoading() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator.adaptive(strokeWidth: 2.5),
            ),
            const SizedBox(height: 16),
            Text(
              l10n?.loadingDashboard ?? 'Loading dashboard…',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAccess() => NoAccessScreen(
        currentUser: widget.currentUser,
        personnelNotifier: widget.personnelNotifier,
        onReturn: () => Navigator.maybePop(context),
      );

  // ============================================================
  // PENDING INVITATIONS
  // ============================================================

  Widget _buildPendingInvitationsButton(ColorScheme cs) {
    final userId = widget.currentUser.idAppUser ?? 0;
    final pending = widget.personnelNotifier.getPendingRulesForUser(userId);
    final count = pending.length;
    final l10n = AppLocalizations.of(context);

    return IconButton(
      splashRadius: 22,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.mail_outline_rounded,
              size: 22, color: cs.onSurfaceVariant),
          if (count > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                decoration:
                    BoxDecoration(color: cs.error, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: TextStyle(
                      fontSize: 10,
                      color: cs.onError,
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      onPressed: () => showDialog(
        context: context,
        builder: (ctx) => PendingInvitationsDialog(
          pendingRules: pending,
          personnelNotifier: widget.personnelNotifier,
        ),
      ),
      tooltip: l10n?.pendingInvitations ?? 'Pending invitations',
    );
  }

  // ============================================================
  // FAB
  // ============================================================

  Widget? _buildFab(List<DashboardItem> items) {
    if (_selectedIndex >= items.length) return null;
    final item = items[_selectedIndex];
    if (item.type == DashboardScreenType.suppliersPersonnel) return null;
    if (!item.showFloatingAction ||
        item.privilegeLevel != PrivilegeLevel.manage) {
      return null;
    }
    return DashboardFAB(
        item: item, onPressed: () => _handleFab(context, item.type));
  }

  void _handleFab(BuildContext context, DashboardScreenType type) {
    switch (type) {
      case DashboardScreenType.pos:
        _showCartSheet(context);
        break;
      case DashboardScreenType.inventory:
        Navigator.pushNamed(
          context,
          AppRoutes.productCreate,
          arguments: {
            'providerId': _selectedSupplierId,
            'lockProvider': true,
          },
        );
        break;
      case DashboardScreenType.services:
        Navigator.pushNamed(context, AppRoutes.serviceForm,
            arguments: {'providerId': _selectedSupplierId});
        break;
      default:
        _showDefaultAction(context, type);
    }
  }

  void _showCartSheet(BuildContext context) {
    final cart = context.read<CartChangeNotifier>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        snap: true,
        snapSizes: const [0.5, 0.85, 0.95],
        builder: (_, sc) => CartSummarySheet(cart: cart, scrollController: sc),
      ),
    );
  }

  void _showDefaultAction(BuildContext context, DashboardScreenType type) {
    final loc = AppLocalizations.of(context);
    final messages = {
      DashboardScreenType.operations: loc?.createNewOrder ?? 'Create New Order',
      DashboardScreenType.finance:
          loc?.createNewInvoice ?? 'Create New Invoice',
    };
    final msg = messages[type];
    if (msg != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ============================================================
// SUPPLIER AVATAR — locale-aware initial
// ============================================================

class _SupplierAvatar extends StatelessWidget {
  final SupplierData? supplier;
  final double size;
  final bool selected;

  /// Locale used to resolve the supplier name's first character.
  /// Without this, an Arabic or French supplier whose name starts with
  /// a different letter in those languages would show the wrong
  /// initial.
  final String localeLang;

  const _SupplierAvatar({
    required this.supplier,
    required this.size,
    required this.selected,
    required this.localeLang,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isOwner = supplier?.accessType == SupplierAccessType.owner;

    // Resolve the locale-aware name and take its first character.
    // Falls back to '?' when the name is empty.
    final name = supplier?.providerNameFor(localeLang) ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected
            ? cs.primary
            : (isOwner ? cs.primaryContainer : cs.surfaceContainerHighest),
        border: isOwner && !selected
            ? Border.all(color: cs.primary.withOpacity(0.6), width: 1.5)
            : null,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.w800,
            color: selected
                ? cs.onPrimary
                : (isOwner ? cs.primary : cs.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}
