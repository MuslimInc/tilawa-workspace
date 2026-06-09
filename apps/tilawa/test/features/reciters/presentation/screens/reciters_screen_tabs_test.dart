import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/downloads/presentation/bloc/downloads_bloc.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciters_bloc.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciters_tabs_bloc.dart';
import 'package:tilawa/features/reciters/presentation/cubit/favorites_cubit.dart';
import 'package:tilawa/features/reciters/presentation/reciter_semantics_ids.dart';
import 'package:tilawa/features/reciters/presentation/widgets/reciters_favorites_tab.dart';
import 'package:tilawa/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../support/reciters_screen_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(registerRecitersScreenTestFallbacks);

  group('RecitersScreen tabs and sliver chrome', () {
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

    testWidgets('uses a shared NestedScrollView header with primary tabs', (
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
      expect(find.byType(TabBarView), findsOneWidget);
      expect(
        find.bySemanticsIdentifier(ReciterSemanticsIds.recitersTab),
        findsOneWidget,
      );
      expect(
        find.bySemanticsIdentifier(ReciterSemanticsIds.recitersFavoritesToggle),
        findsOneWidget,
      );
      expect(
        find.bySemanticsIdentifier(ReciterSemanticsIds.recitersViewDownloads),
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

    testWidgets('hides alphabet rail on favorites tab', (tester) async {
      await tester.pumpWidget(
        buildRecitersScreenTestApp(
          recitersBloc: recitersBloc,
          favoritesCubit: favoritesCubit,
          settingsState: const SettingsState(showRecitersAlphabetIndex: true),
        ),
      );
      await pumpRecitersScreen(tester);

      final Finder alphabetRail = find.bySemanticsIdentifier(
        ReciterSemanticsIds.recitersAlphabetScrollbar,
      );
      expect(tester.widgetList(alphabetRail.hitTestable()), isNotEmpty);

      await tester.tap(
        find.bySemanticsIdentifier(ReciterSemanticsIds.recitersFavoritesToggle),
      );
      await tester.pumpAndSettle();

      expect(tester.widgetList(alphabetRail.hitTestable()), isEmpty);
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

    Finder favoritesTabScrollView() {
      return find.descendant(
        of: find.byType(RecitersFavoritesTab),
        matching: find.byType(CustomScrollView),
      );
    }

    testWidgets(
      'favorites tab uses PrimaryScrollController inside NestedScrollView',
      (tester) async {
        await tester.pumpWidget(
          buildRecitersScreenTestApp(
            recitersBloc: recitersBloc,
            favoritesCubit: favoritesCubit,
          ),
        );
        await pumpRecitersScreen(tester);

        await tester.tap(
          find.bySemanticsIdentifier(
            ReciterSemanticsIds.recitersFavoritesToggle,
          ),
        );
        await tester.pumpAndSettle();

        final CustomScrollView scrollView = tester.widget(
          favoritesTabScrollView(),
        );
        expect(scrollView.controller, isNull);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('favorites tab scroll collapses shared catalog header', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildRecitersScreenTestApp(
          recitersBloc: recitersBloc,
          favoritesCubit: favoritesCubit,
        ),
      );
      await pumpRecitersScreen(tester);

      await tester.tap(
        find.bySemanticsIdentifier(ReciterSemanticsIds.recitersFavoritesToggle),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final Finder searchField = find.text('Search reciters...');
      expect(searchField, findsOneWidget);
      final double beforeScrollY = tester
          .renderObject<RenderBox>(searchField)
          .localToGlobal(Offset.zero)
          .dy;

      await tester.fling(
        find.descendant(
          of: find.byType(RecitersFavoritesTab),
          matching: find.byType(Scrollable),
        ),
        const Offset(0, -400),
        2500,
        warnIfMissed: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      if (searchField.evaluate().isEmpty) {
        expect(beforeScrollY, greaterThan(0));
      } else {
        final double afterScrollY = tester
            .renderObject<RenderBox>(searchField)
            .localToGlobal(Offset.zero)
            .dy;
        expect(afterScrollY, lessThan(beforeScrollY));
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('favorites tab shows empty state when there are no favorites', (
      tester,
    ) async {
      await favoritesCubit.close();
      favoritesCubit = seededFavoritesCubit(
        favoriteIds: const {},
        favorites: const [],
      );
      await configureRecitersScreenTestGetIt(
        favoritesCubit: favoritesCubit,
      );

      await tester.pumpWidget(
        buildRecitersScreenTestApp(
          recitersBloc: recitersBloc,
          favoritesCubit: favoritesCubit,
        ),
      );
      await pumpRecitersScreen(tester);

      await tester.tap(
        find.bySemanticsIdentifier(ReciterSemanticsIds.recitersFavoritesToggle),
      );
      await tester.pumpAndSettle();

      expect(find.text('No favorites'), findsOneWidget);
      expect(
        find.text('Tap the heart to keep the reciters you love within reach.'),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(TilawaIllustratedState),
          matching: find.byType(TilawaButton),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('favorites tab removes a reciter from the list', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildRecitersScreenTestApp(
          recitersBloc: recitersBloc,
          favoritesCubit: favoritesCubit,
        ),
      );
      await pumpRecitersScreen(tester);

      await tester.tap(
        find.bySemanticsIdentifier(ReciterSemanticsIds.recitersFavoritesToggle),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alpha Reciter'), findsOneWidget);

      await tester.tap(
        find.bySemanticsIdentifier(
          ReciterSemanticsIds.reciterFavoriteButton(
            kRecitersTestReciters[0].id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alpha Reciter'), findsNothing);
      expect(find.text('Beta Reciter'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('favorites tab shows all favorites from FavoritesCubit', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildRecitersScreenTestApp(
          recitersBloc: loadedRecitersBloc(
            selectedLetter: 'A',
            filteredReciters: [kRecitersTestReciters[0]],
          ),
          favoritesCubit: favoritesCubit,
        ),
      );
      await pumpRecitersScreen(tester);

      await tester.tap(
        find.bySemanticsIdentifier(ReciterSemanticsIds.recitersFavoritesToggle),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alpha Reciter'), findsOneWidget);
      expect(find.text('Beta Reciter'), findsOneWidget);
      expect(find.text('Gamma Reciter'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('swipe syncs bloc when TabBarView scroll becomes idle', (
      tester,
    ) async {
      final RecitersTabsBloc tabsBloc = RecitersTabsBloc();

      await tester.pumpWidget(
        buildRecitersScreenTestApp(
          recitersBloc: recitersBloc,
          favoritesCubit: favoritesCubit,
          tabsBloc: tabsBloc,
        ),
      );
      await pumpRecitersScreen(tester);

      expect(tabsBloc.state.selectedTab, RecitersHomeTab.all);

      final Size tabViewSize = tester.getSize(find.byType(TabBarView));
      await tester.drag(
        find.byType(TabBarView),
        Offset(-tabViewSize.width * 0.55, 0),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(tabsBloc.state.selectedTab, RecitersHomeTab.favorites);
      expect(find.text('Alpha Reciter'), findsOneWidget);
      expect(find.text('Beta Reciter'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty downloads tab offers browse reciters action', (
      tester,
    ) async {
      final MockDownloadsBloc mockDownloadsBloc =
          GetIt.instance<DownloadsBloc>() as MockDownloadsBloc;
      when(() => mockDownloadsBloc.state).thenReturn(
        const DownloadsState(
          status: DownloadsStateStatus.loaded,
          downloads: {},
        ),
      );

      await tester.pumpWidget(
        buildRecitersScreenTestApp(
          recitersBloc: recitersBloc,
          favoritesCubit: favoritesCubit,
        ),
      );
      await pumpRecitersScreen(tester);

      await tester.tap(
        find.bySemanticsIdentifier(ReciterSemanticsIds.recitersViewDownloads),
      );
      await tester.pumpAndSettle();

      expect(find.text('No downloads yet'), findsOneWidget);

      final Finder browseRecitersButton = find.descendant(
        of: find.byType(TilawaIllustratedState),
        matching: find.widgetWithText(TilawaButton, 'Reciters'),
      );
      expect(browseRecitersButton, findsOneWidget);

      await tester.tap(browseRecitersButton);
      await tester.pumpAndSettle();

      expect(find.text('Alpha Reciter'), findsOneWidget);
      expect(find.text('No downloads yet'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'selecting favorites tab keeps RecitersBloc favorites filter off',
      (tester) async {
        await tester.pumpWidget(
          buildRecitersScreenTestApp(
            recitersBloc: recitersBloc,
            favoritesCubit: favoritesCubit,
          ),
        );
        await pumpRecitersScreen(tester);

        expect(
          (recitersBloc.state as RecitersLoaded).showFavoritesOnly,
          isFalse,
        );

        await tester.tap(
          find.bySemanticsIdentifier(
            ReciterSemanticsIds.recitersFavoritesToggle,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          (recitersBloc.state as RecitersLoaded).showFavoritesOnly,
          isFalse,
        );
        expect(find.byType(RecitersFavoritesTab), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('rtl tab pill matches TabBarView content', (tester) async {
      final MockDownloadsBloc mockDownloadsBloc =
          GetIt.instance<DownloadsBloc>() as MockDownloadsBloc;
      when(() => mockDownloadsBloc.state).thenReturn(
        const DownloadsState(
          status: DownloadsStateStatus.loaded,
          downloads: {},
        ),
      );

      await tester.pumpWidget(
        buildRecitersScreenTestApp(
          recitersBloc: recitersBloc,
          favoritesCubit: favoritesCubit,
          locale: const Locale('ar'),
        ),
      );
      await pumpRecitersScreen(tester);

      expect(find.text('Alpha Reciter'), findsOneWidget);
      expect(find.text('لا توجد تحميلات بعد'), findsNothing);

      await tester.tap(
        find.bySemanticsIdentifier(ReciterSemanticsIds.recitersViewDownloads),
      );
      await tester.pumpAndSettle();

      expect(find.text('لا توجد تحميلات بعد'), findsOneWidget);
      expect(find.text('Alpha Reciter'), findsNothing);

      await tester.tap(
        find.bySemanticsIdentifier(ReciterSemanticsIds.recitersTab),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alpha Reciter'), findsOneWidget);
      expect(find.text('لا توجد تحميلات بعد'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
