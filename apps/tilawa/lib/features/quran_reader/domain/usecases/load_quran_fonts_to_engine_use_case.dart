import 'dart:developer' as developer;
import 'package:injectable/injectable.dart';

import '../repositories/quran_font_repository.dart';

@lazySingleton
class LoadQuranFontsToEngineUseCase {
  const LoadQuranFontsToEngineUseCase(this._repository);

  final QuranFontRepository _repository;

  Future<void> call({required int initialPageNumber}) async {
    developer.log('[USE_CASE] LoadQuranFontsToEngineUseCase entry | page=$initialPageNumber');
    final result = _repository.loadFontsToEngine(initialPageNumber: initialPageNumber);
    result.then((_) => developer.log('[USE_CASE] LoadQuranFontsToEngineUseCase exit | page=$initialPageNumber'));
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
  }) => _repository.batchWarmPages(start, end, onProgress, pivotPage: pivotPage);

  bool get hasLoadedFontsToEngine => _repository.hasLoadedFontsToEngine;

  Future<void> ensureQuranDataLoaded() => _repository.ensureQuranDataLoaded();

  Future<void> ensureSingleFontLoaded(int pageNumber) =>
      _repository.ensureSingleFontLoaded(pageNumber);

  bool isFontLoaded(int pageNumber) => _repository.isFontLoaded(pageNumber);

  Future<void> warmInitialPage(int pageNumber) =>
      _repository.warmInitialPage(pageNumber);
}
