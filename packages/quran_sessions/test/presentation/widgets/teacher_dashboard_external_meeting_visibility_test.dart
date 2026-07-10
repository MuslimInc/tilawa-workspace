import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations_en.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../helpers/availability_test_helpers.dart';
import '../../helpers/fakes/fake_availability_provider.dart';
import '../../helpers/fakes/fake_booked_slot_lock_repository.dart';
import '../../helpers/fakes/fake_session_repository.dart';
import '../../helpers/lifecycle_test_helpers.dart';

void main() {
  late FakeSessionRepository sessionRepo;
  late FakeScheduleRepository scheduleRepo;
  late SpyGetTeacherAvailabilityUseCase spyGetAvailability;

  final fixedNow = DateTime.utc(2026, 1, 9);

  setUpAll(() async {
    tz_data.initializeTimeZones();
    await initializeDateFormatting('en');
  });

  setUp(() {
    sessionRepo = FakeSessionRepository();
    scheduleRepo = FakeScheduleRepository()..schedule = makeWeeklySchedule();
    spyGetAvailability = SpyGetTeacherAvailabilityUseCase(
      scheduleRepository: scheduleRepo,
      bookedSlotLocks: FakeBookedSlotLockRepository(),
      now: () => fixedNow,
    );
  });

  TeacherDashboardBloc buildBloc() {
    return buildTestTeacherDashboardBloc(
      sessionRepo: sessionRepo,
      getAvailability: spyGetAvailability,
      blockGeneratedSlot: BlockGeneratedSlotUseCase(scheduleRepo),
      availabilityProvider: FakeAvailabilityProvider(),
      cancelSession: buildCancelSessionViaServerUseCase(),
      completeSession: buildCompleteSessionViaServerUseCase(),
      scheduleRepo: scheduleRepo,
      now: () => fixedNow,
    );
  }

  Future<void> pumpDashboard(
    WidgetTester tester, {
    required TeacherDashboardBloc bloc,
    WidgetBuilder? meetingUrlSettingsBuilder,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        localizationsDelegates: const [
          ...QuranSessionsLocalizations.localizationsDelegates,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: QuranSessionsLocalizations.supportedLocales,
        home: BlocProvider<TeacherDashboardBloc>.value(
          value: bloc,
          child: TeacherDashboardScreen(
            teacherId: 'teacher_1',
            meetingUrlSettingsBuilder: meetingUrlSettingsBuilder,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('TeacherDashboardScreen external meeting settings', () {
    testWidgets('hides app bar link when meetingUrlSettingsBuilder is null', (
      tester,
    ) async {
      final bloc = buildBloc();
      final l10n = QuranSessionsLocalizationsEn();

      await pumpDashboard(tester, bloc: bloc);

      expect(find.byIcon(Icons.link_outlined), findsNothing);
      expect(find.byTooltip(l10n.teacherExternalMeetingUrlLabel), findsNothing);
    });

    testWidgets('shows app bar link when meetingUrlSettingsBuilder is set', (
      tester,
    ) async {
      final bloc = buildBloc();
      final l10n = QuranSessionsLocalizationsEn();

      await pumpDashboard(
        tester,
        bloc: bloc,
        meetingUrlSettingsBuilder: (_) => const SizedBox.shrink(),
      );

      expect(find.byIcon(Icons.link_outlined), findsOneWidget);
      expect(
        find.byTooltip(l10n.teacherExternalMeetingUrlLabel),
        findsOneWidget,
      );
    });
  });
}
