import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciters_bloc.dart';
import 'package:tilawa/features/reciters/presentation/cubit/favorites_cubit.dart';
import 'package:tilawa/features/reciters/presentation/cubit/favorites_state.dart';
import 'package:tilawa/features/reciters/presentation/reciter_semantics_ids.dart';
import 'package:tilawa/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../support/reciters_screen_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(registerRecitersScreenTestFallbacks);

  group('RecitersScreen catalog chrome', () {
    late RecitersBloc recitersBloc;
    late FavoritesCubit favoritesCubit;

    setUp(() async {
      favoritesCubit = seededFavoritesCubit();
      await configureRecitersScreenTestGetIt(favoritesCubit: favoritesCubit);
      recitersBloc = loadedRecitersBloc();
    });

    tearDown(() async {
      if (!favoritesCubit.isClosed) {
        await favoritesCubit.close();
      }
      await recitersBloc.close();
      await GetIt.instance.reset();
    });

    testWidgets('uses NestedScrollView catalog chrome without tabs', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildRecitersScreenTestApp(
          recitersBloc: recitersBloc,
          favoritesCubit: favoritesCubit,
        ),
      );
      await pumpRecitersScreen(tester);

      expect(find.byType(NestedScrollView), findsOneWidget);
      expect(find.byType(TabBarView), findsNothing);
      expect(find.text('Search reciters...'), findsOneWidget);
      expect(
        find.bySemanticsIdentifier(ReciterSemanticsIds.recitersFavoritesToggle),
        findsNothing,
      );
      expect(
        find.bySemanticsIdentifier(ReciterSemanticsIds.recitersViewFavorites),
        findsOneWidget,
      );
      expect(
        find.bySemanticsIdentifier(ReciterSemanticsIds.recitersViewDownloads),
        findsNothing,
      );
      expect(
        find.bySemanticsIdentifier(ReciterSemanticsIds.recitersSearchLauncher),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows alphabet rail when settings enable it', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildRecitersScreenTestApp(
          recitersBloc: recitersBloc,
          favoritesCubit: favoritesCubit,
          settingsState: const SettingsState(showRecitersAlphabetIndex: true),
        ),
      );
      await pumpRecitersScreen(tester);

      expect(
        find.bySemanticsIdentifier(
          ReciterSemanticsIds.recitersAlphabetScrollbar,
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('hides alphabet rail when settings disable it', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildRecitersScreenTestApp(
          recitersBloc: recitersBloc,
          favoritesCubit: favoritesCubit,
          settingsState: const SettingsState(showRecitersAlphabetIndex: false),
        ),
      );
      await pumpRecitersScreen(tester);

      expect(
        find.bySemanticsIdentifier(
          ReciterSemanticsIds.recitersAlphabetScrollbar,
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'startup from splash cache bubbles favorites without LoadReciters',
      (tester) async {
        await favoritesCubit.close();
        favoritesCubit = seededFavoritesCubit(
          favoriteIds: const {3},
          favorites: [kRecitersTestReciters[2]],
        );
        await configureRecitersScreenTestGetIt(
          favoritesCubit: favoritesCubit,
        );
        recitersBloc = loadedRecitersBloc(
          favoriteIds: const {},
          filteredReciters: kRecitersTestReciters,
        );

        await tester.pumpWidget(
          buildRecitersScreenTestApp(
            recitersBloc: recitersBloc,
            favoritesCubit: favoritesCubit,
          ),
        );
        await pumpRecitersScreen(tester);

        final RecitersLoaded loaded = recitersBloc.state as RecitersLoaded;
        expect(
          loaded.filteredReciters.map((ReciterEntity r) => r.id).toList(),
          [3, 1, 2],
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('tablet catalog uses a two-column reciter grid', (
      WidgetTester tester,
    ) async {
      final Size previousPhysicalSize = tester.view.physicalSize;
      final double previousDevicePixelRatio = tester.view.devicePixelRatio;
      addTearDown(() {
        tester.view.physicalSize = previousPhysicalSize;
        tester.view.devicePixelRatio = previousDevicePixelRatio;
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);

      await tester.pumpWidget(
        buildRecitersScreenTestApp(
          recitersBloc: recitersBloc,
          favoritesCubit: favoritesCubit,
        ),
      );
      await pumpRecitersScreen(tester);

      final Finder gridFinder = find.byType(SliverGrid);
      expect(gridFinder, findsOneWidget);
      final SliverGrid grid = tester.widget<SliverGrid>(gridFinder);
      expect(
        grid.gridDelegate,
        isA<SliverGridDelegateWithFixedCrossAxisCount>(),
      );
      expect(
        (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
            .crossAxisCount,
        2,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('tablet alphabet rail uses tokenized bottom gap only', (
      WidgetTester tester,
    ) async {
      final Size previousPhysicalSize = tester.view.physicalSize;
      final double previousDevicePixelRatio = tester.view.devicePixelRatio;
      addTearDown(() {
        tester.view.physicalSize = previousPhysicalSize;
        tester.view.devicePixelRatio = previousDevicePixelRatio;
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);

      await tester.pumpWidget(
        TilawaShellPadding(
          padding: 88,
          child: buildRecitersScreenTestApp(
            recitersBloc: recitersBloc,
            favoritesCubit: favoritesCubit,
            settingsState: const SettingsState(
              showRecitersAlphabetIndex: true,
            ),
          ),
        ),
      );
      await pumpRecitersScreen(tester);

      final ThemeData theme = Theme.of(
        tester.element(find.byKey(const ValueKey('alphabet_scrollbar'))),
      );
      final Finder positionedFinder = find.ancestor(
        of: find.byKey(const ValueKey('alphabet_scrollbar')),
        matching: find.byType(Positioned),
      );
      expect(positionedFinder, findsOneWidget);
      expect(
        tester.widget<Positioned>(positionedFinder).bottom,
        theme.tokens.spaceSmall,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('phone catalog uses a single-column list', (
      WidgetTester tester,
    ) async {
      final Size previousPhysicalSize = tester.view.physicalSize;
      final double previousDevicePixelRatio = tester.view.devicePixelRatio;
      addTearDown(() {
        tester.view.physicalSize = previousPhysicalSize;
        tester.view.devicePixelRatio = previousDevicePixelRatio;
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);

      await tester.pumpWidget(
        buildRecitersScreenTestApp(
          recitersBloc: recitersBloc,
          favoritesCubit: favoritesCubit,
        ),
      );
      await pumpRecitersScreen(tester);

      expect(find.byType(SliverGrid), findsNothing);
      expect(find.byType(SliverList), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    

    testWidgets('letter filter shows dismissible chip that clears filter', (
      tester,
    ) async {
      await recitersBloc.close();
      recitersBloc = loadedRecitersBloc(
        selectedLetter: 'A',
        filteredReciters: [kRecitersTestReciters.first],
      );

      await tester.pumpWidget(
        buildRecitersScreenTestApp(
          recitersBloc: recitersBloc,
          favoritesCubit: favoritesCubit,
        ),
      );
      await pumpRecitersScreen(tester);

      expect(
        find.bySemanticsIdentifier(ReciterSemanticsIds.recitersLetterFilterChip),
        findsOneWidget,
      );
      expect(find.textContaining('Starts with'), findsOneWidget);

      await tester.tap(
        find.bySemanticsIdentifier(ReciterSemanticsIds.recitersLetterFilterChip),
      );
      await tester.pumpAndSettle();

      expect(
        recitersBloc.state,
        isA<RecitersLoaded>().having(
          (RecitersLoaded s) => s.selectedLetter,
          'selectedLetter',
          isNull,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('startup sync orders favorites before non-favorites', (
      tester,
    ) async {
      final RecitersBloc unorderedBloc = loadedRecitersBloc(
        favoriteIds: const {},
        filteredReciters: kRecitersTestReciters,
      );
      addTearDown(unorderedBloc.close);
      final FavoritesCubit favorites = seededFavoritesCubit(
        favoriteIds: const {1, 2},
      );
      await configureRecitersScreenTestGetIt(favoritesCubit: favorites);

      await tester.pumpWidget(
        buildRecitersScreenTestApp(
          recitersBloc: unorderedBloc,
          favoritesCubit: favorites,
        ),
      );
      await pumpRecitersScreen(tester);
      await tester.pumpAndSettle();

      final RecitersLoaded loaded = unorderedBloc.state as RecitersLoaded;
      expect(loaded.favoriteIds, {1, 2});
      expect(
        loaded.filteredReciters.map((ReciterEntity r) => r.id).toList(),
        [1, 2, 3],
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('adding a favorite syncs ids to RecitersBloc', (tester) async {
      final RecitersBloc recitersBloc = loadedRecitersBloc(
        favoriteIds: const {1},
        filteredReciters: kRecitersTestReciters,
      );
      addTearDown(recitersBloc.close);
      final FavoritesCubit favoritesCubit = seededFavoritesCubit(
        favoriteIds: const {1},
        favorites: <ReciterEntity>[kRecitersTestReciters[0]],
      );
      await configureRecitersScreenTestGetIt(favoritesCubit: favoritesCubit);

      await tester.pumpWidget(
        buildRecitersScreenTestApp(
          recitersBloc: recitersBloc,
          favoritesCubit: favoritesCubit,
        ),
      );
      await pumpRecitersScreen(tester);
      await tester.pumpAndSettle();

      await tester.tap(
        find.bySemanticsIdentifier(
          ReciterSemanticsIds.reciterFavoriteButton(3),
        ),
      );
      await tester.pumpAndSettle();

      final RecitersLoaded loaded = recitersBloc.state as RecitersLoaded;
      expect(loaded.favoriteIds, {1, 3});
      expect(
        (favoritesCubit.state as FavoritesLoaded).favoriteIds,
        {1, 3},
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('pull-to-refresh places favorites first', (tester) async {
      final MockGetRecitersUseCase mockGetReciters = MockGetRecitersUseCase();
      when(mockGetReciters.call).thenAnswer(
        (_) async => const Right<Failure, List<ReciterEntity>>(
          kRecitersTestReciters,
        ),
      );

      final RecitersBloc refreshBloc = RecitersBloc(mockGetReciters);
      addTearDown(refreshBloc.close);
      refreshBloc.emit(
        const RecitersLoaded(
          reciters: kRecitersTestReciters,
          filteredReciters: kRecitersTestReciters,
          favoriteIds: {1, 2},
        ),
      );

      final FavoritesCubit favoritesCubit = seededFavoritesCubit(
        favoriteIds: const {1, 2},
      );
      await configureRecitersScreenTestGetIt(favoritesCubit: favoritesCubit);

      await tester.pumpWidget(
        buildRecitersScreenTestApp(
          recitersBloc: refreshBloc,
          favoritesCubit: favoritesCubit,
        ),
      );
      await pumpRecitersScreen(tester);
      await tester.pumpAndSettle();

      refreshBloc.emit(
        const RecitersLoaded(
          reciters: kRecitersTestReciters,
          filteredReciters: kRecitersTestReciters,
          favoriteIds: {1, 2},
        ),
      );
      await tester.pump();

      await tester.fling(
        find.byType(CustomScrollView).first,
        const Offset(0, 300),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      final RecitersLoaded loaded = refreshBloc.state as RecitersLoaded;
      expect(loaded.favoriteIds, {1, 2});
      expect(
        loaded.filteredReciters.map((ReciterEntity r) => r.id).toList(),
        [1, 2, 3],
      );
      expect(tester.takeException(), isNull);
    });
  });
}
