import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa/features/prayer_times/domain/entities/entities.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/load_prayer_settings_use_case.dart';

import 'get_current_location_use_case_test.mocks.dart';

void main() {
  late LoadPrayerSettingsUseCase useCase;
  late MockPrayerTimesRepository mockRepository;

  setUp(() {
    mockRepository = MockPrayerTimesRepository();
    useCase = LoadPrayerSettingsUseCase(mockRepository);
  });

  const tSettings = PrayerSettingsEntity();

  test('should return settings from repository', () async {
    // Arrange
    when(mockRepository.loadSettings()).thenAnswer((_) async => tSettings);

    // Act
    final Either<Failure, PrayerSettingsEntity> result = await useCase();

    // Assert
    expect(result, const Right<Failure, PrayerSettingsEntity>(tSettings));
    verify(mockRepository.loadSettings());
  });
}
