import 'package:tilawa_core/entities/audio.dart';

/// Resolves the scrubber position shown in the player UI.
///
/// Prefer the live position stream when it has advanced; fall back to
/// [playbackState.position] when the stream has not ticked yet (e.g. right
/// after load). This avoids playback-state sync events with a stale or zero
/// engine position overwriting stream ticks.
Duration resolvePlaybackDisplayPosition({
  required PlaybackStateEntity? playbackState,
  required Duration streamPosition,
}) {
  if (streamPosition > Duration.zero) {
    return streamPosition;
  }
  if (playbackState != null && playbackState.position > Duration.zero) {
    return playbackState.position;
  }
  return Duration.zero;
}
