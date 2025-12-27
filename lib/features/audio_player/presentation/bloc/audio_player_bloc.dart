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
part 'audio_player_bloc.g.dart';
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

    // Sleep Timer events
    on<SetSleepTimer>(_onSetSleepTimer);
    on<CancelSleepTimer>(_onCancelSleepTimer);
    on<AudioTimerExpired>(_onAudioTimerExpired);

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
  Timer? _sleepTimer;

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

    _subscriptions.add(
      _getAudioStreams.position.listen((position) {
        final AudioEntity? currentAudio = state.currentAudio;
        final PlaybackStateEntity? playbackState = state.playbackState;
        final Duration duration = currentAudio?.duration ?? Duration.zero;
        final Duration buffered =
            playbackState?.bufferedPosition ?? Duration.zero;

        add(
          AudioPlayerEvent.updatePositionData(
            PositionData(
              position: position,
              bufferedPosition: buffered,
              duration: duration,
            ),
          ),
        );
      }),
    );
  }

  @override
  Future<void> close() {
    _sleepTimer?.cancel();
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

    // After loading/restoring playback, check if we had a sleep timer
    if (state.sleepTimerTargetTime != null) {
      final now = DateTime.now();
      if (state.sleepTimerTargetTime!.isAfter(now)) {
        final Duration remaining = state.sleepTimerTargetTime!.difference(now);
        _sleepTimer?.cancel();
        _sleepTimer = Timer(remaining, () {
          add(const AudioPlayerEvent.audioTimerExpired());
        });
      } else {
        // Timer already expired while app was closed
        add(const AudioPlayerEvent.audioTimerExpired());
      }
    }

    emit(state.copyWith(status: AudioPlayerStatus.success));
  }

  Future<void> _onUpdateQueue(
    UpdateQueue event,
    Emitter<AudioPlayerState> emit,
  ) async {
    await _updateQueue(event.queue);
  }

  void _onSetSleepTimer(SetSleepTimer event, Emitter<AudioPlayerState> emit) {
    _sleepTimer?.cancel();
    _sleepTimer = Timer(event.duration, () {
      add(const AudioPlayerEvent.audioTimerExpired());
    });
    emit(
      state.copyWith(
        sleepTimerTargetTime: DateTime.now().add(event.duration),
        lastSleepTimerDuration: event.duration,
        status: AudioPlayerStatus.success,
      ),
    );
  }

  void _onCancelSleepTimer(
    CancelSleepTimer event,
    Emitter<AudioPlayerState> emit,
  ) {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    emit(
      state.copyWith(
        sleepTimerTargetTime: null,
        lastSleepTimerDuration: null,
        status: AudioPlayerStatus.success,
      ),
    );
  }

  Future<void> _onAudioTimerExpired(
    AudioTimerExpired event,
    Emitter<AudioPlayerState> emit,
  ) async {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    await _pauseAudio();
    emit(
      state.copyWith(
        sleepTimerTargetTime: null,
        lastSleepTimerDuration: null,
        status: AudioPlayerStatus.success,
      ),
    );
  }

  @override
  AudioPlayerState? fromJson(Map<String, dynamic> json) {
    return AudioPlayerState.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(AudioPlayerState state) {
    return state.toJson();
  }
}
