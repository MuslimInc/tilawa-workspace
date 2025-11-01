import 'package:injectable/injectable.dart';
import 'package:muzakri/core/entities/reciter.dart';
import 'package:muzakri/core/utils/typedefs.dart';
import 'package:muzakri/features/reciters/domain/repositories/reciters_repository.dart';

@Singleton()
class GetRecitersUseCase {
  const GetRecitersUseCase(this._repository);

  final RecitersRepository _repository;

  ResultFuture<List<ReciterEntity>> call() async {
    return await _repository.getReciters();
  }
}
