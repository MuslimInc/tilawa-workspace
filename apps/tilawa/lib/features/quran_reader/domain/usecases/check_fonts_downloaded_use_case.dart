import '../repositories/quran_font_repository.dart';

class CheckFontsDownloadedUseCase {
  const CheckFontsDownloadedUseCase(this._repository);

  final QuranFontRepository _repository;

  Future<bool> call() => _repository.areFontsDownloaded();
}
