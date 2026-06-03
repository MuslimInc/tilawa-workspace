import 'package:tilawa_core/entities/audio.dart';

/// Point-in-time playback from the native [AudioPlayerHandler] bridge.
class ActivePlaybackSnapshot {
  const ActivePlaybackSnapshot({
    required this.currentAudio,
    required this.playbackState,
  });

  final AudioEntity currentAudio;
  final PlaybackStateEntity playbackState;
}
