import '../../../../core/utils/typedefs.dart';
import '../repositories/alphabet_scrollbar_repository.dart';

class GetAvailableLettersUseCase {
  const GetAvailableLettersUseCase(this._repository);

  final AlphabetScrollbarRepository _repository;

  ResultFuture<List<String>> call() async {
    return _repository.getAvailableLetters();
  }
}
