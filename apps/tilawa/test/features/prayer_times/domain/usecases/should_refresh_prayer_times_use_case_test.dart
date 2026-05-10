import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/prayer_times/domain/prayer_times_clock.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/should_refresh_prayer_times_use_case.dart';

void main() {
  const useCase = ShouldRefreshPrayerTimesUseCase();

  tearDown(PrayerTimesClock.clearTestingOverride);

  group('ShouldRefreshPrayerTimesUseCase', () {
    test('returns true when there is no loaded date', () {
      PrayerTimesClock.overrideForTesting(() => DateTime(2026, 5, 10, 12));

      final shouldRefresh = useCase(loadedDate: null);

      expect(shouldRefresh, isTrue);
    });

    test('returns false when loaded date and UTC offset are current', () {
      final now = DateTime(2026, 5, 10, 12);
      PrayerTimesClock.overrideForTesting(() => now);

      final shouldRefresh = useCase(loadedDate: DateTime(2026, 5, 10));

      expect(shouldRefresh, isFalse);
    });

    test('returns true when loaded date is before current local date', () {
      PrayerTimesClock.overrideForTesting(() => DateTime(2026, 5, 11));

      final shouldRefresh = useCase(loadedDate: DateTime(2026, 5, 10));

      expect(shouldRefresh, isTrue);
    });

    test('returns true when loaded UTC offset differs from current offset', () {
      final now = DateTime(2026, 5, 10, 12);
      PrayerTimesClock.overrideForTesting(() => now);

      final shouldRefresh = useCase(
        loadedDate: DateTime(2026, 5, 10),
        loadedUtcOffset: now.timeZoneOffset + const Duration(hours: 1),
      );

      expect(shouldRefresh, isTrue);
    });
  });
}
