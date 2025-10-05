import 'package:muzakri/core/entities/audio.dart';
import 'package:muzakri/core/utils/typedefs.dart';

abstract class AudioPlayerRepository {
  ResultVoid play();
  ResultVoid pause();
  ResultVoid stop();
  ResultVoid seek(Duration position);
  ResultVoid setQueue(List<AudioEntity> queue);
  ResultVoid next();
  ResultVoid previous();
  ResultFuture<PlaybackStateEntity> getPlaybackState();
  ResultVoid setVolume(double volume);
}
