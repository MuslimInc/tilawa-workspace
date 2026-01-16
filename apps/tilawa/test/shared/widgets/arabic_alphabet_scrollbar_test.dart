import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa/features/reciters/presentation/bloc/alphabet_scrollbar/alphabet_scrollbar_bloc.dart';
import 'package:tilawa/shared/widgets/arabic_alphabet_scrollbar.dart';

class MockAlphabetScrollbarBloc
    extends MockBloc<AlphabetScrollbarEvent, AlphabetScrollbarState>
    implements AlphabetScrollbarBloc {}

class FakeAlphabetScrollbarEvent extends Fake
    implements AlphabetScrollbarEvent {}

void main() {
  late MockAlphabetScrollbarBloc mockBloc;
  late ScrollController scrollController;
  late List<String> selectedLetters;

  setUpAll(() {
    registerFallbackValue(FakeAlphabetScrollbarEvent());
  });

  setUp(() {
    mockBloc = MockAlphabetScrollbarBloc();
    scrollController = ScrollController();
    selectedLetters = [];

    when(() => mockBloc.state).thenReturn(const AlphabetScrollbarState());
  });

  tearDown(() {
    scrollController.dispose();
  });

  Widget createWidget({
    List<String> letters = const ['ا', 'ب', 'ت'],
    List<ReciterEntity>? reciters,
    AlphabetScrollbarState? state,
    List<ReciterEntity>? items,
  }) {
    if (state != null) {
      when(() => mockBloc.state).thenReturn(state);
    }

    final List<ReciterEntity> itemsList = items ?? const <ReciterEntity>[];

    return BlocProvider<AlphabetScrollbarBloc>.value(
      value: mockBloc,
      child: MaterialApp(
        home: Builder(
          builder: (context) {
            ScreenUtilPlus.init(
              context,
              designSize: const Size(375, 812),
              minTextAdapt: true,
            );
            return Scaffold(
              body: Row(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: 100,
                      itemBuilder: (context, index) =>
                          ListTile(title: Text('Item $index')),
                    ),
                  ),
                  if (reciters != null)
                    ReciterAlphabetScrollbar(
                      reciters: reciters,
                      scrollController: scrollController,
                      onLetterSelected: (letter) {
                        if (letter != null) {
                          selectedLetters.add(letter);
                        }
                      },
                    )
                  else
                    ArabicAlphabetScrollbar(
                      letters: letters,
                      scrollController: scrollController,
                      onLetterSelected: (letter) {
                        if (letter != null) {
                          selectedLetters.add(letter);
                        }
                      },
                      items: itemsList,
                      getItemLetter: (item) => item.letter,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  group('ArabicAlphabetScrollbar', () {
    testWidgets('renders all letters', (tester) async {
      await tester.pumpWidget(createWidget(letters: ['ا', 'ب', 'ت']));
      await tester.pumpAndSettle();

      expect(find.text('ا'), findsOneWidget);
      expect(find.text('ب'), findsOneWidget);
      expect(find.text('ت'), findsOneWidget);
    });

    testWidgets('tapping a letter dispatches SelectLetter event', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget(letters: ['ا', 'ب', 'ت']));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ب'));

      verify(() => mockBloc.add(const SelectLetter('ب'))).called(1);
    });

    testWidgets('selected letter is highlighted', (tester) async {
      await tester.pumpWidget(
        createWidget(
          letters: ['ا', 'ب', 'ت'],
          state: const AlphabetScrollbarState(selectedLetter: 'ب'),
        ),
      );
      await tester.pumpAndSettle();

      // The selected letter should have a different style (bold)
      final Text selectedText = tester.widget<Text>(find.text('ب'));
      expect(selectedText.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('tapping letter with matching items triggers scroll', (
      tester,
    ) async {
      final items = <ReciterEntity>[
        const ReciterEntity(
          id: 1,
          name: 'Ahmed',
          letter: 'ا',
          date: '2024-01-01',
          moshaf: [],
        ),
        const ReciterEntity(
          id: 2,
          name: 'بلال',
          letter: 'ب',
          date: '2024-01-01',
          moshaf: [],
        ),
      ];

      await tester.pumpWidget(
        createWidget(letters: ['ا', 'ب', 'ت'], items: items),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('ا'));
      await tester.pumpAndSettle();

      verify(() => mockBloc.add(const SelectLetter('ا'))).called(1);
      expect(selectedLetters, contains('ا'));
    });
  });

  group('ReciterAlphabetScrollbar', () {
    testWidgets('renders letters from reciters', (tester) async {
      final reciters = <ReciterEntity>[
        const ReciterEntity(
          id: 1,
          name: 'Ahmed',
          letter: 'A',
          date: '2024-01-01',
          moshaf: [],
        ),
        const ReciterEntity(
          id: 2,
          name: 'Bashir',
          letter: 'B',
          date: '2024-01-01',
          moshaf: [],
        ),
      ];

      await tester.pumpWidget(createWidget(reciters: reciters));
      await tester.pumpAndSettle();

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('hides scrollbar when no reciters', (tester) async {
      await tester.pumpWidget(createWidget(reciters: const []));
      await tester.pumpAndSettle();

      expect(find.byType(ArabicAlphabetScrollbar), findsNothing);
    });
  });
}
