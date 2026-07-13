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

  static const String _activePlanKey = 'smart_khatma.active_plan.v2';

  final SharedPreferencesAsync _prefs;

  @override
  Future<KhatmaPlan?> getActivePlan() async {
    final String? raw = await _prefs.getString(_activePlanKey);
    if (raw == null || raw.isEmpty) return null;
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid Smart Khatma plan');
    }
    return _planFromJson(decoded);
  }

  @override
  Future<void> saveActivePlan(KhatmaPlan plan) =>
      _prefs.setString(_activePlanKey, jsonEncode(_planToJson(plan)));

  @override
  Future<void> clearActivePlan() => _prefs.remove(_activePlanKey);

  Map<String, Object?> _planToJson(KhatmaPlan plan) => <String, Object?>{
    'schema_version': 2,
    'id': plan.id,
    'created_at': plan.createdAt.toIso8601String(),
    'start_date': plan.startDate.toIso8601String(),
    'duration_days': plan.durationDays,
    'start_page': plan.startPage,
    'target_page': plan.targetPage,
    'confirmed_completed_through_page': plan.confirmedCompletedThroughPage,
    'assignment_date': plan.assignmentDate.toIso8601String(),
    'assignment_start_page': plan.assignmentStartPage,
    'assignment_end_page': plan.assignmentEndPage,
    'adjustment': plan.adjustment.name,
    'adjustment_date': plan.adjustmentDate?.toIso8601String(),
  };

  KhatmaPlan _planFromJson(Map<String, Object?> json) {
    if (_requiredInt(json, 'schema_version') != 2) {
      throw const FormatException('Unsupported Smart Khatma schema');
    }
    final plan = KhatmaPlan(
      id: _requiredString(json, 'id'),
      createdAt: DateTime.parse(_requiredString(json, 'created_at')),
      startDate: DateTime.parse(_requiredString(json, 'start_date')),
      durationDays: _requiredInt(json, 'duration_days'),
      startPage: _requiredInt(json, 'start_page'),
      targetPage: _requiredInt(json, 'target_page'),
      confirmedCompletedThroughPage: _optionalInt(
        json,
        'confirmed_completed_through_page',
      ),
      assignmentDate: DateTime.parse(
        _requiredString(json, 'assignment_date'),
      ),
      assignmentStartPage: _requiredInt(json, 'assignment_start_page'),
      assignmentEndPage: _requiredInt(json, 'assignment_end_page'),
      adjustment: KhatmaPlanAdjustment.values.byName(
        _optionalString(json, 'adjustment') ?? KhatmaPlanAdjustment.none.name,
      ),
      adjustmentDate: _optionalDate(json, 'adjustment_date'),
    );
    if (!_isValid(plan)) {
      throw const FormatException('Invalid Smart Khatma plan');
    }
    return plan;
  }

  bool _isValid(KhatmaPlan plan) {
    final int? confirmed = plan.confirmedCompletedThroughPage;
    return plan.id.isNotEmpty &&
        plan.durationDays > 0 &&
        plan.startPage >= KhatmaPlan.firstQuranPage &&
        plan.startPage <= plan.targetPage &&
        plan.targetPage <= KhatmaPlan.lastQuranPage &&
        (confirmed == null ||
            confirmed >= plan.startPage && confirmed <= plan.targetPage) &&
        plan.assignmentStartPage >= plan.startPage &&
        plan.assignmentStartPage <= plan.assignmentEndPage &&
        plan.assignmentEndPage <= plan.targetPage;
  }

  String _requiredString(Map<String, Object?> json, String key) {
    final String? value = _optionalString(json, key);
    if (value == null || value.isEmpty) throw FormatException('Invalid $key');
    return value;
  }

  String? _optionalString(Map<String, Object?> json, String key) {
    final Object? value = json[key];
    if (value == null) return null;
    if (value is String) return value;
    throw FormatException('Invalid $key');
  }

  int _requiredInt(Map<String, Object?> json, String key) {
    final int? value = _optionalInt(json, key);
    if (value == null) throw FormatException('Invalid $key');
    return value;
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
}
