import 'package:injectable/injectable.dart';
import 'package:quran/quran.dart';
import 'package:tilawa_core/logger.dart';

import '../../domain/repositories/quran_font_repository.dart';

@LazySingleton(as: QuranFontRepository)
class QuranFontRepositoryImpl implements QuranFontRepository {
  QuranFontRepositoryImpl(this._fontService);

  final QuranFontService _fontService;

  @override
  Future<bool> areFontsDownloaded() => _fontService.areFontsDownloaded();

  @override
  Future<void> downloadFonts({void Function(double)? onProgress}) =>
      _fontService.downloadFonts(onProgress: onProgress);

  @override
  Future<void> loadFontsToEngine({required int initialPageNumber}) {
    logger.i('[REPO] loadFontsToEngine entry | page=$initialPageNumber');
    final result = _fontService.loadFontsToEngine(
      initialPageNumber: initialPageNumber,
    );
    result.then(
      (_) => logger.i(
        '[REPO] loadFontsToEngine exit | page=$initialPageNumber',
      ),
    );
    return result;
  }

  @override
  Future<void> ensureFontsForPageWindow({required int pageNumber}) =>
      _fontService.ensureFontsForPageWindow(pageNumber: pageNumber);

  @override
  void pauseBackgroundWarmUp() => _fontService.pauseBackgroundWarmUp();

  @override
  void resumeBackgroundWarmUp() => _fontService.resumeBackgroundWarmUp();

  @override
  bool get hasLoadedFontsToEngine => _fontService.hasLoadedFontsToEngine;

  @override
  void updateCurrentPage(int pageNumber) =>
      _fontService.updateCurrentPage(pageNumber);

  @override
  Future<void> ensureQuranDataLoaded() => _fontService.ensureQuranDataLoaded();

  @override
  Future<void> ensureSingleFontLoaded(int pageNumber) =>
      _fontService.ensureSingleFontLoaded(pageNumber);

  @override
  bool isFontLoaded(int pageNumber) => _fontService.isFontLoaded(pageNumber);

  @override
  Future<void> warmInitialPage(int pageNumber) =>
      _fontService.warmInitialPage(pageNumber);

  @override
  Future<void> batchWarmPages(
    int start,
    int end,
    Future<void> Function(int) onProgress, {
    int? pivotPage,
  }) =>
      _fontService.batchWarmPages(start, end, onProgress, pivotPage: pivotPage);
}
