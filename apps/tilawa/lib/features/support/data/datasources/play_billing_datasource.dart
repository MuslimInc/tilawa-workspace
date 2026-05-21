import 'dart:async';

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

  void dispose();
}

@LazySingleton(as: PlayBillingDataSource)
class PlayBillingDataSourceImpl implements PlayBillingDataSource {
  PlayBillingDataSourceImpl(this._inAppPurchase);

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

  /// Waits until Play delivers a purchasable event for [productId].
  @override
  Future<PlayPurchaseEvent> waitForPurchaseEvent(String productId) {
    _ensurePurchaseListener();
    return _pendingByProduct
        .putIfAbsent(productId, Completer<PlayPurchaseEvent>.new)
        .future;
  }

  @override
  Future<void> completePurchase(PurchaseDetails details) async {
    if (details.pendingCompletePurchase) {
      await _inAppPurchase.completePurchase(details);
    }
  }

  void _ensurePurchaseListener() {
    _purchaseSub ??= _inAppPurchase.purchaseStream.listen(_onPurchaseUpdate);
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final PurchaseDetails purchase in purchases) {
      final String productId = purchase.productID;
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _failPending(
            productId,
            const PurchaseFailure.pending(),
          );
        case PurchaseStatus.error:
          _failPending(
            productId,
            PurchaseFailure(
              purchase.error?.message,
              _mapError(purchase.error?.code),
            ),
          );
        case PurchaseStatus.canceled:
          _failPending(
            productId,
            const PurchaseFailure.userCancelled(),
          );
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final String token = purchase.verificationData.serverVerificationData;
          if (token.isEmpty) {
            _failPending(
              productId,
              const PurchaseFailure.verificationFailed(),
            );
            break;
          }
          final PlayPurchaseEvent event = PlayPurchaseEvent(
            productId: productId,
            purchaseToken: token,
            purchaseId: purchase.purchaseID ?? '',
            details: purchase,
          );
          _eventsController.add(event);
          final Completer<PlayPurchaseEvent>? pending = _pendingByProduct
              .remove(productId);
          pending?.complete(event);
        }
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
