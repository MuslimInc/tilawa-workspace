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
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return _planFromJson(decoded);
    } on FormatException {
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
      'adjustment_date': plan.adjustmentDate?.toIso8601String(),
      'progress_date': plan.progressDate?.toIso8601String(),
      'progress_start_page': plan.progressStartPage,
    };
  }

  KhatmaPlan _planFromJson(Map<String, Object?> json) {
    final KhatmaPlan plan = KhatmaPlan(
      id: _requiredString(json, 'id'),
      createdAt: DateTime.parse(_requiredString(json, 'created_at')),
      startDate: DateTime.parse(_requiredString(json, 'start_date')),
      durationDays: _requiredInt(json, 'duration_days'),
      startPage: _requiredInt(json, 'start_page'),
      targetPage: _requiredInt(json, 'target_page'),
      currentPage: _requiredInt(json, 'current_page'),
      readingStyle: _enumByName(
        KhatmaReadingStyle.values,
        _optionalString(json, 'reading_style') ?? KhatmaReadingStyle.pages.name,
      ),
      preferredMinutesPerDay: _optionalInt(json, 'preferred_minutes_per_day'),
      status: _enumByName(
        KhatmaPlanStatus.values,
        _optionalString(json, 'status') ?? KhatmaPlanStatus.active.name,
      ),
      adjustment: _enumByName(
        KhatmaPlanAdjustment.values,
        _optionalString(json, 'adjustment') ?? KhatmaPlanAdjustment.none.name,
      ),
      adjustmentDate: _optionalDate(json, 'adjustment_date'),
      progressDate: _optionalDate(json, 'progress_date'),
      progressStartPage: _optionalInt(json, 'progress_start_page'),
    );
    if (!_isValid(plan)) {
      throw const FormatException('Invalid Smart Khatma plan');
    }
    return plan;
  }

  bool _isValid(KhatmaPlan plan) {
    final bool checkpointValid =
        (plan.progressDate == null && plan.progressStartPage == null) ||
        (plan.progressDate != null &&
            plan.progressStartPage != null &&
            plan.progressStartPage! >= plan.startPage &&
            plan.progressStartPage! <= plan.currentPage);
    return plan.id.isNotEmpty &&
        plan.durationDays > 0 &&
        plan.startPage >= KhatmaPlan.firstQuranPage &&
        plan.startPage <= plan.targetPage &&
        plan.targetPage <= KhatmaPlan.lastQuranPage &&
        plan.currentPage >= plan.startPage &&
        plan.currentPage <= plan.targetPage &&
        checkpointValid;
  }

  String _requiredString(Map<String, Object?> json, String key) {
    final Object? value = json[key];
    if (value is String && value.isNotEmpty) return value;
    throw FormatException('Invalid $key');
  }

  String? _optionalString(Map<String, Object?> json, String key) {
    final Object? value = json[key];
    if (value == null) return null;
    if (value is String) return value;
    throw FormatException('Invalid $key');
  }

  int _requiredInt(Map<String, Object?> json, String key) {
    final int? value = _optionalInt(json, key);
    if (value != null) return value;
    throw FormatException('Invalid $key');
  }

  int? _optionalInt(Map<String, Object?> json, String key) {
    final Object? value = json[key];
    if (value == null) return null;
    if (value is int) return value;
    throw FormatException('Invalid $key');
  }

  DateTime? _optionalDate(Map<String, Object?> json, String key) {
    final String? value = _optionalString(json, key);
    return value == null ? null : DateTime.parse(value);
  }

  T _enumByName<T extends Enum>(List<T> values, String name) {
    for (final T value in values) {
      if (value.name == name) return value;
    }
    throw FormatException('Unknown enum value: $name');
  }
}
