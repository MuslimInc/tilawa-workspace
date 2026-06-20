import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/athkar/domain/entities/athkar_category.dart';
import 'package:tilawa/features/athkar/domain/entities/athkar_item.dart';
import 'package:tilawa/features/athkar/domain/entities/pinned_athkar_preference.dart';
import 'package:tilawa/features/athkar/domain/repositories/athkar_repository.dart';
import 'package:tilawa/features/athkar/domain/repositories/pinned_athkar_repository.dart';
import 'package:tilawa/features/athkar/domain/usecases/get_athkar_categories_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/get_pinned_athkar_preference_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/save_pinned_athkar_category_ids_use_case.dart';
import 'package:tilawa/features/athkar/presentation/cubit/pinned_athkar_cubit.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/home/domain/entities/home_dashboard.dart';
import 'package:tilawa/features/home/domain/repositories/home_dashboard_repository.dart';
import 'package:tilawa/features/home/domain/usecases/get_home_dashboard_use_case.dart';
import 'package:tilawa/features/home/presentation/bloc/home_dashboard_bloc.dart';
import 'package:tilawa/features/home/presentation/bloc/home_dashboard_event.dart';
import 'package:tilawa/features/home/presentation/cubit/home_quran_resume_cubit.dart';
import 'package:tilawa/features/home/presentation/screens/home_screen.dart';
import 'package:tilawa/features/home/presentation/widgets/home_daily_inspiration_section.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_hero_sliver.dart';
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

  testWidgets('Home contains no Reciters or Qibla shortcuts', (tester) async {
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

    // Removed navigation shortcuts must not appear
    expect(find.text('Reciters'), findsNothing);
    expect(find.text('Browse recitations'), findsNothing);
    expect(find.text('Qibla'), findsNothing);
    expect(find.text('Find prayer direction'), findsNothing);
    expect(find.text('Discover'), findsNothing);
    expect(find.text('Explore'), findsNothing);

    // Bottom-nav labels must not appear on Home
    expect(find.text('Home'), findsNothing);
    expect(find.text('Prayer'), findsNothing);
    expect(find.text('Athkar'), findsNothing);
    expect(find.text('Settings'), findsNothing);
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

  testWidgets('Home contains no prayer day strip', (tester) async {
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

    // The five-prayer pill strip was removed; hero owns prayer context
    expect(find.text('View all'), findsNothing);
    expect(find.text('عرض الكل'), findsNothing);
  });

  testWidgets('Daily ayah and dua block is present', (tester) async {
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

    expect(find.byType(HomeDailyInspirationSection), findsOneWidget);
    expect(find.text('Daily ayah'), findsOneWidget);
    expect(find.text('Daily dua'), findsOneWidget);
  });

  testWidgets('Quran module exposes reading and listening actions', (
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

    expect(find.text('Continue Reading'), findsOneWidget);
    expect(find.text('Continue Listening'), findsOneWidget);
  });

  testWidgets('Daily ayah appears below the Quran resume card', (
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

    await tester.ensureVisible(find.text('Daily ayah'));
    await tester.pump();

    expect(
      tester.getTopLeft(find.text('Daily ayah')).dy,
      greaterThan(tester.getTopLeft(find.text('Continue Reading')).dy),
    );
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
            create: (_) => PinnedAthkarCubit(
              GetAthkarCategoriesUseCase(_FakeAthkarRepository()),
              GetPinnedAthkarPreferenceUseCase(_FakePinnedAthkarRepository()),
              SavePinnedAthkarCategoryIdsUseCase(_FakePinnedAthkarRepository()),
            )..load(),
          ),
          BlocProvider(
            create: (_) =>
                HomeQuranResumeCubit(_FakeGetLastReadPosition())..load(),
          ),
          BlocProvider<AudioPlayerBloc>.value(value: audioPlayerBloc),
        ],
        child: Builder(
          builder: (context) => HomeScreen(onOpenPrayer: () {}),
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
    ]);
  }

  @override
  ResultFuture<List<AthkarItem>> getAthkarByCategory(int categoryId) async =>
      const Right([]);
}

class _FakePinnedAthkarRepository implements PinnedAthkarRepository {
  @override
  ResultFuture<PinnedAthkarPreference> getPreference() async {
    return const Right(
      PinnedAthkarPreference(categoryIds: [1, 2], isCustomized: false),
    );
  }

  @override
  ResultVoid saveCategoryIds(List<int> categoryIds) async => const Right(null);
}

class _FakeGetLastReadPosition implements GetLastReadPositionUseCase {
  @override
  Future<Either<Failure, ({int? surahNumber, int? ayahNumber, int? page})>>
  call() async {
    return const Right((surahNumber: 2, ayahNumber: 43, page: 42));
  }
}
