import 'package:injectable/injectable.dart';
import '../repositories/premium_repository.dart';

@Singleton()
class RestoreSubscriptionUseCase {
  const RestoreSubscriptionUseCase(this._premiumRepository);

  final PremiumRepository _premiumRepository;

  Future<bool> call() async {
    return _premiumRepository.restoreSubscription();
  }
}
