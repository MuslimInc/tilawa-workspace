import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:tilawa_core/logger.dart';

import '../repositories/quran_font_repository.dart';

@lazySingleton
class LoadQuranFontsToEngineUseCase {
  const LoadQuranFontsToEngineUseCase(this._repository);

  final QuranFontRepository _repository;

  Future<void> call({required int initialPageNumber}) async {
    logger.i(
      '[USE_CASE] LoadQuranFontsToEngineUseCase entry | page=$initialPageNumber',
    );
    final result = _repository.loadFontsToEngine(
      initialPageNumber: initialPageNumber,
    );
    result.then(
      (_) => logger.i(
        '[USE_CASE] LoadQuranFontsToEngineUseCase exit | page=$initialPageNumber',
      ),
    );
    return result;
  }

  Future<void> ensurePageWindowLoaded({required int pageNumber}) =>
      _repository.ensureFontsForPageWindow(pageNumber: pageNumber);

  void pauseBackgroundWarmUp() => _repository.pauseBackgroundWarmUp();

  void resumeBackgroundWarmUp() => _repository.resumeBackgroundWarmUp();

  Future<void> batchWarmPages({
    required int start,
    required int end,
    required Future<void> Function(int) onProgress,
    int? pivotPage,
  }) =>
      _repository.batchWarmPages(start, end, onProgress, pivotPage: pivotPage);

  bool get hasLoadedFontsToEngine => _repository.hasLoadedFontsToEngine;

  Future<void> ensureQuranDataLoaded() => _repository.ensureQuranDataLoaded();

  Future<void> ensureSingleFontLoaded(int pageNumber) =>
      _repository.ensureSingleFontLoaded(pageNumber);

  bool isFontLoaded(int pageNumber) => _repository.isFontLoaded(pageNumber);

  /// Waits until [isFontLoaded] becomes true for [pageNumber], starting a load
  /// if needed, or throws [TimeoutException] if [timeout] elapses.
  Future<void> ensureFontReady(
    int pageNumber, {
    Duration timeout = const Duration(seconds: 1),
  }) async {
    if (isFontLoaded(pageNumber)) return;

    final Future<void> loadFuture = ensureSingleFontLoaded(pageNumber);
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

  Future<void> warmInitialPage(int pageNumber) =>
      _repository.warmInitialPage(pageNumber);
}
