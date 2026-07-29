import '../repositories/premium_repository.dart';

class PurchaseSubscriptionUseCase {
  const PurchaseSubscriptionUseCase(this._premiumRepository);

  final PremiumRepository _premiumRepository;

  Future<bool> call(String planId) async {
    return _premiumRepository.purchaseSubscription(planId);
  }
}
