import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/services/noop_adhan_alarm_player.dart';

void main() {
  late NoOpAdhanAlarmPlayer player;

  setUp(() {
    player = const NoOpAdhanAlarmPlayer();
  });

  group('NoOpAdhanAlarmPlayer', () {
    test('isSupported returns false', () {
      expect(player.isSupported, isFalse);
    });

    test('scheduleAdhan completes without error', () async {
      expect(
        () => player.scheduleAdhan(
          id: 1,
          scheduledTime: DateTime.now().add(const Duration(hours: 1)),
          prayerName: 'fajr',
          prayerKey: 'fajr',
        ),
        returnsNormally,
      );
    });

    test('cancelAdhan completes without error', () async {
      expect(() => player.cancelAdhan(1), returnsNormally);
    });

    test('cancelAllAdhans completes without error', () async {
      expect(() => player.cancelAllAdhans(), returnsNormally);
    });

    test('scheduleAdhan returns a Future that resolves to void', () async {
      final result = player.scheduleAdhan(
        id: 42,
        scheduledTime: DateTime.now().add(const Duration(minutes: 30)),
        prayerName: 'isha',
        prayerKey: 'isha',
      );
      await expectLater(result, completes);
    });

    test('cancelAdhan returns a Future that resolves to void', () async {
      await expectLater(player.cancelAdhan(42), completes);
    });

    test('cancelAllAdhans returns a Future that resolves to void', () async {
      await expectLater(player.cancelAllAdhans(), completes);
    });

    test('multiple concurrent calls complete without error', () async {
      await expectLater(
        Future.wait([
          player.scheduleAdhan(
            id: 1,
            scheduledTime: DateTime.now().add(const Duration(hours: 1)),
            prayerName: 'fajr',
            prayerKey: 'fajr',
          ),
          player.scheduleAdhan(
            id: 2,
            scheduledTime: DateTime.now().add(const Duration(hours: 2)),
            prayerName: 'dhuhr',
            prayerKey: 'dhuhr',
          ),
          player.cancelAdhan(1),
          player.cancelAllAdhans(),
        ]),
        completes,
      );
    });
  });
}
