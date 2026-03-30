import 'package:injectable/injectable.dart';
import 'package:quran/quran.dart';

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
  Future<void> loadFontsToEngine({required int initialPageNumber}) =>
      _fontService.loadFontsToEngine(initialPageNumber: initialPageNumber);

  @override
  Future<void> ensureFontsForPageWindow({required int pageNumber}) =>
      _fontService.ensureFontsForPageWindow(pageNumber: pageNumber);

  @override
  bool get hasLoadedFontsToEngine => _fontService.hasLoadedFontsToEngine;
}
