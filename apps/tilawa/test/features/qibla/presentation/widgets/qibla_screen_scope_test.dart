import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/qibla/presentation/bloc/qibla_bloc.dart';
import 'package:tilawa/features/qibla/presentation/screens/qibla_screen.dart';
import 'package:tilawa/features/qibla/presentation/widgets/qibla_screen_scope.dart';

import '../../../../support/screen_scope_test_support.dart';

class _MockQiblaBloc extends Mock implements QiblaBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockQiblaBloc mockQiblaBloc;

  setUp(() async {
    await resetScopeGetIt();
    mockQiblaBloc = _MockQiblaBloc();
    when(() => mockQiblaBloc.close()).thenAnswer((_) async {});
    when(() => mockQiblaBloc.state).thenReturn(const QiblaState());
    when(() => mockQiblaBloc.stream).thenAnswer((_) => const Stream.empty());
    scopeGetIt().registerFactory<QiblaBloc>(() => mockQiblaBloc);
  });

  tearDown(() async {
    await resetScopeGetIt();
  });

  testWidgets('provides QiblaBloc to descendants', (tester) async {
    QiblaBloc? bloc;

    await tester.pumpWidget(
      wrapScopeTest(
        home: QiblaScreenScope(
          child: ScopeProbe(
            onBuilt: (context) {
              bloc = readScopeBloc<QiblaBloc>(context);
            },
          ),
        ),
      ),
    );

    expect(bloc, same(mockQiblaBloc));
  });

  testWidgets('closes QiblaBloc when unmounted', (tester) async {
    await tester.pumpWidget(
      wrapScopeTest(
        home: QiblaScreenScope(
          child: ScopeProbe(
            onBuilt: (context) {
              readScopeBloc<QiblaBloc>(context);
            },
          ),
        ),
      ),
    );

    await unmountScope(tester);

    verify(() => mockQiblaBloc.close()).called(1);
  });

  testWidgets('creates a new QiblaBloc from getIt on each mount', (
    tester,
  ) async {
    var createCount = 0;
    scopeGetIt().unregister<QiblaBloc>();
    scopeGetIt().registerFactory<QiblaBloc>(() {
      createCount++;
      final mock = _MockQiblaBloc();
      when(() => mock.close()).thenAnswer((_) async {});
      when(() => mock.state).thenReturn(const QiblaState());
      when(() => mock.stream).thenAnswer((_) => const Stream.empty());
      return mock;
    });

    await tester.pumpWidget(
      wrapScopeTest(
        home: QiblaScreenScope(
          child: ScopeProbe(
            onBuilt: (context) {
              readScopeBloc<QiblaBloc>(context);
            },
          ),
        ),
      ),
    );
    await unmountScope(tester);
    await tester.pumpWidget(
      wrapScopeTest(
        home: QiblaScreenScope(
          child: ScopeProbe(
            onBuilt: (context) {
              readScopeBloc<QiblaBloc>(context);
            },
          ),
        ),
      ),
    );

    expect(createCount, 2);
  });

  testWidgets('renders probe child instead of QiblaScreen', (tester) async {
    await tester.pumpWidget(
      wrapScopeTest(
        home: QiblaScreenScope(
          child: ScopeProbe(onBuilt: (_) {}),
        ),
      ),
    );

    expect(find.byKey(const Key('scope_probe')), findsOneWidget);
    expect(find.byType(QiblaScreen), findsNothing);
  });
}
