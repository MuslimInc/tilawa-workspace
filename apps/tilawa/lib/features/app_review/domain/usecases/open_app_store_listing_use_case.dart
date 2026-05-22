import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../repositories/app_review_repository.dart';

@lazySingleton
class OpenAppStoreListingUseCase {
  const OpenAppStoreListingUseCase(this._repository);

  final AppReviewRepository _repository;

  Future<Either<Failure, void>> call() async {
    try {
      await _repository.openStoreListing();
      return const Right(null);
    } on AppReviewFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(AppReviewFailure.storeListingFailed(e.toString()));
    }
  }
}
