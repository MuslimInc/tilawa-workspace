import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/entities/audio.dart';
import '../../features/audio_player/domain/entities/audio_modes.dart';

part 'queue_state.freezed.dart';

@freezed
abstract class QueueState with _$QueueState {
  const factory QueueState({
    required List<AudioEntity> queue,
    required int? queueIndex,
    required List<int>? shuffleIndices,
    required AudioRepeatMode repeatMode,
  }) = _QueueState;

  const QueueState._();

  static const QueueState empty = QueueState(
    queue: [],
    queueIndex: 0,
    shuffleIndices: [],
    repeatMode: AudioRepeatMode.none,
  );

  bool get hasPrevious =>
      repeatMode != AudioRepeatMode.none || (queueIndex ?? 0) > 0;
  bool get hasNext =>
      repeatMode != AudioRepeatMode.none ||
      (queueIndex ?? 0) + 1 < queue.length;

  List<int> get indices =>
      shuffleIndices ?? List.generate(queue.length, (i) => i);
}
