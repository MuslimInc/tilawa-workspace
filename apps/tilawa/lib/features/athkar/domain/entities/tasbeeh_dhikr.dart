import 'package:equatable/equatable.dart';

class TasbeehDhikr extends Equatable {
  const TasbeehDhikr({
    required this.id,
    required this.text,
    required this.count,
    required this.targetCount,
    required this.targetReachedNotified,
    required this.createdAt,
    required this.updatedAt,
    this.reminderEnabled = false,
    this.reminderHour,
    this.reminderMinute,
  });

  final String id;
  final String text;
  final int count;
  final int targetCount;
  final bool targetReachedNotified;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool reminderEnabled;
  final int? reminderHour;
  final int? reminderMinute;

  TasbeehDhikr copyWith({
    String? id,
    String? text,
    int? count,
    int? targetCount,
    bool? targetReachedNotified,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? reminderEnabled,
    Object? reminderHour = _sentinel,
    Object? reminderMinute = _sentinel,
  }) {
    return TasbeehDhikr(
      id: id ?? this.id,
      text: text ?? this.text,
      count: count ?? this.count,
      targetCount: targetCount ?? this.targetCount,
      targetReachedNotified:
          targetReachedNotified ?? this.targetReachedNotified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderHour: reminderHour == _sentinel
          ? this.reminderHour
          : reminderHour as int?,
      reminderMinute: reminderMinute == _sentinel
          ? this.reminderMinute
          : reminderMinute as int?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    text,
    count,
    targetCount,
    targetReachedNotified,
    createdAt,
    updatedAt,
    reminderEnabled,
    reminderHour,
    reminderMinute,
  ];
}

const Object _sentinel = Object();
