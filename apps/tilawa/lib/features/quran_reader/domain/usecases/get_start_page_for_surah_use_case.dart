import 'package:injectable/injectable.dart';

import '../repositories/quran_reader_repository.dart';

@injectable
class GetStartPageForSurahUseCase {
  GetStartPageForSurahUseCase(this._repository);

  final QuranReaderRepository _repository;

  int call(int surahNumber) {
    return _repository.getStartPageForSurah(surahNumber);
  }
}
