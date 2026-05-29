import 'package:injectable/injectable.dart';

import '../../domain/services/subscription_catalog_prefetch.dart';
import 'subscription_plans_service.dart';

@LazySingleton(as: SubscriptionCatalogPrefetch)
class SubscriptionCatalogPrefetchImpl implements SubscriptionCatalogPrefetch {
  SubscriptionCatalogPrefetchImpl(this._subscriptionPlansService);

  final SubscriptionPlansService _subscriptionPlansService;

  @override
  Future<void> prefetch() async {
    await _subscriptionPlansService.getSubscriptionPlans();
  }
}
