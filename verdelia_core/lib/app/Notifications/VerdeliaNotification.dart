import 'dart:convert';
import 'package:verdelia_core/app/Notifications/NotificationContent.dart';
import 'package:verdelia_core/app/Notifications/Notifications/RoleInvitation.dart';
import 'package:verdelia_core/app/Notifications/Notifications/SystemAlert.dart';
// import 'package:verdelia_core/app/Notifications/Notifications/OrderStatus.dart';
// import 'package:verdelia_core/app/Notifications/Notifications/StockAlert.dart';
// import 'package:verdelia_core/app/Notifications/Notifications/Reminder.dart';
// import 'package:verdelia_core/app/Notifications/Notifications/Promotion.dart';

class VerdeliaNotification {
  final int idNotification;
  final String notificationCode;
  final int notificationUserRef;
  final DateTime? notificationCreatedAt;
  final DateTime? notificationReadAt;
  final Map<String, dynamic> notificationParams;
  final NotificationContent? content;

  VerdeliaNotification({
    required this.idNotification,
    required this.notificationCode,
    required this.notificationUserRef,
    this.notificationCreatedAt,
    this.notificationReadAt,
    required this.notificationParams,
    this.content,
  });

  factory VerdeliaNotification.fromJson(Map<String, dynamic> json) {
    // Parse notification_params - handle both String and Map cases
    Map<String, dynamic> paramsMap;

    if (json['notification_params'] is String) {
      final paramsJson = json['notification_params'] as String? ?? '{}';
      paramsMap = jsonDecode(paramsJson) as Map<String, dynamic>? ?? {};
    } else if (json['notification_params'] is Map) {
      paramsMap = json['notification_params'] as Map<String, dynamic>? ?? {};
    } else {
      paramsMap = {};
    }

    // Create appropriate NotificationContent based on notification_code
    NotificationContent? content;
    final notificationCode = json['notification_code'] as String? ?? '';

    switch (notificationCode.toUpperCase()) {
      case 'ROLE_INVITATION':
        content = RoleInvitation.fromJson(paramsMap);
        break;
      // case 'SYSTEM_ALERT':
      //   content = SystemAlert.fromJson(paramsMap);
      //   break;
      // case 'ORDER_STATUS':
      //   content = OrderStatus.fromJson(paramsMap);
      //   break;
      // case 'STOCK_ALERT':
      //   content = StockAlert.fromJson(paramsMap);
      //   break;
      // case 'REMINDER':
      //   content = Reminder.fromJson(paramsMap);
      //   break;
      // case 'PROMOTION':
      //   content = Promotion.fromJson(paramsMap);
      //   break;
      default:
        content = null;
    }

    return VerdeliaNotification(
      idNotification: json['id_notification'] as int? ?? 0,
      notificationCode: notificationCode,
      notificationUserRef: json['notification_user_ref'] as int? ?? 0,
      notificationCreatedAt: json['notification_created_at'] != null
          ? DateTime.parse(json['notification_created_at'] as String)
          : null,
      notificationReadAt: json['notification_read_at'] != null
          ? DateTime.parse(json['notification_read_at'] as String)
          : null,
      notificationParams: paramsMap,
      content: content,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_notification': idNotification,
      'notification_code': notificationCode,
      'notification_user_ref': notificationUserRef,
      'notification_created_at': notificationCreatedAt?.toIso8601String(),
      'notification_read_at': notificationReadAt?.toIso8601String(),
      'notification_params': content?.toJson() ?? notificationParams,
    };
  }

  // Helper getters
  bool get isRead => notificationReadAt != null;
  bool get hasContent => content != null;
  bool get requiresAction => content?.requiresAction ?? false;

  // Convenience getters for different notification types
  RoleInvitation? get roleInvitation {
    if (content is RoleInvitation) {
      return content as RoleInvitation;
    }
    return null;
  }

  // SystemAlert? get systemAlert {
  //   if (content is SystemAlert) {
  //     return content as SystemAlert;
  //   }
  //   return null;
  // }

  // OrderStatus? get orderStatus {
  //   if (content is OrderStatus) {
  //     return content as OrderStatus;
  //   }
  //   return null;
  // }

  // StockAlert? get stockAlert {
  //   if (content is StockAlert) {
  //     return content as StockAlert;
  //   }
  //   return null;
  // }

  // Reminder? get reminder {
  //   if (content is Reminder) {
  //     return content as Reminder;
  //   }
  //   return null;
  // }

  // Promotion? get promotion {
  //   if (content is Promotion) {
  //     return content as Promotion;
  //   }
  //   return null;
  // }

  DateTime get effectiveDate => notificationCreatedAt ?? DateTime.now();

  @override
  String toString() {
    return 'Notification(id: $idNotification, code: $notificationCode, userRef: $notificationUserRef, read: $isRead, content: $content)';
  }

  VerdeliaNotification copyWith({
    int? idNotification,
    String? notificationCode,
    int? notificationUserRef,
    DateTime? notificationCreatedAt,
    DateTime? notificationReadAt,
    Map<String, dynamic>? notificationParams,
    NotificationContent? content,
  }) {
    return VerdeliaNotification(
      idNotification: idNotification ?? this.idNotification,
      notificationCode: notificationCode ?? this.notificationCode,
      notificationUserRef: notificationUserRef ?? this.notificationUserRef,
      notificationCreatedAt:
          notificationCreatedAt ?? this.notificationCreatedAt,
      notificationReadAt: notificationReadAt ?? this.notificationReadAt,
      notificationParams: notificationParams ?? this.notificationParams,
      content: content ?? this.content,
    );
  }

  VerdeliaNotification markAsRead() {
    return copyWith(notificationReadAt: DateTime.now());
  }

  VerdeliaNotification markAsUnread() {
    return copyWith(notificationReadAt: null);
  }

  // Action methods for role invitations
  Future<VerdeliaNotification> acceptInvitation() async {
    if (roleInvitation != null && roleInvitation!.isPending) {
      final updatedContent = roleInvitation!.markAsAccepted();
      return copyWith(content: updatedContent);
    }
    return this;
  }

  Future<VerdeliaNotification> rejectInvitation() async {
    if (roleInvitation != null && roleInvitation!.isPending) {
      final updatedContent = roleInvitation!.markAsRejected();
      return copyWith(content: updatedContent);
    }
    return this;
  }
}
