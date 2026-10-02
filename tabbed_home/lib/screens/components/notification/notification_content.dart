// notification_content.dart

import 'package:flutter/material.dart';
import 'package:verdelia_core/app/Notifications/VerdeliaNotification.dart';
import 'package:event/notification_notifier.dart';
import 'package:tabbed_home/screens/components/notification_item.dart';
import 'package:tabbed_home/screens/components/NotificationAction.dart';
import 'notification_helpers.dart';

class NotificationContent extends StatelessWidget {
  final NotificationNotifier notifier;
  final List<VerdeliaNotification> notifications;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback onRefresh;
  final Function(NotificationAction) onAction;
  final ScrollController? scrollController;

  const NotificationContent({
    super.key,
    required this.notifier,
    required this.notifications,
    required this.isLoading,
    required this.error,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onRefresh,
    required this.onAction,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && notifications.isEmpty) {
      return NotificationHelpers.buildLoadingIndicator();
    }

    if (error != null && notifications.isEmpty) {
      return NotificationHelpers.buildErrorState(
        context,
        error!,
        onRefresh,
      );
    }

    if (notifications.isEmpty) {
      return NotificationHelpers.buildEmptyNotifications(context);
    }

    return RefreshIndicator(
      onRefresh: onRefresh as RefreshCallback,
      child: ListView.separated(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: notifications.length + (hasMore ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index == notifications.length) {
            return NotificationHelpers.buildLoadMoreIndicator(
              context,
              notifier,
              isLoadingMore,
            );
          }
          return NotificationItem(
            notification: notifications[index],
            onMarkAsRead: () => notifier.markAsRead(
              notifications[index].idNotification,
            ),
            onAction: onAction,
            // onRefresh: onRefresh,
          );
        },
      ),
    );
  }
}
