import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';

import '../entities/tasbeeh_layout_mode.dart';
import '../repositories/tasbeeh_layout_preference_repository.dart';

@lazySingleton
class GetTasbeehLayoutModeUseCase
    implements UseCase<TasbeehLayoutMode, NoParams> {
  GetTasbeehLayoutModeUseCase(this._repository);

  final TasbeehLayoutPreferenceRepository _repository;

  @override
  Future<Either<Failure, TasbeehLayoutMode>> call(NoParams params) async {
    try {
      final TasbeehLayoutMode mode = await _repository.getLayoutMode();
      return Right(mode);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
