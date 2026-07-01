import 'package:bloc_test/bloc_test.dart';
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
import '../../helpers/fakes/fake_booked_slot_lock_repository.dart';
import '../../helpers/fakes/fake_availability_provider.dart';
import '../../helpers/fakes/fake_session_repository.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/lifecycle_test_helpers.dart';

Future<void> _pumpDashboard(
  WidgetTester tester, {
  required TeacherDashboardBloc bloc,
  required Future<void> Function() onManageSchedule,
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
          child: TeacherDashboardScreen(
            teacherId: 'teacher_1',
            onManageSchedule: onManageSchedule,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  late FakeSessionRepository sessionRepo;
  late FakeScheduleRepository scheduleRepo;
  late FakeAvailabilityProvider availabilityProvider;
  late BlockGeneratedSlotUseCase blockGeneratedSlot;
  late SpyGetTeacherAvailabilityUseCase spyGetAvailability;
  late FakeCommitTimers fakeTimers;

  final fixedNow = DateTime.utc(2026, 1, 9);

  TeacherDashboardBloc buildBloc() {
    return buildTestTeacherDashboardBloc(
      sessionRepo: sessionRepo,
      getAvailability: spyGetAvailability,
      blockGeneratedSlot: blockGeneratedSlot,
      availabilityProvider: availabilityProvider,
      cancelSession: buildCancelSessionViaServerUseCase(),
      completeSession: buildCompleteSessionViaServerUseCase(),
      scheduleRepo: scheduleRepo,
      commitTimerFactory: fakeTimers.createFactory(),
      commitDelay: const Duration(days: 365),
      now: () => fixedNow,
    );
  }

  setUpAll(() async {
    tz_data.initializeTimeZones();
    await initializeDateFormatting('en');
  });

  setUp(() {
    sessionRepo = FakeSessionRepository();
    scheduleRepo = FakeScheduleRepository();
    availabilityProvider = FakeAvailabilityProvider();
    blockGeneratedSlot = BlockGeneratedSlotUseCase(scheduleRepo);
    spyGetAvailability = SpyGetTeacherAvailabilityUseCase(
      scheduleRepository: scheduleRepo,
      bookedSlotLocks: FakeBookedSlotLockRepository(),
      now: () => fixedNow,
    );
    fakeTimers = FakeCommitTimers();
  });

  group('TeacherDashboardBloc — return from working hours', () {
    blocTest<TeacherDashboardBloc, TeacherDashboardState>(
      'reload after empty dashboard shows generated open slots',
      build: () => buildBloc(),
      act: (bloc) async {
        bloc.add(const TeacherDashboardLoadRequested(teacherId: 'teacher_1'));
        await bloc.stream.firstWhere((state) => state is TeacherDashboardEmpty);
        scheduleRepo.schedule = makeWeeklySchedule();
        bloc.add(const TeacherDashboardLoadRequested(teacherId: 'teacher_1'));
      },
      expect: () => [
        isA<TeacherDashboardLoading>(),
        isA<TeacherDashboardEmpty>(),
        isA<TeacherDashboardLoading>(),
        isA<TeacherDashboardSuccess>(),
      ],
      verify: (bloc) {
        final state = bloc.state as TeacherDashboardSuccess;
        check(state.availability).isNotEmpty();
      },
    );

    blocTest<TeacherDashboardBloc, TeacherDashboardState>(
      'reload from success emits empty when dashboard has no content',
      build: () {
        sessionRepo.sessions = [
          makeSession(
            lifecycleStatus: SessionLifecycleStatus.scheduled,
            startsAt: DateTime.utc(2026, 7, 1, 9),
            endsAt: DateTime.utc(2026, 7, 1, 9, 30),
          ),
        ];
        return buildBloc();
      },
      seed: () => seedTeacherDashboardSuccess(
        upcomingSessions: sessionRepo.sessions,
      ),
      act: (bloc) async {
        sessionRepo.sessions = [];
        scheduleRepo.schedule = null;
        bloc.add(const TeacherDashboardLoadRequested(teacherId: 'teacher_1'));
        await bloc.stream.firstWhere(
          (s) =>
              s is TeacherDashboardEmpty ||
              (s is TeacherDashboardSuccess && !s.isRefreshing),
        );
      },
      expect: () => [
        isA<TeacherDashboardSuccess>().having(
          (s) => s.isRefreshing,
          'isRefreshing',
          true,
        ),
        isA<TeacherDashboardEmpty>(),
      ],
    );

    blocTest<TeacherDashboardBloc, TeacherDashboardState>(
      'reload does not duplicate generated open slots',
      build: () {
        scheduleRepo.schedule = makeWeeklySchedule();
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const TeacherDashboardLoadRequested(teacherId: 'teacher_1'));
        await bloc.stream.firstWhere(
          (state) => state is TeacherDashboardSuccess,
        );
        final firstCount =
            (bloc.state as TeacherDashboardSuccess).availability.length;
        bloc.add(const TeacherDashboardLoadRequested(teacherId: 'teacher_1'));
        await bloc.stream.firstWhere(
          (state) => state is TeacherDashboardSuccess,
        );
        final secondCount =
            (bloc.state as TeacherDashboardSuccess).availability.length;
        check(secondCount).equals(firstCount);
      },
      expect: () => [
        isA<TeacherDashboardLoading>(),
        isA<TeacherDashboardSuccess>(),
        isA<TeacherDashboardSuccess>().having(
          (s) => s.isRefreshing,
          'isRefreshing',
          true,
        ),
        isA<TeacherDashboardSuccess>().having(
          (s) => s.isRefreshing,
          'isRefreshing',
          false,
        ),
      ],
      verify: (bloc) {
        check(spyGetAvailability.callCount).equals(2);
        final slots = (bloc.state as TeacherDashboardSuccess).availability;
        check(
          slots.map((slot) => slot.slotId).toSet().length,
        ).equals(slots.length);
      },
    );
  });

  group('TeacherDashboardScreen — return from working hours', () {
    testWidgets(
      'empty state clears and open slots appear after editor returns',
      (tester) async {
        final bloc = buildBloc();
        var editorOpened = false;

        await _pumpDashboard(
          tester,
          bloc: bloc,
          onManageSchedule: () async {
            editorOpened = true;
            scheduleRepo.schedule = makeWeeklySchedule();
          },
        );
        await tester.pumpAndSettle();

        final l10n = QuranSessionsLocalizations.of(
          tester.element(find.byType(TeacherDashboardScreen)),
        );

        expect(find.text(l10n.availabilitySetupHeadline), findsOneWidget);
        expect(find.text(l10n.noOpenSlots), findsNothing);

        await tester.tap(find.text(l10n.availabilitySetupCta));
        await tester.pumpAndSettle();

        check(editorOpened).isTrue();
        expect(find.text(l10n.availabilitySetupHeadline), findsNothing);
        await tester.scrollUntilVisible(
          find.text(l10n.bookableTimesThisWeekSectionTitle),
          100,
        );
        expect(
          find.text(l10n.bookableTimesWeekScopedTitle),
          findsOneWidget,
        );
        expect(
          find.text(l10n.bookableTimesThisWeekSectionTitle),
          findsOneWidget,
        );
        expect(
          find.text(l10n.bookableTimesNextWeekSectionTitle),
          findsOneWidget,
        );

        final state = bloc.state as TeacherDashboardSuccess;
        check(state.availability).isNotEmpty();
        check(spyGetAvailability.callCount).equals(2);
      },
    );

    testWidgets('open slots count updates immediately after editor returns', (
      tester,
    ) async {
      scheduleRepo.schedule = makeWeeklySchedule();
      final bloc = buildBloc();

      await _pumpDashboard(
        tester,
        bloc: bloc,
        onManageSchedule: () async {
          scheduleRepo.schedule = makeWeeklySchedule(
            rules: {
              Weekday.saturday: const [
                TimeRange(start: LocalTime(9, 0), end: LocalTime(13, 0)),
              ],
            },
          );
        },
      );
      await tester.pumpAndSettle();

      final initialCount =
          (bloc.state as TeacherDashboardSuccess).availability.length;

      final l10n = QuranSessionsLocalizations.of(
        tester.element(find.byType(TeacherDashboardScreen)),
      );

      await tester.tap(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byIcon(Icons.edit_calendar_outlined),
        ),
      );
      await tester.pumpAndSettle();

      final state = bloc.state as TeacherDashboardSuccess;
      check(state.availability.length).isGreaterThan(initialCount);
      await tester.scrollUntilVisible(
        find.text(l10n.bookableTimesWeekScopedTitle),
        100,
      );
      expect(find.text(l10n.bookableTimesWeekScopedTitle), findsOneWidget);
    });

    testWidgets('edit weekly template uses app bar icon not section header', (
      tester,
    ) async {
      scheduleRepo.schedule = makeWeeklySchedule();
      final bloc = buildBloc();

      await _pumpDashboard(
        tester,
        bloc: bloc,
        onManageSchedule: () async {},
      );
      await tester.pumpAndSettle();

      expect(find.byType(TilawaPrimaryFab), findsNothing);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byIcon(Icons.edit_calendar_outlined),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.text(
            QuranSessionsLocalizations.of(
              tester.element(find.byType(TeacherDashboardScreen)),
            ).bookableTimesWeekScopedTitle,
          ),
          matching: find.byIcon(Icons.edit_calendar_outlined),
        ),
        findsNothing,
      );
    });
  });
}

/// Test double for [CommitTimerFactory] — fires callbacks on demand.
class FakeCommitTimers {
  final List<({Duration delay, void Function() onFire})> scheduled = [];

  CommitTimerFactory createFactory() {
    return (delay, onFire) {
      scheduled.add((delay: delay, onFire: onFire));
      return () => scheduled.removeWhere((e) => e.onFire == onFire);
    };
  }
}
