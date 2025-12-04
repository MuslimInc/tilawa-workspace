import 'package:injectable/injectable.dart';

import '../../../../core/config/currency_config.dart';
import '../../../../main.dart';
import '../../domain/entities/premium_status.dart';
import '../../domain/entities/subscription_plan.dart';
import '../../domain/repositories/premium_repository.dart';
import '../datasources/premium_local_datasource.dart';
import '../datasources/premium_remote_datasource.dart';

@LazySingleton(as: PremiumRepository)
class PremiumRepositoryImpl implements PremiumRepository {
  PremiumRepositoryImpl(this._localDataSource, this._remoteDataSource);
  final PremiumLocalDataSource _localDataSource;
  final PremiumRemoteDataSource _remoteDataSource;

  @override
  Future<PremiumStatus> getPremiumStatus() async {
    try {
      // Try to get from remote first (for validation)
      final PremiumStatus? remoteStatus = await _remoteDataSource
          .getPremiumStatus();
      if (remoteStatus != null) {
        // Update local storage with remote data
        await _localDataSource.savePremiumStatus(remoteStatus);
        return remoteStatus;
      }
    } catch (e) {
      // If remote fails, use local data
      logger.d('Remote premium status fetch failed: $e');
    }

    // Fallback to local data
    return _localDataSource.getPremiumStatus();
  }

  @override
  Future<void> updatePremiumStatus(PremiumStatus status) async {
    await _localDataSource.savePremiumStatus(status);
    // Optionally sync with remote
    try {
      await _remoteDataSource.updatePremiumStatus(status);
    } catch (e) {
      logger.d('Failed to sync premium status with remote: $e');
    }
  }

  @override
  Future<List<SubscriptionPlan>> getAvailablePlans() async {
    try {
      return await _remoteDataSource.getAvailablePlans();
    } catch (e) {
      logger.d('Failed to fetch plans from remote: $e');
      // Return default plans
      return _getDefaultPlans();
    }
  }

  @override
  Future<SubscriptionPlan> getPlanById(String planId) async {
    final List<SubscriptionPlan> plans = await getAvailablePlans();
    return plans.firstWhere((plan) => plan.id == planId);
  }

  @override
  Future<bool> purchaseSubscription(String planId) async {
    try {
      final bool result = await _remoteDataSource.purchaseSubscription(planId);
      if (result) {
        // Update local status
        final PremiumStatus currentStatus = await getPremiumStatus();
        final PremiumStatus updatedStatus = currentStatus.copyWith(
          isPremium: true,
          subscriptionStartDate: DateTime.now(),
          subscriptionType: planId,
        );
        await updatePremiumStatus(updatedStatus);
      }
      return result;
    } catch (e) {
      logger.d('Purchase failed: $e');
      return false;
    }
  }

  @override
  Future<bool> cancelSubscription() async {
    try {
      final bool result = await _remoteDataSource.cancelSubscription();
      if (result) {
        // Update local status
        final PremiumStatus currentStatus = await getPremiumStatus();
        final PremiumStatus updatedStatus = currentStatus.copyWith(
          isPremium: false,
          subscriptionEndDate: DateTime.now(),
        );
        await updatePremiumStatus(updatedStatus);
      }
      return result;
    } catch (e) {
      logger.d('Cancel subscription failed: $e');
      return false;
    }
  }

  @override
  Future<bool> restoreSubscription() async {
    try {
      final bool result = await _remoteDataSource.restoreSubscription();
      if (result) {
        // Refresh premium status
        final PremiumStatus status = await getPremiumStatus();
        return status.isSubscriptionActive;
      }
      return false;
    } catch (e) {
      logger.d('Restore subscription failed: $e');
      return false;
    }
  }

  @override
  Future<bool> startTrial() async {
    try {
      final PremiumStatus currentStatus = await getPremiumStatus();
      if (currentStatus.isTrialUsed) {
        return false; // Trial already used
      }

      final DateTime trialEndDate = DateTime.now().add(const Duration(days: 7));
      final PremiumStatus updatedStatus = currentStatus.copyWith(
        isTrialUsed: true,
        trialStartDate: DateTime.now(),
        trialEndDate: trialEndDate,
      );

      await updatePremiumStatus(updatedStatus);
      return true;
    } catch (e) {
      logger.d('Start trial failed: $e');
      return false;
    }
  }

  @override
  Future<bool> isTrialEligible() async {
    final PremiumStatus status = await getPremiumStatus();
    return !status.isTrialUsed && !status.isSubscriptionActive;
  }

  @override
  Future<bool> canAccessFeature(String featureName) async {
    final PremiumStatus status = await getPremiumStatus();

    // Define which features require premium
    const premiumFeatures = ['download', 'offline_mode', 'high_quality'];

    if (premiumFeatures.contains(featureName)) {
      return status.canDownload;
    }

    return true; // Free features
  }

  @override
  Future<bool> canDownload() async {
    return canAccessFeature('download');
  }

  @override
  List<String> getPremiumFeatures() {
    return [
      'Unlimited Downloads',
      'Offline Mode',
      'High Quality Audio',
      'Ad-Free Experience',
      'Priority Support',
      'Exclusive Content',
    ];
  }

  List<SubscriptionPlan> _getDefaultPlans() {
    return [
      const SubscriptionPlan(
        id: 'monthly',
        name: 'Monthly Premium',
        description: 'Full access to all premium features',
        price: 4.99,
        currency: CurrencyConfig.currencyCode,
        type: SubscriptionType.monthly,
        durationInDays: 30,
        features: [
          'Unlimited Downloads',
          'Offline Mode',
          'High Quality Audio',
          'Ad-Free Experience',
        ],
        isPopular: false,
        discountPercentage: null,
      ),
      const SubscriptionPlan(
        id: 'yearly',
        name: 'Yearly Premium',
        description: 'Best value - Save 50%',
        price: 29.99,
        currency: CurrencyConfig.currencyCode,
        type: SubscriptionType.yearly,
        durationInDays: 365,
        features: [
          'Unlimited Downloads',
          'Offline Mode',
          'High Quality Audio',
          'Ad-Free Experience',
          'Priority Support',
        ],
        isPopular: true,
        discountPercentage: 50.0,
      ),
      const SubscriptionPlan(
        id: 'lifetime',
        name: 'Lifetime Premium',
        description: 'One-time payment, lifetime access',
        price: 99.99,
        currency: CurrencyConfig.currencyCode,
        type: SubscriptionType.lifetime,
        durationInDays: 36500, // ~100 years
        features: [
          'Unlimited Downloads',
          'Offline Mode',
          'High Quality Audio',
          'Ad-Free Experience',
          'Priority Support',
          'Exclusive Content',
        ],
        isPopular: false,
        discountPercentage: 80.0,
      ),
    ];
  }
}
