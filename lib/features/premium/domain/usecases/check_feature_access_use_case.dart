import 'package:injectable/injectable.dart';
import 'package:muzakri/features/premium/domain/repositories/premium_repository.dart';

@Singleton()
class CheckFeatureAccessUseCase {
  const CheckFeatureAccessUseCase(this._premiumRepository);

  final PremiumRepository _premiumRepository;

  Future<bool> call(String featureName) async {
    return await _premiumRepository.canAccessFeature(featureName);
  }
}
