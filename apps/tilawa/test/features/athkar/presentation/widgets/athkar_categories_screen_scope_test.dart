import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/athkar/presentation/cubit/athkar_cubit.dart';
import 'package:tilawa/features/athkar/presentation/cubit/athkar_state.dart';
import 'package:tilawa/features/athkar/presentation/screens/athkar_categories_screen.dart';
import 'package:tilawa/features/athkar/presentation/widgets/athkar_categories_screen_scope.dart';

import '../../../../support/screen_scope_test_support.dart';

class _MockAthkarCubit extends Mock implements AthkarCubit {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockAthkarCubit mockAthkarCubit;

  setUp(() async {
    await resetScopeGetIt();
    mockAthkarCubit = _MockAthkarCubit();
    when(() => mockAthkarCubit.loadCategories()).thenAnswer((_) async {});
    when(() => mockAthkarCubit.close()).thenAnswer((_) async {});
    when(() => mockAthkarCubit.state).thenReturn(const AthkarState.initial());
    when(() => mockAthkarCubit.stream).thenAnswer((_) => const Stream.empty());
    scopeGetIt().registerFactory<AthkarCubit>(() => mockAthkarCubit);
  });

  tearDown(() async {
    await resetScopeGetIt();
  });

  testWidgets('provides AthkarCubit and triggers loadCategories', (
    tester,
  ) async {
    AthkarCubit? cubit;

    await tester.pumpWidget(
      wrapScopeTest(
        home: AthkarCategoriesScreenScope(
          child: ScopeProbe(
            onBuilt: (context) {
              cubit = readScopeBloc<AthkarCubit>(context);
            },
          ),
        ),
      ),
    );

    expect(cubit, same(mockAthkarCubit));
    verify(() => mockAthkarCubit.loadCategories()).called(1);
  });

  testWidgets('closes AthkarCubit when unmounted', (tester) async {
    await tester.pumpWidget(
      wrapScopeTest(
        home: AthkarCategoriesScreenScope(
          child: ScopeProbe(
            onBuilt: (context) {
              readScopeBloc<AthkarCubit>(context);
            },
          ),
        ),
      ),
    );

    await unmountScope(tester);

    verify(() => mockAthkarCubit.close()).called(1);
  });

  testWidgets('renders probe child instead of AthkarCategoriesScreen', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapScopeTest(
        home: AthkarCategoriesScreenScope(
          child: ScopeProbe(onBuilt: (_) {}),
        ),
      ),
    );

    expect(find.byKey(const Key('scope_probe')), findsOneWidget);
    expect(find.byType(AthkarCategoriesScreen), findsNothing);
  });
}
