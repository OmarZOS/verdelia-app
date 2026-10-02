import 'dart:developer';

import 'package:verdelia_core/app/Notifications/VerdeliaNotification.dart';
import 'package:verdelia_core/app/Notifications/NotificationContent.dart';
import 'package:verdelia_core/app/Notifications/Notifications/RoleInvitation.dart';

class NotificationList {
  final List<VerdeliaNotification> notifications;
  final int totalCount;
  final int unreadCount;

  NotificationList({
    required this.notifications,
    this.totalCount = 0,
    this.unreadCount = 0,
  });

  factory NotificationList.fromJson(dynamic json) {
    log("Getting notifications from JSON: $json");

    List<VerdeliaNotification> notifications = [];
    int totalCount = 0;
    int unreadCount = 0;

    // Handle different response formats
    if (json is List) {
      notifications = json
          .map((item) =>
              VerdeliaNotification.fromJson(item as Map<String, dynamic>))
          .toList();
      totalCount = notifications.length;
      unreadCount = notifications.where((n) => !n.isRead).length;
    } else if (json is Map<String, dynamic>) {
      // Handle paginated response
      if (json.containsKey('notifications') && json['notifications'] is List) {
        notifications = (json['notifications'] as List)
            .map((item) =>
                VerdeliaNotification.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (json.containsKey('data') && json['data'] is List) {
        notifications = (json['data'] as List)
            .map((item) =>
                VerdeliaNotification.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (json.containsKey('items') && json['items'] is List) {
        notifications = (json['items'] as List)
            .map((item) =>
                VerdeliaNotification.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      totalCount = json['total_count'] ?? json['total'] ?? notifications.length;
      unreadCount =
          json['unread_count'] ?? notifications.where((n) => !n.isRead).length;
    }

    return NotificationList(
      notifications: notifications,
      totalCount: totalCount,
      unreadCount: unreadCount,
    );
  }

  List<VerdeliaNotification> get unreadNotifications =>
      notifications.where((n) => !n.isRead).toList();

  List<VerdeliaNotification> get readNotifications =>
      notifications.where((n) => n.isRead).toList();

  List<VerdeliaNotification> get requiresActionNotifications =>
      notifications.where((n) => n.requiresAction).toList();

  // Get notifications by content type
  List<VerdeliaNotification> getRoleInvitations() {
    return notifications.where((n) => n.content is RoleInvitation).toList();
  }

  List<VerdeliaNotification> getByContentType<T extends NotificationContent>() {
    return notifications.where((n) => n.content is T).toList();
  }

  int get pendingActionCount => requiresActionNotifications.length;

  // Sort by date (newest first)
  List<VerdeliaNotification> get sortedByDate => List.from(notifications)
    ..sort((a, b) => b.effectiveDate.compareTo(a.effectiveDate));

  VerdeliaNotification? getNotificationById(int id) {
    try {
      return notifications.firstWhere((n) => n.idNotification == id);
    } catch (e) {
      return null;
    }
  }

  NotificationList markAllAsRead() {
    final updatedNotifications =
        notifications.map((n) => n.isRead ? n : n.markAsRead()).toList();
    return NotificationList(
      notifications: updatedNotifications,
      totalCount: totalCount,
      unreadCount: 0,
    );
  }

  NotificationList markAsRead(int id) {
    final updatedNotifications = notifications.map((n) {
      return n.idNotification == id ? n.markAsRead() : n;
    }).toList();
    final newUnreadCount = updatedNotifications.where((n) => !n.isRead).length;
    return NotificationList(
      notifications: updatedNotifications,
      totalCount: totalCount,
      unreadCount: newUnreadCount,
    );
  }

  NotificationList removeNotification(int id) {
    final updatedNotifications =
        notifications.where((n) => n.idNotification != id).toList();
    return NotificationList(
      notifications: updatedNotifications,
      totalCount: totalCount - 1,
      unreadCount:
          unreadCount - (getNotificationById(id)?.isRead == false ? 1 : 0),
    );
  }
}
