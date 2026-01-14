import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/prayer_times/data/datasources/datasources.dart';
import 'package:tilawa/features/prayer_times/data/repositories/prayer_times_repository_impl.dart';
import 'package:tilawa/features/prayer_times/domain/entities/entities.dart';
import 'package:tilawa/features/prayer_times/domain/repositories/prayer_times_repository.dart';

import 'prayer_times_repository_impl_test.mocks.dart';

@GenerateMocks([PrayerSettingsDataSource, LocationDataSource])
void main() {
  late PrayerTimesRepositoryImpl repository;
  late MockPrayerSettingsDataSource mockSettingsDataSource;
  late MockLocationDataSource mockLocationDataSource;

  setUp(() {
    mockSettingsDataSource = MockPrayerSettingsDataSource();
    mockLocationDataSource = MockLocationDataSource();
    repository = PrayerTimesRepositoryImpl(
      mockSettingsDataSource,
      mockLocationDataSource,
    );
  });

  group('PrayerTimesRepository', () {
    const tSettings = PrayerSettingsEntity();
    final tLocationResult = LocationResult(latitude: 10.0, longitude: 10.0);

    test('getPrayerTimes returns prayer times', () async {
      // Act
      final PrayerTimeEntity result = await repository.getPrayerTimes(
        latitude: 10.0,
        longitude: 10.0,
        date: DateTime.now(),
        settings: tSettings,
      );

      // Assert
      expect(result, isA<PrayerTimeEntity>());
    });

    test('getMonthlyPrayerTimes returns list of prayer times', () async {
      // Act
      final List<PrayerTimeEntity> result = await repository
          .getMonthlyPrayerTimes(
            latitude: 10.0,
            longitude: 10.0,
            year: 2024,
            month: 1,
            settings: tSettings,
          );

      // Assert
      expect(result, isA<List<PrayerTimeEntity>>());
      expect(result.isNotEmpty, true);
    });

    test('getPrayerTimesForRange returns list of prayer times', () async {
      // Act
      final List<PrayerTimeEntity> result = await repository
          .getPrayerTimesForRange(
            latitude: 10.0,
            longitude: 10.0,
            startDate: DateTime(2024),
            endDate: DateTime(2024, 1, 5),
            settings: tSettings,
          );

      // Assert
      expect(result, isA<List<PrayerTimeEntity>>());
      expect(result.length, 5);
    });

    test('getCurrentLocation delegates to datasource', () async {
      // Arrange
      when(
        mockLocationDataSource.getCurrentLocation(),
      ).thenAnswer((_) async => tLocationResult);

      // Act
      final LocationResult result = await repository.getCurrentLocation();

      // Assert
      expect(result, tLocationResult);
      verify(mockLocationDataSource.getCurrentLocation());
    });

    test('saveSettings delegates to datasource', () async {
      // Act
      await repository.saveSettings(tSettings);

      // Assert
      verify(mockSettingsDataSource.saveSettings(tSettings));
    });

    test('loadSettings delegates to datasource', () async {
      // Arrange
      when(
        mockSettingsDataSource.loadSettings(),
      ).thenAnswer((_) async => tSettings);

      // Act
      final PrayerSettingsEntity result = await repository.loadSettings();

      // Assert
      expect(result, tSettings);
      verify(mockSettingsDataSource.loadSettings());
    });
  });
}
