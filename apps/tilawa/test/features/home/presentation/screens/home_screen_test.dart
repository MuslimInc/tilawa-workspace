import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/history/domain/entities/history_entity.dart';
import 'package:tilawa/features/history/domain/repositories/history_repository.dart';
import 'package:tilawa/features/home/data/datasources/home_dashboard_memory_cache.dart';
import 'package:tilawa/features/home/domain/entities/home_dashboard.dart';
import 'package:tilawa/features/home/domain/entities/home_prayer_slot.dart';
import 'package:tilawa/features/home/domain/repositories/home_dashboard_repository.dart';
import 'package:tilawa/features/home/domain/usecases/get_home_dashboard_use_case.dart';
import 'package:tilawa/features/home/debug/home_skeleton_debug.dart';
import 'package:tilawa/features/home/presentation/bloc/home_dashboard_bloc.dart';
import 'package:tilawa/features/home/presentation/bloc/home_dashboard_event.dart';
import 'package:tilawa/features/home/presentation/cubit/home_listening_resume_cubit.dart';
import 'package:tilawa/features/home/presentation/screens/home_screen.dart';
import 'package:tilawa/features/home/presentation/widgets/home_next_prayer_time.dart';
import 'package:tilawa/features/quran_sessions/domain/entities/quran_sessions_platform_config.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_platform_config_store.dart';
import 'package:tilawa/features/home/presentation/widgets/home_daily_inspiration_section.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_body_skeleton.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_card.dart';
import 'package:tilawa/features/home/presentation/widgets/home_more_actions_group.dart';
import 'package:tilawa/features/home/presentation/widgets/home_primary_actions_section.dart';
import 'package:tilawa/features/home/presentation/widgets/home_quick_tools_section.dart';
import 'package:tilawa/features/prayer_times/application/prayer_location_update_notifier.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/notify_prayer_location_updated_use_case.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/screens/cubit/main_screen_cubit.dart';
import 'package:tilawa/screens/cubit/main_screen_state.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/features/home/presentation/cubit/home_learning_cubit.dart';
import 'package:tilawa/features/home/presentation/cubit/home_learning_state.dart';
import 'package:tilawa/features/settings/presentation/cubit/teacher_capability_cubit.dart';
import 'package:tilawa/features/settings/domain/services/teacher_capability_refresh_notifier.dart';
import 'package:tilawa/features/home/presentation/widgets/home_learning_cards.dart';

class _TestSharedPreferencesAsync implements SharedPreferencesAsync {
  @override
  Future<String?> getString(String key) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockGetCurrentUserTeacherCapabilityUseCase extends Mock
    implements GetCurrentUserTeacherCapabilityUseCase {}

class _MockTeacherCapabilityRefreshNotifier extends Mock
    implements TeacherCapabilityRefreshNotifier {}

class _MockAuthSessionProvider extends Mock implements AuthSessionProvider {}

class _MockHomeLearningCubit extends Mock implements HomeLearningCubit {}

class _MockTeacherCapabilityCubit extends Mock
    implements TeacherCapabilityCubit {}

void main() {
  setUp(() {
    if (!GetIt.I.isRegistered<SharedPreferencesAsync>()) {
      GetIt.I.registerSingleton<SharedPreferencesAsync>(
        _TestSharedPreferencesAsync(),
      );
    }
    if (!GetIt.I.isRegistered<AuthSessionProvider>()) {
      final mock = _MockAuthSessionProvider();
      when(() => mock.currentUserId).thenReturn('test_user');
      GetIt.I.registerSingleton<AuthSessionProvider>(mock);
    }
    if (!GetIt.I.isRegistered<GetCurrentUserTeacherCapabilityUseCase>()) {
      final mock = _MockGetCurrentUserTeacherCapabilityUseCase();
      when(() => mock.call(any())).thenAnswer(
        (_) async =>
            const Right(TeacherCapability(state: TeacherCapabilityState.none)),
      );
      GetIt.I.registerSingleton<GetCurrentUserTeacherCapabilityUseCase>(mock);
    }
    if (!GetIt.I.isRegistered<TeacherCapabilityRefreshNotifier>()) {
      final mock = _MockTeacherCapabilityRefreshNotifier();
      when(
        () => mock.onApplicationReviewed,
      ).thenAnswer((_) => const Stream.empty());
      GetIt.I.registerSingleton<TeacherCapabilityRefreshNotifier>(mock);
    }
    if (!GetIt.I.isRegistered<HomeLearningCubit>()) {
      final mock = _MockHomeLearningCubit();
      when(() => mock.state).thenReturn(
        const HomeLearningState(
          status: HomeLearningStatus.none,
          isInterestSignalNeeded: false,
        ),
      );
      when(() => mock.stream).thenAnswer((_) => const Stream.empty());
      when(
        () => mock.load(force: any(named: 'force')),
      ).thenAnswer((_) async {});
      when(mock.close).thenAnswer((_) async {});
      GetIt.I.registerSingleton<HomeLearningCubit>(mock);
    }
    if (!GetIt.I.isRegistered<TeacherCapabilityCubit>()) {
      final mock = _MockTeacherCapabilityCubit();
      when(() => mock.state).thenReturn(
        const SettingsTeacherCapabilityLoadState(
          isLoading: false,
          hasLoaded: true,
        ),
      );
      when(() => mock.stream).thenAnswer((_) => const Stream.empty());
      when(mock.load).thenAnswer((_) async {});
      when(mock.close).thenAnswer((_) async {});
      GetIt.I.registerSingleton<TeacherCapabilityCubit>(mock);
    }
  });

  tearDown(() async {
    HomeDashboardMemoryCache.shared.clear();
    if (GetIt.I.isRegistered<SharedPreferencesAsync>()) {
      await GetIt.I.unregister<SharedPreferencesAsync>();
    }
    if (GetIt.I.isRegistered<AuthSessionProvider>()) {
      await GetIt.I.unregister<AuthSessionProvider>();
    }
    if (GetIt.I.isRegistered<GetCurrentUserTeacherCapabilityUseCase>()) {
      await GetIt.I.unregister<GetCurrentUserTeacherCapabilityUseCase>();
    }
    if (GetIt.I.isRegistered<TeacherCapabilityRefreshNotifier>()) {
      await GetIt.I.unregister<TeacherCapabilityRefreshNotifier>();
    }
    if (GetIt.I.isRegistered<HomeLearningCubit>()) {
      await GetIt.I.unregister<HomeLearningCubit>();
    }
    if (GetIt.I.isRegistered<TeacherCapabilityCubit>()) {
      await GetIt.I.unregister<TeacherCapabilityCubit>();
    }
  });

  testWidgets('shows hero and body skeletons during the initial load', (
    tester,
  ) async {
    final repository = _PendingHomeDashboardRepository();
    final bloc = HomeDashboardBloc(
      GetHomeDashboardUseCase(repository),
      NotifyPrayerLocationUpdatedUseCase(PrayerLocationUpdateNotifier()),
    )..add(const HomeDashboardStarted(localeIdentifier: 'en'));
    addTearDown(bloc.close);
    // Runs before bloc.close (LIFO) so close never awaits a stuck handler.
    addTearDown(repository.release);

    await tester.pumpWidget(_HomeScreenHarness(bloc: bloc, locale: 'en'));
    await tester.pump();

    // One shimmer scope in the prayer hero, one in the dashboard body.
    expect(find.byType(TilawaSkeleton), findsNWidgets(2));
    expect(find.byType(HomeDashboardBodySkeleton), findsOneWidget);
    expect(find.byType(HomePrimaryActionsSection), findsNothing);
    expect(find.byType(HomeQuickToolsSection), findsNothing);

    // Completing the load swaps the skeletons for the real dashboard.
    repository.release();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    for (var frame = 0; frame < 5; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(find.byType(HomeDashboardBodySkeleton), findsNothing);
    expect(find.byType(TilawaSkeleton), findsNothing);
    expect(find.byType(HomePrimaryActionsSection), findsOneWidget);
    expect(find.byType(HomeQuickToolsSection), findsOneWidget);
  });

  testWidgets('debug force-skeleton toggle pins Home to the skeleton state', (
    tester,
  ) async {
    final bloc = HomeDashboardBloc(
      GetHomeDashboardUseCase(_FakeHomeDashboardRepository()),
      NotifyPrayerLocationUpdatedUseCase(PrayerLocationUpdateNotifier()),
    )..add(const HomeDashboardStarted(localeIdentifier: 'en'));
    addTearDown(bloc.close);
    addTearDown(() => HomeSkeletonDebug.forceSkeleton.value = false);

    await tester.pumpWidget(_HomeScreenHarness(bloc: bloc, locale: 'en'));
    await tester.pump();
    for (var frame = 0; frame < 30; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.byType(HomePrimaryActionsSection), findsOneWidget);

    HomeSkeletonDebug.forceSkeleton.value = true;
    await tester.pump();
    // Let the crossfade drop the outgoing real body.
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.byType(HomeDashboardBodySkeleton), findsOneWidget);
    expect(find.byType(HomePrimaryActionsSection), findsNothing);

    HomeSkeletonDebug.forceSkeleton.value = false;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    for (var frame = 0; frame < 5; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(find.byType(HomeDashboardBodySkeleton), findsNothing);
    expect(find.byType(HomePrimaryActionsSection), findsOneWidget);
  });

  testWidgets('keeps loaded content when a refresh is requested', (
    tester,
  ) async {
    final repository = _PendingRefreshHomeDashboardRepository();
    final useCase = GetHomeDashboardUseCase(
      repository,
      HomeDashboardMemoryCache(),
    );
    final bloc = HomeDashboardBloc(
      useCase,
      NotifyPrayerLocationUpdatedUseCase(PrayerLocationUpdateNotifier()),
    )..add(const HomeDashboardStarted(localeIdentifier: 'en'));
    addTearDown(bloc.close);

    await tester.pumpWidget(_HomeScreenHarness(bloc: bloc, locale: 'en'));
    await tester.pump();
    repository.completeInitialLoad();
    await tester.pump();
    for (var frame = 0; frame < 30; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.byType(HomePrimaryActionsSection), findsOneWidget);

    final Future<void> refreshFuture = bloc.refreshAndWait(
      localeIdentifier: 'en',
    );
    await tester.pump();

    expect(find.byType(HomeDashboardBodySkeleton), findsNothing);
    expect(find.byType(HomePrimaryActionsSection), findsOneWidget);
    expect(find.byType(TilawaSkeleton), findsNothing);

    repository.completeRefresh();
    await refreshFuture;
    await tester.pump();
    for (var frame = 0; frame < 5; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(find.byType(TilawaSkeleton), findsNothing);
    expect(find.byType(HomePrimaryActionsSection), findsOneWidget);
  });

  testWidgets('renders cached dashboard immediately without full shimmer', (
    tester,
  ) async {
    final cache = HomeDashboardMemoryCache();
    cache.write(_dashboard);
    final repository = _FakeHomeDashboardRepository();
    final bloc = HomeDashboardBloc(
      GetHomeDashboardUseCase(repository, cache),
      NotifyPrayerLocationUpdatedUseCase(PrayerLocationUpdateNotifier()),
    );
    addTearDown(bloc.close);

    bloc.add(const HomeDashboardStarted(localeIdentifier: 'en'));
    await tester.pump();

    await tester.pumpWidget(_HomeScreenHarness(bloc: bloc, locale: 'en'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(HomeDashboardBodySkeleton), findsNothing);
    expect(find.byType(HomePrimaryActionsSection), findsOneWidget);
    expect(find.byType(TilawaSkeleton), findsNothing);
  });

  testWidgets('offline cold start without cache shows failure not skeleton', (
    tester,
  ) async {
    final repository = _RefreshFailingHomeDashboardRepository()
      ..shouldFailInitialLoad = true;
    final bloc = HomeDashboardBloc(
      GetHomeDashboardUseCase(repository, HomeDashboardMemoryCache()),
      NotifyPrayerLocationUpdatedUseCase(PrayerLocationUpdateNotifier()),
    );
    addTearDown(bloc.close);

    bloc.add(const HomeDashboardStarted(localeIdentifier: 'en'));
    await tester.pumpWidget(_HomeScreenHarness(bloc: bloc, locale: 'en'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(HomeDashboardBodySkeleton), findsNothing);
    expect(
      find.text(
        "You're offline and we don't have saved prayer times yet. Reconnect and try again.",
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows offline snackbar when refresh fails on loaded content', (
    tester,
  ) async {
    final repository = _RefreshFailingHomeDashboardRepository();
    final bloc = HomeDashboardBloc(
      GetHomeDashboardUseCase(repository),
      NotifyPrayerLocationUpdatedUseCase(PrayerLocationUpdateNotifier()),
    )..add(const HomeDashboardStarted(localeIdentifier: 'en'));
    addTearDown(bloc.close);

    await tester.pumpWidget(_HomeScreenHarness(bloc: bloc, locale: 'en'));
    await tester.pump();
    for (var frame = 0; frame < 30; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.byType(HomePrimaryActionsSection), findsOneWidget);

    repository.shouldFailRefresh = true;
    await bloc.refreshAndWait(localeIdentifier: 'en');
    await tester.pump();
    await tester.pump();

    expect(find.byType(HomeDashboardBodySkeleton), findsNothing);
    expect(find.byType(HomePrimaryActionsSection), findsOneWidget);
    expect(
      find.text(
        "You're offline. Showing your last saved data.",
      ),
      findsOneWidget,
    );
  });

  testWidgets('home screen hero does not pin', (
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

    if (!getIt.isRegistered<AppLaunchConfig>()) {
      getIt.registerSingleton<AppLaunchConfig>(
        const AppLaunchConfig(),
      );
    }
    addTearDown(() async {
      if (getIt.isRegistered<AppLaunchConfig>()) {
        await getIt.unregister<AppLaunchConfig>();
      }
    });

    await tester.pumpWidget(_HomeScreenHarness(bloc: bloc));
    await tester.pump();
    for (var frame = 0; frame < 20; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(find.byType(SliverPersistentHeader), findsNothing);

    final BuildContext homeContext = tester.element(find.byType(HomeScreen));
    expect(HomeNextPrayerTime.collapseScrollExtent(homeContext), 0);
  });

  testWidgets('paints status bar chrome with bottom-nav surface color', (
    tester,
  ) async {
    const double topInset = 44;
    final bloc = HomeDashboardBloc(
      GetHomeDashboardUseCase(_FakeHomeDashboardRepository()),
      NotifyPrayerLocationUpdatedUseCase(PrayerLocationUpdateNotifier()),
    )..add(const HomeDashboardStarted(localeIdentifier: 'en'));
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(padding: EdgeInsets.only(top: topInset)),
        child: _HomeScreenHarness(bloc: bloc, locale: 'en'),
      ),
    );
    await tester.pump();
    for (var frame = 0; frame < 20; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    final Finder chrome = find.byKey(const Key('home_status_bar_chrome'));
    expect(chrome, findsOneWidget);

    final ColoredBox box = tester.widget<ColoredBox>(chrome);
    final ThemeData theme = AppTheme.getLightTheme(
      primaryColor: AppColors.defaultPrimary,
    );
    expect(
      box.color,
      theme.componentTokens.adaptiveShell.bottomNavBackgroundColor,
    );
    expect(tester.getSize(chrome).height, topInset);
  });

  testWidgets('keeps dashboard content below status bar chrome', (
    tester,
  ) async {
    const double topInset = 44;
    final bloc = HomeDashboardBloc(
      GetHomeDashboardUseCase(_FakeHomeDashboardRepository()),
      NotifyPrayerLocationUpdatedUseCase(PrayerLocationUpdateNotifier()),
    )..add(const HomeDashboardStarted(localeIdentifier: 'en'));
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(padding: EdgeInsets.only(top: topInset)),
        child: _HomeScreenHarness(bloc: bloc, locale: 'ar'),
      ),
    );
    await tester.pump();
    for (var frame = 0; frame < 30; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    final Offset heroTop = tester.getTopLeft(
      find.byType(HomeDashboardCard).first,
    );
    expect(heroTop.dy, greaterThanOrEqualTo(topInset));
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

    expect(find.text('Reciters'), findsOneWidget);
    // Shortcut tiles show only the label (no subtitle in the grid).
    expect(find.text('Listen to curated recitations'), findsNothing);
    expect(find.text("Today's prayer times"), findsNothing);
    expect(find.text('View all'), findsNothing);

    // Nav-duplicate tiles must not appear on Home.
    expect(find.text('Home'), findsNothing);
    expect(find.text('Settings'), findsNothing);
    expect(find.text('Prayer'), findsNothing);
    expect(find.text('Quran'), findsNothing);
    expect(find.text('Mushaf'), findsOneWidget);

    expect(find.text('Discover'), findsNothing);
    expect(find.text('Athkar'), findsOneWidget);
    expect(find.text('Qibla'), findsOneWidget);
    expect(find.text('Quick Actions'), findsNothing);
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

  testWidgets(
    'Home shows quick actions, more, and inspiration',
    (
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

      expect(find.byType(HomePrimaryActionsSection), findsOneWidget);
      expect(find.byType(HomeQuickToolsSection), findsOneWidget);
      expect(find.byType(HomeMoreActionsGroup), findsOneWidget);
      expect(find.byType(HomeDailyInspirationSection), findsOneWidget);

      final double primaryTop = tester
          .getTopLeft(find.byType(HomePrimaryActionsSection))
          .dy;
      final double toolsTop = tester
          .getTopLeft(find.byType(HomeQuickToolsSection))
          .dy;
      final double moreTop = tester
          .getTopLeft(find.byType(HomeMoreActionsGroup))
          .dy;
      final double inspirationTop = tester
          .getTopLeft(find.byType(HomeDailyInspirationSection))
          .dy;

      expect(primaryTop, lessThan(toolsTop));
      expect(toolsTop, lessThan(moreTop));
      expect(moreTop, lessThan(inspirationTop));

      // Old mismatched "Today" wrapper title must not appear.
      expect(find.text('Today'), findsNothing);
      // Quick actions keep supporting tools reachable.
      final l10n = AppLocalizations.of(
        tester.element(find.byType(HomeScreen)),
      );
      expect(find.text(l10n.homeQuickTasbeeh), findsOneWidget);
      expect(find.text(l10n.homeQuickReciters), findsOneWidget);
      expect(find.text(l10n.homeQuickQuranReader), findsOneWidget);
      expect(find.text(l10n.homeQuickQibla), findsOneWidget);
      // Bookmarks removed from Home.
      expect(find.text('Bookmarks'), findsNothing);
      // Nav-duplicate tiles must not appear on Home.
      expect(find.text('Prayer'), findsNothing);
      expect(find.text(l10n.homeQuickQuran), findsNothing);
    },
  );

  testWidgets(
    'featured tutor card scrolls away with content on small screen',
    (tester) async {
      final view = tester.view;
      view.devicePixelRatio = 1;
      view.physicalSize = const Size(360, 640);
      addTearDown(view.resetDevicePixelRatio);
      addTearDown(view.resetPhysicalSize);

      final bloc = HomeDashboardBloc(
        GetHomeDashboardUseCase(_FakeHomeDashboardRepository()),
        NotifyPrayerLocationUpdatedUseCase(PrayerLocationUpdateNotifier()),
      )..add(const HomeDashboardStarted(localeIdentifier: 'en'));
      addTearDown(bloc.close);

      if (!getIt.isRegistered<AppLaunchConfig>()) {
        getIt.registerSingleton<AppLaunchConfig>(
          const AppLaunchConfig(),
        );
      }
      // Feature flags fail closed without the runtime platform-config store —
      // register an enabled config so the featured tutor card renders.
      getIt.registerSingleton<QuranSessionsPlatformConfigStore>(
        QuranSessionsPlatformConfigStore()..setConfig(
          const QuranSessionsPlatformConfig(
            quranSessionsEnabled: true,
            studentEntryEnabled: true,
            bookingEnabled: true,
            bookingMode: 'requiresTutorApproval',
            sessionMode: 'videoOnly',
            enabledCallProviders: {'mock'},
            teacherApplicationEnabled: false,
            teacherApplicationEntryEnabled: false,
            homeTeacherApplicationCardEnabled: false,
            teacherApplicationDiscoverability: 'none',
          ),
        ),
      );
      addTearDown(() async {
        if (getIt.isRegistered<AppLaunchConfig>()) {
          await getIt.unregister<AppLaunchConfig>();
        }
        if (getIt.isRegistered<QuranSessionsPlatformConfigStore>()) {
          await getIt.unregister<QuranSessionsPlatformConfigStore>();
        }
      });

      final homeLearningCubit = getIt<HomeLearningCubit>();
      when(() => homeLearningCubit.state).thenReturn(
        const HomeLearningState(
          status: HomeLearningStatus.none,
          isInterestSignalNeeded: true,
        ),
      );

      await tester.pumpWidget(
        _HomeScreenHarness(
          bloc: bloc,
          locale: 'en',
          shellPadding: 80,
        ),
      );
      await tester.pump();
      for (var frame = 0; frame < 30; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      expect(find.byType(SliverPersistentHeader), findsNothing);
      expect(find.byType(HomeLearningInterestCard), findsOneWidget);

      final double scrollAmount = tester
          .getSize(find.byType(CustomScrollView))
          .height;
      await tester.drag(
        find.byType(CustomScrollView),
        Offset(0, -scrollAmount),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeLearningInterestCard), findsNothing);
    },
  );
}

class _MockAudioPlayerBloc extends MockCubit<AudioPlayerState>
    implements AudioPlayerBloc {}

class _MockMainScreenCubit extends MockCubit<MainScreenState>
    implements MainScreenCubit {}

class _HomeScreenHarness extends StatelessWidget {
  const _HomeScreenHarness({
    required this.bloc,
    this.locale = 'ar',
    this.shellPadding = 0,
  });

  final HomeDashboardBloc bloc;
  final String locale;
  final double shellPadding;

  @override
  Widget build(BuildContext context) {
    final audioPlayerBloc = _MockAudioPlayerBloc();
    when(() => audioPlayerBloc.state).thenReturn(
      const AudioPlayerState(status: AudioPlayerStatus.initial),
    );
    when(() => audioPlayerBloc.stream).thenAnswer(
      (_) => const Stream<AudioPlayerState>.empty(),
    );

    final mainScreenCubit = _MockMainScreenCubit();
    when(() => mainScreenCubit.state).thenReturn(const MainScreenState());
    when(() => mainScreenCubit.stream).thenAnswer(
      (_) => const Stream<MainScreenState>.empty(),
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
            create: (_) => HomeListeningResumeCubit(
              _FakeHistoryRepository(),
            )..load(),
          ),
          BlocProvider<AudioPlayerBloc>.value(value: audioPlayerBloc),
          BlocProvider<MainScreenCubit>.value(value: mainScreenCubit),
        ],
        child: TilawaShellPadding(
          padding: shellPadding,
          child: Builder(
            builder: (context) => HomeScreen(onOpenPrayer: () {}),
          ),
        ),
      ),
    );
  }
}

class _PendingRefreshHomeDashboardRepository
    implements HomeDashboardRepository {
  final Completer<HomeDashboard> _initialCompleter = Completer<HomeDashboard>();
  Completer<HomeDashboard>? _refreshCompleter;
  int _callCount = 0;

  void completeInitialLoad() {
    if (!_initialCompleter.isCompleted) {
      _initialCompleter.complete(_dashboard);
    }
  }

  void completeRefresh() {
    final Completer<HomeDashboard>? refreshCompleter = _refreshCompleter;
    if (refreshCompleter != null && !refreshCompleter.isCompleted) {
      refreshCompleter.complete(_dashboard);
    }
  }

  @override
  Future<HomeDashboard> getDashboard({String? localeIdentifier}) {
    _callCount++;
    if (_callCount == 1) {
      return _initialCompleter.future;
    }
    _refreshCompleter ??= Completer<HomeDashboard>();
    return _refreshCompleter!.future;
  }

  @override
  Future<HomeDashboard> refreshLocation({String? localeIdentifier}) async =>
      _dashboard;
}

class _FakeHomeDashboardRepository implements HomeDashboardRepository {
  @override
  Future<HomeDashboard> getDashboard({String? localeIdentifier}) async =>
      _dashboard;

  @override
  Future<HomeDashboard> refreshLocation({String? localeIdentifier}) async =>
      _dashboard;
}

class _RefreshFailingHomeDashboardRepository
    implements HomeDashboardRepository {
  bool shouldFailRefresh = false;
  bool shouldFailInitialLoad = false;
  int _callCount = 0;

  @override
  Future<HomeDashboard> getDashboard({String? localeIdentifier}) async {
    _callCount++;
    if (shouldFailInitialLoad && _callCount == 1) {
      throw Exception(
        'SocketException: Failed host lookup: example.com',
      );
    }
    if (shouldFailRefresh && _callCount > 1) {
      throw Exception(
        'SocketException: Failed host lookup: example.com',
      );
    }
    return _dashboard;
  }

  @override
  Future<HomeDashboard> refreshLocation({String? localeIdentifier}) async =>
      _dashboard;
}

/// Holds the dashboard load in-flight until [release] completes it.
///
/// Always release (directly or via `addTearDown`) before closing the bloc:
/// [HomeDashboardBloc.close] awaits the active event handler, so a
/// never-completing future would hang the test until its timeout.
class _PendingHomeDashboardRepository implements HomeDashboardRepository {
  final Completer<HomeDashboard> _completer = Completer<HomeDashboard>();

  void release() {
    if (!_completer.isCompleted) {
      _completer.complete(_dashboard);
    }
  }

  @override
  Future<HomeDashboard> getDashboard({String? localeIdentifier}) =>
      _completer.future;

  @override
  Future<HomeDashboard> refreshLocation({String? localeIdentifier}) =>
      _completer.future;
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
