import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/shared/audio/audio_player_handler.dart';

abstract class AudioPositionService {
  Stream<Duration> get position;
}

@LazySingleton(as: AudioPositionService)
class AudioPositionServiceImpl implements AudioPositionService {
  AudioPositionServiceImpl(this._audioHandler);

  final AudioPlayerHandler _audioHandler;

  late final Stream<Duration> _position = _createPositionStream().distinct();

  @override
  Stream<Duration> get position => _position;

  Stream<Duration> _createPositionStream({
    int steps = 800,
    Duration minPeriod = const Duration(milliseconds: 16),
    Duration maxPeriod = const Duration(milliseconds: 200),
  }) {
    assert(minPeriod <= maxPeriod);
    assert(minPeriod > Duration.zero);

    Duration? lastPosition;
    late StreamController<Duration> controller;
    late StreamSubscription<MediaItem?> mediaItemSubscription;
    late StreamSubscription<PlaybackState> playbackStateSubscription;
    Timer? positionTimer;

    Duration currentDuration() =>
        _audioHandler.mediaItem.valueOrNull?.duration ?? Duration.zero;

    Duration tickPeriod() {
      Duration period = currentDuration() ~/ steps;
      if (period < minPeriod) period = minPeriod;
      if (period > maxPeriod) period = maxPeriod;
      return period;
    }

    void emitCurrentPosition([Timer? _]) {
      final Duration position = _audioHandler.playbackState.value.position;
      if (lastPosition != position) {
        controller.add(lastPosition = position);
      }
    }

    void refreshPositionTimer() {
      final bool shouldPollPosition =
          _audioHandler.mediaItem.valueOrNull != null &&
          _audioHandler.playbackState.value.playing;

      if (!shouldPollPosition) {
        positionTimer?.cancel();
        positionTimer = null;
        return;
      }

      positionTimer?.cancel();
      positionTimer = Timer.periodic(tickPeriod(), emitCurrentPosition);
    }

    controller = StreamController<Duration>.broadcast(
      sync: true,
      onListen: () {
        mediaItemSubscription = _audioHandler.mediaItem.listen((_) {
          refreshPositionTimer();
          emitCurrentPosition();
        });
        playbackStateSubscription = _audioHandler.playbackState.listen((_) {
          refreshPositionTimer();
          emitCurrentPosition();
        });
      },
      onCancel: () {
        positionTimer?.cancel();
        mediaItemSubscription.cancel();
        playbackStateSubscription.cancel();
      },
    );

    return controller.stream;
  }
}
