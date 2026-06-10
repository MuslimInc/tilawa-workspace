import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';

import '../repositories/tasbeeh_repository.dart';

@lazySingleton
class ClearAllSavedTasbeehUseCase implements UseCase<void, NoParams> {
  ClearAllSavedTasbeehUseCase(this._repository);

  final TasbeehRepository _repository;

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return _repository.deleteAllDhikr();
  }
}
