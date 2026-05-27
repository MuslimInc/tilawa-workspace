import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/tour_completion_record.dart';

/// SharedPreferences keys for tour progress (do not rename after release).
abstract interface class TourProgressLocalDataSource {
  Future<TourCompletionRecord> read(String tourId);

  Future<void> write({
    required String tourId,
    required TourCompletionRecord record,
  });

  Future<void> clearTour(String tourId);

  Future<void> clearAll();
}

@LazySingleton(as: TourProgressLocalDataSource)
class TourProgressLocalDataSourceImpl implements TourProgressLocalDataSource {
  TourProgressLocalDataSourceImpl(this._prefs);

  static const String _prefix = 'tour_guide_';

  final SharedPreferencesAsync _prefs;

  String _completedKey(String tourId) => '$_prefix${tourId}_completed';

  String _versionKey(String tourId) => '$_prefix${tourId}_version';

  @override
  Future<TourCompletionRecord> read(String tourId) async {
    return TourCompletionRecord(
      completed: await _prefs.getBool(_completedKey(tourId)) ?? false,
      completedVersion: await _prefs.getInt(_versionKey(tourId)) ?? 0,
    );
  }

  @override
  Future<void> write({
    required String tourId,
    required TourCompletionRecord record,
  }) async {
    await _prefs.setBool(_completedKey(tourId), record.completed);
    await _prefs.setInt(_versionKey(tourId), record.completedVersion);
  }

  @override
  Future<void> clearTour(String tourId) async {
    await _prefs.remove(_completedKey(tourId));
    await _prefs.remove(_versionKey(tourId));
  }

  @override
  Future<void> clearAll() async {
    final Set<String> keys = await _prefs.getKeys();
    for (final String key in keys) {
      if (key.startsWith(_prefix)) {
        await _prefs.remove(key);
      }
    }
  }
}
