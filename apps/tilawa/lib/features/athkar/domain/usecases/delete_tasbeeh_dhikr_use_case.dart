import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';

import '../repositories/tasbeeh_repository.dart';

class DeleteTasbeehDhikrUseCase implements UseCase<void, String> {
  DeleteTasbeehDhikrUseCase(this._repository);

  final TasbeehRepository _repository;

  @override
  Future<Either<Failure, void>> call(String params) {
    return _repository.deleteDhikr(params);
  }
}
