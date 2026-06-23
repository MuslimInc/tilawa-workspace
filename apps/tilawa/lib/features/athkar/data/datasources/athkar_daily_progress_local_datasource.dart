import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists per-item remaining counts for canonical daily athkar categories.
abstract class AthkarDailyProgressLocalDataSource {
  Future<Map<int, int>> loadCounts({
    required int categoryId,
    required String dateKey,
  });

  Future<void> saveCounts({
    required int categoryId,
    required String dateKey,
    required Map<int, int> remainingCounts,
  });
}

@LazySingleton(as: AthkarDailyProgressLocalDataSource)
class AthkarDailyProgressLocalDataSourceImpl
    implements AthkarDailyProgressLocalDataSource {
  AthkarDailyProgressLocalDataSourceImpl(this._prefs);

  final SharedPreferencesAsync _prefs;

  static String _storageKey(int categoryId, String dateKey) =>
      'athkar_daily_progress_${categoryId}_$dateKey';

  @override
  Future<Map<int, int>> loadCounts({
    required int categoryId,
    required String dateKey,
  }) async {
    final String? raw = await _prefs.getString(
      _storageKey(categoryId, dateKey),
    );
    if (raw == null || raw.isEmpty) {
      return const {};
    }
    final Map<String, dynamic> decoded =
        json.decode(raw) as Map<String, dynamic>;
    return decoded.map(
      (key, value) => MapEntry(int.parse(key), value as int),
    );
  }

  @override
  Future<void> saveCounts({
    required int categoryId,
    required String dateKey,
    required Map<int, int> remainingCounts,
  }) async {
    final String encoded = json.encode(
      remainingCounts.map((key, value) => MapEntry(key.toString(), value)),
    );
    await _prefs.setString(_storageKey(categoryId, dateKey), encoded);
  }
}

String athkarDailyProgressDateKey(DateTime date) {
  final String month = date.month.toString().padLeft(2, '0');
  final String day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
