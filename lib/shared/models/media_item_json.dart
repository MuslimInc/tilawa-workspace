import 'package:audio_service/audio_service.dart';

/// Helper functions to serialize and deserialize MediaItem to/from JSON
/// MediaItem from audio_service package doesn't include JSON serialization
class MediaItemJson {
  /// Converts a MediaItem to a JSON map
  static Map<String, dynamic> toJson(MediaItem item) {
    return {
      'id': item.id,
      'title': item.title,
      'artist': item.artist,
      'album': item.album,
      'duration': item.duration?.inMilliseconds,
      'artUri': item.artUri?.toString(),
      'displayTitle': item.displayTitle,
      'displaySubtitle': item.displaySubtitle,
      'displayDescription': item.displayDescription,
    };
  }

  /// Creates a MediaItem from a JSON map
  static MediaItem fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String?,
      album: json['album'] as String?,
      duration: json['duration'] != null
          ? Duration(milliseconds: json['duration'] as int)
          : null,
      artUri: json['artUri'] != null
          ? Uri.parse(json['artUri'] as String)
          : null,
      displayTitle: json['displayTitle'] as String?,
      displaySubtitle: json['displaySubtitle'] as String?,
      displayDescription: json['displayDescription'] as String?,
    );
  }

  /// Converts a list of MediaItems to JSON
  static List<Map<String, dynamic>> toJsonList(List<MediaItem> items) {
    return items.map(toJson).toList();
  }

  /// Creates a list of MediaItems from JSON
  static List<MediaItem> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((json) => fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
