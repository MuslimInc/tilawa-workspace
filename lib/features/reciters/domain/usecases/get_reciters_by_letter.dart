import 'package:muzakri/core/entities/reciter.dart';
import 'package:muzakri/core/utils/typedefs.dart';
import 'package:muzakri/features/reciters/domain/repositories/reciters_repository.dart';

class GetRecitersByLetter {
  const GetRecitersByLetter(this._repository);

  final RecitersRepository _repository;

  ResultFuture<List<ReciterEntity>> call(String letter) async {
    return await _repository.getRecitersByLetter(letter);
  }
}
