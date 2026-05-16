import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/reciters/presentation/cubit/favorites_cubit.dart';
import 'package:tilawa/features/reciters/presentation/reciter_semantics_ids.dart';
import 'package:tilawa/features/reciters/presentation/widgets/reciter_card.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../cubit/favorites_cubit_test.mocks.dart';

void main() {
  late MockGetFavoriteRecitersUseCase mockGetFavorites;
  late MockToggleFavoriteReciterUseCase mockToggleFavorite;
  late MockClearFavoriteRecitersUseCase mockClearFavorites;

  const tReciter = ReciterEntity(
    id: 42,
    name: 'Test Reciter',
    letter: 'T',
    date: '2023',
    moshaf: [],
  );

  setUpAll(() {
    AppTheme.useGoogleFonts = false;
  });

  setUp(() {
    provideDummy<Either<Failure, List<ReciterEntity>>>(const Right([]));
    provideDummy<Either<Failure, void>>(const Right(null));
    mockGetFavorites = MockGetFavoriteRecitersUseCase();
    mockToggleFavorite = MockToggleFavoriteReciterUseCase();
    mockClearFavorites = MockClearFavoriteRecitersUseCase();
  });

  tearDown(() async {
    reset(mockGetFavorites);
    reset(mockToggleFavorite);
    reset(mockClearFavorites);
  });

  Future<FavoritesCubit> loadedCubit({
    bool withFavoriteReciter = false,
  }) async {
    when(
      mockGetFavorites(any),
    ).thenAnswer(
      (_) async => Right(
        withFavoriteReciter ? const <ReciterEntity>[tReciter] : const [],
      ),
    );
    when(
      mockToggleFavorite(any),
    ).thenAnswer((_) async => const Right(null));
    final cubit = FavoritesCubit(
      mockGetFavorites,
      mockToggleFavorite,
      mockClearFavorites,
    );
    await cubit.loadFavorites();
    return cubit;
  }

  Future<void> pumpCard(WidgetTester tester, FavoritesCubit cubit) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(
          primaryColor: PrimaryColorPreset.defaultPreset.value,
          useGoogleFontsOverride: false,
        ),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        home: Scaffold(
          body: Center(
            child: BlocProvider<FavoritesCubit>.value(
              value: cubit,
              child: const ReciterCard(reciter: tReciter),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('exposes open-reciter and favorite semantics in English', (
    WidgetTester tester,
  ) async {
    final cubit = await loadedCubit();
    await pumpCard(tester, cubit);

    final Finder openRegion = find.bySemanticsIdentifier(
      ReciterSemanticsIds.reciterCard(tReciter.id),
    );

    expect(
      tester.getSemantics(openRegion).label,
      startsWith('Open Test Reciter'),
    );
    expect(find.bySemanticsLabel('Add to Favorites'), findsOneWidget);

    await cubit.close();
  });

  testWidgets('favorite control semantic bounds meet Tilawa hit-target floor', (
    WidgetTester tester,
  ) async {
    final cubit = await loadedCubit();
    await pumpCard(tester, cubit);

    final Rect rect = tester.getRect(
      find.bySemanticsLabel('Add to Favorites'),
    );
    expect(rect.width, greaterThanOrEqualTo(kTilawaMinInteractiveDimension));
    expect(rect.height, greaterThanOrEqualTo(kTilawaMinInteractiveDimension));

    await cubit.close();
  });

  testWidgets('tapping favorite invokes toggle use case', (
    WidgetTester tester,
  ) async {
    final cubit = await loadedCubit();
    await pumpCard(tester, cubit);

    await tester.tap(find.bySemanticsLabel('Add to Favorites'));
    await tester.pumpAndSettle();

    verify(mockToggleFavorite(tReciter.id)).called(1);

    await cubit.close();
  });

  testWidgets('when reciter is favorited, shows remove semantics', (
    WidgetTester tester,
  ) async {
    final cubit = await loadedCubit(withFavoriteReciter: true);
    await pumpCard(tester, cubit);

    expect(find.bySemanticsLabel('Remove from favorites'), findsOneWidget);

    await cubit.close();
  });

  testWidgets(
    'full-card InkWell wraps content; favorite retains inner InkWell',
    (WidgetTester tester) async {
      final cubit = await loadedCubit();
      await pumpCard(tester, cubit);

      expect(
        find.descendant(
          of: find.byType(ReciterCard),
          matching: find.byType(InkWell),
        ),
        findsNWidgets(2),
      );

      final Finder row = find.byType(Row);
      final Finder openInkWell = find.ancestor(
        of: row,
        matching: find.byType(InkWell),
      );
      expect(openInkWell, findsOneWidget);

      final Finder favoriteInkWell = find.descendant(
        of: find.bySemanticsIdentifier(
          ReciterSemanticsIds.reciterFavoriteButton(tReciter.id),
        ),
        matching: find.byType(InkWell),
      );
      expect(favoriteInkWell, findsOneWidget);
      expect(
        find.descendant(of: openInkWell, matching: favoriteInkWell),
        findsOneWidget,
      );

      await cubit.close();
    },
  );
}
