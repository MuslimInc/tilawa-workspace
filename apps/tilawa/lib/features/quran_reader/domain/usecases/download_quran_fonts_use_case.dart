import 'package:injectable/injectable.dart';

import '../repositories/quran_font_repository.dart';

@lazySingleton
class DownloadQuranFontsUseCase {
  const DownloadQuranFontsUseCase(this._repository);

  final QuranFontRepository _repository;

  Future<void> call({void Function(double)? onProgress}) =>
      _repository.downloadFonts(onProgress: onProgress);
}
