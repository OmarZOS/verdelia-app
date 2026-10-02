import 'package:event/user_change_notifier.dart';
import 'package:flutter/material.dart';
import 'package:app_constants/app_routes.dart';
import 'package:verdelia_core/app/Notifications/VerdeliaNotification.dart';
import 'package:event/notification_notifier.dart';
import 'package:event/personnel_notifier.dart';
import 'package:tabbed_home/screens/components/NotificationAction.dart';
import 'package:ui/Services/ResponseHandler.dart';
import 'package:provider/provider.dart';

class NotificationActionHandler {
  final BuildContext context;
  final NotificationNotifier notifier;

  NotificationActionHandler({
    required this.context,
    required this.notifier,
  });

  Future<void> handle(NotificationAction action) async {
    final callerKey =
        'notification_action_${action.type}_${action.notificationId}_${DateTime.now().millisecondsSinceEpoch}';

    switch (action.type) {
      case ActionType.accept:
        await _handleAccept(action, callerKey);
        break;
      case ActionType.reject:
        await _handleReject(action, callerKey);
        break;
      case ActionType.view:
        _handleView(action);
        break;
      case ActionType.dismiss:
        await _handleDismiss(action, callerKey);
        break;
      case ActionType.reply:
        await _handleReply(action, callerKey);
        break;
      case ActionType.archive:
        await _handleArchive(action, callerKey);
        break;
      case ActionType.download:
        await _handleDownload(action, callerKey);
        break;
    }
  }

  Future<void> _handleAccept(
      NotificationAction action, String callerKey) async {
    try {
      final personnelNotifier = context.read<PersonnelNotifier>();

      final success = await personnelNotifier.answerInvitation(
        ruleId: action.metadata['rule_id'],
        answer: 0,
        callerKey: callerKey,
      );

      if (success) {
        await notifier.markAsRead(action.notificationId);
        _showResponse(
            200, 'INVITATION_ACCEPTED', 'Invitation accepted successfully');
        await _refreshNotifications();
      } else {
        final response = personnelNotifier.getResponse(callerKey);
        _showResponse(
          response?.statusCode ?? 500,
          response?.responseCode ?? 'ACCEPT_FAILED',
          response?.message ?? 'Failed to accept invitation',
        );
      }
    } catch (e) {
      _showResponse(500, 'ACCEPT_ERROR', 'Error accepting invitation: $e');
    }
  }

  Future<void> _handleReject(
      NotificationAction action, String callerKey) async {
    try {
      final personnelNotifier = context.read<PersonnelNotifier>();

      final success = await personnelNotifier.answerInvitation(
        ruleId: action.metadata['rule_id'],
        answer: 1,
        callerKey: callerKey,
      );

      if (success) {
        await notifier.markAsRead(action.notificationId);
        _showResponse(200, 'INVITATION_REJECTED', 'Invitation rejected');
        await _refreshNotifications();
      } else {
        final response = personnelNotifier.getResponse(callerKey);
        _showResponse(
          response?.statusCode ?? 500,
          response?.responseCode ?? 'REJECT_FAILED',
          response?.message ?? 'Failed to reject invitation',
        );
      }
    } catch (e) {
      _showResponse(500, 'REJECT_ERROR', 'Error rejecting invitation: $e');
    }
  }

  void _handleView(NotificationAction action) {
    final orgId = action.metadata['organization_id'] ?? 0;
    final providerId = action.metadata['provider_id'] ?? 0;
    final supplierName = action.metadata['supplier_name'] ?? '';

    Navigator.pushNamed(
      context,
      AppRoutes.supplierManage,
      arguments: {
        "supplierName": supplierName,
        "orgId": orgId is int ? orgId : int.tryParse(orgId.toString()) ?? 0,
        "supplierId": providerId is int
            ? providerId
            : int.tryParse(providerId.toString()) ?? 0,
      },
    );
  }

  Future<void> _handleDismiss(
      NotificationAction action, String callerKey) async {
    try {
      await notifier.markAsRead(action.notificationId, callerKey: callerKey);
      final response = notifier.getResponse(callerKey);
      _showResponse(
        response?.statusCode ?? 200,
        response?.responseCode ?? 'DISMISSED',
        'Notification dismissed',
      );
    } catch (e) {
      _showResponse(500, 'DISMISS_ERROR', 'Error dismissing notification: $e');
    }
  }

  Future<void> _handleReply(NotificationAction action, String callerKey) async {
    final controller = TextEditingController();

    final replyText = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reply'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Type your reply...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (replyText != null && replyText.isNotEmpty) {
      // TODO: Implement reply API call
      _showResponse(200, 'REPLY_SENT', 'Reply sent successfully');
    } else if (replyText == null) {
      _showResponse(400, 'REPLY_CANCELLED', 'Reply cancelled');
    }
  }

  Future<void> _handleArchive(
      NotificationAction action, String callerKey) async {
    try {
      await notifier.deleteNotification(action.notificationId,
          callerKey: callerKey);
      final response = notifier.getResponse(callerKey);
      _showResponse(
        response?.statusCode ?? 200,
        response?.responseCode ?? 'ARCHIVED',
        'Notification archived',
      );
    } catch (e) {
      _showResponse(500, 'ARCHIVE_ERROR', 'Error archiving notification: $e');
    }
  }

  Future<void> _handleDownload(
      NotificationAction action, String callerKey) async {
    final url = action.metadata['url'];
    if (url == null) {
      _showResponse(400, 'NO_DOWNLOAD_URL', 'No download URL available');
      return;
    }

    // TODO: Implement actual download logic
    _showResponse(200, 'DOWNLOAD_STARTED', 'Download started');
  }

  void _showResponse(int statusCode, String responseCode, String message) {
    ResponseHandler.handleResponse(
      context: context,
      statusCode: statusCode,
      responseCode: responseCode,
      finalMessage: message,
    );
  }

  Future<void> _refreshNotifications() async {
    // Get current user ID from notifier or context
    // This is a simplified version - you'd need to get the actual user ID
    final userNotifier = context.read<AppUserNotifier>();
    final userId = userNotifier.appUser?.idAppUser;
    if (userId != null && userId > 0) {
      await notifier.refreshNotifications(userId);
    }
  }
}
