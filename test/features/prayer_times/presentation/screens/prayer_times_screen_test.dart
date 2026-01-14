import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/prayer_times/domain/entities/entities.dart';
import 'package:tilawa/features/prayer_times/presentation/bloc/prayer_times_bloc.dart';
import 'package:tilawa/features/prayer_times/presentation/screens/prayer_times_screen.dart';
import 'package:tilawa/features/prayer_times/presentation/widgets/prayer_time_card.dart';
import 'package:tilawa/features/prayer_times/presentation/widgets/widgets.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';

class MockPrayerTimesBloc extends MockBloc<PrayerTimesEvent, PrayerTimesState>
    implements PrayerTimesBloc {}

void main() {
  late MockPrayerTimesBloc mockBloc;

  setUp(() {
    mockBloc = MockPrayerTimesBloc();
  });

  Widget createWidgetUnderTest() {
    return ScreenUtilPlusInit(
      designSize: const Size(375, 812),
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: BlocProvider<PrayerTimesBloc>.value(
          value: mockBloc,
          child: const PrayerTimesScreen(),
        ),
      ),
    );
  }

  final tPrayerTimes = PrayerTimeEntity(
    date: DateTime.now(),
    fajr: DateTime.now().add(const Duration(hours: 1)),
    sunrise: DateTime.now().add(const Duration(hours: 2)),
    dhuhr: DateTime.now().add(const Duration(hours: 5)),
    asr: DateTime.now().add(const Duration(hours: 8)),
    maghrib: DateTime.now().add(const Duration(hours: 11)),
    isha: DateTime.now().add(const Duration(hours: 13)),
    latitude: 30.0,
    longitude: 31.0,
    timezone: 'UTC',
  );

  group('PrayerTimesScreen', () {
    testWidgets('renders loading indicator when state is loading', (
      tester,
    ) async {
      when(
        () => mockBloc.state,
      ).thenReturn(const PrayerTimesState(status: PrayerTimesStatus.loading));

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders loaded state correctly', (tester) async {
      final PrayerTimeItem currentPrayer = tPrayerTimes.allPrayers[0]; // Fajr
      const timeUntil = Duration(hours: 1);

      when(() => mockBloc.state).thenReturn(
        PrayerTimesState(
          status: PrayerTimesStatus.loaded,
          todayPrayerTimes: tPrayerTimes,
          currentOrNextPrayer: currentPrayer,
          timeUntilNextPrayer: timeUntil,
          locationName: 'Cairo, Egypt',
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify header components
      expect(find.byType(PrayerTimesLocationHeader), findsOneWidget);
      expect(find.text('Cairo, Egypt'), findsOneWidget);

      // Verify countdown card
      expect(find.byType(NextPrayerCountdownCard), findsOneWidget);
      expect(find.byType(NextPrayerCountdownCard), findsOneWidget);

      // Verify list
      expect(find.byType(PrayerTimesList), findsOneWidget);
      expect(find.byType(PrayerTimeCard), findsWidgets);
    });

    testWidgets('renders error view when state is error', (tester) async {
      const errorMessage = 'Network error';
      when(() => mockBloc.state).thenReturn(
        const PrayerTimesState(
          status: PrayerTimesStatus.error,
          errorMessage: errorMessage,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text(errorMessage), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('renders location required view', (tester) async {
      when(() => mockBloc.state).thenReturn(
        const PrayerTimesState(status: PrayerTimesStatus.locationRequired),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.location_off), findsOneWidget);
    });

    testWidgets('tapping location header triggers updateLocation event', (
      tester,
    ) async {
      when(() => mockBloc.state).thenReturn(
        PrayerTimesState(
          status: PrayerTimesStatus.loaded,
          todayPrayerTimes: tPrayerTimes,
          locationName: 'Cairo',
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PrayerTimesLocationHeader));

      verify(
        () => mockBloc.add(const PrayerTimesEvent.updateLocation()),
      ).called(1);
    });
  });
}
