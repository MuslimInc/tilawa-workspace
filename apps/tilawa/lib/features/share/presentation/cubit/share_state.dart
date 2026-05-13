import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../quran_reader/domain/entities/entities.dart';
import '../../domain/entities/share_content.dart';
import '../utils/share_reciter_options.dart';
import '../utils/video_page_specs.dart';

part 'share_state.freezed.dart';

enum ShareStatus { idle, capturing, generating, reviewing, sharing, error }

enum ShareScreenshotLayout { readerPage, passageCard }

@freezed
abstract class ShareState with _$ShareState {
  const factory ShareState({
    @Default(ShareStatus.idle) ShareStatus status,
    @Default(ShareScreenshotLayout.readerPage)
    ShareScreenshotLayout screenshotLayout,
    // Audio clip configuration
    int? surahNumber,
    int? fromAyah,
    int? toAyah,
    int? minAyah,
    int? maxAyah,
    String? reciterName,
    String? reciterServerUrl,
    // Progress tracking
    @Default(0.0) double progress,
    @Default('') String progressMessage,
    // Generated content
    ShareContent? content,

    /// Path from the latest persistent export; cleared when a new save starts.
    String? lastSaveExportPath,
    String? errorMessage,
    List<PageAyahInfo>? ayahs,
    int? capturingIndex,
    @Default([]) List<ShareReciterOption> reciterOptions,
    @Default(false) bool isLoadingReciters,
    @Default([]) List<VideoPageSpec> videoPageSpecs,
  }) = _ShareState;
}
