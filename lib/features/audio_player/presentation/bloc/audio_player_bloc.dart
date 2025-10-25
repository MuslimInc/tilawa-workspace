import 'package:audio_service/audio_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:muzakri/shared/audio/audio_player_handler.dart';
import 'package:muzakri/shared/models/position_data.dart';
import 'package:muzakri/shared/models/queue_state.dart';
import 'package:rxdart/rxdart.dart';

part 'audio_player_bloc.freezed.dart';
part 'audio_player_event.dart';
part 'audio_player_state.dart';

@injectable
class AudioPlayerBloc extends Bloc<AudioPlayerEvent, AudioPlayerState> {
  final AudioPlayerHandler _audioHandler;

  AudioPlayerBloc(this._audioHandler)
    : super(const AudioPlayerState(status: AudioPlayerStatus.initial)) {
    // State update events
    on<LoadAudioPlayerData>(_onLoadAudioPlayerData);
    on<UpdateMediaItem>(_onUpdateMediaItem);
    on<UpdatePlaybackState>(_onUpdatePlaybackState);
    on<UpdatePositionData>(_onUpdatePositionData);
    on<UpdateQueueState>(_onUpdateQueueState);
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
    on<UpdateQueue>(_onUpdateQueue);
    on<AddQueueItem>(_onAddQueueItem);
    on<RemoveQueueItem>(_onRemoveQueueItem);
    on<MoveQueueItem>(_onMoveQueueItem);
    on<SetRepeatMode>(_onSetRepeatMode);
    on<SetShuffleMode>(_onSetShuffleMode);

    _setupAudioStreams();
  }

  void _setupAudioStreams() {
    // Listen to media item changes
    _audioHandler.mediaItem.listen((mediaItem) {
      add(AudioPlayerEvent.updateMediaItem(mediaItem));
    });

    // Listen to playback state changes
    _audioHandler.playbackState.listen((playbackState) {
      add(AudioPlayerEvent.updatePlaybackState(playbackState));
    });

    // Listen to position data changes
    _getPositionDataStream().listen((positionData) {
      add(AudioPlayerEvent.updatePositionData(positionData));
    });

    // Listen to queue state changes
    _audioHandler.queueState.listen((queueState) {
      add(AudioPlayerEvent.updateQueueState(queueState));
    });

    // Listen to volume changes
    _audioHandler.volume.listen((volume) {
      add(AudioPlayerEvent.updateVolume(volume));
    });

    // Listen to speed changes
    _audioHandler.speed.listen((speed) {
      add(AudioPlayerEvent.updateSpeed(speed));
    });
  }

  Stream<Duration> get _bufferedPositionStream => _audioHandler.playbackState
      .map((state) => state.bufferedPosition)
      .distinct();

  Stream<Duration?> get _durationStream =>
      _audioHandler.mediaItem.map((item) => item?.duration).distinct();

  Stream<PositionData> _getPositionDataStream() =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        AudioService.position,
        _bufferedPositionStream,
        _durationStream,
        (position, bufferedPosition, duration) => PositionData(
          position: position,
          bufferedPosition: bufferedPosition,
          duration: duration ?? Duration.zero,
        ),
      );

  void _onLoadAudioPlayerData(
    LoadAudioPlayerData event,
    Emitter<AudioPlayerState> emit,
  ) {
    emit(state.copyWith(status: AudioPlayerStatus.success));
  }

  void _onUpdateMediaItem(
    UpdateMediaItem event,
    Emitter<AudioPlayerState> emit,
  ) {
    emit(
      state.copyWith(
        status: AudioPlayerStatus.success,
        mediaItem: event.mediaItem,
        playbackState: state.playbackState,
        positionData: state.positionData,
        queueState: state.queueState,
        volume: state.volume,
        speed: state.speed,
      ),
    );
  }

  void _onUpdatePlaybackState(
    UpdatePlaybackState event,
    Emitter<AudioPlayerState> emit,
  ) {
    emit(
      state.copyWith(
        status: AudioPlayerStatus.success,
        mediaItem: state.mediaItem,
        playbackState: event.playbackState,
        positionData: state.positionData,
        queueState: state.queueState,
        volume: state.volume,
        speed: state.speed,
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
        mediaItem: state.mediaItem,
        playbackState: state.playbackState,
        positionData: event.positionData,
        queueState: state.queueState,
        volume: state.volume,
        speed: state.speed,
      ),
    );
  }

  void _onUpdateQueueState(
    UpdateQueueState event,
    Emitter<AudioPlayerState> emit,
  ) {
    emit(
      state.copyWith(
        status: AudioPlayerStatus.success,
        mediaItem: state.mediaItem,
        playbackState: state.playbackState,
        positionData: state.positionData,
        queueState: event.queueState,
        volume: state.volume,
        speed: state.speed,
      ),
    );
  }

  void _onUpdateVolume(UpdateVolume event, Emitter<AudioPlayerState> emit) {
    emit(
      state.copyWith(
        status: AudioPlayerStatus.success,
        mediaItem: state.mediaItem,
        playbackState: state.playbackState,
        positionData: state.positionData,
        queueState: state.queueState,
        volume: event.volume,
        speed: state.speed,
      ),
    );
  }

  void _onUpdateSpeed(UpdateSpeed event, Emitter<AudioPlayerState> emit) {
    emit(
      state.copyWith(
        status: AudioPlayerStatus.success,
        mediaItem: state.mediaItem,
        playbackState: state.playbackState,
        positionData: state.positionData,
        queueState: state.queueState,
        volume: state.volume,
        speed: event.speed,
      ),
    );
  }

  // Audio control event handlers
  void _onPlayAudio(PlayAudio event, Emitter<AudioPlayerState> emit) {
    _audioHandler.play();
  }

  void _onPauseAudio(PauseAudio event, Emitter<AudioPlayerState> emit) {
    _audioHandler.pause();
  }

  void _onStopAudio(StopAudio event, Emitter<AudioPlayerState> emit) {
    _audioHandler.stop();
  }

  void _onSkipToNext(SkipToNext event, Emitter<AudioPlayerState> emit) {
    _audioHandler.skipToNext();
  }

  void _onSkipToPrevious(SkipToPrevious event, Emitter<AudioPlayerState> emit) {
    _audioHandler.skipToPrevious();
  }

  void _onSeekTo(SeekTo event, Emitter<AudioPlayerState> emit) {
    _audioHandler.seek(event.position);
  }

  void _onSetVolume(SetVolume event, Emitter<AudioPlayerState> emit) {
    print('Bloc received setVolume event: ${event.volume}');
    _audioHandler.setVolume(event.volume);
    emit(
      state.copyWith(
        status: AudioPlayerStatus.success,
        mediaItem: state.mediaItem,
        playbackState: state.playbackState,
        positionData: state.positionData,
        queueState: state.queueState,
        volume: event.volume,
        speed: state.speed,
      ),
    );
    print('Bloc emitted new state with volume: ${event.volume}');
  }

  void _onSetSpeed(SetSpeed event, Emitter<AudioPlayerState> emit) {
    _audioHandler.setSpeed(event.speed);
    emit(
      state.copyWith(
        status: AudioPlayerStatus.success,
        mediaItem: state.mediaItem,
        playbackState: state.playbackState,
        positionData: state.positionData,
        queueState: state.queueState,
        volume: state.volume,
        speed: event.speed,
      ),
    );
  }

  void _onSkipToQueueItem(
    SkipToQueueItem event,
    Emitter<AudioPlayerState> emit,
  ) {
    _audioHandler.skipToQueueItem(event.index);
  }

  void _onUpdateQueue(UpdateQueue event, Emitter<AudioPlayerState> emit) {
    _audioHandler.updateQueue(event.queue);
  }

  void _onAddQueueItem(AddQueueItem event, Emitter<AudioPlayerState> emit) {
    _audioHandler.addQueueItem(event.item);
  }

  void _onRemoveQueueItem(
    RemoveQueueItem event,
    Emitter<AudioPlayerState> emit,
  ) {
    _audioHandler.removeQueueItem(event.item);
  }

  void _onMoveQueueItem(MoveQueueItem event, Emitter<AudioPlayerState> emit) {
    _audioHandler.moveQueueItem(event.currentIndex, event.newIndex);
  }

  void _onSetRepeatMode(SetRepeatMode event, Emitter<AudioPlayerState> emit) {
    _audioHandler.setRepeatMode(event.repeatMode);
  }

  void _onSetShuffleMode(SetShuffleMode event, Emitter<AudioPlayerState> emit) {
    _audioHandler.setShuffleMode(event.shuffleMode);
  }
}
