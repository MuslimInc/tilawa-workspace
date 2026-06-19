import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';

import '../entities/home_layout_mode.dart';
import '../repositories/home_layout_preference_repository.dart';

@lazySingleton
class SetHomeLayoutModeUseCase implements UseCase<void, HomeLayoutMode> {
  SetHomeLayoutModeUseCase(this._repository);

  final HomeLayoutPreferenceRepository _repository;

  @override
  Future<Either<Failure, void>> call(HomeLayoutMode params) async {
    try {
      await _repository.setLayoutMode(params);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
