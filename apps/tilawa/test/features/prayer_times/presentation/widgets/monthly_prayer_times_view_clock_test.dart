import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/prayer_times/domain/entities/entities.dart';
import 'package:tilawa/features/prayer_times/domain/prayer_times_clock.dart';
import 'package:tilawa/features/prayer_times/presentation/bloc/prayer_times_bloc.dart';
import 'package:tilawa/features/prayer_times/presentation/widgets/monthly_prayer_times_view.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class _MockPrayerTimesBloc extends Mock implements PrayerTimesBloc {}

void main() {
  setUpAll(() {
    registerFallbackValue(const PrayerTimesEvent.loadPrayerTimes());
  });

  tearDown(PrayerTimesClock.clearTestingOverride);

  testWidgets('loads the current month from PrayerTimesClock', (tester) async {
    PrayerTimesClock.overrideForTesting(() => DateTime(2030, 2, 14, 9));

    final bloc = _MockPrayerTimesBloc();
    when(bloc.close).thenAnswer((_) async {});
    when(() => bloc.add(any())).thenReturn(null);
    when(
      () => bloc.stream,
    ).thenAnswer((_) => const Stream<PrayerTimesState>.empty());
    when(() => bloc.state).thenReturn(
      PrayerTimesState(
        status: PrayerTimesStatus.loaded,
        monthlyPrayerTimes: [_prayerDay(DateTime(2030, 2, 14))],
        settings: const PrayerSettingsEntity(use24HourFormat: true),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(
          primaryColor: PrimaryColorPreset.defaultPreset.value,
        ),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: BlocProvider<PrayerTimesBloc>.value(
          value: bloc,
          child: Scaffold(
            body: NestedScrollView(
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
                    return [
                      SliverOverlapAbsorber(
                        handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                          context,
                        ),
                        sliver: const SliverAppBar(
                          pinned: true,
                          automaticallyImplyLeading: false,
                          toolbarHeight: 0,
                        ),
                      ),
                    ];
                  },
              body: const MonthlyPrayerTimesView(latitude: 30, longitude: 31),
            ),
          ),
        ),
      ),
    );

    verify(
      () => bloc.add(
        const PrayerTimesEvent.loadMonthlyPrayerTimes(year: 2030, month: 2),
      ),
    ).called(1);
  });
}

PrayerTimeEntity _prayerDay(DateTime date) {
  return PrayerTimeEntity(
    date: date,
    fajr: date.copyWith(hour: 5),
    sunrise: date.copyWith(hour: 6),
    dhuhr: date.copyWith(hour: 12),
    asr: date.copyWith(hour: 15),
    maghrib: date.copyWith(hour: 18),
    isha: date.copyWith(hour: 20),
    midnight: date.copyWith(hour: 23),
    lastThird: date.add(const Duration(days: 1)).copyWith(hour: 2),
    latitude: 30,
    longitude: 31,
  );
}
