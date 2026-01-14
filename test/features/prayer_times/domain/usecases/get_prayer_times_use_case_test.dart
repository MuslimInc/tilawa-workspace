import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/core.dart';
import 'package:tilawa/features/prayer_times/domain/entities/entities.dart';
import 'package:tilawa/features/prayer_times/domain/repositories/prayer_times_repository.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/usecases.dart';

import 'get_prayer_times_use_case_test.mocks.dart';

@GenerateMocks([PrayerTimesRepository])
void main() {
  late GetPrayerTimesUseCase useCase;
  late MockPrayerTimesRepository mockRepository;

  setUp(() {
    mockRepository = MockPrayerTimesRepository();
    useCase = GetPrayerTimesUseCase(mockRepository);
  });

  final tDate = DateTime.now();
  const tSettings = PrayerSettingsEntity();
  final tPrayerTimes = PrayerTimeEntity(
    date: tDate,
    fajr: tDate,
    sunrise: tDate,
    dhuhr: tDate,
    asr: tDate,
    maghrib: tDate,
    isha: tDate,
    latitude: 10.0,
    longitude: 10.0,
  );

  test('should get prayer times from repository', () async {
    // Arrange
    when(
      mockRepository.getPrayerTimes(
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
        date: anyNamed('date'),
        settings: anyNamed('settings'),
      ),
    ).thenAnswer((_) async => tPrayerTimes);

    // Act
    final Either<Failure, PrayerTimeEntity> result = await useCase(
      latitude: 10.0,
      longitude: 10.0,
      date: tDate,
      settings: tSettings,
    );

    // Assert
    expect(result, Right<Failure, PrayerTimeEntity>(tPrayerTimes));
    verify(
      mockRepository.getPrayerTimes(
        latitude: 10.0,
        longitude: 10.0,
        date: tDate,
        settings: tSettings,
      ),
    );
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return failure when repository throws exception', () async {
    // Arrange
    when(
      mockRepository.getPrayerTimes(
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
        date: anyNamed('date'),
        settings: anyNamed('settings'),
      ),
    ).thenThrow(Exception('Test Error'));

    // Act
    final Either<Failure, PrayerTimeEntity> result = await useCase(
      latitude: 10.0,
      longitude: 10.0,
      date: tDate,
      settings: tSettings,
    );

    // Assert
    expect(result.fold((l) => true, (r) => false), true);
    result.fold(
      (failure) => expect(failure, isA<UnexpectedFailure>()),
      (_) => fail('Should have failed'),
    );
  });
}
