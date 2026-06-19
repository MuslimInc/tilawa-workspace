import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

/// Loads bundled Quran verse translations keyed by surah and ayah number.
abstract class QuranTranslationDataSource {
  Future<String?> getTranslation({
    required int surahNumber,
    required int ayahNumber,
    required String language,
  });

  Future<Map<int, String>> getSurahTranslations({
    required int surahNumber,
    required String language,
  });
}

@LazySingleton(as: QuranTranslationDataSource)
class QuranTranslationDataSourceImpl implements QuranTranslationDataSource {
  QuranTranslationDataSourceImpl();

  static const String _englishAssetPath =
      'assets/data/translations/en_sahih.json';

  Map<String, Map<String, String>>? _englishBySurah;

  Future<void> _ensureEnglishLoaded() async {
    if (_englishBySurah != null) {
      return;
    }

    final String jsonString = await rootBundle.loadString(_englishAssetPath);
    final Map<String, dynamic> parsed =
        jsonDecode(jsonString) as Map<String, dynamic>;
    final Map<String, dynamic> surahs =
        parsed['surahs'] as Map<String, dynamic>;

    _englishBySurah = surahs.map((surahKey, ayahMap) {
      final Map<String, dynamic> ayahs = ayahMap as Map<String, dynamic>;
      return MapEntry(
        surahKey,
        ayahs.map(
          (ayahKey, text) => MapEntry(ayahKey, text as String),
        ),
      );
    });
  }

  Map<String, Map<String, String>>? _translationsForLanguage(String language) {
    return switch (language) {
      'en' => _englishBySurah,
      _ => null,
    };
  }

  @override
  Future<String?> getTranslation({
    required int surahNumber,
    required int ayahNumber,
    required String language,
  }) async {
    if (language != 'en') {
      return null;
    }
    await _ensureEnglishLoaded();
    return _translationsForLanguage(language)?['$surahNumber']?['$ayahNumber'];
  }

  @override
  Future<Map<int, String>> getSurahTranslations({
    required int surahNumber,
    required String language,
  }) async {
    if (language != 'en') {
      return const {};
    }
    await _ensureEnglishLoaded();
    final Map<String, String>? ayahs = _translationsForLanguage(
      language,
    )?['$surahNumber'];
    if (ayahs == null) {
      return const {};
    }
    return ayahs.map(
      (ayahNumber, text) => MapEntry(int.parse(ayahNumber), text),
    );
  }
}
