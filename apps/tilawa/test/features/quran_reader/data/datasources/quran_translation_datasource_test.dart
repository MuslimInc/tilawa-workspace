import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/quran_reader/data/datasources/quran_translation_datasource.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuranTranslationDataSourceImpl', () {
    late QuranTranslationDataSourceImpl dataSource;

    setUp(() {
      dataSource = QuranTranslationDataSourceImpl();
    });

    test('loads Sahih International for Al-Fatiha ayah 1', () async {
      final String? translation = await dataSource.getTranslation(
        surahNumber: 1,
        ayahNumber: 1,
        language: 'en',
      );

      expect(translation, isNotNull);
      expect(translation!, contains('Allāh'));
    });

    test('documents QUL source in bundled asset metadata', () async {
      final String raw = await rootBundle.loadString(
        'assets/data/translations/en_sahih.json',
      );
      final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;

      expect(json['source'], 'qul.tarteel.ai');
      expect(json['name'], 'Saheeh International');
      expect(json['edition'], 'en-sahih-international');
    });

    test('returns all ayahs for a surah', () async {
      final Map<int, String> translations = await dataSource
          .getSurahTranslations(
            surahNumber: 1,
            language: 'en',
          );

      expect(translations.length, 7);
      expect(translations[1], isNotNull);
    });

    test('returns empty map for unsupported languages', () async {
      final Map<int, String> translations = await dataSource
          .getSurahTranslations(
            surahNumber: 1,
            language: 'fr',
          );

      expect(translations, isEmpty);
    });
  });
}
