import 'package:injectable/injectable.dart';

import '../repositories/quran_font_repository.dart';

@lazySingleton
class LoadQuranFontsToEngineUseCase {
  const LoadQuranFontsToEngineUseCase(this._repository);

  final QuranFontRepository _repository;

  Future<void> call({required int initialPageNumber}) =>
      _repository.loadFontsToEngine(initialPageNumber: initialPageNumber);

  Future<void> ensurePageWindowLoaded({required int pageNumber}) =>
      _repository.ensureFontsForPageWindow(pageNumber: pageNumber);

  bool get hasLoadedFontsToEngine => _repository.hasLoadedFontsToEngine;
}
