import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/home/domain/entities/home_dashboard.dart';
import 'package:tilawa/features/home/domain/repositories/home_dashboard_repository.dart';
import 'package:tilawa/features/home/domain/usecases/get_home_dashboard_use_case.dart';
import 'package:tilawa/features/home/presentation/bloc/home_dashboard_bloc.dart';
import 'package:tilawa/features/home/presentation/bloc/home_dashboard_event.dart';
import 'package:tilawa/features/home/presentation/screens/home_screen.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_hero_sliver.dart';
import 'package:tilawa/features/prayer_times/application/prayer_location_update_notifier.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/notify_prayer_location_updated_use_case.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
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
    await tester.pumpAndSettle();

    expect(find.byType(SliverPersistentHeader), findsOneWidget);

    final BuildContext homeContext = tester.element(find.byType(HomeScreen));
    final double collapseExtent = HomeDashboardHeroSliver.collapseScrollExtent(
      homeContext,
    );
    final scrollableFinder = find.descendant(
      of: find.byType(HomeScreen),
      matching: find.byType(Scrollable),
    );
    final scrollable = tester.state<ScrollableState>(scrollableFinder);
    final position = scrollable.position;

    position.jumpTo(collapseExtent * 0.5);
    await tester.pump();

    ScrollEndNotification(
      metrics: position,
      context: tester.element(scrollableFinder),
    ).dispatch(tester.element(scrollableFinder));

    await tester.pumpAndSettle();

    expect(position.pixels, closeTo(collapseExtent, 0.5));
    expect(tester.takeException(), isNull);
  });
}

class _HomeScreenHarness extends StatelessWidget {
  const _HomeScreenHarness({required this.bloc});

  final HomeDashboardBloc bloc;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
      home: BlocProvider.value(
        value: bloc,
        child: HomeScreen(
          onOpenReciters: () {},
          onOpenPrayer: () {},
          onOpenAthkar: () {},
          onOpenSettings: () {},
        ),
      ),
    );
  }
}

class _FakeHomeDashboardRepository implements HomeDashboardRepository {
  @override
  Future<HomeDashboard> getDashboard({String? localeIdentifier}) async {
    return _dashboard;
  }

  @override
  Future<HomeDashboard> refreshLocation({String? localeIdentifier}) async {
    return _dashboard;
  }
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
