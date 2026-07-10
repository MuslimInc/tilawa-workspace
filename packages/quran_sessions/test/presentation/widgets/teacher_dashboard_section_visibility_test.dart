import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations_ar.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations_en.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:quran_sessions/src/presentation/widgets/teacher_dashboard_summary_stats.dart';
import 'package:quran_sessions/src/presentation/widgets/tutor_dashboard_section.dart';
import 'package:quran_sessions/src/presentation/widgets/tutor_session_compact_card.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../helpers/availability_test_helpers.dart';
import '../../helpers/fakes/fake_availability_provider.dart';
import '../../helpers/fakes/fake_booked_slot_lock_repository.dart';
import '../../helpers/fakes/fake_session_repository.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/lifecycle_test_helpers.dart';

void main() {
  late FakeSessionRepository sessionRepo;
  late FakeScheduleRepository scheduleRepo;
  late SpyGetTeacherAvailabilityUseCase spyGetAvailability;

  final fixedNow = DateTime.utc(2026, 1, 9);

  setUpAll(() async {
    tz_data.initializeTimeZones();
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
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
    Locale locale = const Locale('en'),
    TextDirection textDirection = TextDirection.ltr,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        locale: locale,
        localizationsDelegates: const [
          ...QuranSessionsLocalizations.localizationsDelegates,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: QuranSessionsLocalizations.supportedLocales,
        home: Directionality(
          textDirection: textDirection,
          child: BlocProvider<TeacherDashboardBloc>.value(
            value: bloc,
            child: const TeacherDashboardScreen(teacherId: 'teacher_1'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('TeacherDashboardScreen section visibility', () {
    testWidgets('shows compact category overview instead of long sections', (
      tester,
    ) async {
      final bloc = buildBloc();
      final l10n = QuranSessionsLocalizationsEn();

      await pumpDashboard(tester, bloc: bloc);

      expect(find.byType(TeacherDashboardSummaryStats), findsOneWidget);
      expect(find.text(l10n.teacherDashboardCategoriesTitle), findsOneWidget);
      expect(
        find.text(l10n.teacherPendingBookingRequestsSectionTitle),
        findsOneWidget,
      );
      expect(find.text(l10n.upcomingSessionsSectionTitle), findsWidgets);
      expect(find.text(l10n.bookableTimesWeekScopedTitle), findsOneWidget);
      expect(find.byType(TutorSessionCompactCard), findsNothing);
      expect(find.byType(TutorDashboardSection), findsNothing);
    });

    testWidgets('opens booking requests on a separate category screen', (
      tester,
    ) async {
      sessionRepo.sessions = [
        makeSession(
          lifecycleStatus: SessionLifecycleStatus.pendingTutorApproval,
        ),
      ];
      final bloc = buildBloc();
      final l10n = QuranSessionsLocalizationsEn();

      await pumpDashboard(tester, bloc: bloc);

      expect(find.byType(TutorSessionCompactCard), findsNothing);
      expect(
        find.text(l10n.teacherPendingBookingRequestsSectionTitle),
        findsOneWidget,
      );

      await tester.tap(
        find.text(l10n.teacherPendingBookingRequestsSectionTitle),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TutorSessionCompactCard), findsOneWidget);
      expect(find.text(l10n.teacherAcceptBookingRequest), findsOneWidget);
      expect(find.text(l10n.teacherRejectBookingRequest), findsOneWidget);
    });

    testWidgets('toggles category overview between grid and list layouts', (
      tester,
    ) async {
      final bloc = buildBloc();
      final l10n = QuranSessionsLocalizationsEn();

      await pumpDashboard(tester, bloc: bloc);

      expect(
        find.text(l10n.teacherDashboardOpenCategory),
        findsNWidgets(3),
      );

      await tester.tap(find.byIcon(Icons.view_list_rounded));
      await tester.pumpAndSettle();

      expect(find.text(l10n.teacherDashboardOpenCategory), findsNothing);
      expect(
        find.text(l10n.teacherPendingBookingRequestsSectionTitle),
        findsOneWidget,
      );
    });

    testWidgets('Arabic rtl keeps category overview scannable', (
      tester,
    ) async {
      final bloc = buildBloc();
      final l10n = QuranSessionsLocalizationsAr();

      await pumpDashboard(
        tester,
        bloc: bloc,
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
      );

      expect(
        find.text(l10n.teacherDashboardCategoriesTitle),
        findsOneWidget,
      );
      expect(
        find.text(l10n.teacherPendingBookingRequestsSectionTitle),
        findsOneWidget,
      );
      expect(find.text(l10n.upcomingSessionsSectionTitle), findsWidgets);
      expect(find.text(l10n.bookableTimesWeekScopedTitle), findsOneWidget);
      expect(find.byType(TeacherDashboardSummaryStats), findsOneWidget);
      expect(find.byType(TutorSessionCompactCard), findsNothing);
    });
  });
}
