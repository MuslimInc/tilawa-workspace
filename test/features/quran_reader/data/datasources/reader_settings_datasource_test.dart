import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/features/quran_reader/data/datasources/reader_settings_datasource.dart';
import 'package:tilawa/features/quran_reader/domain/entities/reader_settings_entity.dart';

class MockSharedPreferencesAsync extends Mock
    implements SharedPreferencesAsync {}

void main() {
  late ReaderSettingsDataSourceImpl dataSource;
  late MockSharedPreferencesAsync mockPrefs;

  setUp(() {
    mockPrefs = MockSharedPreferencesAsync();
    dataSource = ReaderSettingsDataSourceImpl(mockPrefs);
  });

  group('loadSettings', () {
    test('should return default settings when no settings are saved', () async {
      when(
        () => mockPrefs.getString('reader_settings'),
      ).thenAnswer((_) async => null);

      final ReaderSettingsEntity result = await dataSource.loadSettings();

      expect(result, const ReaderSettingsEntity());
    });

    test('should return saved settings when they exist', () async {
      const settings = ReaderSettingsEntity();
      final String settingsJson = jsonEncode(settings.toJson());
      when(
        () => mockPrefs.getString('reader_settings'),
      ).thenAnswer((_) async => settingsJson);

      final ReaderSettingsEntity result = await dataSource.loadSettings();

      expect(result.fontSize, 24.0);
    });

    test('should return default settings when json is invalid', () async {
      when(
        () => mockPrefs.getString('reader_settings'),
      ).thenAnswer((_) async => 'invalid json');

      final ReaderSettingsEntity result = await dataSource.loadSettings();

      expect(result, const ReaderSettingsEntity());
    });
  });

  group('saveSettings', () {
    test('should call setString on SharedPreferencesAsync', () async {
      const settings = ReaderSettingsEntity(fontSize: 30.0);
      when(
        () => mockPrefs.setString('reader_settings', any()),
      ).thenAnswer((_) async {});

      await dataSource.saveSettings(settings);

      verify(() => mockPrefs.setString('reader_settings', any())).called(1);
    });
  });

  group('saveLastReadPosition', () {
    test('should save all position fields when provided', () async {
      when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async {});

      await dataSource.saveLastReadPosition(
        surahNumber: 1,
        ayahNumber: 2,
        page: 1,
      );

      verify(() => mockPrefs.setInt('last_read_surah', 1)).called(1);
      verify(() => mockPrefs.setInt('last_read_ayah', 2)).called(1);
      verify(() => mockPrefs.setInt('last_read_page', 1)).called(1);
    });

    test('should only save surah number if others are null', () async {
      when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async {});

      await dataSource.saveLastReadPosition(surahNumber: 1);

      verify(() => mockPrefs.setInt('last_read_surah', 1)).called(1);
      verifyNever(() => mockPrefs.setInt('last_read_ayah', any()));
      verifyNever(() => mockPrefs.setInt('last_read_page', any()));
    });
  });

  group('getLastReadPosition', () {
    test('should return previously saved position', () async {
      when(
        () => mockPrefs.getInt('last_read_surah'),
      ).thenAnswer((_) async => 1);
      when(() => mockPrefs.getInt('last_read_ayah')).thenAnswer((_) async => 2);
      when(() => mockPrefs.getInt('last_read_page')).thenAnswer((_) async => 3);

      final ({int? ayahNumber, int? page, int? surahNumber}) result =
          await dataSource.getLastReadPosition();

      expect(result.surahNumber, 1);
      expect(result.ayahNumber, 2);
      expect(result.page, 3);
    });

    test('should return nulls if nothing is saved', () async {
      when(() => mockPrefs.getInt(any())).thenAnswer((_) async => null);

      final ({int? ayahNumber, int? page, int? surahNumber}) result =
          await dataSource.getLastReadPosition();

      expect(result.surahNumber, isNull);
      expect(result.ayahNumber, isNull);
      expect(result.page, isNull);
    });
  });
}
