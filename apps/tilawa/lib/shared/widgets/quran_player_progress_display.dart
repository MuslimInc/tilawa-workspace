import '../models/position_data.dart';

/// Elapsed and remaining labels for the expanded player progress row.
class PlayerProgressTimes {
  const PlayerProgressTimes({
    required this.elapsed,
    required this.remainingLabel,
  });

  final Duration elapsed;
  final String remainingLabel;
}

PlayerProgressTimes resolvePlayerProgressTimes(PositionData data) {
  final Duration duration = data.duration;
  Duration elapsed = data.position;
  if (duration > Duration.zero && data.position > duration) {
    elapsed = duration;
  }
  if (duration <= Duration.zero) {
    return PlayerProgressTimes(
      elapsed: elapsed,
      remainingLabel: formatPlayerDuration(Duration.zero),
    );
  }
  final Duration remaining = duration - elapsed;
  final Duration safeRemaining = remaining.isNegative
      ? Duration.zero
      : remaining;
  return PlayerProgressTimes(
    elapsed: elapsed,
    remainingLabel: '−${formatPlayerDuration(safeRemaining)}',
  );
}

String formatPlayerDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  final String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  if (duration.inHours > 0) {
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }
  return '$twoDigitMinutes:$twoDigitSeconds';
}
