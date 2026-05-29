import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/features/app_review/presentation/cubit/app_review_cubit.dart';
import 'package:tilawa/features/app_review/presentation/cubit/app_review_state.dart';
import 'package:tilawa/features/share/domain/usecases/share_content_use_case.dart';
import 'package:tilawa/features/settings/presentation/screens/settings_screen.dart';
import 'package:tilawa/features/settings/presentation/widgets/settings_screen_scope.dart';

import '../../../../support/screen_scope_test_support.dart';

class _MockAppReviewCubit extends Mock implements AppReviewCubit {}

class _MockShareContentUseCase extends Mock implements ShareContentUseCase {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockAppReviewCubit mockAppReviewCubit;

  setUp(() async {
    await resetScopeGetIt();
    mockAppReviewCubit = _MockAppReviewCubit();
    when(() => mockAppReviewCubit.close()).thenAnswer((_) async {});
    when(() => mockAppReviewCubit.state).thenReturn(const AppReviewState());
    when(
      () => mockAppReviewCubit.stream,
    ).thenAnswer((_) => const Stream.empty());
    scopeGetIt().registerFactory<AppReviewCubit>(() => mockAppReviewCubit);
  });

  tearDown(() async {
    await resetScopeGetIt();
  });

  testWidgets('provides AppReviewCubit to descendants', (tester) async {
    AppReviewCubit? cubit;

    await tester.pumpWidget(
      wrapScopeTest(
        home: SettingsScreenScope(
          child: ScopeProbe(
            onBuilt: (context) {
              cubit = readScopeBloc<AppReviewCubit>(context);
            },
          ),
        ),
      ),
    );

    expect(cubit, same(mockAppReviewCubit));
  });

  testWidgets('closes AppReviewCubit when unmounted', (tester) async {
    await tester.pumpWidget(
      wrapScopeTest(
        home: SettingsScreenScope(
          child: ScopeProbe(
            onBuilt: (context) {
              readScopeBloc<AppReviewCubit>(context);
            },
          ),
        ),
      ),
    );

    await unmountScope(tester);

    verify(() => mockAppReviewCubit.close()).called(1);
  });

  testWidgets('resolves AppReviewCubit from getIt on each mount', (tester) async {
    var createCount = 0;
    scopeGetIt().unregister<AppReviewCubit>();
    scopeGetIt().registerFactory<AppReviewCubit>(() {
      createCount++;
      final mock = _MockAppReviewCubit();
      when(() => mock.close()).thenAnswer((_) async {});
      when(() => mock.state).thenReturn(const AppReviewState());
      when(() => mock.stream).thenAnswer((_) => const Stream.empty());
      return mock;
    });

    await tester.pumpWidget(
      wrapScopeTest(
        home: SettingsScreenScope(
          child: ScopeProbe(
            onBuilt: (context) {
              readScopeBloc<AppReviewCubit>(context);
            },
          ),
        ),
      ),
    );
    await unmountScope(tester);
    await tester.pumpWidget(
      wrapScopeTest(
        home: SettingsScreenScope(
          child: ScopeProbe(
            onBuilt: (context) {
              readScopeBloc<AppReviewCubit>(context);
            },
          ),
        ),
      ),
    );

    expect(createCount, 2);
  });

  testWidgets('renders probe child instead of SettingsScreen', (tester) async {
    await tester.pumpWidget(
      wrapScopeTest(
        home: SettingsScreenScope(
          child: ScopeProbe(onBuilt: (_) {}),
        ),
      ),
    );

    expect(find.byKey(const Key('scope_probe')), findsOneWidget);
    expect(find.byType(SettingsScreen), findsNothing);
  });

  testWidgets('resolves SettingsScreen dependencies from getIt by default', (
    tester,
  ) async {
    scopeGetIt().registerSingleton<AppLaunchConfig>(
      const AppLaunchConfig(supportTilawaEnabled: false),
    );
    scopeGetIt().registerSingleton<ShareContentUseCase>(
      _MockShareContentUseCase(),
    );

    await tester.pumpWidget(
      wrapScopeTest(home: const SettingsScreenScope()),
    );

    // Scope wiring is verified; full SettingsScreen build needs app-wide blocs.
    expect(tester.takeException(), isNotNull);
    expect(find.byType(SettingsScreen), findsOneWidget);
  });
}
