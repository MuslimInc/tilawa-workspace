import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa/features/audio_player/domain/repositories/audio_player_repository.dart';
import 'package:tilawa/features/audio_player/domain/usecases/get_playback_state_use_case.dart';

import 'get_playback_state_use_case_test.mocks.dart';

@GenerateMocks([AudioPlayerRepository])
void main() {
  late GetPlaybackStateUseCase useCase;
  late MockAudioPlayerRepository mockRepository;

  setUp(() {
    mockRepository = MockAudioPlayerRepository();
    useCase = GetPlaybackStateUseCase(mockRepository);
  });

  group('GetPlaybackStateUseCase', () {
    test('returns the current playback state wrapped in Right', () async {
      const state = PlaybackStateEntity(
        isPlaying: true,
        processingState: AudioProcessingStateStatus.ready,
        position: Duration(seconds: 12),
        bufferedPosition: Duration(seconds: 30),
        duration: Duration(seconds: 95),
        currentIndex: 0,
        queue: [],
      );
      when(mockRepository.getPlaybackState).thenReturn(state);

      final result = await useCase();

      result.fold(
        (_) => fail('Expected Right result'),
        (s) {
          expect(s.isPlaying, isTrue);
          expect(s.position, const Duration(seconds: 12));
          expect(s.currentIndex, 0);
        },
      );
      verify(mockRepository.getPlaybackState).called(1);
    });
  });
}
