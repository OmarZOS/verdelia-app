import 'dart:developer' as developer;
import 'package:app_constants/app_constants.dart';
import 'package:verdelia_core/app/Notifications/VerdeliaNotification.dart';
import 'package:verdelia_core/app/Notifications/NotificationList.dart';
import 'package:verdelia_core/app/Services/NotificationService.dart';
import 'package:verdelia_core/mediation/StorageService.dart';
import 'package:locator/locator.dart';

class NotificationImpl extends NotificationService {
  // Helper method to generate caller key
  String _getCallerKey(String method, {String? id, String? suffix}) {
    final parts = [method];
    if (id != null) parts.add(id);
    if (suffix != null) parts.add(suffix);
    if (parts.length == 1)
      parts.add(DateTime.now().millisecondsSinceEpoch.toString());
    return parts.join('_');
  }

  @override
  Future<NotificationList> getNotificationsByUserId(
    int userId, {
    int page = 0,
    int limit = 20,
    bool unreadOnly = false,
    String? callerKey,
  }) async {
    final key = callerKey ??
        _getCallerKey('getNotificationsByUserId',
            suffix: '${userId}_${page}_${limit}_${unreadOnly}');

    try {
      final storageService = AppLocator.get<StorageService>();

      final url =
          '${AppConstants.apiBaseUrl}${AppConstants.getNotificationsEndpoint}/$userId';

      final params = {
        'offset': ((page) * limit).toString(),
        'limit': limit.toString(),
        if (unreadOnly) 'unread_only': 'true',
      };

      final responseData =
          await storageService.getAll(url, params: params, callerKey: key);

      final statusCode = storageService.getStatusCode(key);
      final responseCode = storageService.getResponseCode(key);

      if (responseData == null) {
        setFailureResponse(key, null,
            statusCode: statusCode ?? 404, responseCode: 'NO_NOTIFICATIONS');
        return NotificationList(notifications: []);
      }

      // Pass the raw response to NotificationList.fromJson
      final notificationList = NotificationList.fromJson(responseData);

      setSuccessResponse(key, notificationList,
          statusCode: statusCode ?? 200,
          responseCode: responseCode ?? 'SUCCESS');

      return notificationList;
    } catch (e, stacktrace) {
      developer.log('Error getting notifications for user $userId: $e',
          name: 'NotificationImpl');
      setFailureResponse(key, e.toString(),
          statusCode: 500, responseCode: 'ERROR_GETTING_NOTIFICATIONS');
      return NotificationList(notifications: []);
    }
  }

  @override
  Future<VerdeliaNotification?> getNotificationById(
    int notificationId, {
    String? callerKey,
  }) async {
    final key = callerKey ??
        _getCallerKey('getNotificationById', id: notificationId.toString());

    try {
      final storageService = AppLocator.get<StorageService>();

      // Using the root: GET /{notification_id}
      final url =
          '${AppConstants.apiBaseUrl}${AppConstants.getNotificationByIdEndpoint}/$notificationId';
      developer.log('Getting notification $notificationId from: $url',
          name: 'NotificationImpl');

      final responseData = await storageService
          .get(url, notificationId.toString(), callerKey: key);

      final statusCode = storageService.getStatusCode(key);
      final responseCode = storageService.getResponseCode(key);

      if (responseData == null) {
        developer.log('Notification $notificationId not found',
            name: 'NotificationImpl');
        setFailureResponse(key, null,
            statusCode: statusCode ?? 404,
            responseCode: 'NOTIFICATION_NOT_FOUND');
        return null;
      }

      final notification =
          VerdeliaNotification.fromJson(responseData as Map<String, dynamic>);

      developer.log('Found notification $notificationId',
          name: 'NotificationImpl');
      setSuccessResponse(key, notification,
          statusCode: statusCode ?? 200,
          responseCode: responseCode ?? 'SUCCESS');

      return notification;
    } catch (e, stacktrace) {
      developer.log('Error getting notification $notificationId: $e',
          name: 'NotificationImpl');
      developer.log('Stacktrace: $stacktrace', name: 'NotificationImpl');
      setFailureResponse(key, e.toString(),
          statusCode: 500, responseCode: 'ERROR_GETTING_NOTIFICATION');
      return null;
    }
  }

  @override
  Future<VerdeliaNotification?> markAsRead(
    int notificationId, {
    String? callerKey,
  }) async {
    final key =
        callerKey ?? _getCallerKey('markAsRead', id: notificationId.toString());

    try {
      final storageService = AppLocator.get<StorageService>();

      // Using the root: PUT /{notification_id}/read
      final url =
          '${AppConstants.apiBaseUrl}${AppConstants.readNotificationEndpoint}';
      developer.log('Marking notification $notificationId as read at: $url',
          name: 'NotificationImpl');

      final result = await storageService.update(
        url,
        notificationId.toString(),
        {},
        {},
        callerKey: key,
      );

      final statusCode = storageService.getStatusCode(key);
      final responseCode = storageService.getResponseCode(key);

      developer.log(
          'Mark as read result for notification $notificationId: $result',
          name: 'NotificationImpl');

      if (result == null) {
        developer.log(
            'Failed to mark notification $notificationId as read: null response',
            name: 'NotificationImpl');
        setFailureResponse(key, null,
            statusCode: statusCode ?? 500, responseCode: 'MARK_READ_FAILED');
        return null;
      }

      VerdeliaNotification? notification;

      if (result is Map<String, dynamic>) {
        notification = VerdeliaNotification.fromJson(result);
      }

      if (notification != null) {
        setSuccessResponse(key, notification,
            statusCode: statusCode ?? 200,
            responseCode: responseCode ?? 'SUCCESS');
        developer.log(
            'Notification $notificationId marked as read successfully',
            name: 'NotificationImpl');
      } else {
        setFailureResponse(key, result,
            statusCode: statusCode ?? 500, responseCode: 'INVALID_RESPONSE');
      }

      return notification;
    } catch (e, stacktrace) {
      developer.log('Error marking notification $notificationId as read: $e',
          name: 'NotificationImpl');
      developer.log('Stacktrace: $stacktrace', name: 'NotificationImpl');
      setFailureResponse(key, e.toString(),
          statusCode: 500, responseCode: 'ERROR_MARKING_READ');
      return null;
    }
  }

  @override
  Future<int> markAllAsRead(
    int userId, {
    String? callerKey,
  }) async {
    final key =
        callerKey ?? _getCallerKey('markAllAsRead', id: userId.toString());

    try {
      final storageService = AppLocator.get<StorageService>();

      // Using the root: PUT /user/{user_ref}/read-all
      final url =
          '${AppConstants.apiBaseUrl}${AppConstants.readAllNotificationsEndpoint}';
      developer.log(
          'Marking all notifications as read for user $userId at: $url',
          name: 'NotificationImpl');

      final result = await storageService.update(
        url,
        userId.toString(),
        {},
        {},
        callerKey: key,
      );

      final statusCode = storageService.getStatusCode(key);
      final responseCode = storageService.getResponseCode(key);

      developer.log('Mark all as read result for user $userId: $result',
          name: 'NotificationImpl');

      if (result == null) {
        developer.log(
            'Failed to mark all notifications as read for user $userId: null response',
            name: 'NotificationImpl');
        setFailureResponse(key, null,
            statusCode: statusCode ?? 500,
            responseCode: 'MARK_ALL_READ_FAILED');
        return 0;
      }

      int markedCount = 0;

      if (result is Map<String, dynamic>) {
        markedCount = result['marked_count'] ?? result['updated_count'] ?? 0;
      } else if (result is int) {
        markedCount = result;
      }

      setSuccessResponse(key, markedCount,
          statusCode: statusCode ?? 200,
          responseCode: responseCode ?? 'SUCCESS');
      developer.log(
          'Marked $markedCount notifications as read for user $userId',
          name: 'NotificationImpl');

      return markedCount;
    } catch (e, stacktrace) {
      developer.log(
          'Error marking all notifications as read for user $userId: $e',
          name: 'NotificationImpl');
      developer.log('Stacktrace: $stacktrace', name: 'NotificationImpl');
      setFailureResponse(key, e.toString(),
          statusCode: 500, responseCode: 'ERROR_MARKING_ALL_READ');
      return 0;
    }
  }

  @override
  Future<bool> deleteNotification(
    int notificationId, {
    String? callerKey,
  }) async {
    final key = callerKey ??
        _getCallerKey('deleteNotification', id: notificationId.toString());

    try {
      final storageService = AppLocator.get<StorageService>();

      // Using the root: DELETE /{notification_id}
      final url =
          '${AppConstants.apiBaseUrl}${AppConstants.deleteNotificationEndpoint}/$notificationId';
      developer.log('Deleting notification $notificationId at: $url',
          name: 'NotificationImpl');

      final result = await storageService.delete(
        url,
        notificationId.toString(),
        callerKey: key,
      );

      final statusCode = storageService.getStatusCode(key);
      final responseCode = storageService.getResponseCode(key);

      developer.log('Delete notification result for $notificationId: $result',
          name: 'NotificationImpl');

      final isSuccess = result == 200 || result == 204;

      if (isSuccess) {
        setSuccessResponse(key, true,
            statusCode: result, responseCode: 'SUCCESS');
        developer.log('Notification $notificationId deleted successfully',
            name: 'NotificationImpl');
      } else {
        setFailureResponse(key, false,
            statusCode: result, responseCode: 'DELETE_FAILED');
        developer.log('Failed to delete notification $notificationId',
            name: 'NotificationImpl');
      }

      return isSuccess;
    } catch (e, stacktrace) {
      developer.log('Error deleting notification $notificationId: $e',
          name: 'NotificationImpl');
      developer.log('Stacktrace: $stacktrace', name: 'NotificationImpl');
      setFailureResponse(key, e.toString(),
          statusCode: 500, responseCode: 'ERROR_DELETING_NOTIFICATION');
      return false;
    }
  }

  @override
  Future<int> deleteAllNotifications(
    int userId, {
    String? callerKey,
  }) async {
    final key = callerKey ??
        _getCallerKey('deleteAllNotifications', id: userId.toString());

    try {
      final storageService = AppLocator.get<StorageService>();

      // Using the root: DELETE /user/{user_ref}/all
      final url =
          '${AppConstants.apiBaseUrl}${AppConstants.deleteAllNotificationsEndpoint}/$userId/all';
      developer.log('Deleting all notifications for user $userId at: $url',
          name: 'NotificationImpl');

      final result = await storageService.delete(
        url,
        userId.toString(),
        callerKey: key,
      );

      final statusCode = storageService.getStatusCode(key);
      final responseCode = storageService.getResponseCode(key);

      developer.log('Delete all notifications result for user $userId: $result',
          name: 'NotificationImpl');

      int deletedCount = 0;

      if (result is Map<String, dynamic>) {
        deletedCount = result ?? 0;
      } else if (result is int) {
        deletedCount = result;
      }

      if (deletedCount > 0) {
        setSuccessResponse(key, deletedCount,
            statusCode: statusCode ?? 200, responseCode: 'SUCCESS');
        developer.log('Deleted $deletedCount notifications for user $userId',
            name: 'NotificationImpl');
      } else {
        setFailureResponse(key, deletedCount,
            statusCode: statusCode ?? 404,
            responseCode: 'NO_NOTIFICATIONS_TO_DELETE');
        developer.log('No notifications to delete for user $userId',
            name: 'NotificationImpl');
      }

      return deletedCount;
    } catch (e, stacktrace) {
      developer.log('Error deleting all notifications for user $userId: $e',
          name: 'NotificationImpl');
      developer.log('Stacktrace: $stacktrace', name: 'NotificationImpl');
      setFailureResponse(key, e.toString(),
          statusCode: 500, responseCode: 'ERROR_DELETING_ALL_NOTIFICATIONS');
      return 0;
    }
  }

  @override
  Future<int> getUnreadCount(
    int userId, {
    String? callerKey,
  }) async {
    final key =
        callerKey ?? _getCallerKey('getUnreadCount', id: userId.toString());

    try {
      final storageService = AppLocator.get<StorageService>();

      // Using the root: GET /user/{user_ref}/unread-count
      final url =
          '${AppConstants.apiBaseUrl}${AppConstants.unreadCountEndpoint}/$userId/unread-count';
      developer.log('Getting unread count for user $userId at: $url',
          name: 'NotificationImpl');

      final responseData = await storageService.getAll(url, callerKey: key);

      final statusCode = storageService.getStatusCode(key);
      final responseCode = storageService.getResponseCode(key);

      if (responseData == null) {
        developer.log('No response for unread count for user $userId',
            name: 'NotificationImpl');
        setFailureResponse(key, null,
            statusCode: statusCode ?? 404, responseCode: 'NO_COUNT');
        return 0;
      }

      int unreadCount = 0;

      if (responseData is Map<String, dynamic>) {
        unreadCount =
            responseData['unread_count'] ?? responseData['count'] ?? 0;
      } else if (responseData is int) {
        unreadCount = responseData;
      }

      developer.log('User $userId has $unreadCount unread notifications',
          name: 'NotificationImpl');
      setSuccessResponse(key, unreadCount,
          statusCode: statusCode ?? 200,
          responseCode: responseCode ?? 'SUCCESS');

      return unreadCount;
    } catch (e, stacktrace) {
      developer.log('Error getting unread count for user $userId: $e',
          name: 'NotificationImpl');
      developer.log('Stacktrace: $stacktrace', name: 'NotificationImpl');
      setFailureResponse(key, e.toString(),
          statusCode: 500, responseCode: 'ERROR_GETTING_UNREAD_COUNT');
      return 0;
    }
  }

  @override
  Future<VerdeliaNotification?> sendInvitation(
    int userId,
    String roleName,
    String invitedBy, {
    String? callerKey,
  }) async {
    final key =
        callerKey ?? _getCallerKey('sendInvitation', id: userId.toString());

    try {
      final storageService = AppLocator.get<StorageService>();

      // Using the root: POST /invitation/send
      final url =
          '${AppConstants.apiBaseUrl}${AppConstants.sendInvitationEndpoint}';

      final body = {
        'user_ref': userId,
        'role_name': roleName,
        'invited_by': invitedBy,
      };

      developer.log('Sending invitation to user $userId with role $roleName',
          name: 'NotificationImpl');

      final result = await storageService.insert(
        url,
        body,
        callerKey: key,
      );

      final statusCode = storageService.getStatusCode(key);
      final responseCode = storageService.getResponseCode(key);

      if (result == null) {
        developer.log('Failed to send invitation to user $userId',
            name: 'NotificationImpl');
        setFailureResponse(key, null,
            statusCode: statusCode ?? 500,
            responseCode: 'SEND_INVITATION_FAILED');
        return null;
      }

      VerdeliaNotification? notification;

      if (result is Map<String, dynamic>) {
        notification = VerdeliaNotification.fromJson(result);
      }

      if (notification != null) {
        setSuccessResponse(key, notification,
            statusCode: statusCode ?? 200,
            responseCode: responseCode ?? 'SUCCESS');
        developer.log('Invitation sent to user $userId successfully',
            name: 'NotificationImpl');
      }

      return notification;
    } catch (e, stacktrace) {
      developer.log('Error sending invitation to user $userId: $e',
          name: 'NotificationImpl');
      developer.log('Stacktrace: $stacktrace', name: 'NotificationImpl');
      setFailureResponse(key, e.toString(),
          statusCode: 500, responseCode: 'ERROR_SENDING_INVITATION');
      return null;
    }
  }

  @override
  Future<List<VerdeliaNotification>> bulkCreateNotifications(
    List<Map<String, dynamic>> notificationsData, {
    String? callerKey,
  }) async {
    final key = callerKey ??
        _getCallerKey('bulkCreateNotifications',
            suffix: notificationsData.length.toString());

    try {
      final storageService = AppLocator.get<StorageService>();

      // Using the root: POST /bulk/create
      final url =
          '${AppConstants.apiBaseUrl}${AppConstants.bulkCreateNotificationsEndpoint}';

      final body = {'notifications': notificationsData};

      developer.log('Bulk creating ${notificationsData.length} notifications',
          name: 'NotificationImpl');

      final result = await storageService.insert(
        url,
        body,
        callerKey: key,
      );

      final statusCode = storageService.getStatusCode(key);
      final responseCode = storageService.getResponseCode(key);

      if (result == null) {
        developer.log('Failed to bulk create notifications',
            name: 'NotificationImpl');
        setFailureResponse(key, null,
            statusCode: statusCode ?? 500, responseCode: 'BULK_CREATE_FAILED');
        return [];
      }

      List<VerdeliaNotification> notifications = [];

      if (result is List) {
        notifications = result
            .map((item) =>
                VerdeliaNotification.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (result is Map<String, dynamic> &&
          result.containsKey('notifications')) {
        notifications = (result['notifications'] as List)
            .map((item) =>
                VerdeliaNotification.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      setSuccessResponse(key, notifications,
          statusCode: statusCode ?? 200,
          responseCode: responseCode ?? 'SUCCESS');
      developer.log(
          'Successfully created ${notifications.length} notifications',
          name: 'NotificationImpl');

      return notifications;
    } catch (e, stacktrace) {
      developer.log('Error bulk creating notifications: $e',
          name: 'NotificationImpl');
      developer.log('Stacktrace: $stacktrace', name: 'NotificationImpl');
      setFailureResponse(key, e.toString(),
          statusCode: 500, responseCode: 'ERROR_BULK_CREATING_NOTIFICATIONS');
      return [];
    }
  }
}
