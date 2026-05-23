import 'dart:async';
import 'dart:developer' as developer;

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../domain/constants/support_product_ids.dart';
import '../../domain/entities/support_product.dart';

/// Raw purchase event from Google Play before server verification.
class PlayPurchaseEvent {
  const PlayPurchaseEvent({
    required this.productId,
    required this.purchaseToken,
    required this.purchaseId,
    required this.details,
  });

  final String productId;
  final String purchaseToken;
  final String purchaseId;
  final PurchaseDetails details;
}

/// Low-level Google Play Billing via [InAppPurchase].
abstract class PlayBillingDataSource {
  Future<bool> isAvailable();

  Future<List<SupportProduct>> queryProducts();

  Future<void> buyConsumable(String productId);

  Future<void> restorePurchases();

  /// Waits until Play delivers a purchase for [productId].
  Future<PlayPurchaseEvent> waitForPurchaseEvent(String productId);

  /// Emits purchases that need server verification.
  Stream<PlayPurchaseEvent> get purchaseEvents;

  Future<void> completePurchase(PurchaseDetails details);

  /// Acknowledges stale Play purchases; optionally cancels active waiters.
  Future<void> prepareForSupportScreen({bool cancelActiveWaiters = true});

  /// Fails the in-flight waiter for [productId] with [failure] if any. Used
  /// to recover the UI when Play closes its sheet without emitting a stream
  /// event (e.g. the "not configured for billing" dialog), so the user is not
  /// stuck on a spinner until the 5-minute waiter timeout.
  ///
  /// Returns `true` if a pending waiter was failed, `false` otherwise.
  bool failPendingPurchase(String productId, PurchaseFailure failure);

  void dispose();
}

@LazySingleton(as: PlayBillingDataSource)
class PlayBillingDataSourceImpl implements PlayBillingDataSource {
  PlayBillingDataSourceImpl(this._inAppPurchase) {
    // Subscribe at construction so purchases delivered before the support
    // screen opens (cold start after an interrupted purchase) still flow to
    // listeners. _onPurchaseUpdate is a no-op when no purchase is in flight.
    _ensurePurchaseListener();
  }

  final InAppPurchase _inAppPurchase;
  final StreamController<PlayPurchaseEvent> _eventsController =
      StreamController<PlayPurchaseEvent>.broadcast();

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  final Map<String, Completer<PlayPurchaseEvent>> _pendingByProduct =
      <String, Completer<PlayPurchaseEvent>>{};

  @override
  Stream<PlayPurchaseEvent> get purchaseEvents => _eventsController.stream;

  @override
  Future<bool> isAvailable() => _inAppPurchase.isAvailable();

  @override
  Future<List<SupportProduct>> queryProducts() async {
    final ProductDetailsResponse response = await _inAppPurchase
        .queryProductDetails(
          SupportProductIds.all.toSet(),
        );
    if (response.notFoundIDs.isNotEmpty && response.productDetails.isEmpty) {
      throw const PurchaseFailure.productNotFound();
    }
    if (response.error != null) {
      throw PurchaseFailure(
        response.error!.message,
        PurchaseFailureReason.productNotFound,
      );
    }
    final List<SupportProduct> products =
        response.productDetails.map(_mapProduct).toList()..sort(
          (SupportProduct a, SupportProduct b) =>
              a.displayOrder.compareTo(b.displayOrder),
        );
    return products;
  }

  @override
  Future<void> buyConsumable(String productId) async {
    final ProductDetailsResponse response = await _inAppPurchase
        .queryProductDetails({productId});
    if (response.productDetails.isEmpty) {
      throw const PurchaseFailure.productNotFound();
    }
    final PurchaseParam param = PurchaseParam(
      productDetails: response.productDetails.first,
    );
    final bool started = await _inAppPurchase.buyConsumable(
      purchaseParam: param,
    );
    if (!started) {
      throw const PurchaseFailure.billingUnavailable();
    }
    _ensurePurchaseListener();
  }

  @override
  Future<void> restorePurchases() async {
    _ensurePurchaseListener();
    await _inAppPurchase.restorePurchases();
  }

  static const Duration _purchaseWaitTimeout = Duration(minutes: 5);

  /// Waits until Play delivers a purchasable event for [productId].
  @override
  Future<PlayPurchaseEvent> waitForPurchaseEvent(String productId) {
    _ensurePurchaseListener();
    final Completer<PlayPurchaseEvent> completer = _pendingByProduct
        .putIfAbsent(productId, Completer<PlayPurchaseEvent>.new);
    return completer.future.timeout(
      _purchaseWaitTimeout,
      onTimeout: () {
        // Treat as "still pending in Play" rather than user-cancelled: a
        // background verification may still complete the donation later. The
        // bloc surfaces a pending message so the user doesn't think they were
        // wrongly charged.
        _failPending(productId, const PurchaseFailure.pending());
        throw const PurchaseFailure.pending();
      },
    );
  }

  @override
  Future<void> completePurchase(PurchaseDetails details) async {
    if (details.pendingCompletePurchase) {
      await _inAppPurchase.completePurchase(details);
    }
  }

  @override
  Future<void> prepareForSupportScreen({
    bool cancelActiveWaiters = true,
  }) async {
    if (cancelActiveWaiters) {
      _cancelPendingPurchases();
    }
    _ensurePurchaseListener();
  }

  @override
  bool failPendingPurchase(String productId, PurchaseFailure failure) {
    final Completer<PlayPurchaseEvent>? pending = _pendingByProduct[productId];
    if (pending == null || pending.isCompleted) {
      return false;
    }
    _failPending(productId, failure);
    return true;
  }

  void _cancelPendingPurchases() {
    for (final Completer<PlayPurchaseEvent> completer
        in _pendingByProduct.values) {
      if (!completer.isCompleted) {
        completer.completeError(const PurchaseFailure.userCancelled());
      }
    }
    _pendingByProduct.clear();
  }

  void _ensurePurchaseListener() {
    _purchaseSub ??= _inAppPurchase.purchaseStream.listen(_onPurchaseUpdate);
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final PurchaseDetails purchase in purchases) {
      final String productId = purchase.productID;
      developer.log(
        'event status=${purchase.status} productID="$productId" '
        'errorCode=${purchase.error?.code} '
        'errorMessage=${purchase.error?.message} '
        'tokenLen=${purchase.verificationData.serverVerificationData.length}',
        name: 'tilawa.support.billing',
      );
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _failPending(
            productId,
            const PurchaseFailure.pending(),
          );
        case PurchaseStatus.error:
          // Play sometimes emits error events with an empty productID (e.g.
          // "billing unavailable" / "not configured" dialogs that fire before
          // the product is bound to the flow). In that case, fail every
          // active waiter so the UI can recover instead of hanging until the
          // 5-minute timeout.
          final PurchaseFailure failure = PurchaseFailure(
            purchase.error?.message,
            _mapError(purchase.error?.code),
          );
          if (productId.isEmpty) {
            _failAllPending(failure);
          } else {
            _failPending(productId, failure);
          }
        case PurchaseStatus.canceled:
          if (productId.isEmpty) {
            _failAllPending(const PurchaseFailure.userCancelled());
          } else {
            _failPending(productId, const PurchaseFailure.userCancelled());
          }
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final String token = purchase.verificationData.serverVerificationData;
          if (token.isEmpty) {
            // Play occasionally emits token-less updates (e.g. on resume).
            // Without a token we cannot verify; do not resolve the waiter and
            // do not consume the purchase — the next stream event for this
            // product will carry the real token.
            break;
          }
          final PlayPurchaseEvent event = PlayPurchaseEvent(
            productId: productId,
            purchaseToken: token,
            purchaseId: purchase.purchaseID ?? '',
            details: purchase,
          );
          // Always broadcast so listeners (repository) can verify the purchase
          // server-side before completing it. Never call completePurchase here.
          _eventsController.add(event);
          final Completer<PlayPurchaseEvent>? pending = _pendingByProduct
              .remove(productId);
          if (pending != null && !pending.isCompleted) {
            pending.complete(event);
          }
        }
    }
  }

  /// Fails every active waiter with [failure]. Used for Play stream events
  /// that arrive without a productID (e.g. "billing unavailable" dialogs),
  /// so the UI can recover instead of hanging until the waiter timeout.
  void _failAllPending(PurchaseFailure failure) {
    final List<String> productIds = _pendingByProduct.keys.toList();
    for (final String productId in productIds) {
      _failPending(productId, failure);
    }
  }

  void _failPending(String productId, PurchaseFailure failure) {
    final Completer<PlayPurchaseEvent>? pending = _pendingByProduct.remove(
      productId,
    );
    if (pending != null && !pending.isCompleted) {
      pending.completeError(failure);
    }
  }

  PurchaseFailureReason _mapError(String? code) {
    return switch (code) {
      'purchase_cancelled' => PurchaseFailureReason.userCancelled,
      'item_unavailable' => PurchaseFailureReason.productNotFound,
      _ => PurchaseFailureReason.verificationFailed,
    };
  }

  SupportProduct _mapProduct(ProductDetails details) {
    final int order = switch (details.id) {
      SupportProductIds.small => 0,
      SupportProductIds.kind => 1,
      SupportProductIds.generous => 2,
      _ => 99,
    };
    return SupportProduct(
      id: details.id,
      title: details.id,
      price: details.price,
      rawPrice: details.rawPrice,
      currencyCode: details.currencyCode,
      displayOrder: order,
    );
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    _eventsController.close();
  }
}
