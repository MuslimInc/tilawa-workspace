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
import '../../helpers/fakes/fake_session_mutation_gateway.dart';
import '../../helpers/fakes/fake_session_aggregate_repository.dart';
import '../../helpers/fakes/fake_session_repository.dart';
import '../../helpers/fakes/fake_user_profile_repository.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/fixtures/session_aggregate_fixtures.dart';
import '../../helpers/lifecycle_test_helpers.dart';

void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await initializeDateFormatting('en');
  });

  Future<void> pumpDashboard(
    WidgetTester tester, {
    required TeacherDashboardBloc bloc,
  }) async {
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

  testWidgets('decline opens confirmation sheet and rejects without reason', (
    tester,
  ) async {
    final gateway = FakeSessionMutationGateway();
    final sessionRepo = FakeSessionRepository()
      ..sessions = [
        makeSession(
          lifecycleStatus: SessionLifecycleStatus.pendingTutorApproval,
        ),
      ];
    final scheduleRepo = FakeScheduleRepository();
    final bloc = buildTestTeacherDashboardBloc(
      sessionRepo: sessionRepo,
      getAvailability: buildGetTeacherAvailabilityUseCase(
        scheduleRepository: scheduleRepo,
        bookedSlotLockRepository: FakeBookedSlotLockRepository(),
      ),
      blockGeneratedSlot: BlockGeneratedSlotUseCase(scheduleRepo),
      availabilityProvider: FakeAvailabilityProvider(),
      cancelSession: buildCancelSessionViaServerUseCase(),
      completeSession: buildCompleteSessionViaServerUseCase(),
      respondToBookingRequest: RespondToBookingRequestUseCase(gateway),
      scheduleRepo: scheduleRepo,
      userProfileRepo: FakeUserProfileRepository(),
    );

    await pumpDashboard(tester, bloc: bloc);

    await tester.tap(find.text('Decline'));
    await tester.pumpAndSettle();
    expect(find.text('Decline booking request?'), findsOneWidget);

    await tester.tap(find.text('Decline request'));
    await tester.pumpAndSettle();

    expect(find.text('Decline booking request?'), findsNothing);
    check(gateway.calls).contains('respond:booking_1:reject:');
    final state = bloc.state as TeacherDashboardSuccess;
    check(state.pendingBookingRequests).isEmpty();
  });

  testWidgets('decline with reason forwards trimmed reason', (tester) async {
    final gateway = FakeSessionMutationGateway();
    final sessionRepo = FakeSessionRepository()
      ..sessions = [
        makeSession(
          lifecycleStatus: SessionLifecycleStatus.pendingTutorApproval,
        ),
      ];
    final scheduleRepo = FakeScheduleRepository();
    final bloc = buildTestTeacherDashboardBloc(
      sessionRepo: sessionRepo,
      getAvailability: buildGetTeacherAvailabilityUseCase(
        scheduleRepository: scheduleRepo,
        bookedSlotLockRepository: FakeBookedSlotLockRepository(),
      ),
      blockGeneratedSlot: BlockGeneratedSlotUseCase(scheduleRepo),
      availabilityProvider: FakeAvailabilityProvider(),
      cancelSession: buildCancelSessionViaServerUseCase(),
      completeSession: buildCompleteSessionViaServerUseCase(),
      respondToBookingRequest: RespondToBookingRequestUseCase(gateway),
      scheduleRepo: scheduleRepo,
      userProfileRepo: FakeUserProfileRepository(),
    );

    await pumpDashboard(tester, bloc: bloc);

    await tester.tap(find.text('Decline'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Not available');
    await tester.tap(find.text('Decline request'));
    await tester.pumpAndSettle();

    check(gateway.calls).contains('respond:booking_1:reject:Not available');
  });

  testWidgets('scheduled upcoming card shows overflow cancel only', (
    tester,
  ) async {
    final sessionRepo = FakeSessionRepository()
      ..sessions = [
        makeSession(lifecycleStatus: SessionLifecycleStatus.scheduled),
      ];
    final scheduleRepo = FakeScheduleRepository();
    final bloc = buildTestTeacherDashboardBloc(
      sessionRepo: sessionRepo,
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

    expect(find.byIcon(Icons.more_vert), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
  });

  testWidgets('pending card hides overflow cancel menu', (tester) async {
    final sessionRepo = FakeSessionRepository()
      ..sessions = [
        makeSession(
          lifecycleStatus: SessionLifecycleStatus.pendingTutorApproval,
        ),
      ];
    final scheduleRepo = FakeScheduleRepository();
    final bloc = buildTestTeacherDashboardBloc(
      sessionRepo: sessionRepo,
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

    expect(find.byIcon(Icons.more_vert), findsNothing);
  });

  testWidgets('card cancel uses tutor dialog and removes upcoming session', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    final aggregateRepo = FakeSessionAggregateRepository()
      ..store['booking_1'] = makeAggregate(
        id: 'booking_1',
        status: SessionLifecycleStatus.scheduled,
        pricingType: SessionPricingType.free,
        paymentReference: null,
      );
    final sessionRepo = FakeSessionRepository()
      ..sessions = [
        makeSession(lifecycleStatus: SessionLifecycleStatus.scheduled),
      ];
    final scheduleRepo = FakeScheduleRepository();
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

    await pumpDashboard(tester, bloc: bloc);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    expect(find.text('Cancel session?'), findsOneWidget);
    await tester.tap(find.text('Cancel session'));
    await tester.pumpAndSettle();

    final state = bloc.state as TeacherDashboardSuccess;
    check(state.upcomingSessions).isEmpty();
  });
}
