import '../repositories/premium_repository.dart';

class RestoreSubscriptionUseCase {
  const RestoreSubscriptionUseCase(this._premiumRepository);

  final PremiumRepository _premiumRepository;

  Future<bool> call() async {
    return _premiumRepository.restoreSubscription();
  }
}
