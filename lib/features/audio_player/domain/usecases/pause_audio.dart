import 'package:muzakri/core/utils/typedefs.dart';
import 'package:muzakri/features/audio_player/domain/repositories/audio_player_repository.dart';

class PauseAudio {
  const PauseAudio(this._repository);

  final AudioPlayerRepository _repository;

  ResultVoid call() async {
    return await _repository.pause();
  }
}
