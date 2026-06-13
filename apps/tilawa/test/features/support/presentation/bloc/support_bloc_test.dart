import 'package:bloc_test/bloc_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/support/domain/entities/support_product.dart';
import 'package:tilawa/features/support/domain/usecases/abort_pending_purchase_use_case.dart';
import 'package:tilawa/features/support/domain/usecases/get_support_products_use_case.dart';
import 'package:tilawa/features/support/domain/usecases/prepare_support_session_use_case.dart';
import 'package:tilawa/features/support/domain/usecases/purchase_support_product_use_case.dart';
import 'package:tilawa/features/support/domain/usecases/restore_purchases_use_case.dart';
import 'package:tilawa/features/support/presentation/bloc/support_bloc.dart';
import 'package:tilawa/features/support/presentation/bloc/support_event.dart';
import 'package:tilawa/features/support/presentation/bloc/support_state.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/services/analytics_service.dart';

class MockPrepareSupportSessionUseCase extends Mock
    implements PrepareSupportSessionUseCase {}

class MockGetSupportProductsUseCase extends Mock
    implements GetSupportProductsUseCase {}

class MockPurchaseSupportProductUseCase extends Mock
    implements PurchaseSupportProductUseCase {}

class MockRestorePurchasesUseCase extends Mock
    implements RestorePurchasesUseCase {}

class MockAbortPendingPurchaseUseCase extends Mock
    implements AbortPendingPurchaseUseCase {}

class MockConnectivity extends Mock implements Connectivity {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

const SupportProduct _product = SupportProduct(
  id: 'support_once_small',
  title: 'support_once_small',
  price: r'$2.99',
  rawPrice: 2.99,
  currencyCode: 'USD',
  displayOrder: 0,
);

SupportBloc _buildBloc({
  required MockPrepareSupportSessionUseCase prepare,
  required MockGetSupportProductsUseCase getProducts,
  required MockPurchaseSupportProductUseCase purchase,
  required MockRestorePurchasesUseCase restore,
  required MockAbortPendingPurchaseUseCase abort,
  required MockConnectivity connectivity,
  required MockAnalyticsService analytics,
}) {
  return SupportBloc(
    prepare,
    getProducts,
    purchase,
    restore,
    abort,
    connectivity,
    analytics,
  );
}

void main() {
  late MockPrepareSupportSessionUseCase mockPrepare;
  late MockGetSupportProductsUseCase mockGetProducts;
  late MockPurchaseSupportProductUseCase mockPurchase;
  late MockRestorePurchasesUseCase mockRestore;
  late MockAbortPendingPurchaseUseCase mockAbort;
  late MockConnectivity mockConnectivity;
  late MockAnalyticsService mockAnalytics;

  setUp(() {
    mockPrepare = MockPrepareSupportSessionUseCase();
    mockGetProducts = MockGetSupportProductsUseCase();
    mockPurchase = MockPurchaseSupportProductUseCase();
    mockRestore = MockRestorePurchasesUseCase();
    mockAbort = MockAbortPendingPurchaseUseCase();
    mockConnectivity = MockConnectivity();
    mockAnalytics = MockAnalyticsService();

    when(() => mockPrepare()).thenAnswer((_) async {});
    when(
      () => mockPrepare(resetWaiters: any(named: 'resetWaiters')),
    ).thenAnswer((_) async {});
    when(() => mockAbort(any())).thenReturn(true);
    when(
      () => mockAnalytics.logEvent(any(), parameters: any(named: 'parameters')),
    ).thenAnswer((_) async {});
    when(() => mockConnectivity.checkConnectivity()).thenAnswer(
      (_) async => <ConnectivityResult>[ConnectivityResult.wifi],
    );
    when(() => mockGetProducts()).thenAnswer(
      (_) async => const Right(<SupportProduct>[_product]),
    );
  });

  blocTest<SupportBloc, SupportState>(
    'started prepares billing and resets purchase phase',
    build: () => _buildBloc(
      prepare: mockPrepare,
      getProducts: mockGetProducts,
      purchase: mockPurchase,
      restore: mockRestore,
      abort: mockAbort,
      connectivity: mockConnectivity,
      analytics: mockAnalytics,
    ),
    seed: () => const SupportState(
      purchasePhase: SupportPurchasePhase.purchasing,
      failure: PurchaseFailure.verificationFailed(),
    ),
    act: (SupportBloc bloc) => bloc.add(const SupportEvent.started()),
    verify: (_) {
      verify(() => mockPrepare()).called(1);
    },
    expect: () => <dynamic>[
      isA<SupportState>()
          .having(
            (SupportState s) => s.status,
            'status',
            SupportStatus.loading,
          )
          .having(
            (SupportState s) => s.purchasePhase,
            'purchasePhase',
            SupportPurchasePhase.idle,
          )
          .having((SupportState s) => s.failure, 'failure', isNull),
      isA<SupportState>()
          .having(
            (SupportState s) => s.status,
            'status',
            SupportStatus.ready,
          )
          .having((SupportState s) => s.failure, 'failure', isNull),
    ],
  );

  blocTest<SupportBloc, SupportState>(
    'appResumed clears stale verification failure when idle',
    build: () => _buildBloc(
      prepare: mockPrepare,
      getProducts: mockGetProducts,
      purchase: mockPurchase,
      restore: mockRestore,
      abort: mockAbort,
      connectivity: mockConnectivity,
      analytics: mockAnalytics,
    ),
    seed: () => const SupportState(
      status: SupportStatus.ready,
      products: <SupportProduct>[_product],
      failure: PurchaseFailure.verificationFailed(),
      purchasePhase: SupportPurchasePhase.idle,
    ),
    act: (SupportBloc bloc) => bloc.add(const SupportEvent.appResumed()),
    verify: (_) {
      verify(() => mockPrepare(resetWaiters: false)).called(1);
    },
    expect: () => <dynamic>[
      isA<SupportState>().having(
        (SupportState s) => s.failure,
        'failure',
        isNull,
      ),
    ],
  );

  blocTest<SupportBloc, SupportState>(
    'appResumed during purchasing preserves the in-flight waiter '
    'but aborts it after the grace window if Play never delivers',
    build: () => _buildBloc(
      prepare: mockPrepare,
      getProducts: mockGetProducts,
      purchase: mockPurchase,
      restore: mockRestore,
      abort: mockAbort,
      connectivity: mockConnectivity,
      analytics: mockAnalytics,
    ),
    seed: () => SupportState(
      status: SupportStatus.ready,
      products: const <SupportProduct>[_product],
      selectedProductId: _product.id,
      purchasePhase: SupportPurchasePhase.purchasing,
      failure: const PurchaseFailure.verificationFailed(),
    ),
    act: (SupportBloc bloc) async {
      bloc.add(const SupportEvent.appResumed());
      // Wait long enough for the 1.5s grace window to elapse.
      await Future<void>.delayed(const Duration(milliseconds: 1700));
    },
    verify: (_) {
      // Do NOT reset waiters on resume — Play might still deliver.
      verify(() => mockPrepare(resetWaiters: false)).called(1);
      verifyNever(() => mockPrepare(resetWaiters: true));
      // After the grace, the waiter is aborted as billing-unavailable so
      // the UI clears the spinner instead of waiting 5 minutes.
      verify(() => mockAbort(_product.id)).called(1);
    },
    expect: () => <dynamic>[],
  );

  blocTest<SupportBloc, SupportState>(
    'purchaseConfirmed clears loading when purchase is cancelled',
    build: () => _buildBloc(
      prepare: mockPrepare,
      getProducts: mockGetProducts,
      purchase: mockPurchase,
      restore: mockRestore,
      abort: mockAbort,
      connectivity: mockConnectivity,
      analytics: mockAnalytics,
    ),
    seed: () => const SupportState(
      status: SupportStatus.ready,
      products: <SupportProduct>[_product],
      selectedProductId: 'support_once_small',
    ),
    setUp: () {
      when(() => mockPurchase('support_once_small')).thenAnswer(
        (_) async => const Left(PurchaseFailure.userCancelled()),
      );
    },
    act: (SupportBloc bloc) => bloc.add(const SupportEvent.purchaseConfirmed()),
    expect: () => <dynamic>[
      isA<SupportState>().having(
        (SupportState s) => s.purchasePhase,
        'purchasePhase',
        SupportPurchasePhase.purchasing,
      ),
      isA<SupportState>().having(
        (SupportState s) => s.purchasePhase,
        'purchasePhase',
        SupportPurchasePhase.idle,
      ),
    ],
  );

  blocTest<SupportBloc, SupportState>(
    'purchaseDismissed clears confirming phase and loading',
    build: () => _buildBloc(
      prepare: mockPrepare,
      getProducts: mockGetProducts,
      purchase: mockPurchase,
      restore: mockRestore,
      abort: mockAbort,
      connectivity: mockConnectivity,
      analytics: mockAnalytics,
    ),
    seed: () => const SupportState(
      status: SupportStatus.ready,
      products: <SupportProduct>[_product],
      selectedProductId: 'support_once_small',
      purchasePhase: SupportPurchasePhase.confirming,
    ),
    act: (SupportBloc bloc) => bloc.add(const SupportEvent.purchaseDismissed()),
    expect: () => <dynamic>[
      isA<SupportState>().having(
        (SupportState s) => s.purchasePhase,
        'purchasePhase',
        SupportPurchasePhase.idle,
      ),
    ],
  );
}
