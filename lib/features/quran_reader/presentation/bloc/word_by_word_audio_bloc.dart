import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:just_audio/just_audio.dart';

part 'word_by_word_audio_bloc.freezed.dart';

@freezed
class WordByWordAudioEvent with _$WordByWordAudioEvent {
  const factory WordByWordAudioEvent.playWord(String url, int wordId) =
      _PlayWord;
  const factory WordByWordAudioEvent.stopAudio() = _StopAudio;
  const factory WordByWordAudioEvent.playerStateChanged(
    PlayerState playerState,
  ) = _PlayerStateChanged;
}

@freezed
abstract class WordByWordAudioState with _$WordByWordAudioState {
  const factory WordByWordAudioState({
    int? playingWordId,
    @Default(false) bool isPlaying,
  }) = _WordByWordAudioState;
}

@injectable
class WordByWordAudioBloc
    extends Bloc<WordByWordAudioEvent, WordByWordAudioState> {
  WordByWordAudioBloc() : super(const WordByWordAudioState()) {
    on<_PlayWord>(_onPlayWord);
    on<_StopAudio>(_onStopAudio);
    on<_PlayerStateChanged>(_onPlayerStateChanged);

    // Listen to player state changes
    _globalPlayer.playerStateStream.listen((playerState) {
      if (!isClosed) {
        add(WordByWordAudioEvent.playerStateChanged(playerState));
      }
    });
  }
  // Using a static player to ensure only one audio plays at a time globally for this feature
  static final AudioPlayer _globalPlayer = AudioPlayer();

  Future<void> _onPlayWord(
    _PlayWord event,
    Emitter<WordByWordAudioState> emit,
  ) async {
    if (state.playingWordId == event.wordId && state.isPlaying) {
      add(const WordByWordAudioEvent.stopAudio());
      return;
    }

    try {
      await _globalPlayer.stop();
      emit(state.copyWith(playingWordId: event.wordId, isPlaying: true));

      final fullUrl = 'https://audio.qurancdn.com/${event.url}';
      await _globalPlayer.setUrl(fullUrl);
      await _globalPlayer.play();
    } catch (e) {
      emit(state.copyWith(playingWordId: null, isPlaying: false));
    }
  }

  Future<void> _onStopAudio(
    _StopAudio event,
    Emitter<WordByWordAudioState> emit,
  ) async {
    await _globalPlayer.stop();
    emit(state.copyWith(playingWordId: null, isPlaying: false));
  }

  void _onPlayerStateChanged(
    _PlayerStateChanged event,
    Emitter<WordByWordAudioState> emit,
  ) {
    if (event.playerState.processingState == ProcessingState.completed) {
      emit(state.copyWith(playingWordId: null, isPlaying: false));
    }
  }

  @override
  Future<void> close() {
    // We do NOT dispose the static player here as it might be used by other instances of the Bloc
    // or we might want to keep it ready. If we wanted to dispose it, we'd need a robust lifecycle management.
    // For now, mirroring the controller behavior.
    return super.close();
  }
}
