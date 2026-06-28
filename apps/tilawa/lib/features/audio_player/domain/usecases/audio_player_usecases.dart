import 'package:injectable/injectable.dart';

import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_core/utils/typedefs.dart';
import '../entities/audio_modes.dart';
import '../repositories/audio_player_repository.dart';

@injectable
class PlayAudioUseCase {
  const PlayAudioUseCase(this._repository);
  final AudioPlayerRepository _repository;
  ResultVoid call() => _repository.play();
}

@injectable
class PauseAudioUseCase {
  const PauseAudioUseCase(this._repository);
  final AudioPlayerRepository _repository;
  ResultVoid call() => _repository.pause();
}

@injectable
class StopAudioUseCase {
  const StopAudioUseCase(this._repository);
  final AudioPlayerRepository _repository;
  ResultVoid call() => _repository.stop();
}

@injectable
class SeekToUseCase {
  const SeekToUseCase(this._repository);
  final AudioPlayerRepository _repository;
  ResultVoid call(Duration position) => _repository.seek(position);
}

@injectable
class SkipToNextUseCase {
  const SkipToNextUseCase(this._repository);
  final AudioPlayerRepository _repository;
  ResultVoid call() => _repository.next();
}

@injectable
class SkipToPreviousUseCase {
  const SkipToPreviousUseCase(this._repository);
  final AudioPlayerRepository _repository;
  ResultVoid call() => _repository.previous();
}

@injectable
class SetVolumeUseCase {
  const SetVolumeUseCase(this._repository);
  final AudioPlayerRepository _repository;
  ResultVoid call(double volume) => _repository.setVolume(volume);
}

@injectable
class SetPlaybackSpeedUseCase {
  const SetPlaybackSpeedUseCase(this._repository);
  final AudioPlayerRepository _repository;
  ResultVoid call(double speed) => _repository.setSpeed(speed);
}

@injectable
class SetRepeatModeUseCase {
  const SetRepeatModeUseCase(this._repository);
  final AudioPlayerRepository _repository;
  ResultVoid call(AudioRepeatMode mode) => _repository.setRepeatMode(mode);
}

@injectable
class SetShuffleModeUseCase {
  const SetShuffleModeUseCase(this._repository);
  final AudioPlayerRepository _repository;
  ResultVoid call(AudioShuffleMode mode) => _repository.setShuffleMode(mode);
}

@injectable
class SkipToQueueItemUseCase {
  const SkipToQueueItemUseCase(this._repository);
  final AudioPlayerRepository _repository;
  ResultVoid call(int index) => _repository.skipToQueueItem(index);
}

@injectable
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

@injectable
class UpdateQueueUseCase {
  const UpdateQueueUseCase(this._repository);
  final AudioPlayerRepository _repository;
  ResultVoid call(List<AudioEntity> queue) => _repository.updateQueue(queue);
}

@injectable
class MoveQueueItemUseCase {
  const MoveQueueItemUseCase(this._repository);
  final AudioPlayerRepository _repository;
  ResultVoid call(int currentIndex, int newIndex) =>
      _repository.moveQueueItem(currentIndex, newIndex);
}

@injectable
class AddQueueItemUseCase {
  const AddQueueItemUseCase(this._repository);
  final AudioPlayerRepository _repository;
  ResultVoid call(AudioEntity audio) => _repository.addQueueItem(audio);
}

@injectable
class RemoveQueueItemUseCase {
  const RemoveQueueItemUseCase(this._repository);
  final AudioPlayerRepository _repository;
  ResultVoid call(AudioEntity audio) => _repository.removeQueueItem(audio);
}
