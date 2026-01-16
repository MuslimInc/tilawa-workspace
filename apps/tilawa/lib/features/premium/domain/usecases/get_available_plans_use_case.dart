import 'package:injectable/injectable.dart';
import '../entities/subscription_plan.dart';
import '../repositories/premium_repository.dart';

@Singleton()
class GetAvailablePlansUseCase {
  const GetAvailablePlansUseCase(this._premiumRepository);

  final PremiumRepository _premiumRepository;

  Future<List<SubscriptionPlan>> call() async {
    return _premiumRepository.getAvailablePlans();
  }
}
