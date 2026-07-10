import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations_en.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:quran_sessions/src/presentation/widgets/date_grouped_day_tab_bar.dart';
import 'package:quran_sessions/src/presentation/widgets/teacher_dashboard_collapsible_session_list.dart';
import 'package:quran_sessions/src/presentation/widgets/teacher_dashboard_lazy_slot_day_list.dart';
import 'package:quran_sessions/src/presentation/widgets/tutor_session_compact_card.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../helpers/availability_test_helpers.dart';
import '../../helpers/fakes/fake_availability_provider.dart';
import '../../helpers/fakes/fake_booked_slot_lock_repository.dart';
import '../../helpers/fakes/fake_session_repository.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/lifecycle_test_helpers.dart';
import '../../helpers/widget_pump.dart';

void main() {
  final fixedNow = DateTime.utc(2026, 1, 9, 10);

  setUpAll(() async {
    tz_data.initializeTimeZones();
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
  });

  TeacherDashboardBloc buildBloc({
    required FakeSessionRepository sessionRepo,
  }) {
    final scheduleRepo = FakeScheduleRepository()
      ..schedule = makeWeeklySchedule(
        rules: {
          Weekday.friday: const [
            TimeRange(start: LocalTime(8, 0), end: LocalTime(20, 0)),
          ],
        },
      );
    return buildTestTeacherDashboardBloc(
      sessionRepo: sessionRepo,
      getAvailability: SpyGetTeacherAvailabilityUseCase(
        scheduleRepository: scheduleRepo,
        bookedSlotLocks: FakeBookedSlotLockRepository(),
        now: () => fixedNow,
      ),
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
  }) async {
    await pumpInApp(
      tester,
      BlocProvider<TeacherDashboardBloc>.value(
        value: bloc,
        child: const TeacherDashboardScreen(teacherId: 'teacher_1'),
      ),
      surfaceSize: const Size(390, 640),
    );
  }

  group('TeacherDashboardLazySlotDayList', () {
    testWidgets('uses bounded ListView.builder for many slots', (tester) async {
      const slotCount = 12;

      await pumpInApp(
        tester,
        TeacherDashboardLazySlotDayList(
          itemCount: slotCount,
          itemBuilder: (context, index) => SizedBox(
            height: Theme.of(context).tokens.minInteractiveDimension,
            child: Text('slot_$index'),
          ),
        ),
        surfaceSize: const Size(390, 400),
      );

      final listView = tester.widget<ListView>(find.byType(ListView));
      check(listView.childrenDelegate).isA<SliverChildBuilderDelegate>();

      final listBox = tester.getRect(find.byType(ListView));
      final tokens = Theme.of(
        tester.element(find.byType(TeacherDashboardLazySlotDayList)),
      ).tokens;
      final maxHeight =
          (tokens.minInteractiveDimension + tokens.spaceExtraSmall) *
          TeacherDashboardLazySlotDayList.defaultMaxVisibleRows;

      check(listBox.height).isLessThan(maxHeight + 1);
      expect(find.text('slot_0'), findsOneWidget);
      expect(find.text('slot_11'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('TeacherDashboardCollapsibleSessionList', () {
    testWidgets('shows show-all control when list exceeds preview count', (
      tester,
    ) async {
      final l10n = QuranSessionsLocalizationsEn();

      await pumpInApp(
        tester,
        CustomScrollView(
          slivers: [
            TeacherDashboardCollapsibleSessionList(
              sectionKey: 'upcoming',
              itemCount: 6,
              expanded: false,
              onToggleExpanded: () {},
              itemBuilder: (context, index) => TutorSessionCompactCard(
                session: makeSession(
                  id: 'session_$index',
                  lifecycleStatus: SessionLifecycleStatus.scheduled,
                  startsAt: fixedNow.add(Duration(hours: index + 1)),
                ),
                studentDisplayName: 'Student $index',
                now: fixedNow,
                onJoin: () {},
              ),
            ),
          ],
        ),
        surfaceSize: const Size(390, 640),
      );

      expect(find.byType(TutorSessionCompactCard), findsNWidgets(3));
      expect(
        find.text(l10n.teacherDashboardShowAllSessions(6)),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('parent-controlled toggle reveals all session rows', (
      tester,
    ) async {
      final l10n = QuranSessionsLocalizationsEn();

      await pumpInApp(
        tester,
        const _ControlledCollapsibleListHarness(),
        surfaceSize: const Size(390, 1200),
      );

      await tester.tap(
        find.byKey(
          const ValueKey('teacher-dashboard-upcoming-sessions-expand'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.teacherDashboardShowLessSessions), findsOneWidget);
      expect(find.byType(TutorSessionCompactCard), findsWidgets);
    });
  });

  group('TeacherDashboardScreen long lists', () {
    testWidgets('moves many upcoming sessions to the category detail screen', (
      tester,
    ) async {
      final l10n = QuranSessionsLocalizationsEn();
      final sessionRepo = FakeSessionRepository()
        ..sessions = List.generate(
          6,
          (index) => makeSession(
            id: 'session_$index',
            lifecycleStatus: SessionLifecycleStatus.scheduled,
            startsAt: DateTime.now().add(Duration(hours: index + 2)),
          ),
        );
      final bloc = buildBloc(sessionRepo: sessionRepo);

      await pumpDashboard(tester, bloc: bloc);

      expect(find.byType(TutorSessionCompactCard), findsNothing);
      expect(find.text(l10n.upcomingSessionsSectionTitle), findsWidgets);

      await tester.tap(find.text(l10n.upcomingSessionsSectionTitle).last);
      await tester.pumpAndSettle();

      expect(find.byType(TutorSessionCompactCard), findsWidgets);
      expect(
        find.text(l10n.teacherDashboardShowAllSessions(6)),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('pinned bookable headers stay visible while scrolling slots', (
      tester,
    ) async {
      final l10n = QuranSessionsLocalizationsEn();
      final sessionRepo = FakeSessionRepository()
        ..sessions = List.generate(
          8,
          (index) => makeSession(
            id: 'session_$index',
            lifecycleStatus: SessionLifecycleStatus.scheduled,
            startsAt: DateTime.now().add(Duration(hours: index + 2)),
          ),
        );
      final bloc = buildBloc(sessionRepo: sessionRepo);

      await pumpDashboard(tester, bloc: bloc);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -240));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.bookableTimesWeekScopedTitle).last);
      await tester.pumpAndSettle();

      final weekTabBeforeScroll = tester.getTopLeft(
        find.text(l10n.bookableTimesThisWeekSectionTitle),
      );

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();

      final weekTabAfterScroll = tester.getTopLeft(
        find.text(l10n.bookableTimesThisWeekSectionTitle),
      );

      expect(weekTabAfterScroll.dy, weekTabBeforeScroll.dy);
      expect(find.text(l10n.bookableTimesWeekScopedTitle), findsWidgets);
      expect(find.byType(DateGroupedDayTabBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'week-scoped bookable header survives repeated scroll without sliver errors',
      (tester) async {
        final l10n = QuranSessionsLocalizationsEn();
        final sessionRepo = FakeSessionRepository()
          ..sessions = List.generate(
            4,
            (index) => makeSession(
              id: 'session_$index',
              lifecycleStatus: SessionLifecycleStatus.scheduled,
              startsAt: DateTime.now().add(Duration(hours: index + 2)),
            ),
          );
        final bloc = buildBloc(sessionRepo: sessionRepo);

        await pumpDashboard(tester, bloc: bloc);

        await tester.drag(find.byType(CustomScrollView), const Offset(0, -240));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.bookableTimesWeekScopedTitle).last);
        await tester.pumpAndSettle();

        for (var i = 0; i < 3; i++) {
          await tester.drag(
            find.byType(CustomScrollView),
            const Offset(0, -250),
          );
          await tester.pumpAndSettle();
          await tester.drag(
            find.byType(CustomScrollView),
            const Offset(0, 250),
          );
          await tester.pumpAndSettle();
        }

        expect(find.byType(SliverPersistentHeader), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('join still works from collapsed upcoming session card', (
      tester,
    ) async {
      final sessionRepo = FakeSessionRepository()
        ..sessions = [
          makeSession(
            id: 'session_join',
            lifecycleStatus: SessionLifecycleStatus.scheduled,
            startsAt: DateTime.now().add(const Duration(minutes: 5)),
          ),
          for (var index = 1; index < 5; index++)
            makeSession(
              id: 'session_$index',
              lifecycleStatus: SessionLifecycleStatus.scheduled,
              startsAt: DateTime.now().add(Duration(days: index)),
            ),
        ];
      final bloc = buildBloc(sessionRepo: sessionRepo);

      await pumpDashboard(tester, bloc: bloc);

      final l10n = QuranSessionsLocalizationsEn();
      await tester.tap(find.text(l10n.upcomingSessionsSectionTitle).last);
      await tester.pumpAndSettle();

      final enabledJoin = find.byWidgetPredicate(
        (widget) =>
            widget is TilawaButton &&
            widget.text == 'Join' &&
            widget.onPressed != null,
      );
      expect(enabledJoin, findsOneWidget);
    });
  });
}

class _ControlledCollapsibleListHarness extends StatefulWidget {
  const _ControlledCollapsibleListHarness();

  @override
  State<_ControlledCollapsibleListHarness> createState() =>
      _ControlledCollapsibleListHarnessState();
}

class _ControlledCollapsibleListHarnessState
    extends State<_ControlledCollapsibleListHarness> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        TeacherDashboardCollapsibleSessionList(
          sectionKey: 'upcoming',
          itemCount: 6,
          expanded: _expanded,
          onToggleExpanded: () => setState(() => _expanded = !_expanded),
          itemBuilder: (context, index) => TutorSessionCompactCard(
            session: makeSession(
              id: 'session_$index',
              lifecycleStatus: SessionLifecycleStatus.scheduled,
              startsAt: DateTime.now().add(Duration(hours: index + 1)),
            ),
            studentDisplayName: 'Student $index',
            now: DateTime.now(),
            onJoin: () {},
          ),
        ),
      ],
    );
  }
}
