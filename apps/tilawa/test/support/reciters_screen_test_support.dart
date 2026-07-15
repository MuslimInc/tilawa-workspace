import 'package:bloc_test/bloc_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/downloads/presentation/bloc/downloads_bloc.dart';
import 'package:tilawa/features/localization/presentation/bloc/localization_bloc.dart';
import 'package:tilawa/features/reciters/domain/usecases/clear_favorite_reciters_use_case.dart';
import 'package:tilawa/features/reciters/domain/usecases/get_favorite_reciters_use_case.dart';
import 'package:tilawa/features/reciters/domain/usecases/get_reciters_use_case.dart';
import 'package:tilawa/features/reciters/domain/usecases/toggle_favorite_reciter_use_case.dart';
import 'package:tilawa/features/reciters/presentation/bloc/alphabet_scrollbar/alphabet_scrollbar_bloc.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciters_bloc.dart';
import 'package:tilawa/features/reciters/presentation/cubit/favorites_cubit.dart';
import 'package:tilawa/features/reciters/presentation/cubit/favorites_state.dart';
import 'package:tilawa/features/reciters/presentation/screens/reciters_screen.dart';
import 'package:tilawa/features/reciters/presentation/tour/reciters_tour_launcher.dart';
import 'package:tilawa/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:tilawa/features/tour_guide/domain/services/tour_target_registry.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/screens/cubit/main_screen_cubit.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Registers mocktail fallback values for reciters screen widget tests.
void registerRecitersScreenTestFallbacks() {
  registerFallbackValue(const NoParams());
  registerFallbackValue(const LoadDownloads());
}

class MockGetRecitersUseCase extends Mock implements GetRecitersUseCase {}

class MockGetFavoriteRecitersUseCase extends Mock
    implements GetFavoriteRecitersUseCase {}

class MockToggleFavoriteReciterUseCase extends Mock
    implements ToggleFavoriteReciterUseCase {}

class MockClearFavoriteRecitersUseCase extends Mock
    implements ClearFavoriteRecitersUseCase {}

class MockSettingsCubit extends MockCubit<SettingsState>
    implements SettingsCubit {}

class MockLocalizationBloc extends MockCubit<LocalizationState>
    implements LocalizationBloc {}

class MockDownloadsBloc extends Mock implements DownloadsBloc {}

class _FakeHydratedStorage extends Fake implements Storage {
  @override
  dynamic read(String key) => null;

  @override
  Future<void> write(String key, dynamic value) async {}

  @override
  Future<void> delete(String key) async {}

  @override
  Future<void> clear() async {}
}

class NoopRecitersTourLauncher implements RecitersTourLauncher {
  @override
  Future<bool> maybeShowRecitersIntro(BuildContext context) async => false;

  @override
  Future<bool> maybeShowPlaybackTour(BuildContext context) async => false;
}

const kRecitersTestReciters = <ReciterEntity>[
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

Future<void> configureRecitersScreenTestGetIt({
  required FavoritesCubit favoritesCubit,
}) async {
  final GetIt getIt = GetIt.instance;
  await getIt.reset();
  getIt.allowReassignment = true;
  HydratedBloc.storage = _FakeHydratedStorage();

  getIt.registerSingleton<FavoritesCubit>(favoritesCubit);
  getIt.registerSingleton<RecitersTourLauncher>(NoopRecitersTourLauncher());
  getIt.registerSingleton<TourTargetRegistry>(TourTargetRegistry());

  final MockDownloadsBloc mockDownloadsBloc = MockDownloadsBloc();
  when(() => mockDownloadsBloc.state).thenReturn(
    const DownloadsState(status: DownloadsStateStatus.loading),
  );
  when(() => mockDownloadsBloc.stream).thenAnswer((_) => const Stream.empty());
  when(mockDownloadsBloc.close).thenAnswer((_) async {});
  when(() => mockDownloadsBloc.add(any())).thenReturn(null);
  getIt.registerFactory<DownloadsBloc>(() => mockDownloadsBloc);
}

FavoritesCubit seededFavoritesCubit({
  Set<int> favoriteIds = const {1, 2},
  List<ReciterEntity>? favorites,
}) {
  final List<ReciterEntity> resolvedFavorites =
      favorites ??
      <ReciterEntity>[
        kRecitersTestReciters[0],
        kRecitersTestReciters[1],
      ];
  final MockGetFavoriteRecitersUseCase mockGetFavorites =
      MockGetFavoriteRecitersUseCase();
  final MockToggleFavoriteReciterUseCase mockToggleFavorite =
      MockToggleFavoriteReciterUseCase();
  final MockClearFavoriteRecitersUseCase mockClearFavorites =
      MockClearFavoriteRecitersUseCase();

  when(
    mockGetFavorites.takeCachedSuccessForStartup,
  ).thenReturn(resolvedFavorites);
  when(() => mockGetFavorites(any())).thenAnswer(
    (_) async => Right<Failure, List<ReciterEntity>>(resolvedFavorites),
  );
  when(() => mockToggleFavorite(any())).thenAnswer(
    (_) async => const Right<Failure, void>(null),
  );
  when(mockClearFavorites.call).thenAnswer(
    (_) async => const Right<Failure, void>(null),
  );

  final cubit = FavoritesCubit(
    mockGetFavorites,
    mockToggleFavorite,
    mockClearFavorites,
  );
  expect(cubit.state, isA<FavoritesLoaded>());
  final loaded = cubit.state as FavoritesLoaded;
  expect(loaded.favoriteIds, favoriteIds);
  return cubit;
}

Widget buildRecitersScreenTestApp({
  required RecitersBloc recitersBloc,
  required FavoritesCubit favoritesCubit,
  SettingsState settingsState = const SettingsState(),
  Locale locale = const Locale('en'),
}) {
  final MockLocalizationBloc mockLocalizationBloc = MockLocalizationBloc();
  when(
    () => mockLocalizationBloc.state,
  ).thenReturn(LocalizationState(locale: locale));
  when(
    () => mockLocalizationBloc.stream,
  ).thenAnswer((_) => const Stream.empty());
  when(mockLocalizationBloc.close).thenAnswer((_) async {});

  final MockSettingsCubit mockSettingsCubit = MockSettingsCubit();
  when(() => mockSettingsCubit.state).thenReturn(settingsState);
  when(() => mockSettingsCubit.stream).thenAnswer((_) => const Stream.empty());

  return MultiBlocProvider(
    providers: [
      BlocProvider<MainScreenCubit>(create: (_) => MainScreenCubit()),
      BlocProvider<RecitersBloc>.value(value: recitersBloc),
      BlocProvider<AlphabetScrollbarBloc>(
        create: (_) => AlphabetScrollbarBloc(),
      ),
      BlocProvider<LocalizationBloc>.value(value: mockLocalizationBloc),
      BlocProvider<SettingsCubit>.value(value: mockSettingsCubit),
    ],
    child: MaterialApp(
      theme: AppTheme.getLightTheme(
        primaryColor: PrimaryColorPreset.defaultPreset.value,
      ),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const RecitersScreen(),
    ),
  );
}

RecitersBloc loadedRecitersBloc({
  List<ReciterEntity> reciters = kRecitersTestReciters,
  List<ReciterEntity>? filteredReciters,
  bool showFavoritesOnly = false,
  Set<int> favoriteIds = const {},
  String? selectedLetter,
}) {
  final MockGetRecitersUseCase mockGetReciters = MockGetRecitersUseCase();
  when(mockGetReciters.call).thenAnswer(
    (_) async => Right<Failure, List<ReciterEntity>>(reciters),
  );

  final bloc = RecitersBloc(mockGetReciters);
  bloc.emit(
    RecitersLoaded(
      reciters: reciters,
      filteredReciters: filteredReciters ?? reciters,
      showFavoritesOnly: showFavoritesOnly,
      favoriteIds: favoriteIds,
      selectedLetter: selectedLetter,
    ),
  );
  return bloc;
}

/// Pumps the reciters screen through startup timers (intro tour delay, etc.).
Future<void> pumpRecitersScreen(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}
