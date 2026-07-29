import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_core/utils/typedefs.dart';
import '../entities/audio_modes.dart';
import '../repositories/audio_player_repository.dart';

class PlayAudioUseCase {
  const PlayAudioUseCase(this._repository);
  final AudioPlayerRepository _repository;
  ResultVoid call() => _repository.play();
}

class PauseAudioUseCase {
  const PauseAudioUseCase(this._repository);
  final AudioPlayerRepository _repository;
  ResultVoid call() => _repository.pause();
}

class StopAudioUseCase {
  const StopAudioUseCase(this._repository);
  final AudioPlayerRepository _repository;
  ResultVoid call() => _repository.stop();
}

class SeekToUseCase {
  const SeekToUseCase(this._repository);
  final AudioPlayerRepository _repository;
  ResultVoid call(Duration position) => _repository.seek(position);
}

class SkipToNextUseCase {
  const SkipToNextUseCase(this._repository);
  final AudioPlayerRepository _repository;
  ResultVoid call() => _repository.next();
}

class SkipToPreviousUseCase {
  const SkipToPreviousUseCase(this._repository);
  final AudioPlayerRepository _repository;
  ResultVoid call() => _repository.previous();
}

class SetVolumeUseCase {
  const SetVolumeUseCase(this._repository);
  final AudioPlayerRepository _repository;
  ResultVoid call(double volume) => _repository.setVolume(volume);
}

class SetPlaybackSpeedUseCase {
  const SetPlaybackSpeedUseCase(this._repository);
  final AudioPlayerRepository _repository;
  ResultVoid call(double speed) => _repository.setSpeed(speed);
}

class SetRepeatModeUseCase {
  const SetRepeatModeUseCase(this._repository);
  final AudioPlayerRepository _repository;
  ResultVoid call(AudioRepeatMode mode) => _repository.setRepeatMode(mode);
}

class SetShuffleModeUseCase {
  const SetShuffleModeUseCase(this._repository);
  final AudioPlayerRepository _repository;
  ResultVoid call(AudioShuffleMode mode) => _repository.setShuffleMode(mode);
}

class SkipToQueueItemUseCase {
  const SkipToQueueItemUseCase(this._repository);
  final AudioPlayerRepository _repository;
  ResultVoid call(int index) => _repository.skipToQueueItem(index);
}

class PlayFromQueueUseCase {
  const PlayFromQueueUseCase(this._repository);
  final AudioPlayerRepository _repository;
  ResultVoid call(
    List<AudioEntity> queue,
    int index, {
    Duration? initialPosition,
  }) =>
      _repository.playFromQueue(queue, index, initialPosition: initialPosition);
}

class UpdateQueueUseCase {
  const UpdateQueueUseCase(this._repository);
  final AudioPlayerRepository _repository;
  ResultVoid call(List<AudioEntity> queue) => _repository.updateQueue(queue);
}

class MoveQueueItemUseCase {
  const MoveQueueItemUseCase(this._repository);
  final AudioPlayerRepository _repository;
  ResultVoid call(int currentIndex, int newIndex) =>
      _repository.moveQueueItem(currentIndex, newIndex);
}

class AddQueueItemUseCase {
  const AddQueueItemUseCase(this._repository);
  final AudioPlayerRepository _repository;
  ResultVoid call(AudioEntity audio) => _repository.addQueueItem(audio);
}

class RemoveQueueItemUseCase {
  const RemoveQueueItemUseCase(this._repository);
  final AudioPlayerRepository _repository;
  ResultVoid call(AudioEntity audio) => _repository.removeQueueItem(audio);
}
