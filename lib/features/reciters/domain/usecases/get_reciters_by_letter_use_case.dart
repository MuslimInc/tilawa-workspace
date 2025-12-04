import '../../../../core/entities/reciter.dart';
import '../../../../core/utils/typedefs.dart';
import '../repositories/reciters_repository.dart';

class GetRecitersByLetterUseCase {
  const GetRecitersByLetterUseCase(this._repository);

  final RecitersRepository _repository;

  ResultFuture<List<ReciterEntity>> call(String letter) async {
    return _repository.getRecitersByLetter(letter);
  }
}
