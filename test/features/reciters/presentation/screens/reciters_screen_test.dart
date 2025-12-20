import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:muzakri/core/di/injection.dart';
import 'package:muzakri/core/entities/reciter_entity.dart';
import 'package:muzakri/features/alphabet_scrollbar/presentation/bloc/alphabet_scrollbar_bloc.dart';
import 'package:muzakri/features/localization/presentation/bloc/localization_bloc.dart';
import 'package:muzakri/features/reciters/presentation/bloc/reciters_bloc.dart';
import 'package:muzakri/features/reciters/presentation/cubit/favorites_cubit.dart';
import 'package:muzakri/features/reciters/presentation/cubit/favorites_state.dart';
import 'package:muzakri/features/reciters/presentation/screens/reciters_screen.dart';
import 'package:muzakri/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockRecitersBloc extends MockBloc<RecitersEvent, RecitersState>
    implements RecitersBloc {}

class MockAlphabetScrollbarBloc
    extends MockBloc<AlphabetScrollbarEvent, AlphabetScrollbarState>
    implements AlphabetScrollbarBloc {}

class MockLocalizationBloc
    extends MockBloc<LocalizationEvent, LocalizationState>
    implements LocalizationBloc {}

class MockFavoritesCubit extends MockCubit<FavoritesState>
    implements FavoritesCubit {}

void main() {
  late MockRecitersBloc mockRecitersBloc;
  late MockAlphabetScrollbarBloc mockAlphabetScrollbarBloc;
  late MockLocalizationBloc mockLocalizationBloc;
  late MockFavoritesCubit mockFavoritesCubit;

  setUpAll(() {
    registerFallbackValue(const RecitersInitial());
    registerFallbackValue(FavoritesInitial());
  });

  setUp(() {
    mockRecitersBloc = MockRecitersBloc();
    mockAlphabetScrollbarBloc = MockAlphabetScrollbarBloc();
    mockLocalizationBloc = MockLocalizationBloc();
    mockFavoritesCubit = MockFavoritesCubit();

    // Register mock favorites cubit in getIt
    getIt.registerSingleton<FavoritesCubit>(mockFavoritesCubit);

    // Default stub for favorites cubit
    whenListen(
      mockFavoritesCubit,
      const Stream<FavoritesState>.empty(),
      initialState: FavoritesInitial(),
    );
    when(() => mockFavoritesCubit.loadFavorites()).thenAnswer((_) async {});

    // Mock Alphabet Scrollbar
    whenListen(
      mockAlphabetScrollbarBloc,
      const Stream<AlphabetScrollbarState>.empty(),
      initialState: const AlphabetScrollbarState(),
    );

    // Mock Localization
    whenListen(
      mockLocalizationBloc,
      const Stream<LocalizationState>.empty(),
      initialState: const LocalizationState(locale: Locale('en')),
    );

    // Mock Shared Preferences to avoid late initialization error in ScreenUtil
    SharedPreferences.setMockInitialValues({});

    final TestWidgetsFlutterBinding binding =
        TestWidgetsFlutterBinding.ensureInitialized();
    binding.window.physicalSizeTestValue = const Size(
      1200 * 3,
      1600 * 3,
    ); // Large tablet
    binding.window.devicePixelRatioTestValue = 3;
  });

  tearDown(() {
    final TestWidgetsFlutterBinding binding =
        TestWidgetsFlutterBinding.ensureInitialized();
    binding.window.clearPhysicalSizeTestValue();
    binding.window.clearDevicePixelRatioTestValue();

    // Unregister from getIt
    if (getIt.isRegistered<FavoritesCubit>()) {
      getIt.unregister<FavoritesCubit>();
    }
  });

  Widget createWidgetUnderTest() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<RecitersBloc>.value(value: mockRecitersBloc),
        BlocProvider<AlphabetScrollbarBloc>.value(
          value: mockAlphabetScrollbarBloc,
        ),
        BlocProvider<LocalizationBloc>.value(value: mockLocalizationBloc),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en'), Locale('ar')],
        home: ScreenUtilPlusInit(
          designSize: Size(375, 812),
          minTextAdapt: true,
          splitScreenMode: true,
          child: RecitersScreen(),
        ),
      ),
    );
  }

  testWidgets('RecitersScreen displays loading state', (tester) async {
    whenListen(
      mockRecitersBloc,
      Stream.fromIterable([const RecitersLoading()]),
      initialState: const RecitersInitial(),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets(
    'RecitersScreen displays reciter cards when state is RecitersLoaded',
    (tester) async {
      final reciters = [
        const ReciterEntity(
          id: 1,
          name: 'Reciter 1',
          letter: 'R',
          date: '2023',
          moshaf: [],
        ),
        const ReciterEntity(
          id: 2,
          name: 'Reciter 2',
          letter: 'R',
          date: '2023',
          moshaf: [],
        ),
      ];

      whenListen(
        mockRecitersBloc,
        Stream.fromIterable([
          RecitersLoaded(reciters: reciters, filteredReciters: reciters),
        ]),
        initialState: const RecitersInitial(),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('Reciter 1'), findsOneWidget);
      expect(find.text('Reciter 2'), findsOneWidget);
    },
  );

  testWidgets(
    'RecitersScreen displays empty message when state is RecitersLoaded with empty list',
    (tester) async {
      whenListen(
        mockRecitersBloc,
        Stream.fromIterable([
          const RecitersLoaded(reciters: [], filteredReciters: []),
        ]),
        initialState: const RecitersInitial(),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('No reciters found'), findsOneWidget);
    },
  );
}
