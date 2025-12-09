import 'package:injectable/injectable.dart';
import '../repositories/premium_repository.dart';

@Singleton()
class CancelSubscriptionUseCase {
  const CancelSubscriptionUseCase(this._premiumRepository);

  final PremiumRepository _premiumRepository;

  Future<bool> call() async {
    return _premiumRepository.cancelSubscription();
  }
}
