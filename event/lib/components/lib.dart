import 'package:flutter/material.dart';

class FieldData {
  final dynamic value;
  final DataSource source;
  final double confidence; // 0.0 to 1.0
  final bool isEdited;
  final DateTime lastUpdated;
  final String? operationId;

  const FieldData({
    required this.value,
    required this.source,
    this.confidence = 1.0,
    this.isEdited = false,
    required this.lastUpdated,
    this.operationId,
  });

  FieldData copyWith({
    dynamic value,
    DataSource? source,
    double? confidence,
    bool? isEdited,
    DateTime? lastUpdated,
    String? operationId,
  }) {
    return FieldData(
      value: value ?? this.value,
      source: source ?? this.source,
      confidence: confidence ?? this.confidence,
      isEdited: isEdited ?? this.isEdited,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      operationId: operationId ?? this.operationId,
    );
  }

  @override
  String toString() {
    return 'FieldData(value: $value, source: $source, confidence: $confidence, edited: $isEdited)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FieldData &&
        other.value == value &&
        other.source == source &&
        other.confidence == confidence &&
        other.isEdited == isEdited &&
        other.operationId == operationId;
  }

  @override
  int get hashCode {
    return Object.hash(value, source, confidence, isEdited, operationId);
  }
}

enum DataSource {
  aiGenerated('AI Generated', Icons.auto_awesome, Colors.purple),
  databaseFetched('Database', Icons.storage, Colors.blue),
  userInput('Manual', Icons.edit, Colors.orange),
  verdeliaInput('Auto', Icons.settings_system_daydream, Colors.lightGreenAccent);

  final String displayName;
  final IconData icon;
  final Color color;

  const DataSource(this.displayName, this.icon, this.color);
}

// Extension for easy color scheme integration
extension DataSourceTheme on DataSource {
  Color getColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return switch (this) {
      DataSource.aiGenerated => scheme.tertiary,
      DataSource.databaseFetched => scheme.primary,
      DataSource.userInput => scheme.secondary,
      DataSource.verdeliaInput => scheme.primary,
    };
  }

  Color getContainerColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return switch (this) {
      DataSource.databaseFetched => scheme.primaryContainer,
      DataSource.aiGenerated => scheme.tertiaryContainer,
      DataSource.userInput => scheme.secondaryContainer,
      DataSource.verdeliaInput => scheme.primaryContainer,
    };
  }
}
