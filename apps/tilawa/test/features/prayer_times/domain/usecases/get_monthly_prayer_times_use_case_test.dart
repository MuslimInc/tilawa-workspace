import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/prayer_times/domain/entities/entities.dart';
import 'package:tilawa/features/prayer_times/domain/repositories/prayer_times_repository.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/usecases.dart';
import 'package:tilawa_core/errors/failures.dart';

import 'get_monthly_prayer_times_use_case_test.mocks.dart';

@GenerateMocks([PrayerTimesRepository])
void main() {
  late GetMonthlyPrayerTimesUseCase useCase;
  late MockPrayerTimesRepository mockRepository;

  setUp(() {
    mockRepository = MockPrayerTimesRepository();
    useCase = GetMonthlyPrayerTimesUseCase(mockRepository);
  });

  final tDate = DateTime.now();
  const tSettings = PrayerSettingsEntity();
  final tPrayerTimesList = [
    PrayerTimeEntity(
      date: tDate,
      fajr: tDate,
      sunrise: tDate,
      dhuhr: tDate,
      asr: tDate,
      maghrib: DateTime(2023, 1, 1, 17, 30),
      isha: DateTime(2023, 1, 1, 19, 0),
      midnight: DateTime(2023, 1, 1, 23, 30),
      lastThird: DateTime(2023, 1, 2, 2, 0),
      latitude: 10.0,
      longitude: 10.0,
    ),
  ];

  test('should get monthly prayer times from repository', () async {
    // Arrange
    when(
      mockRepository.getMonthlyPrayerTimes(
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
        year: anyNamed('year'),
        month: anyNamed('month'),
        settings: anyNamed('settings'),
      ),
    ).thenAnswer((_) async => tPrayerTimesList);

    // Act
    final Either<Failure, List<PrayerTimeEntity>> result = await useCase(
      latitude: 10.0,
      longitude: 10.0,
      year: 2024,
      month: 1,
      settings: tSettings,
    );

    // Assert
    expect(result, Right<Failure, List<PrayerTimeEntity>>(tPrayerTimesList));
    verify(
      mockRepository.getMonthlyPrayerTimes(
        latitude: 10.0,
        longitude: 10.0,
        year: 2024,
        month: 1,
        settings: tSettings,
      ),
    );
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return failure when repository throws exception', () async {
    // Arrange
    when(
      mockRepository.getMonthlyPrayerTimes(
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
        year: anyNamed('year'),
        month: anyNamed('month'),
        settings: anyNamed('settings'),
      ),
    ).thenThrow(Exception('Test Error'));

    // Act
    final Either<Failure, List<PrayerTimeEntity>> result = await useCase(
      latitude: 10.0,
      longitude: 10.0,
      year: 2024,
      month: 1,
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
