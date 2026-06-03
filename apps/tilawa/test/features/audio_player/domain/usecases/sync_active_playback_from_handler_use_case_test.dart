import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/audio_player/domain/entities/active_playback_snapshot.dart';
import 'package:tilawa/features/audio_player/domain/repositories/audio_player_repository.dart';
import 'package:tilawa/features/audio_player/domain/usecases/sync_active_playback_from_handler_use_case.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_core/errors/failures.dart';

import 'sync_active_playback_from_handler_use_case_test.mocks.dart';

@GenerateMocks([AudioPlayerRepository])
void main() {
  late MockAudioPlayerRepository repository;
  late SyncActivePlaybackFromHandlerUseCase useCase;

  const AudioEntity surahBaqarah = AudioEntity(
    id: '2',
    title: 'Al-Baqarah',
    url: 'https://example.com/2.mp3',
    duration: Duration(hours: 1),
    artist: 'Akram Al-Alaqmi',
  );

  final PlaybackStateEntity playingState = PlaybackStateEntity(
    isPlaying: true,
    processingState: AudioProcessingStateStatus.ready,
    position: const Duration(minutes: 2),
    bufferedPosition: const Duration(minutes: 5),
    duration: const Duration(hours: 1),
    currentIndex: 0,
    queue: <AudioEntity>[surahBaqarah],
    queueGeneration: 1,
  );

  setUp(() {
    repository = MockAudioPlayerRepository();
    useCase = SyncActivePlaybackFromHandlerUseCase(repository);
  });

  test('returns null when handler has no media item', () async {
    when(repository.readActivePlaybackSnapshot()).thenReturn(null);

    final Either<Failure, ActivePlaybackSnapshot?> result = await useCase();

    expect(result.isRight, isTrue);
    result.fold((_) => fail('expected Right'), (value) => expect(value, isNull));
    verify(repository.readActivePlaybackSnapshot()).called(1);
  });

  test('returns handler snapshot when session is active', () async {
    final ActivePlaybackSnapshot snapshot = ActivePlaybackSnapshot(
      currentAudio: surahBaqarah,
      playbackState: playingState,
    );
    when(repository.readActivePlaybackSnapshot()).thenReturn(snapshot);

    final Either<Failure, ActivePlaybackSnapshot?> result = await useCase();

    expect(result.isRight, isTrue);
    result.fold(
      (_) => fail('expected Right'),
      (value) => expect(value, snapshot),
    );
  });
}
