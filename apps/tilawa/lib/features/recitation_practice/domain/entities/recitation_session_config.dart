/// Tunables for hands-free recitation sessions.
class RecitationSessionConfig {
  const RecitationSessionConfig({
    this.passScoreThreshold = 0.8,
    this.verseAdvanceDelay = const Duration(milliseconds: 700),
    this.retryDelay = const Duration(milliseconds: 900),
  });

  /// Minimum match score to auto-advance to the next ayah.
  final double passScoreThreshold;

  /// Pause after a passed ayah before moving on.
  final Duration verseAdvanceDelay;

  /// Pause before re-listening after a failed attempt.
  final Duration retryDelay;

  static const RecitationSessionConfig defaults = RecitationSessionConfig();
}
