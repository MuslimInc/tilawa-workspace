import 'package:injectable/injectable.dart';

import '../repositories/quran_font_repository.dart';

@lazySingleton
class CheckFontsDownloadedUseCase {
  const CheckFontsDownloadedUseCase(this._repository);

  final QuranFontRepository _repository;

  Future<bool> call() => _repository.areFontsDownloaded();
}
