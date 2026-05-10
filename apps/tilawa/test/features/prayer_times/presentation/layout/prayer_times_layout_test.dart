import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/prayer_times/presentation/layout/prayer_times_layout.dart';

void main() {
  group('PrayerTimesLayout', () {
    test('isNarrowWidth is false at threshold and above', () {
      expect(PrayerTimesLayout.isNarrowWidth(400), isFalse);
      expect(PrayerTimesLayout.isNarrowWidth(500), isFalse);
    });

    test('isNarrowWidth is true below threshold', () {
      expect(PrayerTimesLayout.isNarrowWidth(399), isTrue);
      expect(PrayerTimesLayout.isNarrowWidth(360), isTrue);
    });

    test('isNarrowWidth is false for non-positive width', () {
      expect(PrayerTimesLayout.isNarrowWidth(0), isFalse);
      expect(PrayerTimesLayout.isNarrowWidth(-1), isFalse);
    });
  });
}
