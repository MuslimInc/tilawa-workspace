import 'dart:async';

import 'package:dartz_plus/dartz_plus.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/core/utils/toast_utils.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/services/analytics_service.dart';

import '../../../../shared/models/position_data.dart';
import '../../../../shared/models/queue_state.dart';
import '../../../history/domain/usecases/add_or_update_history_use_case.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../domain/entities/audio_modes.dart';
import '../../domain/usecases/audio_player_usecases.dart';
import '../../domain/usecases/check_audio_playability_use_case.dart';
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
    this._checkAudioPlayability,
    this._settingsCubit,
    this._addOrUpdateHistory,
    this._analyticsService,
  ) : super(const AudioPlayerState(status: AudioPlayerStatus.initial)) {
    // State update events
    on<ResetAudioPlayer>(_onResetAudioPlayer);
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
    _setupSettingsSubscription();
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
  final CheckAudioPlayabilityUseCase _checkAudioPlayability;
  final SettingsCubit _settingsCubit;
  final AddOrUpdateHistoryUseCase _addOrUpdateHistory;
  final AnalyticsService _analyticsService;

  /// Stream subscriptions to be cancelled on close to prevent memory leaks.
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final Map<String, Duration> _lastKnownPositions = {};
  final Map<String, Duration> _lastKnownDurations = {};
  final Set<String> _completedAudioIds = {};
  Timer? _sleepTimer;

  /// Maximum number of cached entries before eviction.
  static const int _maxCacheSize = 50;

  /// Evicts oldest entries when the cache exceeds [_maxCacheSize].
  void _evictCacheIfNeeded() {
    if (_lastKnownPositions.length > _maxCacheSize) {
      final keysToRemove = _lastKnownPositions.keys
          .take(_lastKnownPositions.length - _maxCacheSize)
          .toList();
      keysToRemove.forEach(_lastKnownPositions.remove);
    }
    if (_lastKnownDurations.length > _maxCacheSize) {
      final keysToRemove = _lastKnownDurations.keys
          .take(_lastKnownDurations.length - _maxCacheSize)
          .toList();
      keysToRemove.forEach(_lastKnownDurations.remove);
    }
  }

  void _setupAudioStreams() {
    void onStreamError(Object error, StackTrace stackTrace) {
      // Swallow stream errors to prevent unhandled exceptions in release mode.
      // The audio service can emit errors on codec failures, OS kills, etc.
    }

    _subscriptions.add(
      _getAudioStreams.currentAudio.listen(
        (audio) => add(AudioPlayerEvent.updateAudio(audio)),
        onError: onStreamError,
      ),
    );

    _subscriptions.add(
      _getAudioStreams.playbackState.listen(
        (playbackState) =>
            add(AudioPlayerEvent.updatePlaybackStateEntity(playbackState)),
        onError: onStreamError,
      ),
    );

    _subscriptions.add(
      _getAudioStreams.volume.listen(
        (volume) => add(AudioPlayerEvent.updateVolume(volume)),
        onError: onStreamError,
      ),
    );

    _subscriptions.add(
      _getAudioStreams.speed.listen(
        (speed) => add(AudioPlayerEvent.updateSpeed(speed)),
        onError: onStreamError,
      ),
    );

    _subscriptions.add(
      _getAudioStreams.position.listen(
        (position) {
          final AudioEntity? currentAudio = state.currentAudio;
          final PlaybackStateEntity? playbackState = state.playbackState;

          final Duration duration = currentAudio != null
              ? currentAudio.duration
              : Duration.zero;
          final Duration buffered = playbackState != null
              ? playbackState.bufferedPosition
              : Duration.zero;

          add(
            AudioPlayerEvent.updatePositionData(
              PositionData(
                position: position,
                bufferedPosition: buffered,
                duration: duration,
              ),
            ),
          );
        },
        onError: onStreamError,
      ),
    );
  }

  void _setupSettingsSubscription() {
    _subscriptions.add(
      _settingsCubit.stream.listen(
        (settingsState) {
          if (!settingsState.isSleepTimerEnabled) {
            add(const AudioPlayerEvent.cancelSleepTimer());
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          // Swallow settings stream errors to prevent crashes.
        },
      ),
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

  void _onResetAudioPlayer(
    ResetAudioPlayer event,
    Emitter<AudioPlayerState> emit,
  ) {
    emit(const AudioPlayerState(status: AudioPlayerStatus.initial));
  }

  Future<void> _onUpdateAudio(
    UpdateAudio event,
    Emitter<AudioPlayerState> emit,
  ) async {
    // If we are updating to a NEW track, save the history for the OLD track
    // first — but skip if it was already saved as completed to avoid
    // overwriting good data with a stale/reset position.
    if (state.currentAudio != null &&
        event.audio != null &&
        state.currentAudio!.id != event.audio!.id) {
      final String oldId = state.currentAudio!.id;
      if (!_completedAudioIds.contains(oldId)) {
        // Check if the cached position looks like a reset (very low
        // relative to duration). This happens when the position stream
        // fires with the new track's initial position before
        // _onUpdateAudio processes the track change.
        final Duration cachedPos = _lastKnownPositions[oldId] ?? Duration.zero;
        final Duration cachedDur = _lastKnownDurations[oldId] ?? Duration.zero;
        final bool positionLooksReset =
            cachedDur > const Duration(seconds: 10) &&
            cachedPos < const Duration(seconds: 5);
        if (!positionLooksReset) {
          await _saveHistory(state.currentAudio!);
        }
      }
      // Clear the completed marker for this audio so future replays
      // are tracked normally.
      _completedAudioIds.remove(oldId);
    }

    if (event.audio != null) {
      final extras = event.audio?.extras;
      await _analyticsService.logAudioPlay(
        event.audio!.id,
        audioName: event.audio!.title,
        artist: event.audio!.artist,
        surahName: event.audio!.title,
        reciterName: event.audio!.artist,
        moshafName: extras?['moshafName'] as String?,
        surahId: extras?['surahId']?.toString(),
        reciterId: extras?['reciterId'] as String?,
      );
    }

    emit(
      state.copyWith(
        status: AudioPlayerStatus.success,
        currentAudio: event.audio,
        // Preserve dismissedAudioId.
        // Logic: specific ID is dismissed until explicitly played or cleared.
      ),
    );
    // Note: We intentionally do NOT save history for the new audio here.
    // History will be saved when:
    // 1. The user pauses/stops playback
    // 2. The track completes
    // 3. The user switches to another track
  }

  Future<void> _onUpdatePlaybackStateEntity(
    UpdatePlaybackStateEntity event,
    Emitter<AudioPlayerState> emit,
  ) async {
    // If we start playing, always un-dismiss
    final bool isPlaying = event.playbackState.isPlaying;
    _cachePlaybackMetrics(event.playbackState);

    if (event.playbackState.processingState ==
        AudioProcessingStateStatus.completed) {
      final PlaybackStateEntity playbackState = event.playbackState;
      final int currentIndex = playbackState.currentIndex;
      AudioEntity? completedAudio;
      if (currentIndex >= 0 && currentIndex < playbackState.queue.length) {
        completedAudio = playbackState.queue[currentIndex];
      } else {
        completedAudio = state.currentAudio;
      }
      if (completedAudio != null) {
        await _saveHistory(completedAudio, isCompleted: true);
        _completedAudioIds.add(completedAudio.id);
      }
    }

    emit(
      state.copyWith(
        status: AudioPlayerStatus.success,
        playbackState: event.playbackState,
        dismissedAudioId: isPlaying ? null : state.dismissedAudioId,
      ),
    );
  }

  void _onUpdatePositionData(
    UpdatePositionData event,
    Emitter<AudioPlayerState> emit,
  ) {
    // Cache the last known position for the current audio.
    // We ignore Duration.zero to prevent overwriting the last valid position
    // when the player resets the position before switching to the next track.
    //
    // We also reject dramatic backward jumps (> 10s drop) which indicate that
    // the position stream is reporting the NEW track's initial position while
    // state.currentAudio still references the OLD track.
    if (state.currentAudio != null &&
        event.positionData.position > Duration.zero) {
      final String audioId = state.currentAudio!.id;
      final Duration existingPos =
          _lastKnownPositions[audioId] ?? Duration.zero;
      final Duration newPos = event.positionData.position;

      // Accept if: no existing position, position is advancing, or
      // the backward jump is within 10 seconds (normal seek).
      final bool isForwardOrSmallJump =
          existingPos == Duration.zero ||
          newPos >= existingPos ||
          (existingPos - newPos).inSeconds <= 10;

      if (isForwardOrSmallJump) {
        _lastKnownPositions[audioId] = newPos;
      }
    }
    if (state.currentAudio != null &&
        event.positionData.duration > Duration.zero) {
      _lastKnownDurations[state.currentAudio!.id] = event.positionData.duration;
    }

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
    // Optimistically un-dismiss when play is requested
    emit(state.copyWith(dismissedAudioId: null));
    final result = await _playAudio();
    result.fold(
      (failure) {
        // Revert the optimistic un-dismiss on failure
        emit(state.copyWith(dismissedAudioId: state.currentAudio?.id));
      },
      (_) {
        // Only restart sleep timer if one was actively running before pause
        // (sleepTimerTargetTime is cleared on stop/expiry but kept on pause)
        if (_settingsCubit.state.isSleepTimerEnabled &&
            state.lastSleepTimerDuration != null &&
            state.sleepTimerTargetTime != null) {
          add(AudioPlayerEvent.setSleepTimer(state.lastSleepTimerDuration!));
        }
      },
    );
  }

  Future<void> _onPauseAudio(
    PauseAudio event,
    Emitter<AudioPlayerState> emit,
  ) async {
    await _pauseAudio();
    // Cancel sleep timer on manual pause but keep the preference
    add(const AudioPlayerEvent.cancelSleepTimer(clearPreference: false));

    if (state.currentAudio != null) {
      await _saveHistory(state.currentAudio!);
    }
  }

  Future<void> _onStopAudio(
    StopAudio event,
    Emitter<AudioPlayerState> emit,
  ) async {
    final Either<Failure, void> result = await _stopAudio();
    await result.fold(
      (failure) async {
        // Stop failed — force-pause as fallback so the user isn't stuck
        await _pauseAudio();
      },
      (success) async {
        if (state.currentAudio != null) {
          await _saveHistory(state.currentAudio!);
        }
        // Stop the internal timer
        _sleepTimer?.cancel();
        _sleepTimer = null;

        // Change status to initial and mark current audio as dismissed.
        // We preserve currentAudio to ensure we know "which" audio was dismissed.
        // Clear sleep timer state entirely — stop ends the session.
        emit(
          state.copyWith(
            status: AudioPlayerStatus.initial,
            dismissedAudioId: state.currentAudio?.id,
            sleepTimerTargetTime: null,
            lastSleepTimerDuration: null,
            lastSleepTimerType: null,
          ),
        );
      },
    );
  }

  Future<void> _onSkipToNext(
    SkipToNext event,
    Emitter<AudioPlayerState> emit,
  ) async {
    // Save current track's history before skipping
    if (state.currentAudio != null) {
      await _saveHistory(state.currentAudio!);
    }
    await _skipToNext();
  }

  Future<void> _onSkipToPrevious(
    SkipToPrevious event,
    Emitter<AudioPlayerState> emit,
  ) async {
    // Save current track's history before skipping
    if (state.currentAudio != null) {
      await _saveHistory(state.currentAudio!);
    }
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
    // Validate queue index
    if (event.index < 0 || event.index >= event.queue.length) {
      return;
    }

    // Get the audio to be played
    final AudioEntity audio = event.queue[event.index];

    // Check if playback is allowed (network + download status)
    final Either<Failure, void> playabilityResult =
        await _checkAudioPlayability(audio);

    await playabilityResult.fold(
      (failure) {
        // Playback not allowed - show user-friendly toast
        if (failure is OfflinePlaybackFailure || failure is NetworkFailure) {
          ToastUtils.showErrorToast(
            failure.message ??
                'This content is not available offline. Please download it first.',
          );
        }
        // Don't proceed with playback
      },
      (_) async {
        // New playback session — reset sleep timer state
        _sleepTimer?.cancel();
        _sleepTimer = null;
        emit(
          state.copyWith(
            sleepTimerTargetTime: null,
            lastSleepTimerDuration: null,
            lastSleepTimerType: null,
          ),
        );
        // Playback allowed - proceed normally
        await _playFromQueue(event.queue, event.index);
      },
    );
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
          if (!isClosed) add(const AudioPlayerEvent.audioTimerExpired());
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
      if (!isClosed) add(const AudioPlayerEvent.audioTimerExpired());
    });
    emit(
      state.copyWith(
        sleepTimerTargetTime: DateTime.now().add(event.duration),
        lastSleepTimerDuration: event.duration,
        lastSleepTimerType: event.type,
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
        lastSleepTimerDuration: event.clearPreference
            ? null
            : state.lastSleepTimerDuration,
        lastSleepTimerType: event.clearPreference
            ? null
            : state.lastSleepTimerType,
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
    if (state.currentAudio != null) {
      await _saveHistory(state.currentAudio!);
    }
    emit(
      state.copyWith(
        sleepTimerTargetTime: null,
        // Keep the duration preference when timer expires
        status: AudioPlayerStatus.success,
      ),
    );
  }

  Future<void> _saveHistory(
    AudioEntity audio, {
    bool isCompleted = false,
  }) async {
    final Map<String, dynamic>? extras = audio.extras;
    if (extras == null) return;

    final String? reciterId = extras['reciterId'] as String?;
    final int? moshafId = extras['moshafId'] as int?;
    final int? surahId = extras['surahId'] as int?;

    if (reciterId != null && moshafId != null && surahId != null) {
      // Determine Duration: Prefer audio entity, fallback to playback state
      final PlaybackStateEntity? playbackState = state.playbackState;
      final int? currentIndex = playbackState?.currentIndex;
      final bool isCurrentPlayback =
          playbackState != null &&
          currentIndex != null &&
          currentIndex >= 0 &&
          currentIndex < playbackState.queue.length &&
          playbackState.queue[currentIndex].id == audio.id;

      final Duration duration = _resolveDuration(
        audio,
        playbackState,
        isCurrentPlayback,
      );

      // Determine Position:
      // If completed, use full duration.
      // Otherwise use cached position if available, or current position if it matches.
      final Duration cachedPosition =
          _lastKnownPositions[audio.id] ?? Duration.zero;

      final Duration rawPosition = isCompleted
          ? duration
          : (isCurrentPlayback
                ? state.positionData?.position ?? cachedPosition
                : cachedPosition);

      final Duration position = _clampToDuration(rawPosition, duration);

      // Lenient completion check: within 1.5 seconds of the end
      final bool isLenientlyCompleted =
          duration > Duration.zero &&
          (duration.inMilliseconds - position.inMilliseconds) < 1500;

      final bool completed = isCompleted || isLenientlyCompleted;

      // If completed, ensure lastPositionMs reflects full completion
      final int finalPositionMs = completed
          ? duration.inMilliseconds
          : position.inMilliseconds;

      await _addOrUpdateHistory(
        surahId: surahId,
        surahName: audio.title,
        surahNameEn: audio.title,
        reciterId: reciterId,
        reciterName: audio.artist ?? '',
        moshafId: moshafId,
        moshafName: audio.album ?? '',
        lastPositionMs: finalPositionMs,
        durationMs: duration.inMilliseconds,
        audioUrl: audio.url,
        artworkUrl: audio.artUri,
        completed: completed,
      );
    }
  }

  void _cachePlaybackMetrics(PlaybackStateEntity playbackState) {
    final int currentIndex = playbackState.currentIndex;
    if (currentIndex >= 0 && currentIndex < playbackState.queue.length) {
      final AudioEntity currentAudio = playbackState.queue[currentIndex];
      if (playbackState.position > Duration.zero) {
        _lastKnownPositions[currentAudio.id] = playbackState.position;
      }
      if (playbackState.duration > Duration.zero) {
        _lastKnownDurations[currentAudio.id] = playbackState.duration;
      } else if (currentAudio.duration > Duration.zero) {
        _lastKnownDurations[currentAudio.id] = currentAudio.duration;
      }
    }

    for (final AudioEntity queuedAudio in playbackState.queue) {
      if (queuedAudio.duration > Duration.zero) {
        _lastKnownDurations.putIfAbsent(
          queuedAudio.id,
          () => queuedAudio.duration,
        );
      }
    }

    _evictCacheIfNeeded();
  }

  Duration _resolveDuration(
    AudioEntity audio,
    PlaybackStateEntity? playbackState,
    bool isCurrentPlayback,
  ) {
    if (audio.duration > Duration.zero) {
      return audio.duration;
    }

    final Duration cachedDuration =
        _lastKnownDurations[audio.id] ?? Duration.zero;
    if (cachedDuration > Duration.zero) {
      return cachedDuration;
    }

    if (isCurrentPlayback && playbackState != null) {
      final Duration playbackDuration = playbackState.duration;
      if (playbackDuration > Duration.zero) {
        return playbackDuration;
      }
    }

    if (playbackState != null) {
      for (final AudioEntity queuedAudio in playbackState.queue) {
        if (queuedAudio.id == audio.id &&
            queuedAudio.duration > Duration.zero) {
          return queuedAudio.duration;
        }
      }
    }

    return Duration.zero;
  }

  Duration _clampToDuration(Duration value, Duration max) {
    if (max <= Duration.zero) {
      return value >= Duration.zero ? value : Duration.zero;
    }
    if (value < Duration.zero) {
      return Duration.zero;
    }
    if (value > max) {
      return max;
    }
    return value;
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
