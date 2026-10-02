import 'package:verdelia_core/app/Notifications/NotificationList.dart';
import 'package:verdelia_core/app/TraceableService.dart';

// Assuming you have a NotificationService class - here's a basic interface
class NotificationService extends TraceableService {
  Future<NotificationList> getNotificationsByUserId(int userId,
      {int page = 1, int limit = 20, String? callerKey}) async {
    // Your actual implementation would go here
    // This should return a Map with 'notifications' list and 'total' count
    throw UnimplementedError(
        'NotificationService.getNotificationsByUserId not implemented');
  }

  Future<void> markAsRead(int notificationId, {String? callerKey}) async {
    // Your implementation
    throw UnimplementedError('NotificationService.markAsRead not implemented');
  }

  Future<void> markAllAsRead(int userId, {String? callerKey}) async {
    // Your implementation
    throw UnimplementedError(
        'NotificationService.markAllAsRead not implemented');
  }

  Future<void> deleteNotification(int notificationId,
      {String? callerKey}) async {
    // Your implementation
    throw UnimplementedError(
        'NotificationService.deleteNotification not implemented');
  }
}
