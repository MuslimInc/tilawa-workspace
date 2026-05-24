import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/app_review/domain/repositories/app_review_repository.dart';
import 'package:tilawa/features/app_review/domain/usecases/is_app_review_available_use_case.dart';
import 'package:tilawa/features/app_review/domain/usecases/open_app_store_listing_use_case.dart';
import 'package:tilawa/features/app_review/domain/usecases/request_app_review_use_case.dart';
import 'package:tilawa/features/app_review/presentation/cubit/app_review_cubit.dart';
import 'package:tilawa/features/app_review/presentation/cubit/app_review_state.dart';
import 'package:tilawa/features/settings/presentation/widgets/settings_shared.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class _FakeRepo implements AppReviewRepository {
  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> openStoreListing() async {}

  @override
  Future<void> requestReview() async {}
}

class _TestAppReviewCubit extends AppReviewCubit {
  _TestAppReviewCubit()
    : super(
        _AlwaysAvailable(),
        _NoOpRequestReview(),
        _NoOpOpenStore(),
      );

  int _rateFromSettingsCalls = 0;

  int get rateFromSettingsCalls => _rateFromSettingsCalls;

  @override
  Future<void> rateFromSettings() async {
    _rateFromSettingsCalls++;
    emit(
      state.copyWith(
        isOpeningStore: true,
        clearFailure: true,
      ),
    );
    emit(state.copyWith(isOpeningStore: false));
  }
}

class _AlwaysAvailable extends IsAppReviewAvailableUseCase {
  _AlwaysAvailable() : super(_FakeRepo());

  @override
  Future<Either<Failure, bool>> call() async => const Right(true);
}

class _NoOpRequestReview extends RequestAppReviewUseCase {
  _NoOpRequestReview() : super(_FakeRepo());

  @override
  Future<Either<Failure, void>> call() async => const Right(null);
}

class _NoOpOpenStore extends OpenAppStoreListingUseCase {
  _NoOpOpenStore() : super(_FakeRepo());

  @override
  Future<Either<Failure, void>> call() async => const Right(null);
}

Widget _buildHarness({
  required AppReviewCubit cubit,
}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: ThemeData(extensions: [TilawaDesignTokens.light()]),
    home: BlocProvider<AppReviewCubit>.value(
      value: cubit,
      child: const Scaffold(
        body: SettingsRateAppTile(),
      ),
    ),
  );
}

void main() {
  testWidgets('shows localized rate row', (WidgetTester tester) async {
    final cubit = _TestAppReviewCubit();
    addTearDown(cubit.close);

    await tester.pumpWidget(_buildHarness(cubit: cubit));

    expect(find.text('Rate Tilawa'), findsOneWidget);
    expect(find.text('Share your feedback on the app store.'), findsOneWidget);
  });

  testWidgets('tap requests rating from settings flow', (
    WidgetTester tester,
  ) async {
    final cubit = _TestAppReviewCubit();
    addTearDown(cubit.close);

    await tester.pumpWidget(_buildHarness(cubit: cubit));
    await tester.tap(find.text('Rate Tilawa'));
    await tester.pumpAndSettle();

    expect(cubit.rateFromSettingsCalls, 1);
  });

  testWidgets('shows loading indicator while busy', (
    WidgetTester tester,
  ) async {
    final cubit = _TestAppReviewCubit();
    addTearDown(cubit.close);

    await tester.pumpWidget(_buildHarness(cubit: cubit));
    cubit.emit(
      const AppReviewState(isOpeningStore: true),
    );
    await tester.pump();

    expect(find.byType(TilawaLoadingIndicator), findsOneWidget);
  });

  testWidgets('ignores tap while busy', (WidgetTester tester) async {
    final cubit = _TestAppReviewCubit();
    addTearDown(cubit.close);

    await tester.pumpWidget(_buildHarness(cubit: cubit));
    cubit.emit(
      const AppReviewState(isOpeningStore: true),
    );
    await tester.pump();

    await tester.tap(find.text('Rate Tilawa'));
    await tester.pump();

    expect(cubit.rateFromSettingsCalls, 0);
  });
}
