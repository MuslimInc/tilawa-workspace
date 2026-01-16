import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa_core/entities/moshaf_entity.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa/features/reciters/presentation/cubit/favorites_cubit.dart';
import 'package:tilawa/features/reciters/presentation/cubit/favorites_state.dart';
import 'package:tilawa/features/reciters/presentation/widgets/reciter_card.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';

class MockFavoritesCubit extends MockCubit<FavoritesState>
    implements FavoritesCubit {}

class MockGoRouter extends Mock implements GoRouter {}

void main() {
  late FavoritesCubit mockFavoritesCubit;
  late MockGoRouter mockGoRouter;

  const tReciter = ReciterEntity(
    id: 1,
    name: 'Mishary Rashid Alafasy',
    letter: 'M',
    date: '2023',
    moshaf: [
      MoshafEntity(
        id: 1,
        name: "Rewayat Hafs A'n Assem",
        server: 'https://server.com',
        surahTotal: 114,
        moshafType: 1,
        surahList: '1,2,3',
      ),
    ],
  );

  setUpAll(() {
    registerFallbackValue(tReciter);
  });

  setUp(() {
    mockFavoritesCubit = MockFavoritesCubit();
    mockGoRouter = MockGoRouter();
  });

  Widget createWidgetUnderTest() {
    return ScreenUtilPlusInit(
      designSize: const Size(390, 844),
      builder: (context, child) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: InheritedGoRouter(
          goRouter: mockGoRouter,
          child: BlocProvider<FavoritesCubit>.value(
            value: mockFavoritesCubit,
            child: const Scaffold(body: ReciterCard(reciter: tReciter)),
          ),
        ),
      ),
    );
  }

  group('ReciterCard', () {
    testWidgets('renders correctly with given reciter details', (tester) async {
      when(
        () => mockFavoritesCubit.state,
      ).thenReturn(const FavoritesLoaded(favorites: [], favoriteIds: {}));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Mishary Rashid Alafasy'), findsOneWidget);
      expect(find.text('M'), findsOneWidget);
      expect(find.text("Rewayat Hafs A'n Assem"), findsOneWidget);
    });

    testWidgets('shows favorite border icon when reciter is not favorite', (
      tester,
    ) async {
      when(
        () => mockFavoritesCubit.state,
      ).thenReturn(const FavoritesLoaded(favorites: [], favoriteIds: {}));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsNothing);
    });

    testWidgets('shows filled favorite icon when reciter is favorite', (
      tester,
    ) async {
      when(() => mockFavoritesCubit.state).thenReturn(
        FavoritesLoaded(
          favorites: const [tReciter],
          favoriteIds: {tReciter.id},
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsNothing);

      final Icon icon = tester.widget<Icon>(find.byIcon(Icons.favorite));
      expect(icon.color, Colors.red);
    });

    testWidgets('calls toggleFavorite when favorite button is tapped', (
      tester,
    ) async {
      when(
        () => mockFavoritesCubit.state,
      ).thenReturn(const FavoritesLoaded(favorites: [], favoriteIds: {}));
      when(
        () => mockFavoritesCubit.toggleFavorite(any()),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Find InkWell that contains the favorite icon
      final Finder favoriteButton = find
          .ancestor(
            of: find.byIcon(Icons.favorite_border),
            matching: find.byType(InkWell),
          )
          .first;

      await tester.tap(favoriteButton);
      await tester.pump();

      verify(() => mockFavoritesCubit.toggleFavorite(tReciter)).called(1);
    });

    testWidgets('navigates to ReciterDetailsRoute when card is tapped', (
      tester,
    ) async {
      when(
        () => mockFavoritesCubit.state,
      ).thenReturn(const FavoritesLoaded(favorites: [], favoriteIds: {}));

      // Use exact match to ensure successful stubbing
      when(
        () => mockGoRouter.push<dynamic>('/reciter/1', extra: tReciter),
      ).thenAnswer((_) async => null);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Find and tap the reciter name text to ensure we hit the card's InkWell
      await tester.tap(find.text('Mishary Rashid Alafasy'));
      await tester.pump();

      // Verify navigation called with expected arguments
      verify(
        () => mockGoRouter.push<dynamic>('/reciter/1', extra: tReciter),
      ).called(1);
    });
  });
}
