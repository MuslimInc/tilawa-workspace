import 'package:muzakri/core/entities/reciter.dart';
import 'package:muzakri/core/utils/typedefs.dart';
import 'package:muzakri/features/reciters/domain/repositories/reciters_repository.dart';

class GetReciters {
  const GetReciters(this._repository);

  final RecitersRepository _repository;

  ResultFuture<List<ReciterEntity>> call() async {
    return await _repository.getReciters();
  }
}
