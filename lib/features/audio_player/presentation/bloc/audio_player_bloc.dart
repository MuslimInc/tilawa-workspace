import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/entities/audio.dart';
import '../../../../shared/models/position_data.dart';
import '../../../../shared/models/queue_state.dart';
import '../../domain/entities/audio_modes.dart';
import '../../domain/usecases/audio_player_usecases.dart';
import '../../domain/usecases/get_audio_streams_use_case.dart';

part 'audio_player_bloc.freezed.dart';
part 'audio_player_event.dart';
part 'audio_player_state.dart';

@injectable
class AudioPlayerBloc extends HydratedBloc<AudioPlayerEvent, AudioPlayerState> {
  AudioPlayerBloc(
    this._getAudioStreams,
    this._playAudio,
    this._pauseAudio,
    this._stopAudio,
    this._seekTo,
    this._skipToNext,
    this._skipToPrevious,
    this._setVolume,
    this._setPlaybackSpeed,
    this._setRepeatMode,
    this._setShuffleMode,
    this._skipToQueueItem,
    this._playFromQueue,
    this._updateQueue,
    this._addQueueItem,
    this._removeQueueItem,
    this._moveQueueItem,
    this._loadAudioPlayerData,
  ) : super(const AudioPlayerState(status: AudioPlayerStatus.initial)) {
    // State update events
    on<LoadAudioPlayerData>(_onLoadAudioPlayerData);
    on<UpdateAudio>(_onUpdateAudio);
    on<UpdatePlaybackStateEntity>(_onUpdatePlaybackStateEntity);
    on<UpdatePositionData>(_onUpdatePositionData);
    on<UpdateVolume>(_onUpdateVolume);
    on<UpdateSpeed>(_onUpdateSpeed);

    // Audio control events
    on<PlayAudio>(_onPlayAudio);
    on<PauseAudio>(_onPauseAudio);
    on<StopAudio>(_onStopAudio);
    on<SkipToNext>(_onSkipToNext);
    on<SkipToPrevious>(_onSkipToPrevious);
    on<SeekTo>(_onSeekTo);
    on<SetVolume>(_onSetVolume);
    on<SetSpeed>(_onSetSpeed);
    on<SkipToQueueItem>(_onSkipToQueueItem);
    on<PlayFromQueue>(_onPlayFromQueue);
    on<UpdateQueue>(_onUpdateQueue);
    on<AddQueueItem>(_onAddQueueItem);
    on<RemoveQueueItem>(_onRemoveQueueItem);
    on<MoveQueueItem>(_onMoveQueueItem);
    on<SetRepeatMode>(_onSetRepeatMode);
    on<SetShuffleMode>(_onSetShuffleMode);

    _setupAudioStreams();
  }

  final GetAudioStreamsUseCase _getAudioStreams;
  final PlayAudioUseCase _playAudio;
  final PauseAudioUseCase _pauseAudio;
  final StopAudioUseCase _stopAudio;
  final SeekToUseCase _seekTo;
  final SkipToNextUseCase _skipToNext;
  final SkipToPreviousUseCase _skipToPrevious;
  final SetVolumeUseCase _setVolume;
  final SetPlaybackSpeedUseCase _setPlaybackSpeed;
  final SetRepeatModeUseCase _setRepeatMode;
  final SetShuffleModeUseCase _setShuffleMode;
  final SkipToQueueItemUseCase _skipToQueueItem;
  final PlayFromQueueUseCase _playFromQueue;
  final UpdateQueueUseCase _updateQueue;
  final AddQueueItemUseCase _addQueueItem;
  final RemoveQueueItemUseCase _removeQueueItem;
  final MoveQueueItemUseCase _moveQueueItem;
  final LoadAudioPlayerDataUseCase _loadAudioPlayerData;

  /// Stream subscriptions to be cancelled on close to prevent memory leaks.
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  void _setupAudioStreams() {
    _subscriptions.add(
      _getAudioStreams.currentAudio.listen((audio) {
        add(AudioPlayerEvent.updateAudio(audio));
      }),
    );

    _subscriptions.add(
      _getAudioStreams.playbackState.listen((playbackState) {
        add(AudioPlayerEvent.updatePlaybackStateEntity(playbackState));
      }),
    );

    _subscriptions.add(
      _getAudioStreams.volume.listen((volume) {
        add(AudioPlayerEvent.updateVolume(volume));
      }),
    );

    _subscriptions.add(
      _getAudioStreams.speed.listen((speed) {
        add(AudioPlayerEvent.updateSpeed(speed));
      }),
    );
  }

  @override
  Future<void> close() {
    for (final StreamSubscription<dynamic> subscription in _subscriptions) {
      subscription.cancel();
    }
    return super.close();
  }

  void _onUpdateAudio(UpdateAudio event, Emitter<AudioPlayerState> emit) {
    emit(
      state.copyWith(
        status: AudioPlayerStatus.success,
        currentAudio: event.audio,
      ),
    );
  }

  void _onUpdatePlaybackStateEntity(
    UpdatePlaybackStateEntity event,
    Emitter<AudioPlayerState> emit,
  ) {
    emit(
      state.copyWith(
        status: AudioPlayerStatus.success,
        playbackState: event.playbackState,
      ),
    );
  }

  void _onUpdatePositionData(
    UpdatePositionData event,
    Emitter<AudioPlayerState> emit,
  ) {
    emit(
      state.copyWith(
        status: AudioPlayerStatus.success,
        positionData: event.positionData,
      ),
    );
  }

  void _onUpdateVolume(UpdateVolume event, Emitter<AudioPlayerState> emit) {
    emit(
      state.copyWith(status: AudioPlayerStatus.success, volume: event.volume),
    );
  }

  void _onUpdateSpeed(UpdateSpeed event, Emitter<AudioPlayerState> emit) {
    emit(state.copyWith(status: AudioPlayerStatus.success, speed: event.speed));
  }

  // Control handlers
  Future<void> _onPlayAudio(
    PlayAudio event,
    Emitter<AudioPlayerState> emit,
  ) async {
    await _playAudio();
  }

  Future<void> _onPauseAudio(
    PauseAudio event,
    Emitter<AudioPlayerState> emit,
  ) async {
    await _pauseAudio();
  }

  Future<void> _onStopAudio(
    StopAudio event,
    Emitter<AudioPlayerState> emit,
  ) async {
    await _stopAudio();
  }

  Future<void> _onSkipToNext(
    SkipToNext event,
    Emitter<AudioPlayerState> emit,
  ) async {
    await _skipToNext();
  }

  Future<void> _onSkipToPrevious(
    SkipToPrevious event,
    Emitter<AudioPlayerState> emit,
  ) async {
    await _skipToPrevious();
  }

  Future<void> _onSeekTo(SeekTo event, Emitter<AudioPlayerState> emit) async {
    await _seekTo(event.position);
  }

  Future<void> _onSetVolume(
    SetVolume event,
    Emitter<AudioPlayerState> emit,
  ) async {
    await _setVolume(event.volume);
  }

  Future<void> _onSetSpeed(
    SetSpeed event,
    Emitter<AudioPlayerState> emit,
  ) async {
    await _setPlaybackSpeed(event.speed);
  }

  Future<void> _onSkipToQueueItem(
    SkipToQueueItem event,
    Emitter<AudioPlayerState> emit,
  ) async {
    await _skipToQueueItem(event.index);
  }

  Future<void> _onPlayFromQueue(
    PlayFromQueue event,
    Emitter<AudioPlayerState> emit,
  ) async {
    await _playFromQueue(event.queue, event.index);
  }

  Future<void> _onAddQueueItem(
    AddQueueItem event,
    Emitter<AudioPlayerState> emit,
  ) async {
    await _addQueueItem(event.audio);
  }

  Future<void> _onRemoveQueueItem(
    RemoveQueueItem event,
    Emitter<AudioPlayerState> emit,
  ) async {
    await _removeQueueItem(event.audio);
  }

  Future<void> _onMoveQueueItem(
    MoveQueueItem event,
    Emitter<AudioPlayerState> emit,
  ) async {
    await _moveQueueItem(event.currentIndex, event.newIndex);
  }

  Future<void> _onSetRepeatMode(
    SetRepeatMode event,
    Emitter<AudioPlayerState> emit,
  ) async {
    await _setRepeatMode(event.repeatMode);
    emit(state.copyWith(repeatMode: event.repeatMode));
  }

  Future<void> _onSetShuffleMode(
    SetShuffleMode event,
    Emitter<AudioPlayerState> emit,
  ) async {
    await _setShuffleMode(event.shuffleMode);
    emit(state.copyWith(shuffleMode: event.shuffleMode));
  }

  Future<void> _onLoadAudioPlayerData(
    LoadAudioPlayerData event,
    Emitter<AudioPlayerState> emit,
  ) async {
    emit(state.copyWith(status: AudioPlayerStatus.loading));
    await _loadAudioPlayerData(restorePlayback: event.restorePlayback);
    emit(state.copyWith(status: AudioPlayerStatus.success));
  }

  Future<void> _onUpdateQueue(
    UpdateQueue event,
    Emitter<AudioPlayerState> emit,
  ) async {
    await _updateQueue(event.queue);
  }

  @override
  AudioPlayerState? fromJson(Map<String, dynamic> json) {
    // Hydration logic can stay here or be moved to a repository if it involves complex data
    return null; // Simplified for now
  }

  @override
  Map<String, dynamic>? toJson(AudioPlayerState state) {
    return null; // Simplified for now
  }
}
