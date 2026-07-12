import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/khatma_plan.dart';

abstract interface class KhatmaPlanLocalDataSource {
  Future<KhatmaPlan?> getActivePlan();

  Future<void> saveActivePlan(KhatmaPlan plan);

  Future<void> clearActivePlan();
}

final class SharedPreferencesKhatmaPlanLocalDataSource
    implements KhatmaPlanLocalDataSource {
  SharedPreferencesKhatmaPlanLocalDataSource(this._prefs);

  static const String _activePlanKey = 'smart_khatma.active_plan.v1';

  final SharedPreferencesAsync _prefs;

  @override
  Future<KhatmaPlan?> getActivePlan() async {
    final String? raw = await _prefs.getString(_activePlanKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      return _planFromJson(jsonDecode(raw) as Map<String, Object?>);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    } on ArgumentError {
      return null;
    }
  }

  @override
  Future<void> saveActivePlan(KhatmaPlan plan) {
    return _prefs.setString(_activePlanKey, jsonEncode(_planToJson(plan)));
  }

  @override
  Future<void> clearActivePlan() {
    return _prefs.remove(_activePlanKey);
  }

  Map<String, Object?> _planToJson(KhatmaPlan plan) {
    return <String, Object?>{
      'id': plan.id,
      'created_at': plan.createdAt.toIso8601String(),
      'start_date': plan.startDate.toIso8601String(),
      'duration_days': plan.durationDays,
      'start_page': plan.startPage,
      'target_page': plan.targetPage,
      'current_page': plan.currentPage,
      'reading_style': plan.readingStyle.name,
      'preferred_minutes_per_day': plan.preferredMinutesPerDay,
      'status': plan.status.name,
      'adjustment': plan.adjustment.name,
      'progress_date': plan.progressDate?.toIso8601String(),
      'progress_start_page': plan.progressStartPage,
    };
  }

  KhatmaPlan _planFromJson(Map<String, Object?> json) {
    return KhatmaPlan(
      id: json['id']! as String,
      createdAt: DateTime.parse(json['created_at']! as String),
      startDate: DateTime.parse(json['start_date']! as String),
      durationDays: json['duration_days']! as int,
      startPage: json['start_page']! as int,
      targetPage: json['target_page']! as int,
      currentPage: json['current_page']! as int,
      readingStyle: KhatmaReadingStyle.values.byName(
        json['reading_style'] as String? ?? KhatmaReadingStyle.pages.name,
      ),
      preferredMinutesPerDay: json['preferred_minutes_per_day'] as int?,
      status: KhatmaPlanStatus.values.byName(
        json['status'] as String? ?? KhatmaPlanStatus.active.name,
      ),
      adjustment: KhatmaPlanAdjustment.values.byName(
        json['adjustment'] as String? ?? KhatmaPlanAdjustment.none.name,
      ),
      progressDate: switch (json['progress_date']) {
        final String value => DateTime.parse(value),
        _ => null,
      },
      progressStartPage: json['progress_start_page'] as int?,
    );
  }
}
