import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/errors/failures.dart';
import 'package:tilawa/features/prayer_times/domain/entities/entities.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/save_prayer_settings_use_case.dart';

import 'get_current_location_use_case_test.mocks.dart';

void main() {
  late SavePrayerSettingsUseCase useCase;
  late MockPrayerTimesRepository mockRepository;

  setUp(() {
    mockRepository = MockPrayerTimesRepository();
    useCase = SavePrayerSettingsUseCase(mockRepository);
  });

  const tSettings = PrayerSettingsEntity();

  test('should call repository to save settings', () async {
    // Act
    final Either<Failure, void> result = await useCase(settings: tSettings);

    // Assert
    expect(result, const Right<Failure, void>(null));
    verify(mockRepository.saveSettings(tSettings));
  });
}
