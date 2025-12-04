import 'package:injectable/injectable.dart';
import '../entities/premium_status.dart';
import '../entities/subscription_plan.dart';
import '../repositories/premium_repository.dart';

@Singleton()
class GetPremiumStatusUseCase {
  const GetPremiumStatusUseCase(this._premiumRepository);

  final PremiumRepository _premiumRepository;

  Future<
    ({PremiumStatus status, List<SubscriptionPlan> plans, bool canDownload})
  >
  call() async {
    final PremiumStatus status = await _premiumRepository.getPremiumStatus();
    final List<SubscriptionPlan> plans = await _premiumRepository
        .getAvailablePlans();
    final bool canDownload = await _premiumRepository.canDownload();

    return (status: status, plans: plans, canDownload: canDownload);
  }
}
