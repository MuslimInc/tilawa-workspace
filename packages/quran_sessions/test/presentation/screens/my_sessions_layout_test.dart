import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../helpers/fakes/fake_booking_repository.dart';
import '../../helpers/fakes/fake_session_repository.dart';
import '../../helpers/fakes/fake_teacher_profile_repository.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/lifecycle_test_helpers.dart';

class _MySessionsLayoutBloc extends MySessionsBloc {
  _MySessionsLayoutBloc({required MySessionsSuccess seed})
    : super(
        getStudentSessions: GetStudentSessionsUseCase(FakeSessionRepository()),
        cancelSession: buildCancelSessionViaServerUseCase(),
        submitReview: SubmitReviewUseCase(FakeBookingRepository()),
        joinSession: JoinSessionUseCase(
          sessionRepository: FakeSessionRepository(),
          callProvider: const MockSessionCallProvider(),
          authSession: const _FakeAuthSession('student_1'),
          teacherProfileRepository: FakeTeacherProfileRepository(),
        ),
        studentId: 'student_1',
      ) {
    emit(seed);
  }

  @override
  void add(MySessionsEvent event) {}
}

class _MySessionsEmptyBloc extends MySessionsBloc {
  _MySessionsEmptyBloc()
    : super(
        getStudentSessions: GetStudentSessionsUseCase(FakeSessionRepository()),
        cancelSession: buildCancelSessionViaServerUseCase(),
        submitReview: SubmitReviewUseCase(FakeBookingRepository()),
        joinSession: JoinSessionUseCase(
          sessionRepository: FakeSessionRepository(),
          callProvider: const MockSessionCallProvider(),
          authSession: const _FakeAuthSession('student_1'),
          teacherProfileRepository: FakeTeacherProfileRepository(),
        ),
        studentId: 'student_1',
      ) {
    emit(const MySessionsEmpty());
  }

  @override
  void add(MySessionsEvent event) {}
}

class _FakeAuthSession implements AuthSessionProvider {
  const _FakeAuthSession(this.userId);
  final String userId;

  @override
  String? get currentUserId => userId;

  @override
  Stream<String?> watchUserId() => Stream.value(userId);
}

Future<void> _pumpMySessions(
  WidgetTester tester,
  MySessionsSuccess seed, {
  double textScaleFactor = 1.0,
  void Function({
    required String bookingId,
    required String teacherId,
    required String studentId,
  })?
  onRescheduleRequested,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
      localizationsDelegates: QuranSessionsLocalizations.localizationsDelegates,
      supportedLocales: QuranSessionsLocalizations.supportedLocales,
      home: BlocProvider<MySessionsBloc>.value(
        value: _MySessionsLayoutBloc(seed: seed),
        child: MediaQuery(
          data: MediaQueryData(
            textScaler: TextScaler.linear(textScaleFactor),
          ),
          child: MySessionsScreen(
            studentId: 'student_1',
            onRescheduleRequested: onRescheduleRequested,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows summary strip and segmented tabs with upcoming cards', (
    tester,
  ) async {
    final start = DateTime.now().add(const Duration(hours: 3));
    await _pumpMySessions(
      tester,
      MySessionsSuccess(
        upcoming: [
          makeSession(
            id: 'up_1',
            startsAt: start,
            endsAt: start.add(const Duration(hours: 1)),
          ),
          makeSession(
            id: 'up_2',
            startsAt: start.add(const Duration(hours: 5)),
            endsAt: start.add(const Duration(hours: 6)),
          ),
        ],
        past: const [],
      ),
    );

    expect(find.byType(QuranSessionSummaryStrip), findsOneWidget);
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.byType(QuranSessionCard), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('past tab does not show heavy join buttons', (tester) async {
    await _pumpMySessions(
      tester,
      MySessionsSuccess(
        upcoming: const [],
        past: [
          makeSession(id: 'past_1', status: QuranSessionStatus.completed),
        ],
      ),
    );

    await tester.tap(find.text('Past'));
    await tester.pumpAndSettle();

    expect(find.text('Join now'), findsNothing);
    expect(find.text('Join'), findsNothing);
  });

  testWidgets('empty sessions state is shown when bloc is empty', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        localizationsDelegates:
            QuranSessionsLocalizations.localizationsDelegates,
        supportedLocales: QuranSessionsLocalizations.supportedLocales,
        home: BlocProvider<MySessionsBloc>.value(
          value: _MySessionsEmptyBloc(),
          child: const MySessionsScreen(studentId: 'student_1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No sessions yet'), findsOneWidget);
  });

  testWidgets('upcoming sessions stay compact at text scale 1.4 on 360x800', (
    tester,
  ) async {
    final start = DateTime.now().add(const Duration(minutes: 20));
    await _pumpMySessions(
      tester,
      MySessionsSuccess(
        upcoming: [
          makeSession(
            id: 'up_scaled',
            startsAt: start,
            endsAt: start.add(const Duration(hours: 1)),
          ),
        ],
        past: const [],
      ),
      textScaleFactor: 1.4,
    );

    expect(find.byType(QuranSessionSummaryStrip), findsOneWidget);
    expect(find.byType(QuranSessionCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reschedule appears only outside the 24 hour window', (
    tester,
  ) async {
    final soon = DateTime.now().add(const Duration(hours: 3));
    final later = DateTime.now().add(const Duration(days: 2));

    await _pumpMySessions(
      tester,
      MySessionsSuccess(
        upcoming: [
          makeSession(id: 'soon', startsAt: soon),
          makeSession(id: 'later', startsAt: later),
        ],
        past: const [],
      ),
      onRescheduleRequested:
          ({
            required bookingId,
            required teacherId,
            required studentId,
          }) {},
    );

    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    expect(find.text('Reschedule'), findsNothing);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert).last);
    await tester.pumpAndSettle();

    expect(find.text('Reschedule'), findsOneWidget);
  });
}
