import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/audio_player/domain/entities/reciter_audio_catalog.dart';
import 'package:tilawa/features/audio_player/domain/services/reciter_audio_catalog_builder.dart';
import 'package:tilawa_core/entities/moshaf_entity.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';

void main() {
  const ReciterAudioCatalogBuilder builder = ReciterAudioCatalogBuilder();

  test('builds tracks and O(1) artist index in one pass', () {
    const ReciterEntity reciter = ReciterEntity(
      id: 1,
      name: 'Test Reciter',
      letter: 'T',
      date: '2020',
      moshaf: <MoshafEntity>[
        MoshafEntity(
          id: 10,
          name: 'Hafs',
          server: 'https://cdn.example.com/',
          surahList: '1,2',
          surahTotal: 2,
          moshafType: 1,
        ),
      ],
    );

    final ReciterAudioCatalog catalog = builder.build(<ReciterEntity>[reciter]);

    expect(catalog.tracks, hasLength(2));
    expect(catalog.tracksForArtist('Test Reciter'), hasLength(2));
    expect(catalog.tracksForArtist('Unknown'), isEmpty);
    expect(catalog.reciterNamed('test reciter'), reciter);
    expect(catalog.reciterNamed('Unknown'), isNull);
    expect(
      identical(
        catalog.tracksForArtist('Test Reciter').first,
        catalog.tracks.first,
      ),
      isTrue,
    );
  });

  test('attaches portrait artUri for mapped reciters', () {
    const ReciterEntity reciter = ReciterEntity(
      id: 51,
      name: 'Abdulbasit Abdulsamad',
      letter: 'A',
      date: '2020',
      moshaf: <MoshafEntity>[
        MoshafEntity(
          id: 10,
          name: 'Hafs',
          server: 'https://cdn.example.com/',
          surahList: '1',
          surahTotal: 1,
          moshafType: 1,
        ),
      ],
    );

    final ReciterAudioCatalog catalog = builder.build(<ReciterEntity>[reciter]);

    expect(catalog.tracks, hasLength(1));
    expect(
      catalog.tracks.single.artUri,
      startsWith('https://tvquran.com/uploads/authors/images/'),
    );
  });

  test('skips invalid constructed URLs', () {
    const ReciterEntity reciter = ReciterEntity(
      id: 1,
      name: 'Bad',
      letter: 'B',
      date: '2020',
      moshaf: <MoshafEntity>[
        MoshafEntity(
          id: 10,
          name: 'Hafs',
          server: 'not a url',
          surahList: '1',
          surahTotal: 1,
          moshafType: 1,
        ),
      ],
    );

    final ReciterAudioCatalog catalog = builder.build(<ReciterEntity>[reciter]);

    expect(catalog.tracks, isEmpty);
    expect(catalog.byArtist, isEmpty);
  });
}
