import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../helpers/availability_test_helpers.dart';
import '../../helpers/fakes/fake_availability_provider.dart';
import '../../helpers/fakes/fake_booked_slot_lock_repository.dart';
import '../../helpers/fakes/fake_session_repository.dart';
import '../../helpers/fakes/fake_teacher_profile_repository.dart';
import '../../helpers/fakes/fake_user_profile_repository.dart';
import '../../helpers/lifecycle_test_helpers.dart';

QuranSession _inAppUpcomingSession() {
  final start = DateTime.now().add(const Duration(minutes: 5));
  return QuranSession(
    id: 'session_join',
    bookingId: 'booking_1',
    teacherId: 'teacher_1',
    studentId: 'student_1',
    startsAt: start,
    endsAt: start.add(const Duration(hours: 1)),
    callType: SessionCallType.voiceCall,
    status: QuranSessionStatus.scheduled,
    lifecycleStatus: SessionLifecycleStatus.scheduled,
    callProviderKind: SessionCallProviderKind.mock,
  );
}

class _NoOpCallControlGateway implements SessionCallControlGateway {
  @override
  Future<void> leave() async {}

  @override
  Future<void> setCameraEnabled({required bool enabled}) async {}

  @override
  Future<void> setMicrophoneEnabled({required bool enabled}) async {}

  @override
  Future<void> setSpeakerEnabled({required bool enabled}) async {}

  @override
  Future<void> switchCamera() async {}
}

class _TeacherJoinNavigationTestBloc extends TeacherDashboardBloc {
  _TeacherJoinNavigationTestBloc({
    required TeacherDashboardSuccess seed,
    required FakeSessionRepository sessionRepo,
    required FakeScheduleRepository scheduleRepo,
  }) : super(
         dashboardUseCase: GetTeacherDashboardUseCase(
           userProfileRepository: FakeUserProfileRepository(),
           marketSchedulingConfigRepository:
               FakeMarketSchedulingConfigRepository(),
           scheduleRepository: scheduleRepo,
           sessionRepository: sessionRepo,
           teacherProfileRepository: FakeTeacherProfileRepository(),
           getTeacherAvailability: SpyGetTeacherAvailabilityUseCase(
             scheduleRepository: scheduleRepo,
             bookedSlotLocks: FakeBookedSlotLockRepository(),
           ),
           cacheStore: MemoryCacheStore(),
         ),
         cacheInvalidator: InvalidateQuranSessionCacheUseCase(
           MemoryCacheStore(),
         ),
         slotBookedUseCase: IsSlotBookedUseCase(
           FakeBookedSlotLockRepository(),
         ),
         availabilityUseCase: SpyGetTeacherAvailabilityUseCase(
           scheduleRepository: scheduleRepo,
           bookedSlotLocks: FakeBookedSlotLockRepository(),
         ),
         blockSlotUseCase: BlockGeneratedSlotUseCase(scheduleRepo),
         availabilityGateway: FakeAvailabilityProvider(),
         cancelSessionUseCase: buildCancelSessionViaServerUseCase(),
         respondToBookingRequestUseCase: buildRespondToBookingRequestUseCase(),
         completeSessionUseCase: buildCompleteSessionViaServerUseCase(),
         joinSessionUseCase: buildJoinSessionUseCase(
           sessionRepository: sessionRepo,
           userId: 'teacher_1',
         ),
         fridayReminderStore: InMemoryFridayReviewReminderStore(),
         teacherUserId: 'teacher_1',
       ) {
    emit(seed);
  }

  @override
  void add(TeacherDashboardEvent event) {
    if (event is TeacherDashboardLoadRequested) {
      return;
    }
    if (event is TeacherDashboardSessionJoinRequested) {
      final current = state;
      if (current is! TeacherDashboardSuccess) {
        return;
      }
      emit(
        current.copyWith(
          clearJoinInProgress: true,
          joinCompletedSessionId: event.sessionId,
        ),
      );
      return;
    }
    if (event is TeacherDashboardJoinCompletedAcknowledged) {
      final current = state;
      if (current is! TeacherDashboardSuccess) {
        return;
      }
      emit(current.copyWith(clearJoinCompletedSessionId: true));
      return;
    }
    super.add(event);
  }
}

Future<void> _pumpTeacherDashboard(
  WidgetTester tester, {
  required TeacherDashboardBloc bloc,
  Future<bool?> Function(String bookingId)? onSessionDetailRequested,
  QuranSessionsAnalyticsCallbacks analytics =
      const QuranSessionsAnalyticsCallbacks(),
}) async {
  tester.view.physicalSize = const Size(390, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
      locale: const Locale('en'),
      localizationsDelegates: const [
        ...QuranSessionsLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: QuranSessionsLocalizations.supportedLocales,
      builder: (context, child) => TilawaFeedbackHost(child: child!),
      home: BlocProvider<TeacherDashboardBloc>.value(
        value: bloc,
        child: TeacherDashboardScreen(
          teacherId: 'teacher_1',
          analytics: analytics,
          onSessionDetailRequested: onSessionDetailRequested,
          createCallControlGateway: (_) => _NoOpCallControlGateway(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await initializeDateFormatting('en');
  });

  testWidgets('dashboard join opens call shell without opening detail', (
    tester,
  ) async {
    String? openedBookingId;
    final sessionRepo = FakeSessionRepository();
    final scheduleRepo = FakeScheduleRepository();
    final bloc = _TeacherJoinNavigationTestBloc(
      seed: seedTeacherDashboardSuccess(
        upcomingSessions: [_inAppUpcomingSession()],
      ),
      sessionRepo: sessionRepo,
      scheduleRepo: scheduleRepo,
    );

    await _pumpTeacherDashboard(
      tester,
      bloc: bloc,
      onSessionDetailRequested: (bookingId) async {
        openedBookingId = bookingId;
        return null;
      },
    );

    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();

    check(openedBookingId).isNull();
    expect(find.byKey(const Key('call_shell_end')), findsOneWidget);
  });

  testWidgets('invokes onSessionJoined after successful dashboard join', (
    tester,
  ) async {
    String? joinedBookingId;
    String? joinedSessionId;
    final sessionRepo = FakeSessionRepository();
    final scheduleRepo = FakeScheduleRepository();
    final bloc = _TeacherJoinNavigationTestBloc(
      seed: seedTeacherDashboardSuccess(
        upcomingSessions: [_inAppUpcomingSession()],
      ),
      sessionRepo: sessionRepo,
      scheduleRepo: scheduleRepo,
    );

    await _pumpTeacherDashboard(
      tester,
      bloc: bloc,
      analytics: QuranSessionsAnalyticsCallbacks(
        onSessionJoined: ({bookingId, sessionId}) {
          joinedBookingId = bookingId;
          joinedSessionId = sessionId;
        },
      ),
    );

    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();

    check(joinedBookingId).equals('booking_1');
    check(joinedSessionId).equals('session_join');
  });
}
