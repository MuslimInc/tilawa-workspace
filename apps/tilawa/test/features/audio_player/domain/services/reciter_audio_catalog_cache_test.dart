import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/audio_player/domain/services/reciter_audio_catalog_builder.dart';
import 'package:tilawa/features/audio_player/domain/services/reciter_audio_catalog_cache.dart';
import 'package:tilawa/features/reciters/domain/repositories/reciters_repository.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_core/entities/moshaf_entity.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';

import 'reciter_audio_catalog_cache_test.mocks.dart';

@GenerateMocks([RecitersRepository])
void main() {
  provideDummy<Either<Failure, List<ReciterEntity>>>(
    const Right<Failure, List<ReciterEntity>>(<ReciterEntity>[]),
  );

  late MockRecitersRepository mockRepository;
  late ReciterAudioCatalogCache cache;

  const ReciterEntity sampleReciter = ReciterEntity(
    id: 1,
    name: 'Sample',
    letter: 'S',
    date: '2020',
    moshaf: <MoshafEntity>[
      MoshafEntity(
        id: 1,
        name: 'Hafs',
        server: 'https://cdn.example.com/',
        surahList: '1',
        surahTotal: 1,
        moshafType: 1,
      ),
    ],
  );

  setUp(() {
    mockRepository = MockRecitersRepository();
    cache = ReciterAudioCatalogCache(
      mockRepository,
      const ReciterAudioCatalogBuilder(),
    );
    when(mockRepository.getReciters()).thenAnswer(
      (_) async => const Right<Failure, List<ReciterEntity>>(<ReciterEntity>[
        sampleReciter,
      ]),
    );
  });

  test('loadTracks caches catalog and returns tracks', () async {
    final List<AudioEntity>? first = await cache.loadTracks();
    final List<AudioEntity>? second = await cache.loadTracks();

    expect(first, isNotNull);
    expect(second, same(first));
    expect(cache.catalog, isNotNull);
    verify(mockRepository.getReciters()).called(1);
  });

  test('bindRepository clears cache and uses new repository', () async {
    final MockRecitersRepository firstRepository = MockRecitersRepository();
    final MockRecitersRepository secondRepository = MockRecitersRepository();
    when(firstRepository.getReciters()).thenAnswer(
      (_) async => const Right<Failure, List<ReciterEntity>>(<ReciterEntity>[
        sampleReciter,
      ]),
    );
    when(secondRepository.getReciters()).thenAnswer(
      (_) async => const Right<Failure, List<ReciterEntity>>(<ReciterEntity>[]),
    );

    final ReciterAudioCatalogCache localCache = ReciterAudioCatalogCache(
      firstRepository,
      const ReciterAudioCatalogBuilder(),
    );
    await localCache.loadTracks();

    localCache.bindRepository(secondRepository);
    final List<AudioEntity>? tracks = await localCache.loadTracks();

    expect(tracks, isEmpty);
    verify(firstRepository.getReciters()).called(1);
    verify(secondRepository.getReciters()).called(1);
  });
}
