import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';

import '../entities/tasbeeh_dhikr.dart';
import '../repositories/tasbeeh_repository.dart';

class SetTasbeehTargetCountParams {
  const SetTasbeehTargetCountParams({
    required this.dhikrId,
    required this.targetCount,
  });

  final String dhikrId;
  final int targetCount;
}

class SetTasbeehTargetCountUseCase
    implements UseCase<TasbeehDhikr, SetTasbeehTargetCountParams> {
  SetTasbeehTargetCountUseCase(this._repository);

  final TasbeehRepository _repository;

  @override
  Future<Either<Failure, TasbeehDhikr>> call(
    SetTasbeehTargetCountParams params,
  ) {
    return _repository.setTargetCount(
      dhikrId: params.dhikrId,
      targetCount: params.targetCount,
    );
  }
}
