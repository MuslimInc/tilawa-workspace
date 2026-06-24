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
import 'package:tilawa_core/entities/moshaf_entity.dart';
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

  setUpAll(() {});

  setUp(() {
    provideDummy<Either<Failure, List<ReciterEntity>>>(const Right([]));
    provideDummy<Either<Failure, void>>(const Right(null));
    mockGetFavorites = MockGetFavoriteRecitersUseCase();
    mockToggleFavorite = MockToggleFavoriteReciterUseCase();
    mockClearFavorites = MockClearFavoriteRecitersUseCase();
    when(mockGetFavorites.takeCachedSuccessForStartup()).thenReturn(null);
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

  testWidgets('shows remove control when reciter is favorited', (
    WidgetTester tester,
  ) async {
    final cubit = await loadedCubit(withFavoriteReciter: true);
    await pumpCard(tester, cubit);

    final Finder favoriteButton = find.bySemanticsIdentifier(
      ReciterSemanticsIds.reciterFavoriteButton(tReciter.id),
    );
    expect(favoriteButton, findsOneWidget);
    expect(
      tester.getSemantics(favoriteButton).label,
      startsWith('Remove from'),
    );

    await cubit.close();
  });

  testWidgets('places favorite control as trailing row child', (
    WidgetTester tester,
  ) async {
    final cubit = await loadedCubit();
    await pumpCard(tester, cubit);

    final Finder favoriteButton = find.bySemanticsIdentifier(
      ReciterSemanticsIds.reciterFavoriteButton(tReciter.id),
    );
    expect(
      find.ancestor(
        of: favoriteButton,
        matching: find.descendant(
          of: find.byType(ReciterCard),
          matching: find.byType(Row),
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(ReciterCard),
        matching: find.byType(TilawaCard),
      ),
      findsOneWidget,
    );

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

  testWidgets('favorite control does not stretch with tall card content', (
    WidgetTester tester,
  ) async {
    const reciter = ReciterEntity(
      id: 7,
      name: 'Very Long Reciter Name That Wraps Across Multiple Lines',
      letter: 'V',
      date: '2023',
      moshaf: [
        MoshafEntity(
          id: 1,
          name: "Rewayat Hafs A'n Assem - Murattal - Mojawwad",
          server: 'https://example.com',
          surahTotal: 114,
          moshafType: 0,
          surahList: '1',
        ),
        MoshafEntity(
          id: 2,
          name: 'Murattal',
          server: 'https://example.com',
          surahTotal: 114,
          moshafType: 0,
          surahList: '1',
        ),
      ],
    );
    final cubit = await loadedCubit();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(
          primaryColor: PrimaryColorPreset.defaultPreset.value,
        ),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: BlocProvider<FavoritesCubit>.value(
                value: cubit,
                child: const ReciterCard(reciter: reciter),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Rect favoriteRect = tester.getRect(
      find.bySemanticsIdentifier(
        ReciterSemanticsIds.reciterFavoriteButton(reciter.id),
      ),
    );
    expect(favoriteRect.height, kTilawaMinInteractiveDimension);
    expect(favoriteRect.width, kTilawaMinInteractiveDimension);

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

  testWidgets('favorite icon reverts when persistence fails (offline)', (
    WidgetTester tester,
  ) async {
    final cubit = await loadedCubit();
    when(mockToggleFavorite(any)).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return const Left(ServerFailure('offline'));
    });
    await pumpCard(tester, cubit);

    await tester.tap(find.bySemanticsLabel('Add to Favorites'));
    await tester.pump();
    expect(find.bySemanticsLabel('Remove from favorites'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Add to Favorites'), findsOneWidget);
    expect(find.bySemanticsLabel('Remove from favorites'), findsNothing);

    await cubit.close();
  });

  testWidgets('favorite icon updates optimistically before network settles', (
    WidgetTester tester,
  ) async {
    when(mockToggleFavorite(any)).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(seconds: 1));
      return const Right(null);
    });
    final cubit = await loadedCubit();
    await pumpCard(tester, cubit);

    expect(find.bySemanticsLabel('Add to Favorites'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Add to Favorites'));
    await tester.pump();

    expect(find.bySemanticsLabel('Remove from favorites'), findsOneWidget);
    expect(find.bySemanticsLabel('Add to Favorites'), findsNothing);

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
    'TilawaCard handles card tap; favorite uses TilawaIconToggle',
    (WidgetTester tester) async {
      final cubit = await loadedCubit();
      await pumpCard(tester, cubit);

      expect(
        find.descendant(
          of: find.byType(ReciterCard),
          matching: find.byType(TilawaCard),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(ReciterCard),
          matching: find.byType(TilawaIconToggle),
        ),
        findsOneWidget,
      );

      await cubit.close();
    },
  );

  testWidgets('shows reciter initial in avatar', (WidgetTester tester) async {
    final cubit = await loadedCubit();
    await pumpCard(tester, cubit);

    expect(find.text('T'), findsOneWidget);

    await cubit.close();
  });

  testWidgets('shows compact moshaf label with localized more suffix', (
    WidgetTester tester,
  ) async {
    const reciter = ReciterEntity(
      id: 7,
      name: 'Ibrahim Al-Akdar',
      letter: 'I',
      date: '2023',
      moshaf: [
        MoshafEntity(
          id: 1,
          name: "Rewayat Hafs A'n Assem - Murattal - Mojawwad",
          server: 'https://example.com',
          surahTotal: 114,
          moshafType: 0,
          surahList: '1',
        ),
        MoshafEntity(
          id: 2,
          name: 'Murattal',
          server: 'https://example.com',
          surahTotal: 114,
          moshafType: 0,
          surahList: '1',
        ),
      ],
    );
    final cubit = await loadedCubit();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(
          primaryColor: PrimaryColorPreset.defaultPreset.value,
        ),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        home: Scaffold(
          body: Center(
            child: BlocProvider<FavoritesCubit>.value(
              value: cubit,
              child: const ReciterCard(reciter: reciter),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text("Hafs A'n Assem · Mojawwad · 1 more"),
      findsOneWidget,
    );

    await cubit.close();
  });
}
