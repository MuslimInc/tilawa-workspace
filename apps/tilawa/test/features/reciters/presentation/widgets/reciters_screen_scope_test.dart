import 'package:flutter/material.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/reciters/domain/usecases/get_reciters_use_case.dart';
import 'package:tilawa/features/reciters/presentation/bloc/alphabet_scrollbar/alphabet_scrollbar_bloc.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciters_bloc.dart';
import 'package:tilawa/features/reciters/presentation/screens/reciters_screen.dart';
import 'package:tilawa/features/reciters/presentation/widgets/reciters_screen_scope.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../../../support/screen_scope_test_support.dart';

class _MockGetRecitersUseCase extends Mock implements GetRecitersUseCase {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockGetRecitersUseCase mockGetReciters;

  const cachedReciters = [
    ReciterEntity(
      id: 1,
      name: 'Al-Afasy',
      letter: 'A',
      date: '2024',
      moshaf: [],
    ),
  ];

  setUp(() async {
    await resetScopeGetIt();
    mockGetReciters = _MockGetRecitersUseCase();
    when(() => mockGetReciters()).thenAnswer(
      (_) async => const Right<Failure, List<ReciterEntity>>([]),
    );
    when(() => mockGetReciters.takeCachedSuccessForStartup()).thenReturn(null);
    scopeGetIt().registerSingleton<GetRecitersUseCase>(mockGetReciters);
    scopeGetIt().registerFactory<AlphabetScrollbarBloc>(
      AlphabetScrollbarBloc.new,
    );
  });

  tearDown(() async {
    await resetScopeGetIt();
  });

  testWidgets('provides RecitersBloc and AlphabetScrollbarBloc', (
    tester,
  ) async {
    RecitersBloc? recitersBloc;
    AlphabetScrollbarBloc? alphabetBloc;

    await tester.pumpWidget(
      wrapScopeTest(
        home: RecitersScreenScope(
          child: ScopeProbe(
            onBuilt: (context) {
              recitersBloc = readScopeBloc<RecitersBloc>(context);
              alphabetBloc = readScopeBloc<AlphabetScrollbarBloc>(context);
            },
          ),
        ),
      ),
    );

    expect(recitersBloc, isNotNull);
    expect(alphabetBloc, isNotNull);
    verify(() => mockGetReciters.takeCachedSuccessForStartup()).called(1);
  });

  testWidgets('seeds RecitersBloc from startup cache when available', (
    tester,
  ) async {
    when(
      () => mockGetReciters.takeCachedSuccessForStartup(),
    ).thenReturn(cachedReciters);

    RecitersBloc? recitersBloc;
    await tester.pumpWidget(
      wrapScopeTest(
        home: RecitersScreenScope(
          child: ScopeProbe(
            onBuilt: (context) {
              recitersBloc = readScopeBloc<RecitersBloc>(context);
            },
          ),
        ),
      ),
    );

    expect(recitersBloc!.state, isA<RecitersLoaded>());
    final loaded = recitersBloc!.state as RecitersLoaded;
    expect(loaded.reciters, cachedReciters);
  });

  testWidgets('creates fresh AlphabetScrollbarBloc instances on remount', (
    tester,
  ) async {
    AlphabetScrollbarBloc? first;
    AlphabetScrollbarBloc? second;

    await tester.pumpWidget(
      wrapScopeTest(
        home: RecitersScreenScope(
          child: ScopeProbe(
            onBuilt: (context) {
              first = readScopeBloc<AlphabetScrollbarBloc>(context);
            },
          ),
        ),
      ),
    );

    await unmountScope(tester);

    await tester.pumpWidget(
      wrapScopeTest(
        home: RecitersScreenScope(
          child: ScopeProbe(
            onBuilt: (context) {
              second = readScopeBloc<AlphabetScrollbarBloc>(context);
            },
          ),
        ),
      ),
    );

    expect(first, isNotNull);
    expect(second, isNotNull);
    expect(first, isNot(same(second)));
  });

  testWidgets('closes scoped blocs when unmounted', (tester) async {
    RecitersBloc? recitersBloc;
    AlphabetScrollbarBloc? alphabetBloc;

    await expectScopeClosesBlocs(
      tester,
      scopeWithProbe: RecitersScreenScope(
        child: ScopeProbe(
          onBuilt: (context) {
            recitersBloc = readScopeBloc<RecitersBloc>(context);
            alphabetBloc = readScopeBloc<AlphabetScrollbarBloc>(context);
          },
        ),
      ),
      isClosed: () =>
          recitersBloc!.isClosed && alphabetBloc!.isClosed,
    );
  });

  testWidgets('renders probe child instead of RecitersScreen', (tester) async {
    await tester.pumpWidget(
      wrapScopeTest(
        home: RecitersScreenScope(
          child: ScopeProbe(onBuilt: (_) {}),
        ),
      ),
    );

    expect(find.byKey(const Key('scope_probe')), findsOneWidget);
    expect(find.byType(RecitersScreen), findsNothing);
  });
}
