import 'package:injectable/injectable.dart';
import 'package:muzakri/features/premium/domain/entities/subscription_plan.dart';
import 'package:muzakri/features/premium/domain/repositories/premium_repository.dart';

@Singleton()
class GetAvailablePlansUseCase {
  const GetAvailablePlansUseCase(this._premiumRepository);

  final PremiumRepository _premiumRepository;

  Future<List<SubscriptionPlan>> call() async {
    return await _premiumRepository.getAvailablePlans();
  }
}
