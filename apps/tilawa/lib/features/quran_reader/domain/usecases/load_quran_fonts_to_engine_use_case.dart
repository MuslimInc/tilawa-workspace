import 'package:injectable/injectable.dart';

import '../repositories/quran_font_repository.dart';

@lazySingleton
class LoadQuranFontsToEngineUseCase {
  const LoadQuranFontsToEngineUseCase(this._repository);

  final QuranFontRepository _repository;

  Future<void> call() => _repository.loadFontsToEngine();

  bool get hasLoadedFontsToEngine => _repository.hasLoadedFontsToEngine;
}
