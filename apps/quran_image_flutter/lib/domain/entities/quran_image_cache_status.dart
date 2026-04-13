import 'package:equatable/equatable.dart';

enum QuranImageCachePhase { checking, downloading, extracting, ready, failed }

class QuranImageCacheStatus extends Equatable {
  const QuranImageCacheStatus({
    required this.phase,
    required this.progress,
    required this.message,
    this.errorMessage,
  });

  const QuranImageCacheStatus.checking()
    : this(
        phase: QuranImageCachePhase.checking,
        progress: 0,
        message: 'Checking Quran image cache...',
      );

  const QuranImageCacheStatus.ready()
    : this(
        phase: QuranImageCachePhase.ready,
        progress: 1,
        message: 'Quran images are ready.',
      );

  const QuranImageCacheStatus.failed(String errorMessage)
    : this(
        phase: QuranImageCachePhase.failed,
        progress: 0,
        message: 'Could not prepare Quran images.',
        errorMessage: errorMessage,
      );

  final QuranImageCachePhase phase;
  final double progress;
  final String message;
  final String? errorMessage;

  bool get isReady => phase == QuranImageCachePhase.ready;

  @override
  List<Object?> get props => [phase, progress, message, errorMessage];
}
