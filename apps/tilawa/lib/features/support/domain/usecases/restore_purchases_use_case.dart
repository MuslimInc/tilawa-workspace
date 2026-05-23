import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa_core/errors/failures.dart';
import '../repositories/support_repository.dart';

@lazySingleton
class RestorePurchasesUseCase {
  const RestorePurchasesUseCase(this._repository);

  final SupportRepository _repository;

  Future<Either<Failure, void>> call() async {
    try {
      await _repository.restorePurchases();
      return const Right(null);
    } on PurchaseFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(PurchaseFailure(e.toString()));
    }
  }
}
