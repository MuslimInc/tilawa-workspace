import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';

import '../entities/tasbeeh_dhikr.dart';
import '../repositories/tasbeeh_repository.dart';

class GetSavedTasbeehUseCase implements UseCase<List<TasbeehDhikr>, NoParams> {
  GetSavedTasbeehUseCase(this._repository);

  final TasbeehRepository _repository;

  @override
  Future<Either<Failure, List<TasbeehDhikr>>> call(NoParams params) {
    return _repository.getSavedDhikr();
  }
}
