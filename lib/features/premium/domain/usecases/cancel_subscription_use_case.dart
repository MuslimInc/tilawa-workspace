import 'package:injectable/injectable.dart';
import 'package:muzakri/features/premium/domain/repositories/premium_repository.dart';

@Singleton()
class CancelSubscriptionUseCase {
  const CancelSubscriptionUseCase(this._premiumRepository);

  final PremiumRepository _premiumRepository;

  Future<bool> call() async {
    return await _premiumRepository.cancelSubscription();
  }
}
