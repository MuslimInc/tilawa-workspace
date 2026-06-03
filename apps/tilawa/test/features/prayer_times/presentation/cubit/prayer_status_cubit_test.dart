import 'dart:async';
import 'dart:convert';

import 'package:dartz_plus/dartz_plus.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_settings_entity.dart';
import 'package:tilawa/features/prayer_times/domain/services/adhan_alarm_player_interface.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/load_prayer_settings_use_case.dart';
import 'package:tilawa/features/prayer_times/presentation/cubit/prayer_status_cubit.dart';
import 'package:tilawa_core/core.dart';

void main() {
  String payload({
    String prayerName = 'fajr',
    int? scheduledTimeMs,
    bool adhanEnabled = true,
  }) {
    return jsonEncode({
      'type': 'prayer',
      'prayer_name': prayerName,
      'scheduled_time_ms':
          scheduledTimeMs ?? DateTime(2026, 5, 5, 4, 30).millisecondsSinceEpoch,
      'adhan_enabled': adhanEnabled,
      'notification_id': 2001,
    });
  }

  test(
    'init emits payload state before native playback check completes',
    () async {
      final playbackStatus = Completer<bool>();
      final player = _FakeAdhanAlarmPlayer(
        onIsAdhanPlaying: () => playbackStatus.future,
      );
      final cubit = PrayerStatusCubit(player, _FakeLoadPrayerSettings());
      final states = <PrayerStatusState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.init(payload(adhanEnabled: true));
      await Future<void>.delayed(Duration.zero);

      expect(player.isAdhanPlayingCallCount, 1);
      expect(states.first, const PrayerStatusState.loading());
      expect(
        states.last,
        _loadedState(
          prayerName: 'fajr',
          adhanEnabled: true,
          isAdhanPlaying: true,
        ),
      );

      playbackStatus.complete(false);
      await Future<void>.delayed(Duration.zero);

      expect(
        cubit.state,
        _loadedState(
          prayerName: 'fajr',
          adhanEnabled: true,
          isAdhanPlaying: false,
        ),
      );

      await subscription.cancel();
      await cubit.close();
    },
  );

  test('keeps payload state when native playback check fails', () async {
    final player = _FakeAdhanAlarmPlayer(
      onIsAdhanPlaying: () => Future<bool>.error(Exception('native failed')),
    );
    final cubit = PrayerStatusCubit(player, _FakeLoadPrayerSettings());

    await cubit.init(payload(adhanEnabled: true));
    await Future<void>.delayed(Duration.zero);

    expect(
      cubit.state,
      _loadedState(
        prayerName: 'fajr',
        adhanEnabled: true,
        isAdhanPlaying: true,
      ),
    );

    await cubit.close();
  });

  test('does not start polling when payload says adhan is disabled', () {
    fakeAsync((async) {
      final player = _FakeAdhanAlarmPlayer(onIsAdhanPlaying: () async => false);
      final cubit = PrayerStatusCubit(player, _FakeLoadPrayerSettings());

      unawaited(cubit.init(payload(adhanEnabled: false)));
      async.flushMicrotasks();
      expect(player.isAdhanPlayingCallCount, 1);

      async.elapse(const Duration(seconds: 6));
      async.flushMicrotasks();
      expect(player.isAdhanPlayingCallCount, 1);

      unawaited(cubit.close());
      async.flushMicrotasks();
    });
  });

  test('does not overlap polling while playback status check is in flight', () {
    fakeAsync((async) {
      final playbackStatus = Completer<bool>();
      final player = _FakeAdhanAlarmPlayer(
        onIsAdhanPlaying: () => playbackStatus.future,
      );
      final cubit = PrayerStatusCubit(player, _FakeLoadPrayerSettings());

      unawaited(cubit.init(payload(adhanEnabled: true)));
      async.flushMicrotasks();
      expect(player.isAdhanPlayingCallCount, 1);

      async.elapse(const Duration(seconds: 6));
      async.flushMicrotasks();
      expect(player.isAdhanPlayingCallCount, 1);

      playbackStatus.complete(true);
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 2));
      async.flushMicrotasks();
      expect(player.isAdhanPlayingCallCount, 2);

      unawaited(cubit.close());
      async.flushMicrotasks();
    });
  });
}

Matcher _loadedState({
  required String prayerName,
  required bool adhanEnabled,
  required bool isAdhanPlaying,
}) {
  return predicate<PrayerStatusState>((state) {
    return state.maybeWhen(
      loaded:
          (
            actualPrayerName,
            scheduledTime,
            actualIsAdhanPlaying,
            actualAdhanEnabled,
            soundName,
            notificationId,
            locationName,
          ) {
            return actualPrayerName == prayerName &&
                actualAdhanEnabled == adhanEnabled &&
                actualIsAdhanPlaying == isAdhanPlaying;
          },
      orElse: () => false,
    );
  });
}

class _FakeLoadPrayerSettings implements LoadPrayerSettingsUseCase {
  @override
  Future<Either<Failure, PrayerSettingsEntity>> call() async =>
      Left(Failure.unexpectedError('no settings'));
}

class _FakeAdhanAlarmPlayer implements IAdhanAlarmPlayer {
  _FakeAdhanAlarmPlayer({required this._onIsAdhanPlaying});

  final Future<bool> Function() _onIsAdhanPlaying;
  int isAdhanPlayingCallCount = 0;

  @override
  bool get isSupported => true;

  @override
  Stream<String> get onNotificationTapped => const Stream.empty();

  @override
  Future<void> flushPendingNotificationTap() async {}

  @override
  Future<String?> pullPendingNotificationTapPayload() async => null;

  @override
  Future<bool> isAdhanPlaying() {
    isAdhanPlayingCallCount += 1;
    return _onIsAdhanPlaying();
  }

  @override
  Future<void> stopCurrentAdhan() async {}

  @override
  Future<void> cancelAdhan(int id, {String? prayerName}) async {}

  @override
  Future<void> cancelAllAdhans() async {}

  @override
  Future<bool> consumeNeedsRescheduleAfterBoot() async => false;

  @override
  Future<void> markNeedsReschedule() async {}

  @override
  Future<bool> isIgnoringBatteryOptimizations() async => true;

  @override
  Future<String?> manufacturer() async => null;

  @override
  Future<void> persistPendingAlarms(List<PendingAdhanAlarm> alarms) async {}

  @override
  Future<void> requestIgnoreBatteryOptimizations() async {}

  @override
  Future<bool> scheduleAdhan({
    required int id,
    required DateTime scheduledTime,
    required String prayerName,
    required String prayerKey,
    String? sound,
  }) async {
    return true;
  }

  @override
  Future<bool> playAdhanNow({
    required int id,
    required String prayerName,
    required String prayerKey,
    String? sound,
  }) async =>
      false;

  @override
  Future<String?> getActiveAdhanPayload() async => null;
}
