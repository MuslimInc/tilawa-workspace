import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/prayer_alerts_permission_onboarding_repository.dart';

@LazySingleton(as: PrayerAlertsPermissionOnboardingRepository)
class PrayerAlertsPermissionOnboardingRepositoryImpl
    implements PrayerAlertsPermissionOnboardingRepository {
  PrayerAlertsPermissionOnboardingRepositoryImpl(this._prefs);

  static const String _flowCompletedKey =
      'prayer_alerts_permission_flow_completed_v1';

  final SharedPreferencesAsync _prefs;

  @override
  Future<bool> wasFlowCompleted() async {
    return await _prefs.getBool(_flowCompletedKey) ?? false;
  }

  @override
  Future<void> markFlowCompleted() async {
    await _prefs.setBool(_flowCompletedKey, true);
  }
}
