import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_settings_entity.dart';
import 'package:tilawa/features/prayer_times/presentation/bloc/prayer_permissions_cubit.dart';
import 'package:tilawa/features/prayer_times/presentation/bloc/prayer_times_bloc.dart';
import 'package:tilawa/features/prayer_times/presentation/widgets/prayer_notification_settings_sheet.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';

import 'prayer_notification_settings_sheet_test.mocks.dart';

@GenerateMocks([PrayerTimesBloc, PrayerPermissionsCubit])
void main() {
  group('PrayerNotificationSettingsSheet', () {
    late MockPrayerTimesBloc mockBloc;
    late MockPrayerPermissionsCubit mockPermissionsCubit;

    setUp(() {
      mockBloc = MockPrayerTimesBloc();
      mockPermissionsCubit = MockPrayerPermissionsCubit();

      when(mockBloc.state).thenReturn(
        const PrayerTimesState(
          settings: PrayerSettingsEntity(),
        ),
      );
      when(mockBloc.stream).thenAnswer((_) => const Stream.empty());

      when(mockPermissionsCubit.state).thenReturn(const PrayerPermissionsState());
      when(mockPermissionsCubit.stream).thenAnswer((_) => const Stream.empty());
    });

    Widget buildSubject() {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<PrayerTimesBloc>.value(value: mockBloc),
            BlocProvider<PrayerPermissionsCubit>.value(value: mockPermissionsCubit),
          ],
          child: const Scaffold(
            body: PrayerNotificationSettingsSheet(),
          ),
        ),
      );
    }

    testWidgets('renders all prayer names', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Fajr'), findsOneWidget);
      expect(find.text('Dhuhr'), findsOneWidget);
      expect(find.text('Asr'), findsOneWidget);
      expect(find.text('Maghrib'), findsOneWidget);
      expect(find.text('Isha'), findsOneWidget);
    });

    testWidgets('renders global toggles', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('All Prayer Notifications'), findsOneWidget);
      expect(find.text('Play Adhan'), findsOneWidget);
    });

    testWidgets('renders close button', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });
}
