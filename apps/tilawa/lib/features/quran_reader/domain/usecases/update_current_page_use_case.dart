import '../repositories/quran_font_repository.dart';

class UpdateCurrentPageUseCase {
  UpdateCurrentPageUseCase(this._repository);

  final QuranFontRepository _repository;

  void call(int pageNumber) {
    _repository.updateCurrentPage(pageNumber);
  }
}
