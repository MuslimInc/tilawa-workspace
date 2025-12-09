import '../../../../core/utils/typedefs.dart';
import '../repositories/audio_player_repository.dart';

class PauseAudioUseCase {
  const PauseAudioUseCase(this._repository);

  final AudioPlayerRepository _repository;

  ResultVoid call() {
    return _repository.pause();
  }
}
