import '../entities/premium_status.dart';
import '../entities/subscription_plan.dart';

abstract class PremiumRepository {
  // Premium status management
  Future<PremiumStatus> getPremiumStatus();
  Future<void> updatePremiumStatus(PremiumStatus status);

  // Subscription plans
  Future<List<SubscriptionPlan>> getAvailablePlans();
  Future<SubscriptionPlan> getPlanById(String planId);

  // Subscription management
  Future<bool> purchaseSubscription(String planId);
  Future<bool> cancelSubscription();
  Future<bool> restoreSubscription();

  // Trial management
  Future<bool> startTrial();
  Future<bool> isTrialEligible();

  // Feature access
  Future<bool> canAccessFeature(String featureName);
  Future<bool> canDownload();

  // Premium features list
  List<String> getPremiumFeatures();
}
