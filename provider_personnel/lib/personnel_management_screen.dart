import 'dart:async';

import 'package:app_constants/app_routes.dart';
import 'package:event/extensions/personnel_access_manager.dart';
import 'package:flutter/material.dart';
import 'package:verdelia_core/app/ManagementRule.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/app/AppUser.dart';
import 'package:event/personnel_notifier.dart';
import 'package:event/user_change_notifier.dart';
import 'package:provider_personnel/components/pending_tab_content.dart';
import 'package:provider_personnel/components/personnel_tab_content.dart';
import 'package:provider_personnel/components/privilege_dialog/privilege_dialog.dart';
import 'package:provider_personnel/components/search_invite_dialog.dart';
import 'package:provider_personnel/components/dashboard/add_options_sheet.dart';
import 'package:provider_personnel/components/dashboard/confirmation_dialogs.dart';
import 'package:provider_personnel/components/dashboard/privilege_dialog_manager.dart';
import 'package:ui/utils/qr_utils.dart';
import 'package:provider_personnel/components/dashboard/quick_stats_widget.dart';
import 'package:ui/components/search/search_bar_widget.dart';
import 'package:ui/components/store/StoreDashboardHeader.dart';
import 'package:provider/provider.dart';

class PersonnelManagementScreen extends StatefulWidget {
  final String supplierName;
  final int supplierId;
  final int orgId;
  final bool canManagePersonnel;
  final int userId;
  final List<int> accessibleSuppliers;
  final List<ManagementRule> userRules;
  final PersonnelAccessManager? accessManager;

  const PersonnelManagementScreen({
    super.key,
    required this.supplierName,
    required this.orgId,
    required this.supplierId,
    this.canManagePersonnel = true,
    this.userId = 0,
    this.accessibleSuppliers = const [],
    this.userRules = const [],
    this.accessManager,
  });

  @override
  State<PersonnelManagementScreen> createState() =>
      _PersonnelManagementScreenState();
}

class _PersonnelManagementScreenState extends State<PersonnelManagementScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late TabController _tabController;

  Timer? _debounceTimer;
  bool _isInitialLoadComplete = false;
  bool _initialized = false;

  late PersonnelNotifier _personnelNotifier;
  late AppUserNotifier _userNotifier;

  // ==================== LIFECYCLE ====================

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _personnelNotifier = context.read<PersonnelNotifier>();
        _userNotifier = context.read<AppUserNotifier>();

        if (!_isInitialLoadComplete) {
          _isInitialLoadComplete = true;
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _loadInitialData());
        }
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _tabController.removeListener(_onTabChanged);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  // ==================== DATA LOADING ====================

  void _loadInitialData() {
    _personnelNotifier.loadPersonnel(
      supplierId: widget.supplierId,
      reset: true,
      includePending: true,
    );
  }

  Future<void> _refreshData() async {
    await _personnelNotifier.loadPersonnel(
      supplierId: widget.supplierId,
      reset: true,
      includePending: true,
    );
  }

  // ==================== SEARCH ====================

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      _personnelNotifier.clearSearch(supplierId: widget.supplierId);
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        _personnelNotifier.searchPersonnel(query,
            supplierId: widget.supplierId);
      }
    });
  }

  // ==================== UI ====================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: cs.surface,
      floatingActionButton:
          widget.canManagePersonnel ? _buildFAB(cs, l10n) : null,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
      body: Column(
        children: [
          // ── Simple header ──
          DashboardHeader(
            leadingIcon: Icons.people_rounded,
            title: widget.supplierName,
            subtitle: l10n.personnelManagement,
            searchBar: SearchBarWidget(
              controller: _searchController,
              focusNode: _searchFocusNode,
              tabIndex: _tabController.index,
              supplierId: widget.supplierId,
            ),
          ),
          // ── Stats ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: QuickStatsWidget(supplierId: widget.supplierId),
          ),
          // ── Tab bar ──
          _buildTabBar(theme, cs, l10n),

          // ── Tab content ──
          Expanded(child: _buildActiveTab()),
        ],
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    ColorScheme cs,
    AppLocalizations l10n,
  ) {
    return Container(
      color: cs.surface,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people_rounded, size: 22, color: cs.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.personnelManagement,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SearchBarWidget(
            controller: _searchController,
            focusNode: _searchFocusNode,
            tabIndex: _tabController.index,
            supplierId: widget.supplierId,
          ),
        ],
      ),
    );
  }

  // ==================== TAB BAR ====================

  PreferredSizeWidget _buildTabBar(
    ThemeData theme,
    ColorScheme cs,
    AppLocalizations l10n,
  ) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: Container(
        color: cs.surface,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withOpacity(0.4),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: cs.outlineVariant.withOpacity(0.5),
            ),
          ),
          padding: const EdgeInsets.all(4),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: cs.primary,
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: EdgeInsets.zero,
            dividerColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            labelColor: cs.onPrimary,
            unselectedLabelColor: cs.onSurfaceVariant,
            labelStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 0.1,
            ),
            unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            tabs: [
              _buildTab(Icons.all_inclusive_rounded, l10n.allText),
              _buildTab(Icons.check_circle_rounded, l10n.status_active),
              _buildTab(Icons.schedule_rounded, l10n.pendingTxt),
            ],
          ),
        ),
      ),
    );
  }

  Tab _buildTab(IconData icon, String label) {
    return Tab(
      height: 40,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }

  // ==================== TAB CONTENT ====================

  Widget _buildActiveTab() {
    switch (_tabController.index) {
      case 0:
        return PersonnelTabContent(
          supplierId: widget.supplierId,
          includePending: true,
          onRefresh: _refreshData,
          onShowPrivilegeDialog: _showPrivilegeDialog,
          onShowRemoveDialog: _showRemoveDialog,
          onCancelInvitation: _cancelInvitation,
          canManage: widget.canManagePersonnel,
        );

      case 1:
        return PersonnelTabContent(
          supplierId: widget.supplierId,
          includePending: false,
          onRefresh: _refreshData,
          onShowPrivilegeDialog: _showPrivilegeDialog,
          onShowRemoveDialog: _showRemoveDialog,
          onCancelInvitation: _cancelInvitation,
          canManage: widget.canManagePersonnel,
        );

      case 2:
        return PendingTabContent(
          supplierId: widget.supplierId,
          supplierName: widget.supplierName,
          onRefresh: _refreshData,
          onShowPrivilegeDialog: _showPrivilegeDialog,
          onShowRemoveDialog: _showRemoveDialog,
          onCancelInvitation: _cancelInvitation,
          onShowAddOptions: _showAddOptions,
          canManage: widget.canManagePersonnel,
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFAB(ColorScheme colorScheme, AppLocalizations l10n) {
    return FloatingActionButton.extended(
      onPressed: _showAddOptions,
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 3,
      icon: const Icon(Icons.person_add_alt_1, size: 20),
      label: Text(
        l10n.addMemberText,
      ),
    );
  }

  // ==================== ACTIONS ====================

  void _showAddOptions() {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddOptionsSheet(
        supplierName: widget.supplierName,
        onQROption: _handleQRCodeOption,
        onSearchOption: _showSearchInviteDialog,
      ),
    );
  }

  void _showSearchInviteDialog() {
    final currentUserId = _userNotifier.appUser?.idAppUser;
    if (currentUserId == null || !mounted) return;

    showDialog(
      context: context,
      builder: (_) => SearchInviteDialog(
        orgId: widget.orgId,
        onUserSelected: (user, privileges) async {
          await _addUserToSupplier(user, privileges);
          _refreshData();
        },
        userId: currentUserId,
        supplierId: widget.supplierId,
        supplierName: widget.supplierName,
      ),
    );
  }

  Future<void> _handleQRCodeOption() async {
    if (!mounted) return;
    Navigator.pop(context);

    final qrCode = await Navigator.pushNamed(context, AppRoutes.QRScanPage);
    if (qrCode is! String || qrCode.isEmpty) return;

    final userId = extractUserIdFromQR(qrCode);
    if (userId == null) return;

    final AppUser? user = await _userNotifier.fetchUserPassively(userId);
    if (user == null || !mounted) return;

    final privilegesBitmask = await showDialog<int>(
      context: context,
      builder: (_) => PrivilegeDialog(
        user: user,
        supplierName: widget.supplierName,
        initialPrivileges: 0,
      ),
    );

    if (privilegesBitmask != null && mounted) {
      await _addUserToSupplier(user, privilegesBitmask, fromQR: true);
    }
  }

  Future<void> _addUserToSupplier(
    AppUser user,
    int privileges, {
    bool fromQR = false,
  }) async {
    final success = await _personnelNotifier.addTeamMember(
      user.idAppUser ?? 0,
      supplierId: widget.supplierId,
      orgId: widget.orgId,
      privilege: privileges,
      fromQR: fromQR,
    );

    if (mounted) {
      _showSnackBar(
        success
            ? 'Added ${user.personFirstName ?? 'user'} to ${widget.supplierName}'
            : 'Failed to add user',
        success,
      );
      if (success) _refreshData();
    }
  }

  Future<void> _showPrivilegeDialog(
    AppUser user,
    bool isPending,
    int ruleId,
  ) async {
    await PrivilegeDialogManager.showPrivilegeDialog(
      context: context,
      user: user,
      isPending: isPending,
      ruleId: ruleId,
      supplierId: widget.supplierId,
      supplierName: widget.supplierName,
      personnelNotifier: _personnelNotifier,
      orgId: widget.orgId,
      onRefresh: _refreshData,
    );
  }

  Future<void> _cancelInvitation(AppUser user, int ruleId) async {
    await ConfirmationDialogs.showCancelInvitationDialog(
      context: context,
      user: user,
      onConfirm: () async {
        final success = await _personnelNotifier.removeUserFromSupplier(
          ruleId,
          user.idAppUser ?? 0,
          widget.supplierId,
        );

        if (success && mounted) {
          _showSnackBar(
            "${user.personFirstName ?? 'User'}'s invitation has been cancelled",
            true,
          );
          _refreshData();
        }
      },
    );
  }

  void _showRemoveDialog(int ruleId, AppUser user) {
    ConfirmationDialogs.showRemoveMemberDialog(
      context: context,
      userName: user.personFirstName ?? '',
      supplierName: widget.supplierName,
      onConfirm: () => _removeUserFromSupplier(ruleId, user),
    );
  }

  Future<void> _removeUserFromSupplier(int ruleId, AppUser user) async {
    final success = await _personnelNotifier.removeUserFromSupplier(
      ruleId,
      user.idAppUser ?? 0,
      widget.supplierId,
    );

    if (mounted) {
      _showSnackBar(
        success
            ? 'Removed ${user.personFirstName ?? 'user'}'
            : 'Failed to remove user',
        success,
      );
      if (success) _refreshData();
    }
  }

  // ==================== HELPERS ====================

  void _showSnackBar(String message, bool isSuccess) {
    final colorScheme = Theme.of(context).colorScheme;
    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                color: isSuccess
                    ? colorScheme.onTertiaryContainer
                    : colorScheme.onErrorContainer,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: isSuccess
              ? colorScheme.tertiaryContainer
              : colorScheme.errorContainer,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 2),
        ),
      );
  }
}
