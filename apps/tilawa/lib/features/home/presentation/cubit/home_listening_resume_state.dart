import 'package:equatable/equatable.dart';

enum HomeListeningResumeStatus { initial, loading, ready }

/// Last listening session snapshot for the Home resume row.
final class HomeListeningResumeState extends Equatable {
  const HomeListeningResumeState({
    this.status = HomeListeningResumeStatus.initial,
    this.reciterName,
    this.surahName,
    this.historyId,
    this.audioUrl,
    this.surahId,
    this.reciterId,
    this.moshafId,
    this.moshafName,
    this.lastPositionMs = 0,
    this.durationMs = 0,
    this.completed = false,
    this.artworkUrl,
  });

  final HomeListeningResumeStatus status;
  final String? reciterName;
  final String? surahName;
  final String? historyId;
  final String? audioUrl;
  final int? surahId;
  final String? reciterId;
  final int? moshafId;
  final String? moshafName;
  final int lastPositionMs;
  final int durationMs;
  final bool completed;
  final String? artworkUrl;

  bool get isVisible =>
      status == HomeListeningResumeStatus.ready &&
      reciterName != null &&
      surahName != null &&
      audioUrl != null;

  /// Seek when resuming; `null` restarts from the beginning.
  ///
  /// Matches [HistoryEntity.resumeInitialPosition]: completed / ≥97% progress
  /// must not seek to the saved end position.
  Duration? get resumeInitialPosition {
    if (completed) {
      return null;
    }
    if (durationMs > 0 && lastPositionMs / durationMs >= 0.97) {
      return null;
    }
    if (lastPositionMs <= 0) {
      return null;
    }
    return Duration(milliseconds: lastPositionMs);
  }

  HomeListeningResumeState copyWith({
    HomeListeningResumeStatus? status,
    String? reciterName,
    String? surahName,
    String? historyId,
    String? audioUrl,
    int? surahId,
    String? reciterId,
    int? moshafId,
    String? moshafName,
    int? lastPositionMs,
    int? durationMs,
    bool? completed,
    String? artworkUrl,
    bool clearHistory = false,
  }) {
    return HomeListeningResumeState(
      status: status ?? this.status,
      reciterName: clearHistory ? null : reciterName ?? this.reciterName,
      surahName: clearHistory ? null : surahName ?? this.surahName,
      historyId: clearHistory ? null : historyId ?? this.historyId,
      audioUrl: clearHistory ? null : audioUrl ?? this.audioUrl,
      surahId: clearHistory ? null : surahId ?? this.surahId,
      reciterId: clearHistory ? null : reciterId ?? this.reciterId,
      moshafId: clearHistory ? null : moshafId ?? this.moshafId,
      moshafName: clearHistory ? null : moshafName ?? this.moshafName,
      lastPositionMs: clearHistory ? 0 : lastPositionMs ?? this.lastPositionMs,
      durationMs: clearHistory ? 0 : durationMs ?? this.durationMs,
      completed: !clearHistory && (completed ?? this.completed),
      artworkUrl: clearHistory ? null : artworkUrl ?? this.artworkUrl,
    );
  }

  @override
  List<Object?> get props => [
    status,
    reciterName,
    surahName,
    historyId,
    audioUrl,
    surahId,
    reciterId,
    moshafId,
    moshafName,
    lastPositionMs,
    durationMs,
    completed,
    artworkUrl,
  ];
}
