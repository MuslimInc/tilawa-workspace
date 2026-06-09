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
    ReciterEntity(id: 3, name: 'Gamma', letter: 'C', date: '', moshaf: []),
  ];

  testWidgets(
    'alphabet scrub does not reset NestedScrollView offset mid-drag',
    (tester) async {
      final alphabetBloc = AlphabetScrollbarBloc();
      addTearDown(alphabetBloc.close);

      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      final recitersBloc = RecitersBloc(_MockGetRecitersUseCase())
        ..emit(
          const RecitersLoaded(
            reciters: reciters,
            filteredReciters: reciters,
          ),
        );
      addTearDown(recitersBloc.close);

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
              BlocProvider<RecitersBloc>.value(value: recitersBloc),
              BlocProvider<AlphabetScrollbarBloc>.value(value: alphabetBloc),
            ],
            child: PrimaryScrollController(
              controller: scrollController,
              child: BlocBuilder<AlphabetScrollbarBloc, AlphabetScrollbarState>(
                buildWhen: (previous, current) =>
                    previous.isDragging != current.isDragging,
                builder: (context, alphabetState) {
                  return NestedScrollView(
                    physics: alphabetState.isDragging
                        ? const NeverScrollableScrollPhysics()
                        : null,
                    headerSliverBuilder: (context, innerBoxIsScrolled) {
                      return [
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 200, child: Text('Header')),
                        ),
                      ];
                    },
                    body: Stack(
                      children: [
                        CustomScrollView(
                          physics: alphabetState.isDragging
                              ? const NeverScrollableScrollPhysics()
                              : null,
                          slivers: [
                            SliverList.builder(
                              itemCount: 50,
                              itemBuilder: (context, index) {
                                return SizedBox(
                                  height: 48,
                                  child: Text('Row $index'),
                                );
                              },
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ReciterAlphabetScrollbar(
                            allReciters: reciters,
                            onLetterSelected: (_) {},
                            onScrubStart: () {
                              alphabetBloc.add(const StartDragging());
                            },
                            onScrubEnd: () {
                              if (scrollController.hasClients) {
                                scrollController.jumpTo(0);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      scrollController.jumpTo(120);
      await tester.pump();
      expect(scrollController.offset, 120);

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('A')),
      );
      await tester.pump();
      await gesture.moveBy(const Offset(0, 40));
      await tester.pump();

      expect(
        scrollController.offset,
        120,
        reason: 'scrubbing letters should not scroll header to top',
      );

      await gesture.up();
      await tester.pumpAndSettle();

      expect(
        scrollController.offset,
        0,
        reason: 'scrub end should scroll nested view to top',
      );
    },
  );

  testWidgets(
    'alphabet scrub keeps isDragging true until pointer up',
    (tester) async {
      final alphabetBloc = AlphabetScrollbarBloc();
      addTearDown(alphabetBloc.close);

      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      final recitersBloc = RecitersBloc(_MockGetRecitersUseCase())
        ..emit(
          const RecitersLoaded(
            reciters: reciters,
            filteredReciters: reciters,
          ),
        );
      addTearDown(recitersBloc.close);

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
              BlocProvider<RecitersBloc>.value(value: recitersBloc),
              BlocProvider<AlphabetScrollbarBloc>.value(value: alphabetBloc),
            ],
            child: PrimaryScrollController(
              controller: scrollController,
              child: ReciterAlphabetScrollbar(
                allReciters: reciters,
                onLetterSelected: (_) {},
                onScrubStart: () {
                  alphabetBloc.add(const StartDragging());
                },
                onScrubEnd: () {
                  if (scrollController.hasClients) {
                    scrollController.jumpTo(0);
                  }
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

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
    },
  );
}
