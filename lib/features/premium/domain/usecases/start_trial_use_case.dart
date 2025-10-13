import 'package:injectable/injectable.dart';
import 'package:muzakri/features/premium/domain/repositories/premium_repository.dart';

@Singleton()
class StartTrialUseCase {
  const StartTrialUseCase(this._premiumRepository);

  final PremiumRepository _premiumRepository;

  Future<({bool isEligible, bool success})> call() async {
    final isEligible = await _premiumRepository.isTrialEligible();

    if (!isEligible) {
      return (isEligible: false, success: false);
    }

    final success = await _premiumRepository.startTrial();
    return (isEligible: isEligible, success: success);
  }
}
