import 'package:bloc_test/bloc_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/app_review/domain/services/app_review_flow_guard.dart';
import 'package:tilawa/features/app_review/domain/services/app_review_trigger_manager.dart';
import 'package:tilawa/features/audio_player/domain/entities/player_background_configuration.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/audio_player/presentation/cubit/player_background_cubit.dart';
import 'package:tilawa/features/audio_player/presentation/cubit/player_background_state.dart';
import 'package:tilawa/features/localization/domain/usecases/get_current_language_use_case.dart';
import 'package:tilawa/features/localization/domain/usecases/set_language_use_case.dart';
import 'package:tilawa/features/localization/presentation/bloc/localization_bloc.dart';
import 'package:tilawa/features/reciters/domain/usecases/clear_favorite_reciters_use_case.dart';
import 'package:tilawa/features/reciters/domain/usecases/get_favorite_reciters_use_case.dart';
import 'package:tilawa/features/reciters/domain/usecases/get_reciters_use_case.dart';
import 'package:tilawa/features/reciters/domain/usecases/toggle_favorite_reciter_use_case.dart';
import 'package:tilawa/features/reciters/presentation/bloc/alphabet_scrollbar/alphabet_scrollbar_bloc.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciters_bloc.dart';
import 'package:tilawa/features/reciters/presentation/cubit/favorites_cubit.dart';
import 'package:tilawa/features/reciters/presentation/screens/reciters_screen.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/screens/cubit/main_screen_cubit.dart';
import 'package:tilawa/screens/main_screen.dart';
import 'package:tilawa/shared/widgets/quran_player_chrome.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/presentation/bloc/internet_status/internet_status_bloc.dart';
import 'package:tilawa_core/presentation/bloc/internet_status/internet_status_state.dart';
import 'package:tilawa_core/usecases/usecase.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class _MockGetFavoriteRecitersUseCase extends Mock
    implements GetFavoriteRecitersUseCase {}

class _MockToggleFavoriteReciterUseCase extends Mock
    implements ToggleFavoriteReciterUseCase {}

class _MockClearFavoriteRecitersUseCase extends Mock
    implements ClearFavoriteRecitersUseCase {}

class _MockGetRecitersUseCase extends Mock implements GetRecitersUseCase {}

class _MockGetCurrentLanguageUseCase extends Mock
    implements GetCurrentLanguageUseCase {}

class _MockPlayerBackgroundCubit extends MockCubit<PlayerBackgroundState>
    implements PlayerBackgroundCubit {}

class _MockAudioPlayerBloc extends MockCubit<AudioPlayerState>
    implements AudioPlayerBloc {}

class _MockInternetStatusBloc extends MockCubit<InternetStatusState>
    implements InternetStatusBloc {}

class _MockSetLanguageUseCase extends Mock implements SetLanguageUseCase {}

class _MockAppReviewTriggerManager extends Mock
    implements AppReviewTriggerManager {}

class _FakeStorage extends Fake implements Storage {
  @override
  dynamic read(String key) => null;

  @override
  Future<void> write(String key, dynamic value) async {}

  @override
  Future<void> delete(String key) async {}

  @override
  Future<void> clear() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final GetIt getIt = GetIt.instance;
  late _MockGetFavoriteRecitersUseCase mockGetFavorites;
  late _MockToggleFavoriteReciterUseCase mockToggleFavorite;
  late _MockClearFavoriteRecitersUseCase mockClearFavorites;
  late FavoritesCubit favoritesCubit;
  late _MockInternetStatusBloc mockInternetStatusBloc;

  setUpAll(() {
    registerFallbackValue(const NoParams());
  });

  setUp(() async {
    await getIt.reset();
    getIt.allowReassignment = true;
    HydratedBloc.storage = _FakeStorage();

    mockGetFavorites = _MockGetFavoriteRecitersUseCase();
    mockToggleFavorite = _MockToggleFavoriteReciterUseCase();
    mockClearFavorites = _MockClearFavoriteRecitersUseCase();

    when(() => mockGetFavorites(any())).thenAnswer(
      (_) async => Future<Either<Failure, List<ReciterEntity>>>.value(
        const Right<Failure, List<ReciterEntity>>([]),
      ),
    );
    when(
      () => mockToggleFavorite(any()),
    ).thenAnswer((_) async => const Right<Failure, void>(null));
    when(
      () => mockClearFavorites(),
    ).thenAnswer((_) async => const Right<Failure, void>(null));

    favoritesCubit = FavoritesCubit(
      mockGetFavorites,
      mockToggleFavorite,
      mockClearFavorites,
    );

    getIt.registerSingleton<FavoritesCubit>(favoritesCubit);

    mockInternetStatusBloc = _MockInternetStatusBloc();
    when(() => mockInternetStatusBloc.state).thenReturn(
      const InternetStatusState.connected(),
    );
    getIt.registerSingleton<InternetStatusBloc>(mockInternetStatusBloc);

    getIt.registerSingleton<AppReviewFlowGuard>(AppReviewFlowGuard());

    final mockAppReviewTriggerManager = _MockAppReviewTriggerManager();
    when(
      () => mockAppReviewTriggerManager.onSessionStarted(),
    ).thenAnswer((_) async {});
    getIt.registerSingleton<AppReviewTriggerManager>(
      mockAppReviewTriggerManager,
    );
  });

  tearDown(() async {
    if (!favoritesCubit.isClosed) {
      await favoritesCubit.close();
    }
    await getIt.reset();
  });

  Widget buildTestApp({
    MainScreenCubit? mainScreenCubit,
    RecitersBloc? recitersBloc,
  }) {
    final mockPlayerBackgroundCubit = _MockPlayerBackgroundCubit();
    when(() => mockPlayerBackgroundCubit.state).thenReturn(
      const PlayerBackgroundInitial(PlayerBackgroundConfiguration()),
    );
    final mockAudioPlayerBloc = _MockAudioPlayerBloc();
    when(() => mockAudioPlayerBloc.state).thenReturn(
      const AudioPlayerState(status: AudioPlayerStatus.initial),
    );

    final mockGetLanguage = _MockGetCurrentLanguageUseCase();
    when(
      () => mockGetLanguage(),
    ).thenAnswer((_) async => const Right<Failure, String>('en'));
    final mockSetLanguage = _MockSetLanguageUseCase();
    when(
      () => mockSetLanguage(any()),
    ).thenAnswer((_) async => const Right<Failure, void>(null));

    final RecitersBloc effectiveRecitersBloc = recitersBloc ?? () {
      final mockGetReciters = _MockGetRecitersUseCase();
      when(() => mockGetReciters.call()).thenAnswer(
        (_) async => const Right<Failure, List<ReciterEntity>>([]),
      );
      return RecitersBloc(mockGetReciters);
    }();

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const MainScreen(),
        ),
      ],
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<MainScreenCubit>(
          create: (_) => mainScreenCubit ?? MainScreenCubit(),
        ),
        BlocProvider<RecitersBloc>.value(value: effectiveRecitersBloc),
        BlocProvider<AlphabetScrollbarBloc>(
          create: (_) => AlphabetScrollbarBloc(),
        ),
        BlocProvider<LocalizationBloc>(
          create: (_) => LocalizationBloc(mockGetLanguage, mockSetLanguage),
        ),
        BlocProvider<PlayerBackgroundCubit>.value(
          value: mockPlayerBackgroundCubit,
        ),
        BlocProvider<AudioPlayerBloc>.value(value: mockAudioPlayerBloc),
      ],
      child: ChangeNotifierProvider(
        create: (_) => QuranPlayerChromeNotifier(),
        child: MaterialApp.router(
          theme: ThemeData(
            extensions: [
              TilawaDesignTokens.light(),
              TilawaComponentTokens.light(),
            ],
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
  }

  Widget buildRecitersScreenTestApp() {
    final mockGetReciters = _MockGetRecitersUseCase();
    final mockGetLanguage = _MockGetCurrentLanguageUseCase();
    final mockSetLanguage = _MockSetLanguageUseCase();
    const reciters = [
      ReciterEntity(
        id: 1,
        name: 'Alpha Reciter',
        letter: 'A',
        date: '',
        moshaf: [],
      ),
      ReciterEntity(
        id: 2,
        name: 'Beta Reciter',
        letter: 'B',
        date: '',
        moshaf: [],
      ),
      ReciterEntity(
        id: 3,
        name: 'Gamma Reciter',
        letter: 'G',
        date: '',
        moshaf: [],
      ),
    ];

    when(() => mockGetReciters.call()).thenAnswer(
      (_) async => const Right<Failure, List<ReciterEntity>>(reciters),
    );
    when(
      () => mockGetLanguage(),
    ).thenAnswer((_) async => const Right<Failure, String>('en'));
    when(
      () => mockSetLanguage(any()),
    ).thenAnswer((_) async => const Right<Failure, void>(null));

    return MultiBlocProvider(
      providers: [
        BlocProvider<RecitersBloc>(
          create: (_) => RecitersBloc(mockGetReciters),
        ),
        BlocProvider<AlphabetScrollbarBloc>(
          create: (_) => AlphabetScrollbarBloc(),
        ),
        BlocProvider<LocalizationBloc>(
          create: (_) => LocalizationBloc(mockGetLanguage, mockSetLanguage),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(
          extensions: [
            TilawaDesignTokens.light(),
            TilawaComponentTokens.light(),
          ],
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const RecitersScreen(),
      ),
    );
  }

  testWidgets('keeps main content deferred before initial tab settle delay', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestApp());

    expect(find.byType(RecitersScreen), findsNothing);

    await tester.pump(const Duration(milliseconds: 1100));
    expect(find.byType(RecitersScreen), findsNothing);
  });

  testWidgets('mounts initial reciters tab after settle delay gate', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestApp());

    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump();

    expect(find.byType(RecitersScreen), findsOneWidget);
  });

  testWidgets(
    'does not regress by remounting tab during short follow-up frames',
    (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pump();
      expect(find.byType(RecitersScreen), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(RecitersScreen), findsOneWidget);
    },
  );

  for (final (:name, :size) in [
    (name: 'narrowPhone', size: const Size(360, 640)),
    (name: 'expanded', size: const Size(1024, 768)),
  ]) {
    testWidgets('renders reciters sliver surface without overflow on $name', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildRecitersScreenTestApp());
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();

      expect(find.byType(RecitersScreen), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.text('Alpha Reciter'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
