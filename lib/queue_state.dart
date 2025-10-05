import 'package:audio_service/audio_service.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'queue_state.freezed.dart';

@freezed
abstract class QueueState with _$QueueState {
  const factory QueueState({
    required List<MediaItem> queue,
    required int? queueIndex,
    required List<int>? shuffleIndices,
    required AudioServiceRepeatMode repeatMode,
  }) = _QueueState;

  const QueueState._();

  static const QueueState empty = QueueState(
    queue: [],
    queueIndex: 0,
    shuffleIndices: [],
    repeatMode: AudioServiceRepeatMode.none,
  );

  bool get hasPrevious =>
      repeatMode != AudioServiceRepeatMode.none || (queueIndex ?? 0) > 0;
  bool get hasNext =>
      repeatMode != AudioServiceRepeatMode.none ||
      (queueIndex ?? 0) + 1 < queue.length;

  List<int> get indices =>
      shuffleIndices ?? List.generate(queue.length, (i) => i);
}
