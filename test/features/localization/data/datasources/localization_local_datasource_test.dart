import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/config/language_config.dart';
import 'package:tilawa/features/localization/data/datasources/localization_local_datasource.dart';

import 'localization_local_datasource_test.mocks.dart';

@GenerateMocks([SharedPreferencesAsync])
void main() {
  late LocalizationLocalDataSourceImpl dataSource;
  late MockSharedPreferencesAsync mockPrefs;

  setUp(() {
    mockPrefs = MockSharedPreferencesAsync();
    dataSource = LocalizationLocalDataSourceImpl(mockPrefs);
  });

  group('LocalizationLocalDataSource', () {
    const tLanguageCode = 'ar';

    test('getCurrentLanguage returns stored language code', () async {
      when(
        mockPrefs.getString(LanguageConfig.languageKey),
      ).thenAnswer((_) async => tLanguageCode);

      final String result = await dataSource.getCurrentLanguage();

      expect(result, tLanguageCode);
      verify(mockPrefs.getString(LanguageConfig.languageKey)).called(1);
    });

    test('getCurrentLanguage returns default when null', () async {
      when(
        mockPrefs.getString(LanguageConfig.languageKey),
      ).thenAnswer((_) async => null);

      final String result = await dataSource.getCurrentLanguage();

      expect(result, LanguageConfig.getDefaultLanguageCode());
      verify(mockPrefs.getString(LanguageConfig.languageKey)).called(1);
    });

    test('setLanguage saves language code', () async {
      when(mockPrefs.setString(any, any)).thenAnswer((_) async {
        return;
      });

      await dataSource.setLanguage(tLanguageCode);

      verify(
        mockPrefs.setString(LanguageConfig.languageKey, tLanguageCode),
      ).called(1);
    });

    test('getSupportedLanguages returns list from config', () async {
      final List<String> result = await dataSource.getSupportedLanguages();

      expect(result, LanguageConfig.getSupportedLanguageCodes());
    });
  });
}
