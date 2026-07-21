import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/prayer_times/domain/value_objects/prayer_alarm_capability.dart';
import 'package:tilawa/features/prayer_times/presentation/bloc/prayer_permissions_cubit.dart';
import 'package:tilawa/features/prayer_times/presentation/widgets/prayer_alerts_permission_flow.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../fakes/fake_prayer_permissions_cubit.dart';

void main() {
  testWidgets('shows step progress and soft notification copy', (tester) async {
    final FakePrayerPermissionsCubit cubit = FakePrayerPermissionsCubit(
      const PrayerPermissionsState(
        hasLocationPermission: true,
        capability: PrayerAlarmCapability(
          canScheduleExact: true,
          hasNotificationPermission: false,
        ),
      ),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(
          primaryColor: PrimaryColorPreset.defaultPreset.value,
        ),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<PrayerPermissionsCubit>.value(
          value: cubit,
          child: PrayerAlertsPermissionFlow(
            steps: const <PrayerAlertsPermissionStep>[
              PrayerAlertsPermissionStep.notifications,
              PrayerAlertsPermissionStep.exactAlarm,
            ],
            onFinished: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(
      find.text(l10n.prayerAlertsPermissionStepProgress(1, 2)),
      findsOneWidget,
    );
    expect(
      find.text(l10n.prayerAlertsPermissionNotificationsBody),
      findsOneWidget,
    );
    expect(
      l10n.prayerAlertsPermissionNotificationsBody.toLowerCase(),
      isNot(contains('never miss')),
    );
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });
}
