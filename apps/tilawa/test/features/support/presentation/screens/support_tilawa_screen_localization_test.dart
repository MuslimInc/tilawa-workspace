import 'package:bloc_test/bloc_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/support/domain/usecases/abort_pending_purchase_use_case.dart';
import 'package:tilawa/features/support/domain/usecases/get_support_products_use_case.dart';
import 'package:tilawa/features/support/domain/usecases/prepare_support_session_use_case.dart';
import 'package:tilawa/features/support/domain/usecases/purchase_support_product_use_case.dart';
import 'package:tilawa/features/support/domain/usecases/restore_purchases_use_case.dart';
import 'package:tilawa/features/support/presentation/bloc/support_bloc.dart';
import 'package:tilawa/features/support/presentation/bloc/support_event.dart';
import 'package:tilawa/features/support/presentation/bloc/support_state.dart';
import 'package:tilawa/features/support/presentation/screens/support_tilawa_screen.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/services/analytics_service.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

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

void main() {
  late MockPrepareSupportSessionUseCase mockPrepare;
  late MockGetSupportProductsUseCase mockGetProducts;
  late MockPurchaseSupportProductUseCase mockPurchase;
  late MockRestorePurchasesUseCase mockRestore;
  late MockAbortPendingPurchaseUseCase mockAbort;
  late MockConnectivity mockConnectivity;
  late MockAnalyticsService mockAnalytics;
  late AppLocalizations ar;
  late AppLocalizations en;

  setUpAll(() {
    ar = lookupAppLocalizations(const Locale('ar'));
    en = lookupAppLocalizations(const Locale('en'));
  });

  setUp(() {
    mockPrepare = MockPrepareSupportSessionUseCase();
    mockGetProducts = MockGetSupportProductsUseCase();
    mockPurchase = MockPurchaseSupportProductUseCase();
    mockRestore = MockRestorePurchasesUseCase();
    mockAbort = MockAbortPendingPurchaseUseCase();
    mockConnectivity = MockConnectivity();
    mockAnalytics = MockAnalyticsService();

    when(() => mockPrepare()).thenAnswer((_) async {});
    when(() => mockAbort(any())).thenReturn(true);
    when(() => mockAnalytics.logEvent(any(), parameters: any(named: 'parameters')))
        .thenAnswer((_) async {});
    when(() => mockConnectivity.checkConnectivity()).thenAnswer(
      (_) async => <ConnectivityResult>[ConnectivityResult.wifi],
    );
    when(() => mockGetProducts()).thenAnswer(
      (_) async => const Left(PurchaseFailure.verificationFailed()),
    );
  });

  Widget buildSubject({
    required Locale locale,
    required SupportBloc bloc,
  }) {
    return MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: ThemeData(extensions: [TilawaDesignTokens.light()]),
      home: BlocProvider<SupportBloc>.value(
        value: bloc,
        child: const SupportTilawaScreen(),
      ),
    );
  }

  testWidgets(
    'error state shows Arabic verification message when locale is ar',
    (tester) async {
      final SupportBloc bloc = SupportBloc(
        mockPrepare,
        mockGetProducts,
        mockPurchase,
        mockRestore,
        mockAbort,
        mockConnectivity,
        mockAnalytics,
      );
      bloc.add(const SupportEvent.started());

      await tester.pumpWidget(buildSubject(locale: const Locale('ar'), bloc: bloc));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      addTearDown(bloc.close);

      expect(find.text(ar.purchaseVerificationFailed), findsOneWidget);
      expect(find.text(en.purchaseVerificationFailed), findsNothing);
      expect(find.text(ar.supportTilawa), findsOneWidget);
    },
  );

  testWidgets(
    'error state shows English verification message when locale is en',
    (tester) async {
      final SupportBloc bloc = SupportBloc(
        mockPrepare,
        mockGetProducts,
        mockPurchase,
        mockRestore,
        mockAbort,
        mockConnectivity,
        mockAnalytics,
      );
      bloc.add(const SupportEvent.started());

      await tester.pumpWidget(buildSubject(locale: const Locale('en'), bloc: bloc));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      addTearDown(bloc.close);

      expect(find.text(en.purchaseVerificationFailed), findsOneWidget);
      expect(find.text(ar.purchaseVerificationFailed), findsNothing);
    },
  );

  testWidgets(
    'purchase failure with English message still shows Arabic error UI',
    (tester) async {
      const String firebaseEnglish =
          'We could not confirm your support. Please try again.';
      when(() => mockGetProducts()).thenAnswer(
        (_) async => const Left(
          PurchaseFailure(
            firebaseEnglish,
            PurchaseFailureReason.verificationFailed,
          ),
        ),
      );

      final SupportBloc bloc = SupportBloc(
        mockPrepare,
        mockGetProducts,
        mockPurchase,
        mockRestore,
        mockAbort,
        mockConnectivity,
        mockAnalytics,
      );
      bloc.add(const SupportEvent.started());

      await tester.pumpWidget(buildSubject(locale: const Locale('ar'), bloc: bloc));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      addTearDown(bloc.close);

      expect(find.text(ar.purchaseVerificationFailed), findsOneWidget);
      expect(find.text(firebaseEnglish), findsNothing);
    },
  );

  testWidgets(
    'error text stays Arabic when only BlocConsumer rebuilds',
    (tester) async {
      var parentBuildCount = 0;

      final SupportBloc bloc = SupportBloc(
        mockPrepare,
        mockGetProducts,
        mockPurchase,
        mockRestore,
        mockAbort,
        mockConnectivity,
        mockAnalytics,
      );
      addTearDown(bloc.close);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: ThemeData(extensions: [TilawaDesignTokens.light()]),
          home: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              parentBuildCount++;
              return BlocProvider<SupportBloc>.value(
                value: bloc,
                child: const SupportTilawaScreen(),
              );
            },
          ),
        ),
      );
      await tester.pump();

      final int buildsBeforeBlocUpdate = parentBuildCount;
      bloc.add(const SupportEvent.started());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(parentBuildCount, buildsBeforeBlocUpdate);
      expect(find.text(ar.purchaseVerificationFailed), findsOneWidget);
      expect(find.text(en.purchaseVerificationFailed), findsNothing);
    },
  );

  blocTest<SupportBloc, SupportState>(
    'product load failure keeps verification reason for localization',
    build: () => SupportBloc(
      mockPrepare,
      mockGetProducts,
      mockPurchase,
      mockRestore,
      mockAbort,
      mockConnectivity,
      mockAnalytics,
    ),
    act: (SupportBloc bloc) async {
      bloc.add(const SupportEvent.started());
      await Future<void>.delayed(Duration.zero);
    },
    skip: 1,
    expect: () => <dynamic>[
      isA<SupportState>()
          .having(
            (SupportState s) => s.status,
            'status',
            SupportStatus.error,
          )
          .having(
            (SupportState s) => s.failure,
            'failure',
            isA<PurchaseFailure>().having(
              (PurchaseFailure f) => f.reason,
              'reason',
              PurchaseFailureReason.verificationFailed,
            ),
          ),
    ],
  );
}
