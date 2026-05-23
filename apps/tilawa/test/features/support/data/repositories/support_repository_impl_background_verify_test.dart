import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/support/data/datasources/play_billing_datasource.dart';
import 'package:tilawa/features/support/data/datasources/support_local_datasource.dart';
import 'package:tilawa/features/support/data/repositories/support_repository_impl.dart';
import 'package:tilawa/features/support/data/services/purchase_verification_client.dart';
import 'package:tilawa/features/support/domain/constants/support_product_ids.dart';
import 'package:tilawa/features/support/domain/entities/purchase_outcome.dart';
import 'package:tilawa_core/services/analytics_service.dart';

import '../../helpers/support_purchase_test_helpers.dart';

class _MockBilling extends Mock implements PlayBillingDataSource {}

class _MockLocal extends Mock implements SupportLocalDataSource {}

class _MockVerify extends Mock implements PurchaseVerificationClient {}

class _MockAnalytics extends Mock implements AnalyticsService {}

void main() {
  setUpAll(() {
    registerFallbackValue(supportPurchaseDetails());
  });

  late _MockBilling billing;
  late _MockLocal local;
  late _MockVerify verifyClient;
  late _MockAnalytics analytics;
  late StreamController<PlayPurchaseEvent> events;

  setUp(() {
    billing = _MockBilling();
    local = _MockLocal();
    verifyClient = _MockVerify();
    analytics = _MockAnalytics();
    events = StreamController<PlayPurchaseEvent>.broadcast();

    when(() => billing.purchaseEvents).thenAnswer((_) => events.stream);
    when(() => billing.completePurchase(any())).thenAnswer((_) async {});
    when(
      () => local.saveLastSupport(
        productId: any(named: 'productId'),
        at: any(named: 'at'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => analytics.logEvent(any(), parameters: any(named: 'parameters')),
    ).thenAnswer((_) async {});
  });

  tearDown(() async {
    await events.close();
  });

  test(
    'background purchase event is verified, persisted, and completed even '
    'when no caller awaits purchaseSupportProduct',
    () async {
      when(
        () => verifyClient.verify(
          productId: any(named: 'productId'),
          purchaseToken: any(named: 'purchaseToken'),
        ),
      ).thenAnswer(
        (_) async => const VerifiedPurchase(
          orderId: 'order-123',
          productId: SupportProductIds.small,
        ),
      );

      SupportRepositoryImpl(billing, local, verifyClient, analytics);

      events.add(
        PlayPurchaseEvent(
          productId: SupportProductIds.small,
          purchaseToken: 'bg-token',
          purchaseId: 'order-123',
          details: supportPurchaseDetails(serverToken: 'bg-token'),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      verify(
        () => verifyClient.verify(
          productId: SupportProductIds.small,
          purchaseToken: 'bg-token',
        ),
      ).called(1);
      verify(() => billing.completePurchase(any())).called(1);
      verify(
        () => local.saveLastSupport(
          productId: SupportProductIds.small,
          at: any(named: 'at'),
        ),
      ).called(1);
    },
  );

  test('duplicate token from stream is verified only once', () async {
    when(
      () => verifyClient.verify(
        productId: any(named: 'productId'),
        purchaseToken: any(named: 'purchaseToken'),
      ),
    ).thenAnswer(
      (_) async => const VerifiedPurchase(
        orderId: 'order-1',
        productId: SupportProductIds.small,
      ),
    );

    SupportRepositoryImpl(billing, local, verifyClient, analytics);

    final PlayPurchaseEvent event = PlayPurchaseEvent(
      productId: SupportProductIds.small,
      purchaseToken: 'same-token',
      purchaseId: 'order-1',
      details: supportPurchaseDetails(serverToken: 'same-token'),
    );

    events.add(event);
    await Future<void>.delayed(Duration.zero);
    events.add(event);
    await Future<void>.delayed(Duration.zero);

    verify(
      () => verifyClient.verify(
        productId: SupportProductIds.small,
        purchaseToken: 'same-token',
      ),
    ).called(1);
  });

  test(
    'purchaseSupportProduct returns outcome when stream verifies first',
    () async {
      const String token = 'race-token';
      final PlayPurchaseEvent event = PlayPurchaseEvent(
        productId: SupportProductIds.small,
        purchaseToken: token,
        purchaseId: 'order-race',
        details: supportPurchaseDetails(serverToken: token),
      );

      when(() => billing.buyConsumable(any())).thenAnswer((_) async {});
      when(() => billing.waitForPurchaseEvent(any())).thenAnswer((_) async {
        events.add(event);
        await Future<void>.delayed(Duration.zero);
        return event;
      });
      when(
        () => verifyClient.verify(
          productId: any(named: 'productId'),
          purchaseToken: any(named: 'purchaseToken'),
        ),
      ).thenAnswer(
        (_) async => const VerifiedPurchase(
          orderId: 'order-race',
          productId: SupportProductIds.small,
        ),
      );

      final SupportRepositoryImpl repository = SupportRepositoryImpl(
        billing,
        local,
        verifyClient,
        analytics,
      );

      final PurchaseOutcome outcome = await repository.purchaseSupportProduct(
        SupportProductIds.small,
      );

      expect(outcome.productId, SupportProductIds.small);
      verify(
        () => verifyClient.verify(
          productId: SupportProductIds.small,
          purchaseToken: token,
        ),
      ).called(1);
    },
  );
}
