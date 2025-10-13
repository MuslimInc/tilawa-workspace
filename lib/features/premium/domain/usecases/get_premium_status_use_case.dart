import 'package:injectable/injectable.dart';
import 'package:muzakri/features/premium/domain/entities/premium_status.dart';
import 'package:muzakri/features/premium/domain/entities/subscription_plan.dart';
import 'package:muzakri/features/premium/domain/repositories/premium_repository.dart';

@Singleton()
class GetPremiumStatusUseCase {
  const GetPremiumStatusUseCase(this._premiumRepository);

  final PremiumRepository _premiumRepository;

  Future<
    ({PremiumStatus status, List<SubscriptionPlan> plans, bool canDownload})
  >
  call() async {
    final status = await _premiumRepository.getPremiumStatus();
    final plans = await _premiumRepository.getAvailablePlans();
    final canDownload = await _premiumRepository.canDownload();

    return (status: status, plans: plans, canDownload: canDownload);
  }
}
