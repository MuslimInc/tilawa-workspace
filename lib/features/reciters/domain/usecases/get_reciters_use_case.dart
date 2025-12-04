import 'package:injectable/injectable.dart';
import '../../../../core/entities/reciter.dart';
import '../../../../core/utils/typedefs.dart';
import '../repositories/reciters_repository.dart';

@Singleton()
class GetRecitersUseCase {
  const GetRecitersUseCase(this._repository);

  final RecitersRepository _repository;

  ResultFuture<List<ReciterEntity>> call() async {
    return _repository.getReciters();
  }
}
