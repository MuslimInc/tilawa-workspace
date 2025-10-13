import 'package:injectable/injectable.dart';
import 'package:muzakri/features/premium/domain/repositories/premium_repository.dart';

@Singleton()
class PurchaseSubscriptionUseCase {
  const PurchaseSubscriptionUseCase(this._premiumRepository);

  final PremiumRepository _premiumRepository;

  Future<bool> call(String planId) async {
    return await _premiumRepository.purchaseSubscription(planId);
  }
}
