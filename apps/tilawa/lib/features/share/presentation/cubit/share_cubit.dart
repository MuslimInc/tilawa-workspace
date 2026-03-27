import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../data/services/reciter_audio_mapping.dart';
import '../../domain/entities/audio_clip_config.dart';
import '../../domain/entities/share_content.dart';
import '../../domain/entities/share_progress_messages.dart';
import '../../domain/usecases/capture_screenshot_use_case.dart';
import '../../domain/usecases/generate_audio_clip_use_case.dart';
import '../../domain/usecases/generate_reel_use_case.dart';
import '../../domain/usecases/share_content_use_case.dart';
import '../../../quran_reader/domain/entities/entities.dart';
import '../../../quran_reader/domain/repositories/quran_reader_repository.dart';
import 'share_state.dart';

@injectable
class ShareCubit extends Cubit<ShareState> {
  ShareCubit(
    this._captureScreenshot,
    this._generateAudioClip,
    this._generateReel,
    this._quranRepository,
    this._shareContent,
  ) : super(const ShareState());

  final CaptureScreenshotUseCase _captureScreenshot;
  final GenerateAudioClipUseCase _generateAudioClip;
  final GenerateReelUseCase _generateReel;
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
    GlobalKey? boundaryKey,
  }) {
    emit(
      state.copyWith(
        status: ShareStatus.idle,
        surahNumber: surahNumber,
        fromAyah: fromAyah,
        toAyah: toAyah,
        reciterName: reciterName,
        reciterServerUrl: serverUrl,
        boundaryKey: boundaryKey,
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
    } catch (e) {
      // Handle error silently
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
      ShareReel(
        :final filePath,
        :final fromAyah,
        :final toAyah,
        :final reciterName,
      ) =>
        ShareContent.reel(
          filePath: filePath,
          surahName: surahName,
          fromAyah: fromAyah,
          toAyah: toAyah,
          reciterName: reciterName,
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
        boundaryKey: boundaryKey,
        content: null,
        progress: 0,
        progressMessage: preparingImageLabel,
        errorMessage: null,
      ),
    );

    try {
      final content = await _captureScreenshot(
        boundaryKey: boundaryKey,
        surahName: surahName,
        pageNumber: pageNumber,
        appName: appName,
        sharedViaLabel: sharedViaLabel,
        brandCapture: brandCapture,
      );
      emit(state.copyWith(status: ShareStatus.reviewing, content: content));
    } catch (e) {
      emit(
        state.copyWith(status: ShareStatus.error, errorMessage: e.toString()),
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
    emit(state.copyWith(status: ShareStatus.sharing, boundaryKey: boundaryKey));
    try {
      final content = await _captureScreenshot(
        boundaryKey: boundaryKey,
        surahName: surahName,
        pageNumber: pageNumber,
        appName: appName,
        sharedViaLabel: sharedViaLabel,
      );
      await _shareContent(content);
      emit(state.copyWith(status: ShareStatus.idle));
    } catch (e) {
      emit(
        state.copyWith(status: ShareStatus.error, errorMessage: e.toString()),
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
          emit(state.copyWith(progress: progress, progressMessage: message));
        },
      );

      emit(
        state.copyWith(
          status: ShareStatus.reviewing,
          content: _withLocalizedSurahName(content, surahName: surahName),
        ),
      );
    } catch (e) {
      if (e is! DioException || e.type != DioExceptionType.cancel) {
        emit(
          state.copyWith(status: ShareStatus.error, errorMessage: e.toString()),
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
  Future<void> generateReel({
    required String surahName,
    required ShareProgressMessages progressMessages,
    required String appName,
    required String sharedViaLabel,
    GlobalKey? boundaryKey,
    int? maxDurationSeconds,
  }) async {
    final audioConfig = _buildAudioConfig();
    final effectiveBoundaryKey = boundaryKey ?? state.boundaryKey;

    if (audioConfig == null || effectiveBoundaryKey == null) {
      return;
    }

    _cancelToken = CancelToken();
    emit(
      state.copyWith(
        status: ShareStatus.generating,
        progress: 0,
        progressMessage: progressMessages.preparingReel,
        errorMessage: null,
        content: null,
      ),
    );

    try {
      final content = await _generateReel(
        boundaryKey: effectiveBoundaryKey,
        config: audioConfig,
        appName: appName,
        sharedViaLabel: sharedViaLabel,
        progressMessages: progressMessages,
        maxDurationSeconds: maxDurationSeconds,
        cancelToken: _cancelToken,
        onProgress: (p, m) =>
            emit(state.copyWith(progress: p, progressMessage: m)),
      );

      emit(
        state.copyWith(
          status: ShareStatus.reviewing,
          content: _withLocalizedSurahName(content, surahName: surahName),
        ),
      );
    } catch (e) {
      if (e is! DioException || e.type != DioExceptionType.cancel) {
        emit(
          state.copyWith(status: ShareStatus.error, errorMessage: e.toString()),
        );
      } else {
        emit(state.copyWith(status: ShareStatus.idle));
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
    } catch (e) {
      emit(
        state.copyWith(status: ShareStatus.error, errorMessage: e.toString()),
      );
    }
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
