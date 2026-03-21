import 'package:tilawa/test_support/screenutil_compat.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/prayer_times/domain/entities/entities.dart';
import 'package:tilawa/features/prayer_times/presentation/bloc/prayer_times_bloc.dart';
import 'package:tilawa/features/prayer_times/presentation/screens/prayer_times_screen.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';

class MockPrayerTimesBloc extends MockBloc<PrayerTimesEvent, PrayerTimesState>
    implements PrayerTimesBloc {}

void main() {
  late MockPrayerTimesBloc mockBloc;

  setUpAll(() async {
    await initializeDateFormatting('en', null);
    await initializeDateFormatting('ar', null);
  });

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
    maghrib: DateTime.now().add(const Duration(hours: 6)),
    isha: DateTime.now().add(const Duration(hours: 8)),
    midnight: DateTime.now().add(const Duration(hours: 12)),
    lastThird: DateTime.now().add(const Duration(hours: 15)),
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
      // test logic hidden
    }, skip: true);

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
      // test logic hidden
    }, skip: true);
  });
}
