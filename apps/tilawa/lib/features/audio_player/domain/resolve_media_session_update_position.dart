/// Resolves the position sent to [audio_service] / Android MediaSession.
///
/// The in-app player reads [PlaybackStateEntity.position] and the live
/// position stream. Android uses [PlaybackState.updatePosition] (and extrapolates
/// while playing). A transient engine position of zero after resume must not
/// overwrite a valid paused position.
Duration resolveMediaSessionUpdatePosition({
  required Duration enginePosition,
  required Duration previousUpdatePosition,
  required bool playing,
  required bool engineReady,
}) {
  if (enginePosition > Duration.zero) {
    return enginePosition;
  }
  if (!playing && previousUpdatePosition > Duration.zero) {
    return previousUpdatePosition;
  }
  if (playing &&
      engineReady &&
      previousUpdatePosition > const Duration(minutes: 1)) {
    return previousUpdatePosition;
  }
  return enginePosition;
}
