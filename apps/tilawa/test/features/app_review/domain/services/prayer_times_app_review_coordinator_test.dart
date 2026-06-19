import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/app_review/domain/services/prayer_times_app_review_coordinator.dart';

void main() {
  late PrayerTimesAppReviewCoordinator coordinator;

  setUp(() {
    coordinator = PrayerTimesAppReviewCoordinator();
  });

  test('consumeRecitersPrompt is false until prayer screen closes', () {
    expect(coordinator.consumeRecitersPrompt(), isFalse);
  });

  test('arms and consumes reciters prompt once', () {
    coordinator.onPrayerTimesScreenClosed();

    expect(coordinator.consumeRecitersPrompt(), isTrue);
    expect(coordinator.consumeRecitersPrompt(), isFalse);
  });

  test('cancelRecitersPrompt clears a pending arm', () {
    coordinator
      ..onPrayerTimesScreenClosed()
      ..cancelRecitersPrompt();

    expect(coordinator.consumeRecitersPrompt(), isFalse);
  });
}
