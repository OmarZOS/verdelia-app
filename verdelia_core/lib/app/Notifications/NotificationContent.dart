import 'dart:convert';

abstract class NotificationContent {
  final String type;
  final DateTime timestamp;
  final int addedBy;

  const NotificationContent({
    required this.timestamp,
    required this.type,
    required this.addedBy,
  });

  /// Convert the notification content to JSON
  Map<String, dynamic> toJson();

  /// Create a display title for the notification
  String get displayTitle;

  /// Create a display message for the notification
  String get displayMessage;

  /// Create an action text for the notification (e.g., "View", "Accept", etc.)
  String get actionText;

  /// Whether this notification requires user action
  bool get requiresAction;

  @override
  String toString() =>
      'NotificationContent(type: $type, timestamp: $timestamp)';
}
