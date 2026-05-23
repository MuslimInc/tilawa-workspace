import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../repositories/app_review_repository.dart';

@lazySingleton
class RequestAppReviewUseCase {
  const RequestAppReviewUseCase(this._repository);

  final AppReviewRepository _repository;

  Future<Either<Failure, void>> call() async {
    try {
      await _repository.requestReview();
      return const Right(null);
    } on AppReviewFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(AppReviewFailure.requestFailed(e.toString()));
    }
  }
}
