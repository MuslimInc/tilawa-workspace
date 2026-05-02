import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tilawa/features/prayer_times/domain/services/adhan_alarm_player_interface.dart';
import 'package:tilawa_core/errors/failures.dart';

part 'prayer_status_cubit.freezed.dart';

@freezed
class PrayerStatusState with _$PrayerStatusState {
  const factory PrayerStatusState.initial() = _Initial;
  const factory PrayerStatusState.loading() = _Loading;
  const factory PrayerStatusState.loaded({
    required String prayerName,
    required DateTime scheduledTime,
    required bool isAdhanPlaying,
    required bool adhanEnabled,
    String? soundName,
    int? notificationId,
  }) = _Loaded;
  const factory PrayerStatusState.error(Failure failure) = _Error;
}

class PrayerStatusCubit extends Cubit<PrayerStatusState> {
  final IAdhanAlarmPlayer _adhanPlayer;
  Timer? _statusPollTimer;

  PrayerStatusCubit(this._adhanPlayer)
    : super(const PrayerStatusState.initial());

  Future<void> init(String? payloadJson) async {
    if (payloadJson == null || payloadJson.isEmpty) {
      emit(
        const PrayerStatusState.error(
          NotificationFailure(
            'Missing payload',
            NotificationFailureReason.missingPayload,
          ),
        ),
      );
      return;
    }

    emit(const PrayerStatusState.loading());

    try {
      final Map<String, dynamic> data = jsonDecode(payloadJson);
      final String? prayerName = data['prayer_name'];
      final int? scheduledTimeMs = data['scheduled_time_ms'];
      final bool adhanEnabled = data['adhan_enabled'] ?? false;
      final String? soundName =
          data['sound_name'] ?? (adhanEnabled ? 'adhan' : null);
      final int? notificationId = data['notification_id'];

      if (prayerName == null || scheduledTimeMs == null) {
        emit(
          const PrayerStatusState.error(
            NotificationFailure(
              'Invalid payload data',
              NotificationFailureReason.invalidPayload,
            ),
          ),
        );
        return;
      }

      final isPlaying = await _adhanPlayer.isAdhanPlaying();

      emit(
        PrayerStatusState.loaded(
          prayerName: prayerName,
          scheduledTime: DateTime.fromMillisecondsSinceEpoch(scheduledTimeMs),
          isAdhanPlaying: isPlaying,
          adhanEnabled: adhanEnabled,
          soundName: soundName,
          notificationId: notificationId,
        ),
      );

      // Start polling status if Adhan is expected to be playing
      if (adhanEnabled) {
        _startPolling();
      }
    } catch (e) {
      emit(
        PrayerStatusState.error(
          NotificationFailure(
            'Failed to parse payload: $e',
            NotificationFailureReason.invalidPayload,
          ),
        ),
      );
    }
  }

  void _startPolling() {
    _statusPollTimer?.cancel();
    _statusPollTimer = Timer.periodic(const Duration(seconds: 2), (
      timer,
    ) async {
      final isPlaying = await _adhanPlayer.isAdhanPlaying();
      state.maybeWhen(
        loaded: (name, time, currentPlaying, enabled, sound, id) {
          if (currentPlaying != isPlaying) {
            emit((state as _Loaded).copyWith(isAdhanPlaying: isPlaying));
          }
        },
        orElse: () => timer.cancel(),
      );
    });
  }

  Future<void> stopAdhan() async {
    await _adhanPlayer.stopCurrentAdhan();
    final isPlaying = await _adhanPlayer.isAdhanPlaying();
    state.maybeWhen(
      loaded: (name, time, currentPlaying, enabled, sound, id) {
        emit((state as _Loaded).copyWith(isAdhanPlaying: isPlaying));
      },
      orElse: () {},
    );
  }

  @override
  Future<void> close() {
    _statusPollTimer?.cancel();
    return super.close();
  }
}
