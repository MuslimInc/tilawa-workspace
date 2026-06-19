import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:tilawa/features/surah/domain/entities/surah_entity.dart';

/// Presentation model for one surah row/card on [ReciterDetailsScreen].
///
/// Keeps widgets off [SurahEntity] so UI only receives display and download
/// fields. Play and batch-download flows still resolve [SurahEntity] in the
/// screen or bloc.
@immutable
class ReciterSurahListItem extends Equatable {
  const ReciterSurahListItem({
    required this.audioId,
    required this.audioUrl,
    required this.displayName,
    required this.formattedNumber,
    required this.semanticsKey,
    required this.reciterName,
    required this.reciterId,
    required this.isDownloaded,
    required this.isDownloading,
    required this.downloadProgress,
  });

  /// Stable audio URL used for playback matching and per-surah downloads.
  final String audioId;

  /// Stream URL (remote or local) for active-track detection.
  final String audioUrl;

  /// Surah title shown in the list or grid.
  final String displayName;

  /// Padded surah index for the leading badge (e.g. `001`).
  final String formattedNumber;

  /// Maestro / semantics suffix when [formattedNumber] is unavailable.
  final String semanticsKey;

  final String reciterName;
  final int reciterId;
  final bool isDownloaded;
  final bool isDownloading;
  final double downloadProgress;

  factory ReciterSurahListItem.fromSurahEntity(
    SurahEntity surah, {
    required int reciterId,
    required String reciterName,
    required int listIndex,
  }) {
    final String semanticsKey = surah.formattedId.isNotEmpty
        ? surah.formattedId
        : '${listIndex + 1}';

    return ReciterSurahListItem(
      audioId: surah.id,
      audioUrl: surah.audio.url,
      displayName: surah.name,
      formattedNumber: semanticsKey,
      semanticsKey: semanticsKey,
      reciterName: reciterName,
      reciterId: reciterId,
      isDownloaded: surah.isDownloaded,
      isDownloading: surah.isDownloading,
      downloadProgress: surah.downloadProgress,
    );
  }

  @override
  List<Object?> get props => [
    audioId,
    audioUrl,
    displayName,
    formattedNumber,
    semanticsKey,
    reciterName,
    reciterId,
    isDownloaded,
    isDownloading,
    downloadProgress,
  ];
}
