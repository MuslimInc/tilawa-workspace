import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../repositories/app_review_repository.dart';

@lazySingleton
class IsAppReviewAvailableUseCase {
  const IsAppReviewAvailableUseCase(this._repository);

  final AppReviewRepository _repository;

  Future<Either<Failure, bool>> call() async {
    try {
      final bool available = await _repository.isAvailable();
      return Right(available);
    } on AppReviewFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(AppReviewFailure.requestFailed(e.toString()));
    }
  }
}
