import 'package:equatable/equatable.dart';

enum QuranImageCachePhase {
  checking,
  downloadingImages,
  downloadingHeader,
  extracting,
  ready,
  failed,
}

class QuranImageCacheStatus extends Equatable {
  const QuranImageCacheStatus({
    required this.phase,
    required this.progress,
    this.errorMessage,
  });

  const QuranImageCacheStatus.checking()
    : this(phase: QuranImageCachePhase.checking, progress: 0);

  const QuranImageCacheStatus.ready()
    : this(phase: QuranImageCachePhase.ready, progress: 1);

  const QuranImageCacheStatus.failed(String errorMessage)
    : this(
        phase: QuranImageCachePhase.failed,
        progress: 0,
        errorMessage: errorMessage,
      );

  final QuranImageCachePhase phase;
  final double progress;
  final String? errorMessage;

  bool get isReady => phase == QuranImageCachePhase.ready;

  @override
  List<Object?> get props => [phase, progress, errorMessage];
}
