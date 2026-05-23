import 'dart:async';
import 'dart:developer' as developer;

import 'package:injectable/injectable.dart';
import 'package:tilawa_core/constants/analytics_constants.dart';
import 'package:tilawa_core/errors/failures.dart';
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
  ) {
    // Singleton: subscription lives for the app process. Background verifies
    // any Play purchase the user completed off-screen (cold start, resume,
    // notification) without needing the support UI to be mounted.
    _billing.purchaseEvents.listen(_onPurchaseEvent);
  }

  final PlayBillingDataSource _billing;
  final SupportLocalDataSource _local;
  final PurchaseVerificationClient _verification;
  final AnalyticsService _analytics;

  final StreamController<PurchaseOutcome> _verifiedController =
      StreamController<PurchaseOutcome>.broadcast();

  /// Tokens already (or currently) being verified — prevents double-processing
  /// when both the active waiter and the broadcast stream fire for the same
  /// event, or when restorePurchases() re-emits a token we just handled.
  final Set<String> _handledTokens = <String>{};

  @override
  Stream<PurchaseOutcome> get watchVerifiedPurchases =>
      _verifiedController.stream;

  @override
  Future<bool> isBillingAvailable() => _billing.isAvailable();

  @override
  Future<List<SupportProduct>> getSupportProducts() =>
      _billing.queryProducts();

  @override
  Future<void> prepareSupportSession({bool resetWaiters = true}) =>
      _billing.prepareForSupportScreen(cancelActiveWaiters: resetWaiters);

  @override
  bool abortPendingPurchaseAsUnavailable(String productId) =>
      _billing.failPendingPurchase(
        productId,
        const PurchaseFailure.billingUnavailable(),
      );

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

    return _verifyAndComplete(event);
  }

  Future<PurchaseOutcome> _verifyAndComplete(PlayPurchaseEvent event) async {
    if (!_handledTokens.add(event.purchaseToken)) {
      // Already verified (or being verified) in this app session. The server
      // ledger is idempotent on the same token hash, so we just need to keep
      // local side-effects to one emission.
      throw const PurchaseFailure.alreadyOwned();
    }
    try {
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
    } catch (_) {
      // Allow a retry on the same token if verification failed transiently.
      _handledTokens.remove(event.purchaseToken);
      rethrow;
    }
  }

  Future<void> _onPurchaseEvent(PlayPurchaseEvent event) async {
    try {
      await _verifyAndComplete(event);
    } on PurchaseFailure catch (failure) {
      // Already-handled dedupe or transient verify failure; do not crash the
      // singleton's broadcast subscription. The active purchase flow (if any)
      // reports failures through its own path.
      developer.log(
        'background purchase verification failed: ${failure.reason}',
        name: 'tilawa.support.repo',
        level: 900,
      );
    } catch (e, st) {
      developer.log(
        'background purchase verification crashed',
        name: 'tilawa.support.repo',
        error: e,
        stackTrace: st,
        level: 1000,
      );
    }
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
