import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';

import '../entities/tasbeeh_dhikr.dart';
import '../repositories/tasbeeh_repository.dart';

class ResetTasbeehCountUseCase implements UseCase<TasbeehDhikr, String> {
  ResetTasbeehCountUseCase(this._repository);

  final TasbeehRepository _repository;

  @override
  Future<Either<Failure, TasbeehDhikr>> call(String params) {
    return _repository.resetCount(params);
  }
}
