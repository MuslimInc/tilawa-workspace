/// Tunables for hands-free recitation sessions.
class RecitationSessionConfig {
  const RecitationSessionConfig({
    this.passScoreThreshold = 0.8,
    this.verseAdvanceDelay = const Duration(milliseconds: 700),
    this.retryDelay = const Duration(milliseconds: 900),
    this.asrCatchUpDelay = const Duration(milliseconds: 900),
    this.asrIdleBeforeFail = const Duration(milliseconds: 2800),
    this.shortAyahIdleBeforeFail = const Duration(milliseconds: 4500),
    this.catchUpScoreFloor = 0.65,
    this.allowSkipAhead = false,
  });

  /// Minimum match score to auto-advance to the next ayah.
  final double passScoreThreshold;

  /// Pause after a passed ayah before moving on.
  final Duration verseAdvanceDelay;

  /// Pause before re-listening after a failed attempt.
  final Duration retryDelay;

  /// Wait after the last ASR update before judging an ayah so lagging
  /// partials can catch up with fast recitation.
  final Duration asrCatchUpDelay;

  /// Start the catch-up window once the live score reaches this value.
  final double catchUpScoreFloor;

  /// Silence window before failing an ayah when the score is still low.
  ///
  /// Micro-session [isFinal] events from Android must not trigger an immediate
  /// retry while the user is still reciting.
  final Duration asrIdleBeforeFail;

  /// Extra silence tolerance for 1–3 word ayahs stuck at partial match.
  final Duration shortAyahIdleBeforeFail;

  /// When false, every ayah must pass verification before advancing.
  final bool allowSkipAhead;

  static const RecitationSessionConfig defaults = RecitationSessionConfig();
}
