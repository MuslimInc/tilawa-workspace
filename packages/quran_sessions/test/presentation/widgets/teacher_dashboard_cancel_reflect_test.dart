import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:quran_sessions/src/presentation/widgets/tutor_session_compact_card.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../helpers/availability_test_helpers.dart';
import '../../helpers/fakes/fake_availability_provider.dart';
import '../../helpers/fakes/fake_booked_slot_lock_repository.dart';
import '../../helpers/fakes/fake_session_aggregate_repository.dart';
import '../../helpers/fakes/fake_session_repository.dart';
import '../../helpers/fakes/fake_user_profile_repository.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/fixtures/session_aggregate_fixtures.dart';
import '../../helpers/lifecycle_test_helpers.dart';

/// Widget-level repro for tutor cancel not reflecting on the dashboard.
void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
  });

  Future<void> pumpDashboard(
    WidgetTester tester, {
    required TeacherDashboardBloc bloc,
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
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
        home: TilawaFeedbackHost(
          child: BlocProvider<TeacherDashboardBloc>.value(
            value: bloc,
            child: const TeacherDashboardScreen(teacherId: 'teacher_1'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> confirmCardCancel(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel session'));
    await tester.pumpAndSettle();
  }

  Future<void> confirmArabicCardCancel(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إلغاء'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    expect(find.text('إلغاء الحصة؟'), findsOneWidget);
    await tester.tap(find.text('إلغاء الحصة'));
    await tester.pumpAndSettle();
  }

  group('teacher dashboard tutor cancel reflection', () {
    testWidgets('missing aggregate keeps upcoming card after confirm', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      final sessionRepo = FakeSessionRepository()
        ..sessions = [
          makeSession(
            lifecycleStatus: SessionLifecycleStatus.scheduled,
            startsAt: DateTime.utc(2026, 7, 10, 9),
            endsAt: DateTime.utc(2026, 7, 10, 9, 30),
          ),
        ];
      final scheduleRepo = FakeScheduleRepository()
        ..schedule = makeWeeklySchedule();
      final bloc = buildTestTeacherDashboardBloc(
        sessionRepo: sessionRepo,
        getAvailability: buildGetTeacherAvailabilityUseCase(
          scheduleRepository: scheduleRepo,
          bookedSlotLockRepository: FakeBookedSlotLockRepository(),
        ),
        blockGeneratedSlot: BlockGeneratedSlotUseCase(scheduleRepo),
        availabilityProvider: FakeAvailabilityProvider(),
        cancelSession: buildCancelSessionViaServerUseCase(
          repository: FakeSessionAggregateRepository(),
        ),
        completeSession: buildCompleteSessionViaServerUseCase(),
        scheduleRepo: scheduleRepo,
        userProfileRepo: FakeUserProfileRepository(),
      );

      bloc.emit(
        seedTeacherDashboardSuccess(
          upcomingSessions: sessionRepo.sessions,
        ),
      );

      await pumpDashboard(tester, bloc: bloc);
      expect(find.byType(TutorSessionCompactCard), findsOneWidget);

      await confirmCardCancel(tester);

      expect(find.byType(TutorSessionCompactCard), findsOneWidget);
      final state = bloc.state as TeacherDashboardSuccess;
      check(state.upcomingSessions.length).equals(1);
      check(state.sessionCancelFailure).isA<NotFoundFailure>();
    });

    testWidgets('Arabic cancel dialog removes card when cancel succeeds', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      final aggregateRepo = FakeSessionAggregateRepository()
        ..store['booking_1'] = makeAggregate(
          id: 'booking_1',
          status: SessionLifecycleStatus.scheduled,
          startsAt: DateTime.utc(2026, 7, 10, 9),
          paymentReference: null,
          pricingType: SessionPricingType.free,
        );
      final sessionRepo = FakeSessionRepository()
        ..sessions = [
          makeSession(
            lifecycleStatus: SessionLifecycleStatus.scheduled,
            startsAt: DateTime.utc(2026, 7, 10, 9),
            endsAt: DateTime.utc(2026, 7, 10, 9, 30),
          ),
        ];
      final scheduleRepo = FakeScheduleRepository()
        ..schedule = makeWeeklySchedule();
      final bloc = buildTestTeacherDashboardBloc(
        sessionRepo: sessionRepo,
        getAvailability: buildGetTeacherAvailabilityUseCase(
          scheduleRepository: scheduleRepo,
          bookedSlotLockRepository: FakeBookedSlotLockRepository(),
        ),
        blockGeneratedSlot: BlockGeneratedSlotUseCase(scheduleRepo),
        availabilityProvider: FakeAvailabilityProvider(),
        cancelSession: buildCancelSessionViaServerUseCase(
          repository: aggregateRepo,
        ),
        completeSession: buildCompleteSessionViaServerUseCase(),
        scheduleRepo: scheduleRepo,
        userProfileRepo: FakeUserProfileRepository(),
      );

      bloc.emit(
        seedTeacherDashboardSuccess(
          upcomingSessions: sessionRepo.sessions,
        ),
      );

      await pumpDashboard(
        tester,
        bloc: bloc,
        locale: const Locale('ar'),
      );
      expect(find.byType(TutorSessionCompactCard), findsOneWidget);

      await confirmArabicCardCancel(tester);

      expect(find.byType(TutorSessionCompactCard), findsNothing);
      final state = bloc.state as TeacherDashboardSuccess;
      check(state.upcomingSessions).isEmpty();
    });

    testWidgets('cancel failure shows friendly tutor error toast', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      final session = makeSession(
        lifecycleStatus: SessionLifecycleStatus.scheduled,
        startsAt: DateTime.utc(2026, 7, 10, 9),
        endsAt: DateTime.utc(2026, 7, 10, 9, 30),
      );
      final scheduleRepo = FakeScheduleRepository()
        ..schedule = makeWeeklySchedule();
      final bloc = buildTestTeacherDashboardBloc(
        sessionRepo: FakeSessionRepository()..sessions = [session],
        getAvailability: buildGetTeacherAvailabilityUseCase(
          scheduleRepository: scheduleRepo,
          bookedSlotLockRepository: FakeBookedSlotLockRepository(),
        ),
        blockGeneratedSlot: BlockGeneratedSlotUseCase(scheduleRepo),
        availabilityProvider: FakeAvailabilityProvider(),
        cancelSession: buildCancelSessionViaServerUseCase(),
        completeSession: buildCompleteSessionViaServerUseCase(),
        scheduleRepo: scheduleRepo,
        userProfileRepo: FakeUserProfileRepository(),
      );

      await pumpDashboard(tester, bloc: bloc);

      bloc.emit(
        (bloc.state as TeacherDashboardSuccess).copyWith(
          sessionCancelFailure: const InvalidTransitionFailure(
            action: 'cancelByTeacher',
            actorRole: 'teacher',
            reasonCode: 'invalid_transition',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TilawaFeedbackStrip), findsOneWidget);
      expect(
        find.textContaining('Could not cancel the session'),
        findsOneWidget,
      );
      expect(find.textContaining('invalid_transition'), findsNothing);
    });

    testWidgets(
      'pull-to-refresh restores upcoming card when session doc stays scheduled',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        final aggregateRepo = FakeSessionAggregateRepository()
          ..store['booking_1'] = makeAggregate(
            id: 'booking_1',
            status: SessionLifecycleStatus.scheduled,
            startsAt: DateTime.utc(2026, 7, 10, 9),
            paymentReference: null,
            pricingType: SessionPricingType.free,
          );
        final session = makeSession(
          lifecycleStatus: SessionLifecycleStatus.scheduled,
          startsAt: DateTime.utc(2026, 7, 10, 9),
          endsAt: DateTime.utc(2026, 7, 10, 9, 30),
        );
        final sessionRepo = FakeSessionRepository()..sessions = [session];
        final scheduleRepo = FakeScheduleRepository()
          ..schedule = makeWeeklySchedule();
        final bloc = buildTestTeacherDashboardBloc(
          sessionRepo: sessionRepo,
          getAvailability: buildGetTeacherAvailabilityUseCase(
            scheduleRepository: scheduleRepo,
            bookedSlotLockRepository: FakeBookedSlotLockRepository(),
          ),
          blockGeneratedSlot: BlockGeneratedSlotUseCase(scheduleRepo),
          availabilityProvider: FakeAvailabilityProvider(),
          cancelSession: buildCancelSessionViaServerUseCase(
            repository: aggregateRepo,
          ),
          completeSession: buildCompleteSessionViaServerUseCase(),
          scheduleRepo: scheduleRepo,
          userProfileRepo: FakeUserProfileRepository(),
        );

        bloc.emit(
          seedTeacherDashboardSuccess(upcomingSessions: [session]),
        );

        await pumpDashboard(tester, bloc: bloc);
        await confirmCardCancel(tester);
        expect(find.byType(TutorSessionCompactCard), findsNothing);

        await tester.drag(
          find.byType(CustomScrollView),
          const Offset(0, 300),
        );
        await tester.pumpAndSettle();

        expect(find.byType(TutorSessionCompactCard), findsOneWidget);
        check(
          aggregateRepo.store['booking_1']!.lifecycleStatus,
        ).equals(SessionLifecycleStatus.cancelledByTeacher);
      },
    );
  });
}
