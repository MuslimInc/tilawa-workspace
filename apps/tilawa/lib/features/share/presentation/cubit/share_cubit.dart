import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../data/services/reciter_audio_mapping.dart';
import '../../domain/entities/audio_clip_config.dart';
import '../../domain/entities/share_content.dart';
import '../../domain/usecases/capture_screenshot_use_case.dart';
import '../../domain/usecases/generate_audio_clip_use_case.dart';
import '../../domain/usecases/generate_reel_use_case.dart';
import '../../domain/usecases/share_content_use_case.dart';
import 'share_state.dart';

/// Manages the share flow for both screenshots and audio clips.
///
/// This is an ephemeral cubit — no state persistence is needed.
@injectable
class ShareCubit extends Cubit<ShareState> {
  ShareCubit(
    this._captureScreenshot,
    this._generateAudioClip,
    this._generateReel,
    this._shareContent,
  ) : super(const ShareState());

  final CaptureScreenshotUseCase _captureScreenshot;
  final GenerateAudioClipUseCase _generateAudioClip;
  final GenerateReelUseCase _generateReel;
  final ShareContentUseCase _shareContent;

  CancelToken? _cancelToken;

  // ---------------------------------------------------------------------------
  // Screenshot flow
  // ---------------------------------------------------------------------------

  /// Captures the current Quran page and opens the share sheet.
  Future<void> captureAndShareScreenshot({
    required GlobalKey boundaryKey,
    required String surahName,
    required int pageNumber,
    required String appName,
    required String sharedViaLabel,
  }) async {
    emit(state.copyWith(status: ShareStatus.capturing, errorMessage: null));

    try {
      final content = await _captureScreenshot(
        boundaryKey: boundaryKey,
        surahName: surahName,
        pageNumber: pageNumber,
        appName: appName,
        sharedViaLabel: sharedViaLabel,
      );

      emit(state.copyWith(status: ShareStatus.sharing, content: content));

      await _shareContent(content);

      emit(const ShareState()); // Reset to idle
    } catch (e) {
      emit(state.copyWith(
        status: ShareStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // Audio clip flow
  // ---------------------------------------------------------------------------

  /// Configures the audio clip parameters before generation.
  void configureAudioClip({
    required int surahNumber,
    required int fromAyah,
    required int toAyah,
    required String reciterName,
    required String reciterServerUrl,
    GlobalKey? boundaryKey,
  }) {
    emit(state.copyWith(
      surahNumber: surahNumber,
      fromAyah: fromAyah,
      toAyah: toAyah,
      reciterName: reciterName,
      reciterServerUrl: reciterServerUrl,
      boundaryKey: boundaryKey,
      errorMessage: null,
    ));
  }

  /// Updates the verse range.
  void updateVerseRange({int? fromAyah, int? toAyah}) {
    emit(state.copyWith(
      fromAyah: fromAyah ?? state.fromAyah,
      toAyah: toAyah ?? state.toAyah,
    ));
  }

  /// Updates the selected reciter.
  void updateReciter({
    required String reciterName,
    required String reciterServerUrl,
  }) {
    emit(state.copyWith(
      reciterName: reciterName,
      reciterServerUrl: reciterServerUrl,
    ));
  }

  /// Generates the audio clip and opens the share sheet.
  Future<void> generateAndShareAudioClip({
    required String surahName,
  }) async {
    final surahNumber = state.surahNumber;
    final fromAyah = state.fromAyah;
    final toAyah = state.toAyah;
    final serverUrl = state.reciterServerUrl;
    final reciterName = state.reciterName;

    if (surahNumber == null ||
        fromAyah == null ||
        toAyah == null ||
        serverUrl == null ||
        reciterName == null) {
      emit(state.copyWith(
        status: ShareStatus.error,
        errorMessage: 'Missing audio clip configuration.',
      ));
      return;
    }

    _cancelToken = CancelToken();
    emit(state.copyWith(
      status: ShareStatus.generating,
      progress: 0.0,
      progressMessage: '',
      errorMessage: null,
    ));

    try {
      final reciterFolder = ReciterAudioMapping.resolveFolder(serverUrl);
      final config = AudioClipConfig(
        surahNumber: surahNumber,
        fromAyah: fromAyah,
        toAyah: toAyah,
        reciterName: reciterName,
        reciterFolder: reciterFolder,
        serverUrl: serverUrl,
      );

      final content = await _generateAudioClip(
        config: config,
        onProgress: (progress, message) {
          if (!isClosed) {
            emit(state.copyWith(
              progress: progress,
              progressMessage: message,
            ));
          }
        },
        cancelToken: _cancelToken,
      );

      // Fill in the localized surah name.
      final namedContent = switch (content) {
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
        _ => content,
      };

      emit(state.copyWith(
        status: ShareStatus.sharing,
        content: namedContent,
        progress: 1.0,
      ));

      await _shareContent(namedContent);

      emit(const ShareState()); // Reset to idle
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        emit(const ShareState()); // Cancelled — reset silently
      } else {
        emit(state.copyWith(
          status: ShareStatus.error,
          errorMessage: e.message ?? 'Download failed.',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: ShareStatus.error,
        errorMessage: e.toString(),
      ));
    } finally {
      _cancelToken = null;
    }
  }

  /// Generates a vertical video (9:16) for social media.
  Future<void> generateReel({
    required String surahName,
  }) async {
    final surahNumber = state.surahNumber;
    final fromAyah = state.fromAyah;
    final toAyah = state.toAyah;
    final reciterName = state.reciterName;
    final serverUrl = state.reciterServerUrl;
    final boundaryKey = state.boundaryKey;

    if (surahNumber == null ||
        fromAyah == null ||
        toAyah == null ||
        reciterName == null ||
        serverUrl == null ||
        boundaryKey == null) {
      return;
    }

    _cancelToken = CancelToken();
    emit(state.copyWith(
      status: ShareStatus.generating,
      progress: 0.0,
      progressMessage: 'Initializing reel generation...',
      errorMessage: null,
    ));

    try {
      final reciterFolder = ReciterAudioMapping.resolveFolder(serverUrl);
      final config = AudioClipConfig(
        surahNumber: surahNumber,
        fromAyah: fromAyah,
        toAyah: toAyah,
        reciterName: reciterName,
        reciterFolder: reciterFolder,
        serverUrl: serverUrl,
      );

      final content = await _generateReel(
        boundaryKey: boundaryKey,
        config: config,
        appName: 'Tilawa',
        sharedViaLabel: 'Shared via Tilawa',
        onProgress: (progress, message) {
          if (!isClosed) {
            emit(state.copyWith(
              progress: progress,
              progressMessage: message,
            ));
          }
        },
        cancelToken: _cancelToken,
      );

      // Fill in localized surah name.
      final namedContent = switch (content) {
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
        _ => content,
      };

      emit(state.copyWith(
        status: ShareStatus.reviewing,
        content: namedContent,
        progress: 1.0,
      ));
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        emit(const ShareState()); // Cancelled — reset silently
      } else {
        emit(state.copyWith(
          status: ShareStatus.error,
          errorMessage: e.message ?? 'Reel generation failed.',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: ShareStatus.error,
        errorMessage: e.toString(),
      ));
    } finally {
      _cancelToken = null;
    }
  }

  /// Initiates the final native share for the generated content.
  Future<void> shareContent() async {
    final content = state.content;
    if (content == null) return;

    emit(state.copyWith(status: ShareStatus.sharing));
    try {
      await _shareContent(content);
      emit(const ShareState()); // Return to idle after share
    } catch (e) {
      emit(state.copyWith(
        status: ShareStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Cancels an in-progress audio clip generation.
  void cancelGeneration() {
    _cancelToken?.cancel('User cancelled');
    _cancelToken = null;
  }

  /// Clears any error state and returns to idle.
  void clearError() {
    emit(const ShareState());
  }

  @override
  Future<void> close() {
    cancelGeneration();
    return super.close();
  }
}
