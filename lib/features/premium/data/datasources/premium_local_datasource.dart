import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:muzakri/features/premium/domain/entities/premium_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class PremiumLocalDataSource {
  Future<PremiumStatus> getPremiumStatus();
  Future<void> savePremiumStatus(PremiumStatus status);
  Future<void> clearPremiumStatus();
}

@LazySingleton(as: PremiumLocalDataSource)
class PremiumLocalDataSourceImpl implements PremiumLocalDataSource {
  static const String _premiumStatusKey = 'premium_status';

  final SharedPreferencesAsync _prefs;

  PremiumLocalDataSourceImpl(this._prefs);

  @override
  Future<PremiumStatus> getPremiumStatus() async {
    final statusJson = await _prefs.getString(_premiumStatusKey) ?? '';

    try {
      final statusMap = jsonDecode(statusJson) as Map<String, dynamic>;
      return PremiumStatus.fromJson(statusMap);
    } catch (e) {
      print('Error parsing premium status: $e');
      // Return default free status
      return const PremiumStatus(
        isPremium: false,
        subscriptionStartDate: null,
        subscriptionEndDate: null,
        subscriptionType: null,
        isTrialUsed: false,
        trialStartDate: null,
        trialEndDate: null,
      );
    }
  }

  @override
  Future<void> savePremiumStatus(PremiumStatus status) async {
    try {
      final statusJson = jsonEncode(status.toJson());
      await _prefs.setString(_premiumStatusKey, statusJson);
    } catch (e) {
      print('Error saving premium status: $e');
    }
  }

  @override
  Future<void> clearPremiumStatus() async {
    await _prefs.remove(_premiumStatusKey);
  }
}
