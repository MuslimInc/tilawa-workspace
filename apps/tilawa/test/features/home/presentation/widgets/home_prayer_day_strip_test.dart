import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/home/domain/entities/home_dashboard.dart';
import 'package:tilawa/features/home/domain/entities/home_prayer_slot.dart';
import 'package:tilawa/features/home/domain/repositories/home_dashboard_repository.dart';
import 'package:tilawa/features/home/domain/usecases/get_home_dashboard_use_case.dart';
import 'package:tilawa/features/home/presentation/bloc/home_dashboard_bloc.dart';
import 'package:tilawa/features/home/presentation/bloc/home_dashboard_event.dart';
import 'package:tilawa/features/home/presentation/widgets/home_prayer_day_strip.dart';
import 'package:tilawa/features/prayer_times/application/prayer_location_update_notifier.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/notify_prayer_location_updated_use_case.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  testWidgets('Arabic prayer chips do not overflow in the day strip', (
    tester,
  ) async {
    final view = tester.view;
    view.devicePixelRatio = 1;
    view.physicalSize = const Size(360, 640);
    addTearDown(view.resetDevicePixelRatio);
    addTearDown(view.resetPhysicalSize);

    var viewAllTapped = false;
    final bloc = HomeDashboardBloc(
      GetHomeDashboardUseCase(_ArabicPrayerStripRepository()),
      NotifyPrayerLocationUpdatedUseCase(PrayerLocationUpdateNotifier()),
    )..add(const HomeDashboardStarted(localeIdentifier: 'ar'));
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        home: BlocProvider.value(
          value: bloc,
          child: Scaffold(
            body: HomePrayerDayStrip(
              onOpenPrayer: () => viewAllTapped = true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    for (var frame = 0; frame < 20; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(tester.takeException(), isNull);
    expect(find.textContaining('الشروق'), findsOneWidget);
    expect(find.textContaining('الفجر'), findsOneWidget);

    await tester.tap(find.text('عرض الكل'));
    await tester.pump();
    expect(viewAllTapped, isTrue);
  });
}

class _ArabicPrayerStripRepository implements HomeDashboardRepository {
  @override
  Future<HomeDashboard> getDashboard({String? localeIdentifier}) async {
    return HomeDashboard(
      generatedAt: DateTime(2026, 6, 18, 1, 15),
      displayName: 'Muhammad Kamel',
      locationLabel: 'Al-Isawiya',
      nextPrayer: HomeNextPrayer(
        type: PrayerType.fajr,
        time: DateTime(2026, 6, 18, 4, 8),
        timeUntil: const Duration(hours: 2, minutes: 52),
      ),
      todayPrayers: [
        HomePrayerSlot(
          type: PrayerType.fajr,
          time: _fajr,
          isNext: true,
          hasPassed: false,
        ),
        HomePrayerSlot(
          type: PrayerType.sunrise,
          time: _sunrise,
          isNext: false,
          hasPassed: false,
        ),
        HomePrayerSlot(
          type: PrayerType.dhuhr,
          time: _dhuhr,
          isNext: false,
          hasPassed: false,
        ),
        HomePrayerSlot(
          type: PrayerType.asr,
          time: _asr,
          isNext: false,
          hasPassed: false,
        ),
        HomePrayerSlot(
          type: PrayerType.maghrib,
          time: _maghrib,
          isNext: false,
          hasPassed: false,
        ),
      ],
    );
  }

  @override
  Future<HomeDashboard> refreshLocation({String? localeIdentifier}) async {
    return getDashboard(localeIdentifier: localeIdentifier);
  }
}

final _fajr = _slotTime(4, 8);
final _sunrise = _slotTime(5, 30);
final _dhuhr = _slotTime(12, 45);
final _asr = _slotTime(16, 20);
final _maghrib = _slotTime(19, 5);

DateTime _slotTime(int hour, int minute) => DateTime(2026, 6, 18, hour, minute);
