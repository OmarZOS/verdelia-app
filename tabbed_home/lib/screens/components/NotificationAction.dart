// import 'dart:developer';

// import 'package:app_constants/app_routes.dart';
// import 'package:flutter/material.dart';
// import 'package:app_constants/app_constants.dart';
// import 'package:verdelia_core/app/Notifications/Notifications/RoleInvitation.dart';
// import 'package:event/notification_notifier.dart';
// import 'package:event/personnel_notifier.dart';
// import 'package:ui/Services/ResponseHandler.dart';
// import 'package:provider/provider.dart';

enum ActionType {
  view,
  accept,
  reject,
  reply,
  dismiss,
  archive,
  download,
}

extension ActionTypeExt on ActionType {
  String get value => name;
  static ActionType fromString(String type) {
    return ActionType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => ActionType.view,
    );
  }
}

class NotificationAction {
  final ActionType type;
  final String label;
  final int notificationId;
  final Map<String, dynamic> metadata;

  const NotificationAction({
    required this.type,
    required this.label,
    required this.notificationId,
    this.metadata = const {},
  });

  // Add a helper to safely get int values from metadata
  int getIntMetadata(String key, {int defaultValue = 0}) {
    final value = metadata[key];
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    if (value is double) return value.toInt();
    return defaultValue;
  }

  // Add a helper to safely get String values from metadata
  String getStringMetadata(String key, {String defaultValue = ''}) {
    final value = metadata[key];
    if (value is String) return value;
    if (value is int) return value.toString();
    if (value is double) return value.toString();
    return defaultValue;
  }

  factory NotificationAction.fromJson(Map<String, dynamic> json) {
    return NotificationAction(
      type: ActionTypeExt.fromString(json['type']),
      label: json['label'] ?? '',
      notificationId: json['notificationId'],
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      'label': label,
      'notificationId': notificationId,
      'metadata': metadata,
    };
  }

  factory NotificationAction.view(int id,
          {Map<String, dynamic> metadata = const {}}) =>
      NotificationAction(
          type: ActionType.view,
          label: "View",
          notificationId: id,
          metadata: metadata);

  factory NotificationAction.accept(int id,
          {Map<String, dynamic> metadata = const {}}) =>
      NotificationAction(
          type: ActionType.accept,
          label: "Accept",
          notificationId: id,
          metadata: metadata);

  factory NotificationAction.reject(int id,
          {Map<String, dynamic> metadata = const {}}) =>
      NotificationAction(
          type: ActionType.reject,
          label: "Reject",
          notificationId: id,
          metadata: metadata);

  factory NotificationAction.reply(int id,
          {String? text, Map<String, dynamic> metadata = const {}}) =>
      NotificationAction(
        type: ActionType.reply,
        label: "Reply",
        notificationId: id,
        metadata: {...metadata, if (text != null) 'text': text},
      );

  factory NotificationAction.dismiss(int id,
          {Map<String, dynamic> metadata = const {}}) =>
      NotificationAction(
          type: ActionType.dismiss,
          label: "Dismiss",
          notificationId: id,
          metadata: metadata);

  factory NotificationAction.archive(int id,
          {Map<String, dynamic> metadata = const {}}) =>
      NotificationAction(
          type: ActionType.archive,
          label: "Archive",
          notificationId: id,
          metadata: metadata);

  factory NotificationAction.download(int id,
          {String? url, Map<String, dynamic> metadata = const {}}) =>
      NotificationAction(
        type: ActionType.download,
        label: "Download",
        notificationId: id,
        metadata: {...metadata, if (url != null) 'url': url},
      );

  @override
  String toString() =>
      'NotificationAction(type: $type, label: $label, id: $notificationId)';
}

// class NotificationActionResult {
//   final bool isSuccess;
//   final int? statusCode;
//   final String? responseCode;
//   final String? message;

//   const NotificationActionResult({
//     required this.isSuccess,
//     this.statusCode,
//     this.responseCode,
//     this.message,
//   });

//   factory NotificationActionResult.success(
//       {int? statusCode, String? responseCode, String? message}) {
//     return NotificationActionResult(
//       isSuccess: true,
//       statusCode: statusCode ?? 200,
//       responseCode: responseCode ?? 'SUCCESS',
//       message: message ?? 'Action completed',
//     );
//   }

//   factory NotificationActionResult.failure(
//       {int? statusCode, String? responseCode, String? message}) {
//     return NotificationActionResult(
//       isSuccess: false,
//       statusCode: statusCode ?? 500,
//       responseCode: responseCode ?? 'FAILED',
//       message: message ?? 'Action failed',
//     );
//   }
// }

// class NotificationActionHandler {
//   static String _generateKey(String actionType, int notificationId) {
//     return 'notification_${actionType}_${notificationId}_${DateTime.now().millisecondsSinceEpoch}';
//   }

//   static Future<NotificationActionResult> handle(
//     BuildContext context,
//     NotificationAction action, {
//     String? callerKey,
//   }) async {
//     final key =
//         callerKey ?? _generateKey(action.type.value, action.notificationId);

//     switch (action.type) {
//       case ActionType.view:
//         return await _handleView(context, action, key); // Add 'await'
//       case ActionType.accept:
//         return await _handleAccept(context, action, key);
//       case ActionType.reject:
//         return await _handleReject(context, action, key);
//       case ActionType.reply:
//         return await _handleReply(context, action, key);
//       case ActionType.dismiss:
//         return await _handleDismiss(context, action, key);
//       case ActionType.archive:
//         return await _handleArchive(context, action, key);
//       case ActionType.download:
//         return await _handleDownload(context, action, key);
//     }
//   }

//   static Future<NotificationActionResult> _handleView(
//     BuildContext context,
//     NotificationAction action,
//     String key,
//   ) async {
//     try {
//       // Use safe getters to avoid type errors
//       final orgId = action.getIntMetadata('organization_id');
//       final providerId = action.getIntMetadata('provider_id');
//       final supplierName = action.getStringMetadata('supplier_name');

//       await Navigator.pushNamed(
//         context,
//         AppRoutes.supplierManage,
//         arguments: {
//           "supplierName": supplierName,
//           "orgId": orgId,
//           "supplierId": providerId,
//         },
//       );
//       return NotificationActionResult.success(responseCode: 'VIEW_SUCCESS');
//     } catch (e) {
//       return NotificationActionResult.failure(
//         responseCode: 'VIEW_ERROR',
//         message: e.toString(),
//       );
//     }
//   }

//   static Future<NotificationActionResult> _handleAccept(
//     BuildContext context,
//     NotificationAction action,
//     String callerKey,
//   ) async {
//     try {
//       final personnelNotifier = context.read<PersonnelNotifier>();
//       final notificationNotifier = context.read<NotificationNotifier>();

//       final success = await personnelNotifier.answerInvitation(
//         ruleId: action.metadata['rule_id'],
//         answer: 0,
//         callerKey: callerKey,
//       );

//       final response = personnelNotifier.getResponse(callerKey);

//       if (success) {
//         await notificationNotifier.markAsRead(action.notificationId);
//         ResponseHandler.handleResponse(
//           context: context,
//           statusCode: response?.statusCode ?? 200,
//           responseCode: response?.responseCode ?? 'INVITATION_ACCEPTED',
//           finalMessage: response?.message ?? 'Invitation accepted',
//         );
//         return NotificationActionResult.success(
//           statusCode: response?.statusCode,
//           responseCode: response?.responseCode,
//           message: response?.message,
//         );
//       } else {
//         // Use the actual error from the response
//         ResponseHandler.handleResponse(
//           context: context,
//           statusCode: response?.statusCode ?? 500,
//           responseCode: response?.responseCode ?? 'ACCEPT_FAILED',
//           finalMessage: response?.message ?? 'Failed to accept invitation',
//         );
//         return NotificationActionResult.failure(
//           statusCode: response?.statusCode,
//           responseCode: response?.responseCode,
//           message: response?.message,
//         );
//       }
//     } catch (e) {
//       ResponseHandler.handleResponse(
//         context: context,
//         statusCode: 500,
//         responseCode: 'ACCEPT_ERROR',
//         finalMessage: 'Error: $e',
//       );
//       return NotificationActionResult.failure(
//         responseCode: 'ACCEPT_ERROR',
//         message: e.toString(),
//       );
//     }
//   }

//   static Future<NotificationActionResult> _handleReject(
//     BuildContext context,
//     NotificationAction action,
//     String callerKey,
//   ) async {
//     try {
//       final personnelNotifier = context.read<PersonnelNotifier>();
//       final notificationNotifier = context.read<NotificationNotifier>();

//       final success = await personnelNotifier.answerInvitation(
//         ruleId: action.metadata['rule_id'],
//         answer: 1,
//         callerKey: callerKey,
//       );

//       final response = personnelNotifier.getResponse(callerKey);

//       if (success) {
//         await notificationNotifier.markAsRead(action.notificationId);
//         ResponseHandler.handleResponse(
//           context: context,
//           statusCode: response?.statusCode ?? 200,
//           responseCode: response?.responseCode ?? 'INVITATION_REJECTED',
//           finalMessage: response?.message ?? 'Invitation rejected',
//         );
//         return NotificationActionResult.success(
//           statusCode: response?.statusCode,
//           responseCode: response?.responseCode,
//           message: response?.message,
//         );
//       } else {
//         // Use the actual error from the response
//         ResponseHandler.handleResponse(
//           context: context,
//           statusCode: response?.statusCode ?? 500,
//           responseCode: response?.responseCode ?? 'REJECT_FAILED',
//           finalMessage: response?.message ?? 'Failed to reject invitation',
//         );
//         return NotificationActionResult.failure(
//           statusCode: response?.statusCode,
//           responseCode: response?.responseCode,
//           message: response?.message,
//         );
//       }
//     } catch (e) {
//       ResponseHandler.handleResponse(
//         context: context,
//         statusCode: 500,
//         responseCode: 'REJECT_ERROR',
//         finalMessage: 'Error: $e',
//       );
//       return NotificationActionResult.failure(
//         responseCode: 'REJECT_ERROR',
//         message: e.toString(),
//       );
//     }
//   }

//   static Future<NotificationActionResult> _handleReply(
//       BuildContext context, NotificationAction action, String key) async {
//     final replyText = await showDialog<String>(
//       context: context,
//       builder: (context) => const ReplyDialog(),
//     );

//     if (replyText != null && replyText.isNotEmpty) {
//       // TODO: Call API
//       ResponseHandler.handleResponse(
//         context: context,
//         statusCode: 200,
//         responseCode: 'REPLY_SENT',
//         finalMessage: 'Reply sent',
//       );
//       return NotificationActionResult.success(responseCode: 'REPLY_SENT');
//     }

//     return NotificationActionResult.failure(
//         responseCode: 'REPLY_CANCELLED', message: 'Cancelled');
//   }

//   static Future<NotificationActionResult> _handleDismiss(
//       BuildContext context, NotificationAction action, String key) async {
//     try {
//       final notifier = context.read<NotificationNotifier>();
//       await notifier.markAsRead(action.notificationId, callerKey: key);

//       final response = notifier.getResponse(key);
//       ResponseHandler.handleResponse(
//         context: context,
//         statusCode: response?.statusCode ?? 200,
//         responseCode: response?.responseCode ?? 'DISMISSED',
//         finalMessage: 'Dismissed',
//         // isSilent: true,
//       );
//       return NotificationActionResult.success(responseCode: 'DISMISSED');
//     } catch (e) {
//       return NotificationActionResult.failure(
//           responseCode: 'DISMISS_ERROR', message: e.toString());
//     }
//   }

//   static Future<NotificationActionResult> _handleArchive(
//       BuildContext context, NotificationAction action, String key) async {
//     try {
//       final notifier = context.read<NotificationNotifier>();
//       await notifier.deleteNotification(action.notificationId, callerKey: key);

//       final response = notifier.getResponse(key);
//       ResponseHandler.handleResponse(
//         context: context,
//         statusCode: response?.statusCode ?? 200,
//         responseCode: response?.responseCode ?? 'ARCHIVED',
//         finalMessage: 'Archived',
//         // isSilent: true,
//       );
//       return NotificationActionResult.success(responseCode: 'ARCHIVED');
//     } catch (e) {
//       ResponseHandler.handleResponse(
//         context: context,
//         statusCode: 500,
//         responseCode: 'ARCHIVE_ERROR',
//         finalMessage: 'Error: $e',
//       );
//       return NotificationActionResult.failure(
//           responseCode: 'ARCHIVE_ERROR', message: e.toString());
//     }
//   }

//   static Future<NotificationActionResult> _handleDownload(
//       BuildContext context, NotificationAction action, String key) async {
//     final url = action.metadata['url'];
//     if (url == null) {
//       ResponseHandler.handleResponse(
//         context: context,
//         statusCode: 400,
//         responseCode: 'NO_URL',
//         finalMessage: 'No download URL',
//       );
//       return NotificationActionResult.failure(responseCode: 'NO_URL');
//     }

//     // TODO: Implement download
//     ResponseHandler.handleResponse(
//       context: context,
//       statusCode: 200,
//       responseCode: 'DOWNLOAD_STARTED',
//       finalMessage: 'Download started',
//     );
//     return NotificationActionResult.success(responseCode: 'DOWNLOAD_STARTED');
//   }
// }

// class ReplyDialog extends StatefulWidget {
//   const ReplyDialog();

//   @override
//   State<ReplyDialog> createState() => ReplyDialogState();
// }

// class ReplyDialogState extends State<ReplyDialog> {
//   final TextEditingController textController = TextEditingController();

//   @override
//   void dispose() {
//     textController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: const Text('Reply'),
//       content: TextField(
//         controller: textController,
//         autofocus: true,
//         decoration: const InputDecoration(hintText: 'Type your reply...'),
//         maxLines: 3,
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context, null),
//           child: const Text('Cancel'),
//         ),
//         ElevatedButton(
//           onPressed: () => Navigator.pop(context, textController.text),
//           child: const Text('Send'),
//         ),
//       ],
//     );
//   }
// }
