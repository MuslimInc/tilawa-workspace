import 'package:tilawa_core/entities/audio.dart';

/// Resolves the scrubber position shown in the player UI.
///
/// Prefer the live position stream when it has advanced; fall back to
/// [playbackState.position] when the stream has not ticked yet (e.g. right
/// after load). When both are zero, use [cachedPosition] from the bloc cache
/// (e.g. hydrated history before the handler rebroadcasts).
Duration resolvePlaybackDisplayPosition({
  required PlaybackStateEntity? playbackState,
  required Duration streamPosition,
  Duration cachedPosition = Duration.zero,
  Duration trackDuration = Duration.zero,
}) {
  Duration resolved;
  if (streamPosition > Duration.zero) {
    resolved = streamPosition;
  } else if (playbackState != null && playbackState.position > Duration.zero) {
    resolved = playbackState.position;
  } else if (cachedPosition > Duration.zero) {
    resolved = cachedPosition;
  } else {
    return Duration.zero;
  }

  if (trackDuration <= Duration.zero || resolved <= trackDuration) {
    return resolved;
  }

  // Handler [updatePosition] can briefly carry the previous surah after a skip.
  if (streamPosition > Duration.zero && streamPosition <= trackDuration) {
    return streamPosition;
  }
  if (cachedPosition > Duration.zero && cachedPosition <= trackDuration) {
    return cachedPosition;
  }
  return Duration.zero;
}
