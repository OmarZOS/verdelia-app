import 'package:flutter/material.dart';
import 'package:app_constants/app_constants.dart';
import 'package:verdelia_core/app/Notifications/VerdeliaNotification.dart';
import 'package:event/notification_notifier.dart';
import 'package:event/user_change_notifier.dart';
import 'package:tabbed_home/screens/components/NotificationAction.dart';
import 'package:provider/provider.dart';
import 'package:tabbed_home/screens/components/notification/notification_action_handler.dart';
import 'package:tabbed_home/screens/components/notification/notification_content.dart';
import 'package:tabbed_home/screens/components/notification/notification_footer.dart';
import 'package:tabbed_home/screens/components/notification/notification_header.dart';

class NotificationsPanel extends StatefulWidget {
  const NotificationsPanel({super.key});

  @override
  State<NotificationsPanel> createState() => _NotificationsPanelState();
}

class _NotificationsPanelState extends State<NotificationsPanel> {
  bool _isInitialized = false;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  int _currentPage = 0;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadNotifications();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final notifier = context.read<NotificationNotifier>();
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        notifier.hasMore &&
        !notifier.isLoading &&
        !_isLoadingMore) {
      _loadMoreNotifications();
    }
  }

  Future<void> _loadNotifications() async {
    final userNotifier = context.read<AppUserNotifier>();
    final notifier = context.read<NotificationNotifier>();

    final currentUserId = userNotifier.appUser?.idAppUser;
    if (currentUserId != null && currentUserId > 0) {
      _currentPage = 0;
      await notifier.loadInitialNotifications(
        currentUserId,
        limit: _pageSize,
      );
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    final notifier = context.read<NotificationNotifier>();
    _currentPage++;
    await notifier.loadMoreNotifications(limit: _pageSize);

    if (mounted) {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _refreshNotifications() async {
    final userNotifier = context.read<AppUserNotifier>();
    final notifier = context.read<NotificationNotifier>();
    final currentUserId = userNotifier.appUser?.idAppUser;
    if (currentUserId != null && currentUserId > 0) {
      _currentPage = 0;
      await notifier.refreshNotifications(
        currentUserId,
        limit: _pageSize,
      );
    }
  }

  void _handleAction(NotificationAction action) {
    final notifier = context.read<NotificationNotifier>();
    final handler = NotificationActionHandler(
      context: context,
      notifier: notifier,
    );
    handler.handle(action);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Consumer<NotificationNotifier>(
        builder: (context, notifier, child) {
          final unreadCount = notifier.unreadCount;
          final notifications = notifier.sortedByDate;
          final isLoading = notifier.isLoading;
          final error = notifier.error;
          final hasMore = notifier.hasMore;
          final totalCount = notifier.totalCount;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              NotificationHeader(
                notifier: notifier,
                unreadCount: unreadCount,
                totalCount: totalCount,
                onClose: () => Navigator.pop(context),
              ),

              // Content
              Expanded(
                child: NotificationContent(
                  notifier: notifier,
                  notifications: notifications,
                  isLoading: isLoading,
                  error: error,
                  hasMore: hasMore,
                  isLoadingMore: _isLoadingMore,
                  onRefresh: _refreshNotifications,
                  onAction: _handleAction,
                  scrollController: _scrollController, // Pass the controller
                ),
              ),

              // Footer Actions
              if (notifications.isNotEmpty)
                NotificationFooter(
                  notifier: notifier,
                  unreadCount: unreadCount,
                  onMarkAllRead: () async {
                    await notifier.markAllAsRead();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('All notifications marked as read'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  onViewAll: () {
                    Navigator.pop(context);
                    // TODO: Navigate to full notifications screen
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
