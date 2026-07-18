import 'package:audio_service/audio_service.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_core/entities/audio_extras_keys.dart';

/// Maps domain [AudioEntity] values to [MediaItem] for [audio_service].
@lazySingleton
class AudioEntityMediaItemMapper {
  const AudioEntityMediaItemMapper();

  MediaItem toMediaItem(AudioEntity entity) {
    final bool isLive =
        entity.extras?[AudioExtrasKeys.live] == true ||
        entity.extras?[AudioExtrasKeys.source] == AudioExtrasKeys.sourceRadio ||
        entity.id.startsWith('radio:');
    final Map<String, dynamic> extras = <String, dynamic>{
      'url': entity.url,
      ...?entity.extras,
    };
    return MediaItem(
      id: entity.id,
      title: entity.title,
      // Null duration marks live streams for lock-screen / notification.
      duration: isLive ? null : entity.duration,
      artist: entity.artist,
      album: entity.album,
      artUri: entity.artUri != null ? Uri.parse(entity.artUri!) : null,
      extras: extras,
    );
  }
}
