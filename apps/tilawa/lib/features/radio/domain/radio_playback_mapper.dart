import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_core/entities/audio_extras_keys.dart';

import 'entities/radio_station.dart';

/// Maps a [RadioStation] to [AudioEntity] for the shared audio player.
abstract final class RadioPlaybackMapper {
  static AudioEntity toAudioEntity(RadioStation station) {
    return AudioEntity(
      id: station.audioId,
      title: station.name,
      url: station.streamUrl,
      duration: Duration.zero,
      artist: 'Islamic Radio',
      extras: <String, dynamic>{
        AudioExtrasKeys.source: AudioExtrasKeys.sourceRadio,
        AudioExtrasKeys.live: true,
        AudioExtrasKeys.stationId: station.id,
      },
    );
  }

  static bool isRadioAudio(AudioEntity? audio) {
    if (audio == null) return false;
    return audio.extras?[AudioExtrasKeys.source] ==
            AudioExtrasKeys.sourceRadio ||
        audio.id.startsWith('radio:');
  }

  static String? stationIdFromAudio(AudioEntity? audio) {
    if (audio == null) return null;
    final String? fromExtras = audio.extras.getString(
      AudioExtrasKeys.stationId,
    );
    if (fromExtras != null && fromExtras.isNotEmpty) return fromExtras;
    if (audio.id.startsWith('radio:')) {
      return audio.id.substring('radio:'.length);
    }
    return null;
  }
}
