import 'package:audio_service/audio_service.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/entities/audio.dart';

/// Maps domain [AudioEntity] values to [MediaItem] for [audio_service].
@lazySingleton
class AudioEntityMediaItemMapper {
  const AudioEntityMediaItemMapper();

  MediaItem toMediaItem(AudioEntity entity) {
    return MediaItem(
      id: entity.id,
      title: entity.title,
      duration: entity.duration,
      artist: entity.artist,
      album: entity.album,
      artUri: entity.artUri != null ? Uri.parse(entity.artUri!) : null,
      extras: <String, dynamic>{'url': entity.url},
    );
  }
}
