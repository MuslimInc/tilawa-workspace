import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/prayer_times/domain/entities/entities.dart';
import 'package:tilawa/features/prayer_times/domain/prayer_times_clock.dart';
import 'package:tilawa/features/prayer_times/presentation/bloc/prayer_permissions_cubit.dart';
import 'package:tilawa/features/prayer_times/presentation/bloc/prayer_times_bloc.dart';
import 'package:tilawa/features/prayer_times/presentation/config/prayer_times_screen_loading_preview.dart';
import 'package:tilawa/features/prayer_times/presentation/screens/prayer_times_screen.dart';
import 'package:tilawa/features/quran_reader/presentation/theme/quran_reader_theme.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class MockPrayerTimesBloc extends Mock implements PrayerTimesBloc {}

class MockPrayerPermissionsCubit extends Mock
    implements PrayerPermissionsCubit {}

/// Fixed "now" so next prayer, countdown, and row states match baselines.
final DateTime _kGoldenNow = DateTime(2026, 5, 9, 20, 32, 15);

PrayerTimesState _goldenLoadedState() {
  final day = DateTime(2026, 5, 9);
  final times = PrayerTimeEntity(
    date: day,
    fajr: DateTime(2026, 5, 9, 4, 28),
    sunrise: DateTime(2026, 5, 9, 5, 50),
    dhuhr: DateTime(2026, 5, 9, 12, 15),
    asr: DateTime(2026, 5, 9, 15, 45),
    maghrib: DateTime(2026, 5, 9, 18, 10),
    isha: DateTime(2026, 5, 9, 21, 4),
    midnight: DateTime(2026, 5, 10, 0, 30),
    lastThird: DateTime(2026, 5, 10, 2, 15),
    latitude: 30.0,
    longitude: 31.0,
  );

  return PrayerTimesState(
    status: PrayerTimesStatus.loaded,
    todayPrayerTimes: times,
    settings: const PrayerSettingsEntity(
      use24HourFormat: false,
      showSunrise: false,
      savedLatitude: 30,
      savedLongitude: 31,
      savedLocationName: 'Neighborhood, Al Isaweyah',
      fajrNotification: PrayerNotificationSettings(mode: PrayerAlertMode.adhan),
      dhuhrNotification: PrayerNotificationSettings(
        mode: PrayerAlertMode.notification,
      ),
      asrNotification: PrayerNotificationSettings(mode: PrayerAlertMode.none),
      maghribNotification: PrayerNotificationSettings(
        mode: PrayerAlertMode.adhan,
      ),
      ishaNotification: PrayerNotificationSettings(
        mode: PrayerAlertMode.notification,
      ),
    ),
    latitude: 30,
    longitude: 31,
    locationName: 'Neighborhood, Al Isaweyah',
  );
}

// Goldens:
// - Loaded: `prayer_times_screen_light_*.png`
// - Loading preview (`PrayerTimesScreenLoadingPreview`): `prayer_times_screen_loading_light_*.png`
void main() {
  late MockPrayerTimesBloc mockPrayerTimesBloc;
  late MockPrayerPermissionsCubit mockPermissionsCubit;
  late GoRouter router;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useGoogleFonts = false;
    registerFallbackValue(const PrayerTimesEvent.loadPrayerTimes());
  });

  void bindGoldenRouter() {
    final goldenState = _goldenLoadedState();

    mockPrayerTimesBloc = MockPrayerTimesBloc();
    when(() => mockPrayerTimesBloc.close()).thenAnswer((_) async {});
    whenListen(
      mockPrayerTimesBloc,
      Stream<PrayerTimesState>.value(goldenState),
      initialState: goldenState,
    );

    mockPermissionsCubit = MockPrayerPermissionsCubit();
    when(() => mockPermissionsCubit.close()).thenAnswer((_) async {});
    whenListen(
      mockPermissionsCubit,
      Stream<PrayerPermissionsState>.value(const PrayerPermissionsState()),
      initialState: const PrayerPermissionsState(),
    );

    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider<PrayerTimesBloc>.value(value: mockPrayerTimesBloc),
              BlocProvider<PrayerPermissionsCubit>.value(
                value: mockPermissionsCubit,
              ),
            ],
            child: const PrayerTimesScreen(),
          ),
        ),
        GoRoute(
          path: '/qibla',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Qibla'))),
        ),
      ],
    );
  }

  Future<void> pumpGolden(WidgetTester tester, {required Locale locale}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(390, 844),
          devicePixelRatio: 1.0,
          disableAnimations: true,
        ),
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getLightTheme(
            primaryColor: PrimaryColorPreset.defaultPreset.value,
            density: TilawaDensity.comfortable,
            useGoogleFontsOverride: false,
            extensions: const [QuranReaderTheme.light],
          ),
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
  }

  group('PrayerTimesScreen loaded', () {
    setUp(() {
      PrayerTimesScreenLoadingPreview.debugOverride = null;
      PrayerTimesClock.overrideForTesting(() => _kGoldenNow);
      bindGoldenRouter();
    });

    tearDown(() {
      PrayerTimesClock.clearTestingOverride();
      PrayerTimesScreenLoadingPreview.debugOverride = null;
    });

    testWidgets('golden — English', (tester) async {
      await pumpGolden(tester, locale: const Locale('en'));

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/prayer_times_screen_light_en.png'),
      );
    });

    testWidgets('golden — Arabic', (tester) async {
      await pumpGolden(tester, locale: const Locale('ar'));

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/prayer_times_screen_light_ar.png'),
      );
    });
  });

  group('PrayerTimesScreen loading preview', () {
    setUp(() {
      PrayerTimesScreenLoadingPreview.debugOverride = true;
      PrayerTimesClock.overrideForTesting(() => _kGoldenNow);
      bindGoldenRouter();
    });

    tearDown(() {
      PrayerTimesClock.clearTestingOverride();
      PrayerTimesScreenLoadingPreview.debugOverride = null;
    });

    testWidgets('golden — English', (tester) async {
      await pumpGolden(tester, locale: const Locale('en'));

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/prayer_times_screen_loading_light_en.png'),
      );
    });

    testWidgets('golden — Arabic', (tester) async {
      await pumpGolden(tester, locale: const Locale('ar'));

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/prayer_times_screen_loading_light_ar.png'),
      );
    });
  });
}
