import 'package:injectable/injectable.dart';

import 'package:tilawa_core/entities/audio.dart';
import '../repositories/audio_player_repository.dart';

@injectable
class GetAudioStreamsUseCase {
  const GetAudioStreamsUseCase(this._repository);
  final AudioPlayerRepository _repository;

  Stream<PlaybackStateEntity> get playbackState => _repository.playbackState;
  Stream<AudioEntity?> get currentAudio => _repository.currentAudio;
  Stream<List<AudioEntity>> get queue => _repository.queue;
  Stream<double> get volume => _repository.volume;
  Stream<double> get speed => _repository.speed;
  Stream<Duration> get position => _repository.position;
}
