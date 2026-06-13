import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa_core/errors/failures.dart';
import '../entities/purchase_outcome.dart';
import '../repositories/support_repository.dart';

@lazySingleton
class PurchaseSupportProductUseCase {
  const PurchaseSupportProductUseCase(this._repository);

  final SupportRepository _repository;

  Future<Either<Failure, PurchaseOutcome>> call(String productId) async {
    try {
      final PurchaseOutcome outcome = await _repository.purchaseSupportProduct(
        productId,
      );
      return Right(outcome);
    } on PurchaseFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(PurchaseFailure(e.toString()));
    }
  }
}
