import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/support/data/datasources/play_billing_datasource.dart';
import 'package:tilawa/features/support/domain/constants/support_product_ids.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../helpers/support_purchase_test_helpers.dart';

class MockInAppPurchase extends Mock implements InAppPurchase {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      supportPurchaseDetails(),
    );
  });

  late MockInAppPurchase mockInAppPurchase;
  late StreamController<List<PurchaseDetails>> purchaseStream;
  late PlayBillingDataSourceImpl dataSource;

  setUp(() {
    mockInAppPurchase = MockInAppPurchase();
    purchaseStream = StreamController<List<PurchaseDetails>>.broadcast();
    when(() => mockInAppPurchase.purchaseStream).thenAnswer(
      (_) => purchaseStream.stream,
    );
    when(() => mockInAppPurchase.isAvailable()).thenAnswer((_) async => true);
    when(() => mockInAppPurchase.restorePurchases()).thenAnswer((_) async {});
    when(() => mockInAppPurchase.completePurchase(any())).thenAnswer(
      (_) async {},
    );
    dataSource = PlayBillingDataSourceImpl(mockInAppPurchase);
  });

  tearDown(() {
    dataSource.dispose();
    purchaseStream.close();
  });

  group('resume / background purchase updates', () {
    test('empty server token does not fail the active waiter', () async {
      final Future<PlayPurchaseEvent> pending = dataSource.waitForPurchaseEvent(
        SupportProductIds.small,
      );

      purchaseStream.add(<PurchaseDetails>[
        supportPurchaseDetails(serverToken: ''),
      ]);
      await Future<void>.delayed(Duration.zero);

      var completed = false;
      unawaited(
        pending
            .then((_) {
              completed = true;
            })
            .catchError((_) {}),
      );
      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);

      purchaseStream.add(<PurchaseDetails>[
        supportPurchaseDetails(serverToken: 'valid-token'),
      ]);
      final PlayPurchaseEvent event = await pending;
      expect(event.purchaseToken, 'valid-token');
    });

    test(
      'stale purchased event is acknowledged when no waiter exists',
      () async {
        await dataSource.restorePurchases();

        purchaseStream.add(<PurchaseDetails>[
          supportPurchaseDetails(serverToken: 'stale-token'),
        ]);
        await Future<void>.delayed(Duration.zero);

        verify(() => mockInAppPurchase.completePurchase(any())).called(1);
      },
    );
  });

  group('prepareForSupportScreen', () {
    test('cancels abandoned purchase waiters', () async {
      final Future<PlayPurchaseEvent> pending = dataSource.waitForPurchaseEvent(
        SupportProductIds.small,
      );

      final Future<void> cancelled = expectLater(
        pending,
        throwsA(
          isA<PurchaseFailure>().having(
            (PurchaseFailure f) => f.reason,
            'reason',
            PurchaseFailureReason.userCancelled,
          ),
        ),
      );

      await dataSource.prepareForSupportScreen();
      await cancelled;

      verify(() => mockInAppPurchase.restorePurchases()).called(1);
    });

    test('canceled purchase status completes the waiter with userCancelled', () async {
      final Future<PlayPurchaseEvent> pending = dataSource
          .waitForPurchaseEvent(SupportProductIds.small);

      final Future<void> cancelled = expectLater(
        pending,
        throwsA(
          isA<PurchaseFailure>().having(
            (PurchaseFailure f) => f.reason,
            'reason',
            PurchaseFailureReason.userCancelled,
          ),
        ),
      );

      purchaseStream.add(<PurchaseDetails>[
        supportPurchaseDetails(status: PurchaseStatus.canceled),
      ]);
      await cancelled;
    });

    test('does not cancel waiters when cancelActiveWaiters is false', () async {
      final Future<PlayPurchaseEvent> pending = dataSource.waitForPurchaseEvent(
        SupportProductIds.small,
      );

      await dataSource.prepareForSupportScreen(cancelActiveWaiters: false);

      var completed = false;
      unawaited(
        pending
            .then((_) {
              completed = true;
            })
            .catchError((_) {}),
      );
      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);
    });
  });
}
