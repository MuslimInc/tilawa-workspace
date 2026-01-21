import 'package:tilawa_core/utils/typedefs.dart';
import '../repositories/audio_player_repository.dart';

class PlayAudioUseCase {
  const PlayAudioUseCase(this._repository);

  final AudioPlayerRepository _repository;

  ResultVoid call() async {
    return _repository.play();
  }
}
