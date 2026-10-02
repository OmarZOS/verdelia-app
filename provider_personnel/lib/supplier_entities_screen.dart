// supplier_entities_screen.dart

import 'package:app_constants/app_routes.dart';
import 'package:event/extensions/personnel_access_manager.dart';
import 'package:flutter/material.dart';
import 'package:event/personnel_notifier.dart';
import 'package:event/supplier_change_notifier.dart';
import 'package:verdelia_core/app/ManagementRule.dart';
import 'package:verdelia_core/business/Supplier.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:provider_personnel/components/supplier_card.dart';

class SupplierEntitiesScreen extends StatefulWidget {
  final int userId;
  final List<int> accessibleSuppliers;
  final List<ManagementRule> userRules;
  final List<Supplier> suppliers;
  final List<AccessibleSupplier> suppliersWithAccess;
  final PersonnelNotifier personnelNotifier;
  final SupplierChangeNotifier supplierNotifier;
  final PersonnelAccessManager accessManager;

  const SupplierEntitiesScreen({
    Key? key,
    required this.userId,
    required this.accessibleSuppliers,
    required this.userRules,
    required this.suppliers,
    required this.suppliersWithAccess,
    required this.personnelNotifier,
    required this.supplierNotifier,
    required this.accessManager,
  }) : super(key: key);

  @override
  State<SupplierEntitiesScreen> createState() => _SupplierEntitiesScreenState();
}

class _SupplierEntitiesScreenState extends State<SupplierEntitiesScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterType = 'all';
  bool _isLoading = false;

  // ============================================================
  // COMPUTED GETTERS
  // ============================================================

  List<AccessibleSupplier> get _visibleSuppliers {
    if (widget.suppliersWithAccess.isEmpty && widget.userId > 0) {
      return widget.accessManager
          .getAccessibleSuppliersWithAccessTypeSync(widget.userId);
    }
    return widget.suppliersWithAccess;
  }

  List<AccessibleSupplier> get _owned =>
      _visibleSuppliers.where((s) => s.isOwner).toList();

  List<AccessibleSupplier> get _managed =>
      _visibleSuppliers.where((s) => s.isManaged).toList();

  List<ManagementRule> get _pendingRules {
    return widget.personnelNotifier.getPendingRulesForUser(widget.userId);
  }

  List<ManagementRule> get _pendingSuppliersWithRules {
    return _pendingRules.where((r) => r.productProvider != null).toList();
  }

  int get _pendingCount => _pendingRules.length;

  /// Filter suppliers by the current type and query.
  ///
  /// The search matches against the flat provider name AND against
  /// every language in the naming contribution, so a user typing in
  /// Arabic or French finds the same rows a user typing in English
  /// would find.
  List<AccessibleSupplier> get _filtered {
    var suppliers = _visibleSuppliers;

    switch (_filterType) {
      case 'owned':
        suppliers = _owned;
        break;
      case 'managed':
        suppliers = _managed;
        break;
      case 'pending':
        return [];
      default:
        break;
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      suppliers = suppliers.where((s) {
        // Provider matches: flat + every language on the naming block.
        final providerMatches = _matchesQuery(s.supplier.providerName, q) ||
            _matchesQuery(s.supplier.naming?.en, q) ||
            _matchesQuery(s.supplier.naming?.ar, q) ||
            _matchesQuery(s.supplier.naming?.fr, q);

        // Org matches: same idea.
        final orgMatches =
            _matchesQuery(s.supplier.providerOrganisationName, q) ||
                _matchesQuery(s.supplier.organisationNaming?.en, q) ||
                _matchesQuery(s.supplier.organisationNaming?.ar, q) ||
                _matchesQuery(s.supplier.organisationNaming?.fr, q);

        return providerMatches || orgMatches;
      }).toList();
    }

    return suppliers;
  }

  bool _matchesQuery(String? value, String lowerQuery) =>
      value != null && value.toLowerCase().contains(lowerQuery);

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.supplierNotifier.fetchSupplierCategories();
      if (_visibleSuppliers.isEmpty && widget.userId > 0) {
        _loadData();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // DATA LOADING
  // ============================================================

  Future<void> _loadData() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await Future.wait([
        widget.supplierNotifier.fetchOwnedSuppliers(
          widget.userId,
          forceRefresh: true,
        ),
        widget.personnelNotifier.loadPersonnel(
          userId: widget.userId,
          reset: true,
          includePending: true,
        ),
      ]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context)?.refreshSuccess ?? 'Refreshed'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)?.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async => _loadData();

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final filtered = _filtered;
    final visibleCount = _visibleSuppliers.length;
    final pendingCount = _pendingCount;
    final isPendingFilter = _filterType == 'pending';

    if (_isLoading && visibleCount == 0 && pendingCount == 0) {
      return _buildLoading(l10n);
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(l10n, cs, visibleCount, pendingCount),
            _buildSearch(l10n, cs),
            _buildStats(l10n, cs, visibleCount, pendingCount),
            _buildFilters(l10n, cs),
            Expanded(
              child: isPendingFilter
                  ? _buildPendingList(l10n, cs)
                  : _buildList(l10n, filtered),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFab(l10n, cs),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(
    AppLocalizations? l10n,
    ColorScheme cs,
    int count,
    int pending,
  ) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cs.primary,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: cs.onPrimary),
              onPressed: () => Navigator.pop(context),
              tooltip: l10n?.back ?? 'Back',
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.businesses ?? 'Businesses',
                    style: TextStyle(
                      color: cs.onPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$count ${l10n?.accessible ?? 'accessible'}${pending > 0 ? ' • $pending ${l10n?.pending ?? 'pending'}' : ''}',
                    style: TextStyle(
                      color: cs.onPrimary.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.onPrimary,
                      ),
                    )
                  : Icon(Icons.refresh, color: cs.onPrimary),
              onPressed: _isLoading ? null : _refresh,
              tooltip: l10n?.refresh ?? 'Refresh',
            ),
          ],
        ),
      );

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearch(AppLocalizations? l10n, ColorScheme cs) => Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: l10n?.searchBusinesses ?? 'Search businesses...',
            prefixIcon: Icon(Icons.search, color: cs.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.outline.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.outline.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.primary, width: 2),
            ),
            filled: true,
            fillColor: cs.surfaceVariant.withOpacity(0.2),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: cs.onSurfaceVariant),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
          ),
        ),
      );

  // ============================================================
  // STATS
  // ============================================================

  Widget _buildStats(
    AppLocalizations? l10n,
    ColorScheme cs,
    int total,
    int pending,
  ) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _chip(l10n?.total ?? 'Total', total, cs.primary),
            const SizedBox(width: 8),
            _chip(l10n?.owned ?? 'Owned', _owned.length, Colors.blue),
            const SizedBox(width: 8),
            _chip(l10n?.managed ?? 'Managed', _managed.length, Colors.green),
            if (pending > 0) ...[
              const SizedBox(width: 8),
              _chip(l10n?.pending ?? 'Pending', pending, Colors.orange),
            ],
          ],
        ),
      );

  Widget _chip(String label, int count, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 11),
            ),
          ],
        ),
      );

  // ============================================================
  // FILTERS
  // ============================================================

  Widget _buildFilters(AppLocalizations? l10n, ColorScheme cs) {
    final filters = [
      {'value': 'all', 'label': l10n?.all ?? 'All'},
      {'value': 'owned', 'label': l10n?.owned ?? 'Owned'},
      {'value': 'managed', 'label': l10n?.managed ?? 'Managed'},
      {'value': 'pending', 'label': l10n?.pendingInvitations ?? 'Pending'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final selected = _filterType == f['value'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(f['label']!),
                selected: selected,
                onSelected: (_) => setState(() => _filterType = f['value']!),
                selectedColor: cs.primary.withOpacity(0.15),
                checkmarkColor: cs.primary,
                labelStyle: TextStyle(
                  color: selected ? cs.primary : cs.onSurface,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
                side: selected
                    ? BorderSide(color: cs.primary, width: 2)
                    : BorderSide(color: cs.outline.withOpacity(0.3)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ============================================================
  // PENDING LIST
  // ============================================================

  Widget _buildPendingList(AppLocalizations? l10n, ColorScheme cs) {
    final pendingRules = _pendingSuppliersWithRules;

    if (pendingRules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              l10n?.noPendingInvitations ?? 'No pending invitations',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pendingRules.length,
      itemBuilder: (_, i) => _buildPendingCard(l10n, cs, pendingRules[i]),
    );
  }

  Widget _buildPendingCard(
    AppLocalizations? l10n,
    ColorScheme cs,
    ManagementRule rule,
  ) {
    final supplier = rule.productProvider!;
    final createdAt = rule.createdAt;

    // Resolve the name for the ambient locale so the pending card
    // shows the same translation the rest of the app uses.
    final localeLang = Localizations.localeOf(context).languageCode;
    final displayName = supplier.nameFor(localeLang);
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.orange.withOpacity(0.3), width: 1.5),
      ),
      elevation: 2,
      shadowColor: Colors.orange.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.orange.withOpacity(0.1),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              l10n?.pending ?? 'Pending',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (createdAt != null)
                            Text(
                              _formatDate(createdAt.toIso8601String()),
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleInvitation(rule, true),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: Text(l10n?.decline ?? 'Decline'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleInvitation(rule, false),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(l10n?.accept ?? 'Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INVITATION ACTIONS
  // ============================================================

  Future<void> _handleInvitation(ManagementRule rule, bool isDecline) async {
    final l10n = AppLocalizations.of(context);
    final answer = isDecline ? 1 : 0;

    try {
      final success = await widget.personnelNotifier.answerInvitation(
        ruleId: rule.idManagementRule,
        answer: answer,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? (isDecline
                      ? l10n?.invitationDeclinedSuccessfully ??
                          'Invitation declined successfully'
                      : l10n?.invitationAcceptedSuccessfully ??
                          'Invitation accepted successfully')
                  : l10n?.failedToProcessInvitation ??
                      'Failed to process invitation',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n?.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============================================================
  // LIST
  // ============================================================

  Widget _buildList(
      AppLocalizations? l10n, List<AccessibleSupplier> suppliers) {
    if (suppliers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? l10n?.noResults ?? 'No results found'
                  : l10n?.noBusinesses ?? 'No businesses',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            if (_searchQuery.isNotEmpty)
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                icon: const Icon(Icons.clear, size: 18),
                label: Text(l10n?.clearSearch ?? 'Clear search'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: suppliers.length,
      itemBuilder: (_, i) => _buildSupplierCard(l10n, suppliers[i]),
    );
  }

  // ============================================================
  // SUPPLIER CARD
  // ============================================================

  Widget _buildSupplierCard(AppLocalizations? l10n, AccessibleSupplier data) {
    final s = data.supplier;
    final rule = widget.userRules.firstWhere(
      (r) => r.productProvider?.idProductProvider == s.idProductProvider,
      orElse: () => ManagementRule.empty(),
    );

    final hasManage = widget.personnelNotifier.hasPrivilege(
      widget.userId,
      s.idProductProvider,
      'personnel_manage',
    );
    final hasView = widget.personnelNotifier.hasPrivilege(
      widget.userId,
      s.idProductProvider,
      'personnel_view',
    );

    Widget? trailing;
    if (hasManage) {
      trailing = _permissionChip(l10n?.canManage ?? 'Can Manage', Colors.green);
    } else if (hasView) {
      trailing = _permissionChip(l10n?.canView ?? 'Can View', Colors.blue);
    }

    return SupplierCard(
      managementRule: rule.idManagementRule != 0 ? rule : null,
      supplier: s,
      onTap: () => _showPrivilegesDialog(context, s),
      trailing: trailing,
      statusColor: data.isOwner
          ? Colors.blue
          : (rule.isPending ? Colors.orange : Colors.green),
      statusText: data.isOwner
          ? (l10n?.owner ?? 'Owner')
          : (rule.isPending
              ? (l10n?.pending ?? 'Pending')
              : (l10n?.managed ?? 'Managed')),
    );
  }

  Widget _permissionChip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );

  // ============================================================
  // PRIVILEGES DIALOG
  // ============================================================

  void _showPrivilegesDialog(BuildContext context, Supplier supplier) {
    final rules = widget.userRules
        .where(
          (r) =>
              r.productProvider?.idProductProvider ==
              supplier.idProductProvider,
        )
        .toList();

    if (rules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.noPrivileges ??
                'No privileges assigned.',
          ),
          backgroundColor: Colors.grey,
        ),
      );
      return;
    }

    final active = rules.where((r) => r.isActive).toList();
    final pending = rules.where((r) => r.isPending).toList();

    // Resolve the name once for the dialog header.
    final localeLang = Localizations.localeOf(context).languageCode;
    final displayName = supplier.nameFor(localeLang);
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                initial,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (active.isNotEmpty) ...[
                _privilegeSection(
                  AppLocalizations.of(context)?.activePrivileges ??
                      'Active Privileges',
                  active,
                  true,
                ),
                const SizedBox(height: 12),
              ],
              if (pending.isNotEmpty) ...[
                _privilegeSection(
                  AppLocalizations.of(context)?.pendingPrivileges ??
                      'Pending Privileges',
                  pending,
                  false,
                ),
              ],
              if (rules.isEmpty)
                Text(
                  AppLocalizations.of(context)?.noPrivileges ??
                      'No privileges assigned.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)?.close ?? 'Close'),
          ),
          if (active.isNotEmpty || pending.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _navigateToSupplierManage(context, supplier);
              },
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(AppLocalizations.of(context)?.manage ?? 'Manage'),
            ),
        ],
      ),
    );
  }

  Widget _privilegeSection(
          String title, List<ManagementRule> rules, bool active) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: active ? Colors.green : Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          ...rules.map((r) => _privilegeTile(r, active)),
        ],
      );

  Widget _privilegeTile(ManagementRule rule, bool active) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (active ? Colors.green : Colors.orange).withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (active ? Colors.green : Colors.orange).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            active ? Icons.check_circle_rounded : Icons.access_time_rounded,
            color: active ? Colors.green : Colors.orange,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getPrivilegeDisplay(rule.managementRuleCode, l10n),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                ),
                if (rule.managementRuleExpiry != null)
                  Text(
                    '${l10n?.expiresLabel ?? 'Expires'}: '
                    '${_formatDate(rule.managementRuleExpiry!)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: (active ? Colors.green : Colors.orange).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              active
                  ? (l10n?.activeStatus ?? 'Active')
                  : (l10n?.pendingStatus ?? 'Pending'),
              style: TextStyle(
                fontSize: 9,
                color: active ? Colors.green : Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Human-readable label for a rule code.
  ///
  /// Falls back to `AppLocalizations.privilegeByCode` when available;
  /// otherwise returns the raw code. Migrate this map to ARB when you
  /// want full localization; the fallback keeps the screen working
  /// while the ARB keys are being added.
  String _getPrivilegeDisplay(int code, AppLocalizations? l10n) {
    // If AppLocalizations exposes a `privilege_<code>` lookup, use it.
    // Uncomment and adapt once the ARB keys land:
    //
    // final resolved = l10n?.privilegeByCode(code);
    // if (resolved != null && resolved.isNotEmpty) return resolved;

    const map = {
      1: 'Admin',
      2: 'Manage Personnel',
      3: 'View Personnel',
      4: 'Manage Inventory',
      5: 'View Inventory',
      6: 'Manage Services',
      7: 'View Services',
      8: 'Manage Orders',
      9: 'View Orders',
      10: 'Manage Finance',
      11: 'View Finance',
      12: 'Manage Operations',
      13: 'View Operations',
      14: 'Manage POS',
      15: 'View POS',
    };
    return map[code] ?? 'Privilege $code';
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _navigateToSupplierManage(BuildContext context, Supplier supplier) {
    Navigator.pushNamed(
      context,
      AppRoutes.supplierManage,
      arguments: {
        // Route arg stays the flat name — the downstream screen
        // resolves its own locale-aware name when it needs to render
        // a header. Passing the flat name keeps the argument stable
        // across locale changes.
        'supplierName': supplier.providerName,
        'orgId': supplier.idProviderOrganisation,
        'supplierId': supplier.idProductProvider,
      },
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Widget _buildLoading(AppLocalizations? l10n) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator.adaptive(),
              const SizedBox(height: 16),
              Text(l10n?.loading ?? 'Loading...'),
            ],
          ),
        ),
      );

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateString;
    }
  }

  Widget _buildFab(AppLocalizations? l10n, ColorScheme cs) =>
      FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(
            context,
            AppRoutes.supplierManage,
            arguments: {
              'supplierId': 0,
              'orgId': 0,
              'isNew': true,
            },
          );
        },
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        icon: const Icon(Icons.add_business_rounded),
        label: Text(l10n?.add ?? 'Add'),
      );
}
