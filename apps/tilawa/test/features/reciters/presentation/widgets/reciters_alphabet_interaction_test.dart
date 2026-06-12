import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/reciters/presentation/cubit/favorites_cubit.dart';
import 'package:tilawa/features/reciters/domain/usecases/get_reciters_use_case.dart';
import 'package:tilawa/features/reciters/presentation/bloc/alphabet_scrollbar/alphabet_scrollbar_bloc.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciters_bloc.dart';
import 'package:tilawa/features/reciters/presentation/reciter_semantics_ids.dart';
import 'package:tilawa/features/reciters/presentation/screens/reciters_screen.dart';
import 'package:tilawa/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../support/reciters_screen_test_support.dart';

List<ReciterEntity> _recitersForLetters(Iterable<String> letters) {
  var id = 1;
  return letters
      .map(
        (letter) => ReciterEntity(
          id: id++,
          name: 'Reciter $letter',
          letter: letter,
          date: '',
          moshaf: const [],
        ),
      )
      .toList();
}

Finder _refreshProgressIndicator() {
  return find.byWidgetPredicate(
    (widget) =>
        widget is CircularProgressIndicator ||
        widget.runtimeType.toString() == 'RefreshProgressIndicator',
  );
}

Finder _allTabCustomScrollView() {
  return find.byKey(const PageStorageKey<String>('reciters_all_tab'));
}

Future<void> _scrubLetter(
  WidgetTester tester, {
  required String letter,
  Offset dragDelta = const Offset(0, 48),
}) async {
  final Finder letterFinder = find.descendant(
    of: find.bySemanticsIdentifier(
      ReciterSemanticsIds.recitersAlphabetScrollbar,
    ),
    matching: find.text(letter),
  );
  expect(letterFinder, findsOneWidget);

  final gesture = await tester.startGesture(tester.getCenter(letterFinder));
  await tester.pump();
  await gesture.moveBy(dragDelta);
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(registerRecitersScreenTestFallbacks);

  group('Reciters alphabet interaction', () {
    late RecitersBloc recitersBloc;
    late FavoritesCubit favoritesCubit;

    setUp(() async {
      favoritesCubit = seededFavoritesCubit();
      await configureRecitersScreenTestGetIt(favoritesCubit: favoritesCubit);
      recitersBloc = loadedRecitersBloc(
        reciters: _recitersForLetters(['A', 'B', 'C', 'D', 'E']),
      );
    });

    tearDown(() async {
      if (!favoritesCubit.isClosed) {
        await favoritesCubit.close();
      }
      await recitersBloc.close();
      await GetIt.instance.reset();
    });

    Future<void> pumpAlphabetScreen(WidgetTester tester) async {
      await tester.pumpWidget(
        buildRecitersScreenTestApp(
          recitersBloc: recitersBloc,
          favoritesCubit: favoritesCubit,
          settingsState: const SettingsState(showRecitersAlphabetIndex: true),
        ),
      );
      await pumpRecitersScreen(tester);
    }

    testWidgets('alphabet scrub does not show pull-to-refresh indicator', (
      tester,
    ) async {
      await pumpAlphabetScreen(tester);

      final gesture = await tester.startGesture(
        tester.getCenter(
          find.descendant(
            of: find.bySemanticsIdentifier(
              ReciterSemanticsIds.recitersAlphabetScrollbar,
            ),
            matching: find.text('A'),
          ),
        ),
      );
      await tester.pump();
      await gesture.moveBy(const Offset(0, 120));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(_refreshProgressIndicator(), findsNothing);
      expect(tester.takeException(), isNull);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('alphabet scrub locks list scroll physics', (tester) async {
      await pumpAlphabetScreen(tester);

      await _scrubLetter(tester, letter: 'A');

      final CustomScrollView scrollView = tester.widget(
        _allTabCustomScrollView(),
      );
      expect(scrollView.physics, isA<NeverScrollableScrollPhysics>());
      expect(
        tester.widget<NestedScrollView>(find.byType(NestedScrollView)).physics,
        isA<NeverScrollableScrollPhysics>(),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('alphabet scrub restores scroll physics after release', (
      tester,
    ) async {
      await pumpAlphabetScreen(tester);

      final gesture = await tester.startGesture(
        tester.getCenter(
          find.descendant(
            of: find.bySemanticsIdentifier(
              ReciterSemanticsIds.recitersAlphabetScrollbar,
            ),
            matching: find.text('A'),
          ),
        ),
      );
      await tester.pump();
      await gesture.moveBy(const Offset(0, 48));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      final CustomScrollView scrollView = tester.widget(
        _allTabCustomScrollView(),
      );
      expect(scrollView.physics, isA<AlwaysScrollableScrollPhysics>());
      expect(
        tester.widget<NestedScrollView>(find.byType(NestedScrollView)).physics,
        isNull,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('alphabet scrub updates letter filter without tap', (
      tester,
    ) async {
      await pumpAlphabetScreen(tester);

      expect(
        (recitersBloc.state as RecitersLoaded).selectedLetter,
        isNull,
      );

      final gesture = await tester.startGesture(
        tester.getCenter(
          find.descendant(
            of: find.bySemanticsIdentifier(
              ReciterSemanticsIds.recitersAlphabetScrollbar,
            ),
            matching: find.text('A'),
          ),
        ),
      );
      await tester.pump();
      await gesture.moveBy(const Offset(0, 64));
      await tester.pump();
      await tester.runAsync(() async {
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pump();

      expect(
        (recitersBloc.state as RecitersLoaded).selectedLetter,
        isNotNull,
      );

      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('scrubbing across letters updates filter to last letter', (
      tester,
    ) async {
      recitersBloc = loadedRecitersBloc(
        reciters: _recitersForLetters(['A', 'B', 'C', 'D', 'E']),
      );

      await pumpAlphabetScreen(tester);

      final gesture = await tester.startGesture(
        tester.getCenter(
          find.descendant(
            of: find.bySemanticsIdentifier(
              ReciterSemanticsIds.recitersAlphabetScrollbar,
            ),
            matching: find.text('A'),
          ),
        ),
      );
      await tester.pump();
      await gesture.moveBy(const Offset(0, 120));
      await tester.pumpAndSettle();

      final selectedLetter =
          (recitersBloc.state as RecitersLoaded).selectedLetter;
      expect(selectedLetter, isNot('A'));
      expect(selectedLetter, isNotNull);
      expect(tester.takeException(), isNull);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('tap letter filters list and scrolls without scrub overlay', (
      tester,
    ) async {
      await pumpAlphabetScreen(tester);

      final gesture = await tester.startGesture(
        tester.getCenter(
          find.descendant(
            of: find.bySemanticsIdentifier(
              ReciterSemanticsIds.recitersAlphabetScrollbar,
            ),
            matching: find.text('B'),
          ),
        ),
      );
      await tester.pump();
      await gesture.up();
      await tester.runAsync(() async {
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pumpAndSettle();

      expect(
        (recitersBloc.state as RecitersLoaded).selectedLetter,
        'B',
      );
      expect(
        find.bySemanticsIdentifier(
          ReciterSemanticsIds.recitersAlphabetLetterSelected,
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('tap selected letter clears filter', (tester) async {
      recitersBloc = loadedRecitersBloc(
        reciters: _recitersForLetters(['A', 'B']),
        selectedLetter: 'A',
        filteredReciters: _recitersForLetters(['A']),
      );

      await pumpAlphabetScreen(tester);

      final gesture = await tester.startGesture(
        tester.getCenter(
          find.descendant(
            of: find.bySemanticsIdentifier(
              ReciterSemanticsIds.recitersAlphabetScrollbar,
            ),
            matching: find.text('A'),
          ),
        ),
      );
      await tester.pump();
      await gesture.up();
      await tester.runAsync(() async {
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pumpAndSettle();

      expect(
        (recitersBloc.state as RecitersLoaded).selectedLetter,
        isNull,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('pull-to-refresh still works when not scrubbing alphabet', (
      tester,
    ) async {
      await pumpAlphabetScreen(tester);

      await tester.drag(
        find.byType(RefreshIndicator),
        const Offset(0, 300),
        warnIfMissed: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });
  });

  group('ReciterAlphabetScrollbar scrub lifecycle', () {
    const reciters = <ReciterEntity>[
      ReciterEntity(id: 1, name: 'Alpha', letter: 'A', date: '', moshaf: []),
      ReciterEntity(id: 2, name: 'Beta', letter: 'B', date: '', moshaf: []),
      ReciterEntity(id: 3, name: 'Charlie', letter: 'C', date: '', moshaf: []),
    ];

    testWidgets('pan start sets isDragging and pan end clears it', (
      tester,
    ) async {
      final alphabetBloc = AlphabetScrollbarBloc();
      addTearDown(alphabetBloc.close);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [
              TilawaDesignTokens.light(),
              TilawaComponentTokens.light(),
            ],
          ),
          home: MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => RecitersBloc(_MockGetRecitersUseCase())
                  ..emit(
                    const RecitersLoaded(
                      reciters: reciters,
                      filteredReciters: reciters,
                    ),
                  ),
              ),
              BlocProvider<AlphabetScrollbarBloc>.value(value: alphabetBloc),
            ],
            child: ReciterAlphabetScrollbar(
              allReciters: reciters,
              onLetterSelected: (_) {},
              onScrubStart: () {
                alphabetBloc.add(const StartDragging());
              },
              onScrubEnd: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(alphabetBloc.state.isDragging, isFalse);

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('A')),
      );
      await tester.pump();

      expect(alphabetBloc.state.isDragging, isTrue);

      await gesture.moveBy(const Offset(0, 40));
      await tester.pump();
      expect(alphabetBloc.state.isDragging, isTrue);

      await gesture.up();
      await tester.pumpAndSettle();

      expect(alphabetBloc.state.isDragging, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('onScrubEnd fires once when scrub ends', (tester) async {
      var scrubEndCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [
              TilawaDesignTokens.light(),
              TilawaComponentTokens.light(),
            ],
          ),
          home: MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => RecitersBloc(_MockGetRecitersUseCase())
                  ..emit(
                    const RecitersLoaded(
                      reciters: reciters,
                      filteredReciters: reciters,
                    ),
                  ),
              ),
              BlocProvider(create: (_) => AlphabetScrollbarBloc()),
            ],
            child: ReciterAlphabetScrollbar(
              allReciters: reciters,
              onLetterSelected: (_) {},
              onScrubStart: () {},
              onScrubEnd: () => scrubEndCount++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('B')),
      );
      await tester.pump();
      await gesture.moveBy(const Offset(0, 40));
      await tester.pump();
      expect(scrubEndCount, 0);

      await gesture.up();
      await tester.pumpAndSettle();

      expect(scrubEndCount, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('hides when reciter list yields no letters', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [
              TilawaDesignTokens.light(),
              TilawaComponentTokens.light(),
            ],
          ),
          home: MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => RecitersBloc(_MockGetRecitersUseCase())
                  ..emit(
                    const RecitersLoaded(
                      reciters: <ReciterEntity>[],
                      filteredReciters: <ReciterEntity>[],
                    ),
                  ),
              ),
              BlocProvider(create: (_) => AlphabetScrollbarBloc()),
            ],
            child: const ReciterAlphabetScrollbar(
              allReciters: <ReciterEntity>[],
              onLetterSelected: _noopLetterSelected,
              onScrubStart: _noopScrubStart,
              onScrubEnd: _noopScrubEnd,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TilawaAlphabetScrollbar), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}

class _MockGetRecitersUseCase extends Mock implements GetRecitersUseCase {}

void _noopLetterSelected(String? _) {}

void _noopScrubStart() {}

void _noopScrubEnd() {}
