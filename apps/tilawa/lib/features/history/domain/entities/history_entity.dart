import 'package:freezed_annotation/freezed_annotation.dart';

part 'history_entity.freezed.dart';
part 'history_entity.g.dart';

/// Represents a listening history entry
@freezed
abstract class HistoryEntity with _$HistoryEntity {
  const factory HistoryEntity({
    /// Unique identifier for the history entry
    required String id,

    /// Surah number (1-114)
    required int surahId,

    /// Surah name in Arabic
    required String surahName,

    /// Surah name in English
    required String surahNameEn,

    /// Reciter ID
    required String reciterId,

    /// Reciter name
    required String reciterName,

    /// Moshaf ID
    required int moshafId,

    /// Moshaf name
    required String moshafName,

    /// Last played position in milliseconds
    required int lastPositionMs,

    /// Total duration of the audio in milliseconds
    required int durationMs,

    /// Audio URL for playback
    required String audioUrl,

    /// Artwork URL
    String? artworkUrl,

    /// Timestamp when last played
    required DateTime playedAt,

    /// Whether the surah was completed
    @Default(false) bool completed,

    /// Number of times played
    @Default(1) int playCount,
  }) = _HistoryEntity;

  const HistoryEntity._();

  factory HistoryEntity.fromJson(Map<String, dynamic> json) =>
      _$HistoryEntityFromJson(json);

  /// Get last position as Duration
  Duration get lastPosition => Duration(milliseconds: lastPositionMs);

  /// Get duration as Duration
  Duration get duration => Duration(milliseconds: durationMs);

  /// Get progress percentage (0.0 - 1.0)
  double get progress => durationMs > 0 ? lastPositionMs / durationMs : 0.0;

  /// Get progress percentage (0 - 100)
  double get progressPercentage => progress * 100;

  /// Get formatted last position string (mm:ss or hh:mm:ss)
  String get formattedLastPosition => _formatDuration(lastPosition);

  /// Get formatted duration string (mm:ss or hh:mm:ss)
  String get formattedDuration => _formatDuration(duration);

  /// Get simple formatted played at time
  String get formattedPlayedAt {
    final Duration difference = DateTime.now().difference(playedAt);
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${playedAt.day}/${playedAt.month}/${playedAt.year}';
    }
  }

  /// Get formatted played time (e.g., "Today", "Yesterday", "2 days ago")
  String getFormattedPlayedAt(String Function(String) localizer) {
    final now = DateTime.now();
    final Duration difference = now.difference(playedAt);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return localizer('justNow');
        }
        return localizer(
          'minutesAgo',
        ).replaceAll('{count}', difference.inMinutes.toString());
      }
      return localizer(
        'hoursAgo',
      ).replaceAll('{count}', difference.inHours.toString());
    } else if (difference.inDays == 1) {
      return localizer('yesterday');
    } else if (difference.inDays < 7) {
      return localizer(
        'daysAgo',
      ).replaceAll('{count}', difference.inDays.toString());
    } else {
      // Format as date
      return '${playedAt.day}/${playedAt.month}/${playedAt.year}';
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    final String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
    }
    return '$twoDigitMinutes:$twoDigitSeconds';
  }
}
