import 'package:injectable/injectable.dart';
import 'package:muzakri/core/config/currency_config.dart';
import 'package:muzakri/features/premium/data/datasources/premium_local_datasource.dart';
import 'package:muzakri/features/premium/data/datasources/premium_remote_datasource.dart';
import 'package:muzakri/features/premium/domain/entities/premium_status.dart';
import 'package:muzakri/features/premium/domain/entities/subscription_plan.dart';
import 'package:muzakri/features/premium/domain/repositories/premium_repository.dart';

@LazySingleton(as: PremiumRepository)
class PremiumRepositoryImpl implements PremiumRepository {
  final PremiumLocalDataSource _localDataSource;
  final PremiumRemoteDataSource _remoteDataSource;

  PremiumRepositoryImpl(this._localDataSource, this._remoteDataSource);

  @override
  Future<PremiumStatus> getPremiumStatus() async {
    try {
      // Try to get from remote first (for validation)
      final remoteStatus = await _remoteDataSource.getPremiumStatus();
      if (remoteStatus != null) {
        // Update local storage with remote data
        await _localDataSource.savePremiumStatus(remoteStatus);
        return remoteStatus;
      }
    } catch (e) {
      // If remote fails, use local data
      print('Remote premium status fetch failed: $e');
    }

    // Fallback to local data
    return await _localDataSource.getPremiumStatus();
  }

  @override
  Future<void> updatePremiumStatus(PremiumStatus status) async {
    await _localDataSource.savePremiumStatus(status);
    // Optionally sync with remote
    try {
      await _remoteDataSource.updatePremiumStatus(status);
    } catch (e) {
      print('Failed to sync premium status with remote: $e');
    }
  }

  @override
  Future<List<SubscriptionPlan>> getAvailablePlans() async {
    try {
      return await _remoteDataSource.getAvailablePlans();
    } catch (e) {
      print('Failed to fetch plans from remote: $e');
      // Return default plans
      return _getDefaultPlans();
    }
  }

  @override
  Future<SubscriptionPlan> getPlanById(String planId) async {
    final plans = await getAvailablePlans();
    return plans.firstWhere((plan) => plan.id == planId);
  }

  @override
  Future<bool> purchaseSubscription(String planId) async {
    try {
      final result = await _remoteDataSource.purchaseSubscription(planId);
      if (result) {
        // Update local status
        final currentStatus = await getPremiumStatus();
        final updatedStatus = currentStatus.copyWith(
          isPremium: true,
          subscriptionStartDate: DateTime.now(),
          subscriptionType: planId,
        );
        await updatePremiumStatus(updatedStatus);
      }
      return result;
    } catch (e) {
      print('Purchase failed: $e');
      return false;
    }
  }

  @override
  Future<bool> cancelSubscription() async {
    try {
      final result = await _remoteDataSource.cancelSubscription();
      if (result) {
        // Update local status
        final currentStatus = await getPremiumStatus();
        final updatedStatus = currentStatus.copyWith(
          isPremium: false,
          subscriptionEndDate: DateTime.now(),
        );
        await updatePremiumStatus(updatedStatus);
      }
      return result;
    } catch (e) {
      print('Cancel subscription failed: $e');
      return false;
    }
  }

  @override
  Future<bool> restoreSubscription() async {
    try {
      final result = await _remoteDataSource.restoreSubscription();
      if (result) {
        // Refresh premium status
        final status = await getPremiumStatus();
        return status.isSubscriptionActive;
      }
      return false;
    } catch (e) {
      print('Restore subscription failed: $e');
      return false;
    }
  }

  @override
  Future<bool> startTrial() async {
    try {
      final currentStatus = await getPremiumStatus();
      if (currentStatus.isTrialUsed) {
        return false; // Trial already used
      }

      final trialEndDate = DateTime.now().add(const Duration(days: 7));
      final updatedStatus = currentStatus.copyWith(
        isTrialUsed: true,
        trialStartDate: DateTime.now(),
        trialEndDate: trialEndDate,
      );

      await updatePremiumStatus(updatedStatus);
      return true;
    } catch (e) {
      print('Start trial failed: $e');
      return false;
    }
  }

  @override
  Future<bool> isTrialEligible() async {
    final status = await getPremiumStatus();
    return !status.isTrialUsed && !status.isSubscriptionActive;
  }

  @override
  Future<bool> canAccessFeature(String featureName) async {
    final status = await getPremiumStatus();

    // Define which features require premium
    const premiumFeatures = ['download', 'offline_mode', 'high_quality'];

    if (premiumFeatures.contains(featureName)) {
      return status.canDownload;
    }

    return true; // Free features
  }

  @override
  Future<bool> canDownload() async {
    return await canAccessFeature('download');
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
