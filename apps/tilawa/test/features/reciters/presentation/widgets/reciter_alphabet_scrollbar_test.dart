import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/reciters/domain/usecases/get_reciters_use_case.dart';
import 'package:tilawa/features/reciters/presentation/bloc/alphabet_scrollbar/alphabet_scrollbar_bloc.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciters_bloc.dart';
import 'package:tilawa/features/reciters/presentation/screens/reciters_screen.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class _MockGetRecitersUseCase extends Mock implements GetRecitersUseCase {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const reciters = <ReciterEntity>[
    ReciterEntity(id: 1, name: 'Alpha', letter: 'A', date: '', moshaf: []),
    ReciterEntity(id: 2, name: 'Beta', letter: 'B', date: '', moshaf: []),
  ];

  late RecitersBloc recitersBloc;
  late _MockGetRecitersUseCase mockGetReciters;

  setUp(() {
    mockGetReciters = _MockGetRecitersUseCase();
    recitersBloc = RecitersBloc(mockGetReciters)
      ..emit(
        const RecitersLoaded(
          reciters: reciters,
          filteredReciters: reciters,
          selectedLetter: 'A',
        ),
      );
  });

  tearDown(() async {
    await recitersBloc.close();
  });

  Widget buildScrollbar({
    required ValueChanged<String?> onLetterSelected,
    VoidCallback? onScrubStart,
    VoidCallback? onScrubEnd,
  }) {
    return ReciterAlphabetScrollbar(
      allReciters: reciters,
      onLetterSelected: onLetterSelected,
      onScrubStart: onScrubStart ?? () {},
      onScrubEnd: onScrubEnd ?? () {},
    );
  }

  Widget wrap({
    required Widget child,
  }) {
    return MaterialApp(
      theme: ThemeData(
        extensions: [
          MeMuslimDesignTokens.light(),
          MeMuslimComponentTokens.light(),
        ],
      ),
      home: Scaffold(
        body: MultiBlocProvider(
          providers: [
            BlocProvider<RecitersBloc>.value(value: recitersBloc),
            BlocProvider(create: (_) => AlphabetScrollbarBloc()),
          ],
          child: child,
        ),
      ),
    );
  }

  Finder circleFor(String letter) => find.ancestor(
    of: find.text(letter),
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration! as BoxDecoration).shape == BoxShape.circle,
    ),
  );

  group('ReciterAlphabetScrollbar', () {
    testWidgets('highlights letter from RecitersBloc selectedLetter', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          child: buildScrollbar(onLetterSelected: (_) {}),
        ),
      );
      await tester.pump();

      expect(circleFor('A'), findsOneWidget);
      expect(circleFor('B'), findsNothing);
    });

    testWidgets('tap selected letter clears RecitersBloc filter', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          child: buildScrollbar(
            onLetterSelected: (letter) {
              if (letter == null) {
                recitersBloc.add(const ClearLetterFilter());
              }
            },
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('A'));
      await tester.runAsync(() async {
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pump();

      final state = recitersBloc.state as RecitersLoaded;
      expect(state.selectedLetter, isNull);
      expect(circleFor('A'), findsNothing);
    });

    testWidgets('tap different letter updates RecitersBloc filter', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          child: buildScrollbar(
            onLetterSelected: (letter) {
              if (letter != null) {
                recitersBloc.add(FilterByLetter(letter));
              }
            },
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('B'));
      await tester.runAsync(() async {
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pump();

      final state = recitersBloc.state as RecitersLoaded;
      expect(state.selectedLetter, 'B');
      expect(circleFor('B'), findsOneWidget);
    });

    testWidgets('rebuilds scrollbar when selectedLetter changes externally', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          child: buildScrollbar(onLetterSelected: (_) {}),
        ),
      );
      await tester.pump();

      expect(circleFor('A'), findsOneWidget);

      recitersBloc.emit(
        (recitersBloc.state as RecitersLoaded).copyWith(
          clearSelectedLetter: true,
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(circleFor('A'), findsNothing);
    });
  });
}
