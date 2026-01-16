import 'package:freezed_annotation/freezed_annotation.dart';

part 'bookmark_entity.freezed.dart';
part 'bookmark_entity.g.dart';

/// Represents a bookmark for a specific position in a surah
@freezed
abstract class BookmarkEntity with _$BookmarkEntity {
  const factory BookmarkEntity({
    /// Unique identifier for the bookmark
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

    /// Position in the audio (milliseconds)
    required int positionMs,

    /// Total duration of the audio (milliseconds)
    required int durationMs,

    /// Audio URL for playback
    required String audioUrl,

    /// Optional label/note for the bookmark
    String? label,

    /// Artwork URL
    String? artworkUrl,

    /// Creation timestamp
    required DateTime createdAt,

    /// Last updated timestamp
    required DateTime updatedAt,
  }) = _BookmarkEntity;

  const BookmarkEntity._();

  factory BookmarkEntity.fromJson(Map<String, dynamic> json) =>
      _$BookmarkEntityFromJson(json);

  /// Get position as Duration
  Duration get position => Duration(milliseconds: positionMs);

  /// Get duration as Duration
  Duration get duration => Duration(milliseconds: durationMs);

  /// Get progress percentage (0.0 - 1.0)
  double get progress => durationMs > 0 ? positionMs / durationMs : 0.0;

  /// Get formatted position string (mm:ss or hh:mm:ss)
  String get formattedPosition => _formatDuration(position);

  /// Get formatted duration string (mm:ss or hh:mm:ss)
  String get formattedDuration => _formatDuration(duration);

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
