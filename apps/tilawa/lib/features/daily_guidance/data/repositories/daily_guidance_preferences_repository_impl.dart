import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/daily_guidance_enums.dart';
import '../../domain/entities/daily_guidance_preferences.dart';
import '../../domain/repositories/daily_guidance_preferences_repository.dart';

@LazySingleton(as: DailyGuidancePreferencesRepository)
class DailyGuidancePreferencesRepositoryImpl
    implements DailyGuidancePreferencesRepository {
  final SharedPreferencesAsync _prefs;

  static const _prefix = 'daily_guidance_';
  static const _keyEnabled = '${_prefix}enabled';
  static const _keyTimeHour = '${_prefix}time_hour';
  static const _keyTimeMinute = '${_prefix}time_minute';
  static const _keyWeekdays = '${_prefix}weekdays';
  static const _keyContentMode = '${_prefix}content_mode';
  static const _keyTopics = '${_prefix}topics';
  static const _keyLocale = '${_prefix}locale';
  static const _keyPausedUntil = '${_prefix}paused_until';
  static const _keyTimezone = '${_prefix}timezone';
  static const _keyUpdatedAt = '${_prefix}updated_at';

  DailyGuidancePreferencesRepositoryImpl(this._prefs);

  @override
  Future<DailyGuidancePreferences> getPreferences() async {
    final enabled = await _prefs.getBool(_keyEnabled) ?? false;
    final hour = await _prefs.getInt(_keyTimeHour) ?? 7;
    final minute = await _prefs.getInt(_keyTimeMinute) ?? 0;

    final weekdaysStr = await _prefs.getString(_keyWeekdays);
    Set<int> weekdays = const {1, 2, 3, 4, 5, 6, 7};
    if (weekdaysStr != null && weekdaysStr.isNotEmpty) {
      weekdays = weekdaysStr.split(',').map(int.parse).toSet();
    }

    final modeStr = await _prefs.getString(_keyContentMode);
    var mode = DailyGuidanceContentMode.mixed;
    if (modeStr != null) {
      mode = DailyGuidanceContentMode.values.firstWhere(
        (e) => e.name == modeStr,
        orElse: () => DailyGuidanceContentMode.mixed,
      );
    }

    final topicsStr = await _prefs.getString(_keyTopics);
    List<String> topics = [];
    if (topicsStr != null) {
      topics = List<String>.from(jsonDecode(topicsStr) as List<dynamic>);
    }

    final locale = await _prefs.getString(_keyLocale);

    final pausedStr = await _prefs.getString(_keyPausedUntil);
    DateTime? pausedUntil;
    if (pausedStr != null) {
      pausedUntil = DateTime.tryParse(pausedStr);
    }

    final timezone = await _prefs.getString(_keyTimezone);

    final updatedStr = await _prefs.getString(_keyUpdatedAt);
    DateTime updatedAt = DateTime.now();
    if (updatedStr != null) {
      updatedAt = DateTime.tryParse(updatedStr) ?? DateTime.now();
    }

    return DailyGuidancePreferences(
      enabled: enabled,
      preferredLocalTime: TimeOfDay(hour: hour, minute: minute),
      enabledWeekdays: weekdays,
      contentMode: mode,
      preferredTopics: topics,
      preferredLocale: locale,
      pausedUntil: pausedUntil,
      lastTimezone: timezone,
      updatedAt: updatedAt,
    );
  }

  @override
  Future<void> savePreferences(DailyGuidancePreferences prefs) async {
    await _prefs.setBool(_keyEnabled, prefs.enabled);
    await _prefs.setInt(_keyTimeHour, prefs.preferredLocalTime.hour);
    await _prefs.setInt(_keyTimeMinute, prefs.preferredLocalTime.minute);
    await _prefs.setString(_keyWeekdays, prefs.enabledWeekdays.join(','));
    await _prefs.setString(_keyContentMode, prefs.contentMode.name);
    await _prefs.setString(_keyTopics, jsonEncode(prefs.preferredTopics));

    if (prefs.preferredLocale != null) {
      await _prefs.setString(_keyLocale, prefs.preferredLocale!);
    } else {
      await _prefs.remove(_keyLocale);
    }

    if (prefs.pausedUntil != null) {
      await _prefs.setString(
        _keyPausedUntil,
        prefs.pausedUntil!.toIso8601String(),
      );
    } else {
      await _prefs.remove(_keyPausedUntil);
    }

    if (prefs.lastTimezone != null) {
      await _prefs.setString(_keyTimezone, prefs.lastTimezone!);
    } else {
      await _prefs.remove(_keyTimezone);
    }

    await _prefs.setString(_keyUpdatedAt, prefs.updatedAt.toIso8601String());
  }

  @override
  Future<void> clearPreferences() async {
    await _prefs.remove(_keyEnabled);
    await _prefs.remove(_keyTimeHour);
    await _prefs.remove(_keyTimeMinute);
    await _prefs.remove(_keyWeekdays);
    await _prefs.remove(_keyContentMode);
    await _prefs.remove(_keyTopics);
    await _prefs.remove(_keyLocale);
    await _prefs.remove(_keyPausedUntil);
    await _prefs.remove(_keyTimezone);
    await _prefs.remove(_keyUpdatedAt);
  }
}
