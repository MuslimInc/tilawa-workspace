import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/download_item.dart';

part 'downloads_status.freezed.dart';

/// One-time status events emitted by DownloadsBloc
/// These are not persistent states, but notifications of events
@freezed
sealed class DownloadsStatus with _$DownloadsStatus {
  const factory DownloadsStatus.downloadStarted({
    required String surahId,
    required String surahTitle,
    required String reciterName,
  }) = DownloadStarted;

  const factory DownloadsStatus.premiumRequired({required String message}) =
      PremiumRequired;

  const factory DownloadsStatus.playbackInitiated({required String message}) =
      PlaybackInitiated;

  const factory DownloadsStatus.surahDownloadStatus({
    required String surahId,
    required String reciterName,
    required bool isDownloaded,
  }) = SurahDownloadStatus;

  const factory DownloadsStatus.fileValidationResult({
    required String downloadId,
    required bool isValid,
  }) = FileValidationResult;

  const factory DownloadsStatus.validDownloadsLoaded({
    required String reciterName,
    required List<DownloadItem> validDownloads,
  }) = ValidDownloadsLoaded;

  const factory DownloadsStatus.error({required String message}) = Error;
}
