import '../../domain/constants/tasbeeh_constants.dart';
import '../../domain/entities/tasbeeh_dhikr.dart';

class TasbeehDhikrModel extends TasbeehDhikr {
  const TasbeehDhikrModel({
    required super.id,
    required super.text,
    required super.count,
    required super.targetCount,
    required super.targetReachedNotified,
    required super.createdAt,
    required super.updatedAt,
    super.reminderEnabled = false,
    super.reminderHour,
    super.reminderMinute,
  });

  factory TasbeehDhikrModel.fromEntity(TasbeehDhikr entity) {
    return TasbeehDhikrModel(
      id: entity.id,
      text: entity.text,
      count: entity.count,
      targetCount: entity.targetCount,
      targetReachedNotified: entity.targetReachedNotified,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      reminderEnabled: entity.reminderEnabled,
      reminderHour: entity.reminderHour,
      reminderMinute: entity.reminderMinute,
    );
  }

  factory TasbeehDhikrModel.fromJson(Map<String, dynamic> json) {
    return TasbeehDhikrModel(
      id: json['id'] as String,
      text: json['text'] as String,
      count: json['count'] as int,
      targetCount:
          (json['targetCount'] as int?) ?? TasbeehConstants.defaultTargetCount,
      targetReachedNotified: (json['targetReachedNotified'] as bool?) ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      reminderEnabled: (json['reminderEnabled'] as bool?) ?? false,
      reminderHour: json['reminderHour'] as int?,
      reminderMinute: json['reminderMinute'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'count': count,
      'targetCount': targetCount,
      'targetReachedNotified': targetReachedNotified,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'reminderEnabled': reminderEnabled,
      if (reminderHour != null) 'reminderHour': reminderHour,
      if (reminderMinute != null) 'reminderMinute': reminderMinute,
    };
  }

  @override
  TasbeehDhikrModel copyWith({
    String? id,
    String? text,
    int? count,
    int? targetCount,
    bool? targetReachedNotified,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? reminderEnabled,
    Object? reminderHour = _modelSentinel,
    Object? reminderMinute = _modelSentinel,
  }) {
    return TasbeehDhikrModel(
      id: id ?? this.id,
      text: text ?? this.text,
      count: count ?? this.count,
      targetCount: targetCount ?? this.targetCount,
      targetReachedNotified:
          targetReachedNotified ?? this.targetReachedNotified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderHour: reminderHour == _modelSentinel
          ? this.reminderHour
          : reminderHour as int?,
      reminderMinute: reminderMinute == _modelSentinel
          ? this.reminderMinute
          : reminderMinute as int?,
    );
  }
}

const Object _modelSentinel = Object();
