// invitations_page.dart
import 'package:flutter/material.dart';
import 'package:app_constants/app_constants.dart';
import 'package:verdelia_core/app/AppUser.dart';
import 'package:verdelia_core/app/ManagementRule.dart';
import 'package:event/personnel_notifier.dart';
import 'package:event/user_change_notifier.dart';
import 'package:ui/Services/ResponseHandler.dart';
import 'package:provider/provider.dart';

class InvitationsPage extends StatefulWidget {
  const InvitationsPage({super.key});

  @override
  State<InvitationsPage> createState() => _InvitationsPageState();
}

class _InvitationsPageState extends State<InvitationsPage> {
  bool _isLoading = false;
  String? _error;
  List<ManagementRule> _pendingInvitations = [];
  List<ManagementRule> _activeRules = [];

  @override
  void initState() {
    super.initState();
    _loadInvitations();
  }

  Future<void> _loadInvitations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userNotifier = context.read<AppUserNotifier>();
      final personnelNotifier = context.read<PersonnelNotifier>();

      final userId = userNotifier.appUser?.idAppUser ?? 0;
      if (userId == 0) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      // Load personnel to get rules
      await personnelNotifier.loadPersonnel(
        userId: userId,
        reset: true,
        includePending: true,
      );

      // Get pending invitations
      final pending = personnelNotifier.getPendingRulesForUser(userId);
      final active = personnelNotifier.getRulesForUser(userId);

      setState(() {
        _pendingInvitations = pending;
        _activeRules = active;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load invitations: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleInvitation(
    ManagementRule rule,
    bool accept,
  ) async {
    final personnelNotifier = context.read<PersonnelNotifier>();
    final key =
        'invitation_${rule.idManagementRule}_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final success = await personnelNotifier.answerInvitation(
          ruleId: rule.idManagementRule,
          answer: accept ? 0 : 1,
          callerKey: key,
          token: context.read<AppUserNotifier>().token);

      if (success) {
        ResponseHandler.handleResponse(
          context: context,
          statusCode: 200,
          responseCode: accept ? 'INVITATION_ACCEPTED' : 'INVITATION_REJECTED',
          finalMessage: accept ? 'Invitation accepted!' : 'Invitation declined',
        );
        // Refresh the list
        await _loadInvitations();
      } else {
        final response = personnelNotifier.getResponse(key);
        ResponseHandler.handleResponse(
          context: context,
          statusCode: response?.statusCode ?? 500,
          responseCode: response?.responseCode ?? 'ACTION_FAILED',
          finalMessage: response?.message ?? 'Action failed',
        );
      }
    } catch (e) {
      ResponseHandler.handleResponse(
        context: context,
        statusCode: 500,
        responseCode: 'ERROR',
        finalMessage: 'Error: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invitations'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInvitations,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading invitations...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInvitations,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_pendingInvitations.isEmpty && _activeRules.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: _loadInvitations,
      child: CustomScrollView(
        slivers: [
          // Pending Invitations Section
          if (_pendingInvitations.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                context,
                'Pending Invitations (${_pendingInvitations.length})',
                Icons.pending_actions,
              ),
            ),
          if (_pendingInvitations.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final rule = _pendingInvitations[index];
                  return _buildInvitationCard(context, rule, isPending: true);
                },
                childCount: _pendingInvitations.length,
              ),
            ),

          // Active Rules Section
          if (_activeRules.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                context,
                'Active Assignments (${_activeRules.length})',
                Icons.assignment_turned_in,
              ),
            ),
          if (_activeRules.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final rule = _activeRules[index];
                  return _buildInvitationCard(context, rule, isPending: false);
                },
                childCount: _activeRules.length,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No Invitations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "You don't have any pending invitations or active assignments.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadInvitations,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitationCard(
    BuildContext context,
    ManagementRule rule, {
    required bool isPending,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final providerName = rule.providerName;
    final organisationName = rule.organisationName;
    final status = rule.displayStatus;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isPending
            ? BorderSide(
                color: colorScheme.primary.withOpacity(0.3),
                width: 2,
              )
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isPending
                        ? colorScheme.primary.withOpacity(0.1)
                        : colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isPending ? Icons.pending : Icons.check_circle,
                    color:
                        isPending ? colorScheme.primary : colorScheme.secondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        providerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        organisationName,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        _getStatusColor(status, colorScheme).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(status, colorScheme),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Details
            Row(
              children: [
                Icon(
                  Icons.badge,
                  size: 16,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  'Role Code: ${rule.managementRuleCode}',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(rule.expiryDate.toString()),
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
              ],
            ),

            // Actions (only for pending invitations)
            if (isPending) ...[
              const SizedBox(height: 12),
              Divider(
                color: colorScheme.outline.withOpacity(0.1),
                height: 1,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _handleInvitation(rule, true),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Accept'),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handleInvitation(rule, false),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Decline'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        side: BorderSide(color: colorScheme.error),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status, ColorScheme colorScheme) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return colorScheme.primary;
      case 'ACTIVE':
        return colorScheme.secondary;
      case 'REJECTED':
        return colorScheme.error;
      case 'EXPIRED':
        return Colors.orange;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'No expiry';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = date.difference(now);

      if (diff.inDays < 0) {
        return 'Expired';
      } else if (diff.inDays == 0) {
        return 'Today';
      } else if (diff.inDays == 1) {
        return 'Tomorrow';
      } else if (diff.inDays < 7) {
        return 'In ${diff.inDays} days';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (_) {
      return dateStr;
    }
  }
}
