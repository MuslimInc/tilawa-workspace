import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/onboarding_repository.dart';

@LazySingleton(as: OnboardingRepository)
class OnboardingRepositoryImpl implements OnboardingRepository {
  OnboardingRepositoryImpl(this._prefs);
  final SharedPreferencesAsync _prefs;
  static const _keyOnboardingCompleted = 'onboarding_completed';

  @override
  Future<bool> isOnboardingCompleted() async {
    return await _prefs.getBool(_keyOnboardingCompleted) ?? false;
  }

  @override
  Future<void> completeOnboarding() async {
    await _prefs.setBool(_keyOnboardingCompleted, true);
  }
}
