import 'dart:async';

import 'package:flutter/material.dart';
import 'package:verdelia_core/app/AppUser.dart';
import 'package:event/personnel_notifier.dart';
import 'package:provider_personnel/components/privilege_dialog/privilege_dialog.dart';
import 'package:provider/provider.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

class SearchInviteDialog extends StatefulWidget {
  final Function(AppUser, int) onUserSelected;
  final int userId;
  final int? orgId;
  final int? supplierId;
  final String supplierName;

  const SearchInviteDialog({
    Key? key,
    required this.onUserSelected,
    required this.orgId,
    required this.userId,
    this.supplierId = 0,
    required this.supplierName,
  }) : super(key: key);

  @override
  State<SearchInviteDialog> createState() => _SearchInviteDialogState();
}

class _SearchInviteDialogState extends State<SearchInviteDialog> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      _isInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final notifier = context.read<PersonnelNotifier>();
        final existing = notifier.getPersonnelForSupplier(
          widget.supplierId ?? 0,
          includePending: true,
        );
        if (existing.isEmpty) {
          notifier.loadPersonnel(
            supplierId: widget.supplierId ?? 0,
            reset: true,
            includePending: true,
          );
        }
      });
    }
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    final query = _searchController.text.trim();
    final notifier = context.read<PersonnelNotifier>();

    if (query.length < 2) {
      notifier.clearSearch(supplierId: widget.supplierId ?? 0);
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        notifier.searchPersonnel(query, supplierId: widget.supplierId ?? 0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 600, minHeight: 400),
        child: Consumer<PersonnelNotifier>(
          builder: (context, notifier, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(l10n, colorScheme),
                _buildSearchBar(l10n, colorScheme, notifier.isLoading),
                Expanded(child: _buildContent(notifier, l10n)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations? l10n, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.searchAndInvite ?? 'Search & Invite',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n?.findUsersToAddTo(widget.supplierName) ??
                        'Find users to add to ${widget.supplierName}',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colorScheme.onPrimaryContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(
    AppLocalizations? l10n,
    ColorScheme colorScheme,
    bool isLoading,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n?.searchByNameUsernameOrRole ??
                      'Search by name, username, or role...',
                  prefixIcon: Icon(
                    Icons.search,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            size: 18,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                ),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            if (isLoading)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(PersonnelNotifier notifier, AppLocalizations? l10n) {
    final results = notifier.searchResults;
    final isLoading = notifier.isLoading;
    final isDebouncing = _debounceTimer?.isActive ?? false;
    final hasQuery = _searchController.text.trim().isNotEmpty;

    if ((isLoading || isDebouncing) && results.isEmpty && hasQuery) {
      return _buildLoadingState(l10n);
    }

    if (!hasQuery) {
      final personnel = notifier.getPersonnelForSupplier(
        widget.supplierId ?? 0,
        includePending: true,
      );
      if (personnel.isNotEmpty) {
        return _buildTeamMembers(notifier, personnel, l10n);
      }
      return _buildInitialState(l10n);
    }

    if (!isLoading && !isDebouncing && results.isEmpty) {
      return _buildEmptyState(notifier, l10n);
    }

    return _buildResults(notifier, results, l10n);
  }

  Widget _buildInitialState(AppLocalizations? l10n) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.group,
          size: 80,
          color: colorScheme.onSurfaceVariant.withOpacity(0.3),
        ),
        const SizedBox(height: 16),
        Text(
          l10n?.searchForUsers ?? 'Search for users',
          style: TextStyle(
            fontSize: 16,
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n?.enterNameUsernameOrRole ??
              'Enter a name, username, or role to find people',
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTeamMembers(
    PersonnelNotifier notifier,
    List<AppUser> members,
    AppLocalizations? l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            '${l10n?.currentTeam ?? 'Current Team'} (${members.length})',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final user = members[index];
              return _buildUserTile(user, notifier, l10n);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(AppLocalizations? l10n) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n?.searching ?? 'Searching...',
          style: TextStyle(
            fontSize: 16,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(PersonnelNotifier notifier, AppLocalizations? l10n) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.search_off,
          size: 80,
          color: colorScheme.onSurfaceVariant.withOpacity(0.3),
        ),
        const SizedBox(height: 16),
        Text(
          l10n?.noUsersFound ?? 'No users found',
          style: TextStyle(
            fontSize: 16,
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n?.tryAdjustingSearchTerms ?? 'Try adjusting your search terms',
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () {
            _searchController.clear();
            notifier.clearSearch(supplierId: widget.supplierId ?? 0);
          },
          icon: const Icon(Icons.refresh, size: 18),
          label: Text(l10n?.clearSearch ?? 'Clear Search'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.surfaceVariant,
            foregroundColor: colorScheme.onSurfaceVariant,
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildResults(
    PersonnelNotifier notifier,
    List<AppUser> results,
    AppLocalizations? l10n,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Text(
                '${l10n?.results ?? 'Results'}: ${results.length}',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final user = results[index];
              return _buildUserTile(user, notifier, l10n);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUserTile(
    AppUser user,
    PersonnelNotifier notifier,
    AppLocalizations? l10n,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final isUserInTeam = _isUserInTeam(user.idAppUser ?? 0, notifier);
    final isPending = _isUserPending(user.idAppUser ?? 0, notifier);
    final canInvite = !isUserInTeam || (isUserInTeam && isPending);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleUserTap(user, isUserInTeam, isPending, l10n),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isUserInTeam
                    ? (isPending
                        ? Colors.orange.withOpacity(0.3)
                        : Colors.green.withOpacity(0.3))
                    : colorScheme.outline.withOpacity(0.1),
                width: isUserInTeam ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                _buildUserAvatar(user, isUserInTeam, isPending),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${user.personFirstName} ${user.personLastName}'
                                  .trim(),
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isUserInTeam) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isPending
                                    ? Colors.orange.withOpacity(0.1)
                                    : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isPending
                                      ? Colors.orange.withOpacity(0.3)
                                      : Colors.green.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                isPending
                                    ? (l10n?.pending ?? 'Pending')
                                    : (l10n?.team ?? 'Team'),
                                style: textTheme.labelSmall?.copyWith(
                                  color:
                                      isPending ? Colors.orange : Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (user.appUserName != null &&
                          user.appUserName!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '@${user.appUserName!}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      _buildUserRole(
                        user.appUserType?.value ?? 'guest',
                        colorScheme,
                        textTheme,
                        l10n,
                      ),
                    ],
                  ),
                ),
                _buildAddButton(
                  colorScheme,
                  canInvite,
                  isUserInTeam,
                  isPending,
                  l10n,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(AppUser user, bool isUserInTeam, bool isPending) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: isUserInTeam
                ? (isPending
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1))
                : colorScheme.surfaceVariant,
            border: Border.all(
              color: isUserInTeam
                  ? (isPending
                      ? Colors.orange.withOpacity(0.3)
                      : Colors.green.withOpacity(0.3))
                  : colorScheme.outline.withOpacity(0.2),
              width: isUserInTeam ? 2 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child:
                user.appUserImageUrl != null && user.appUserImageUrl!.isNotEmpty
                    ? Image.network(
                        user.appUserImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildFallbackAvatar(
                          colorScheme,
                          user,
                          isUserInTeam,
                          isPending,
                        ),
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.primary,
                              ),
                            ),
                          );
                        },
                      )
                    : _buildFallbackAvatar(
                        colorScheme,
                        user,
                        isUserInTeam,
                        isPending,
                      ),
          ),
        ),
        if (isUserInTeam)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isPending ? Colors.orange : Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.surface,
                  width: 2,
                ),
              ),
              child: Icon(
                isPending ? Icons.access_time : Icons.check,
                size: 10,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFallbackAvatar(
    ColorScheme colorScheme,
    AppUser user,
    bool isUserInTeam,
    bool isPending,
  ) {
    final colors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    final color = colors[
        user.idAppUser != null ? user.idAppUser!.abs() % colors.length : 0];
    final initials = _getUserInitials(user);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.15), color.withOpacity(0.3)],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: isUserInTeam
                ? (isPending ? Colors.orange : Colors.green)
                : color,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildUserRole(
    String? role,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppLocalizations? l10n,
  ) {
    final roleText = _getLocalizedRole(role, l10n);
    final roleColor = _getRoleColor(role, colorScheme);
    final roleIcon = _getRoleIcon(role);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: roleColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: roleColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(roleIcon, size: 12, color: roleColor),
          const SizedBox(width: 4),
          Text(
            roleText,
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: roleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(
    ColorScheme colorScheme,
    bool canInvite,
    bool isUserInTeam,
    bool isPending,
    AppLocalizations? l10n,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: canInvite
            ? (isUserInTeam
                ? (isPending
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1))
                : colorScheme.primary.withOpacity(0.08))
            : colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: canInvite
              ? (isUserInTeam
                  ? (isPending
                      ? Colors.orange.withOpacity(0.2)
                      : Colors.green.withOpacity(0.2))
                  : colorScheme.primary.withOpacity(0.2))
              : colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Icon(
        isUserInTeam
            ? (isPending ? Icons.access_time : Icons.check)
            : Icons.person_add_alt_1_rounded,
        size: 18,
        color: canInvite
            ? (isUserInTeam
                ? (isPending ? Colors.orange : Colors.green)
                : colorScheme.primary)
            : colorScheme.onSurfaceVariant.withOpacity(0.3),
      ),
    );
  }

  // ============ HELPERS ============

  bool _isUserInTeam(int userId, PersonnelNotifier notifier) {
    final users = notifier.getPersonnelForSupplier(
      widget.supplierId ?? 0,
      includePending: true,
    );
    return users.any((user) => user.idAppUser == userId);
  }

  bool _isUserPending(int userId, PersonnelNotifier notifier) {
    return notifier.hasPendingRulesForSupplier(userId, widget.supplierId ?? 0);
  }

  void _handleUserTap(
    AppUser user,
    bool isUserInTeam,
    bool isPending,
    AppLocalizations? l10n,
  ) {
    if (isUserInTeam && !isPending) {
      _showAlreadyInTeamDialog(user, l10n);
      return;
    }

    _showPrivilegeDialog(user);
  }

  Future<void> _showPrivilegeDialog(AppUser user) async {
    int? existingPrivileges;

    try {
      final notifier = context.read<PersonnelNotifier>();
      final rule = notifier.getRuleForUser(
        userId: user.idAppUser ?? 0,
        supplierId: widget.supplierId ?? 0,
      );
      if (rule != null) {
        // existingPrivileges = rule.managementRuleCode ?? 0;
      }
    } catch (_) {}

    final privilegesBitmask = await showDialog<int>(
      context: context,
      builder: (context) => PrivilegeDialog(
        user: user,
        supplierName: widget.supplierName,
        initialPrivileges: existingPrivileges,
      ),
    );

    if (privilegesBitmask != null && mounted) {
      Navigator.pop(context);
      widget.onUserSelected(user, privilegesBitmask);
    }
  }

  void _showAlreadyInTeamDialog(AppUser user, AppLocalizations? l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.userAlreadyInTeam ?? 'User Already in Team'),
        content: Text(
          '${user.personFirstName} ${user.personLastName} ${l10n?.isAlreadyActiveMemberOf ?? 'is already an active member of'} ${widget.supplierName}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.ok ?? 'OK'),
          ),
        ],
      ),
    );
  }

  String _getLocalizedRole(String? role, AppLocalizations? l10n) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return l10n?.admin ?? 'Admin';
      case 'provider':
        return l10n?.provider ?? 'Provider';
      case 'manager':
        return l10n?.manager ?? 'Manager';
      case 'customer':
        return l10n?.customer ?? 'Customer';
      case 'staff':
        return l10n?.staff ?? 'Staff';
      default:
        return l10n?.user ?? 'User';
    }
  }

  Color _getRoleColor(String? role, ColorScheme colorScheme) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return colorScheme.error;
      case 'provider':
        return colorScheme.primary;
      case 'manager':
        return colorScheme.secondary;
      case 'customer':
        return colorScheme.tertiary;
      case 'staff':
        return Colors.orange;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  IconData _getRoleIcon(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return Icons.security_rounded;
      case 'provider':
        return Icons.business_rounded;
      case 'manager':
        return Icons.manage_accounts_rounded;
      case 'customer':
        return Icons.person_rounded;
      case 'staff':
        return Icons.badge_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  String _getUserInitials(AppUser user) {
    final firstName = user.personFirstName?.trim() ?? '';
    final lastName = user.personLastName?.trim() ?? '';

    if (firstName.isEmpty && lastName.isEmpty) return '?';
    final first = firstName.isNotEmpty ? firstName[0] : '';
    final last = lastName.isNotEmpty ? lastName[0] : '';
    return '$first$last'.toUpperCase();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
}
