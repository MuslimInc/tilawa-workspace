import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:tilawa_core/constants/analytics_constants.dart';
import 'package:tilawa_core/services/analytics_service.dart';

import '../../domain/entities/purchase_outcome.dart';
import '../../domain/entities/support_product.dart';
import '../../domain/repositories/support_repository.dart';
import '../datasources/play_billing_datasource.dart';
import '../datasources/support_local_datasource.dart';
import '../services/purchase_verification_client.dart';

@LazySingleton(as: SupportRepository)
class SupportRepositoryImpl implements SupportRepository {
  SupportRepositoryImpl(
    this._billing,
    this._local,
    this._verification,
    this._analytics,
  );

  final PlayBillingDataSource _billing;
  final SupportLocalDataSource _local;
  final PurchaseVerificationClient _verification;
  final AnalyticsService _analytics;

  final StreamController<PurchaseOutcome> _verifiedController =
      StreamController<PurchaseOutcome>.broadcast();

  @override
  Stream<PurchaseOutcome> get watchVerifiedPurchases =>
      _verifiedController.stream;

  @override
  Future<bool> isBillingAvailable() => _billing.isAvailable();

  @override
  Future<List<SupportProduct>> getSupportProducts() =>
      _billing.queryProducts();

  @override
  Future<PurchaseOutcome> purchaseSupportProduct(String productId) async {
    await _analytics.logEvent(
      AnalyticsEvents.supportPurchaseStarted,
      parameters: <String, Object>{
        AnalyticsParams.productId: productId,
      },
    );

    await _billing.buyConsumable(productId);

    final PlayPurchaseEvent event =
        await _billing.waitForPurchaseEvent(productId);

    final VerifiedPurchase verified = await _verification.verify(
      productId: event.productId,
      purchaseToken: event.purchaseToken,
    );

    await _billing.completePurchase(event.details);

    final PurchaseOutcome outcome = PurchaseOutcome(
      productId: verified.productId,
      orderId: verified.orderId.isNotEmpty
          ? verified.orderId
          : event.purchaseId,
    );

    await _local.saveLastSupport(
      productId: outcome.productId,
      at: DateTime.now(),
    );

    await _analytics.logEvent(
      AnalyticsEvents.supportPurchaseVerified,
      parameters: <String, Object>{
        AnalyticsParams.productId: outcome.productId,
      },
    );

    _verifiedController.add(outcome);
    return outcome;
  }

  @override
  Future<void> restorePurchases() async {
    await _analytics.logEvent(AnalyticsEvents.supportRestoreTapped);
    await _billing.restorePurchases();
  }

  @override
  Future<DateTime?> getLastSupportAt() => _local.getLastSupportAt();

  @override
  Future<String?> getLastSupportProductId() =>
      _local.getLastSupportProductId();
}
