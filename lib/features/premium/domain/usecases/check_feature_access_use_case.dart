import 'package:injectable/injectable.dart';
import '../repositories/premium_repository.dart';

@Singleton()
class CheckFeatureAccessUseCase {
  const CheckFeatureAccessUseCase(this._premiumRepository);

  final PremiumRepository _premiumRepository;

  Future<bool> call(String featureName) async {
    return _premiumRepository.canAccessFeature(featureName);
  }
}
