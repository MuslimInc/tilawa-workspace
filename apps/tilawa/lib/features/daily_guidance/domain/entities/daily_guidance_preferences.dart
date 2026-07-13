import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'daily_guidance_enums.dart';

/// User-controlled preferences for the Daily Guidance feature.
class DailyGuidancePreferences extends Equatable {
  final bool enabled;
  final TimeOfDay preferredLocalTime;
  final Set<int> enabledWeekdays; // 1 = Monday, 7 = Sunday
  final DailyGuidanceContentMode contentMode;
  final List<String> preferredTopics;
  final String? preferredLocale;
  final DateTime? pausedUntil;
  final String? lastTimezone;
  final DateTime updatedAt;

  const DailyGuidancePreferences({
    this.enabled = false,
    this.preferredLocalTime = const TimeOfDay(hour: 7, minute: 0),
    this.enabledWeekdays = const {1, 2, 3, 4, 5, 6, 7},
    this.contentMode = DailyGuidanceContentMode.mixed,
    this.preferredTopics = const [],
    this.preferredLocale,
    this.pausedUntil,
    this.lastTimezone,
    required this.updatedAt,
  });

  DailyGuidancePreferences copyWith({
    bool? enabled,
    TimeOfDay? preferredLocalTime,
    Set<int>? enabledWeekdays,
    DailyGuidanceContentMode? contentMode,
    List<String>? preferredTopics,
    String? preferredLocale,
    DateTime? pausedUntil,
    String? lastTimezone,
    DateTime? updatedAt,
  }) {
    return DailyGuidancePreferences(
      enabled: enabled ?? this.enabled,
      preferredLocalTime: preferredLocalTime ?? this.preferredLocalTime,
      enabledWeekdays: enabledWeekdays ?? this.enabledWeekdays,
      contentMode: contentMode ?? this.contentMode,
      preferredTopics: preferredTopics ?? this.preferredTopics,
      preferredLocale: preferredLocale ?? this.preferredLocale,
      pausedUntil: pausedUntil ?? this.pausedUntil,
      lastTimezone: lastTimezone ?? this.lastTimezone,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    enabled,
    preferredLocalTime,
    enabledWeekdays,
    contentMode,
    preferredTopics,
    preferredLocale,
    pausedUntil,
    lastTimezone,
    updatedAt,
  ];
}
