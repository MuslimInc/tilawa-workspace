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
  return find.byKey(const PageStorageKey<String>('reciters_catalog'));
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

    testWidgets('scrubs across letters without throwing', (tester) async {
      await _pumpAlphabetScreen(
        tester,
        recitersBloc: recitersBloc,
        favoritesCubit: favoritesCubit,
      );

      await _flingCatalog(tester, delta: const Offset(0, -900));

      final gesture = await _startAlphabetScrub(tester, letter: 'A');
      for (var step = 0; step < 8; step++) {
        await gesture.moveBy(const Offset(0, 36));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 16));
      }

      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });

    testWidgets('scrub release scrolls catalog to top', (tester) async {
      await _pumpAlphabetScreen(
        tester,
        recitersBloc: recitersBloc,
        favoritesCubit: favoritesCubit,
      );

      await _flingCatalog(tester, delta: const Offset(0, -900));
      await _flingCatalog(tester, delta: const Offset(0, -600));

      final gesture = await _startAlphabetScrub(tester, letter: 'H');
      await gesture.moveBy(const Offset(0, 160));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      final ScrollPosition? catalogAfter = _catalogScrollPosition(tester);

      expect(catalogAfter?.pixels ?? 0, closeTo(0, 1.5));
      expect(tester.takeException(), isNull);
    });

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
      'catalog stays near top when scrub starts expanded',
      (tester) async {
        await _pumpAlphabetScreen(
          tester,
          recitersBloc: recitersBloc,
          favoritesCubit: favoritesCubit,
        );

        expect(_catalogScrollPosition(tester)?.pixels ?? 0, closeTo(0, 1.0));

        final gesture = await _startAlphabetScrub(tester, letter: 'A');
        await gesture.moveBy(const Offset(0, 220));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 50));

        expect(
          _catalogScrollPosition(tester)?.pixels ?? 0,
          closeTo(0, 1.5),
          reason: 'expanded catalog must not jump when letters change',
        );

        await gesture.up();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('records catalog metrics before scrub for restore', (
      tester,
    ) async {
      await _pumpAlphabetScreen(
        tester,
        recitersBloc: recitersBloc,
        favoritesCubit: favoritesCubit,
      );

      await _flingCatalog(tester, delta: const Offset(0, -900));
      final double scrolledCatalog =
          _catalogScrollPosition(tester)?.pixels ?? 0;
      expect(scrolledCatalog, greaterThan(8));

      final gesture = await _startAlphabetScrub(tester, letter: 'K');
      await gesture.moveBy(const Offset(0, 48));
      await tester.pump();

      expect(
        _catalogScrollPosition(tester)?.pixels ?? 0,
        closeTo(scrolledCatalog, 2.0),
        reason: 'catalog offset should stay pinned during scrub',
      );

      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

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
