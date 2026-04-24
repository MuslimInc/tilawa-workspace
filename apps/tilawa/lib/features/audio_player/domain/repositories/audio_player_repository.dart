import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_core/utils/typedefs.dart';
import '../entities/audio_modes.dart';

abstract class AudioPlayerRepository {
  // Streams for state monitoring
  Stream<PlaybackStateEntity> get playbackState;
  Stream<AudioEntity?> get currentAudio;
  Stream<List<AudioEntity>> get queue;
  Stream<double> get volume;
  Stream<double> get speed;
  Stream<Duration> get position;

  // Current State Getters
  PlaybackStateEntity get getPlaybackState;

  // Playback Controls
  ResultVoid play();
  ResultVoid pause();
  ResultVoid stop();
  ResultVoid seek(Duration position);
  ResultVoid next();
  ResultVoid previous();
  ResultVoid skipToQueueItem(int index);
  ResultVoid setVolume(double volume);
  ResultVoid setSpeed(double speed);
  ResultVoid setRepeatMode(AudioRepeatMode repeatMode);
  ResultVoid setShuffleMode(AudioShuffleMode shuffleMode);

  // Queue Management
  ResultVoid addQueueItem(AudioEntity audio);
  ResultVoid removeQueueItem(AudioEntity audio);
  ResultVoid moveQueueItem(int currentIndex, int newIndex);
  ResultVoid updateQueue(List<AudioEntity> queue);

  // Custom restoration/initialization logic if needed
  ResultVoid playFromQueue(
    List<AudioEntity> queue,
    int index, {
    Duration? initialPosition,
  });
  ResultVoid loadAudioPlayerData({bool restorePlayback = true});
}
