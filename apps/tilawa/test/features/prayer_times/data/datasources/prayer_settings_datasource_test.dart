import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/features/prayer_times/data/datasources/prayer_settings_datasource.dart';
import 'package:tilawa/features/prayer_times/domain/entities/entities.dart';

import 'prayer_settings_datasource_test.mocks.dart';

@GenerateMocks([SharedPreferencesAsync])
void main() {
  late PrayerSettingsDataSourceImpl dataSource;
  late MockSharedPreferencesAsync mockPrefs;
  const tSettings = PrayerSettingsEntity(
    calculationMethod: CalculationMethod.muslimWorldLeague,
  );

  setUp(() {
    mockPrefs = MockSharedPreferencesAsync();
    dataSource = PrayerSettingsDataSourceImpl(mockPrefs);
  });

  group('PrayerSettingsDataSource', () {
    test('saveSettings saves encoded json', () async {
      // Act
      await dataSource.saveSettings(tSettings);

      // Assert
      final String expectedJson = jsonEncode(tSettings.toJson());
      verify(mockPrefs.setString('prayer_settings', expectedJson));
    });

    test('loadSettings returns settings when cached data is present', () async {
      // Arrange
      when(
        mockPrefs.getString('prayer_settings'),
      ).thenAnswer((_) async => jsonEncode(tSettings.toJson()));

      // Act
      final PrayerSettingsEntity result = await dataSource.loadSettings();

      // Assert
      expect(result.calculationMethod, tSettings.calculationMethod);
    });

    test(
      'loadSettings returns default settings when no data is present',
      () async {
        // Arrange
        when(
          mockPrefs.getString('prayer_settings'),
        ).thenAnswer((_) async => null);

        // Act
        final PrayerSettingsEntity result = await dataSource.loadSettings();

        // Assert
        expect(result, const PrayerSettingsEntity());
      },
    );

    test(
      'loadSettings returns default settings when json is invalid',
      () async {
        // Arrange
        when(
          mockPrefs.getString('prayer_settings'),
        ).thenAnswer((_) async => 'invalid_json');

        // Act
        final PrayerSettingsEntity result = await dataSource.loadSettings();

        // Assert
        expect(result, const PrayerSettingsEntity());
      },
    );

    test('clearSettings removes the key', () async {
      // Act
      await dataSource.clearSettings();

      // Assert
      verify(mockPrefs.remove('prayer_settings'));
    });
  });
}
