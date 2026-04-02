import 'package:injectable/injectable.dart';
import '../repositories/quran_font_repository.dart';

@injectable
class UpdateCurrentPageUseCase {
  UpdateCurrentPageUseCase(this._repository);

  final QuranFontRepository _repository;

  void call(int pageNumber) {
    _repository.updateCurrentPage(pageNumber);
  }
}
