import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../helpers/availability_test_helpers.dart';
import '../../helpers/fakes/fake_availability_provider.dart';
import '../../helpers/fakes/fake_session_repository.dart';
import '../../helpers/lifecycle_test_helpers.dart';

/// Test double for [CommitTimerFactory] — fires callbacks on demand.
class _FakeCommitTimers {
  final List<({Duration delay, void Function() onFire})> scheduled = [];

  CommitTimerFactory createFactory() {
    return (delay, onFire) {
      scheduled.add((delay: delay, onFire: onFire));
      return () => scheduled.removeWhere((e) => e.onFire == onFire);
    };
  }
}

/// Mirrors [TeacherDashboardScreen] undo-toast listener + open-slot count without
/// auto-reload on mount — keeps widget tests deterministic.
class _SlotDeletionHarness extends StatefulWidget {
  const _SlotDeletionHarness({required this.teacherId});

  final String teacherId;

  @override
  State<_SlotDeletionHarness> createState() => _SlotDeletionHarnessState();
}

class _SlotDeletionHarnessState extends State<_SlotDeletionHarness> {
  String? _lastUndoSnackSlotId;

  static const _undoSnackDuration = Duration(seconds: 4);

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;

    return BlocConsumer<TeacherDashboardBloc, TeacherDashboardState>(
      listener: (context, state) {
        if (state is! TeacherDashboardSuccess) {
          _lastUndoSnackSlotId = null;
          return;
        }

        final undoId = state.undoableSlotId;
        if (undoId == null) {
          _lastUndoSnackSlotId = null;
          return;
        }
        if (undoId == _lastUndoSnackSlotId) return;

        final pending = state.pendingDeletes[undoId];
        if (pending == null) return;

        _lastUndoSnackSlotId = undoId;
        _showDeleteUndoToast(
          context,
          pending.snapshot,
          pendingDeleteCount: state.pendingDeletes.length,
        );
      },
      builder: (context, state) {
        if (state is! TeacherDashboardSuccess) {
          return const SizedBox.shrink();
        }

        return Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.openSlotsSection(state.availability.length)),
              if (state.availability.isEmpty)
                Text(l10n.noOpenSlots)
              else
                for (final slot in state.availability)
                  ListTile(
                    title: Text(slot.slotId),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => context.read<TeacherDashboardBloc>().add(
                        AvailabilitySlotRemoved(
                          teacherId: widget.teacherId,
                          slot: slot,
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteUndoToast(
    BuildContext context,
    TeacherAvailability slot, {
    required int pendingDeleteCount,
  }) {
    final l10n = context.quranSessionsL10n;
    final locale = Localizations.localeOf(context).languageCode;
    final timeFmt = DateFormat('EEE d MMM، h:mm a', locale);
    final timeLabel = timeFmt.format(slot.startsAt.toLocal());
    final message = pendingDeleteCount > 1
        ? l10n.deleteSlotRemovedSnackBarWithPending(
            timeLabel,
            pendingDeleteCount,
          )
        : l10n.deleteSlotRemovedSnackBar(timeLabel);

    TilawaFeedback.showActionable(
      context,
      message: message,
      variant: TilawaFeedbackVariant.success,
      duration: _undoSnackDuration,
      dedupeKey: 'teacher-dashboard-slot-undo',
      actions: <TilawaFeedbackAction>[
        TilawaFeedbackAction(
          label: l10n.deleteSlotUndo,
          onPressed: () {
            final current = context.read<TeacherDashboardBloc>().state;
            if (current is! TeacherDashboardSuccess) return;
            final undoId = current.undoableSlotId;
            if (undoId == null) return;

            context.read<TeacherDashboardBloc>().add(
              AvailabilitySlotDeleteUndone(slotId: undoId),
            );
          },
        ),
      ],
    );
  }
}

TeacherAvailability _slot(String id, DateTime start) => TeacherAvailability(
  slotId: id,
  teacherId: 'teacher_1',
  startsAt: start,
  endsAt: start.add(const Duration(minutes: 30)),
  isBooked: false,
);

Future<void> _pumpHarness(
  WidgetTester tester, {
  required TeacherDashboardBloc bloc,
  Locale locale = const Locale('en'),
  TextDirection textDirection = TextDirection.ltr,
}) async {
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
        child: TilawaFeedbackHost(
          child: BlocProvider<TeacherDashboardBloc>.value(
            value: bloc,
            child: const _SlotDeletionHarness(teacherId: 'teacher_1'),
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
  late _FakeCommitTimers fakeTimers;

  final slotA = _slot('slot_a', DateTime.utc(2026, 1, 10, 7, 0));
  final slotB = _slot('slot_b', DateTime.utc(2026, 1, 10, 7, 30));
  final slotOnly = _slot('slot_only', DateTime.utc(2026, 1, 10, 8, 0));

  TeacherDashboardBloc buildBloc({
    required List<TeacherAvailability> availability,
  }) {
    scheduleRepo.schedule = makeWeeklySchedule();
    final bloc = TeacherDashboardBloc(
      getTeacherSessions: GetTeacherSessionsUseCase(sessionRepo),
      getAvailability: spyGetAvailability,
      blockGeneratedSlot: blockGeneratedSlot,
      availabilityProvider: availabilityProvider,
      cancelSession: buildCancelSessionViaServerUseCase(),
      completeSession: buildCompleteSessionViaServerUseCase(),
      teacherId: 'teacher_1',
      commitTimerFactory: fakeTimers.createFactory(),
      commitDelay: const Duration(days: 365),
    );
    bloc.emit(
      TeacherDashboardSuccess(
        upcomingSessions: const [],
        availability: availability,
      ),
    );
    return bloc;
  }

  setUpAll(() async {
    tz_data.initializeTimeZones();
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
  });

  setUp(() {
    sessionRepo = FakeSessionRepository();
    scheduleRepo = FakeScheduleRepository();
    availabilityProvider = FakeAvailabilityProvider();
    blockGeneratedSlot = BlockGeneratedSlotUseCase(scheduleRepo);
    spyGetAvailability = SpyGetTeacherAvailabilityUseCase(
      scheduleRepository: scheduleRepo,
      sessionRepository: sessionRepo,
      now: () => DateTime.utc(2026, 1, 9),
    );
    fakeTimers = _FakeCommitTimers();
    TilawaInteractionFeedback.enabled = false;
  });

  group('slot deletion undo toast harness', () {
    testWidgets('delete B while A undo toast visible shows one undo toast', (
      tester,
    ) async {
      final bloc = buildBloc(availability: [slotA, slotB]);
      addTearDown(bloc.close);

      await _pumpHarness(tester, bloc: bloc);

      final l10n = await QuranSessionsLocalizations.delegate.load(
        const Locale('en'),
      );
      expect(find.text(l10n.openSlotsSection(2)), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline).at(0));
      await tester.pump();
      await tester.pump();
      expect(find.text(l10n.deleteSlotUndo), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline).at(0));
      await tester.pump();
      await tester.pump();

      expect(find.text(l10n.deleteSlotUndo), findsOneWidget);
      expect(find.byType(TilawaFeedbackStrip), findsOneWidget);
      expect(find.text(l10n.openSlotsSection(0)), findsOneWidget);
    });

    testWidgets('undo toast restores only the latest deleted slot', (
      tester,
    ) async {
      final bloc = buildBloc(availability: [slotA, slotB]);
      addTearDown(bloc.close);

      await _pumpHarness(tester, bloc: bloc);

      await tester.tap(find.byIcon(Icons.delete_outline).at(0));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byIcon(Icons.delete_outline).at(0));
      await tester.pump();
      await tester.pump();

      final l10n = await QuranSessionsLocalizations.delegate.load(
        const Locale('en'),
      );
      await tester.tap(find.text(l10n.deleteSlotUndo));
      await tester.pump();
      await tester.pump();

      final state = bloc.state as TeacherDashboardSuccess;
      check(state.availability.single.slotId).equals(slotB.slotId);
      check(state.pendingDeletes).containsKey(slotA.slotId);
      expect(find.text(l10n.openSlotsSection(1)), findsOneWidget);
    });

    testWidgets('open slots count drops to zero on last delete', (
      tester,
    ) async {
      final bloc = buildBloc(availability: [slotOnly]);
      addTearDown(bloc.close);

      await _pumpHarness(tester, bloc: bloc);

      final l10n = await QuranSessionsLocalizations.delegate.load(
        const Locale('en'),
      );
      expect(find.text(l10n.openSlotsSection(1)), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();
      await tester.pump();

      expect(find.text(l10n.openSlotsSection(0)), findsOneWidget);
      expect(find.text(l10n.noOpenSlots), findsOneWidget);
    });

    testWidgets('undo on last delete restores count from 0 to 1', (
      tester,
    ) async {
      final bloc = buildBloc(availability: [slotOnly]);
      addTearDown(bloc.close);

      await _pumpHarness(tester, bloc: bloc);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();
      await tester.pump();

      final l10n = await QuranSessionsLocalizations.delegate.load(
        const Locale('en'),
      );
      await tester.tap(find.text(l10n.deleteSlotUndo));
      await tester.pump();
      await tester.pump();

      expect(find.text(l10n.openSlotsSection(1)), findsOneWidget);
      check(
        (bloc.state as TeacherDashboardSuccess).availability,
      ).length.equals(1);
    });

    testWidgets('arabic rtl shows undo action for slot deletion', (
      tester,
    ) async {
      final bloc = buildBloc(availability: [slotOnly]);
      addTearDown(bloc.close);

      await _pumpHarness(
        tester,
        bloc: bloc,
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
      );

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();
      await tester.pump();

      final l10n = await QuranSessionsLocalizations.delegate.load(
        const Locale('ar'),
      );
      expect(find.text(l10n.deleteSlotUndo), findsOneWidget);
      expect(find.text(l10n.openSlotsSection(0)), findsOneWidget);
    });
  });
}
