import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart' show GlobalKey;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:tilawa_core/logger.dart';

import '../../../quran_reader/domain/entities/entities.dart';
import '../../../quran_reader/domain/repositories/quran_reader_repository.dart';
import '../../data/services/reciter_audio_mapping.dart';
import '../../domain/entities/audio_clip_config.dart';
import '../../domain/entities/share_content.dart';
import '../../domain/entities/share_progress_messages.dart';
import '../../domain/usecases/capture_screenshot_use_case.dart';
import '../../domain/usecases/generate_audio_clip_use_case.dart';
import '../../domain/usecases/generate_video_use_case.dart';
import '../../domain/usecases/share_content_use_case.dart';
import 'share_state.dart';

@injectable
class ShareCubit extends Cubit<ShareState> {
  ShareCubit(
    this._captureScreenshot,
    this._generateAudioClip,
    this._generateVideo,
    this._quranRepository,
    this._shareContent,
  ) : super(const ShareState());

  final CaptureScreenshotUseCase _captureScreenshot;
  final GenerateAudioClipUseCase _generateAudioClip;
  final GenerateVideoUseCase _generateVideo;
  final QuranReaderRepository _quranRepository;
  final ShareContentUseCase _shareContent;

  CancelToken? _cancelToken;

  /// Initializes the sharing flow with current context.
  void configureAudioClip({
    required int surahNumber,
    required int fromAyah,
    required int toAyah,
    required String reciterName,
    required String serverUrl,
    String? reciterFolder,
  }) {
    emit(
      state.copyWith(
        status: ShareStatus.idle,
        surahNumber: surahNumber,
        fromAyah: fromAyah,
        toAyah: toAyah,
        reciterName: reciterName,
        reciterServerUrl: serverUrl,
        content: null,
        progress: 0,
        progressMessage: '',
        ayahs: null,
        errorMessage: null,
      ),
    );

    _fetchAyahs(surahNumber, fromAyah, toAyah);
  }

  /// Updates the verse range.
  void updateVerseRange({int? fromAyah, int? toAyah}) {
    final nextFrom = fromAyah ?? state.fromAyah;
    final nextTo = toAyah ?? state.toAyah;

    emit(
      state.copyWith(
        status: ShareStatus.idle,
        fromAyah: nextFrom,
        toAyah: nextTo,
        content: null,
        progress: 0,
        progressMessage: '',
        errorMessage: null,
      ),
    );

    if (state.surahNumber != null && nextFrom != null && nextTo != null) {
      _fetchAyahs(state.surahNumber!, nextFrom, nextTo);
    }
  }

  Future<void> _fetchAyahs(int surahNumber, int fromAyah, int toAyah) async {
    try {
      final surahContent = await _quranRepository.getSurahContent(surahNumber);
      final rangeAyahs = surahContent.ayahs
          .where(
            (a) => a.numberInSurah >= fromAyah && a.numberInSurah <= toAyah,
          )
          .map(
            (a) => PageAyahInfo(
              surahNumber: surahNumber,
              surahName: surahContent.name,
              surahNameEnglish: surahContent.nameEnglish,
              ayahNumber: a.numberInSurah,
              text: a.textUthmani ?? a.text,
              words: null,
            ),
          )
          .toList();

      emit(state.copyWith(ayahs: rangeAyahs));
      unawaited(_preheatSelectionFonts(surahNumber, fromAyah, toAyah));
    } catch (e, st) {
      logger.e('[SHARE_CUBIT] _fetchAyahs failed', error: e, stackTrace: st);
      // Non-fatal: ayah list is supplementary metadata; generation can proceed.
    }
  }

  /// Updates the selected reciter.
  void updateReciter({required String name, required String serverUrl}) {
    emit(state.copyWith(reciterName: name, reciterServerUrl: serverUrl));
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
        await QuranFontService.instance.ensureSingleFontLoaded(page);
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
    required GlobalKey boundaryKey,
    required String surahName,
    required int pageNumber,
    required String appName,
    required String sharedViaLabel,
    required String preparingImageLabel,
    bool brandCapture = true,
  }) async {
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
      await QuranFontService.instance.ensureSingleFontLoaded(pageNumber);

      final content = await _captureScreenshot(
        boundaryKey: boundaryKey,
        surahName: surahName,
        pageNumber: pageNumber,
        appName: appName,
        sharedViaLabel: sharedViaLabel,
        brandCapture: brandCapture,
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
    required GlobalKey boundaryKey,
    required String surahName,
    required int pageNumber,
    required String appName,
    required String sharedViaLabel,
  }) async {
    emit(state.copyWith(status: ShareStatus.sharing));
    try {
      await QuranFontService.instance.ensureSingleFontLoaded(pageNumber);
      final content = await _captureScreenshot(
        boundaryKey: boundaryKey,
        surahName: surahName,
        pageNumber: pageNumber,
        appName: appName,
        sharedViaLabel: sharedViaLabel,
      );
      await _shareContent(content);
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
    required List<GlobalKey> boundaryKeys,
    int? maxDurationSeconds,
  }) async {
    final audioConfig = _buildAudioConfig();
    final List<GlobalKey> activeBoundaryKeys = boundaryKeys
        .where((key) => key.currentContext != null)
        .toList();

    logger.d(
      '[VIDEO_GEN] generateVideo called | boundaryKeysTotal=${boundaryKeys.length} | active=${activeBoundaryKeys.length} | audioConfig=${audioConfig != null}',
    );

    if (audioConfig == null || activeBoundaryKeys.isEmpty) {
      logger.d(
        '[VIDEO_GEN] generateVideo ABORTED | audioConfig=$audioConfig | active=${activeBoundaryKeys.length}',
      );
      return;
    }

    final int tVideo = DateTime.now().millisecondsSinceEpoch;
    logger.d(
      '[VIDEO_GEN] start | surah=${audioConfig.surahNumber} ${audioConfig.fromAyah}-${audioConfig.toAyah} | pages=${activeBoundaryKeys.length} | t=${tVideo}ms',
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
        boundaryKeys: activeBoundaryKeys,
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
            errorMessage: _userFacingError(e),
          ),
        );
      } else {
        emit(state.copyWith(status: ShareStatus.idle, capturingIndex: null));
      }
    }
  }

  void discardPreparedContent() {
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
    emit(state.copyWith(status: ShareStatus.sharing));
    try {
      await _shareContent(state.content!);
      emit(state.copyWith(status: ShareStatus.idle, content: null));
    } catch (e, st) {
      logger.e('[SHARE_CUBIT] shareContent failed', error: e, stackTrace: st);
      emit(
        state.copyWith(
          status: ShareStatus.error,
          errorMessage: _userFacingError(e),
        ),
      );
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
  String _userFacingError(Object e) {
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
