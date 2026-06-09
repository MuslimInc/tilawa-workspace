import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciters_bloc.dart';
import 'package:tilawa/features/reciters/presentation/cubit/favorites_cubit.dart';
import 'package:tilawa/features/reciters/presentation/reciter_semantics_ids.dart';
import 'package:tilawa/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';

import '../../../../support/reciters_screen_test_support.dart';

List<ReciterEntity> _alphabetCatalogReciters({int perLetter = 8}) {
  var id = 1;
  return 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
      .split('')
      .expand(
        (String letter) => List<ReciterEntity>.generate(
          perLetter,
          (int index) => ReciterEntity(
            id: id++,
            name: 'Reciter $letter$index',
            letter: letter,
            date: '',
            moshaf: const [],
          ),
        ),
      )
      .toList();
}

Finder _allTabCustomScrollView() {
  return find.byKey(const PageStorageKey<String>('reciters_all_tab'));
}

Finder _alphabetLetter(String letter) {
  return find.descendant(
    of: find.bySemanticsIdentifier(
      ReciterSemanticsIds.recitersAlphabetScrollbar,
    ),
    matching: find.text(letter),
  );
}

NestedScrollViewState _nestedScrollState(WidgetTester tester) {
  return tester.state<NestedScrollViewState>(find.byType(NestedScrollView));
}

ScrollPosition? _headerScrollPosition(WidgetTester tester) {
  final NestedScrollViewState nested = _nestedScrollState(tester);
  final ScrollController? primary = PrimaryScrollController.maybeOf(
    tester.element(find.byType(NestedScrollView)),
  );
  ScrollPosition? best;
  for (final ScrollController? controller in <ScrollController?>[
    nested.innerController,
    primary,
  ]) {
    if (controller == null || !controller.hasClients) {
      continue;
    }
    for (final ScrollPosition position in controller.positions) {
      if (!position.hasContentDimensions ||
          position.maxScrollExtent <= 0 ||
          position.maxScrollExtent > 500) {
        continue;
      }
      if (best == null ||
          position.pixels > best.pixels ||
          (position.pixels == best.pixels &&
              position.maxScrollExtent < best.maxScrollExtent)) {
        best = position;
      }
    }
  }
  return best;
}

ScrollPosition? _catalogScrollPosition(WidgetTester tester) {
  final ScrollController inner = _nestedScrollState(tester).innerController;
  if (!inner.hasClients) {
    return null;
  }
  ScrollPosition? largest;
  for (final ScrollPosition position in inner.positions) {
    if (!position.hasContentDimensions || position.maxScrollExtent <= 500) {
      continue;
    }
    if (largest == null || position.maxScrollExtent > largest.maxScrollExtent) {
      largest = position;
    }
  }
  return largest;
}

Future<void> _pumpAlphabetScreen(
  WidgetTester tester, {
  required RecitersBloc recitersBloc,
  required FavoritesCubit favoritesCubit,
}) async {
  await tester.pumpWidget(
    buildRecitersScreenTestApp(
      recitersBloc: recitersBloc,
      favoritesCubit: favoritesCubit,
      settingsState: const SettingsState(showRecitersAlphabetIndex: true),
    ),
  );
  await pumpRecitersScreen(tester);
}

Future<void> _flingCatalog(
  WidgetTester tester, {
  required Offset delta,
  double velocity = 2500,
}) async {
  await tester.fling(
    _allTabCustomScrollView(),
    delta,
    velocity,
    warnIfMissed: false,
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<TestGesture> _startAlphabetScrub(
  WidgetTester tester, {
  required String letter,
}) async {
  final gesture = await tester.startGesture(
    tester.getCenter(_alphabetLetter(letter)),
  );
  await tester.pump();
  return gesture;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(registerRecitersScreenTestFallbacks);

  group('Reciters alphabet scrub scroll coverage', () {
    late RecitersBloc recitersBloc;
    late FavoritesCubit favoritesCubit;

    setUp(() async {
      favoritesCubit = seededFavoritesCubit();
      await configureRecitersScreenTestGetIt(favoritesCubit: favoritesCubit);
      recitersBloc = loadedRecitersBloc(
        reciters: _alphabetCatalogReciters(),
      );
    });

    tearDown(() async {
      if (!favoritesCubit.isClosed) {
        await favoritesCubit.close();
      }
      await recitersBloc.close();
      await GetIt.instance.reset();
    });

    testWidgets('removes RefreshIndicator while scrubbing', (tester) async {
      await _pumpAlphabetScreen(
        tester,
        recitersBloc: recitersBloc,
        favoritesCubit: favoritesCubit,
      );

      expect(find.byType(RefreshIndicator), findsOneWidget);

      final gesture = await _startAlphabetScrub(tester, letter: 'A');
      await gesture.moveBy(const Offset(0, 48));
      await tester.pump();

      expect(find.byType(RefreshIndicator), findsNothing);

      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows catalog AbsorbPointer overlay while scrubbing', (
      tester,
    ) async {
      await _pumpAlphabetScreen(
        tester,
        recitersBloc: recitersBloc,
        favoritesCubit: favoritesCubit,
      );

      final Finder catalogAbsorbOverlay = find.byWidgetPredicate(
        (Widget widget) =>
            widget is AbsorbPointer &&
            widget.absorbing &&
            widget.child is SizedBox,
      );

      expect(catalogAbsorbOverlay, findsNothing);

      final gesture = await _startAlphabetScrub(tester, letter: 'A');
      await gesture.moveBy(const Offset(0, 48));
      await tester.pump();

      expect(catalogAbsorbOverlay, findsOneWidget);

      await gesture.up();
      await tester.pumpAndSettle();

      expect(catalogAbsorbOverlay, findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('preserves collapsed header while scrubbing across letters', (
      tester,
    ) async {
      await _pumpAlphabetScreen(
        tester,
        recitersBloc: recitersBloc,
        favoritesCubit: favoritesCubit,
      );

      await _flingCatalog(tester, delta: const Offset(0, -900));
      final ScrollPosition? headerBeforeScrub = _headerScrollPosition(tester);
      expect(headerBeforeScrub, isNotNull);
      final double pinnedHeader = headerBeforeScrub!.pixels;

      final gesture = await _startAlphabetScrub(tester, letter: 'A');
      for (var step = 0; step < 8; step++) {
        await gesture.moveBy(const Offset(0, 36));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 16));

        final double headerPixels =
            _headerScrollPosition(tester)?.pixels ?? pinnedHeader;
        expect(
          (headerPixels - pinnedHeader).abs(),
          lessThan(1.5),
          reason: 'header should stay pinned during scrub step $step',
        );
      }

      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'scrub release scrolls catalog to top and keeps collapsed header',
      (tester) async {
        await _pumpAlphabetScreen(
          tester,
          recitersBloc: recitersBloc,
          favoritesCubit: favoritesCubit,
        );

        await _flingCatalog(tester, delta: const Offset(0, -900));
        await _flingCatalog(tester, delta: const Offset(0, -600));

        final ScrollPosition? headerBefore = _headerScrollPosition(tester);
        expect(headerBefore, isNotNull);
        final double pinnedHeader = headerBefore!.pixels;

        final gesture = await _startAlphabetScrub(tester, letter: 'H');
        await gesture.moveBy(const Offset(0, 160));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        await gesture.up();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));

        final ScrollPosition? catalogAfter = _catalogScrollPosition(tester);
        final ScrollPosition? headerAfter = _headerScrollPosition(tester);

        expect(catalogAfter?.pixels ?? 0, closeTo(0, 1.5));
        expect(
          (headerAfter?.pixels ?? 0),
          closeTo(pinnedHeader, 1.5),
          reason: 'header collapse should survive scrub release',
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('pins catalog offset when filter changes during scrub', (
      tester,
    ) async {
      await _pumpAlphabetScreen(
        tester,
        recitersBloc: recitersBloc,
        favoritesCubit: favoritesCubit,
      );

      await _flingCatalog(tester, delta: const Offset(0, -1200));
      final ScrollPosition? catalogBeforeScrub = _catalogScrollPosition(tester);
      expect(catalogBeforeScrub, isNotNull);
      final double pinnedCatalog = catalogBeforeScrub!.pixels;

      final gesture = await _startAlphabetScrub(tester, letter: 'A');
      await gesture.moveBy(const Offset(0, 200));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      final double catalogDuringScrub =
          _catalogScrollPosition(tester)?.pixels ?? pinnedCatalog;
      expect(
        (catalogDuringScrub - pinnedCatalog).abs(),
        lessThan(2.0),
        reason: 'catalog should stay pinned while letters change during scrub',
      );

      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'expanded header stays at top when filter changes during scrub',
      (
        tester,
      ) async {
        await _pumpAlphabetScreen(
          tester,
          recitersBloc: recitersBloc,
          favoritesCubit: favoritesCubit,
        );

        final ScrollPosition? headerAtTop = _headerScrollPosition(tester);
        expect(headerAtTop?.pixels ?? 0, closeTo(0, 1.0));

        final gesture = await _startAlphabetScrub(tester, letter: 'A');
        await gesture.moveBy(const Offset(0, 220));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 50));

        final double headerDuringScrub =
            _headerScrollPosition(tester)?.pixels ?? 0;
        expect(
          headerDuringScrub,
          closeTo(0, 1.5),
          reason: 'expanded header must not collapse when letters change',
        );

        await gesture.up();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('records header metrics before scrub for collapsed restore', (
      tester,
    ) async {
      await _pumpAlphabetScreen(
        tester,
        recitersBloc: recitersBloc,
        favoritesCubit: favoritesCubit,
      );

      await _flingCatalog(tester, delta: const Offset(0, -900));
      final double collapsedHeader = _headerScrollPosition(tester)?.pixels ?? 0;
      expect(collapsedHeader, greaterThan(8));

      final gesture = await _startAlphabetScrub(tester, letter: 'K');
      await gesture.moveBy(const Offset(0, 48));
      await tester.pump();

      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        _headerScrollPosition(tester)?.pixels ?? 0,
        closeTo(collapsedHeader, 1.5),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('tap letter selects filter when not scrubbing', (tester) async {
      await _pumpAlphabetScreen(
        tester,
        recitersBloc: recitersBloc,
        favoritesCubit: favoritesCubit,
      );

      final gesture = await _startAlphabetScrub(tester, letter: 'C');
      await tester.pump();
      await gesture.up();
      await tester.runAsync(() async {
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pumpAndSettle();

      expect(
        (recitersBloc.state as RecitersLoaded).selectedLetter,
        'C',
      );
      expect(tester.takeException(), isNull);
    });
  });
}
