import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa_core/errors/failures.dart';
import '../entities/support_product.dart';
import '../repositories/support_repository.dart';

@lazySingleton
class GetSupportProductsUseCase {
  const GetSupportProductsUseCase(this._repository);

  final SupportRepository _repository;

  Future<Either<Failure, List<SupportProduct>>> call() async {
    try {
      final bool available = await _repository.isBillingAvailable();
      if (!available) {
        return const Left(PurchaseFailure.billingUnavailable());
      }
      final List<SupportProduct> products =
          await _repository.getSupportProducts();
      if (products.isEmpty) {
        return const Left(PurchaseFailure.productNotFound());
      }
      return Right(products);
    } on PurchaseFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(PurchaseFailure(e.toString()));
    }
  }
}
