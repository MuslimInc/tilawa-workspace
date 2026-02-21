import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/entities.dart';

abstract class ReaderSettingsDataSource {
  Future<ReaderSettingsEntity> loadSettings();
  Future<void> saveSettings(ReaderSettingsEntity settings);
  Future<void> saveLastReadPosition({
    required int surahNumber,
    int? ayahNumber,
    int? page,
  });
  Future<({int? surahNumber, int? ayahNumber, int? page})>
  getLastReadPosition();
}

@LazySingleton(as: ReaderSettingsDataSource)
class ReaderSettingsDataSourceImpl implements ReaderSettingsDataSource {
  ReaderSettingsDataSourceImpl(this._prefs);

  static const String _settingsKey = 'reader_settings';
  static const String _lastReadSurahKey = 'last_read_surah';
  static const String _lastReadAyahKey = 'last_read_ayah';
  static const String _lastReadPageKey = 'last_read_page';

  final SharedPreferencesAsync _prefs;

  @override
  Future<ReaderSettingsEntity> loadSettings() async {
    final String? settingsJson = await _prefs.getString(_settingsKey);

    if (settingsJson == null) {
      return const ReaderSettingsEntity();
    }

    try {
      final Map<String, dynamic> json = jsonDecode(settingsJson);
      return ReaderSettingsEntity.fromJson(json);
    } catch (e) {
      return const ReaderSettingsEntity();
    }
  }

  @override
  Future<void> saveSettings(ReaderSettingsEntity settings) async {
    final String settingsJson = jsonEncode(settings.toJson());
    await _prefs.setString(_settingsKey, settingsJson);
  }

  @override
  Future<void> saveLastReadPosition({
    required int surahNumber,
    int? ayahNumber,
    int? page,
  }) async {
    await _prefs.setInt(_lastReadSurahKey, surahNumber);
    if (ayahNumber != null) {
      await _prefs.setInt(_lastReadAyahKey, ayahNumber);
    } else {
      await _prefs.remove(_lastReadAyahKey);
    }
    if (page != null) {
      await _prefs.setInt(_lastReadPageKey, page);
    } else {
      await _prefs.remove(_lastReadPageKey);
    }
  }

  @override
  Future<({int? surahNumber, int? ayahNumber, int? page})>
  getLastReadPosition() async {
    final int? surahNumber = await _prefs.getInt(_lastReadSurahKey);
    final int? ayahNumber = await _prefs.getInt(_lastReadAyahKey);
    final int? page = await _prefs.getInt(_lastReadPageKey);

    return (surahNumber: surahNumber, ayahNumber: ayahNumber, page: page);
  }
}
