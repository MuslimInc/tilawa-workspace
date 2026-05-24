import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';

import '../entities/tasbeeh_dhikr.dart';
import '../repositories/tasbeeh_repository.dart';

class SaveCustomTasbeehParams {
  const SaveCustomTasbeehParams({
    required this.text,
    required this.targetCount,
  });

  final String text;
  final int targetCount;
}

@lazySingleton
class SaveCustomTasbeehUseCase
    implements UseCase<TasbeehDhikr, SaveCustomTasbeehParams> {
  SaveCustomTasbeehUseCase(this._repository);

  final TasbeehRepository _repository;

  @override
  Future<Either<Failure, TasbeehDhikr>> call(SaveCustomTasbeehParams params) {
    return _repository.saveCustomDhikr(
      text: params.text,
      targetCount: params.targetCount,
    );
  }
}
