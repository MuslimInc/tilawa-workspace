import 'package:muzakri/features/premium/domain/entities/premium_status.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

abstract class PremiumLocalDataSource {
  Future<PremiumStatus> getPremiumStatus();
  Future<void> savePremiumStatus(PremiumStatus status);
  Future<void> clearPremiumStatus();
}

class PremiumLocalDataSourceImpl implements PremiumLocalDataSource {
  static const String _premiumStatusKey = 'premium_status';

  final SharedPreferences _prefs;

  PremiumLocalDataSourceImpl({required SharedPreferences prefs})
    : _prefs = prefs;

  @override
  Future<PremiumStatus> getPremiumStatus() async {
    final statusJson = _prefs.getString(_premiumStatusKey);

    if (statusJson == null) {
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
