import '../repositories/premium_repository.dart';

class CheckFeatureAccessUseCase {
  const CheckFeatureAccessUseCase(this._premiumRepository);

  final PremiumRepository _premiumRepository;

  Future<bool> call(String featureName) async {
    return _premiumRepository.canAccessFeature(featureName);
  }
}
