import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa/features/audio_player/domain/repositories/audio_player_repository.dart';
import 'package:tilawa/features/audio_player/domain/usecases/get_audio_streams_use_case.dart';

import 'get_audio_streams_use_case_test.mocks.dart';

@GenerateMocks([AudioPlayerRepository])
void main() {
  late GetAudioStreamsUseCase useCase;
  late MockAudioPlayerRepository mockRepository;

  setUp(() {
    mockRepository = MockAudioPlayerRepository();
    useCase = GetAudioStreamsUseCase(mockRepository);
  });

  group('GetAudioStreamsUseCase', () {
    test('exposes playbackState stream from repository', () {
      const state = PlaybackStateEntity(
        isPlaying: false,
        processingState: AudioProcessingStateStatus.idle,
        position: Duration.zero,
        bufferedPosition: Duration.zero,
        duration: Duration.zero,
        currentIndex: 0,
        queue: [],
      );
      final stream = Stream<PlaybackStateEntity>.value(state);
      when(mockRepository.playbackState).thenAnswer((_) => stream);

      expect(useCase.playbackState, same(stream));
    });

    test('exposes currentAudio stream from repository', () {
      final stream = Stream<AudioEntity?>.value(null);
      when(mockRepository.currentAudio).thenAnswer((_) => stream);

      expect(useCase.currentAudio, same(stream));
    });

    test('exposes queue stream from repository', () {
      final stream = Stream<List<AudioEntity>>.value(const []);
      when(mockRepository.queue).thenAnswer((_) => stream);

      expect(useCase.queue, same(stream));
    });

    test('exposes volume, speed, and position streams from repository', () {
      final volume = Stream<double>.value(0.8);
      final speed = Stream<double>.value(1.0);
      final position = Stream<Duration>.value(const Duration(seconds: 5));
      when(mockRepository.volume).thenAnswer((_) => volume);
      when(mockRepository.speed).thenAnswer((_) => speed);
      when(mockRepository.position).thenAnswer((_) => position);

      expect(useCase.volume, same(volume));
      expect(useCase.speed, same(speed));
      expect(useCase.position, same(position));
    });
  });
}
