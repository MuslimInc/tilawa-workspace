import 'dart:async';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:tilawa/features/share/domain/entities/audio_clip_config.dart';
import 'package:tilawa/features/share/domain/entities/share_content.dart';
import 'package:tilawa/features/share/domain/entities/share_progress_messages.dart';
import 'package:tilawa/features/share/domain/entities/widget_capture_handle.dart';
import 'package:tilawa/features/share/domain/usecases/capture_screenshot_use_case.dart';
import 'package:tilawa/features/share/domain/usecases/generate_audio_clip_use_case.dart';
import 'package:tilawa/features/share/domain/usecases/generate_video_use_case.dart';
import 'package:tilawa/features/share/domain/usecases/get_share_ayahs_use_case.dart';
import 'package:tilawa/features/share/domain/usecases/prepare_share_range_use_case.dart';
import 'package:tilawa/features/share/domain/usecases/share_content_use_case.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/logger.dart';

import '../../../reciters/domain/usecases/get_reciters_use_case.dart';
import '../../data/services/reciter_audio_mapping.dart';
import '../utils/share_reciter_options.dart';
import 'share_state.dart';

@injectable
class ShareCubit extends Cubit<ShareState> {
  ShareCubit(
    this._captureScreenshot,
    this._generateAudioClip,
    this._generateVideo,
    this._prepareShareRange,
    this._getShareAyahs,
    this._shareContent,
    this._getReciters,
  ) : super(const ShareState()) {
    logger.d(
      '[AppLaunch][ShareCubit.constructor]: Start in (${DateTime.now()})',
    );
  }

  final CaptureScreenshotUseCase _captureScreenshot;
  final GenerateAudioClipUseCase _generateAudioClip;
  final GenerateVideoUseCase _generateVideo;
  final PrepareShareRangeUseCase _prepareShareRange;
  final GetShareAyahsUseCase _getShareAyahs;
  final ShareContentUseCase _shareContent;
  final GetRecitersUseCase _getReciters;

  CancelToken? _cancelToken;

  void configureAudioClip({
    required int surahNumber,
    required int fromAyah,
    required int toAyah,
    int? minAyah,
    int? maxAyah,
    required String reciterName,
    required String serverUrl,
    String? reciterFolder,
  }) {
    logger.d(
      '[AppLaunch][ShareCubit.configureAudioClip]: Start in (${DateTime.now()})',
    );
    final effectiveMin = minAyah ?? 1;
    final effectiveMax = maxAyah ?? getVerseCount(surahNumber);

    developer.log(
      '[SHARE_CUBIT] configureAudioClip | surah=$surahNumber | range=$fromAyah-$toAyah | bounds=$effectiveMin-$effectiveMax',
    );

    final result = _prepareShareRange(
      surahNumber: surahNumber,
      fromAyah: fromAyah.clamp(effectiveMin, effectiveMax),
      toAyah: toAyah.clamp(effectiveMin, effectiveMax),
    );

    emit(
      state.copyWith(
        status: ShareStatus.idle,
        surahNumber: surahNumber,
        fromAyah: result.fromAyah,
        toAyah: result.toAyah,
        minAyah: minAyah,
        maxAyah: maxAyah,
        reciterName: reciterName,
        reciterServerUrl: serverUrl,
        content: null,
        progress: 0,
        progressMessage: '',
        ayahs: null,
        errorMessage: null,
        reciterOptions: const [],
        isLoadingReciters: false,
        videoPageSpecs: result.videoPageSpecs,
      ),
    );

    _fetchAyahs(surahNumber, result.fromAyah, result.toAyah);
  }

  void updateVerseRange({int? fromAyah, int? toAyah}) {
    if (state.surahNumber == null) return;

    final int min = state.minAyah ?? 1;
    final int max = state.maxAyah ?? getVerseCount(state.surahNumber!);

    final int targetFrom = (fromAyah ?? state.fromAyah!).clamp(min, max);
    final int targetTo = (toAyah ?? state.toAyah!).clamp(targetFrom, max);

    final result = _prepareShareRange(
      surahNumber: state.surahNumber!,
      fromAyah: targetFrom,
      toAyah: targetTo,
    );

    emit(
      state.copyWith(
        status: ShareStatus.idle,
        fromAyah: result.fromAyah,
        toAyah: result.toAyah,
        content: null,
        progress: 0,
        progressMessage: '',
        errorMessage: null,
        videoPageSpecs: result.videoPageSpecs,
      ),
    );

    _fetchAyahs(state.surahNumber!, result.fromAyah, result.toAyah);
  }

  Future<void> _fetchAyahs(int surahNumber, int fromAyah, int toAyah) async {
    logger.d(
      '[AppLaunch][ShareCubit._fetchAyahs]: Start in (${DateTime.now()})',
    );
    try {
      final rangeAyahs = await _getShareAyahs(
        surahNumber: surahNumber,
        fromAyah: fromAyah,
        toAyah: toAyah,
      );

      emit(state.copyWith(ayahs: rangeAyahs));
      unawaited(_preheatSelectionFonts(surahNumber, fromAyah, toAyah));
    } catch (e, st) {
      logger.e('[SHARE_CUBIT] _fetchAyahs failed', error: e, stackTrace: st);
    }
  }

  Future<void> loadReciterOptions() async {
    logger.d(
      '[AppLaunch][ShareCubit.loadReciterOptions]: Start in (${DateTime.now()})',
    );
    if (state.surahNumber == null) return;
    if (state.isLoadingReciters) return;
    emit(state.copyWith(isLoadingReciters: true));

    final result = await _getReciters();
    result.fold(
      (failure) {
        emit(
          state.copyWith(
            isLoadingReciters: false,
            errorMessage: failure.message,
          ),
        );
      },
      (reciters) {
        final options = buildShareReciterOptions(
          reciters: reciters,
          surahNumber: state.surahNumber!,
          selectedReciterName: state.reciterName ?? '',
          selectedServerUrl: state.reciterServerUrl ?? '',
        );
        emit(state.copyWith(isLoadingReciters: false, reciterOptions: options));
      },
    );
  }

  /// Updates the selected reciter.
  void updateReciter({required String name, required String serverUrl}) {
    emit(state.copyWith(reciterName: name, reciterServerUrl: serverUrl));
  }

  /// Updates the screenshot layout.
  void updateScreenshotLayout(ShareScreenshotLayout layout) {
    emit(state.copyWith(screenshotLayout: layout));
  }

  AudioClipConfig? _buildAudioConfig() {
    final surahNumber = state.surahNumber;
    final fromAyah = state.fromAyah;
    final toAyah = state.toAyah;
    final reciterName = state.reciterName;
    final serverUrl = state.reciterServerUrl;

    if (surahNumber == null ||
        fromAyah == null ||
        toAyah == null ||
        reciterName == null ||
        serverUrl == null) {
      return null;
    }

    final folder = ReciterAudioMapping.resolveFolder(serverUrl);
    return AudioClipConfig(
      surahNumber: surahNumber,
      fromAyah: fromAyah,
      toAyah: toAyah,
      reciterName: reciterName,
      reciterFolder: folder,
      serverUrl: serverUrl,
    );
  }

  /// Automatically registers required QCF fonts in the engine as soon as a
  /// selection is made. This ensures the share preview and generation renderers
  /// don't get stuck on a loading spinner.
  Future<void> _preheatSelectionFonts(
    int surahNumber,
    int fromAyah,
    int toAyah,
  ) async {
    try {
      final Set<int> uniquePages = {};
      for (int i = fromAyah; i <= toAyah; i++) {
        uniquePages.add(getPageNumber(surahNumber, i));
      }

      for (final page in uniquePages) {
        await quranQcfLocator<QuranFontService>().ensureSingleFontLoaded(page);
      }
    } catch (e) {
      logger.w('[SHARE_CUBIT] _preheatSelectionFonts failed: $e');
    }
  }

  ShareContent _withLocalizedSurahName(
    ShareContent content, {
    required String surahName,
  }) {
    return switch (content) {
      ShareScreenshot(:final filePath, :final pageNumber) =>
        ShareContent.screenshot(
          filePath: filePath,
          surahName: surahName,
          pageNumber: pageNumber,
        ),
      ShareAudioClip(
        :final filePath,
        :final fromAyah,
        :final toAyah,
        :final reciterName,
      ) =>
        ShareContent.audioClip(
          filePath: filePath,
          surahName: surahName,
          fromAyah: fromAyah,
          toAyah: toAyah,
          reciterName: reciterName,
        ),
      ShareVideo(
        :final filePath,
        :final fromAyah,
        :final toAyah,
        :final reciterName,
      ) =>
        ShareContent.video(
          filePath: filePath,
          surahName: surahName,
          fromAyah: fromAyah,
          toAyah: toAyah,
          reciterName: reciterName,
        ),
      ShareText(:final filePath, :final text) => ShareContent.text(
        filePath: filePath,
        surahName: surahName,
        text: text,
      ),
    };
  }

  /// Captures a screenshot and enters review mode.
  Future<void> prepareScreenshot({
    required WidgetCaptureHandle handle,
    required String surahName,
    required int pageNumber,
    required String appName,
    required String sharedViaLabel,
    required String preparingImageLabel,
    bool brandCapture = true,
    Color? footerBackgroundColor,
    Color? footerForegroundColor,
  }) async {
    logger.d(
      '[AppLaunch][ShareCubit.prepareScreenshot]: Start in (${DateTime.now()})',
    );
    emit(
      state.copyWith(
        status: ShareStatus.capturing,
        content: null,
        progress: 0,
        progressMessage: preparingImageLabel,
        errorMessage: null,
      ),
    );

    try {
      // Ensure the font for the page is loaded to prevent fallback to system fonts,
      // which would cause incorrect text metrics and layout overflows.
      await quranQcfLocator<QuranFontService>().ensureSingleFontLoaded(
        pageNumber,
      );

      final content = await _captureScreenshot(
        handle: handle,
        surahName: surahName,
        pageNumber: pageNumber,
        appName: appName,
        sharedViaLabel: sharedViaLabel,
        brandCapture: brandCapture,
        footerBackgroundColor: footerBackgroundColor,
        footerForegroundColor: footerForegroundColor,
      );
      emit(state.copyWith(status: ShareStatus.reviewing, content: content));
    } catch (e, st) {
      logger.e(
        '[SHARE_CUBIT] prepareScreenshot failed',
        error: e,
        stackTrace: st,
      );
      emit(
        state.copyWith(
          status: ShareStatus.error,
          errorMessage: _userFacingError(e),
        ),
      );
    }
  }

  /// Captures a screenshot of the current page and shares it.
  Future<void> captureAndShareScreenshot({
    required WidgetCaptureHandle handle,
    required String surahName,
    required int pageNumber,
    required String appName,
    required String sharedViaLabel,
    Color? footerBackgroundColor,
    Color? footerForegroundColor,
  }) async {
    logger.d(
      '[AppLaunch][ShareCubit.captureAndShareScreenshot]: Start in (${DateTime.now()})',
    );
    emit(state.copyWith(status: ShareStatus.sharing));
    try {
      await quranQcfLocator<QuranFontService>().ensureSingleFontLoaded(
        pageNumber,
      );
      final content = await _captureScreenshot(
        handle: handle,
        surahName: surahName,
        pageNumber: pageNumber,
        appName: appName,
        sharedViaLabel: sharedViaLabel,
        footerBackgroundColor: footerBackgroundColor,
        footerForegroundColor: footerForegroundColor,
      );
      await _shareContent(content);
      await _shareContent.cleanup();
      emit(state.copyWith(status: ShareStatus.idle));
    } catch (e, st) {
      logger.e(
        '[SHARE_CUBIT] captureAndShareScreenshot failed',
        error: e,
        stackTrace: st,
      );
      emit(
        state.copyWith(
          status: ShareStatus.error,
          errorMessage: _userFacingError(e),
        ),
      );
    }
  }

  /// Generates the audio clip and enters review mode.
  Future<void> prepareAudioClip({
    required String surahName,
    required ShareProgressMessages progressMessages,
    int? maxDurationSeconds,
  }) async {
    logger.d(
      '[AppLaunch][ShareCubit.prepareAudioClip]: Start in (${DateTime.now()})',
    );
    final config = _buildAudioConfig();
    if (config == null) return;

    final int tAudio = DateTime.now().millisecondsSinceEpoch;
    logger.d(
      '[AUDIO_GEN] prepareAudioClip start | surah=${config.surahNumber} ${config.fromAyah}-${config.toAyah} | t=${tAudio}ms',
    );

    _cancelToken?.cancel();
    _cancelToken = CancelToken();
    emit(
      state.copyWith(
        status: ShareStatus.generating,
        progress: 0,
        progressMessage: progressMessages.preparingAudioClip,
        errorMessage: null,
      ),
    );

    try {
      final content = await _generateAudioClip(
        config: config,
        progressMessages: progressMessages.audioClip,
        maxDurationSeconds: maxDurationSeconds,
        cancelToken: _cancelToken,
        onProgress: (progress, message) {
          logger.d(
            '[AUDIO_GEN] progress=${(progress * 100).toStringAsFixed(0)}% | "$message" | elapsed=${DateTime.now().millisecondsSinceEpoch - tAudio}ms',
          );
          emit(state.copyWith(progress: progress, progressMessage: message));
        },
      );

      logger.d(
        '[AUDIO_GEN] complete | took=${DateTime.now().millisecondsSinceEpoch - tAudio}ms | file=${content.filePath}',
      );
      emit(
        state.copyWith(
          status: ShareStatus.reviewing,
          content: _withLocalizedSurahName(content, surahName: surahName),
        ),
      );
    } catch (e, st) {
      logger.e(
        '[AUDIO_GEN] ERROR after ${DateTime.now().millisecondsSinceEpoch - tAudio}ms',
        error: e,
        stackTrace: st,
      );
      if (e is! DioException || e.type != DioExceptionType.cancel) {
        emit(
          state.copyWith(
            status: ShareStatus.error,
            errorMessage: _userFacingError(e),
          ),
        );
      } else {
        emit(state.copyWith(status: ShareStatus.idle));
      }
    }
  }

  /// Generates the audio clip and shares it.
  Future<void> generateAndShareAudioClip({
    required String surahName,
    required ShareProgressMessages progressMessages,
    int? maxDurationSeconds,
  }) async {
    await prepareAudioClip(
      surahName: surahName,
      progressMessages: progressMessages,
      maxDurationSeconds: maxDurationSeconds,
    );
    if (state.status == ShareStatus.reviewing &&
        state.content is ShareAudioClip) {
      await shareContent();
    }
  }

  /// Generates a vertical video (9:16) for social media.
  Future<void> generateVideo({
    required String surahName,
    required ShareProgressMessages progressMessages,
    required String appName,
    required String sharedViaLabel,
    required List<WidgetCaptureHandle> handles,
    int? maxDurationSeconds,
  }) async {
    logger.d(
      '[AppLaunch][ShareCubit.generateVideo]: Start in (${DateTime.now()})',
    );
    final audioConfig = _buildAudioConfig();

    logger.d(
      '[VIDEO_GEN] generateVideo called | handlesTotal=${handles.length} | audioConfig=${audioConfig != null}',
    );

    if (audioConfig == null || handles.isEmpty) {
      logger.d(
        '[VIDEO_GEN] generateVideo ABORTED | audioConfig=$audioConfig | handles=${handles.length}',
      );
      return;
    }

    final int tVideo = DateTime.now().millisecondsSinceEpoch;
    logger.d(
      '[VIDEO_GEN] start | surah=${audioConfig.surahNumber} ${audioConfig.fromAyah}-${audioConfig.toAyah} | pages=${handles.length} | t=${tVideo}ms',
    );

    _cancelToken?.cancel();
    _cancelToken = CancelToken();
    emit(
      state.copyWith(
        status: ShareStatus.generating,
        progress: 0,
        progressMessage: progressMessages.preparingVideo,
        errorMessage: null,
        content: null,
      ),
    );

    try {
      final content = await _generateVideo(
        handles: handles,
        config: audioConfig,
        appName: appName,
        sharedViaLabel: sharedViaLabel,
        progressMessages: progressMessages,
        maxDurationSeconds: maxDurationSeconds,
        cancelToken: _cancelToken,
        onProgress: (p, m) {
          logger.d(
            '[VIDEO_GEN] progress=${(p * 100).toStringAsFixed(0)}% | "$m" | elapsed=${DateTime.now().millisecondsSinceEpoch - tVideo}ms',
          );
          emit(state.copyWith(progress: p, progressMessage: m));
        },
        onFrameCaptureStarted: (index) {
          emit(state.copyWith(capturingIndex: index));
        },
      );

      logger.d(
        '[VIDEO_GEN] complete | took=${DateTime.now().millisecondsSinceEpoch - tVideo}ms | file=${content.filePath}',
      );
      emit(
        state.copyWith(
          status: ShareStatus.reviewing,
          capturingIndex: null,
          content: _withLocalizedSurahName(content, surahName: surahName),
        ),
      );
    } catch (e, st) {
      logger.e(
        '[VIDEO_GEN] ERROR after ${DateTime.now().millisecondsSinceEpoch - tVideo}ms',
        error: e,
        stackTrace: st,
      );
      if (e is! DioException || e.type != DioExceptionType.cancel) {
        emit(
          state.copyWith(
            status: ShareStatus.error,
            capturingIndex: null,
            errorMessage: _userFacingError(
              e,
              videoMessages: progressMessages.video,
            ),
          ),
        );
      } else {
        emit(state.copyWith(status: ShareStatus.idle, capturingIndex: null));
      }
    }
  }

  void discardPreparedContent() {
    unawaited(_shareContent.cleanup());
    emit(
      state.copyWith(
        status: ShareStatus.idle,
        content: null,
        progress: 0,
        progressMessage: '',
        errorMessage: null,
      ),
    );
  }

  /// Shares the currently reviewed content.
  Future<void> shareContent() async {
    if (state.content == null) return;
    final int tShare = DateTime.now().millisecondsSinceEpoch;
    logger.d('[SHARE_FLOW] shareContent start | t=${tShare}ms');
    emit(state.copyWith(status: ShareStatus.sharing));
    try {
      await _shareContent(state.content!);
      await _shareContent.cleanup();
      logger.d(
        '[SHARE_FLOW] shareContent success | took=${DateTime.now().millisecondsSinceEpoch - tShare}ms',
      );
      emit(state.copyWith(status: ShareStatus.idle, content: null));
    } catch (e, st) {
      logger.e('[SHARE_CUBIT] shareContent failed', error: e, stackTrace: st);
      logger.e(
        '[SHARE_FLOW] shareContent failure after ${DateTime.now().millisecondsSinceEpoch - tShare}ms',
        error: e,
        stackTrace: st,
      );
      emit(
        state.copyWith(
          status: ShareStatus.error,
          errorMessage: _userFacingError(e),
        ),
      );
    }
  }

  /// Exports the currently reviewed media as a persistent copy.
  Future<String?> savePreparedContent() async {
    final content = state.content;
    if (content == null || content is ShareText) return null;

    final int tSave = DateTime.now().millisecondsSinceEpoch;
    logger.d('[SHARE_FLOW] savePreparedContent start | t=${tSave}ms');
    try {
      final exportedPath = await _shareContent.exportContent(content);
      logger.d(
        '[SHARE_FLOW] savePreparedContent success | took=${DateTime.now().millisecondsSinceEpoch - tSave}ms | path=$exportedPath',
      );
      return exportedPath;
    } catch (e, st) {
      logger.e(
        '[SHARE_FLOW] savePreparedContent failure after ${DateTime.now().millisecondsSinceEpoch - tSave}ms',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Shares Quran metadata as plain text without generating a media asset.
  Future<void> shareText(String text, {String surahName = ''}) async {
    emit(
      state.copyWith(
        status: ShareStatus.sharing,
        content: null,
        errorMessage: null,
      ),
    );

    try {
      await _shareContent(ShareContent.text(surahName: surahName, text: text));
      emit(state.copyWith(status: ShareStatus.idle));
    } catch (e, st) {
      logger.e('[SHARE_CUBIT] shareText failed', error: e, stackTrace: st);
      emit(
        state.copyWith(
          status: ShareStatus.error,
          errorMessage: _userFacingError(e),
        ),
      );
    }
  }

  /// Returns a clean, user-facing error string without internal stack details.
  String _userFacingError(Object e, {VideoProgressMessages? videoMessages}) {
    if (e is VideoGenerationFailure) {
      if (videoMessages == null) {
        return e.message ?? 'Failed to generate reel.';
      }

      return switch (e.reason) {
        VideoGenerationFailureReason.invalidFrameFormat =>
          videoMessages.videoGenerationFailedInvalidFrame,
        VideoGenerationFailureReason.missingScreenshot =>
          videoMessages.videoGenerationFailedMissingScreenshot,
        VideoGenerationFailureReason.invalidOutput =>
          videoMessages.videoGenerationFailedInvalidOutput,
        VideoGenerationFailureReason.encodingFailed =>
          videoMessages.videoGenerationFailed,
      };
    }

    if (e is StateError) return e.message;
    final msg = e.toString();
    // Strip "Exception:" / "StateError:" prefixes that leak implementation detail.
    return msg.replaceFirst(RegExp(r'^[\w]+:\s*'), '');
  }

  void cancelGeneration() {
    _cancelToken?.cancel();
    _cancelToken = null;
    emit(
      state.copyWith(
        status: ShareStatus.idle,
        progress: 0,
        progressMessage: '',
      ),
    );
  }
}
