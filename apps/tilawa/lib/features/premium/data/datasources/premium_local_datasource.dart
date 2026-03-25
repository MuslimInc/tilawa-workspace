import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tilawa/core/logging/app_logger.dart';
import '../../domain/entities/premium_status.dart';

abstract class PremiumLocalDataSource {
  Future<PremiumStatus> getPremiumStatus();
  Future<void> savePremiumStatus(PremiumStatus status);
  Future<void> clearPremiumStatus();
}

@LazySingleton(as: PremiumLocalDataSource)
class PremiumLocalDataSourceImpl implements PremiumLocalDataSource {
  PremiumLocalDataSourceImpl(this._prefs);
  static const String _premiumStatusKey = 'premium_status';

  final SharedPreferencesAsync _prefs;

  @override
  Future<PremiumStatus> getPremiumStatus() async {
    final String statusJson = await _prefs.getString(_premiumStatusKey) ?? '';

    try {
      final statusMap = jsonDecode(statusJson) as Map<String, dynamic>;
      return PremiumStatus.fromJson(statusMap);
    } catch (e) {
      logger.d('Error parsing premium status: $e');
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
      final String statusJson = jsonEncode(status.toJson());
      await _prefs.setString(_premiumStatusKey, statusJson);
    } catch (e) {
      logger.d('Error saving premium status: $e');
    }
  }

  @override
  Future<void> clearPremiumStatus() async {
    await _prefs.remove(_premiumStatusKey);
  }
}
