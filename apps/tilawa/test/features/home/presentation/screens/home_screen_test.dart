import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/athkar/data/datasources/athkar_daily_progress_local_datasource.dart';
import 'package:tilawa/features/athkar/domain/entities/athkar_category.dart';
import 'package:tilawa/features/athkar/domain/entities/athkar_item.dart';
import 'package:tilawa/features/athkar/domain/repositories/athkar_repository.dart';
import 'package:tilawa/features/athkar/domain/usecases/get_athkar_by_category_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/get_athkar_categories_use_case.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/history/domain/entities/history_entity.dart';
import 'package:tilawa/features/history/domain/repositories/history_repository.dart';
import 'package:tilawa/features/home/domain/entities/home_dashboard.dart';
import 'package:tilawa/features/home/domain/entities/home_prayer_slot.dart';
import 'package:tilawa/features/home/domain/repositories/home_dashboard_repository.dart';
import 'package:tilawa/features/home/domain/usecases/get_home_dashboard_use_case.dart';
import 'package:tilawa/features/home/presentation/bloc/home_dashboard_bloc.dart';
import 'package:tilawa/features/home/presentation/bloc/home_dashboard_event.dart';
import 'package:tilawa/features/home/presentation/cubit/home_athkar_compact_cubit.dart';
import 'package:tilawa/features/home/presentation/cubit/home_listening_resume_cubit.dart';
import 'package:tilawa/features/home/presentation/cubit/home_primary_action_cubit.dart';
import 'package:tilawa/features/home/presentation/widgets/home_primary_action_zone.dart';
import 'package:tilawa/features/home/presentation/cubit/home_quran_resume_cubit.dart';
import 'package:tilawa/features/home/presentation/screens/home_screen.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_hero_sliver.dart';
import 'package:tilawa/features/home/presentation/widgets/home_daily_ayah_card.dart';
import 'package:tilawa/features/home/presentation/widgets/home_primary_action_card.dart';
import 'package:tilawa/features/quran_reader/domain/usecases/get_last_read_position_use_case.dart';
import 'package:tilawa/features/prayer_times/application/prayer_location_update_notifier.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/notify_prayer_location_updated_use_case.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/utils/typedefs.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  testWidgets('settles a partial home hero collapse to the pinned state', (
    tester,
  ) async {
    final view = tester.view;
    view.devicePixelRatio = 1;
    view.physicalSize = const Size(360, 640);
    addTearDown(view.resetDevicePixelRatio);
    addTearDown(view.resetPhysicalSize);

    final bloc = HomeDashboardBloc(
      GetHomeDashboardUseCase(_FakeHomeDashboardRepository()),
      NotifyPrayerLocationUpdatedUseCase(PrayerLocationUpdateNotifier()),
    )..add(const HomeDashboardStarted(localeIdentifier: 'ar'));
    addTearDown(bloc.close);

    await tester.pumpWidget(_HomeScreenHarness(bloc: bloc));
    await tester.pump();
    for (var frame = 0; frame < 20; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(find.byType(SliverPersistentHeader), findsOneWidget);

    final BuildContext homeContext = tester.element(find.byType(HomeScreen));
    final double collapseExtent = HomeDashboardHeroSliver.collapseScrollExtent(
      homeContext,
    );
    final scrollableFinder = find
        .descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(Scrollable),
        )
        .first;
    final scrollable = tester.state<ScrollableState>(scrollableFinder);
    final position = scrollable.position;

    position.jumpTo(collapseExtent * 0.5);
    await tester.pump();

    ScrollEndNotification(
      metrics: position,
      context: tester.element(scrollableFinder),
    ).dispatch(tester.element(scrollableFinder));

    await tester.pump();
    for (var frame = 0; frame < 50; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      if ((position.pixels - collapseExtent).abs() < 0.5) {
        break;
      }
    }

    expect(position.pixels, closeTo(collapseExtent, 0.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home avoids bottom-nav duplicate shortcuts', (tester) async {
    final bloc = HomeDashboardBloc(
      GetHomeDashboardUseCase(_FakeHomeDashboardRepository()),
      NotifyPrayerLocationUpdatedUseCase(PrayerLocationUpdateNotifier()),
    )..add(const HomeDashboardStarted(localeIdentifier: 'en'));
    addTearDown(bloc.close);

    await tester.pumpWidget(_HomeScreenHarness(bloc: bloc, locale: 'en'));
    await tester.pump();
    for (var frame = 0; frame < 30; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(find.text('Reciters'), findsNothing);
    expect(find.text('Browse recitations'), findsNothing);
    expect(find.text('Quick athkar'), findsNothing);
    expect(find.text("Today's prayer times"), findsNothing);
    expect(find.text('View all'), findsNothing);

    expect(find.text('Home'), findsNothing);
    expect(find.text('Settings'), findsNothing);

    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('Athkar'), findsWidgets);
    expect(find.text('Qibla'), findsWidgets);
  });

  testWidgets('Home contains no layout toggle button', (tester) async {
    final bloc = HomeDashboardBloc(
      GetHomeDashboardUseCase(_FakeHomeDashboardRepository()),
      NotifyPrayerLocationUpdatedUseCase(PrayerLocationUpdateNotifier()),
    )..add(const HomeDashboardStarted(localeIdentifier: 'en'));
    addTearDown(bloc.close);

    await tester.pumpWidget(_HomeScreenHarness(bloc: bloc, locale: 'en'));
    await tester.pump();
    for (var frame = 0; frame < 30; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(find.byIcon(Icons.grid_view_rounded), findsNothing);
    expect(find.byIcon(Icons.view_list_rounded), findsNothing);
  });

  testWidgets('Home shows today ayah, primary action, and feature hub', (
    tester,
  ) async {
    final bloc = HomeDashboardBloc(
      GetHomeDashboardUseCase(_FakeHomeDashboardRepository()),
      NotifyPrayerLocationUpdatedUseCase(PrayerLocationUpdateNotifier()),
    )..add(const HomeDashboardStarted(localeIdentifier: 'en'));
    addTearDown(bloc.close);

    await tester.pumpWidget(_HomeScreenHarness(bloc: bloc, locale: 'en'));
    await tester.pump();
    for (var frame = 0; frame < 30; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yours'), findsNothing);
    expect(find.byType(HomeDailyAyahCard), findsOneWidget);
    expect(find.byType(HomePrimaryActionCard), findsOneWidget);
    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('Tasbeeh'), findsWidgets);
    expect(find.text('Bookmarks'), findsOneWidget);
  });
}

class _MockAudioPlayerBloc extends MockCubit<AudioPlayerState>
    implements AudioPlayerBloc {}

class _HomeScreenHarness extends StatelessWidget {
  const _HomeScreenHarness({required this.bloc, this.locale = 'ar'});

  final HomeDashboardBloc bloc;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final audioPlayerBloc = _MockAudioPlayerBloc();
    when(() => audioPlayerBloc.state).thenReturn(
      const AudioPlayerState(status: AudioPlayerStatus.initial),
    );
    when(() => audioPlayerBloc.stream).thenAnswer(
      (_) => const Stream<AudioPlayerState>.empty(),
    );

    return MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
      home: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: bloc),
          BlocProvider(
            create: (_) => HomeQuranResumeCubit(
              _FakeGetLastReadPosition(),
              _FakeHistoryRepository(),
            )..load(),
          ),
          BlocProvider(
            create: (_) => HomeListeningResumeCubit(
              _FakeHistoryRepository(),
            )..load(),
          ),
          BlocProvider(
            create: (_) => HomeAthkarCompactCubit(
              GetAthkarCategoriesUseCase(_FakeAthkarRepository()),
              GetAthkarByCategoryUseCase(_FakeAthkarRepository()),
              _FakeAthkarDailyProgressLocalDataSource(),
            )..load(),
          ),
          BlocProvider(create: (_) => HomePrimaryActionCubit()),
          BlocProvider<AudioPlayerBloc>.value(value: audioPlayerBloc),
        ],
        child: HomePrimaryActionSyncListener(
          child: Builder(
            builder: (context) => HomeScreen(onOpenPrayer: () {}),
          ),
        ),
      ),
    );
  }
}

class _FakeHomeDashboardRepository implements HomeDashboardRepository {
  @override
  Future<HomeDashboard> getDashboard({String? localeIdentifier}) async =>
      _dashboard;

  @override
  Future<HomeDashboard> refreshLocation({String? localeIdentifier}) async =>
      _dashboard;
}

final HomeDashboard _dashboard = HomeDashboard(
  generatedAt: DateTime(2026, 6, 16, 18, 25),
  displayName: 'Muhammad Kamel',
  locationLabel: 'Cairo',
  nextPrayer: HomeNextPrayer(
    type: PrayerType.maghrib,
    time: DateTime.now().add(const Duration(hours: 1, minutes: 35)),
    timeUntil: const Duration(hours: 1, minutes: 35),
  ),
  todayPrayers: [
    HomePrayerSlot(
      type: PrayerType.fajr,
      time: DateTime(2026, 6, 16, 4, 8),
      isNext: false,
      hasPassed: true,
    ),
    HomePrayerSlot(
      type: PrayerType.maghrib,
      time: DateTime(2026, 6, 16, 20, 0),
      isNext: true,
      hasPassed: false,
    ),
  ],
);

class _FakeAthkarRepository implements AthkarRepository {
  @override
  ResultFuture<List<AthkarCategory>> getCategories() async {
    return const Right([
      AthkarCategory(
        id: 1,
        nameAr: 'أذكار الصباح',
        nameEn: 'Morning Athkar',
        icon: 'wb_sunny_rounded',
      ),
      AthkarCategory(
        id: 2,
        nameAr: 'أذكار المساء',
        nameEn: 'Evening Athkar',
        icon: 'nights_stay_rounded',
      ),
      AthkarCategory(
        id: 3,
        nameAr: 'أذكار النوم',
        nameEn: 'Sleep Athkar',
        icon: 'bedtime_rounded',
      ),
    ]);
  }

  @override
  ResultFuture<List<AthkarItem>> getAthkarByCategory(int categoryId) async {
    return Right([
      AthkarItem(
        id: categoryId * 10,
        categoryId: categoryId,
        textAr: 'test',
        textEn: 'test',
        count: 3,
        reference: 'ref',
      ),
    ]);
  }
}

class _FakeAthkarDailyProgressLocalDataSource
    implements AthkarDailyProgressLocalDataSource {
  @override
  Future<Map<int, int>> loadCounts({
    required int categoryId,
    required String dateKey,
  }) async => const {};

  @override
  Future<void> saveCounts({
    required int categoryId,
    required String dateKey,
    required Map<int, int> remainingCounts,
  }) async {}
}

class _FakeHistoryRepository implements HistoryRepository {
  @override
  Future<List<HistoryEntity>> getRecentHistory({int limit = 20}) async => [];

  @override
  Future<List<HistoryEntity>> getAllHistory() async => [];

  @override
  Future<HistoryEntity> addOrUpdateHistory({
    required int surahId,
    required String surahName,
    required String surahNameEn,
    required String reciterId,
    required String reciterName,
    required int moshafId,
    required String moshafName,
    required int lastPositionMs,
    required int durationMs,
    required String audioUrl,
    String? artworkUrl,
    bool completed = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteAllHistory() async {}

  @override
  Future<void> deleteHistory(String id) async {}

  @override
  Future<HistoryEntity?> getHistoryById(String id) async => null;

  @override
  Future<List<HistoryEntity>> getHistoryByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async => [];

  @override
  Future<List<HistoryEntity>> getHistoryByReciter(String reciterId) async => [];

  @override
  Future<HistoryEntity?> updateLastPosition({
    required String id,
    required int lastPositionMs,
    bool? completed,
  }) async => null;

  @override
  Future<void> deleteHistoryOlderThan(DateTime date) async {}

  @override
  Future<List<HistoryEntity>> searchHistory(String query) async => [];

  @override
  Future<int> getHistoryCount() async => 0;

  @override
  Future<int> getTotalListeningTime() async => 0;

  @override
  Future<List<HistoryEntity>> getMostPlayedSurahs({int limit = 10}) async => [];

  @override
  Future<bool> hasBeenPlayed({
    required int surahId,
    required String reciterId,
    required int moshafId,
  }) async => false;
}

class _FakeGetLastReadPosition implements GetLastReadPositionUseCase {
  @override
  Future<Either<Failure, ({int? surahNumber, int? ayahNumber, int? page})>>
  call() async {
    return const Right((surahNumber: 2, ayahNumber: 43, page: 42));
  }
}
