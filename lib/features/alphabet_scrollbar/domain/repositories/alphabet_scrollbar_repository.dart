import '../../../../core/utils/typedefs.dart';

abstract class AlphabetScrollbarRepository {
  ResultFuture<List<String>> getAvailableLetters();
  ResultFuture<List<String>> getLettersForReciters(List<String> reciterNames);
}
