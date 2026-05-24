import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/audio_player/domain/entities/reciter_audio_catalog.dart';
import 'package:tilawa/features/audio_player/domain/services/artist_playlist_builder.dart';
import 'package:tilawa_core/entities/audio.dart';

void main() {
  const ArtistPlaylistBuilder playlistBuilder = ArtistPlaylistBuilder();

  test('playlistForArtist uses catalog index in O(1)', () {
    final AudioEntity a = AudioEntity(
      id: '1',
      title: 'Al-Fatiha',
      url: 'https://cdn.example.com/001.mp3',
      duration: Duration.zero,
      artist: 'Reciter A',
    );
    final AudioEntity b = AudioEntity(
      id: '2',
      title: 'Al-Baqarah',
      url: 'https://cdn.example.com/002.mp3',
      duration: Duration.zero,
      artist: 'Reciter B',
    );
    final ReciterAudioCatalog catalog = ReciterAudioCatalog(
      tracks: <AudioEntity>[a, b],
      byArtist: <String, List<AudioEntity>>{
        'Reciter A': <AudioEntity>[a],
        'Reciter B': <AudioEntity>[b],
      },
    );

    expect(playlistBuilder.playlistForArtist(catalog, 'Reciter A'), <AudioEntity>[a]);
    expect(playlistBuilder.playlistForArtist(catalog, 'Missing'), isEmpty);
  });
}
