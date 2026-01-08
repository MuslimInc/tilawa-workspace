import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/quran_reader/presentation/bloc/word_by_word_audio_bloc.dart';

class MockAudioPlayer extends Mock implements AudioPlayer {}

void main() {
  late MockAudioPlayer mockPlayer;
  late WordByWordAudioBloc bloc;
  late StreamController<PlayerState> playerStateController;

  setUpAll(() {
    registerFallbackValue(PlayerState(false, ProcessingState.idle));
  });

  setUp(() {
    mockPlayer = MockAudioPlayer();
    playerStateController = StreamController<PlayerState>.broadcast();

    when(
      () => mockPlayer.playerStateStream,
    ).thenAnswer((_) => playerStateController.stream);
    when(() => mockPlayer.stop()).thenAnswer((_) async {});
    when(() => mockPlayer.setUrl(any())).thenAnswer((_) async => null);
    when(() => mockPlayer.play()).thenAnswer((_) async {});

    bloc = WordByWordAudioBloc(player: mockPlayer);
  });

  tearDown(() {
    playerStateController.close();
    bloc.close();
  });

  group('WordByWordAudioBloc', () {
    test('initial state should be empty', () {
      expect(bloc.state.playingWordId, isNull);
      expect(bloc.state.isPlaying, isFalse);
    });

    blocTest<WordByWordAudioBloc, WordByWordAudioState>(
      'emits [playingWordId, isPlaying: true] when playWord is added',
      build: () => bloc,
      act: (bloc) =>
          bloc.add(const WordByWordAudioEvent.playWord('audio.mp3', 1)),
      expect: () => [
        const WordByWordAudioState(playingWordId: 1, isPlaying: true),
      ],
      verify: (_) {
        verify(() => mockPlayer.stop()).called(1);
        verify(() => mockPlayer.setUrl(any())).called(1);
        verify(() => mockPlayer.play()).called(1);
      },
    );

    blocTest<WordByWordAudioBloc, WordByWordAudioState>(
      'stops audio and clears state when playWord is called for already playing word',
      build: () => bloc,
      seed: () => const WordByWordAudioState(playingWordId: 1, isPlaying: true),
      act: (bloc) =>
          bloc.add(const WordByWordAudioEvent.playWord('audio.mp3', 1)),
      expect: () => [const WordByWordAudioState()],
      verify: (_) {
        verify(() => mockPlayer.stop()).called(1);
      },
    );

    blocTest<WordByWordAudioBloc, WordByWordAudioState>(
      'emits [null, isPlaying: false] when stopAudio is added',
      build: () => bloc,
      seed: () => const WordByWordAudioState(playingWordId: 1, isPlaying: true),
      act: (bloc) => bloc.add(const WordByWordAudioEvent.stopAudio()),
      expect: () => [const WordByWordAudioState()],
      verify: (_) {
        verify(() => mockPlayer.stop()).called(1);
      },
    );

    blocTest<WordByWordAudioBloc, WordByWordAudioState>(
      'clears playing state when player state changes to completed',
      build: () => bloc,
      seed: () => const WordByWordAudioState(playingWordId: 1, isPlaying: true),
      act: (bloc) {
        playerStateController.add(
          PlayerState(false, ProcessingState.completed),
        );
      },
      expect: () => [const WordByWordAudioState()],
    );

    blocTest<WordByWordAudioBloc, WordByWordAudioState>(
      'handles error during playback by clearing state',
      build: () {
        when(
          () => mockPlayer.setUrl(any()),
        ).thenThrow(Exception('Playback error'));
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const WordByWordAudioEvent.playWord('audio.mp3', 1)),
      expect: () => [
        const WordByWordAudioState(playingWordId: 1, isPlaying: true),
        const WordByWordAudioState(),
      ],
    );
  });
}
