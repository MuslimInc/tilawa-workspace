import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';

import '../entities/tasbeeh_layout_mode.dart';
import '../repositories/tasbeeh_layout_preference_repository.dart';

@lazySingleton
class SetTasbeehLayoutModeUseCase implements UseCase<void, TasbeehLayoutMode> {
  SetTasbeehLayoutModeUseCase(this._repository);

  final TasbeehLayoutPreferenceRepository _repository;

  @override
  Future<Either<Failure, void>> call(TasbeehLayoutMode params) async {
    try {
      await _repository.setLayoutMode(params);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
