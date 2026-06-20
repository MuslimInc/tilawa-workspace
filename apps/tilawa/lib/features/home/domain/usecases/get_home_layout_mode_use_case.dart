import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';

import '../entities/home_layout_mode.dart';
import '../repositories/home_layout_preference_repository.dart';

class GetHomeLayoutModeUseCase implements UseCase<HomeLayoutMode, NoParams> {
  GetHomeLayoutModeUseCase(this._repository);

  final HomeLayoutPreferenceRepository _repository;

  @override
  Future<Either<Failure, HomeLayoutMode>> call(NoParams params) async {
    try {
      final HomeLayoutMode mode = await _repository.getLayoutMode();
      return Right(mode);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
