import 'package:muzakri/core/utils/typedefs.dart';
import 'package:muzakri/features/alphabet_scrollbar/domain/repositories/alphabet_scrollbar_repository.dart';

class GetAvailableLetters {
  const GetAvailableLetters(this._repository);

  final AlphabetScrollbarRepository _repository;

  ResultFuture<List<String>> call() async {
    return await _repository.getAvailableLetters();
  }
}
