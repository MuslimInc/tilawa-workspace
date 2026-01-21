import 'package:injectable/injectable.dart';
import '../repositories/premium_repository.dart';

@Singleton()
class PurchaseSubscriptionUseCase {
  const PurchaseSubscriptionUseCase(this._premiumRepository);

  final PremiumRepository _premiumRepository;

  Future<bool> call(String planId) async {
    return _premiumRepository.purchaseSubscription(planId);
  }
}
