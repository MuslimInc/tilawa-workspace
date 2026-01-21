import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';
import '../repositories/qibla_repository.dart';

@injectable
class RequestLocationPermissionUseCase extends UseCase<bool, NoParams> {
  RequestLocationPermissionUseCase(this._repository);
  final QiblaRepository _repository;

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    try {
      final bool result = await _repository.requestLocationPermission();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
