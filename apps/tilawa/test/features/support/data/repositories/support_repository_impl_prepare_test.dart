import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/support/data/datasources/play_billing_datasource.dart';
import 'package:tilawa/features/support/data/datasources/support_local_datasource.dart';
import 'package:tilawa/features/support/data/repositories/support_repository_impl.dart';
import 'package:tilawa/features/support/data/services/purchase_verification_client.dart';
import 'package:tilawa_core/services/analytics_service.dart';

class MockPlayBillingDataSource extends Mock implements PlayBillingDataSource {}

class MockSupportLocalDataSource extends Mock
    implements SupportLocalDataSource {}

class MockPurchaseVerificationClient extends Mock
    implements PurchaseVerificationClient {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  late MockPlayBillingDataSource mockBilling;
  late SupportRepositoryImpl repository;

  setUp(() {
    mockBilling = MockPlayBillingDataSource();
    repository = SupportRepositoryImpl(
      mockBilling,
      MockSupportLocalDataSource(),
      MockPurchaseVerificationClient(),
      MockAnalyticsService(),
    );
    when(
      () => mockBilling.prepareForSupportScreen(
        cancelActiveWaiters: any(named: 'cancelActiveWaiters'),
      ),
    ).thenAnswer((_) async {});
  });

  test('prepareSupportSession resets billing waiters by default', () async {
    await repository.prepareSupportSession();

    verify(
      () => mockBilling.prepareForSupportScreen(cancelActiveWaiters: true),
    ).called(1);
  });

  test('prepareSupportSession can preserve active waiters on resume', () async {
    await repository.prepareSupportSession(resetWaiters: false);

    verify(
      () => mockBilling.prepareForSupportScreen(cancelActiveWaiters: false),
    ).called(1);
  });
}
