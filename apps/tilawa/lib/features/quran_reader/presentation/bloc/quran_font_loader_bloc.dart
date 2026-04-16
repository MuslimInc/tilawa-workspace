import 'dart:async';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/logger.dart';

import '../../domain/usecases/check_fonts_downloaded_use_case.dart';
import '../../domain/usecases/download_quran_fonts_use_case.dart';
import '../../domain/usecases/load_quran_fonts_to_engine_use_case.dart';
import '../../domain/usecases/update_current_page_use_case.dart';

part 'quran_font_loader_bloc.freezed.dart';

@freezed
abstract class QuranFontLoaderEvent with _$QuranFontLoaderEvent {
  const factory QuranFontLoaderEvent.initialize({
    required int initialPageNumber,
  }) = _Initialize;
  const factory QuranFontLoaderEvent.updateProgress(double progress) =
      _UpdateProgress;
  const factory QuranFontLoaderEvent.updateCurrentPage(int pageNumber) =
      _UpdateCurrentPage;
}

@freezed
abstract class QuranFontLoaderState with _$QuranFontLoaderState {
  const factory QuranFontLoaderState.initial() = _Initial;
  const factory QuranFontLoaderState.checking() = _Checking;
  const factory QuranFontLoaderState.downloading(
    double progress, {
    @Default(0.0) double speedKbps,
    @Default(0) int etaSeconds,
  }) = _Downloading;
  const factory QuranFontLoaderState.registering() = _Registering;
  const factory QuranFontLoaderState.warming(int current, int total) = _Warming;
  const factory QuranFontLoaderState.success() = _Success;
  const factory QuranFontLoaderState.error(String message) = _Error;
}

@injectable
class QuranFontLoaderBloc
    extends Bloc<QuranFontLoaderEvent, QuranFontLoaderState> {
  QuranFontLoaderBloc(
    this._checkFontsDownloadedUseCase,
    this._downloadQuranFontsUseCase,
    this._loadQuranFontsToEngineUseCase,
    this._updateCurrentPageUseCase,
  ) : super(const QuranFontLoaderState.initial()) {
    on<_Initialize>(_onInitialize, transformer: droppable());
    on<_UpdateProgress>(_onUpdateProgress);
    on<_UpdateCurrentPage>(_onUpdateCurrentPage);
  }

  final CheckFontsDownloadedUseCase _checkFontsDownloadedUseCase;
  final DownloadQuranFontsUseCase _downloadQuranFontsUseCase;
  final LoadQuranFontsToEngineUseCase _loadQuranFontsToEngineUseCase;
  final UpdateCurrentPageUseCase _updateCurrentPageUseCase;

  Future<void> ensurePageWindowLoaded(int pageNumber) {
    return _loadQuranFontsToEngineUseCase.ensurePageWindowLoaded(
      pageNumber: pageNumber,
    );
  }

  Future<void> ensureSingleFontLoaded(int pageNumber) {
    return _loadQuranFontsToEngineUseCase.ensureSingleFontLoaded(pageNumber);
  }

  Future<void> ensureFontReady(
    int pageNumber, {
    Duration timeout = const Duration(seconds: 1),
  }) async {
    if (isFontLoaded(pageNumber)) return;

    final Future<void> loadFuture = _loadQuranFontsToEngineUseCase
        .ensureSingleFontLoaded(pageNumber);
    var loadCompleted = false;
    unawaited(
      loadFuture.whenComplete(() {
        loadCompleted = true;
      }),
    );

    final Stopwatch stopwatch = Stopwatch()..start();
    while (!isFontLoaded(pageNumber) && !loadCompleted) {
      if (stopwatch.elapsed >= timeout) {
        throw TimeoutException(
          'Font for page $pageNumber did not become ready within $timeout',
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
  }

  bool isFontLoaded(int pageNumber) =>
      _loadQuranFontsToEngineUseCase.isFontLoaded(pageNumber);

  void pauseBackgroundWarmUp() =>
      _loadQuranFontsToEngineUseCase.pauseBackgroundWarmUp();

  void resumeBackgroundWarmUp() =>
      _loadQuranFontsToEngineUseCase.resumeBackgroundWarmUp();

  Future<void> _onInitialize(
    _Initialize event,
    Emitter<QuranFontLoaderState> emit,
  ) async {
    final int t0 = DateTime.now().millisecondsSinceEpoch;
    _debugLog(() => '[FONT] _onInitialize start | t=${t0}ms');

    if (_loadQuranFontsToEngineUseCase.isFontLoaded(event.initialPageNumber)) {
      _debugLog(
        () =>
            '[FONT] initial page font already loaded → ensuring Quran data | t=${DateTime.now().millisecondsSinceEpoch}ms',
      );
      await _loadQuranFontsToEngineUseCase.ensureQuranDataLoaded();
      _debugLog(
        () =>
            '[FONT] initialize short-circuit success | t=${DateTime.now().millisecondsSinceEpoch}ms',
      );
      emit(const QuranFontLoaderState.success());
      return;
    }

    emit(const QuranFontLoaderState.checking());
    _debugLog(
      () =>
          '[FONT] state=checking | t=${DateTime.now().millisecondsSinceEpoch}ms',
    );

    try {
      final int tCheck = DateTime.now().millisecondsSinceEpoch;
      final isDownloaded = await _checkFontsDownloadedUseCase();
      _debugLog(
        () =>
            '[FONT] checkFontsDownloaded=$isDownloaded | took=${DateTime.now().millisecondsSinceEpoch - tCheck}ms',
      );

      if (!isDownloaded) {
        emit(const QuranFontLoaderState.downloading(0));
        _debugLog(
          () =>
              '[FONT] state=downloading(0%) | t=${DateTime.now().millisecondsSinceEpoch}ms',
        );
        final int tDownload = DateTime.now().millisecondsSinceEpoch;
        var lastEmittedProgress = 0.0;
        // progress 0.0–0.8 = download phase, 0.8–1.0 = extract phase.
        // Map download-phase progress back to 0–100% for speed/ETA calculation.
        const double downloadPhaseEnd = 0.8;
        const int minSpeedSampleMs = 250;
        await _downloadQuranFontsUseCase(
          onProgress: (progress) {
            if (isClosed) return;
            final currentPercent = (progress * 100).floor();
            final lastPercent = (lastEmittedProgress * 100).floor();
            if (currentPercent > lastPercent || progress >= 1.0) {
              lastEmittedProgress = progress;
              final int elapsedMs =
                  DateTime.now().millisecondsSinceEpoch - tDownload;
              double speedKbps = 0;
              int etaSeconds = 0;
              // Only compute speed/ETA during the download phase (progress ≤ 0.8).
              if (progress <= downloadPhaseEnd &&
                  elapsedMs >= minSpeedSampleMs) {
                final double downloadFraction = progress / downloadPhaseEnd;
                // Total zip is ~52444 KB; estimate received bytes from fraction.
                const double totalKb = 52444.0;
                final double receivedKb = downloadFraction * totalKb;
                speedKbps = receivedKb / (elapsedMs / 1000);
                if (speedKbps > 0) {
                  final double remainingKb = totalKb - receivedKb;
                  etaSeconds = (remainingKb / speedKbps).ceil();
                }
              }
              _debugLog(
                () =>
                    '[FONT] download progress=${(progress * 100).toStringAsFixed(1)}% | elapsed=${elapsedMs}ms | speed=${speedKbps.toStringAsFixed(0)}KB/s | eta=${etaSeconds}s',
              );
              emit(
                QuranFontLoaderState.downloading(
                  progress,
                  speedKbps: speedKbps,
                  etaSeconds: etaSeconds,
                ),
              );
            }
          },
        );
        _debugLog(
          () =>
              '[FONT] download+extract done | total=${DateTime.now().millisecondsSinceEpoch - tDownload}ms',
        );
      }

      emit(const QuranFontLoaderState.registering());
      // Let the registering state paint once, but do not introduce an
      // artificial startup stall.
      await Future<void>.delayed(Duration.zero);

      _debugLog(
        () =>
            '[FONT] state=registering | t=${DateTime.now().millisecondsSinceEpoch}ms',
      );
      final int tRegister = DateTime.now().millisecondsSinceEpoch;
      _debugLog(
        () =>
            '[FONT] await ensureSingleFontLoaded starting... | page=${event.initialPageNumber}',
      );

      final Future<void> ensureInitialFontFuture = ensureFontReady(
        event.initialPageNumber,
      );

      _debugLog(() => '[FONT] await ensureQuranDataLoaded starting...');
      final Future<void> ensureDataFuture = _loadQuranFontsToEngineUseCase
          .ensureQuranDataLoaded()
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('ensureQuranDataLoaded timed out');
            },
          );

      await Future.wait([ensureInitialFontFuture, ensureDataFuture]);

      _debugLog(
        () =>
            '[FONT] await ensureSingleFontLoaded finished | took=${DateTime.now().millisecondsSinceEpoch - tRegister}ms',
      );
      _debugLog(() => '[FONT] await ensureQuranDataLoaded finished');

      emit(const QuranFontLoaderState.success());
      _debugLog(
        () =>
            '[FONT] state=success | total=${DateTime.now().millisecondsSinceEpoch - t0}ms',
      );
    } catch (e) {
      _debugLog(
        () => '[FONT] ERROR: $e | t=${DateTime.now().millisecondsSinceEpoch}ms',
      );
      emit(QuranFontLoaderState.error(e.toString()));
    }
  }

  void _onUpdateProgress(
    _UpdateProgress event,
    Emitter<QuranFontLoaderState> emit,
  ) {
    emit(QuranFontLoaderState.downloading(event.progress));
  }

  void _onUpdateCurrentPage(
    _UpdateCurrentPage event,
    Emitter<QuranFontLoaderState> emit,
  ) {
    _updateCurrentPageUseCase(event.pageNumber);
  }
}

void _debugLog(String Function() messageBuilder) {
  if (!kReleaseMode) {
    logger.i(messageBuilder());
  }
}
